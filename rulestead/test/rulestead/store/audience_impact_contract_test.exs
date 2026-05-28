# credo:disable-for-this-file
defmodule Rulestead.Store.AudienceImpactContractTest do
  use Rulestead.RepoCase, async: false

  import Ecto.Query
  import Rulestead.StoreFixtures

  alias Rulestead.{Audience, Environment, Repo}
  alias Rulestead.Error
  alias Rulestead.Runtime.Snapshot
  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.Targeting.{AudienceDependencies, ImpactPreview}

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_pid = Application.get_env(:rulestead, :policy_test_pid)

    Application.put_env(:rulestead, :store, __MODULE__.CaptureStore)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.CapturePolicy)
    Application.put_env(:rulestead, :policy_test_pid, self())

    on_exit(fn ->
      restore_env(:store, previous_store)
      restore_env(:admin_policy, previous_policy)
      restore_env(:policy_test_pid, previous_pid)
    end)

    :ok
  end

  test "preview_audience_impact builds a command and routes through admin read authorization" do
    actor = %{id: "reader-1", roles: [:viewer]}

    assert {:ok, %{command: %Command.PreviewAudienceImpact{} = command}} =
             Rulestead.preview_audience_impact("vip-users", :update,
               environment_key: "production",
               tenant_key: "tenant-a",
               after_definition: %{rules: [%{attribute: "plan", operator: "eq", value: "pro"}]},
               actor: actor,
               reason: "check references",
               metadata: %{request_id: "req-preview"}
             )

    assert command.audience_key == "vip-users"
    assert command.operation == "update"
    assert command.environment_key == "production"
    assert command.tenant_key == "tenant-a"

    assert_received {:authorized, :preview_audience_impact,
                     %{resource_type: :audience, resource_key: "vip-users"}, "production",
                     authorized_actor}

    assert authorized_actor.id == "reader-1"
    assert authorized_actor.roles == [:viewer]

    assert_received {:store_preview, ^command}
  end

  test "apply_audience_mutation rejects missing fingerprint before store mutation" do
    assert {:error, %Error{domain: :store, type: :invalid_command} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: ImpactPreview.schema_version(),
               preview_fingerprint: "",
               reason: "ship update",
               actor: %{id: "editor-1", roles: [:admin]},
               after_definition: %{rules: []}
             })

    assert error.message =~ "preview_fingerprint"
    refute_received {:store_apply, _command}
  end

  test "apply_audience_mutation routes confirmed mutations through admin write authorization" do
    actor = %{id: "editor-1", roles: [:admin]}

    attrs = %{
      environment_key: "production",
      tenant_key: "tenant-a",
      audience_key: "vip-users",
      operation: :archive,
      preview_schema_version: ImpactPreview.schema_version(),
      preview_fingerprint: "audprev_fresh",
      preview_basis: %{basis: "authored_state"},
      affected_reference_keys: ["flag:checkout"],
      reason: "retire stale audience",
      actor: actor,
      metadata: %{request_id: "req-apply"}
    }

    assert {:ok, %{command: %Command.ApplyAudienceMutation{} = command}} =
             Rulestead.apply_audience_mutation(attrs)

    assert command.operation == "archive"
    assert command.preview_fingerprint == "audprev_fresh"

    assert_received {:authorized, :apply_audience_mutation,
                     %{resource_type: :audience, resource_key: "vip-users"}, "production",
                     authorized_actor}

    assert authorized_actor.id == "editor-1"
    assert authorized_actor.roles == [:admin]

    assert_received {:store_apply, ^command}
  end

  test "Fake preview returns fingerprinted impact payload with redacted sample evidence" do
    setup_fake!()
    seed_audience_reference!()

    assert {:ok, preview} =
             Rulestead.preview_audience_impact("vip-users", :update,
               environment_key: "test",
               tenant_key: "tenant-a",
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               samples: [
                 %{actor_key: "actor-1", email: "secret@example.com", traits: %{plan: "pro"}}
               ],
               actor: %{id: "reader-1", roles: [:viewer]},
               reason: "inspect blast radius"
             )

    assert preview.preview_schema_version == ImpactPreview.schema_version()
    assert String.starts_with?(preview.preview_fingerprint, "audprev_")
    assert preview.preview_basis == "authored_state_and_explicit_samples"
    assert preview.uncertainty.authoritative_population_count? == false

    assert [%{reference_key: "flag:checkout-redesign:ruleset:1:rule:vip-rule"}] =
             preview.affected_references

    assert [%{actor_key: "actor-1", traits: %{plan: "pro"}}] = preview.sample_evidence
    refute inspect(preview.sample_evidence) =~ "secret@example.com"
  end

  describe "preview evidence resolver wiring" do
    setup do
      ensure_phase9_schema!()
      previous_resolver = Application.get_env(:rulestead, :preview_evidence_resolver)

      Application.put_env(
        :rulestead,
        :preview_evidence_resolver,
        Rulestead.Fake.PreviewEvidenceResolver
      )

      on_exit(fn ->
        case previous_resolver do
          nil -> Application.delete_env(:rulestead, :preview_evidence_resolver)
          value -> Application.put_env(:rulestead, :preview_evidence_resolver, value)
        end
      end)

      :ok
    end

    test "configured resolver enriches preview across adapters" do
      Enum.each(@adapters, fn adapter ->
        reset_adapter!(adapter)
        seed_audience_reference!(adapter)

        assert {:ok, preview} =
                 preview_audience_impact(adapter,
                   environment_key: "test",
                   tenant_key: "tenant-a",
                   after_definition: %{
                     conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
                   }
                 )

        assert preview.preview_schema_version == 2
        assert preview.preview_basis == "authored_state_with_host_evidence"
        assert preview.impression_evidence.window_label == "last_24h"

        assert Enum.any?(
                 preview.sample_evidence,
                 &String.starts_with?(&1.actor_key, "fake-vip-users")
               )
      end)
    end

    test "nil resolver keeps explicit-only preview basis across adapters" do
      Application.delete_env(:rulestead, :preview_evidence_resolver)

      Enum.each(@adapters, fn adapter ->
        reset_adapter!(adapter)
        seed_audience_reference!(adapter)

        assert {:ok, preview} =
                 preview_audience_impact(adapter,
                   environment_key: "test",
                   tenant_key: "tenant-a",
                   after_definition: %{
                     conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
                   }
                 )

        assert preview.preview_schema_version == ImpactPreview.schema_version()
        assert preview.preview_basis == "authored_state_and_explicit_samples"
        refute Enum.any?(preview.sample_evidence, &String.starts_with?(&1.actor_key, "fake-"))
      end)
    end
  end

  test "Fake apply mutates only with a fresh matching fingerprint and fails closed for stale or protected changes" do
    setup_fake!()
    seed_audience_reference!()

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "test",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:error, %Error{} = stale_error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: "audprev_stale",
               preview_basis: preview.preview_basis,
               affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply stale update"
             })

    assert stale_error.type == :invalid_command

    assert {:error, %Error{message: schema_message}} =
             Rulestead.Fake.apply_audience_mutation(
               Command.ApplyAudienceMutation.new(%{
                 environment_key: "test",
                 tenant_key: "tenant-a",
                 audience_key: "vip-users",
                 operation: :update,
                 preview_schema_version: 999,
                 preview_fingerprint: preview.preview_fingerprint,
                 preview_basis: preview.preview_basis,
                 affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
                 after_definition: %{
                   conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
                 },
                 actor: %{id: "editor-1", roles: [:editor]},
                 reason: "apply incompatible schema"
               })
             )

    assert schema_message =~ "schema"

    assert {:error, %Error{} = affected_error} =
             Rulestead.Fake.apply_audience_mutation(
               Command.ApplyAudienceMutation.new(%{
                 environment_key: "test",
                 tenant_key: "tenant-a",
                 audience_key: "vip-users",
                 operation: :update,
                 preview_schema_version: preview.preview_schema_version,
                 preview_fingerprint: preview.preview_fingerprint,
                 preview_basis: preview.preview_basis,
                 affected_reference_keys: [],
                 after_definition: %{
                   conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
                 },
                 actor: %{id: "editor-1", roles: [:editor]},
                 reason: "apply mismatched references"
               })
             )

    assert Enum.any?(affected_error.details, &dependency_code?(&1, "stale_reference"))

    assert {:ok, applied} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply confirmed update"
             })

    assert applied.result == :ok

    assert applied.audience.definition == %{
             "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
           }

    assert {:ok, compiled} = Snapshot.compile(Rulestead.Fake.Control.latest_snapshot!("test"))
    assert compiled.audience_keys == ["vip-users"]

    assert compiled.audiences["vip-users"].definition == %{
             "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
           }

    seed_production_audience_references!(1)

    {:ok, archive_preview} =
      Rulestead.preview_audience_impact("vip-users", :archive,
        environment_key: "production",
        tenant_key: "tenant-a",
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "archive preview"
      )

    assert {:error, %Error{} = protected_error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :archive,
               preview_schema_version: archive_preview.preview_schema_version,
               preview_fingerprint: archive_preview.preview_fingerprint,
               preview_basis: archive_preview.preview_basis,
               affected_reference_keys:
                 AudienceDependencies.reference_keys(archive_preview.affected_references),
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "archive protected audience"
             })

    assert protected_error.type == :invalid_command
    assert protected_error.message =~ "change request"
  end

  test "Fake apply allows below-threshold update in production" do
    setup_fake!()
    seed_production_audience_references!(1)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "production",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:ok, applied} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys:
                 AudienceDependencies.reference_keys(preview.affected_references),
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply below-threshold update in production"
             })

    assert applied.result == :ok
  end

  test "Fake apply blocks above-threshold update in production" do
    setup_fake!()
    seed_production_audience_references!(3)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "production",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:error, %Error{type: :invalid_command} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys:
                 AudienceDependencies.reference_keys(preview.affected_references),
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply above-threshold update in production"
             })

    assert error.message =~ "change request" or
             Enum.any?(error.details, &(&1.code == "blast_radius_above_threshold"))
  end

  test "Fake apply bypasses threshold in non-protected environment" do
    setup_fake!()
    seed_audience_references_in_environment!("test", 3)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "test",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:ok, applied} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys:
                 AudienceDependencies.reference_keys(preview.affected_references),
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply above-threshold update in test"
             })

    assert applied.result == :ok
  end

  test "Fake apply blocks indeterminate blast radius in production" do
    setup_fake!()
    seed_production_audience_references!(1)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "production",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "indeterminate preview"
      )

    assert {:error, %Error{type: :invalid_command} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys: ["flag:missing:ruleset:1:rule:vip-rule"],
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply indeterminate blast radius"
             })

    assert error.message =~ "Blast radius cannot be evaluated safely" or
             Enum.any?(
               error.details,
               &(&1.code in ["blast_radius_indeterminate", "blast_radius_missing_preview_inputs"])
             )
  end

  test "apply_audience_mutation blocks above-threshold production mutation via facade" do
    setup_fake!()
    seed_production_audience_references!(3)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "production",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:error, %Error{type: :invalid_command} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys:
                 AudienceDependencies.reference_keys(preview.affected_references),
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "facade apply above-threshold production"
             })

    assert error.message =~ "change request"
  end

  test "Fake apply blocks incompatible dependencies and records dependency_findings audit metadata" do
    setup_fake!()
    seed_audience_reference!()

    snapshot = Rulestead.Fake.Control.snapshot!()

    updated_snapshot =
      put_in(snapshot, [:audiences, "vip-users", :definition], %{
        conditions: [%{attribute: "plan", operator: "unsupported_operator", value: "enterprise"}]
      })

    Rulestead.Fake.Control.restore!(updated_snapshot)

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "test",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "incompatible preview"
      )

    assert {:error, %Error{} = error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :update,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
               after_definition: %{
                 conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]
               },
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "apply incompatible dependency"
             })

    assert Enum.any?(error.details, &dependency_code?(&1, "incompatible_reference"))

    latest_event =
      Rulestead.Fake.Control.snapshot!()
      |> Map.get(:audit_events, [])
      |> List.first()

    assert latest_event.event_type == "audience.mutation_blocked"

    dependency_findings = latest_event.metadata["dependency_findings"]

    assert Enum.any?(dependency_findings, &dependency_code?(&1, "incompatible_reference"))

    # Fake and Ecto same findings contract: deterministic order + explicit scope fields.
    assert dependency_findings == Enum.sort_by(dependency_findings, &dependency_sort_tuple/1)

    assert Enum.all?(dependency_findings, fn finding ->
             is_binary(Map.get(finding, "environment_key")) and
               Map.get(finding, "environment_key") != "" and
               is_binary(Map.get(finding, "tenant_key")) and
               Map.get(finding, "tenant_key") != ""
           end)
  end

  test "Fake blocks archived audiences tenant mismatch delete attempts and Redis rejects new callbacks" do
    setup_fake!()
    seed_audience_reference!()

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :delete_attempt,
        environment_key: "test",
        tenant_key: "tenant-a",
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "delete preview"
      )

    assert {:error, %Error{type: :invalid_command, message: message}} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :delete_attempt,
               preview_schema_version: preview.preview_schema_version,
               preview_fingerprint: preview.preview_fingerprint,
               preview_basis: preview.preview_basis,
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "try delete"
             })

    assert message =~ "audience_delete_unsupported"

    Rulestead.Fake.Control.put_audience!(%{
      key: "archived-users",
      tenant_key: "tenant-a",
      definition: %{conditions: []},
      archived_at: DateTime.utc_now()
    })

    assert {:error, %Error{type: :invalid_command}} =
             Rulestead.preview_audience_impact("archived-users", :update,
               environment_key: "test",
               tenant_key: "tenant-a",
               actor: %{id: "reader-1", roles: [:viewer]},
               reason: "archived preview"
             )

    assert {:error, %Error{type: :invalid_command}} =
             Rulestead.preview_audience_impact("vip-users", :update,
               environment_key: "test",
               tenant_key: "tenant-b",
               actor: %{id: "reader-1", roles: [:viewer]},
               reason: "tenant mismatch preview"
             )

    preview_command = Command.PreviewAudienceImpact.new("vip-users", :update)

    apply_command =
      Command.ApplyAudienceMutation.new(%{
        environment_key: "test",
        audience_key: "vip-users",
        operation: :update,
        preview_schema_version: ImpactPreview.schema_version(),
        preview_fingerprint: "audprev_any",
        reason: "redis check"
      })

    assert {:error, %Error{message: "Redis adapter is read-only"}} =
             Rulestead.Store.Redis.preview_audience_impact(preview_command)

    assert {:error, %Error{message: "Redis adapter is read-only"}} =
             Rulestead.Store.Redis.apply_audience_mutation(apply_command)
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)

  defp preview_audience_impact(Rulestead.Fake, attrs) do
    Rulestead.Fake.preview_audience_impact(
      Command.PreviewAudienceImpact.new("vip-users", :update, attrs)
    )
  end

  defp preview_audience_impact(StoreEcto, attrs) do
    StoreEcto.preview_audience_impact(
      Command.PreviewAudienceImpact.new("vip-users", :update, attrs)
    )
  end

  defp reset_adapter!(Rulestead.Fake) do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
  end

  defp reset_adapter!(StoreEcto), do: reset_repo!()

  defp seed_audience_reference!(Rulestead.Fake), do: seed_fake_audience_reference!()
  defp seed_audience_reference!(StoreEcto), do: seed_ecto_audience_reference!()
  defp seed_audience_reference!, do: seed_fake_audience_reference!()

  defp seed_fake_audience_reference! do
    Rulestead.Fake.Control.put_audience!(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })

    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["test"]
      })
    )

    ruleset =
      valid_ruleset_attrs(%{
        rules: [
          %{
            key: "vip-rule",
            name: "VIP audience",
            strategy: :segment_match,
            audience_key: "vip-users",
            conditions: []
          }
        ]
      })

    assert {:ok, _draft} =
             Rulestead.Fake.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset)
             )

    assert {:ok, _published} =
             Rulestead.Fake.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", "test")
             )
  end

  defp seed_ecto_audience_reference! do
    reset_repo!()

    %Audience{}
    |> Audience.changeset(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })
    |> Repo.insert!()

    assert {:ok, _flag} =
             StoreEcto.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   key: "checkout-redesign",
                   environment_keys: ["test"]
                 })
               )
             )

    ruleset =
      valid_ruleset_attrs(%{
        rules: [
          %{
            key: "vip-rule",
            name: "VIP audience",
            strategy: :segment_match,
            audience_key: "vip-users",
            conditions: []
          }
        ]
      })

    assert {:ok, _draft} =
             StoreEcto.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset)
             )

    assert {:ok, _published} =
             StoreEcto.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))
  end

  defp setup_fake! do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.CapturePolicy)
    Application.put_env(:rulestead, :policy_test_pid, self())
  end

  defp reset_repo! do
    Repo.delete_all(from(a in Rulestead.AuditEvent))
    Repo.delete_all(from(a in Audience))
    Repo.delete_all(from(f in Rulestead.Flag))
    Repo.delete_all(from(fe in Rulestead.FlagEnvironment))
    Repo.delete_all(from(r in Rulestead.Ruleset))
    Repo.delete_all(from(e in Environment))

    for attrs <- default_environments() do
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
    end
  end

  defp default_environments do
    [
      %{key: "development", name: "Development", description: "Local environments"},
      %{key: "staging", name: "Staging", description: "Pre-production environments"},
      %{key: "production", name: "Production", description: "Live environments"},
      %{key: "test", name: "Test", description: "Test environments"}
    ]
  end

  defp ensure_phase9_schema! do
    Rulestead.Repo.query!(
      "ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false"
    )

    Rulestead.Repo.query!(
      "ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone"
    )

    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS change_requests (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      status text NOT NULL DEFAULT 'submitted',
      governed_action text NOT NULL,
      environment_key text NOT NULL,
      resource_type text NOT NULL,
      resource_key text NOT NULL,
      submitter_id text NOT NULL,
      submitter_type text NOT NULL,
      submitter_display text,
      reason text,
      approval_requirement_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      command_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      correlation_id text NOT NULL,
      submitted_at timestamp(6) with time zone NOT NULL,
      resolved_at timestamp(6) with time zone,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone NOT NULL
    )")
  end

  defp seed_production_audience_references!(count) do
    seed_audience_references_in_environment!("production", count)
  end

  defp seed_audience_references_in_environment!(environment_key, count) do
    Rulestead.Fake.Control.put_audience!(%{
      key: "vip-users",
      tenant_key: "tenant-a",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })

    for index <- 1..count do
      flag_key = "checkout-redesign-#{index}"

      Rulestead.Fake.Control.put_flag!(
        valid_flag_attrs(%{
          key: flag_key,
          environment_keys: [environment_key]
        })
      )

      ruleset =
        valid_ruleset_attrs(%{
          rules: [
            %{
              key: "vip-rule-#{index}",
              name: "VIP audience #{index}",
              strategy: :segment_match,
              audience_key: "vip-users",
              conditions: []
            }
          ]
        })

      assert {:ok, _draft} =
               Rulestead.Fake.save_draft_ruleset(
                 Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
               )

      assert {:ok, _published} =
               Rulestead.Fake.publish_ruleset(
                 Command.PublishRuleset.new(flag_key, environment_key)
               )
    end
  end

  defp production_reference_keys(count), do: environment_reference_keys("production", count)

  defp environment_reference_keys(environment_key, count) do
    for index <- 1..count do
      "flag:checkout-redesign-#{index}:ruleset:1:rule:vip-rule-#{index}"
    end
  end

  defp dependency_code?(entry, code) do
    Map.get(entry, :code) == code or Map.get(entry, "code") == code
  end

  defp dependency_sort_tuple(finding) do
    {
      Map.get(finding, "severity", Map.get(finding, :severity)),
      Map.get(finding, "code", Map.get(finding, :code)),
      Map.get(finding, "environment_key", Map.get(finding, :environment_key)),
      Map.get(finding, "tenant_key", Map.get(finding, :tenant_key)),
      Map.get(finding, "flag_key", Map.get(finding, :flag_key)),
      Map.get(finding, "ruleset_version", Map.get(finding, :ruleset_version)),
      Map.get(finding, "rule_key", Map.get(finding, :rule_key)),
      Map.get(finding, "audience_key", Map.get(finding, :audience_key))
    }
  end

  defmodule CapturePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(actor, action, resource, environment_key) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {
        :authorized,
        action,
        resource,
        environment_key,
        actor
      })

      true
    end
  end

  defmodule CaptureStore do
    def preview_audience_impact(%Command.PreviewAudienceImpact{} = command) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {:store_preview, command})
      {:ok, %{command: command}}
    end

    def apply_audience_mutation(%Command.ApplyAudienceMutation{} = command) do
      send(Application.fetch_env!(:rulestead, :policy_test_pid), {:store_apply, command})
      {:ok, %{command: command}}
    end
  end
end

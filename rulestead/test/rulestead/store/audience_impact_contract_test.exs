# credo:disable-for-this-file
defmodule Rulestead.Store.AudienceImpactContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.Error
  alias Rulestead.Store.Command
  alias Rulestead.Targeting.ImpactPreview

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

    {:ok, archive_preview} =
      Rulestead.preview_audience_impact("vip-users", :archive,
        environment_key: "test",
        tenant_key: "tenant-a",
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "archive preview"
      )

    assert {:error, %Error{} = protected_error} =
             Rulestead.apply_audience_mutation(%{
               environment_key: "test",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               operation: :archive,
               preview_schema_version: archive_preview.preview_schema_version,
               preview_fingerprint: archive_preview.preview_fingerprint,
               preview_basis: archive_preview.preview_basis,
               affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
               protected_shared_targeting?: true,
               actor: %{id: "editor-1", roles: [:editor]},
               reason: "archive protected audience"
             })

    assert protected_error.type == :invalid_command
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

  defp setup_fake! do
    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.CapturePolicy)
    Application.put_env(:rulestead, :policy_test_pid, self())
  end

  defp seed_audience_reference! do
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

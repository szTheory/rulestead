# credo:disable-for-this-file
defmodule Rulestead.Store.EctoAudienceImpactContractTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    AuditEvent,
    Environment,
    Flag,
    FlagEnvironment,
    Repo,
    Ruleset,
    RuntimeSnapshot,
    Runtime.Snapshot,
    Store.Command,
    Targeting.ImpactPreview
  }

  alias Rulestead.Store.Ecto, as: EctoStore

  setup do
    checkout_repo()
    reset_repo!()
    seed_audience_reference!()
    :ok
  end

  test "preview_audience_impact returns scoped fingerprinted payload with redacted evidence" do
    command =
      Command.PreviewAudienceImpact.new("vip-users", :update,
        environment_key: "test",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        samples: [%{actor_key: "actor-1", email: "secret@example.com", traits: %{plan: "pro"}}],
        actor: %{id: "reader-1", roles: [:viewer]},
        reason: "inspect blast radius"
      )

    assert {:ok, preview} = EctoStore.preview_audience_impact(command)
    assert preview.preview_schema_version == ImpactPreview.schema_version()
    assert String.starts_with?(preview.preview_fingerprint, "audprev_")
    assert preview.environment_scope == %{environment_key: "test"}
    assert preview.tenant_scope == %{tenant_key: "tenant-a"}
    assert preview.preview_basis == "authored_state_and_explicit_samples"
    assert preview.uncertainty.authoritative_population_count? == false

    assert [%{reference_key: "flag:checkout-redesign:ruleset:1:rule:vip-rule"}] =
             preview.affected_references

    assert [%{actor_key: "actor-1", traits: %{plan: "pro"}}] = preview.sample_evidence
    refute inspect(preview.sample_evidence) =~ "secret@example.com"
  end

  test "apply_audience_mutation updates or archives only with a fresh preview fingerprint" do
    {:ok, preview} =
      EctoStore.preview_audience_impact(
        Command.PreviewAudienceImpact.new("vip-users", :update,
          environment_key: "test",
          tenant_key: "tenant-a",
          after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
        )
      )

    command =
      Command.ApplyAudienceMutation.new(%{
        environment_key: "test",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        operation: :update,
        preview_schema_version: preview.preview_schema_version,
        preview_fingerprint: preview.preview_fingerprint,
        preview_basis: preview.preview_basis,
        affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "editor-1", roles: [:editor]},
        reason: "apply confirmed update"
      })

    assert {:ok, result} = EctoStore.apply_audience_mutation(command)
    assert result.result == :ok
    assert result.operation == "update"
    assert result.preview.preview_fingerprint == preview.preview_fingerprint
    assert result.snapshot_version == 2

    assert Repo.get_by!(Audience, key: "vip-users").definition == %{
             "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
           }

    assert {:ok, compiled} = Snapshot.compile(latest_snapshot!("test"))
    assert compiled.version == 2
    assert compiled.audience_keys == ["vip-users"]

    assert compiled.audiences["vip-users"].definition == %{
             "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "pro"}]
           }

    {:ok, archive_preview} =
      EctoStore.preview_audience_impact(
        Command.PreviewAudienceImpact.new("vip-users", :archive,
          environment_key: "test",
          tenant_key: "tenant-a"
        )
      )

    archive_command =
      Command.ApplyAudienceMutation.new(%{
        environment_key: "test",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        operation: :archive,
        preview_schema_version: archive_preview.preview_schema_version,
        preview_fingerprint: archive_preview.preview_fingerprint,
        preview_basis: archive_preview.preview_basis,
        affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
        actor: %{id: "editor-1", roles: [:editor]},
        reason: "archive confirmed audience"
      })

    assert {:ok, archive_result} = EctoStore.apply_audience_mutation(archive_command)
    assert archive_result.operation == "archive"
    assert archive_result.snapshot_version == 3
    assert %DateTime{} = Repo.get_by!(Audience, key: "vip-users").archived_at

    assert {:ok, archived_compiled} = Snapshot.compile(latest_snapshot!("test"))
    assert archived_compiled.version == 3
    assert archived_compiled.audience_keys == []
  end

  test "published Ecto runtime snapshot payload includes non-archived audiences" do
    snapshot = latest_snapshot!("test")
    payload = :erlang.binary_to_term(snapshot.payload)

    assert Map.has_key?(payload, :audiences)

    assert payload.audiences["vip-users"].definition == %{
             "conditions" => [
               %{"attribute" => "plan", "operator" => "eq", "value" => "enterprise"}
             ]
           }

    assert {:ok, compiled} = Snapshot.compile(snapshot)
    assert compiled.audience_keys == ["vip-users"]
    assert Map.has_key?(compiled.flags["checkout-redesign"].flag_payload, :audiences)
  end

  test "apply fail-closed cases leave audience unchanged" do
    original = Repo.get_by!(Audience, key: "vip-users").definition

    {:ok, preview} =
      EctoStore.preview_audience_impact(
        Command.PreviewAudienceImpact.new("vip-users", :update,
          environment_key: "test",
          tenant_key: "tenant-a",
          after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
        )
      )

    stale =
      apply_command(preview,
        preview_fingerprint: "audprev_stale",
        reason: "stale apply"
      )

    assert {:error, error} = EctoStore.apply_audience_mutation(stale)
    assert error.message =~ "stale"

    missing = %{apply_command(preview) | audience_key: "missing-users"}
    assert {:error, error} = EctoStore.apply_audience_mutation(missing)
    assert error.message =~ "audience was not found"

    archived_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.get_by!(Audience, key: "vip-users")
    |> Audience.changeset(%{archived_at: archived_at})
    |> Repo.update!()

    assert {:error, error} = EctoStore.apply_audience_mutation(apply_command(preview))
    assert error.message =~ "archived"

    Repo.get_by!(Audience, key: "vip-users")
    |> Audience.changeset(%{archived_at: nil})
    |> Repo.update!()

    bad_schema = %{apply_command(preview) | preview_schema_version: 999}
    assert {:error, error} = EctoStore.apply_audience_mutation(bad_schema)
    assert error.message =~ "schema"

    mismatched_references = %{apply_command(preview) | affected_reference_keys: []}
    assert {:error, error} = EctoStore.apply_audience_mutation(mismatched_references)
    assert Enum.any?(error.details, &dependency_code?(&1, "stale_reference"))

    tenant_mismatch = %{apply_command(preview) | tenant_key: "tenant-b"}
    assert {:error, error} = EctoStore.apply_audience_mutation(tenant_mismatch)
    assert error.message =~ "stale"

    protected = %{apply_command(preview) | protected_shared_targeting?: true}
    assert {:error, error} = EctoStore.apply_audience_mutation(protected)
    assert error.message =~ "protected shared targeting"

    delete_attempt = %{apply_command(preview) | operation: "delete_attempt"}
    assert {:error, error} = EctoStore.apply_audience_mutation(delete_attempt)
    assert error.message =~ "audience_delete_unsupported"

    assert Repo.get_by!(Audience, key: "vip-users").definition == original
  end

  test "apply emits incompatible_reference blockers and persists dependency findings in audit metadata" do
    Repo.get_by!(Audience, key: "vip-users")
    |> Audience.changeset(%{
      definition: %{
        conditions: [%{attribute: "plan", operator: "unsupported_operator", value: "enterprise"}]
      }
    })
    |> Repo.update!()

    {:ok, preview} =
      EctoStore.preview_audience_impact(
        Command.PreviewAudienceImpact.new("vip-users", :update,
          environment_key: "test",
          tenant_key: "tenant-a",
          after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]}
        )
      )

    assert {:error, error} = EctoStore.apply_audience_mutation(apply_command(preview))
    assert Enum.any?(error.details, &dependency_code?(&1, "incompatible_reference"))

    assert %{metadata: %{"dependency_findings" => findings}} = latest_blocked_audience_event!()
    assert Enum.any?(findings, &dependency_code?(&1, "incompatible_reference"))

    # Fake and Ecto same findings contract: deterministic order + explicit scope fields.
    assert findings == Enum.sort_by(findings, &dependency_sort_tuple/1)

    assert Enum.all?(findings, fn finding ->
             is_binary(Map.get(finding, "environment_key")) and
               Map.get(finding, "environment_key") != "" and
               is_binary(Map.get(finding, "tenant_key")) and
               Map.get(finding, "tenant_key") != ""
           end)
  end

  defp apply_command(preview, overrides \\ []) do
    attrs =
      %{
        environment_key: "test",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        operation: :update,
        preview_schema_version: preview.preview_schema_version,
        preview_fingerprint: preview.preview_fingerprint,
        preview_basis: preview.preview_basis,
        affected_reference_keys: ["flag:checkout-redesign:ruleset:1:rule:vip-rule"],
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        actor: %{id: "editor-1", roles: [:editor]},
        reason: "apply confirmed update"
      }
      |> Map.merge(Map.new(overrides))

    Command.ApplyAudienceMutation.new(attrs)
  end

  defp seed_audience_reference! do
    %Audience{}
    |> Audience.changeset(%{
      key: "vip-users",
      description: "VIP Users",
      definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "enterprise"}]}
    })
    |> Repo.insert!()

    assert {:ok, _flag} =
             EctoStore.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["test"]})
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
             EctoStore.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset)
             )

    assert {:ok, _published} =
             EctoStore.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", "test"))
  end

  defp reset_repo! do
    Repo.delete_all(AuditEvent)
    Repo.delete_all(RuntimeSnapshot)
    Repo.delete_all(Ruleset)
    Repo.delete_all(FlagEnvironment)
    Repo.delete_all(Flag)
    Repo.delete_all(Audience)
    Repo.delete_all(Environment)

    Enum.each(default_environments(), fn attrs ->
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
    end)
  end

  defp latest_snapshot!(environment_key) do
    RuntimeSnapshot
    |> where([snapshot], snapshot.environment_key == ^environment_key)
    |> order_by([snapshot], desc: snapshot.version)
    |> limit(1)
    |> Repo.one!()
    |> Map.from_struct()
  end

  defp latest_blocked_audience_event! do
    AuditEvent
    |> where([event], event.event_type in ["audience.mutation_blocked", "audience.delete_blocked"])
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> Repo.one!()
    |> AuditEvent.serialize()
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

  defp checkout_repo do
    case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
      :ok -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:already, :owner} -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:already, :allowed} -> :ok
    end
  end

  defp default_environments do
    [
      %{
        key: "development",
        name: "Development",
        description: "Local and developer-owned environments"
      },
      %{key: "staging", name: "Staging", description: "Pre-production validation environments"},
      %{key: "production", name: "Production", description: "Live customer-facing environments"},
      %{key: "test", name: "Test", description: "Automated and ephemeral test environments"}
    ]
  end
end

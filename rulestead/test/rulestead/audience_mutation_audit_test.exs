# credo:disable-for-this-file
defmodule Rulestead.AudienceMutationAuditTest do
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
    Store.Command,
    Targeting.ImpactPreview
  }

  alias Rulestead.Store.Ecto, as: EctoStore

  setup do
    checkout_repo()
    reset_repo!()
    seed_audience_reference!()

    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :store, EctoStore)

    on_exit(fn ->
      restore_env(:store, previous_store)
      restore_env(:admin_policy, previous_policy)
    end)

    :ok
  end

  test "accepted audience update writes reconstructable support-safe preview evidence" do
    {:ok, preview} = update_preview()

    command =
      apply_command(preview,
        actor: %{id: "editor-1", type: "operator", display: "Editor One"},
        metadata: %{
          request_id: "req-accepted",
          session_token: "secret-session",
          socket_session: "secret-socket",
          email: "editor@example.com",
          phone: "+1-555-0000"
        }
      )

    assert {:ok, result} = EctoStore.apply_audience_mutation(command)
    assert result.audit_event.event_type == "audience.updated"

    event = latest_audience_event!("audience.updated")
    assert event.result == :ok
    assert event.resource_type == "audience"
    assert event.resource_key == "vip-users"
    assert event.environment_key == "test"
    assert event.actor_id == "editor-1"
    assert event.actor_type == "operator"
    assert event.actor_display == "Editor One"
    assert event.reason == "apply confirmed update"

    metadata = event.metadata
    assert metadata["tenant"]["tenant_key"] == "tenant-a"
    assert metadata["preview_fingerprint"] == preview.preview_fingerprint
    assert metadata["preview_schema_version"] == ImpactPreview.schema_version()
    assert metadata["affected_reference_keys"] == ["flag:checkout-redesign:ruleset:1:rule:vip-rule"]
    assert [%{"reference_key" => "flag:checkout-redesign:ruleset:1:rule:vip-rule"}] = metadata["affected_references"]
    assert metadata["preview_basis"] == "authored_state_and_explicit_samples"
    assert metadata["uncertainty"]["authoritative_population_count?"] == false
    assert [%{"actor_key" => "actor-1", "traits" => %{"plan" => "pro"}}] = metadata["sample_evidence"]

    refute inspect(metadata) =~ "secret-session"
    refute inspect(metadata) =~ "secret-socket"
    refute inspect(metadata) =~ "editor@example.com"
    refute inspect(metadata) =~ "+1-555-0000"
  end

  test "blocked stale apply writes error audit with blockers and redacted evidence" do
    {:ok, preview} = update_preview()

    command =
      apply_command(preview,
        preview_fingerprint: "audprev_stale",
        metadata: %{request_id: "req-blocked", email: "blocked@example.com", phone: "+1-555-1111"}
      )

    assert {:error, error} = EctoStore.apply_audience_mutation(command)
    assert error.message =~ "stale"

    event = latest_audience_event!("audience.mutation_blocked")
    assert event.result == :error
    assert event.actor_id == "editor-1"
    assert event.reason == "apply confirmed update"
    assert event.metadata["preview_fingerprint"] == "audprev_stale"
    assert event.metadata["blockers"] == [%{"code" => "audience_preview_stale"}]
    assert event.metadata["affected_reference_keys"] == ["flag:checkout-redesign:ruleset:1:rule:vip-rule"]

    refute inspect(event.metadata) =~ "blocked@example.com"
    refute inspect(event.metadata) =~ "+1-555-1111"
  end

  test "denied authorization records denied audience audit without raw PII" do
    {:ok, preview} = update_preview()
    Application.put_env(:rulestead, :admin_policy, __MODULE__.DenyAllPolicy)

    assert {:error, %{type: :unauthorized}} =
             Rulestead.apply_audience_mutation(
               Map.from_struct(
                 apply_command(preview,
                   actor: %{id: "viewer-1", roles: [:viewer]},
                   metadata: %{
                     request_id: "req-denied",
                     session_token: "secret-denied",
                     socket_session: "socket-denied",
                     email: "viewer@example.com",
                     phone: "+1-555-2222"
                   }
                 )
               )
             )

    event = latest_audience_event!("audience.mutation_blocked")
    assert event.result == :denied
    assert event.resource_type == "audience"
    assert event.resource_key == "vip-users"
    assert event.actor_id == "viewer-1"
    assert event.environment_key == "test"
    assert event.metadata["request_id"] == "req-denied"
    assert event.metadata["context"]["denied_action"] == "apply_audience_mutation"

    refute inspect(event.metadata) =~ "secret-denied"
    refute inspect(event.metadata) =~ "socket-denied"
    refute inspect(event.metadata) =~ "viewer@example.com"
    refute inspect(event.metadata) =~ "+1-555-2222"
  end

  defp update_preview do
    EctoStore.preview_audience_impact(
      Command.PreviewAudienceImpact.new("vip-users", :update,
        environment_key: "test",
        tenant_key: "tenant-a",
        after_definition: %{conditions: [%{attribute: "plan", operator: "eq", value: "pro"}]},
        samples: [%{actor_key: "actor-1", traits: %{plan: "pro"}, email: "sample@example.com"}]
      )
    )
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
        actor: %{id: "editor-1", type: "operator", display: "Editor One"},
        reason: "apply confirmed update"
      }
      |> Map.merge(Map.new(overrides))

    Command.ApplyAudienceMutation.new(attrs)
  end

  defp latest_audience_event!(event_type) do
    AuditEvent
    |> where([event], event.resource_type == "audience" and event.event_type == ^event_type)
    |> order_by([event], desc: event.inserted_at)
    |> limit(1)
    |> Repo.one!()
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
             EctoStore.save_draft_ruleset(Command.SaveDraftRuleset.new("checkout-redesign", "test", ruleset))

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

  defp checkout_repo do
    case Ecto.Adapters.SQL.Sandbox.checkout(Repo) do
      :ok -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:already, :owner} -> Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      {:already, :allowed} -> :ok
    end
  end

  defp default_environments do
    [
      %{key: "development", name: "Development", description: "Local and developer-owned environments"},
      %{key: "staging", name: "Staging", description: "Pre-production validation environments"},
      %{key: "production", name: "Production", description: "Live customer-facing environments"},
      %{key: "test", name: "Test", description: "Automated and ephemeral test environments"}
    ]
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)

  defmodule DenyAllPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false
  end
end

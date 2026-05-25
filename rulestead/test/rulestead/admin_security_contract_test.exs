defmodule Rulestead.AdminSecurityContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Admin.Authorizer, Admin.Redaction, AuthError, Error, Store.Command}
  alias Rulestead.StoreFixtures

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.DenyAllPolicy)
    Rulestead.Fake.Control.reset!()

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end

      Rulestead.Fake.Control.reset!()
    end)

    :ok
  end

  test "root facade exposes typed phase 7 verbs and command structs" do
    assert Code.ensure_loaded?(Rulestead)
    assert function_exported?(Rulestead, :engage_kill_switch, 1)
    assert function_exported?(Rulestead, :engage_kill_switch, 4)
    assert function_exported?(Rulestead, :release_kill_switch, 1)
    assert function_exported?(Rulestead, :release_kill_switch, 4)
    assert function_exported?(Rulestead, :list_audit_events, 0)
    assert function_exported?(Rulestead, :list_audit_events, 1)
    assert function_exported?(Rulestead, :rollback_audit_event, 1)
    assert function_exported?(Rulestead, :rollback_audit_event, 2)
    assert function_exported?(Rulestead, :simulate_flag, 3)
    assert function_exported?(Rulestead, :explain_flag, 3)

    assert %Command.EngageKillSwitch{
             flag_key: "checkout-redesign",
             environment_key: "production",
             actor: %{id: "operator-1"},
             metadata: %{request_id: "req-1"}
           } =
             Command.EngageKillSwitch.new("checkout-redesign", "production",
               actor: %{id: "operator-1"},
               metadata: %{request_id: "req-1"}
             )

    assert %Command.ReleaseKillSwitch{
             flag_key: "checkout-redesign",
             environment_key: "production",
             actor: %{id: "operator-1"}
           } =
             Command.ReleaseKillSwitch.new("checkout-redesign", "production",
               actor: %{id: "operator-1"}
             )

    assert %Command.ListAuditEvents{
             flag_key: "checkout-redesign",
             environment_key: "production",
             actor: %{id: "auditor-1"}
           } =
             Command.ListAuditEvents.new(
               flag_key: "checkout-redesign",
               environment_key: "production",
               actor: %{id: "auditor-1"}
             )

    assert %Command.RollbackAuditEvent{
             audit_event_id: "evt-123",
             actor: %{id: "operator-1"},
             metadata: %{reason: "revert"}
           } =
             Command.RollbackAuditEvent.new("evt-123",
               actor: %{id: "operator-1"},
               metadata: %{reason: "revert"}
             )
  end

  test "authorization denies return a typed auth error and a normalized denied audit payload" do
    actor = %{id: "viewer-1", role: :viewer}
    resource = %{resource_type: :flag, resource_key: "checkout-redesign"}

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Authorizer.authorize(actor, :engage_kill_switch, resource, "production")

    assert error ==
             AuthError.unauthorized(
               metadata: %{action: "engage_kill_switch", environment_key: "production"}
             )

    assert denied_audit.result == :denied
    assert denied_audit.action == :engage_kill_switch
    assert denied_audit.environment_key == "production"
    assert denied_audit.resource.resource_key == "checkout-redesign"
    assert denied_audit.actor.id == "viewer-1"
  end

  test "redaction preserves only allowlisted trait keys before telemetry or audit use" do
    context = %{
      targeting_key: "acct-123",
      plan: "enterprise",
      email: "ops@example.com",
      ip: "192.168.1.10",
      nested: %{region: "us-east-1", secret_token: "shh"}
    }

    assert %{audit: audit, telemetry: telemetry} =
             Redaction.redact_metadata(%{traits: context},
               allow: ["targeting_key", "plan", "nested.region"]
             )

    assert audit.traits.targeting_key == "acct-123"
    assert audit.traits.plan == "enterprise"
    assert audit.traits.email == "[REDACTED]"
    assert audit.traits.ip == "[REDACTED]"
    assert audit.traits.nested.region == "us-east-1"
    assert audit.traits.nested.secret_token == "[REDACTED]"

    assert telemetry.traits.targeting_key == "acct-123"
    assert telemetry.traits.plan == "enterprise"
    assert telemetry.traits.nested.region == "us-east-1"
    refute Map.has_key?(telemetry.traits, :email)
    refute Map.has_key?(telemetry.traits, :ip)
    refute Map.has_key?(telemetry.traits.nested, :secret_token)
  end

  test "configured host policy denials are final for draft, publish, and archive writes" do
    seed_flag!()

    actor = %{id: "prod-operator-1", roles: [:prod_operator]}
    ruleset = StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})

    assert {:error, %Error{domain: :auth, type: :unauthorized}} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset,
                 actor: actor
               )
             )

    assert {:error, %Error{domain: :auth, type: :unauthorized}} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test", actor: actor)
             )

    assert {:error, %Error{domain: :auth, type: :unauthorized}} =
             Rulestead.archive_flag(
               StoreFixtures.archive_flag_command("checkout-redesign", actor: actor)
             )
  end

  test "denied draft, publish, and archive writes append denied audit rows instead of calling direct writes" do
    seed_flag!()

    actor = %{id: "viewer-1", roles: [:viewer]}
    ruleset = StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})

    assert {:error, %Error{type: :unauthorized}} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset,
                 actor: actor,
                 metadata: %{request_id: "req-draft"}
               )
             )

    assert {:error, %Error{type: :unauthorized}} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test",
                 actor: actor,
                 metadata: %{request_id: "req-publish"}
               )
             )

    assert {:error, %Error{type: :unauthorized}} =
             Rulestead.archive_flag(
               StoreFixtures.archive_flag_command("checkout-redesign",
                 actor: actor,
                 metadata: %{request_id: "req-archive"}
               )
             )

    Application.delete_env(:rulestead, :admin_policy)

    assert {:ok, page} =
             Rulestead.list_audit_events(
               flag_key: "checkout-redesign",
               actor: %{id: "aud-1", roles: [:auditor]},
               limit: 10
             )

    denied =
      page.entries
      |> Enum.filter(&(&1.result == :denied))
      |> Enum.map(&{&1.event_type, &1.result, &1.actor_id, &1.metadata["request_id"]})

    assert {"ruleset.save_draft", :denied, "viewer-1", "req-draft"} in denied
    assert {"ruleset.publish", :denied, "viewer-1", "req-publish"} in denied
    assert {"flag.archive", :denied, "viewer-1", "req-archive"} in denied

    assert {:ok, detail} = Rulestead.fetch_flag("checkout-redesign", "test")
    assert detail.flag.archived_at == nil
    assert detail.active_ruleset.version == 1
    assert detail.draft_rulesets == []
  end

  test "fallback roles still authorize when no host policy module is configured" do
    seed_flag!()
    Application.delete_env(:rulestead, :admin_policy)

    actor = %{id: "operator-1", roles: [:operator]}
    ruleset = StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})

    assert {:ok, %{version: 2}} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset,
                 actor: actor
               )
             )

    assert {:ok, published} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test",
                 version: 2,
                 actor: actor
               )
             )

    assert published.active_ruleset.version == 2

    assert {:ok, archived} =
             Rulestead.archive_flag(
               StoreFixtures.archive_flag_command("checkout-redesign", actor: actor)
             )

    assert archived.archived?
  end

  defp seed_flag! do
    Application.delete_env(:rulestead, :admin_policy)

    assert {:ok, _} =
             Rulestead.create_flag(
               StoreFixtures.valid_flag_attrs(%{
                 permanent: true,
                 actor: %{id: "seed-operator", roles: [:operator]}
               })
             )

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "test",
                 StoreFixtures.valid_ruleset_attrs(),
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test",
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    Application.put_env(:rulestead, :admin_policy, __MODULE__.DenyAllPolicy)
  end

  defmodule DenyAllPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false
  end
end

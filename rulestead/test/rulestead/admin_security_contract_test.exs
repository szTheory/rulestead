defmodule Rulestead.AdminSecurityContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Admin.Authorizer, Admin.Redaction, AuthError, Error, Store.Command}

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
    assert function_exported?(Rulestead, :engage_kill_switch, 1)
    assert function_exported?(Rulestead, :engage_kill_switch, 4)
    assert function_exported?(Rulestead, :release_kill_switch, 1)
    assert function_exported?(Rulestead, :release_kill_switch, 4)
    assert function_exported?(Rulestead, :list_audit_events, 1)
    assert function_exported?(Rulestead, :list_audit_events, 2)
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
             Command.ListAuditEvents.new(flag_key: "checkout-redesign", environment_key: "production", actor: %{id: "auditor-1"})

    assert %Command.RollbackAuditEvent{
             audit_event_id: "evt-123",
             actor: %{id: "operator-1"},
             metadata: %{reason: "revert"}
           } =
             Command.RollbackAuditEvent.new("evt-123", actor: %{id: "operator-1"}, metadata: %{reason: "revert"})
  end

  test "authorization denies return a typed auth error and a normalized denied audit payload" do
    actor = %{id: "viewer-1", role: :viewer}
    resource = %{resource_type: :flag, resource_key: "checkout-redesign"}

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Authorizer.authorize(actor, :engage_kill_switch, resource, "production")

    assert error == AuthError.unauthorized(metadata: %{action: "engage_kill_switch", environment_key: "production"})
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

    assert %{
             audit: %{
               traits: %{
                 "targeting_key" => "acct-123",
                 "plan" => "enterprise",
                 "nested" => %{"region" => "us-east-1"},
                 "email" => "[REDACTED]",
                 "ip" => "[REDACTED]"
               }
             },
             telemetry: %{
               traits: %{
                 "targeting_key" => "acct-123",
                 "plan" => "enterprise",
                 "nested" => %{"region" => "us-east-1"}
               }
             }
           } = Redaction.redact_metadata(%{traits: context}, allow: ["targeting_key", "plan", "nested.region"])
  end

  defmodule DenyAllPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false
  end
end

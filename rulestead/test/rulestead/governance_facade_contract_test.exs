defmodule Rulestead.GovernanceFacadeContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Error, Governance.ApprovalRequirement, Store.Command, Telemetry}

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
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

  test "root facade exports governance verbs in command-first forms" do
    assert function_exported?(Rulestead, :submit_change_request, 1)
    assert function_exported?(Rulestead, :approve_change_request, 1)
    assert function_exported?(Rulestead, :reject_change_request, 1)
    assert function_exported?(Rulestead, :cancel_change_request, 1)
    assert function_exported?(Rulestead, :execute_change_request, 1)

    approval_requirement =
      ApprovalRequirement.new(
        action: :publish_ruleset,
        environment_key: "production",
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: false
      )

    assert %Command.SubmitChangeRequest{
             action: :publish_ruleset,
             environment_key: "production",
             resource_type: "flag",
             resource_key: "checkout-redesign",
             actor: %{"id" => "operator-1"},
             approval_requirement: %{"required_approvals" => 1}
           } =
             Command.SubmitChangeRequest.new(
               %{
                 action: :publish_ruleset,
                 environment_key: "production",
                 resource_type: "flag",
                 resource_key: "checkout-redesign",
                 command: %{"version" => 2},
                 approval_requirement: approval_requirement
               },
               actor: %{id: "operator-1"}
             )

    assert %Command.ApproveChangeRequest{change_request_id: "cr-123"} =
             Command.ApproveChangeRequest.new("cr-123")

    assert %Command.RejectChangeRequest{change_request_id: "cr-123"} =
             Command.RejectChangeRequest.new("cr-123")

    assert %Command.CancelChangeRequest{change_request_id: "cr-123"} =
             Command.CancelChangeRequest.new("cr-123")

    assert %Command.ExecuteChangeRequest{change_request_id: "cr-123"} =
             Command.ExecuteChangeRequest.new("cr-123")
  end

  test "facade returns typed errors for change-request-required and self-approval-denied cases" do
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)

    actor = %{id: "prod-operator-1", roles: [:prod_operator], display: "Prod Operator"}

    submit_command =
      Command.SubmitChangeRequest.new(
        %{
          action: :publish_ruleset,
          environment_key: "production",
          resource_type: "flag",
          resource_key: "checkout-redesign",
          command: %{"version" => 2},
          approval_requirement:
            ApprovalRequirement.new(
              action: :publish_ruleset,
              environment_key: "production",
              required_approvals: 1,
              change_request_required?: true,
              self_approval_allowed?: false
            )
        },
        actor: actor,
        metadata: %{request_id: "req-submit"}
      )

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new("cr-self",
                 actor: actor,
                 metadata: %{
                   submitter: %{id: actor.id, display: actor.display},
                   action: :publish_ruleset,
                   resource_type: "flag",
                   resource_key: "checkout-redesign",
                   environment_key: "production"
                 }
               )
             )

    assert error.metadata == %{
             action: "approve_change_request",
             environment_key: "production",
             reason: "self_approval_forbidden"
           }

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error} =
             Rulestead.execute_change_request(
               Command.ExecuteChangeRequest.new("cr-locked",
                 actor: actor,
                 metadata: %{
                   action: :publish_ruleset,
                   resource_type: "flag",
                   resource_key: "checkout-redesign",
                   environment_key: "production"
                 }
               )
             )

    assert error.metadata == %{
             action: "publish_ruleset",
             environment_key: "production",
             reason: "change_request_required"
           }

    assert {:ok, _change_request} = Rulestead.submit_change_request(submit_command)
  end

  test "governance telemetry metadata keeps the canonical correlated fields" do
    metadata =
      Telemetry.governance_metadata(
        %Command.ExecuteChangeRequest{change_request_id: "cr-123", metadata: %{request_id: "req-123"}},
        %{
          event: :merged,
          action: :publish_ruleset,
          environment_key: "production",
          resource_key: "checkout-redesign",
          change_request_id: "cr-123",
          correlation_id: "corr-123",
          audit_event_id: "evt-123"
        }
      )

    assert metadata == %{
             operation: "execute_change_request",
             environment: "production",
             audit_action: "publish_ruleset",
             reason: :merged,
             change_request_id: "cr-123",
             correlation_id: "corr-123",
             audit_event_id: "evt-123",
             resource_key: "checkout-redesign"
           }
  end

  defmodule GovernancePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, :publish_ruleset, _resource, "production"), do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, "production"), do: false

    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end
end

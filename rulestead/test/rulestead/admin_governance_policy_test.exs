# credo:disable-for-this-file
defmodule Rulestead.AdminGovernancePolicyTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Admin.Authorizer, Error}
  alias Rulestead.Governance.ApprovalRequirement

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    :ok
  end

  test "admin policy exposes optional governance hooks on the existing host seam" do
    assert {:change_request_required?, 4} in Rulestead.Admin.Policy.behaviour_info(
             :optional_callbacks
           )

    assert {:allow_self_approval?, 4} in Rulestead.Admin.Policy.behaviour_info(
             :optional_callbacks
           )

    assert __MODULE__.SelectiveGovernancePolicy.change_request_required?(
             %{id: "operator-1"},
             :publish_ruleset,
             %{resource_type: :flag, resource_key: "checkout-redesign"},
             "production"
           )

    refute __MODULE__.SelectiveGovernancePolicy.change_request_required?(
             %{id: "operator-1"},
             :publish_ruleset,
             %{resource_type: :flag, resource_key: "checkout-redesign"},
             "staging"
           )

    refute __MODULE__.SelectiveGovernancePolicy.allow_self_approval?(
             %{id: "operator-1"},
             :publish_ruleset,
             %{resource_type: :flag, resource_key: "checkout-redesign"},
             "production"
           )

    assert __MODULE__.SelectiveGovernancePolicy.allow_self_approval?(
             %{id: "operator-1"},
             :publish_ruleset,
             %{resource_type: :flag, resource_key: "checkout-redesign"},
             "staging"
           )
  end

  test "approval requirement stores the resolved governance posture" do
    assert %ApprovalRequirement{
             action: :publish_ruleset,
             environment_key: "production",
             required_approvals: 1,
             change_request_required?: true,
             self_approval_allowed?: false
           } =
             ApprovalRequirement.new(
               action: :publish_ruleset,
               environment_key: "production",
               required_approvals: 1,
               change_request_required?: true,
               self_approval_allowed?: false
             )

    assert ApprovalRequirement.serialize(
             action: :publish_ruleset,
             environment_key: "production",
             required_approvals: 1,
             change_request_required?: true,
             self_approval_allowed?: false
           ) == %{
             action: :publish_ruleset,
             environment_key: "production",
             required_approvals: 1,
             change_request_required?: true,
             self_approval_allowed?: false
           }
  end

  test "bounded governance vocabulary includes release kill switch without legacy manage settings fallback" do
    assert Rulestead.Admin.Policy.governance_actions() == [
             :publish_ruleset,
             :advance_rollout,
             :engage_kill_switch,
             :release_kill_switch,
             :promote_environment
           ]

    assert {:ok, %ApprovalRequirement{action: :release_kill_switch}} =
             Authorizer.authorize_governed_action(
               %{id: "operator-1", roles: [:operator]},
               :release_kill_switch,
               %{resource_type: :flag, resource_key: "checkout-redesign"},
               "staging"
             )
  end

  test "authorizer returns a policy snapshot and blocks direct governed production execution" do
    Application.put_env(:rulestead, :admin_policy, __MODULE__.SelectiveGovernancePolicy)

    actor = %{id: "prod-operator-1", roles: [:prod_operator]}
    resource = %{resource_type: :flag, resource_key: "checkout-redesign"}

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Authorizer.authorize_governed_action(actor, :publish_ruleset, resource, "production")

    assert error.metadata == %{
             action: "publish_ruleset",
             environment_key: "production",
             reason: "change_request_required"
           }

    assert denied_audit.reason == :change_request_required
    assert denied_audit.approval_requirement.change_request_required?
    assert denied_audit.approval_requirement.required_approvals == 1
    refute denied_audit.approval_requirement.self_approval_allowed?

    assert {:ok,
            %ApprovalRequirement{
              change_request_required?: false,
              self_approval_allowed?: true
            }} =
             Authorizer.authorize_governed_action(actor, :publish_ruleset, resource, "staging")
  end

  test "authorizer denies production self-approval by default and allows an explicit host opt-in" do
    resource = %{resource_type: :flag, resource_key: "checkout-redesign"}
    actor = %{id: "prod-operator-1", roles: [:prod_operator]}

    Application.put_env(:rulestead, :admin_policy, __MODULE__.NoSelfApprovalOverridePolicy)

    assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
             Authorizer.authorize_change_request_approval(
               actor,
               actor,
               :publish_ruleset,
               resource,
               "production"
             )

    assert error.metadata == %{
             action: "approve_change_request",
             environment_key: "production",
             reason: "self_approval_forbidden"
           }

    assert denied_audit.reason == :self_approval_forbidden
    refute denied_audit.approval_requirement.self_approval_allowed?

    Application.put_env(:rulestead, :admin_policy, __MODULE__.SelectiveGovernancePolicy)

    assert {:ok, %ApprovalRequirement{self_approval_allowed?: true}} =
             Authorizer.authorize_change_request_approval(
               actor,
               actor,
               :publish_ruleset,
               resource,
               "staging"
             )
  end

  defmodule SelectiveGovernancePolicy do
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

  defmodule NoSelfApprovalOverridePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, :publish_ruleset, _resource, "production"), do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
  end
end

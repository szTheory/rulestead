defmodule Rulestead.AdminGovernancePolicyTest do
  use ExUnit.Case, async: false

  alias Rulestead.Governance.ApprovalRequirement

  test "admin policy exposes optional governance hooks on the existing host seam" do
    assert {:change_request_required?, 4} in Rulestead.Admin.Policy.behaviour_info(:optional_callbacks)
    assert {:allow_self_approval?, 4} in Rulestead.Admin.Policy.behaviour_info(:optional_callbacks)

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
end

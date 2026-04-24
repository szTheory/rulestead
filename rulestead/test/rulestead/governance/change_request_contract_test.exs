defmodule Rulestead.Governance.ChangeRequestContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.Governance.{ApprovalRequirement, ChangeRequest}

  describe "canonical governance vocabulary" do
    test "states and governed actions stay fixed" do
      assert ChangeRequest.states() == [:submitted, :approved, :rejected, :cancelled, :executed]
      assert ChangeRequest.terminal_states() == [:rejected, :cancelled, :executed]

      assert ChangeRequest.governed_actions() == [
               :publish_ruleset,
               :advance_rollout,
               :engage_kill_switch,
               :manage_settings
             ]
    end
  end

  describe "change request serialization" do
    test "retains explicit governance facts without admin-ui state" do
      approval_requirement =
        ApprovalRequirement.new(
          action: :publish_ruleset,
          environment_key: "prod",
          required_approvals: 2,
          self_approval_allowed?: false
        )

      change_request =
        ChangeRequest.new(
          state: :submitted,
          action: :publish_ruleset,
          environment_key: "prod",
          resource_type: :ruleset,
          resource_key: "checkout-banner",
          submitted_by: %{id: "user_123", type: "user", display: "Alice Operator"},
          command: %{
            reason: "Publish reviewed rollout",
            changes: %{"version" => 7}
          },
          approval_requirement: approval_requirement,
          correlation_id: "req_123"
        )

      assert ChangeRequest.serialize(change_request) == %{
               state: :submitted,
               action: :publish_ruleset,
               environment_key: "prod",
               resource_type: "ruleset",
               resource_key: "checkout-banner",
               submitted_by: %{
                 id: "user_123",
                 type: "user",
                 display: "Alice Operator"
               },
               command: %{
                 "reason" => "Publish reviewed rollout",
                 "changes" => %{"version" => 7}
               },
               approval_requirement: %{
                 action: :publish_ruleset,
                 environment_key: "prod",
                 required_approvals: 2,
                 self_approval_allowed?: false
               },
               correlation_id: "req_123"
             }
    end
  end
end

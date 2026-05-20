defmodule Rulestead.Governance.ChangeRequestContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.Governance.{Approval, ApprovalRequirement, ChangeRequest}

  describe "canonical governance vocabulary" do
    test "states and governed actions stay fixed" do
      assert ChangeRequest.states() == [:submitted, :approved, :rejected, :cancelled, :executed]
      assert ChangeRequest.terminal_states() == [:rejected, :cancelled, :executed]

      assert ChangeRequest.governed_actions() == [
               :publish_ruleset,
               :advance_rollout,
               :engage_kill_switch,
               :release_kill_switch,
               :promote_environment
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
               command: %{"reason" => "Publish reviewed rollout", "changes" => %{"version" => 7}},
               metadata: %{},
               approval_requirement: %{
                 action: :publish_ruleset,
                 environment_key: "prod",
                 required_approvals: 2,
                 change_request_required?: false,
                 self_approval_allowed?: false
               },
               correlation_id: "req_123"
             }
    end
  end

  describe "approval correlation contract" do
    test "approval shares correlation id and explicit reviewer identity fields" do
      approval =
        Approval.new(
          change_request_id: "cr_123",
          decision: :approved,
          reviewed_by: %{id: "user_456", type: "user", display: "Bob Reviewer"},
          reason: "Peer review complete",
          correlation_id: "req_123"
        )

      assert Approval.decisions() == [:approved, :rejected]

      assert Approval.serialize(approval) == %{
               change_request_id: "cr_123",
               decision: :approved,
               reviewed_by: %{
                 id: "user_456",
                 type: "user",
                 display: "Bob Reviewer"
               },
               reason: "Peer review complete",
               correlation_id: "req_123"
             }
    end

    test "approval requirement keeps self-approval posture explicit" do
      approval_requirement =
        ApprovalRequirement.new(
          action: :release_kill_switch,
          environment_key: :prod,
          required_approvals: 1,
          self_approval_allowed?: true
        )

      assert ApprovalRequirement.serialize(approval_requirement) == %{
               action: :release_kill_switch,
               environment_key: "prod",
               required_approvals: 1,
               change_request_required?: false,
               self_approval_allowed?: true
             }
    end

    test "release kill switch is preserved without a legacy manage settings fallback" do
      assert ChangeRequest.new(
               state: :submitted,
               action: :release_kill_switch,
               environment_key: "prod",
               resource_type: :flag,
               resource_key: "checkout-redesign",
               submitted_by: %{id: "user_123"},
               command: %{},
               approval_requirement: %{action: :release_kill_switch},
               correlation_id: "corr-123"
             ).action == :release_kill_switch

      assert ApprovalRequirement.new(action: :release_kill_switch).action ==
               :release_kill_switch

      refute :manage_settings in ChangeRequest.governed_actions()
    end
  end
end

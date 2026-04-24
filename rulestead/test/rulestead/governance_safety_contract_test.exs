defmodule Rulestead.GovernanceSafetyContractTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Error, Governance.ApprovalRequirement, Store.Command}
  alias Rulestead.StoreFixtures

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)
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

    seed_governed_publish!(Rulestead.Fake)
    :ok
  end

  test "production publish change requests submit, peer-approve, and execute through the public facade" do
    submitter = actor("submitter-1")
    reviewer = actor("reviewer-1")
    executor = actor("executor-1")

    assert {:ok, %{change_request: submitted}} =
             Rulestead.submit_change_request(governed_publish_command(submitter,
               reason: "Ship version 2",
               request_id: "corr-approve"
             ))

    assert submitted.state == :submitted

    assert {:ok, %{change_request: approved, approval: approval}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: reviewer,
                 reason: "Approved by peer"
               )
             )

    assert approved.state == :approved
    assert approval.reviewed_by.id == "reviewer-1"

    assert {:ok, %{change_request: executed, execution_result: execution_result}} =
             Rulestead.execute_change_request(
               Command.ExecuteChangeRequest.new(submitted.id,
                 actor: executor,
                 reason: "Execute now"
               )
             )

    assert executed.state == :executed
    assert execution_result.active_ruleset.version == 2

    assert {:ok, %{approvals: approvals, audit_events: audit_events}} =
             Rulestead.Fake.fetch_change_request(Command.FetchChangeRequest.new(submitted.id))

    assert [%{decision: :approved, correlation_id: "corr-approve"}] = approvals

    assert audit_events
           |> Enum.map(& &1.event_type)
           |> Enum.sort() == [
             "change_request.approved",
             "change_request.merged",
             "change_request.submitted",
             "ruleset.publish"
           ]

    assert Enum.all?(audit_events, &(&1.correlation_id == "corr-approve"))
  end

  test "rejected and cancelled requests are terminal and cannot execute through the public facade" do
    submitter = actor("submitter-2")
    reviewer = actor("reviewer-2")

    assert {:ok, %{change_request: rejected_request}} =
             Rulestead.submit_change_request(governed_publish_command(submitter,
               reason: "Reject path",
               request_id: "corr-reject"
             ))

    assert {:ok, %{change_request: rejected}} =
             Rulestead.reject_change_request(
               Command.RejectChangeRequest.new(rejected_request.id,
                 actor: reviewer,
                 reason: "Missing context"
               )
             )

    assert rejected.state == :rejected

    assert {:error, %Error{type: :invalid_command}} =
             Rulestead.execute_change_request(
               Command.ExecuteChangeRequest.new(rejected.id, actor: reviewer)
             )

    assert {:ok, %{change_request: cancelled_request}} =
             Rulestead.submit_change_request(governed_publish_command(submitter,
               reason: "Cancel path",
               request_id: "corr-cancel"
             ))

    assert {:ok, %{change_request: cancelled}} =
             Rulestead.cancel_change_request(
               Command.CancelChangeRequest.new(cancelled_request.id,
                 actor: submitter,
                 reason: "No longer needed"
               )
             )

    assert cancelled.state == :cancelled

    assert {:error, %Error{type: :invalid_command}} =
             Rulestead.execute_change_request(
               Command.ExecuteChangeRequest.new(cancelled.id, actor: reviewer)
             )
  end

  defp governed_publish_command(actor, opts) do
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
      reason: Keyword.fetch!(opts, :reason),
      metadata: %{request_id: Keyword.fetch!(opts, :request_id), source: :review_queue}
    )
  end

  defp seed_governed_publish!(adapter) do
    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{
                   permanent: true,
                   environment_keys: ["production"]
                 })
               )
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "production",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(StoreFixtures.publish_ruleset_command("checkout-redesign", "production"))

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 "checkout-redesign",
                 "production",
                 StoreFixtures.valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )
  end

  defp actor(id) do
    %{id: id, type: "operator", display: String.capitalize(id), roles: [:prod_operator]}
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

defmodule Rulestead.Store.CommandGovernanceTest do
  use ExUnit.Case, async: true

  alias Rulestead.Store
  alias Rulestead.Store.Command

  test "exposes governance store callbacks" do
    callbacks = Store.behaviour_info(:callbacks)

    assert {:submit_change_request, 1} in callbacks
    assert {:approve_change_request, 1} in callbacks
    assert {:reject_change_request, 1} in callbacks
    assert {:cancel_change_request, 1} in callbacks
    assert {:execute_change_request, 1} in callbacks
    assert {:fetch_change_request, 1} in callbacks
    assert {:list_change_requests, 1} in callbacks
  end

  test "builds a submit command from plain input and normalizes metadata" do
    command =
      Command.SubmitChangeRequest.new(%{
        action: :publish_ruleset,
        environment_key: :production,
        resource_type: :flag,
        resource_key: :checkout_v2,
        command: %{version: 7, rollout: %{stage: :confirm}},
        approval_requirement: %{
          action: :publish_ruleset,
          environment_key: :production,
          required_approvals: 2,
          self_approval_allowed?: false
        },
        actor: %{id: 42, type: :operator, display: "Ops"},
        reason: "Promote ruleset",
        metadata: [request_id: "req-123", source: :admin_ui, nested: %{correlation_id: "corr-123"}]
      })

    assert %Command.SubmitChangeRequest{
             action: :publish_ruleset,
             environment_key: "production",
             resource_type: "flag",
             resource_key: "checkout_v2",
             actor: %{"id" => "42", "type" => "operator", "display" => "Ops"},
             reason: "Promote ruleset",
             metadata: %{
               "request_id" => "req-123",
               "source" => "admin_ui",
               "nested" => %{"correlation_id" => "corr-123"}
             }
           } = command

    assert command.command == %{"version" => 7, "rollout" => %{"stage" => "confirm"}}
    assert command.approval_requirement["required_approvals"] == 2
    assert command.approval_requirement["self_approval_allowed?"] == false
  end

  test "write-path governance commands carry actor and metadata without admin inputs" do
    approve =
      Command.ApproveChangeRequest.new("cr-123",
        actor: [id: "u-1", type: :operator, display: "Reviewer"],
        reason: "Looks good",
        metadata: %{request_id: "req-1", session_id: "sess-1", source: :review_queue}
      )

    reject =
      Command.RejectChangeRequest.new("cr-123",
        actor: %{id: "u-2", type: :operator, display: "Reviewer Two"},
        reason: "Missing simulation",
        metadata: %{request_id: "req-2", admin_session: "lv", source: :review_queue}
      )

    cancel =
      Command.CancelChangeRequest.new("cr-123",
        actor: %{id: "u-3", type: :operator, display: "Submitter"},
        reason: "No longer needed",
        metadata: %{request_id: "req-3", source: :admin_ui}
      )

    execute =
      Command.ExecuteChangeRequest.new("cr-123",
        actor: %{id: "u-4", type: :operator, display: "Executor"},
        reason: "Approved and ready",
        metadata: %{request_id: "req-4", source: :governance_worker}
      )

    for command <- [approve, reject, cancel, execute] do
      assert %{"id" => _, "type" => _, "display" => _} = command.actor
      assert is_binary(command.reason)
      assert is_map(command.metadata)
      assert is_binary(command.metadata["request_id"])
      refute Map.has_key?(command.metadata, "session_id")
      refute Map.has_key?(command.metadata, "admin_session")
      refute Map.has_key?(Map.from_struct(command), :admin_session)
    end
  end

  test "builds fetch and list governance read commands without admin-specific fields" do
    assert %Command.FetchChangeRequest{change_request_id: "cr-123"} =
             Command.FetchChangeRequest.new("cr-123")

    assert %Command.ListChangeRequests{
             environment_key: "production",
             status: :submitted,
             limit: 20
           } =
             Command.ListChangeRequests.new(environment_key: :production, status: :submitted, limit: 20)
  end
end

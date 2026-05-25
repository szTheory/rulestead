defmodule Rulestead.Store.CommandScheduledExecutionTest do
  use ExUnit.Case, async: true

  alias Rulestead.Governance.ExecutionAttempt
  alias Rulestead.Governance.ScheduledExecution
  alias Rulestead.Store
  alias Rulestead.Store.Command

  test "exposes scheduled execution store callbacks" do
    callbacks = Store.behaviour_info(:callbacks)

    assert {:schedule_change_request, 1} in callbacks
    assert {:schedule_governed_action, 1} in callbacks
    assert {:cancel_scheduled_execution, 1} in callbacks
    assert {:requeue_scheduled_execution, 1} in callbacks
    assert {:execute_scheduled_execution, 1} in callbacks
    assert {:fetch_scheduled_execution, 1} in callbacks
    assert {:list_scheduled_executions, 1} in callbacks
  end

  test "scheduled execution contracts normalize actor chain action timing and replay identity" do
    scheduled_execution =
      ScheduledExecution.new(%{
        id: "se-123",
        state: :scheduled,
        action: :publish_ruleset,
        change_request_id: "cr-123",
        scheduled_by: %{id: 42, type: :operator, display: "Scheduler"},
        approved_by_snapshot: [
          %{id: "u-1", type: :operator, display: "Approver One"},
          %{id: :u_2, type: :operator, display: "Approver Two"}
        ],
        scheduled_for: ~U[2026-04-25 12:30:00Z],
        executed_at: ~U[2026-04-25 12:35:00Z],
        attempt_count: 2,
        failure_reason: "timed out",
        correlation_id: :corr_123,
        idempotency_key: :idem_123,
        command_snapshot: %{version: 7, rollout: %{stage: :confirm}},
        metadata: %{
          request_id: "req-123",
          source: :admin_ui,
          nested: %{correlation_id: "corr-123", session_id: "sess-1"}
        }
      })

    assert %ScheduledExecution{
             id: "se-123",
             state: :scheduled,
             action: :publish_ruleset,
             change_request_id: "cr-123",
             scheduled_by: %{"id" => "42", "type" => "operator", "display" => "Scheduler"},
             approved_by_snapshot: [
               %{"id" => "u-1", "type" => "operator", "display" => "Approver One"},
               %{"id" => "u_2", "type" => "operator", "display" => "Approver Two"}
             ],
             scheduled_for: ~U[2026-04-25 12:30:00Z],
             executed_at: ~U[2026-04-25 12:35:00Z],
             attempt_count: 2,
             failure_reason: "timed out",
             correlation_id: "corr_123",
             idempotency_key: "idem_123"
           } = scheduled_execution

    serialized = ScheduledExecution.serialize(scheduled_execution)

    assert serialized.id == "se-123"
    assert serialized.state == :scheduled
    assert serialized.action == :publish_ruleset
    assert serialized.change_request_id == "cr-123"

    assert serialized.scheduled_by == %{
             "id" => "42",
             "type" => "operator",
             "display" => "Scheduler"
           }

    assert serialized.approved_by_snapshot == [
             %{"id" => "u-1", "type" => "operator", "display" => "Approver One"},
             %{"id" => "u_2", "type" => "operator", "display" => "Approver Two"}
           ]

    assert serialized.scheduled_for == ~U[2026-04-25 12:30:00Z]
    assert serialized.executed_at == ~U[2026-04-25 12:35:00Z]
    assert serialized.attempt_count == 2
    assert serialized.failure_reason == "timed out"
    assert serialized.correlation_id == "corr_123"
    assert serialized.idempotency_key == "idem_123"
    assert serialized.command_snapshot == %{"version" => 7, "rollout" => %{"stage" => "confirm"}}

    assert serialized.metadata == %{
             "request_id" => "req-123",
             "source" => "admin_ui",
             "nested" => %{"correlation_id" => "corr-123"}
           }
  end

  test "execution attempt contracts preserve append-only attempt numbers and failure details" do
    first_attempt =
      ExecutionAttempt.new(%{
        id: "ea-1",
        scheduled_execution_id: "se-123",
        attempt_number: 1,
        state: :failed,
        started_at: ~U[2026-04-25 12:30:01Z],
        finished_at: ~U[2026-04-25 12:31:00Z],
        failure_reason: "oban timeout",
        metadata: %{request_id: "req-123", context: %{step: :delivery, session_token: "secret"}}
      })

    second_attempt =
      ExecutionAttempt.new(%{
        id: "ea-2",
        scheduled_execution_id: "se-123",
        attempt_number: 2,
        state: :quarantined,
        started_at: ~U[2026-04-25 12:32:00Z],
        finished_at: ~U[2026-04-25 12:33:00Z],
        failure_reason: "stale target",
        metadata: %{request_id: "req-123", context: %{step: :apply, retry: 2}}
      })

    assert first_attempt.attempt_number == 1
    assert second_attempt.attempt_number == 2

    assert ExecutionAttempt.serialize(first_attempt) == %{
             id: "ea-1",
             scheduled_execution_id: "se-123",
             attempt_number: 1,
             state: :failed,
             started_at: ~U[2026-04-25 12:30:01Z],
             finished_at: ~U[2026-04-25 12:31:00Z],
             failure_reason: "oban timeout",
             metadata: %{"request_id" => "req-123", "context" => %{"step" => "delivery"}}
           }

    assert ExecutionAttempt.serialize(second_attempt) == %{
             id: "ea-2",
             scheduled_execution_id: "se-123",
             attempt_number: 2,
             state: :quarantined,
             started_at: ~U[2026-04-25 12:32:00Z],
             finished_at: ~U[2026-04-25 12:33:00Z],
             failure_reason: "stale target",
             metadata: %{
               "request_id" => "req-123",
               "context" => %{"step" => "apply", "retry" => 2}
             }
           }
  end

  test "schedule commands normalize actor metadata approval snapshots and command payloads" do
    change_request_command =
      Command.ScheduleChangeRequest.new(%{
        change_request_id: :cr_123,
        scheduled_for: ~U[2026-04-25 12:30:00Z],
        actor: %{id: 42, type: :operator, display: "Scheduler"},
        reason: "Wait for launch window",
        metadata: %{
          request_id: "req-123",
          source: :admin_ui,
          session_id: "sess-123",
          nested: %{admin_session: "secret", correlation_id: "corr-123"}
        }
      })

    governed_action_command =
      Command.ScheduleGovernedAction.new(%{
        action: :engage_kill_switch,
        environment_key: :production,
        resource_type: :flag,
        resource_key: :checkout_v2,
        command: %{reason: "High error rate", actor: %{id: "ignored"}},
        scheduled_for: ~U[2026-04-25 12:30:00Z],
        execution_mode: :emergency_bypass,
        actor: %{id: 7, type: :operator, display: "Incident Commander"},
        reason: "Protect checkout",
        approval_requirement: %{
          action: :engage_kill_switch,
          environment_key: :production,
          required_approvals: 0,
          self_approval_allowed?: true
        },
        metadata: %{
          request_id: "req-456",
          source: :incident_console,
          admin_session: "lv-123",
          nested: %{session_token: "secret", correlation_id: "corr-456"}
        }
      })

    assert %Command.ScheduleChangeRequest{
             change_request_id: "cr_123",
             scheduled_for: ~U[2026-04-25 12:30:00Z],
             actor: %{"id" => "42", "type" => "operator", "display" => "Scheduler"},
             reason: "Wait for launch window",
             metadata: %{
               "request_id" => "req-123",
               "source" => "admin_ui",
               "nested" => %{"correlation_id" => "corr-123"}
             }
           } = change_request_command

    assert %Command.ScheduleGovernedAction{
             action: :engage_kill_switch,
             environment_key: "production",
             resource_type: "flag",
             resource_key: "checkout_v2",
             scheduled_for: ~U[2026-04-25 12:30:00Z],
             execution_mode: :emergency_bypass,
             actor: %{"id" => "7", "type" => "operator", "display" => "Incident Commander"},
             reason: "Protect checkout",
             metadata: %{
               "request_id" => "req-456",
               "source" => "incident_console",
               "nested" => %{"correlation_id" => "corr-456"}
             }
           } = governed_action_command

    assert governed_action_command.command == %{
             "reason" => "High error rate",
             "actor" => %{"id" => "ignored"}
           }

    assert governed_action_command.approval_requirement["required_approvals"] == 0
    assert governed_action_command.approval_requirement["self_approval_allowed?"] == true
  end

  test "fetch list requeue cancel and execute commands preserve scheduled execution identity" do
    cancel =
      Command.CancelScheduledExecution.new("se-123",
        actor: %{id: "u-1", type: :operator, display: "Scheduler"},
        reason: "Launch delayed",
        metadata: %{request_id: "req-1", source: :admin_ui, session_id: "sess-1"}
      )

    requeue =
      Command.RequeueScheduledExecution.new("se-123",
        actor: %{id: "u-2", type: :operator, display: "Responder"},
        reason: "Retry after fix",
        metadata: %{request_id: "req-2", source: :admin_ui}
      )

    execute =
      Command.ExecuteScheduledExecution.new("se-123",
        actor: %{id: "scheduler", type: :system, display: "Scheduler"},
        reason: "Due now",
        metadata: %{request_id: "req-3", source: :governance_worker}
      )

    fetch = Command.FetchScheduledExecution.new("se-123")

    list =
      Command.ListScheduledExecutions.new(
        environment_key: :production,
        state: :scheduled,
        action: :publish_ruleset,
        scheduled_by_id: :u_1,
        limit: 20
      )

    for command <- [cancel, requeue, execute] do
      assert command.scheduled_execution_id == "se-123"
      assert %{"id" => _, "type" => _, "display" => _} = command.actor
      assert is_binary(command.reason)
      assert is_binary(command.metadata["request_id"])
      refute Map.has_key?(command.metadata, "session_id")
    end

    assert %Command.FetchScheduledExecution{scheduled_execution_id: "se-123"} = fetch

    assert %Command.ListScheduledExecutions{
             environment_key: "production",
             state: :scheduled,
             action: :publish_ruleset,
             scheduled_by_id: "u_1",
             limit: 20
           } = list
  end
end

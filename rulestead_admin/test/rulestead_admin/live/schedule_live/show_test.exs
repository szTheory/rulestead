defmodule RulesteadAdmin.Live.ScheduleLive.ShowTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true

    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    on_exit(fn ->
      restore_env(:admin_policy, previous_policy)
      restore_env(:store, previous_store)
    end)

    now = ~U[2026-04-24 14:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)

    ensure_environment!("prod", "Production")
    seed_flag!("checkout-redesign", ["prod"])
    seed_flag!("incident-gate", ["prod"])
    seed_flag!("ops-banner", ["prod"])
    seed_flag!("legacy-toggle", ["prod"])

    scheduled = schedule_change_request!("checkout-redesign", "prod", ~U[2026-04-25 16:00:00Z])

    cancelled =
      schedule_direct!(
        "ops-banner",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 17:00:00Z],
        "corr-cancelled"
      )

    quarantined =
      schedule_direct!(
        "incident-gate",
        "prod",
        :engage_kill_switch,
        ~U[2026-04-25 18:00:00Z],
        "corr-quarantined"
      )

    completed =
      schedule_direct!(
        "legacy-toggle",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 19:00:00Z],
        "corr-completed"
      )

    failed =
      schedule_direct!(
        "checkout-redesign",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 20:00:00Z],
        "corr-failed"
      )

    assert {:ok, %{scheduled_execution: cancelled}} =
             Rulestead.cancel_scheduled_execution(
               Command.CancelScheduledExecution.new(cancelled.id,
                 actor: %{id: "operator-8", type: "operator", display: "Priya", roles: [:admin]},
                 reason: "The release train moved",
                 metadata: %{request_id: "req-cancelled", source: :admin_ui}
               )
             )

    quarantined =
      rewrite_execution_state(quarantined.id, %{
        state: "quarantined",
        attempt_count: 3,
        failure_reason: "Kill switch command was rejected by the downstream policy hook",
        execution_metadata: %{"quarantined_at" => "2026-04-25T18:04:00Z"}
      })

    completed =
      rewrite_execution_state(completed.id, %{
        state: "completed",
        executed_at: ~U[2026-04-25 19:03:00Z],
        attempt_count: 1,
        execution_metadata: %{
          "completed_at" => "2026-04-25T19:03:00Z",
          "completed_by" => "scheduler"
        }
      })

    failed =
      rewrite_execution_state(failed.id, %{
        state: "failed",
        attempt_count: 2,
        failure_reason: "Timed out while applying the publish command",
        execution_metadata: %{"failed_at" => "2026-04-25T20:02:00Z"}
      })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: "operator-8", email: "priya@example.com", display: "Priya"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok,
     conn: conn,
     scheduled: scheduled,
     cancelled: cancelled,
     quarantined: quarantined,
     completed: completed,
     failed: failed}
  end

  test "detail renders scheduled execution truth including status timing failure details and actor chain",
       %{
         conn: conn,
         scheduled: scheduled
       } do
    {:ok, _view, html} = live(conn, "/admin/flags/schedule/#{scheduled.id}?env=prod")

    assert html =~ scheduled.id
    assert html =~ "Status"
    assert html =~ "Scheduled"
    assert html =~ "Publish ruleset"
    assert html =~ "Change request"
    assert html =~ "Requested for"
    assert html =~ "2026-04-25 16:00 UTC"
    assert html =~ "Attempt count"
    assert html =~ "0"
    assert html =~ "scheduled by Scheduler One"
    assert html =~ "approved by Reviewer One"
    assert html =~ "executed by scheduler"
    assert html =~ "/admin/flags/checkout-redesign?env=prod"
    assert html =~ "/admin/flags/change-requests/#{scheduled.change_request_id}?env=prod"
    refute html =~ "Oban"
  end

  test "cancel and requeue stay explicit and require a reason before mutating", %{
    conn: conn,
    scheduled: scheduled,
    quarantined: quarantined
  } do
    {:ok, scheduled_view, _html} = live(conn, "/admin/flags/schedule/#{scheduled.id}?env=prod")

    scheduled_view
    |> form("#scheduled-execution-action-form", %{"action" => %{"reason" => ""}})
    |> render_submit()

    assert render(scheduled_view) =~ "Enter a reason before updating this execution"

    scheduled_view
    |> form("#scheduled-execution-action-form", %{
      "action" => %{"reason" => "Hold the launch for QA"}
    })
    |> render_submit()

    assert render(scheduled_view) =~ "Scheduled execution cancelled."
    assert render(scheduled_view) =~ "Hold the launch for QA"
    refute render(scheduled_view) =~ "Requeue execution"

    {:ok, requeue_view, _html} = live(conn, "/admin/flags/schedule/#{quarantined.id}?env=prod")

    assert render(requeue_view) =~ "Requeue execution"

    requeue_view
    |> form("#scheduled-execution-action-form", %{
      "action" => %{"reason" => "Retry after correcting the policy hook"}
    })
    |> render_submit()

    assert render(requeue_view) =~ "Scheduled execution requeued."
    assert render(requeue_view) =~ "Retry after correcting the policy hook"
    refute render(requeue_view) =~ "Cancellation is only available"
  end

  test "quarantined failed completed and cancelled records expose only the state-appropriate guidance",
       %{
         conn: conn,
         quarantined: quarantined,
         failed: failed,
         completed: completed,
         cancelled: cancelled
       } do
    {:ok, _view, quarantined_html} =
      live(conn, "/admin/flags/schedule/#{quarantined.id}?env=prod")

    assert quarantined_html =~ "Quarantined"
    assert quarantined_html =~ "Retry path"
    assert quarantined_html =~ "Requeue execution"
    assert quarantined_html =~ "Kill switch command was rejected by the downstream policy hook"

    {:ok, _view, failed_html} = live(conn, "/admin/flags/schedule/#{failed.id}?env=prod")

    assert failed_html =~ "Failed"
    assert failed_html =~ "Read-only recovery guidance"
    assert failed_html =~ "Timed out while applying the publish command"
    refute failed_html =~ "Requeue execution"
    refute failed_html =~ "Cancel execution"

    {:ok, _view, completed_html} = live(conn, "/admin/flags/schedule/#{completed.id}?env=prod")

    assert completed_html =~ "Completed"
    assert completed_html =~ "History only"
    assert completed_html =~ "2026-04-25 19:03 UTC"
    refute completed_html =~ "Cancel execution"

    {:ok, _view, cancelled_html} = live(conn, "/admin/flags/schedule/#{cancelled.id}?env=prod")

    assert cancelled_html =~ "Cancelled"
    assert cancelled_html =~ "History only"
    assert cancelled_html =~ "The release train moved"
    refute cancelled_html =~ "Requeue execution"
  end

  defp schedule_change_request!(flag_key, environment_key, scheduled_for) do
    actor = %{id: "requester-1", type: "operator", display: "Requester One", roles: [:operator]}
    reviewer = %{id: "reviewer-1", type: "operator", display: "Reviewer One", roles: [:operator]}

    scheduler = %{
      id: "scheduler-1",
      type: "operator",
      display: "Scheduler One",
      roles: [:operator]
    }

    assert {:ok, %{change_request: change_request}} =
             Rulestead.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :publish_ruleset,
                   environment_key: environment_key,
                   resource_type: "flag",
                   resource_key: flag_key,
                   command: %{"version" => 2},
                   approval_requirement:
                     ApprovalRequirement.new(
                       action: :publish_ruleset,
                       environment_key: environment_key,
                       required_approvals: 1,
                       change_request_required?: true,
                       self_approval_allowed?: true
                     )
                 },
                 actor: actor,
                 reason: "Schedule a reviewed publish",
                 metadata: %{request_id: "req-submit-#{flag_key}", source: :admin_ui}
               )
             )

    assert {:ok, %{change_request: approved}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(change_request.id,
                 actor: reviewer,
                 reason: "Approved for launch window",
                 metadata: %{request_id: "req-approve-#{flag_key}", source: :admin_ui}
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             Rulestead.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: scheduled_for,
                 actor: scheduler,
                 reason: "Wait for the release window",
                 metadata: %{request_id: "req-schedule-#{flag_key}", source: :admin_ui}
               })
             )

    scheduled_execution
  end

  defp schedule_direct!(flag_key, environment_key, action, scheduled_for, correlation_id) do
    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             Rulestead.schedule_governed_action(
               Command.ScheduleGovernedAction.new(%{
                 action: action,
                 environment_key: environment_key,
                 resource_type: "flag",
                 resource_key: flag_key,
                 command: %{"version" => 2},
                 scheduled_for: scheduled_for,
                 execution_mode: :policy_bypass,
                 actor: %{
                   id: "scheduler-2",
                   type: "operator",
                   display: "Ops Scheduler",
                   roles: [:operator]
                 },
                 reason: "Seed schedule state",
                 approval_requirement:
                   ApprovalRequirement.new(
                     action: action,
                     environment_key: environment_key,
                     required_approvals: 0,
                     change_request_required?: false,
                     self_approval_allowed?: true
                   ),
                 metadata: %{request_id: correlation_id, source: :admin_ui}
               })
             )

    scheduled_execution
  end

  defp rewrite_execution_state(id, attrs) do
    state = Control.snapshot!()
    scheduled_execution = Map.fetch!(state.scheduled_executions, id)
    updated = Map.merge(scheduled_execution, attrs)
    Control.restore!(put_in(state.scheduled_executions[id], updated))

    Rulestead.fetch_scheduled_execution(Command.FetchScheduledExecution.new(id))
    |> then(fn {:ok, %{scheduled_execution: scheduled_execution}} -> scheduled_execution end)
  end

  defp seed_flag!(key, environment_keys) do
    assert {:ok, _payload} =
             Rulestead.create_flag(%{
               key: key,
               owner: "growth",
               tags: ["ops"],
               description: "#{key} flag",
               expected_expiration: ~D[2026-05-01],
               permanent: false,
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               environment_keys: environment_keys
             })
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end

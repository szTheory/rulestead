defmodule RulesteadAdmin.Live.ScheduleLive.IndexTest do
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
    ensure_environment!("staging", "Staging")

    seed_flag!("checkout-redesign", ["prod", "staging"])
    seed_flag!("kill-switch", ["prod"])
    seed_flag!("copy-refresh", ["prod"])
    seed_flag!("beta-banner", ["prod"])
    seed_flag!("incident-gate", ["prod"])
    seed_flag!("legacy-toggle", ["prod"])

    with_change_request =
      schedule_change_request!("checkout-redesign", "prod", ~U[2026-04-25 13:00:00Z])

    running =
      schedule_direct!(
        "kill-switch",
        "prod",
        :release_kill_switch,
        ~U[2026-04-25 13:30:00Z],
        "corr-running"
      )

    completed =
      schedule_direct!(
        "copy-refresh",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 14:00:00Z],
        "corr-completed"
      )

    failed =
      schedule_direct!(
        "beta-banner",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 14:30:00Z],
        "corr-failed"
      )

    quarantined =
      schedule_direct!(
        "incident-gate",
        "prod",
        :engage_kill_switch,
        ~U[2026-04-25 15:00:00Z],
        "corr-quarantined"
      )

    cancelled =
      schedule_direct!(
        "legacy-toggle",
        "prod",
        :publish_ruleset,
        ~U[2026-04-25 15:30:00Z],
        "corr-cancelled"
      )

    staging_only =
      schedule_direct!(
        "checkout-redesign",
        "staging",
        :publish_ruleset,
        ~U[2026-04-26 10:00:00Z],
        "corr-staging"
      )

    rewrite_execution_state(running.id, %{
      state: "running",
      execution_metadata: %{"started_at" => "2026-04-25T13:31:00Z"},
      attempt_count: 1
    })

    rewrite_execution_state(completed.id, %{
      state: "completed",
      executed_at: ~U[2026-04-25 14:04:00Z],
      execution_metadata: %{"completed_at" => "2026-04-25T14:04:00Z"},
      attempt_count: 1
    })

    rewrite_execution_state(failed.id, %{
      state: "failed",
      failure_reason: "Timed out waiting for approval snapshot refresh",
      execution_metadata: %{"failed_at" => "2026-04-25T14:34:00Z"},
      attempt_count: 2
    })

    rewrite_execution_state(quarantined.id, %{
      state: "quarantined",
      failure_reason: "Version 9 was not available to publish",
      execution_metadata: %{"quarantined_at" => "2026-04-25T15:05:00Z"},
      attempt_count: 3
    })

    rewrite_execution_state(cancelled.id, %{
      state: "cancelled",
      failure_reason: "Launch window moved to next week",
      execution_metadata: %{"cancelled_at" => "2026-04-25T15:10:00Z"}
    })

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: "operator-7", email: "priya@example.com", display: "Priya"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok,
     conn: conn,
     with_change_request: with_change_request,
     running: running,
     completed: completed,
     failed: failed,
     quarantined: quarantined,
     cancelled: cancelled,
     staging_only: staging_only}
  end

  test "schedule page defaults to a dense env-aware list instead of a calendar-first interface",
       %{conn: conn} do
    {:ok, view, html} = live(conn, "/admin/flags/schedule?env=prod")

    assert html =~ "Scheduled changes"
    assert has_element?(view, ".rs-shell__header [aria-label='Access']", "Admin")
    refute has_element?(view, "main aside.rs-policy-state")
    assert html =~ "Dense operator list"
    assert html =~ "State filters"
    assert html =~ "Requested for"
    assert html =~ "Execution result"
    refute html =~ "Calendar view"
    refute html =~ "Oban"

    refute html =~ "corr-staging"
    refute html =~ "checkout-redesign?env=staging"

    {:ok, _view, filtered_html} = live(conn, "/admin/flags/schedule?env=prod&state=failed")

    assert filtered_html =~ "Filtered to failed executions"
    assert filtered_html =~ "Timed out waiting for approval snapshot refresh"
    refute filtered_html =~ "Running"
    refute filtered_html =~ "Cancelled"
  end

  test "operators can scan every required status group with links to the flag and change request when present",
       %{
         conn: conn,
         with_change_request: with_change_request
       } do
    {:ok, _view, html} = live(conn, "/admin/flags/schedule?env=prod")

    for state_label <- ["Scheduled", "Running", "Completed", "Failed", "Quarantined", "Cancelled"] do
      assert html =~ state_label
    end

    assert html =~ with_change_request.id

    assert html =~
             "/admin/flags/change-requests/#{with_change_request.change_request_id}?env=prod"

    assert html =~ "/admin/flags/checkout-redesign?env=prod"
    assert html =~ "/admin/flags/schedule/#{with_change_request.id}?env=prod"
    assert html =~ "scheduled by Scheduler One"
    assert html =~ "approved by Reviewer One"
    assert html =~ "executed by scheduler"
    assert html =~ "Version 9 was not available to publish"
    assert html =~ "Launch window moved to next week"
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

defmodule RulesteadAdmin.Live.GovernanceRouteContractTest do
  use RulesteadAdmin.ConnCase, async: false

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com", roles: ["admin", "auditor"]},
        "rulestead_admin_last_env" => "staging",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "mounted governance routes keep env canonical and render route-backed placeholders", %{
    conn: conn
  } do
    assert {:error, {:live_redirect, %{to: "/admin/flags/change-requests?env=staging"}}} =
             live(conn, "/admin/flags/change-requests")

    {:ok, _view, queue_html} = live(conn, "/admin/flags/change-requests?env=staging")

    assert queue_html =~ "Change requests"
    assert queue_html =~ "Governance navigation"
    assert queue_html =~ "/admin/flags?env=staging"
    assert queue_html =~ "/admin/flags/change-requests?env=staging"
    assert queue_html =~ "/admin/flags/schedule?env=staging"
    assert queue_html =~ "/admin/flags/audit?env=staging"
    assert queue_html =~ "/admin/flags/change-requests/req-123?env=staging"

    assert queue_html =~
             "This queue stays route-backed so review and execution work can grow without crowding flag detail."

    assert {:error, {:live_redirect, %{to: "/admin/flags/change-requests/req-123?env=staging"}}} =
             live(conn, "/admin/flags/change-requests/req-123")

    {:ok, _view, queue_show_html} = live(conn, "/admin/flags/change-requests/req-123?env=staging")

    assert queue_show_html =~ "Change request review"
    assert queue_show_html =~ "/admin/flags/change-requests/req-123?env=staging"
    assert queue_show_html =~ "/admin/flags/change-requests?env=staging"

    assert queue_show_html =~
             "Review stays on its own route so approvals, rejection, execution, and scheduling remain explicit."

    assert {:error, {:live_redirect, %{to: "/admin/flags/schedule?env=staging"}}} =
             live(conn, "/admin/flags/schedule")

    {:ok, _view, schedule_html} = live(conn, "/admin/flags/schedule?env=staging")

    assert schedule_html =~ "Schedule"
    assert schedule_html =~ "Governance navigation"
    assert schedule_html =~ "/admin/flags?env=staging"
    assert schedule_html =~ "/admin/flags/change-requests?env=staging"
    assert schedule_html =~ "/admin/flags/schedule?env=staging"
    assert schedule_html =~ "/admin/flags/audit?env=staging"
    assert schedule_html =~ "/admin/flags/schedule/sched-456?env=staging"

    assert schedule_html =~
             "Scheduled execution visibility stays list-first so operators can scan state without a calendar workbench."

    assert {:error, {:live_redirect, %{to: "/admin/flags/schedule/sched-456?env=staging"}}} =
             live(conn, "/admin/flags/schedule/sched-456")

    {:ok, _view, schedule_show_html} = live(conn, "/admin/flags/schedule/sched-456?env=staging")

    assert schedule_show_html =~ "Scheduled execution"
    assert schedule_show_html =~ "/admin/flags/schedule/sched-456?env=staging"
    assert schedule_show_html =~ "/admin/flags/schedule?env=staging"

    assert schedule_show_html =~
             "Execution detail remains route-backed so retries, quarantine context, and audit links stay explicit."
  end

  test "mounted governance routes accept canonical env query params", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/schedule/sched-456?env=prod")

    assert html =~ "Production"
    assert html =~ "Governance navigation"
    assert html =~ "/admin/flags?env=prod"
    assert html =~ "/admin/flags/schedule/sched-456?env=prod"
    assert html =~ "/admin/flags/change-requests?env=prod"
    assert html =~ "/admin/flags/audit?env=prod"
  end
end

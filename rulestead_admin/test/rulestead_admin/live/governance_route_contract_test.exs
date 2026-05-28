defmodule RulesteadAdmin.Live.GovernanceRouteContractTest do
  use RulesteadAdmin.ConnCase, async: false

  setup_all do
    start_supervised!(RulesteadAdmin.TestEndpoint)
    :ok
  end

  setup %{conn: conn} do
    ensure_environment!("staging", "Staging")
    ensure_environment!("prod", "Production")

    {:ok, %{change_request: cr}} =
      Rulestead.submit_change_request(
        Command.SubmitChangeRequest.new(
          %{
            action: :publish_ruleset,
            environment_key: "staging",
            resource_type: :flag,
            resource_key: "checkout-redesign",
            command: %{"version" => 1},
            approval_requirement: %{required_approvals: 1}
          },
          actor: %{id: "op-1", display: "Op 1"},
          reason: "test"
        )
      )

    {:ok, _} =
      Rulestead.approve_change_request(
        Command.ApproveChangeRequest.new(
          cr.id,
          actor: %{id: "op-2", display: "Op 2"}
        )
      )

    {:ok, %{scheduled_execution: sched}} =
      Rulestead.schedule_change_request(
        Command.ScheduleChangeRequest.new(
          %{
            change_request_id: cr.id,
            scheduled_for: ~U[2026-04-24 16:00:00Z]
          },
          actor: %{id: "op-1", display: "Op 1"}
        )
      )

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

    {:ok, conn: conn, change_request_id: cr.id, scheduled_execution_id: sched.id}
  end

  test "mounted governance routes keep env canonical and render route-backed placeholders", %{
    conn: conn,
    change_request_id: cr_id,
    scheduled_execution_id: sched_id
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
    assert queue_html =~ "/admin/flags/change-requests/#{cr_id}?env=staging"

    assert queue_html =~
             "Dedicated review queue"

    expected_cr_redirect = "/admin/flags/change-requests/#{cr_id}?env=staging"

    assert {:error, {:live_redirect, %{to: ^expected_cr_redirect}}} =
             live(conn, "/admin/flags/change-requests/#{cr_id}")

    {:ok, _view, queue_show_html} = live(conn, expected_cr_redirect)

    assert queue_show_html =~ "Change request review"
    assert queue_show_html =~ expected_cr_redirect
    assert queue_show_html =~ "/admin/flags/change-requests?env=staging"

    assert {:error, {:live_redirect, %{to: "/admin/flags/schedule?env=staging"}}} =
             live(conn, "/admin/flags/schedule")

    {:ok, _view, schedule_html} = live(conn, "/admin/flags/schedule?env=staging")

    assert schedule_html =~ "Schedule"
    assert schedule_html =~ "Governance navigation"
    assert schedule_html =~ "/admin/flags?env=staging"
    assert schedule_html =~ "/admin/flags/change-requests?env=staging"
    assert schedule_html =~ "/admin/flags/schedule?env=staging"
    assert schedule_html =~ "/admin/flags/audit?env=staging"

    expected_sched_path = "/admin/flags/schedule/#{sched_id}?env=staging"
    assert schedule_html =~ expected_sched_path

    assert {:error, {:live_redirect, %{to: ^expected_sched_path}}} =
             live(conn, "/admin/flags/schedule/#{sched_id}")

    {:ok, _view, schedule_show_html} = live(conn, expected_sched_path)

    assert schedule_show_html =~ "Scheduled execution"
    assert schedule_show_html =~ "/admin/flags/schedule/#{sched_id}?env=staging"
    assert schedule_show_html =~ "/admin/flags/schedule?env=staging"
  end

  test "audience governance reuses existing audience preview and confirm routes only" do
    router_source =
      Path.join([__DIR__, "..", "..", "..", "lib", "rulestead_admin", "router.ex"])
      |> File.read!()

    for path <- [
          "/audiences/:audience_key/edit/preview",
          "/audiences/:audience_key/edit/confirm",
          "/audiences/:audience_key/archive/preview",
          "/audiences/:audience_key/archive/confirm"
        ] do
      assert router_source =~ ~r/live\s*\(\s*"#{Regex.escape(path)}"/
    end

    refute router_source =~ ~r/live\("[^"]*governance/
    refute router_source =~ ~r/live\("[^"]*proposal/
  end

  test "mounted governance routes accept canonical env query params", %{
    conn: conn,
    scheduled_execution_id: sched_id
  } do
    {:ok, _view, html} = live(conn, "/admin/flags/schedule/#{sched_id}?env=prod")

    assert html =~ "Production"
    assert html =~ "Governance navigation"
    assert html =~ "/admin/flags?env=prod"
    assert html =~ "/admin/flags/schedule/#{sched_id}?env=prod"
    assert html =~ "/admin/flags/change-requests?env=prod"
    assert html =~ "/admin/flags/audit?env=prod"
  end

  defp ensure_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end
end

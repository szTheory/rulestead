defmodule RulesteadAdmin.Live.ScheduleLive.AccessibilityTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command
  alias RulesteadAdmin.TestSupport.AxeAudit

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

    scheduled =
      seed_change_request_schedule!("checkout-redesign", "prod", ~U[2026-04-25 16:00:00Z])

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

    {:ok, conn: conn, scheduled: scheduled}
  end

  test "schedule list and detail pages pass the accessibility audit", %{
    conn: conn,
    scheduled: scheduled
  } do
    {:ok, view, index_html} = live(conn, "/admin/flags/schedule?env=prod")
    AxeAudit.assert_accessible!(index_html)

    assert has_element?(view, "a[href='/admin/flags/schedule?env=prod&state=scheduled']")

    {:ok, _filtered_view, filtered_html} =
      live(conn, "/admin/flags/schedule?env=prod&state=scheduled")

    AxeAudit.assert_accessible!(filtered_html)

    {:ok, detail_view, detail_html} = live(conn, "/admin/flags/schedule/#{scheduled.id}?env=prod")
    AxeAudit.assert_accessible!(detail_html)

    confirm_html =
      detail_view
      |> form("#scheduled-execution-action-form", %{"action" => %{"reason" => ""}})
      |> render_submit()

    AxeAudit.assert_accessible!(confirm_html)
  end

  defp seed_change_request_schedule!(flag_key, environment_key, scheduled_for) do
    approval_requirement =
      ApprovalRequirement.new(
        action: :publish_ruleset,
        environment_key: environment_key,
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: true
      )

    assert {:ok, %{change_request: change_request}} =
             Rulestead.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :publish_ruleset,
                   environment_key: environment_key,
                   resource_type: "flag",
                   resource_key: flag_key,
                   command: %{
                     "diff" => %{"title" => "Publish ruleset v2", "summary" => "Operator preview"}
                   },
                   approval_requirement: approval_requirement
                 },
                 actor: %{id: "requester-1", display: "Requester One"},
                 reason: "Queue publish"
               )
             )

    assert {:ok, %{change_request: approved}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(change_request.id,
                 actor: %{id: "reviewer-1", display: "Reviewer One"},
                 reason: "Approved for schedule"
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             Rulestead.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: scheduled_for,
                 actor: %{id: "scheduler-1", display: "Scheduler One"},
                 reason: "Wait for low-traffic window"
               })
             )

    scheduled_execution
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

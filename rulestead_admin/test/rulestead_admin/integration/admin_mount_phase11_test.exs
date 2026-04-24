defmodule RulesteadAdmin.Integration.AdminMountPhase11Test do
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

    submitted = seed_change_request!("checkout-redesign", "prod", "Publish ruleset v2")

    assert {:ok, %{change_request: approved}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(submitted.id,
                 actor: %{id: "reviewer-1", display: "Reviewer One"},
                 reason: "Approved for prod"
               )
             )

    assert {:ok, %{scheduled_execution: scheduled_execution}} =
             Rulestead.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: ~U[2026-04-25 16:00:00Z],
                 actor: %{id: "scheduler-1", display: "Scheduler One"},
                 reason: "Wait for the maintenance window"
               })
             )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{
          id: "operator-9",
          email: "host-admin@example.com",
          display: "Host Admin"
        },
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok,
     conn: conn,
     submitted: submitted,
     approved: approved,
     scheduled_execution: scheduled_execution}
  end

  test "host-style mount reaches phase 11 governance and schedule routes with canonical env state",
       %{
         conn: conn,
         submitted: submitted,
         approved: approved,
         scheduled_execution: scheduled_execution
       } do
    {:ok, _queue_view, queue_html} = live(conn, "/admin/flags/change-requests?env=prod")
    assert queue_html =~ "Review queue"
    assert queue_html =~ "/admin/flags/change-requests?env=prod"

    {:ok, _submitted_view, submitted_html} =
      live(conn, "/admin/flags/change-requests/#{submitted.id}?env=prod")

    assert submitted_html =~ "Proposed change"
    assert submitted_html =~ "Approve"

    {:ok, _approved_view, approved_html} =
      live(conn, "/admin/flags/change-requests/#{approved.id}?env=prod")

    assert approved_html =~ "Execute now"
    assert approved_html =~ "Schedule"

    {:ok, _schedule_view, schedule_html} = live(conn, "/admin/flags/schedule?env=prod")
    assert schedule_html =~ "Dense operator list"
    assert schedule_html =~ "/admin/flags/schedule/#{scheduled_execution.id}?env=prod"

    {:ok, _schedule_detail_view, schedule_detail_html} =
      live(conn, "/admin/flags/schedule/#{scheduled_execution.id}?env=prod")

    assert schedule_detail_html =~ "Scheduled execution"
    assert schedule_detail_html =~ "/admin/flags/change-requests/#{approved.id}?env=prod"
  end

  defp seed_change_request!(flag_key, environment_key, title) do
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
                   command: %{"diff" => %{"title" => title, "summary" => "Operator preview"}},
                   approval_requirement: approval_requirement
                 },
                 actor: %{id: "requester-1", display: "Requester One"},
                 reason: "Open governed review"
               )
             )

    change_request
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

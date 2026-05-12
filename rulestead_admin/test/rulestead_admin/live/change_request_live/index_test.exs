defmodule RulesteadAdmin.Live.ChangeRequestLive.IndexTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_, _, _, _), do: false
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
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    now = ~U[2026-04-24 10:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)

    seed_change_request!(
      env: "staging",
      action: :publish_ruleset,
      resource_key: "checkout-redesign",
      actor_id: "op-1",
      actor_display: "Priya",
      diff_title: "Publish ruleset v2"
    )

    seed_change_request!(
      env: "staging",
      action: :advance_rollout,
      resource_key: "search-ranking",
      actor_id: "op-2",
      actor_display: "Noah",
      diff_title: "Advance rollout to 50%"
    )

    seed_change_request!(
      env: "prod",
      action: :engage_kill_switch,
      resource_key: "billing-fallback",
      actor_id: "op-3",
      actor_display: "Ava",
      diff_title: "Engage kill switch"
    )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "reviewer@example.com"},
        "rulestead_admin_last_env" => "staging",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "queue lists change requests by environment with filters, badges, and deep links", %{
    conn: conn
  } do
    {:ok, view, html} =
      live(
        conn,
        "/admin/flags/change-requests?env=staging&status=submitted&action=publish_ruleset&resource=checkout"
      )

    assert html =~ "Review queue"
    assert html =~ "checkout-redesign"
    assert html =~ "Publish ruleset"
    assert html =~ "Submitted"
    assert html =~ "/admin/flags/change-requests?"
    assert html =~ "status=submitted"
    assert html =~ "action=publish_ruleset"
    assert html =~ "resource=checkout"
    assert html =~ "/admin/flags/checkout-redesign?env=staging"
    refute html =~ "billing-fallback"
    refute html =~ "search-ranking"

    assert has_element?(
             view,
             "a[href^='/admin/flags/change-requests/'][href*='env=staging'][href*='status=submitted']"
           )
  end

  defp seed_change_request!(attrs) do
    approval_requirement =
      ApprovalRequirement.new(
        action: attrs[:action],
        environment_key: attrs[:env],
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: false
      )

    assert {:ok, _payload} =
             Rulestead.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: attrs[:action],
                   environment_key: attrs[:env],
                   resource_type: "flag",
                   resource_key: attrs[:resource_key],
                   command: %{
                     "diff" => %{
                       "title" => attrs[:diff_title],
                       "summary" => "Operator preview"
                     }
                   },
                   approval_requirement: approval_requirement
                 },
                 actor: %{id: attrs[:actor_id], display: attrs[:actor_display]}
               )
             )
  end
end

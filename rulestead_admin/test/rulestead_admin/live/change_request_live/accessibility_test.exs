defmodule RulesteadAdmin.Live.ChangeRequestLive.AccessibilityTest do
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

    now = ~U[2026-04-24 12:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    ensure_environment!("staging", "Staging")
    seed_flag!("checkout-redesign", ["staging"])

    submitted = seed_change_request!("checkout-redesign", "staging", "Publish ruleset v2")
    approved = seed_change_request!("checkout-redesign", "staging", "Emergency kill switch")

    assert {:ok, %{change_request: _approved}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(approved.id,
                 actor: %{id: "reviewer-1", display: "Reviewer One"},
                 reason: "Approved for follow-through"
               )
             )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{
          id: "reviewer-7",
          email: "reviewer@example.com",
          display: "Priya Reviewer"
        },
        "rulestead_admin_last_env" => "staging",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn, submitted: submitted}
  end

  test "change-request queue and detail pages pass the accessibility audit", %{
    conn: conn,
    submitted: submitted
  } do
    {:ok, view, queue_html} = live(conn, "/admin/flags/change-requests?env=staging")
    AxeAudit.assert_accessible!(queue_html)

    assert has_element?(view, "form.rs-filter-grid")

    {:ok, _filtered_view, filtered_html} =
      live(
        conn,
        "/admin/flags/change-requests?env=staging&status=submitted&action=publish_ruleset&resource=checkout"
      )

    AxeAudit.assert_accessible!(filtered_html)

    {:ok, detail_view, detail_html} =
      live(conn, "/admin/flags/change-requests/#{submitted.id}?env=staging")

    AxeAudit.assert_accessible!(detail_html)

    confirm_html =
      detail_view
      |> element("button[phx-value-action='approve']")
      |> render_click()

    AxeAudit.assert_accessible!(confirm_html)
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

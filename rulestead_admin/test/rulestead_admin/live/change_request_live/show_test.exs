defmodule RulesteadAdmin.Live.ChangeRequestLive.ShowTest do
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

  defmodule GovernanceTestPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule DenyFlagReadsPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, :read_flags, _resource, _environment_key), do: false

    @impl true
    def can?(_actor, action, _resource, _environment_key)
        when action in [
               :list_audiences,
               :list_audience_dependencies,
               :read,
               :submit_change_request
             ],
        do: true

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: true

    @impl true
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
    seed_flag!("billing-fallback", ["staging"])

    submitted =
      seed_change_request!("checkout-redesign", "staging", :publish_ruleset, "Publish ruleset v2")

    approved =
      seed_change_request!(
        "billing-fallback",
        "staging",
        :engage_kill_switch,
        "Engage kill switch"
      )

    approve_change_request!(approved.id, "Approved for operator drill")

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

    {:ok, conn: conn, submitted: submitted, approved: approved}
  end

  test "review page shows the diff first and keeps approve reject primary before execution", %{
    conn: conn,
    submitted: submitted
  } do
    {:ok, _view, html} = live(conn, "/admin/flags/change-requests/#{submitted.id}?env=staging")

    assert html =~ "Proposed change"
    assert html =~ "Publish ruleset v2"
    assert html =~ "requested by Requester One"
    assert html =~ "Required approvals: 1"
    assert html =~ "Approve"
    assert html =~ "Reject"
    refute html =~ "Execute now"
  end

  test "approval requires confirmation and does not auto execute the request", %{
    conn: conn,
    submitted: submitted
  } do
    {:ok, view, _html} = live(conn, "/admin/flags/change-requests/#{submitted.id}?env=staging")

    view |> element("button[phx-value-action='approve']") |> render_click()
    assert render(view) =~ "Confirm Approve before mutation."

    view
    |> form("#change-request-action-form", %{"action" => %{"reason" => ""}})
    |> render_submit()

    assert render(view) =~ "Enter a reason before continuing"

    view
    |> form("#change-request-action-form", %{"action" => %{"reason" => "Looks safe to merge"}})
    |> render_submit()

    assert render(view) =~ "Change request approved."
    assert render(view) =~ "Audit state: change_request.approved"
    assert render(view) =~ "Execute now"
    assert render(view) =~ "Schedule"
    refute render(view) =~ "Change request executed."
  end

  test "execute and schedule stay explicit and require confirm step with audit-linked result", %{
    conn: conn,
    approved: approved
  } do
    {:ok, execute_view, _html} =
      live(conn, "/admin/flags/change-requests/#{approved.id}?env=staging")

    execute_view |> element("button[phx-value-action='execute']") |> render_click()

    execute_view
    |> form("#change-request-action-form", %{"action" => %{"reason" => "Run it now"}})
    |> render_submit()

    assert render(execute_view) =~ "Change request executed."
    assert render(execute_view) =~ "Audit state: change_request.merged"

    approved_again =
      seed_change_request!(
        "billing-fallback",
        "staging",
        :engage_kill_switch,
        "Emergency kill switch"
      )

    approve_change_request!(approved_again.id, "Approved for schedule")

    {:ok, schedule_view, _html} =
      live(conn, "/admin/flags/change-requests/#{approved_again.id}?env=staging")

    schedule_view |> element("button[phx-value-action='schedule']") |> render_click()

    schedule_view
    |> form("#change-request-action-form", %{
      "action" => %{
        "reason" => "Wait for the maintenance window",
        "scheduled_for" => "2026-04-25T16:00"
      }
    })
    |> render_submit()

    assert render(schedule_view) =~ "Change request scheduled."
    assert render(schedule_view) =~ "Audit state: change_request.approved"
    assert render(schedule_view) =~ "Open scheduled execution"
  end

  describe "audience mutation governance evidence" do
    setup %{conn: conn} do
      previous_policy = Application.get_env(:rulestead, :admin_policy)
      on_exit(fn -> restore_env(:admin_policy, previous_policy) end)

      Application.put_env(:rulestead, :admin_policy, AllowPolicy)
      Control.reset!()
      change_request = seed_prod_audience_mutation_change_request!()

      conn =
        Phoenix.ConnTest.init_test_session(conn, %{
          "current_actor" => %{
            id: "reviewer-7",
            email: "reviewer@example.com",
            display: "Priya Reviewer"
          },
          "rulestead_admin_last_env" => "prod",
          "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}]
        })

      {:ok, conn: conn, change_request: change_request}
    end

    test "renders frozen blast-radius evidence from submission metadata", %{
      conn: conn,
      change_request: change_request
    } do
      {:ok, _view, html} =
        live(conn, "/admin/flags/change-requests/#{change_request.id}?env=prod")

      assert html =~ "Evidence frozen at submission"
      assert html =~ "Governance required"
      assert html =~ "blast_radius_above_threshold"
      assert html =~ "Audience Update"
      assert html =~ "vip-users"
    end
  end

  describe "audience mutation approve visibility gate" do
    setup %{conn: conn} do
      previous_policy = Application.get_env(:rulestead, :admin_policy)
      on_exit(fn -> restore_env(:admin_policy, previous_policy) end)

      Application.put_env(:rulestead, :admin_policy, AllowPolicy)
      Control.reset!()
      change_request = seed_prod_audience_mutation_change_request!()
      Application.put_env(:rulestead, :admin_policy, DenyFlagReadsPolicy)

      conn =
        Phoenix.ConnTest.init_test_session(conn, %{
          "current_actor" => %{
            id: "reviewer-7",
            email: "reviewer@example.com",
            display: "Priya Reviewer"
          },
          "rulestead_admin_last_env" => "prod",
          "rulestead_admin_environments" => [%{"key" => "prod", "name" => "Production"}]
        })

      {:ok, conn: conn, change_request: change_request}
    end

    test "hides approve when dependency visibility is partial", %{
      conn: conn,
      change_request: change_request
    } do
      {:ok, _view, html} =
        live(conn, "/admin/flags/change-requests/#{change_request.id}?env=prod")

      assert html =~ "Broader flag read access required to approve this change."
      refute html =~ ~s/phx-value-action="approve"/
      assert html =~ "Reject"
    end
  end

  defp seed_change_request!(flag_key, environment_key, action, title) do
    approval_requirement =
      ApprovalRequirement.new(
        action: action,
        environment_key: environment_key,
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: true
      )

    assert {:ok, %{change_request: change_request}} =
             Rulestead.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: action,
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

  defp approve_change_request!(change_request_id, reason) do
    assert {:ok, %{change_request: _change_request}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(change_request_id,
                 actor: %{id: "reviewer-1", display: "Reviewer One"},
                 reason: reason
               )
             )
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

  defp seed_prod_audience_mutation_change_request! do
    Control.put_environment!(%{key: "prod", name: "Production"})
    Control.put_audience!(%{key: "vip-users", description: "VIP"})

    for {flag_key, rule_key} <- [
          {"checkout", "vip-rule"},
          {"checkout-b", "vip-rule-b"},
          {"checkout-c", "vip-rule-c"}
        ] do
      Control.put_flag!(%{
        key: flag_key,
        description: "Checkout #{flag_key}",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "growth",
        permanent: true,
        expected_expiration: nil,
        environment_keys: ["prod"]
      })

      publish_ruleset!(flag_key, "prod", %{
        salt: "#{flag_key}:prod",
        rules: [
          %{key: rule_key, strategy: :segment_match, audience_key: "vip-users", conditions: []}
        ]
      })
    end

    Control.rebuild_audience_reference_projection!()

    {:ok, audiences} = Rulestead.list_audiences(include_archived?: true)
    audience = Enum.find(audiences, &(&1.key == "vip-users"))

    {:ok, preview} =
      Rulestead.preview_audience_impact("vip-users", :update,
        environment_key: "prod",
        after_definition: audience.definition,
        reason: "CR show governance test"
      )

    approval_requirement =
      ApprovalRequirement.new(
        action: :apply_audience_mutation,
        environment_key: "prod",
        required_approvals: 1,
        change_request_required?: true,
        self_approval_allowed?: true
      )

    command_map = %{
      "audience_key" => "vip-users",
      "environment_key" => "prod",
      "operation" => "update",
      "preview_schema_version" => preview.preview_schema_version,
      "preview_fingerprint" => preview.preview_fingerprint,
      "preview_basis" => preview.preview_basis,
      "affected_reference_keys" =>
        preview.affected_references
        |> Enum.map(& &1.reference_key)
        |> Enum.sort()
    }

    assert {:ok, %{change_request: change_request}} =
             Rulestead.submit_change_request(
               Command.SubmitChangeRequest.new(
                 %{
                   action: :apply_audience_mutation,
                   environment_key: "prod",
                   resource_type: "audience",
                   resource_key: "vip-users",
                   command: command_map,
                   approval_requirement: approval_requirement
                 },
                 actor: %{id: "requester-1", display: "Requester One"},
                 reason: "Governed audience update for review"
               )
             )

    change_request
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset) do
    %{version: version} =
      Rulestead.save_draft_ruleset!(
        Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset)
      )

    Rulestead.publish_ruleset!(
      Command.PublishRuleset.new(flag_key, environment_key, version: version)
    )
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)
end

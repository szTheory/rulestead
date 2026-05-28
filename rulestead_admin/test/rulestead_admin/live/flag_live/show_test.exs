defmodule RulesteadAdmin.Live.FlagLive.ShowTest do
  use RulesteadAdmin.ConnCase, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Governance.ApprovalRequirement
  alias Rulestead.Store.Command

  @admin_actor %{id: 7, email: "priya@example.com", roles: [:admin]}

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, _action, _resource, _environment_key), do: true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule AuditRestrictedPolicy do
    @behaviour Rulestead.Admin.Policy

    def can?(_actor, :list_audit_events, _resource, _environment_key), do: false
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
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, AllowPolicy)

    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    now = ~U[2026-04-23 16:00:00Z]
    Control.reset!(now: now)
    Control.set_now!(now)
    seed_environment!("prod", "Production")
    seed_environment!("staging", "Staging")

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      description: "Checkout experiment for the new payment flow",
      expected_expiration: ~D[2026-05-01],
      permanent: false,
      environment_keys: ["prod", "staging"]
    )

    seed_flag!(
      key: "ops-cleanup",
      owner: "ops",
      tags: ["infra"],
      description: "Ops cleanup candidate",
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      environment_keys: ["prod"],
      code_reference_count: 0,
      code_refs_scan: %{received_at: DateTime.add(now, -600, :second), reference_count: 0}
    )

    seed_flag!(
      key: "remote-config-review",
      owner: "ops",
      tags: ["config"],
      description: "Remote config needs review",
      expected_expiration: ~D[2026-04-20],
      permanent: false,
      environment_keys: ["prod"],
      flag_type: :remote_config
    )

    publish_flag!("checkout-redesign", "prod")
    save_draft!("checkout-redesign", "prod", 2, false)
    save_draft!("checkout-redesign", "staging", 1, true)
    publish_flag!("ops-cleanup", "prod")
    publish_flag!("remote-config-review", "prod")
    seed_change_request!("checkout-redesign", "prod")

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "checkout-redesign",
               "prod",
               DateTime.add(now, -600, :second)
             )

    assert {:ok, _} =
             Rulestead.record_evaluation(
               "ops-cleanup",
               "prod",
               DateTime.add(now, -7_200, :second)
             )

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 7, email: "priya@example.com"},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, conn: conn}
  end

  test "detail shows description, type, default value, owner, tags, lifecycle, and per-environment status",
       %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Checkout experiment for the new payment flow"
    assert html =~ "Release"
    assert html =~ "Boolean"
    assert html =~ "false"
    assert html =~ "growth"
    assert html =~ "Kind:"
    assert html =~ "Reference:"
    assert html =~ "checkout"
    assert html =~ "Production"
    assert html =~ "Staging"
    assert html =~ "Lifecycle"
    assert html =~ "Active"
    assert html =~ "Lifecycle posture"
  end

  test "detail links to the dedicated phase 7 routes and keeps audit summary on the read surface",
       %{conn: conn} do
    {:ok, view, html} =
      live(
        conn,
        "/admin/flags/checkout-redesign?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dgrowth"
      )

    assert html =~ "Active ruleset"
    assert html =~ "Version 1"
    assert html =~ "Draft ruleset"
    assert html =~ "Version 2"
    assert has_element?(view, "a[href='/admin/flags?env=prod&owner=growth']", "Back to queue")

    assert has_element?(
             view,
             "a[href='/admin/flags/checkout-redesign/rules?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dgrowth']"
           )

    assert has_element?(
             view,
             "a[href='/admin/flags/checkout-redesign/kill?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dgrowth']"
           )

    assert has_element?(
             view,
             "a[href='/admin/flags/checkout-redesign/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dgrowth']",
             "Review cleanup"
           )

    assert has_element?(
             view,
             "a[href='/admin/flags/checkout-redesign/timeline?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod%26owner%3Dgrowth']"
           )

    assert html =~ "Open rules workspace"
    assert html =~ "Open kill switch"
    assert html =~ "Open audit timeline"
    assert html =~ "Use the dedicated timeline for append-only history"
  end

  test "detail reads audit data with the current session actor and hides restricted reasons", %{
    conn: conn
  } do
    assert {:ok, _payload} =
             Rulestead.engage_kill_switch(
               "checkout-redesign",
               "prod",
               %{id: "op-1", display: "Priya", roles: [:admin]},
               reason: "incident bridge"
             )

    Application.put_env(:rulestead, :admin_policy, AuditRestrictedPolicy)

    restricted_conn =
      conn
      |> Phoenix.ConnTest.recycle()
      |> Phoenix.ConnTest.init_test_session(%{
        "current_actor" => %{id: 8, email: "viewer@example.com", roles: ["viewer"]},
        "rulestead_admin_last_env" => "prod",
        "rulestead_admin_environments" => [
          %{"key" => "dev", "name" => "Development"},
          %{"key" => "staging", "name" => "Staging"},
          %{"key" => "prod", "name" => "Production"}
        ]
      })

    {:ok, _view, html} = live(restricted_conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Kill switch active"
    refute html =~ "incident bridge"
  end

  test "detail surfaces compact governance and scheduled preview cards without becoming a workflow hub",
       %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/checkout-redesign?env=prod")

    assert html =~ "Open change requests"
    assert html =~ "Scheduled changes"
    assert html =~ "Publish ruleset v2"
    assert html =~ "/admin/flags/change-requests/"
    assert html =~ "/admin/flags/schedule/"
  end

  test "detail renders archive-readiness reasons, bounded actions, and strong evidence for archive candidates",
       %{conn: conn} do
    {:ok, _view, html} = live(conn, "/admin/flags/ops-cleanup?env=prod")

    assert html =~ "Archive readiness guidance"
    assert html =~ "Archive candidate"
    assert html =~ "Strong"
    assert html =~ "Primary recommendation:"
    assert html =~ "Archive when the review is complete"
    assert html =~ "Fresh scan found no code references"
    assert html =~ "Review horizon passed"
    assert html =~ "Evaluation has not run recently"
    assert html =~ "Latest scan receipt:"
  end

  test "detail withholds a primary recommendation when evidence is weak and blockers remain", %{
    conn: conn
  } do
    {:ok, _view, html} = live(conn, "/admin/flags/remote-config-review?env=prod")

    assert html =~ "Guidance limited by missing evidence"
    assert html =~ "Primary recommendation:"
    assert html =~ "Keep active"
    assert html =~ "Code-reference scan receipt is missing"
    assert html =~ "Remote config flags require stronger review"
  end

  test "invalid return_to falls back to the mounted queue path", %{conn: conn} do
    {:ok, view, _html} =
      live(conn, "/admin/flags/checkout-redesign?env=prod&return_to=%2Foutside")

    assert has_element?(view, "a[href='/admin/flags?env=prod']", "Back to queue")

    assert has_element?(
             view,
             "a[href='/admin/flags/checkout-redesign/cleanup?env=prod&return_to=%2Fadmin%2Fflags%3Fenv%3Dprod']",
             "Review cleanup"
           )
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["prod"])
      |> Map.put_new(:tags, [])

    if Map.has_key?(attrs, :code_reference_count) or Map.has_key?(attrs, :code_refs_scan) do
      assert %{flag: %{key: _key}} = Control.put_flag!(attrs)
    else
      assert {:ok, _payload} = Rulestead.create_flag(attrs)
    end
  end

  defp publish_flag!(flag_key, environment_key) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v1",
      rules: [
        %{
          key: "#{flag_key}-enabled",
          strategy: :forced_value,
          value: %{value: true},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new(flag_key, environment_key, actor: @admin_actor)
             )
  end

  defp save_draft!(flag_key, environment_key, version, value) do
    ruleset = %{
      salt: "#{flag_key}:#{environment_key}:v#{version}",
      rules: [
        %{
          key: "#{flag_key}-draft-#{version}",
          strategy: :forced_value,
          value: %{value: value},
          conditions: []
        }
      ]
    }

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(flag_key, environment_key, ruleset,
                 actor: @admin_actor
               )
             )
  end

  defp seed_environment!(key, name) do
    snapshot = Control.snapshot!()

    if Map.has_key?(snapshot.environments, key) do
      :ok
    else
      assert %{key: ^key, name: ^name} = Control.put_environment!(%{key: key, name: name})
    end
  end

  defp seed_change_request!(flag_key, environment_key) do
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
                 actor: %{id: "submitter-1", display: "Submitter One"},
                 reason: "Queue a publish"
               )
             )

    assert {:ok, %{change_request: approved}} =
             Rulestead.approve_change_request(
               Command.ApproveChangeRequest.new(change_request.id,
                 actor: %{id: "reviewer-1", display: "Reviewer One"},
                 reason: "Approved for prod"
               )
             )

    assert {:ok, %{scheduled_execution: _scheduled_execution}} =
             Rulestead.schedule_change_request(
               Command.ScheduleChangeRequest.new(%{
                 change_request_id: approved.id,
                 scheduled_for: ~U[2026-04-24 18:00:00Z],
                 actor: %{id: "scheduler-1", display: "Scheduler One"},
                 reason: "Wait for low-traffic window"
               })
             )
  end
end

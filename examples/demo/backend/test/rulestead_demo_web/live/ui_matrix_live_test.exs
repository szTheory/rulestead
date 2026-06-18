defmodule RulesteadDemoWeb.UiMatrixLiveTest do
  use RulesteadDemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias RulesteadDemoWeb.UiMatrixFixtures

  @matrix_path "/dev/rulestead-admin/ui-matrix"
  @sections [
    "overview-shell",
    "foundations-reference",
    "primitives",
    "composites",
    "mutation-flows",
    "dense-tables",
    "timelines",
    "rule-editor",
    "rollout-panels",
    "command-palette",
    "workflow-states",
    "rare-states",
    "static-fixtures"
  ]
  @cmp_evidence %{
    "CMP-01" => [
      "Primitive form field examples",
      "rs-badge",
      "rs-stat",
      "rs-empty-state",
      "rs-task-link"
    ],
    "CMP-02" => [
      "Primitive action row",
      "Read-only policy",
      "Return to matrix overview",
      "rs-form-field"
    ],
    "CMP-03" => [
      "Destructive confirmation",
      "Type production flag key",
      "Unavailable confirmation",
      "Read-only confirmation",
      "rs-mutation-confirm"
    ],
    "CMP-04" => [
      "Provenance",
      "Guardrail decision: Held - stale host evidence",
      "Preview uncertainty",
      "Governance severity",
      "Support-safe trace",
      "Audience trace state"
    ],
    "CMP-05" => [
      "Host evidence is stale",
      "Blocked by guardrail health",
      "Authored-state boundary",
      "Hidden references",
      "Read-only policy"
    ]
  }
  @forbidden_source_terms [
    "Storybook",
    "PhoenixStorybook",
    "phoenix_storybook",
    "visual-diff",
    "pixel-baseline",
    "matchSnapshot",
    "toHaveScreenshot",
    "pixelmatch"
  ]

  test "dev matrix route renders the real admin shell and required sections", %{conn: conn} do
    {:ok, view, html} = live(conn, @matrix_path)
    rendered = html <> render(view)

    assert rendered =~ "rs-shell"
    assert rendered =~ "Rulestead admin UI matrix"
    assert rendered =~ "Review Matrix Evidence"

    for section <- @sections do
      assert rendered =~ ~s(data-matrix-section="#{section}")
    end

    assert rendered =~ "rs-mutation-confirm"
    assert rendered =~ "rs-badge"
    assert rendered =~ "rs-stat"
    assert rendered =~ "rs-empty-state"
    assert rendered =~ "rs-cmdk"
    assert rendered =~ "Primitive form field examples"
    assert rendered =~ "Host evidence is stale"
    assert rendered =~ "Unavailable action"
    assert rendered =~ "Read-only policy"
    assert rendered =~ "Destructive confirmation"
    assert rendered =~ "Type production flag key"
    assert rendered =~ "Production fixture archive requires the exact flag key."
    assert rendered =~ "Host evidence is stale. Refresh guardrail evidence before mutating."
    assert rendered =~ "Read-only fixture action"
    assert rendered =~ "Provenance"
    assert rendered =~ "Redacted JSON is locally scrollable"
    assert rendered =~ "Guardrail decision: Held - stale host evidence"
    assert rendered =~ "Blocked by guardrail health"
    assert rendered =~ "Risky jump skips the advisory ladder"
    assert rendered =~ "Preview uncertainty"
    assert rendered =~ "Governance severity"
    assert rendered =~ "Authored-state boundary"
    assert rendered =~ "Support-safe trace"
    assert rendered =~ "Audience trace state"
  end

  test "phase 116 requirements have concrete matrix evidence", %{conn: conn} do
    {:ok, view, html} = live(conn, @matrix_path)
    rendered = html <> render(view)

    for {requirement, markers} <- @cmp_evidence do
      for marker <- markers do
        assert rendered =~ marker, "#{requirement} evidence missing marker #{inspect(marker)}"
      end
    end
  end

  test "read-only matrix interactions keep the LiveView mounted", %{conn: conn} do
    {:ok, view, _html} = live(conn, @matrix_path)

    view
    |> form(~s(form[aria-label="Confirm destructive fixture action"]), %{
      "confirmation" => UiMatrixFixtures.long_flag_key(),
      "reason" => "matrix proof"
    })
    |> render_submit()

    assert render(view) =~ "Rulestead admin UI matrix"

    view
    |> element(~s(button[phx-click="save_draft"]))
    |> render_click()

    assert render(view) =~ "Rulestead admin UI matrix"
  end

  test "fixture helpers expose deterministic stress states" do
    assert UiMatrixFixtures.long_flag_key() ==
             "enterprise-checkout-redesign-rollout-experiment-long-key-for-wrapping-proof"

    assert UiMatrixFixtures.long_audience_key() ==
             "audience:enterprise:regional:vip:long-key-for-matrix-proof"

    assert String.contains?(
             UiMatrixFixtures.long_reason(),
             "intentionally long operator rationale"
           )

    assert length(UiMatrixFixtures.dense_records()) > 10
    assert length(UiMatrixFixtures.audit_entries()) > 0

    rare_states = Enum.map(UiMatrixFixtures.rare_state_examples(), & &1.state)

    assert :permission_denied in rare_states
    assert :read_only in rare_states
    assert :unavailable in rare_states
    assert :destructive in rare_states
    assert :loading in rare_states
    assert :error in rare_states

    assert UiMatrixFixtures.mutation_confirm_assigns(:destructive).danger? == true

    assert UiMatrixFixtures.mutation_confirm_assigns(:destructive).typed_confirmation_required ==
             true

    assert UiMatrixFixtures.mutation_confirm_assigns(:disabled).submit_label =~ "Unavailable"

    assert UiMatrixFixtures.mutation_confirm_assigns(:disabled).unavailable_reason =~
             "Host evidence is stale"

    assert UiMatrixFixtures.mutation_confirm_assigns(:read_only).read_only? == true
    assert length(UiMatrixFixtures.mutation_confirm_variants()) == 3
    assert UiMatrixFixtures.audience_dependencies().denied? == false
    assert UiMatrixFixtures.audience_dependencies().hidden_count > 0
  end

  test "phase 117 route examples cover primary flow IA routes" do
    route_examples = UiMatrixFixtures.route_examples()
    route_labels = Enum.map(route_examples, & &1.label)
    route_paths = Enum.map(route_examples, & &1.path)

    for label <- [
          "Overview",
          "Inventory",
          "Rules",
          "Kill switch",
          "Audiences",
          "Audit",
          "Explain",
          "Simulate"
        ] do
      assert label in route_labels
    end

    for path_fragment <- [
          "/admin/flags",
          "/admin/flags/flags",
          "/admin/flags/enable-new-dashboard/rules",
          "/admin/flags/enable-new-dashboard/kill",
          "/admin/flags/audiences",
          "/admin/flags/audit",
          "/admin/flags/enable-new-dashboard/explain",
          "/admin/flags/enable-new-dashboard/simulate"
        ] do
      assert Enum.any?(route_paths, &String.contains?(&1, path_fragment))
    end

    rare_states = Enum.map(UiMatrixFixtures.rare_state_examples(), & &1.state)

    for state <- [
          :empty,
          :permission_denied,
          :read_only,
          :unavailable,
          :destructive,
          :loading,
          :error
        ] do
      assert state in rare_states
    end
  end

  test "source boundary stays demo-hosted and real-component backed" do
    router_source = read_source("lib/rulestead_demo_web/router.ex")
    live_source = read_source("lib/rulestead_demo_web/live/ui_matrix_live.ex")
    fixtures_source = read_source("lib/rulestead_demo_web/live/ui_matrix_fixtures.ex")
    admin_router_source = read_repo_source("rulestead_admin/lib/rulestead_admin/router.ex")

    operator_source =
      read_repo_source("rulestead_admin/lib/rulestead_admin/components/operator_components.ex")

    confirm_source =
      read_repo_source("rulestead_admin/lib/rulestead_admin/components/confirm_components.ex")

    # Route stays dev/test-gated by default; the adoption-lab prod image opts in
    # explicitly via RULESTEAD_DEMO_DEV_ROUTES=1 so it is never exposed in a real
    # production build that does not set the flag.
    assert router_source =~ "if Mix.env() in [:dev, :test] or"
    assert router_source =~ ~s|System.get_env("RULESTEAD_DEMO_DEV_ROUTES") == "1"|
    assert router_source =~ ~s(scope "/dev/rulestead-admin", RulesteadDemoWeb do)
    assert router_source =~ ~s(live "/ui-matrix", UiMatrixLive, :index)
    refute admin_router_source =~ "ui-matrix"
    assert operator_source =~ "def form_field"
    assert operator_source =~ "def action_row"
    assert operator_source =~ "def state_note"
    assert confirm_source =~ "typed_confirmation_label"
    assert confirm_source =~ "unavailable_reason"
    assert confirm_source =~ "read_only_reason"

    for module <- [
          "RulesteadAdmin.Components.Shell",
          "OperatorComponents",
          "ConfirmComponents",
          "RolloutComponents",
          "RuleEditorComponents",
          "AuditComponents",
          "AudienceComponents",
          "GovernanceComponents",
          "SimulateComponents"
        ] do
      assert live_source =~ module
    end

    for section <- @sections do
      assert live_source =~ ~s(data-matrix-section="#{section}")
    end

    for source <- [router_source, live_source, fixtures_source],
        marker <- @forbidden_source_terms do
      refute source =~ marker
    end
  end

  defp read_source(relative_path) do
    Path.expand(Path.join(["../../..", relative_path]), __DIR__)
    |> File.read!()
  end

  defp read_repo_source(relative_path) do
    Path.expand(Path.join(["../../../../../..", relative_path]), __DIR__)
    |> File.read!()
  end
end

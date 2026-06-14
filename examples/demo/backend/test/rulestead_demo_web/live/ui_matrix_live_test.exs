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
  end

  test "read-only matrix interactions keep the LiveView mounted", %{conn: conn} do
    {:ok, view, _html} = live(conn, @matrix_path)

    view
    |> form(~s(form[aria-label="Confirm action"]), %{"reason" => "matrix proof"})
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
    assert UiMatrixFixtures.mutation_confirm_assigns(:disabled).submit_label =~ "Unavailable"
    assert UiMatrixFixtures.audience_dependencies().denied? == false
    assert UiMatrixFixtures.audience_dependencies().hidden_count > 0
  end

  test "source boundary stays demo-hosted and real-component backed" do
    router_source = read_source("lib/rulestead_demo_web/router.ex")
    live_source = read_source("lib/rulestead_demo_web/live/ui_matrix_live.ex")
    fixtures_source = read_source("lib/rulestead_demo_web/live/ui_matrix_fixtures.ex")
    admin_router_source = read_repo_source("rulestead_admin/lib/rulestead_admin/router.ex")

    assert router_source =~ "if Mix.env() in [:dev, :test] do"
    assert router_source =~ ~s(scope "/dev/rulestead-admin", RulesteadDemoWeb do)
    assert router_source =~ ~s(live "/ui-matrix", UiMatrixLive, :index)
    refute admin_router_source =~ "ui-matrix"

    for module <- [
          "RulesteadAdmin.Components.Shell",
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
        marker <- [
          "Storybook",
          "PhoenixStorybook",
          "phoenix_storybook",
          "visual-diff",
          "pixel-baseline"
        ] do
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

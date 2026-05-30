defmodule Rulestead.AdoptionLabContractTest do
  use ExUnit.Case, async: true

  @adoption_lab_path Path.expand("../../../guides/introduction/adoption-lab.md", __DIR__)
  @getting_started_path Path.expand("../../../guides/introduction/getting-started.md", __DIR__)
  @installation_path Path.expand("../../../guides/introduction/installation.md", __DIR__)
  @user_flows_path Path.expand("../../../guides/introduction/user-flows-and-jtbd.md", __DIR__)
  @testing_path Path.expand("../../../guides/recipes/testing.md", __DIR__)
  @admin_ui_path Path.expand("../../../guides/flows/admin-ui.md", __DIR__)
  @explainability_path Path.expand("../../../guides/flows/explainability.md", __DIR__)
  @root_readme_path Path.expand("../../../README.md", __DIR__)
  @demo_seeds_path Path.expand(
                     "../../../examples/demo/backend/lib/rulestead_demo/seeds.ex",
                     __DIR__
                   )
  @demo_rulestead_config_path Path.expand(
                                "../../../examples/demo/backend/config/rulestead.exs",
                                __DIR__
                              )
  @install_journey_path Path.expand("../../../scripts/demo/install_journey.sh", __DIR__)

  @playwright_specs [
    "flag-inventory.spec.ts",
    "rollout-advance.spec.ts",
    "explain-admin.spec.ts",
    "audit-timeline.spec.ts",
    "guarded-rollout.spec.ts"
  ]

  @seed_flag_keys [
    "enable-new-dashboard",
    "fleet-map-v2",
    "dispatch-ops-copy",
    "ops-banner-config",
    "dispatch-guarded-rollout",
    "ops-audience-preview"
  ]

  test "adoption lab guide documents FleetDesk personas and two proof paths" do
    guide = File.read!(@adoption_lab_path)

    assert guide =~ "FleetDesk"
    assert guide =~ "docker compose up"
    assert guide =~ "scripts/demo/proof.sh"
    assert guide =~ "scripts/demo/install_journey.sh"
    assert guide =~ "dispatch-guarded-rollout"
    assert guide =~ "ops-audience-preview"
    assert guide =~ "GOV-05"
  end

  test "adoption lab runbook documents connect URLs and troubleshooting" do
    guide = File.read!(@adoption_lab_path)

    assert guide =~ "At a glance"
    assert guide =~ "Developer tools"
    assert guide =~ "localhost:3000"
    assert guide =~ "/demo/sign-in"
    assert guide =~ "localhost:4000"
    assert guide =~ "docker compose ps" or guide =~ "smoke.sh"
    assert guide =~ "Morgan Chen"
    assert guide =~ "enable-new-dashboard"
    assert guide =~ "Classic dispatch map is holding steady"
  end

  test "rulestead admin stylesheet ships in package priv static" do
    css_path =
      Path.expand("../../../rulestead_admin/priv/static/css/rulestead_admin.css", __DIR__)

    assert File.regular?(css_path)
    css = File.read!(css_path)
    assert byte_size(css) > 1000
    assert css =~ ".rs-shell"
    assert css =~ ".rs-table"
  end

  test "root readme does not ship stale FleetDesk demo copy" do
    root_readme = File.read!(@root_readme_path)

    refute root_readme =~ "new operator cockpit"
    refute root_readme =~ "classic cockpit is holding"
  end

  test "intro and flow guides cross-link the adoption lab" do
    getting_started = File.read!(@getting_started_path)
    installation = File.read!(@installation_path)
    user_flows = File.read!(@user_flows_path)
    testing = File.read!(@testing_path)
    admin_ui = File.read!(@admin_ui_path)
    explainability = File.read!(@explainability_path)
    root_readme = File.read!(@root_readme_path)

    for doc <- [
          getting_started,
          installation,
          user_flows,
          testing,
          admin_ui,
          explainability,
          root_readme
        ] do
      assert doc =~ "adoption-lab"
    end
  end

  test "FleetDesk seeds include post-GA adoption-lab flags" do
    seeds = File.read!(@demo_seeds_path)
    rulestead_config = File.read!(@demo_rulestead_config_path)

    for flag_key <- @seed_flag_keys do
      assert seeds =~ flag_key
    end

    assert seeds =~ "fleet-ops-dispatchers"
    assert rulestead_config =~ "PreviewEvidenceResolver"
  end

  test "install journey and curated Playwright specs ship in repo" do
    assert File.regular?(@install_journey_path)

    playwright_dir = Path.expand("../../../examples/demo/frontend/tests", __DIR__)

    for spec <- @playwright_specs do
      assert File.regular?(Path.join(playwright_dir, spec))
    end
  end
end

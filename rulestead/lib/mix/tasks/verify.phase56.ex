# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Phase56 do
  @moduledoc false

  use Mix.Task

  @shortdoc "Runs Phase 56 reusable targeting deepening verification suite"

  # Union of verify.phase54 + verify.phase55 + Phase 53 gaps — do not call those tasks
  # (avoids duplicate runs). Phase 54 paths (13) + Phase 55-unique core (2) + Phase 53 gaps (2).
  @phase56_core_tests [
    "test/rulestead/targeting/dependency_sort_property_test.exs",
    "test/rulestead/store/audience_dependency_inventory_contract_test.exs",
    "test/rulestead/store/compare_contract_test.exs",
    "test/rulestead/store/publish_ruleset_dependency_contract_test.exs",
    "test/rulestead/store/promotion_apply_contract_test.exs",
    "test/rulestead/store/manifest_import_contract_test.exs",
    "test/rulestead/store/audience_impact_contract_test.exs",
    "test/rulestead/store/ecto_audience_impact_contract_test.exs",
    "test/rulestead/manifest/export_test.exs",
    "test/rulestead/manifest/import_test.exs",
    "test/rulestead/manifest/validate_test.exs",
    "test/rulestead/runtime/audience_snapshot_test.exs",
    "test/rulestead/release_contract_test.exs",
    "test/rulestead/admin/dependency_visibility_test.exs",
    "test/rulestead/targeting/dependency_inventory_test.exs",
    "test/rulestead/targeting/impact_preview_test.exs",
    "test/rulestead/audience_mutation_audit_test.exs"
  ]

  @admin_test_paths [
    "test/rulestead_admin/live/audience_live",
    "test/rulestead_admin/live/flag_live/explain_test.exs",
    "test/rulestead_admin/router_test.exs",
    "test/rulestead_admin/live/environment_compare_live/index_test.exs",
    "test/rulestead_admin/live/environment_compare_live/show_test.exs",
    "test/rulestead_admin/live/flag_live/rules_test.exs",
    "test/rulestead_admin/live/flag_live/simulate_test.exs"
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("test", @phase56_core_tests)

    admin_dir = Path.expand("../../../../rulestead_admin", __DIR__)

    Mix.Task.run("cmd", [
      "sh",
      "-c",
      "cd #{admin_dir} && MIX_ENV=test mix test #{Enum.join(@admin_test_paths, " ")}"
    ])
  end
end

# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Phase64 do
  @moduledoc false

  use Mix.Task

  @shortdoc "Runs Phase 64 guarded rollout auto-advance verification suite"

  # Flat union of phase60 core regression paths + v1.8 auto-advance delta — do not delegate
  # to other verify tasks (avoids duplicate runs).
  @phase64_core_tests [
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
    "test/rulestead/audience_mutation_audit_test.exs",
    "test/rulestead/governance/blast_radius_threshold_test.exs",
    "test/rulestead/governance/audience_mutation_change_request_test.exs",
    "test/rulestead/governance/audience_mutation_change_request_contract_test.exs",
    "test/rulestead/governance/change_request_contract_test.exs",
    "test/rulestead/admin_governance_policy_test.exs",
    "test/rulestead/rollout_auto_advance_contract_test.exs",
    "test/rulestead/rollout_auto_advance_orchestration_contract_test.exs",
    "test/rulestead/guardrails/auto_advance_test.exs",
    "test/rulestead/guarded_rollout_test.exs",
    "test/rulestead/scheduled_execution_conflict_test.exs"
  ]

  @admin_test_paths [
    "test/rulestead_admin/live/audience_live",
    "test/rulestead_admin/live/flag_live/explain_test.exs",
    "test/rulestead_admin/router_test.exs",
    "test/rulestead_admin/live/environment_compare_live/index_test.exs",
    "test/rulestead_admin/live/environment_compare_live/show_test.exs",
    "test/rulestead_admin/live/flag_live/rules_test.exs",
    "test/rulestead_admin/live/flag_live/simulate_test.exs",
    "test/rulestead_admin/components/governance_components_test.exs",
    "test/rulestead_admin/live/governance_route_contract_test.exs",
    "test/rulestead_admin/live/change_request_live/show_test.exs",
    "test/rulestead_admin/live/flag_live/rollouts_test.exs",
    "test/rulestead_admin/live/flag_live/timeline_test.exs"
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("test", @phase64_core_tests)

    admin_dir = Path.expand("../../../../rulestead_admin", __DIR__)

    Mix.Task.run("cmd", [
      "sh",
      "-c",
      "cd #{admin_dir} && MIX_ENV=test mix test #{Enum.join(@admin_test_paths, " ")}"
    ])
  end
end

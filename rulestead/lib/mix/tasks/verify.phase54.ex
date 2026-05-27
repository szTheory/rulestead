# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Phase54 do
  @moduledoc false

  use Mix.Task

  @shortdoc "Runs Phase 54 dependency truth verification suite"

  @phase54_tests [
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
    "test/rulestead/release_contract_test.exs"
  ]

  @impl Mix.Task
  def run(_args) do
    # Equivalent command: mix test <phase54 contract and property suites>.
    Mix.Task.run("test", @phase54_tests)
  end
end

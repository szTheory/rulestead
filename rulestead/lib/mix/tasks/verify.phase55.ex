# credo:disable-for-this-file
defmodule Mix.Tasks.Verify.Phase55 do
  @moduledoc false

  use Mix.Task

  @shortdoc "Runs Phase 55 mounted operator workflow verification suite"

  @phase55_tests [
    "test/rulestead/admin/dependency_visibility_test.exs",
    "test/rulestead/targeting/dependency_inventory_test.exs",
    "test/rulestead/store/audience_impact_contract_test.exs",
    "test/rulestead/store/audience_dependency_inventory_contract_test.exs"
  ]

  @admin_test_paths [
    "test/rulestead_admin/live/audience_live",
    "test/rulestead_admin/live/flag_live/explain_test.exs",
    "test/rulestead_admin/router_test.exs",
    "test/rulestead_admin/live/environment_compare_live/index_test.exs"
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("test", @phase55_tests)

    admin_dir = Path.expand("../../../../rulestead_admin", __DIR__)

    Mix.Task.run("cmd", [
      "sh",
      "-c",
      "cd #{admin_dir} && MIX_ENV=test mix test #{Enum.join(@admin_test_paths, " ")}"
    ])
  end
end

defmodule Rulestead.Mix.Tasks.RulesteadDiffTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Rulestead.Diff
  alias Rulestead.Manifest.Result

  test "compute returns no_changes or changes with the locked exit codes" do
    source = %{
      "schema_version" => 1,
      "kind" => "rulestead_environment_manifest",
      "environment_key" => "staging",
      "flags" => [
        %{
          "flag_key" => "checkout-redesign",
          "flag" => %{
            "flag_type" => "release",
            "value_type" => "boolean",
            "default_value" => %{"value" => false}
          },
          "environment" => %{"status" => "active", "active_ruleset_version" => 1},
          "active_ruleset" => %{"version" => 1, "salt" => "v2", "metadata" => %{}, "rules" => []}
        }
      ]
    }

    identical_target = put_in(source, ["environment_key"], "test")

    changed_target =
      put_in(identical_target, ["flags", Access.at(0), "active_ruleset", "salt"], "v1")

    assert {:ok, no_change_result} = Diff.compute(source, target_manifest: identical_target)
    assert no_change_result["status"] == "no_changes"
    assert Result.exit_code(no_change_result) == 0

    assert {:ok, changed_result} = Diff.compute(source, target_manifest: changed_target)
    assert changed_result["status"] == "changes"
    assert Result.exit_code(changed_result) == 2
  end
end

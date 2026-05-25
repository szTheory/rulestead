defmodule Rulestead.Mix.Tasks.RulesteadValidateTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Rulestead.Validate
  alias Rulestead.Manifest.Result

  test "compute returns ok for valid manifests and invalid for dependency failures" do
    valid_manifest = %{
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
          "active_ruleset" => %{
            "version" => 1,
            "salt" => "checkout-redesign:v1",
            "metadata" => %{},
            "rules" => [
              %{
                "key" => "segment",
                "name" => "Segment",
                "strategy" => "segment_match",
                "audience_key" => "vip-users",
                "value" => %{}
              }
            ]
          }
        }
      ]
    }

    invalid_manifest =
      put_in(
        valid_manifest,
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "audience_key"],
        nil
      )

    assert {:ok, ok_result} = Validate.compute(valid_manifest)
    assert ok_result["status"] == "ok"
    assert Result.exit_code(ok_result) == 0

    assert {:ok, invalid_result} = Validate.compute(invalid_manifest)
    assert invalid_result["status"] == "invalid"
    assert Result.exit_code(invalid_result) == 3
  end
end

defmodule Rulestead.Manifest.ValidateTest do
  use ExUnit.Case, async: true

  alias Rulestead.Manifest.Validate

  test "returns the canonical envelope with ok status for a valid manifest" do
    assert {:ok, result} = Validate.validate(valid_manifest())

    assert result["status"] == "ok"
    assert result["command"] == "validate"

    assert result["summary"] == %{
             "environment_key" => "staging",
             "finding_count" => 0,
             "flag_count" => 1
           }

    assert result["findings"] == []
    assert result["details"]["manifest"]["environment_key"] == "staging"
  end

  test "returns invalid when dependency references are missing" do
    manifest =
      put_in(
        valid_manifest(),
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "audience_key"],
        nil
      )
      |> put_in(
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "strategy"],
        "segment_match"
      )

    assert {:ok, result} = Validate.validate(manifest)

    assert result["status"] == "invalid"

    assert result["findings"] == [
             %{
               "code" => "missing_dependency",
               "message" => "segment_match rules require audience_key",
               "scope" => "flag:checkout-redesign",
               "severity" => "blocker"
             }
           ]
  end

  defp valid_manifest do
    %{
      "schema_version" => 1,
      "kind" => "rulestead_environment_manifest",
      "environment_key" => "staging",
      "flags" => [
        %{
          "flag_key" => "checkout-redesign",
          "flag" => %{
            "description" => "Release the new checkout flow",
            "flag_type" => "release",
            "value_type" => "boolean",
            "default_value" => %{"value" => false},
            "owner" => "growth",
            "permanent" => true,
            "tags" => ["checkout", "release"]
          },
          "environment" => %{
            "status" => "active",
            "active_ruleset_version" => 1
          },
          "active_ruleset" => %{
            "version" => 1,
            "salt" => "checkout-redesign:v1",
            "metadata" => %{"source" => "contract"},
            "rules" => [
              %{
                "key" => "target-segment",
                "name" => "Target segment",
                "strategy" => "segment_match",
                "audience_key" => "vip-users",
                "value" => %{},
                "conditions" => []
              }
            ]
          }
        }
      ]
    }
  end
end

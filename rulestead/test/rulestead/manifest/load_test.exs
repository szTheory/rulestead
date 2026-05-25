defmodule Rulestead.Manifest.LoadTest do
  use ExUnit.Case, async: false

  alias Rulestead.Manifest

  test "loads serialized manifests back into the canonical normalized shape" do
    manifest = %{
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
                "key" => "force-enabled",
                "name" => "Force enabled",
                "strategy" => "forced_value",
                "value" => %{"value" => true},
                "variants" => [],
                "conditions" => [
                  %{
                    "attribute" => "attributes.account.plan",
                    "operator" => "equals",
                    "value" => %{"equals" => "enterprise"}
                  }
                ]
              }
            ]
          }
        }
      ]
    }

    assert {:ok, encoded} = Manifest.serialize(manifest)
    assert {:ok, loaded} = Manifest.load(encoded)
    assert loaded == manifest
    assert {:ok, reencoded} = Manifest.serialize(loaded)
    assert reencoded == encoded
  end

  test "rejects invalid manifest kind" do
    assert {:error, %Rulestead.Error{message: "manifest kind is unsupported"}} =
             Manifest.load(%{"schema_version" => 1, "kind" => "wrong", "environment_key" => "staging", "flags" => []})
  end

  test "rejects invalid manifest schema version" do
    assert {:error, %Rulestead.Error{message: "manifest schema version is unsupported"}} =
             Manifest.load(%{"schema_version" => 2, "kind" => "rulestead_environment_manifest", "environment_key" => "staging", "flags" => []})
  end
end

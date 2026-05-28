defmodule Rulestead.Manifest.ValidateTest do
  use ExUnit.Case, async: false

  alias Rulestead.Fake
  alias Rulestead.Manifest.Validate

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)
    seed_audience!("vip-users")

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "returns the canonical envelope with ok status for a valid manifest" do
    assert {:ok, result} = Validate.validate(valid_manifest())

    assert result["status"] == "ok"
    assert result["command"] == "validate"

    assert result["summary"] == %{
             "dependency_finding_count" => 0,
             "environment_key" => "staging",
             "finding_count" => 0,
             "flag_count" => 1
           }

    assert result["findings"] == []
    assert result["dependency_findings"] == []
    assert result["details"]["manifest"]["environment_key"] == "staging"
  end

  test "returns invalid when dependency references are missing" do
    manifest =
      put_in(
        valid_manifest(),
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "audience_key"],
        "missing-audience"
      )
      |> put_in(
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "strategy"],
        "segment_match"
      )

    assert {:ok, result} = Validate.validate(manifest)

    assert result["status"] == "invalid"
    assert Enum.any?(result["dependency_findings"], &(&1["code"] == "missing_reference"))
    assert Enum.any?(result["findings"], &(&1["code"] == "missing_reference"))

    assert Enum.all?(result["dependency_findings"], fn finding ->
             is_binary(finding["environment_key"]) and finding["environment_key"] != "" and
               is_binary(finding["tenant_key"]) and finding["tenant_key"] != ""
           end)
  end

  test "returns deterministic dependency blocker findings for archived_reference incompatible_reference and tenant_mismatch" do
    archive_audience!("vip-users")

    manifest =
      valid_manifest()
      |> put_in(
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "tenant_key"],
        "other"
      )
      |> put_in(
        ["flags", Access.at(0), "active_ruleset", "rules", Access.at(0), "audience_key"],
        "vip-users"
      )

    assert {:ok, result} = Validate.validate(manifest)

    # stale_reference remains part of the dependency contract through expected-reference checks.
    assert Enum.any?(result["dependency_findings"], &(&1["code"] == "archived_reference"))

    assert Enum.any?(
             result["dependency_findings"],
             &(&1["code"] in ["incompatible_reference", "tenant_mismatch"])
           )

    assert result["dependency_findings"] ==
             Enum.sort_by(result["dependency_findings"], fn finding ->
               {
                 finding["severity"],
                 finding["code"],
                 finding["environment_key"],
                 finding["tenant_key"],
                 finding["flag_key"],
                 finding["ruleset_version"],
                 finding["rule_key"],
                 finding["audience_key"]
               }
             end)

    assert Enum.all?(result["dependency_findings"], fn finding ->
             is_binary(finding["environment_key"]) and finding["environment_key"] != "" and
               is_binary(finding["tenant_key"]) and finding["tenant_key"] != ""
           end)
  end

  defp valid_manifest do
    %{
      "schema_version" => 1,
      "kind" => "rulestead_environment_manifest",
      "environment_key" => "staging",
      "tenant_key" => "acme",
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
                "environment_key" => "staging",
                "tenant_key" => "acme",
                "value" => %{},
                "conditions" => []
              }
            ]
          }
        }
      ]
    }
  end

  defp seed_audience!(key) do
    now = Rulestead.Fake.Control.now!()

    Rulestead.Fake.Control.restore!(
      Rulestead.Fake.Control.snapshot!()
      |> Map.update!(:audiences, fn audiences ->
        Map.put(audiences, key, %{
          id: "aud-#{key}",
          key: key,
          name: "Audience #{key}",
          description: "Seeded audience",
          definition: %{clauses: [%{attribute: "plan", op: "eq", value: "vip"}]},
          inserted_at: now,
          updated_at: now,
          archived_at: nil
        })
      end)
    )
  end

  defp archive_audience!(key) do
    snapshot = Rulestead.Fake.Control.snapshot!()
    audience = Map.fetch!(snapshot.audiences, key)

    Rulestead.Fake.Control.restore!(%{
      snapshot
      | audiences:
          Map.put(snapshot.audiences, key, %{
            audience
            | archived_at: snapshot.now,
              definition: %{clauses: "invalid-shape"},
              updated_at: snapshot.now
          })
    })
  end
end

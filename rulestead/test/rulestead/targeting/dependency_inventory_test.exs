defmodule Rulestead.Targeting.DependencyInventoryTest do
  use ExUnit.Case, async: true

  alias Rulestead.Targeting.DependencyInventory

  test "normalize_entry/1 keeps canonical scope and lifecycle metadata" do
    entry =
      DependencyInventory.normalize_entry(%{
        environment_key: "staging",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        flag_key: "checkout-redesign",
        ruleset_version: "2",
        rule_key: "segment-match",
        ruleset_status: "published",
        rollout_context: %{percentage: 25},
        lifecycle_context: %{state: "active"}
      })

    assert entry.environment_key == "staging"
    assert entry.tenant_key == "tenant-a"
    assert entry.flag_key == "checkout-redesign"
    assert entry.ruleset_version == 2
    assert entry.rule_key == "segment-match"
    assert entry.audience_key == "vip-users"
    assert entry.ruleset_status == "published"
    assert entry.rollout_context == %{percentage: 25}
    assert entry.lifecycle_context == %{state: "active"}
    refute entry.malformed?
  end

  test "normalize_entry/1 marks malformed rows when required scope fields are missing" do
    entry =
      DependencyInventory.normalize_entry(%{
        environment_key: "staging",
        audience_key: "vip-users",
        flag_key: "checkout-redesign",
        ruleset_version: 1,
        rule_key: "segment-match"
      })

    assert entry.malformed?

    assert entry.malformed_reasons == [
             %{
               code: "missing_required_scope_or_identity",
               fields: ["tenant_key"]
             }
           ]
  end

  test "sort_entries/1 uses the stable semantic key tuple" do
    entries =
      DependencyInventory.sort_entries([
        %{
          environment_key: "production",
          tenant_key: "tenant-a",
          audience_key: "vip-users",
          flag_key: "checkout-redesign",
          ruleset_version: 2,
          rule_key: "segment-b"
        },
        %{
          environment_key: "staging",
          tenant_key: "tenant-b",
          audience_key: "vip-users",
          flag_key: "checkout-redesign",
          ruleset_version: 3,
          rule_key: "segment-a"
        },
        %{
          environment_key: "staging",
          tenant_key: "tenant-a",
          audience_key: "vip-users",
          flag_key: "checkout-redesign",
          ruleset_version: 1,
          rule_key: "segment-a"
        }
      ])

    assert Enum.map(entries, fn entry ->
             {
               entry.environment_key,
               entry.tenant_key,
               entry.flag_key,
               entry.ruleset_version,
               entry.rule_key,
               entry.audience_key
             }
           end) == [
             {"production", "tenant-a", "checkout-redesign", 2, "segment-b", "vip-users"},
             {"staging", "tenant-a", "checkout-redesign", 1, "segment-a", "vip-users"},
             {"staging", "tenant-b", "checkout-redesign", 3, "segment-a", "vip-users"}
           ]
  end

  test "redacted_result/2 returns hidden reference counts for unauthorized entries" do
    redacted =
      DependencyInventory.redacted_result(
        [
          %{
            environment_key: "staging",
            tenant_key: "tenant-a",
            audience_key: "vip-users",
            flag_key: "checkout-redesign",
            ruleset_version: 1,
            rule_key: "segment-a"
          },
          %{
            environment_key: "staging",
            tenant_key: "tenant-a",
            audience_key: "secret-audience",
            flag_key: "checkout-redesign",
            ruleset_version: 2,
            rule_key: "segment-b"
          }
        ],
        visible_audience_keys: ["vip-users"]
      )

    assert length(redacted.entries) == 1
    assert redacted.hidden_reference_count == 1
    assert redacted.reference_count == 2
    assert redacted.redacted
  end
end

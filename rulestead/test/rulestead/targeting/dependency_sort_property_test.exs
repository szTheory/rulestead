defmodule Rulestead.Targeting.DependencySortPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import StreamData

  alias Rulestead.Targeting.{DependencyInventory, DependencyValidator}

  property "dependency inventory sorting stays stable and keeps scope keys" do
    check all(entries <- list_of(entry_generator(), min_length: 2, max_length: 20)) do
      sorted_from_shuffled =
        entries
        |> Enum.shuffle()
        |> DependencyInventory.sort_entries()

      sorted_from_reversed =
        entries
        |> Enum.reverse()
        |> DependencyInventory.sort_entries()

      assert sorted_from_shuffled == sorted_from_reversed

      assert Enum.all?(sorted_from_shuffled, fn entry ->
               present?(entry.environment_key) and
                 present?(entry.tenant_key) and
                 present?(entry.flag_key) and
                 is_integer(entry.ruleset_version) and
                 present?(entry.rule_key) and
                 present?(entry.audience_key)
             end)
    end
  end

  property "dependency finding sorting stays stable and carries explicit scope" do
    check all(findings <- list_of(finding_generator(), min_length: 3, max_length: 25)) do
      sorted_from_shuffled =
        findings
        |> Enum.shuffle()
        |> DependencyValidator.sort_findings()

      sorted_from_reversed =
        findings
        |> Enum.reverse()
        |> DependencyValidator.sort_findings()

      assert sorted_from_shuffled == sorted_from_reversed

      assert Enum.all?(sorted_from_shuffled, fn finding ->
               present?(finding.environment_key) and
                 present?(finding.tenant_key) and
                 present?(finding.flag_key) and
                 is_integer(finding.ruleset_version) and
                 present?(finding.rule_key) and
                 present?(finding.audience_key)
             end)
    end
  end

  defp entry_generator do
    gen all environment_key <- member_of(["production", "staging", "test"]),
            tenant_key <- member_of(["acme", "global", "tenant-b"]),
            flag_key <- string(:alphanumeric, min_length: 3, max_length: 12),
            ruleset_version <- positive_integer(),
            rule_key <- string(:alphanumeric, min_length: 3, max_length: 12),
            audience_key <- string(:alphanumeric, min_length: 3, max_length: 12) do
      %{
        environment_key: environment_key,
        tenant_key: tenant_key,
        flag_key: flag_key,
        ruleset_version: ruleset_version,
        rule_key: rule_key,
        audience_key: audience_key,
        ruleset_status: "published",
        rollout_context: %{available?: true},
        lifecycle_context: %{available?: true},
        visibility: %{status: "visible"},
        reference_count: 1,
        hidden_reference_count: 0
      }
    end
  end

  defp finding_generator do
    gen all code <-
              member_of([
                "missing_reference",
                "archived_reference",
                "incompatible_reference",
                "stale_reference",
                "tenant_mismatch"
              ]),
            environment_key <- member_of(["production", "staging", "test"]),
            tenant_key <- member_of(["acme", "global", "tenant-b"]),
            flag_key <- string(:alphanumeric, min_length: 3, max_length: 12),
            ruleset_version <- positive_integer(),
            rule_key <- string(:alphanumeric, min_length: 3, max_length: 12),
            audience_key <- string(:alphanumeric, min_length: 3, max_length: 12) do
      %{
        code: code,
        severity: :blocker,
        message: "#{code} blocker",
        environment_key: environment_key,
        tenant_key: tenant_key,
        audience_key: audience_key,
        flag_key: flag_key,
        ruleset_version: ruleset_version,
        rule_key: rule_key
      }
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false
end

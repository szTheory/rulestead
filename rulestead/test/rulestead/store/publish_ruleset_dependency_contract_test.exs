defmodule Rulestead.Store.PublishRulesetDependencyContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.Targeting.DependencyValidator

  test "validate/2 emits missing_reference with canonical identity fields" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{}, tenant_key: "tenant-a"},
        [dependency_entry()]
      )

    assert [
             %{
               code: "missing_reference",
               severity: :blocker,
               environment_key: "production",
               tenant_key: "tenant-a",
               audience_key: "vip-users",
               flag_key: "checkout-redesign",
               ruleset_version: 2,
               rule_key: "vip-rule"
             }
           ] = findings
  end

  test "validate/2 emits archived_reference when audience is archived" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{archived_at: ~U[2026-01-01 00:00:00Z]})
          }
        },
        [dependency_entry()]
      )

    assert Enum.any?(findings, &(&1.code == "archived_reference"))
  end

  test "validate/2 marks incompatible_reference for unsupported clause op shape" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" =>
              audience(%{
                definition: %{
                  conditions: [%{"attribute" => "plan", "operator" => "unsupported_operator"}]
                }
              })
          }
        },
        [dependency_entry()]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "unsupported clause"
  end

  test "validate/2 marks incompatible_reference on schema version mismatch when metadata is present" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{definition: %{"conditions" => [], "schema_version" => 1}})
          }
        },
        [dependency_entry(%{audience_schema_version: 2})]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "schema version"
  end

  test "validate/2 marks incompatible_reference on version hash mismatch when metadata is present" do
    findings =
      DependencyValidator.validate(
        %{
          audiences: %{
            "vip-users" => audience(%{definition: %{"conditions" => [], "version_hash" => "v1"}})
          }
        },
        [dependency_entry(%{audience_version_hash: "v2"})]
      )

    assert [%{code: "incompatible_reference", message: message}] = findings
    assert message =~ "version hash"
  end

  test "validate/2 emits stale_reference when stale reference key is supplied" do
    entry = dependency_entry()

    findings =
      DependencyValidator.validate(
        [entry],
        stale_reference_keys: [reference_key(entry)],
        audiences: %{"vip-users" => audience()}
      )

    assert Enum.any?(findings, &(&1.code == "stale_reference"))
  end

  test "tenant precedence enforces explicit scope tenant on every dependency entry" do
    findings =
      DependencyValidator.validate(
        %{tenant_key: "tenant-a", audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: "tenant-b"})]
      )

    assert [%{code: "tenant_mismatch", message: message}] = findings
    assert message =~ "command scope tenant"
  end

  test "tenant precedence emits tenant_mismatch for mixed tenant dependencies when scope omits tenant" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{"vip-users" => audience()}},
        [
          dependency_entry(%{tenant_key: "tenant-a"}),
          dependency_entry(%{tenant_key: "tenant-b", rule_key: "vip-rule-2"})
        ]
      )

    assert Enum.map(findings, & &1.code) == ["tenant_mismatch", "tenant_mismatch"]
    assert Enum.all?(findings, &String.contains?(&1.message, "mixed tenant"))
  end

  test "tenant precedence treats nil tenant scope as tenant-agnostic when dependencies are nil" do
    findings =
      DependencyValidator.validate(
        %{audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: nil})]
      )

    assert findings == []
  end

  test "to_error keeps deterministic blocker details and blockers?/1 detects blockers" do
    findings =
      DependencyValidator.validate(
        %{tenant_key: "tenant-a", audiences: %{"vip-users" => audience()}},
        [dependency_entry(%{tenant_key: "tenant-b"})]
      )

    assert DependencyValidator.blockers?(findings)

    assert %Rulestead.Error{domain: :store, type: :invalid_command, details: [detail]} =
             DependencyValidator.to_error(findings)

    assert detail.code == "tenant_mismatch"
    assert detail.environment_key == "production"
  end

  test "sort_findings keeps deterministic severity/code and semantic tuple ordering" do
    findings = [
      finding("tenant_mismatch", "production", "tenant-b", "checkout-redesign", 2, "c", "c"),
      finding("archived_reference", "production", "tenant-a", "checkout-redesign", 2, "a", "a"),
      finding("missing_reference", "staging", "tenant-a", "checkout-redesign", 1, "a", "a")
    ]

    sorted = DependencyValidator.sort_findings(findings)

    assert Enum.map(sorted, & &1.code) == [
             "archived_reference",
             "missing_reference",
             "tenant_mismatch"
           ]
  end

  defp dependency_entry(overrides \\ %{}) do
    Map.merge(
      %{
        environment_key: "production",
        tenant_key: "tenant-a",
        audience_key: "vip-users",
        flag_key: "checkout-redesign",
        ruleset_version: 2,
        rule_key: "vip-rule"
      },
      overrides
    )
  end

  defp audience(overrides \\ %{}) do
    Map.merge(
      %{
        key: "vip-users",
        archived_at: nil,
        definition: %{
          "conditions" => [%{"attribute" => "plan", "operator" => "eq", "value" => "enterprise"}]
        }
      },
      overrides
    )
  end

  defp finding(code, environment_key, tenant_key, flag_key, ruleset_version, rule_key, audience_key) do
    %{
      code: code,
      severity: :blocker,
      message: "#{code} message",
      environment_key: environment_key,
      tenant_key: tenant_key,
      audience_key: audience_key,
      flag_key: flag_key,
      ruleset_version: ruleset_version,
      rule_key: rule_key
    }
  end

  defp reference_key(entry) do
    "flag:#{entry.flag_key}:ruleset:#{entry.ruleset_version}:rule:#{entry.rule_key}"
  end
end

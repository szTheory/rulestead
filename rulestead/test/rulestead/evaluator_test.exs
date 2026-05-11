defmodule Rulestead.EvaluatorTest do
  use ExUnit.Case, async: true

  alias Rulestead.Evaluator

  test "rules are evaluated in order and the first match wins" do
    payload = %{
      flag: %{key: "checkout-redesign", default_value: %{value: false}},
      environment: %{key: "test"},
      active_ruleset: %{
        version: 1,
        salt: "checkout:v1",
        rules: [
          %{
            key: "enterprise-first",
            strategy: :forced_value,
            value: %{value: true},
            conditions: [%{attribute: "attributes.plan", operator: :equals, value: %{equals: "enterprise"}}]
          },
          %{
            key: "fallback-second",
            strategy: :forced_value,
            value: %{value: false},
            conditions: [%{attribute: "attributes.plan", operator: :equals, value: %{equals: "enterprise"}}]
          }
        ]
      }
    }

    assert {:ok, result} = Evaluator.evaluate(payload, %{attributes: %{plan: "enterprise"}})
    assert result.matched_rule == "enterprise-first"
    assert result.reason == :rule_match
  end

  test "strict and permissive sticky identity behavior is deterministic" do
    payload = %{
      flag: %{key: "pricing-test", default_value: %{value: false}},
      environment: %{key: "test"},
      active_ruleset: %{
        version: 2,
        salt: "pricing:v2",
        rules: [
          %{
            key: "account-rollout",
            strategy: :percentage_rollout,
            value: %{value: true},
            rollout: %{bucket_by: :account, percentage: 100, salt: "account"},
            conditions: []
          }
        ]
      }
    }

    assert {:ok, permissive} = Evaluator.evaluate(payload, %{})
    assert permissive.reason == :default
    assert permissive.debug_trace.warnings == [%{type: :missing_targeting_key, bucket_by: "account", strict?: false}]

    assert {:error, %Rulestead.Error{type: :missing_targeting_key}} =
             Evaluator.evaluate(payload, %{strict?: true})
  end
end

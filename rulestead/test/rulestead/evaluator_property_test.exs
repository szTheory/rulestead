defmodule Rulestead.EvaluatorPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Rulestead.Evaluator

  property "first-match-wins is determined only by rule order" do
    check all(
            value_a <- boolean(),
            value_b <- boolean(),
            plan <- member_of(["enterprise", "starter"])
          ) do
      first_payload = payload_for([value_a, value_b])
      second_payload = payload_for([value_b, value_a])
      context = %{attributes: %{plan: plan}}

      assert {:ok, first_result} = Evaluator.evaluate(first_payload, context)
      assert {:ok, second_result} = Evaluator.evaluate(second_payload, context)

      if plan == "enterprise" do
        assert first_result.value == value_a
        assert second_result.value == value_b
      else
        assert first_result.reason == :default
        assert second_result.reason == :default
      end
    end
  end

  property "public projections stay consistent with evaluate/3" do
    check all(targeting_key <- string(:ascii, min_length: 1, max_length: 24)) do
      payload = %{
        flag: %{key: "variant-flag", default_value: %{value: false}},
        environment: %{key: "test"},
        active_ruleset: %{
          version: 1,
          salt: "variant",
          rules: [
            %{
              key: "all-users",
              strategy: :variant_split,
              rollout: %{bucket_by: :subject, percentage: 100, salt: "all"},
              variants: [
                %{key: "off", weight: 50, value: %{value: false}},
                %{key: "on", weight: 50, value: %{value: true}}
              ]
            }
          ]
        }
      }

      context = %{actor: %{key: targeting_key}}

      assert {:ok, result} = Rulestead.evaluate(payload, context)
      assert {:ok, enabled?} = Rulestead.enabled?(payload, context)
      assert {:ok, value} = Rulestead.get_value(payload, context, :fallback)
      assert {:ok, variant} = Rulestead.get_variant(payload, context)

      assert enabled? == result.enabled?
      assert value == result.value
      assert variant == result.variant
    end
  end

  property "tenant-aware bucketing remains deterministic" do
    check all(tenant_key <- string(:ascii, min_length: 1, max_length: 24)) do
      payload = %{
        flag: %{key: "tenant-flag", default_value: %{value: false}},
        environment: %{key: "test"},
        active_ruleset: %{
          version: 1,
          salt: "tenant-salt",
          rules: [
            %{
              key: "tenant-rule",
              strategy: :percentage_rollout,
              value: %{value: true},
              rollout: %{bucket_by: :tenant, percentage: 50, salt: "rollout-salt"}
            }
          ]
        }
      }

      context = %Rulestead.Context{tenant_key: tenant_key}

      assert {:ok, result1} = Rulestead.Evaluator.evaluate(payload, context)
      assert {:ok, result2} = Rulestead.Evaluator.evaluate(payload, context)

      assert result1.value == result2.value
    end
  end

  defp payload_for([first_value, second_value]) do
    %{
      flag: %{key: "precedence-flag", default_value: %{value: false}},
      environment: %{key: "test"},
      active_ruleset: %{
        version: 1,
        salt: "precedence",
        rules: [
          %{
            key: "rule-a",
            strategy: :forced_value,
            value: %{value: first_value},
            conditions: [
              %{attribute: "attributes.plan", operator: :equals, value: %{equals: "enterprise"}}
            ]
          },
          %{
            key: "rule-b",
            strategy: :forced_value,
            value: %{value: second_value},
            conditions: [
              %{attribute: "attributes.plan", operator: :equals, value: %{equals: "enterprise"}}
            ]
          }
        ]
      }
    }
  end
end

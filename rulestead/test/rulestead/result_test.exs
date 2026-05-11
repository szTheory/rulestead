defmodule Rulestead.ResultTest do
  use ExUnit.Case, async: true

  alias Rulestead.{EvaluationError, Result}

  test "Result.new/1 produces the stable result contract" do
    assert %Result{
             value: true,
             enabled?: true,
             variant: "control",
             reason: :rule_match,
             matched_rule: "force-enabled",
             flag_key: "checkout-redesign",
             flag_version: 3,
             cache_age_ms: nil,
             debug_trace: %{matched_rule: "force-enabled"}
           } =
             Result.new(
               value: true,
               enabled?: true,
               variant: "control",
               reason: :rule_match,
               matched_rule: "force-enabled",
               flag_key: "checkout-redesign",
               flag_version: 3,
               debug_trace: %{matched_rule: "force-enabled"}
             )
  end

  test "result reasons stay compact closed atoms and debug_trace normalization is optional" do
    assert Result.new(reason: :default).reason == :default
    assert Result.new(reason: :targeting_key_missing).reason == :targeting_key_missing
    assert Result.new(reason: :error).reason == :error
    assert Result.new(debug_trace: "nope").debug_trace == nil
  end

  test "evaluation errors expose missing targeting and malformed runtime constructors" do
    assert %Rulestead.Error{type: :missing_targeting_key} = EvaluationError.missing_targeting_key()
    assert %Rulestead.Error{type: :malformed_runtime_data} = EvaluationError.malformed_runtime_data()
    assert %Rulestead.Error{type: :invalid_value_projection} = EvaluationError.invalid_value_projection()
  end
end

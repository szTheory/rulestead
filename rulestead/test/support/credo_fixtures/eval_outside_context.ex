defmodule Rulestead.CredoFixtures.EvalOutsideContext do
  def evaluate(payload, context) do
    Rulestead.Evaluator.evaluate(payload, context)
  end
end

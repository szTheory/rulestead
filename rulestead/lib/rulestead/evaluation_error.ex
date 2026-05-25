defmodule Rulestead.EvaluationError do
  @moduledoc false
  # Constructors for evaluation-domain `Rulestead.Error` values.

  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    build(type, message, opts)
  end

  @spec not_implemented(keyword()) :: Error.t()
  def not_implemented(opts \\ []) do
    build(
      :not_implemented,
      "runtime evaluation is reserved in Phase 2 and will be implemented in Phase 3",
      opts
    )
  end

  @spec missing_targeting_key(keyword()) :: Error.t()
  def missing_targeting_key(opts \\ []) do
    build(
      :missing_targeting_key,
      "targeting_key is required for sticky evaluation",
      opts
    )
  end

  @spec invalid_value_projection(keyword()) :: Error.t()
  def invalid_value_projection(opts \\ []) do
    build(
      :invalid_value_projection,
      "evaluation result could not be projected into the requested value shape",
      opts
    )
  end

  @spec malformed_runtime_data(keyword()) :: Error.t()
  def malformed_runtime_data(opts \\ []) do
    build(
      :malformed_runtime_data,
      "authored runtime data is malformed",
      opts
    )
  end

  defp build(type, message, opts) do
    Error.new(
      Keyword.merge(
        [
          domain: :evaluation,
          type: type,
          message: message
        ],
        opts
      )
    )
  end
end

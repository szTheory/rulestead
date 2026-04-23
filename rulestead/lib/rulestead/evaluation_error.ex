defmodule Rulestead.EvaluationError do
  @moduledoc """
  Constructors for evaluation-domain `Rulestead.Error` values.
  """

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

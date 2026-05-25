defmodule Rulestead.RulesetError do
  @moduledoc false
  # Constructors for ruleset-domain `Rulestead.Error` values.

  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :ruleset,
          type: type,
          message: message
        ],
        opts
      )
    )
  end

  @spec not_found(keyword()) :: Error.t()
  def not_found(opts \\ []) do
    new(:ruleset_not_found, "ruleset was not found", opts)
  end

  @spec invalid(keyword()) :: Error.t()
  def invalid(opts \\ []) do
    new(:invalid_ruleset, "ruleset is invalid", opts)
  end

  @spec invalid_variant_weights(keyword()) :: Error.t()
  def invalid_variant_weights(opts \\ []) do
    new(:variant_weights_invalid, "variant weights must sum to 100%", opts)
  end
end

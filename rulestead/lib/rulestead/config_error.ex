defmodule Rulestead.ConfigError do
  @moduledoc false
  # Constructors for config-domain `Rulestead.Error` values.


  alias Rulestead.Error

  @spec new(Error.type(), String.t(), keyword()) :: Error.t()
  def new(type, message, opts \\ []) do
    Error.new(
      Keyword.merge(
        [
          domain: :config,
          type: type,
          message: message
        ],
        opts
      )
    )
  end

  @spec repo_not_configured(keyword()) :: Error.t()
  def repo_not_configured(opts \\ []) do
    new(:repo_not_configured, "rulestead repo is not configured", opts)
  end

  @spec repo_ambiguous(keyword()) :: Error.t()
  def repo_ambiguous(opts \\ []) do
    new(:repo_ambiguous, "multiple repos are configured; pass an explicit repo", opts)
  end

  @spec store_not_configured(keyword()) :: Error.t()
  def store_not_configured(opts \\ []) do
    new(:store_not_configured, "rulestead store adapter is not configured", opts)
  end

  @spec store_adapter_invalid(keyword()) :: Error.t()
  def store_adapter_invalid(opts \\ []) do
    new(:store_adapter_invalid, "configured rulestead store adapter is invalid", opts)
  end
end

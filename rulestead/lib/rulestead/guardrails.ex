defmodule Rulestead.Guardrails do
  @moduledoc false

  alias Rulestead.Guardrails.{Query, SignalFact}

  @spec fetch_signal(Query.t() | map() | keyword(), keyword()) :: SignalFact.t()
  def fetch_signal(query, opts \\ []) do
    query = Query.new(query)

    case provider_module(opts) do
      nil ->
        SignalFact.provider_missing(query)

      provider when is_atom(provider) ->
        if function_exported?(provider, :fetch_signal, 1) do
          SignalFact.from_query_result(query, provider.fetch_signal(query))
        else
          SignalFact.provider_missing(query)
        end
    end
  rescue
    _error ->
      SignalFact.from_query_result(query, {:error, :invalid_provider_response})
  end

  @spec provider_module(keyword()) :: module() | nil
  def provider_module(opts \\ []) do
    Keyword.get(opts, :provider) || Application.get_env(:rulestead, :guardrails_provider)
  end
end

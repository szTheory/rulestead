defmodule Rulestead.Runtime do
  @moduledoc false

  alias Rulestead.{Context, Evaluator, Result}
  alias Rulestead.Runtime.Cache

  @spec evaluate(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, Result.t()} | {:error, Rulestead.Error.t()}
  def evaluate(environment_key, flag_key, context) do
    with {:ok, %{flag_payload: flag_payload}} <- Cache.lookup(environment_key, flag_key),
         {:ok, %Result{} = result} <- Evaluator.evaluate(flag_payload, Context.normalize(context)),
         {:ok, cache_age_ms} <- Cache.cache_age_ms(environment_key) do
      {:ok, Result.normalize(%{result | cache_age_ms: cache_age_ms})}
    end
  end
end

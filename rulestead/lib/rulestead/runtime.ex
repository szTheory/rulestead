defmodule Rulestead.Runtime do
  @moduledoc false

  alias Rulestead.{Context, Error, Evaluator, Explainer, Result}
  alias Rulestead.Runtime.{Cache, Diagnostics}

  @spec evaluate(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, Result.t()} | {:error, Rulestead.Error.t()}
  def evaluate(environment_key, flag_key, context) do
    with {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
      case Cache.lookup(environment_key, flag_key) do
        {:ok, %{flag_payload: flag_payload}} ->
          with {:ok, %Result{} = result} <- Evaluator.evaluate(flag_payload, Context.normalize(context)),
               {:ok, cache_age_ms} <- Cache.cache_age_ms(environment_key) do
            {:ok, Result.normalize(%{result | cache_age_ms: cache_age_ms})}
          end

        {:error, %Error{type: :flag_not_found} = error} ->
          maybe_degraded_result(flag_key, runtime_metadata, error)
      end
    end
  end

  @spec enabled?(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, boolean()} | {:error, Rulestead.Error.t()}
  def enabled?(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      {:ok, result.enabled?}
    end
  end

  @spec get_value(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map(), term()) ::
          {:ok, term()} | {:error, Rulestead.Error.t()}
  def get_value(environment_key, flag_key, context, default) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      value =
        cond do
          result.reason == :default and is_nil(result.value) -> default
          is_nil(result.value) -> default
          true -> result.value
        end

      {:ok, value}
    end
  end

  @spec get_variant(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, String.t() | nil} | {:error, Rulestead.Error.t()}
  def get_variant(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      {:ok, result.variant}
    end
  end

  @spec explain(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, String.t()} | {:error, Rulestead.Error.t()}
  def explain(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context),
         {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
      {:ok, Explainer.runtime_explain(result.debug_trace, runtime_metadata)}
    end
  end

  @spec diagnostics() :: map()
  def diagnostics, do: Diagnostics.current()

  defp maybe_degraded_result(flag_key, %{refresh_status: :degraded, source: :none}, _error) do
    {:ok,
     Result.new(
       flag_key: flag_key,
       reason: :default,
       enabled?: false,
       value: nil,
       variant: nil,
       cache_age_ms: nil
     )}
  end

  defp maybe_degraded_result(_flag_key, _runtime_metadata, error), do: {:error, error}
end

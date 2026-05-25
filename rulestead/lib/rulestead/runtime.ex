# credo:disable-for-this-file
defmodule Rulestead.Runtime do
  @moduledoc false

  alias Rulestead.{Context, Error, Evaluator, Explainer, Result, Telemetry}
  alias Rulestead.Runtime.{Cache, Diagnostics}

  @spec evaluate(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, Result.t()} | {:error, Rulestead.Error.t()}
  def evaluate(environment_key, flag_key, context) do
    context = Context.normalize(context)

    with {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
      lookup_result = Cache.lookup(environment_key, flag_key)
      start_metadata = runtime_start_metadata(lookup_result, flag_key, runtime_metadata, context)

      Telemetry.span(
        [:rulestead, :eval, :decide],
        Telemetry.metadata(start_metadata),
        fn ->
          result =
            case lookup_result do
              {:ok, %{flag_payload: flag_payload}} ->
                emit_cache_event(:hit, flag_payload, context, runtime_metadata, %{
                  reason: :cache_hit
                })

                maybe_emit_stale_used(flag_payload, context, runtime_metadata)

                with {:ok, %Result{} = result} <- Evaluator.evaluate(flag_payload, context),
                     {:ok, cache_age_ms} <- Cache.cache_age_ms(environment_key) do
                  {:ok, Result.normalize(%{result | cache_age_ms: cache_age_ms})}
                end

              {:error, %Error{type: :flag_not_found} = error} ->
                emit_cache_event(:miss, nil, context, runtime_metadata, %{
                  flag_key: flag_key,
                  reason: :cache_miss
                })

                maybe_degraded_result(flag_key, runtime_metadata, error)
            end

          {result, runtime_eval_stop_metadata(result, runtime_metadata, context)}
        end
      )
    end
  end

  @spec enabled?(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, boolean()} | {:error, Rulestead.Error.t()}
  def enabled?(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      {:ok, result.enabled?}
    end
  end

  @spec get_value(
          String.t() | atom(),
          String.t() | atom(),
          Context.t() | keyword() | map(),
          term()
        ) ::
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

  @spec diagnostics(keyword()) :: map()
  def diagnostics(opts \\ []), do: Diagnostics.current(opts)

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

  defp maybe_degraded_result(flag_key, %{refresh_status: :stale} = runtime_metadata, _error) do
    Telemetry.execute(
      [:rulestead, :runtime, :cache, :stale_used],
      %{count: 1},
      Telemetry.metadata(
        Telemetry.runtime_metadata(runtime_metadata, %{
          flag_key: flag_key,
          reason: :stale_snapshot
        })
      )
    )

    {:ok,
     Result.new(
       flag_key: flag_key,
       reason: :default,
       enabled?: false,
       value: nil,
       variant: nil,
       cache_age_ms: runtime_metadata.cache_age_ms
     )}
  end

  defp maybe_degraded_result(_flag_key, _runtime_metadata, error), do: {:error, error}

  defp maybe_emit_stale_used(flag_payload, context, %{refresh_status: :stale} = runtime_metadata) do
    emit_cache_event(:stale_used, flag_payload, context, runtime_metadata, %{
      reason: :stale_snapshot
    })
  end

  defp maybe_emit_stale_used(_flag_payload, _context, _runtime_metadata), do: :ok

  defp emit_cache_event(event, flag_payload, context, runtime_metadata, attrs) do
    metadata =
      flag_payload
      |> Telemetry.base_metadata(context, attrs)
      |> Map.merge(Telemetry.runtime_metadata(runtime_metadata, attrs))

    measurements =
      case event do
        :hit -> %{}
        _event -> %{count: 1}
      end

    Telemetry.execute(
      [:rulestead, :runtime, :cache, event],
      measurements,
      Telemetry.metadata(metadata)
    )
  end

  defp runtime_eval_stop_metadata({:ok, %Result{} = result}, runtime_metadata, context) do
    Telemetry.runtime_metadata(runtime_metadata)
    |> Map.merge(Telemetry.result_metadata(result, context))
  end

  defp runtime_eval_stop_metadata({:error, %Error{} = error}, runtime_metadata, context) do
    Telemetry.runtime_metadata(runtime_metadata)
    |> Map.merge(%{
      environment: runtime_metadata.environment_key,
      has_targeting_key?: not is_nil(context.targeting_key),
      matched_rule_count: 0,
      reason: error.type
    })
  end

  defp runtime_start_metadata(
         {:ok, %{flag_payload: flag_payload}},
         _flag_key,
         runtime_metadata,
         context
       ) do
    flag_payload
    |> Telemetry.base_metadata(context)
    |> Map.merge(Telemetry.runtime_metadata(runtime_metadata))
  end

  defp runtime_start_metadata(_lookup_result, flag_key, runtime_metadata, context) do
    Telemetry.runtime_metadata(runtime_metadata, %{
      environment: runtime_metadata.environment_key,
      flag_key: flag_key,
      has_targeting_key?: not is_nil(context.targeting_key)
    })
  end
end

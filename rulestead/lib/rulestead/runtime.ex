# credo:disable-for-this-file
defmodule Rulestead.Runtime do
  @moduledoc """
  Cached, keyed flag lookup for running Phoenix and Plug applications.

  Where `Rulestead.evaluate/3` is the pure evaluator over an authored flag
  *payload* you already hold, `Rulestead.Runtime` resolves a flag by
  `environment_key` and `flag_key` against the local snapshot cache and then
  evaluates it. Use it in request and job paths where you do not want to fetch and
  pass payloads yourself.

  ```elixir
  {:ok, true} =
    Rulestead.Runtime.enabled?("production", "checkout_v2", context)
  ```

  ## Payload-first vs cached lookup

  | You have… | Use |
  |-----------|-----|
  | an authored flag payload | `Rulestead.evaluate/3` |
  | an environment + flag key, snapshot cache running | `Rulestead.Runtime` |

  Both share the same deterministic evaluator and the same `%Rulestead.Result{}`.

  ## Supported surface

  This facade is a closed catalog: `evaluate/3`, `enabled?/3`, `get_value/4`,
  `get_variant/3`, `explain/3`, and `diagnostics/1`. Modules under
  `Rulestead.Runtime.*` (cache, snapshot, refresh) are **implementation detail and
  not public API** — see [API Stability](api_stability.md).
  """

  alias Rulestead.{Context, Error, Evaluator, Explainer, Result, Telemetry}
  alias Rulestead.Runtime.{Cache, Diagnostics}

  @doc """
  Resolves a flag from the snapshot cache and evaluates it against the given
  context.

  Arguments:

  - `environment_key` — the environment to look up (e.g. `"production"`)
  - `flag_key` — the flag identifier (e.g. `"checkout_v2"`)
  - `context` — a `%Rulestead.Context{}`, keyword list, or map describing the
    requesting actor and environment

  Returns `{:ok, %Rulestead.Result{}}` on success, or
  `{:error, %Rulestead.Error{}}` when the cache is unavailable or the flag is
  not found.

  ```elixir
  context = Rulestead.Context.new(environment: "production", targeting_key: "u1")
  {:ok, result} = Rulestead.Runtime.evaluate("production", "checkout_v2", context)
  result.enabled?
  ```
  """
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

  @doc """
  Evaluates a flag and returns whether it is enabled for the given context.

  Derives the result from `evaluate/3`. Returns `{:ok, boolean()}` on success,
  or `{:error, %Rulestead.Error{}}` when evaluation fails.
  """
  @spec enabled?(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, boolean()} | {:error, Rulestead.Error.t()}
  def enabled?(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      {:ok, result.enabled?}
    end
  end

  @doc """
  Evaluates a flag and returns its configured value, falling back to `default`.

  The fourth argument, `default`, is returned when the result's `:value` is `nil`
  or the evaluation reason is `:default`. This covers degraded-cache scenarios
  where the flag is not found and a safe fallback is needed.

  Returns `{:ok, term()}` on success, or `{:error, %Rulestead.Error{}}` when
  evaluation fails.
  """
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

  @doc """
  Evaluates a flag and returns the matched variant key, or `nil` when no variant
  applies.

  Returns `{:ok, String.t() | nil}` on success, or `{:error, %Rulestead.Error{}}`
  when evaluation fails.
  """
  @spec get_variant(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, String.t() | nil} | {:error, Rulestead.Error.t()}
  def get_variant(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context) do
      {:ok, result.variant}
    end
  end

  @doc """
  Evaluates a flag and returns a human-readable explanation of the evaluation
  decision.

  Requires a running cache with available runtime metadata for the given
  `environment_key`. The returned string describes which rule matched, what the
  bucketing outcome was, and why — useful for support tools, operator dashboards,
  and debugging.

  Returns `{:ok, String.t()}` on success, or `{:error, %Rulestead.Error{}}` when
  evaluation or metadata retrieval fails.
  """
  @spec explain(String.t() | atom(), String.t() | atom(), Context.t() | keyword() | map()) ::
          {:ok, String.t()} | {:error, Rulestead.Error.t()}
  def explain(environment_key, flag_key, context) do
    with {:ok, %Result{} = result} <- evaluate(environment_key, flag_key, context),
         {:ok, runtime_metadata} <- Cache.runtime_metadata(environment_key) do
      {:ok, Explainer.runtime_explain(result.debug_trace, runtime_metadata)}
    end
  end

  @doc """
  Returns a map of current runtime cache state for all known environments.

  `opts` is a keyword list, currently unused and reserved for future filtering
  options. Pass `[]` or omit the argument entirely.

  The returned map is keyed by environment name and includes cache freshness,
  refresh status, flag counts, and snapshot timestamps. Useful for health checks,
  operator dashboards, and debugging cache state without querying the store
  directly.
  """
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

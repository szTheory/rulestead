defmodule Rulestead.Runtime.Cache do
  @moduledoc false

  alias Rulestead.{EvaluationError, Runtime.Snapshot}

  @flags_table :rulestead_runtime_cache_flags
  @env_table :rulestead_runtime_cache_envs

  @type env_state :: %{
          required(:environment_key) => String.t(),
          required(:version) => pos_integer(),
          required(:published_at) => DateTime.t(),
          required(:generated_at) => DateTime.t() | nil,
          required(:applied_at) => DateTime.t(),
          required(:applied_monotonic_ms) => integer(),
          optional(:metadata) => map(),
          optional(:flag_count) => non_neg_integer()
        }

  @type flag_state :: %{
          required(:environment_key) => String.t(),
          required(:flag_key) => String.t(),
          required(:flag_payload) => map(),
          required(:version) => pos_integer(),
          required(:published_at) => DateTime.t(),
          required(:applied_at) => DateTime.t()
        }

  @spec apply(Snapshot.t()) :: {:ok, %{applied?: boolean(), version: pos_integer()}} | {:error, Rulestead.Error.t()}
  def apply(%Snapshot{} = snapshot) do
    ensure_tables()

    environment_key = snapshot.environment_key
    current_version = current_version(environment_key)

    if snapshot.version > current_version do
      applied_at = DateTime.utc_now()
      applied_monotonic_ms = System.monotonic_time(:millisecond)

      Enum.each(snapshot.flags, fn {flag_key, %{flag_payload: flag_payload}} ->
        :ets.insert(
          @flags_table,
          {{environment_key, flag_key},
           %{
             environment_key: environment_key,
             flag_key: flag_key,
             flag_payload: flag_payload,
             version: snapshot.version,
             published_at: snapshot.published_at,
             applied_at: applied_at
           }}
        )
      end)

      :ets.insert(
        @env_table,
        {environment_key,
         %{
           environment_key: environment_key,
           version: snapshot.version,
           published_at: snapshot.published_at,
           generated_at: snapshot.generated_at,
           applied_at: applied_at,
           applied_monotonic_ms: applied_monotonic_ms,
           metadata: snapshot.metadata,
           flag_count: map_size(snapshot.flags)
         }}
      )

      {:ok, %{applied?: true, version: snapshot.version}}
    else
      {:ok, %{applied?: false, version: current_version}}
    end
  end

  @spec lookup(String.t() | atom(), String.t() | atom()) :: {:ok, flag_state()} | {:error, Rulestead.Error.t()}
  def lookup(environment_key, flag_key) do
    ensure_tables()
    environment_key = to_string(environment_key)
    flag_key = to_string(flag_key)

    case :ets.lookup(@flags_table, {environment_key, flag_key}) do
      [{{^environment_key, ^flag_key}, entry}] -> {:ok, entry}
      [] -> {:error, EvaluationError.new(:flag_not_found, "runtime flag was not found", metadata: %{environment_key: environment_key, flag_key: flag_key})}
    end
  end

  @spec environment(String.t() | atom()) :: {:ok, env_state()} | {:error, Rulestead.Error.t()}
  def environment(environment_key) do
    ensure_tables()
    environment_key = to_string(environment_key)

    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, state}] -> {:ok, state}
      [] -> {:error, EvaluationError.new(:flag_not_found, "runtime environment was not loaded", metadata: %{environment_key: environment_key})}
    end
  end

  @spec cache_age_ms(String.t() | atom()) :: {:ok, non_neg_integer()} | {:error, Rulestead.Error.t()}
  def cache_age_ms(environment_key) do
    with {:ok, %{applied_monotonic_ms: applied_monotonic_ms}} <- environment(environment_key) do
      {:ok, max(System.monotonic_time(:millisecond) - applied_monotonic_ms, 0)}
    end
  end

  @spec reset(String.t() | atom()) :: :ok
  def reset(environment_key) do
    ensure_tables()
    environment_key = to_string(environment_key)
    match_spec = [{{{environment_key, :_}, :_}, [], [true]}]
    :ets.select_delete(@flags_table, match_spec)
    :ets.delete(@env_table, environment_key)
    :ok
  end

  defp current_version(environment_key) do
    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, %{version: version}}] -> version
      [] -> 0
    end
  end

  defp ensure_tables do
    ensure_table(@flags_table)
    ensure_table(@env_table)
  end

  defp ensure_table(name) do
    case :ets.whereis(name) do
      :undefined ->
        :ets.new(name, [:named_table, :public, :set, {:read_concurrency, true}])

      _tid ->
        name
    end
  end
end

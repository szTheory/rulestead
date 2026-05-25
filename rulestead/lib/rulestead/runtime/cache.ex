defmodule Rulestead.Runtime.Cache do
  @moduledoc false

  alias Rulestead.{EvaluationError, Runtime.Snapshot}

  @flags_table :rulestead_runtime_cache_flags
  @env_table :rulestead_runtime_cache_envs

  @type env_state :: %{
          required(:environment_key) => String.t(),
          optional(:version) => pos_integer() | nil,
          optional(:published_at) => DateTime.t() | nil,
          optional(:generated_at) => DateTime.t() | nil,
          optional(:applied_at) => DateTime.t() | nil,
          optional(:applied_monotonic_ms) => integer() | nil,
          required(:refresh_status) => :ready | :degraded | :stale,
          required(:source) => :ets | :disk | :none,
          optional(:last_refresh_error) => atom() | nil,
          optional(:disk_backup_status) => atom(),
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

  @spec ensure_tables() :: :ok
  def ensure_tables do
    ensure_table(@flags_table)
    ensure_table(@env_table)
    :ok
  end

  @spec register_environment(String.t() | atom()) :: :ok
  def register_environment(environment_key) do
    ensure_tables()
    environment_key = to_string(environment_key)

    case :ets.lookup(@env_table, environment_key) do
      [] ->
        :ets.insert(@env_table, {environment_key, empty_env_state(environment_key)})

      [{^environment_key, state}] ->
        :ets.insert(@env_table, {environment_key, normalize_env_state(state)})
    end

    :ok
  end

  @spec apply(Snapshot.t(), keyword()) ::
          {:ok, %{applied?: boolean(), version: pos_integer()}} | {:error, Rulestead.Error.t()}
  def apply(%Snapshot{} = snapshot, opts \\ []) do
    ensure_tables()

    environment_key = snapshot.environment_key
    current_version = current_version(environment_key)
    source = Keyword.get(opts, :source, :ets)
    disk_backup_status = Keyword.get(opts, :disk_backup_status)

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
           refresh_status: :ready,
           source: source,
           last_refresh_error: nil,
           disk_backup_status: disk_backup_status || current_backup_status(environment_key),
           metadata: snapshot.metadata,
           flag_count: map_size(snapshot.flags)
         }}
      )

      {:ok, %{applied?: true, version: snapshot.version}}
    else
      {:ok, %{applied?: false, version: current_version}}
    end
  end

  @spec lookup(String.t() | atom(), String.t() | atom()) ::
          {:ok, flag_state()} | {:error, Rulestead.Error.t()}
  def lookup(environment_key, flag_key) do
    ensure_tables()
    environment_key = to_string(environment_key)
    flag_key = to_string(flag_key)

    case :ets.lookup(@flags_table, {environment_key, flag_key}) do
      [{{^environment_key, ^flag_key}, entry}] ->
        {:ok, entry}

      [] ->
        {:error,
         EvaluationError.new(:flag_not_found, "runtime flag was not found",
           metadata: %{environment_key: environment_key, flag_key: flag_key}
         )}
    end
  end

  @spec environment(String.t() | atom()) :: {:ok, env_state()} | {:error, Rulestead.Error.t()}
  def environment(environment_key) do
    ensure_tables()
    environment_key = to_string(environment_key)

    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, state}] ->
        {:ok, normalize_env_state(state)}

      [] ->
        {:error,
         EvaluationError.new(:flag_not_found, "runtime environment was not loaded",
           metadata: %{environment_key: environment_key}
         )}
    end
  end

  @spec cache_age_ms(String.t() | atom()) ::
          {:ok, non_neg_integer() | nil} | {:error, Rulestead.Error.t()}
  def cache_age_ms(environment_key) do
    with {:ok, %{applied_monotonic_ms: applied_monotonic_ms}} <- environment(environment_key) do
      case applied_monotonic_ms do
        value when is_integer(value) -> {:ok, max(System.monotonic_time(:millisecond) - value, 0)}
        _ -> {:ok, nil}
      end
    end
  end

  @spec runtime_metadata(String.t() | atom()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def runtime_metadata(environment_key) do
    with {:ok, state} <- environment(environment_key),
         {:ok, cache_age_ms} <- cache_age_ms(environment_key) do
      {:ok,
       %{
         environment_key: state.environment_key,
         snapshot_version: state.version,
         applied_at: state.applied_at,
         published_at: state.published_at,
         cache_age_ms: cache_age_ms,
         source: state.source,
         refresh_status: state.refresh_status,
         stale_used?: false,
         disk_backup_status: Map.get(state, :disk_backup_status, :disabled),
         last_refresh_error: state.last_refresh_error
       }}
    end
  end

  @spec diagnostics() :: [map()]
  def diagnostics do
    ensure_tables()

    @env_table
    |> :ets.tab2list()
    |> Enum.map(fn {_environment_key, state} ->
      {:ok, metadata} = runtime_metadata(state.environment_key)
      metadata
    end)
    |> Enum.sort_by(& &1.environment_key)
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

  @spec mark_refresh_failed(String.t() | atom(), term()) :: :ok
  def mark_refresh_failed(environment_key, error \\ nil) do
    ensure_tables()
    environment_key = to_string(environment_key)
    state = current_env_state(environment_key)

    next_state =
      state
      |> Map.put(:refresh_status, refresh_status_for(state))
      |> Map.put(:source, source_for(state))
      |> Map.put(:last_refresh_error, normalize_error_code(error))

    :ets.insert(@env_table, {environment_key, next_state})
    :ok
  end

  @spec put_backup_status(String.t() | atom(), atom()) :: :ok
  def put_backup_status(environment_key, status) when is_atom(status) do
    ensure_tables()
    environment_key = to_string(environment_key)
    state = current_env_state(environment_key)
    :ets.insert(@env_table, {environment_key, Map.put(state, :disk_backup_status, status)})
    :ok
  end

  defp current_version(environment_key) do
    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, %{version: version}}] when is_integer(version) -> version
      [{^environment_key, _state}] -> 0
      [] -> 0
    end
  end

  defp ensure_table(name) do
    case :ets.whereis(name) do
      :undefined ->
        try do
          :ets.new(name, [:named_table, :public, :set, {:read_concurrency, true}])
        rescue
          ArgumentError -> name
        end

      _tid ->
        name
    end
  end

  defp current_env_state(environment_key) do
    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, state}] -> normalize_env_state(state)
      [] -> empty_env_state(environment_key)
    end
  end

  defp normalize_env_state(state) do
    state
    |> Map.put_new(:version, nil)
    |> Map.put_new(:published_at, nil)
    |> Map.put_new(:generated_at, nil)
    |> Map.put_new(:applied_at, nil)
    |> Map.put_new(:applied_monotonic_ms, nil)
    |> Map.put_new(:refresh_status, refresh_status_for(state))
    |> Map.put_new(:source, source_for(state))
    |> Map.put_new(:last_refresh_error, nil)
    |> Map.put_new(:disk_backup_status, :disabled)
    |> Map.put_new(:metadata, %{})
    |> Map.put_new(:flag_count, 0)
  end

  defp empty_env_state(environment_key) do
    %{
      environment_key: environment_key,
      version: nil,
      published_at: nil,
      generated_at: nil,
      applied_at: nil,
      applied_monotonic_ms: nil,
      refresh_status: :degraded,
      source: :none,
      last_refresh_error: nil,
      disk_backup_status: :disabled,
      metadata: %{},
      flag_count: 0
    }
  end

  defp refresh_status_for(%{version: version}) when is_integer(version) and version > 0,
    do: :stale

  defp refresh_status_for(_state), do: :degraded

  defp source_for(%{version: version, source: source})
       when is_integer(version) and version > 0 and source in [:ets, :disk] do
    source
  end

  defp source_for(%{version: version}) when is_integer(version) and version > 0, do: :ets
  defp source_for(_state), do: :none

  defp current_backup_status(environment_key) do
    case :ets.lookup(@env_table, environment_key) do
      [{^environment_key, state}] -> Map.get(state, :disk_backup_status, :disabled)
      [] -> :disabled
    end
  end

  defp normalize_error_code(%{type: type}) when is_atom(type), do: type
  defp normalize_error_code(type) when is_atom(type), do: type
  defp normalize_error_code(_error), do: :refresh_failed
end

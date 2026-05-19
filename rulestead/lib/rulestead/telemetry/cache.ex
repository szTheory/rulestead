defmodule Rulestead.Telemetry.Cache do
  @moduledoc false
  # ETS write-behind caching for telemetry.
  # Stores `last_evaluated_at` and `variants_served` for each flag evaluated.

  use GenServer

  @table :rulestead_telemetry_cache

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def table_name, do: @table

  @doc """
  Record an evaluation.
  Uses public ETS for high throughput.
  """
  def record_evaluation(flag_key, environment_key, variant, timestamp) do
    key = {flag_key, environment_key}
    try do
      :ets.insert(@table, {{key, :last_evaluated_at}, timestamp})
      
      try do
        :ets.update_counter(@table, {key, :variants_served, variant}, {2, 1})
      rescue
        ArgumentError ->
          :ets.insert(@table, {{key, :variants_served, variant}, 1})
      end
    rescue
      ArgumentError ->
        # Table does not exist (likely in test environment where Cache is not started)
        :ok
    end
    :ok
  end

  @doc """
  Returns a snapshot of the cache.
  """
  def snapshot do
    :ets.tab2list(@table)
    |> Enum.reduce(%{}, fn
      {{{flag_key, env_key}, :last_evaluated_at}, timestamp}, acc ->
        key = {flag_key, env_key}
        map = Map.get(acc, key, %{})
        Map.put(acc, key, Map.put(map, :last_evaluated_at, timestamp))

      {{{flag_key, env_key}, :variants_served, variant}, count}, acc ->
        key = {flag_key, env_key}
        map = Map.get(acc, key, %{})
        variants = Map.get(map, :variants_served, %{})
        map = Map.put(map, :variants_served, Map.put(variants, variant, count))
        Map.put(acc, key, map)
    end)
  end

  @doc """
  Clears the cache for flushing.
  """
  def clear do
    :ets.delete_all_objects(@table)
    :ok
  end

  @impl true
  def init(_opts) do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
      _ ->
        :ok
    end
    {:ok, %{}}
  end
end

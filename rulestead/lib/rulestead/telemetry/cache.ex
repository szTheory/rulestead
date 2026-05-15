defmodule Rulestead.Telemetry.Cache do
  @moduledoc """
  ETS write-behind caching for telemetry.
  Stores `last_evaluated_at` and `variants_served` for each flag evaluated.
  """
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
  def record_evaluation(flag_key, variant, timestamp) do
    :ets.insert(@table, {{flag_key, :last_evaluated_at}, timestamp})
    
    try do
      :ets.update_counter(@table, {flag_key, :variants_served, variant}, {2, 1})
    rescue
      ArgumentError ->
        :ets.insert(@table, {{flag_key, :variants_served, variant}, 1})
    end
    :ok
  end

  @doc """
  Returns a snapshot of the cache.
  """
  def snapshot do
    :ets.tab2list(@table)
    |> Enum.reduce(%{}, fn
      {{flag_key, :last_evaluated_at}, timestamp}, acc ->
        map = Map.get(acc, flag_key, %{})
        Map.put(acc, flag_key, Map.put(map, :last_evaluated_at, timestamp))

      {{flag_key, :variants_served, variant}, count}, acc ->
        map = Map.get(acc, flag_key, %{})
        variants = Map.get(map, :variants_served, %{})
        map = Map.put(map, :variants_served, Map.put(variants, variant, count))
        Map.put(acc, flag_key, map)
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
    # Since we run tests with async: true and GenServer might be started multiple times,
    # we should handle if the table already exists, or don't name the GenServer.
    # Actually, if we use a named ETS table and async tests, we'll get an error unless we handle it properly,
    # or if we don't name the table and pass the table ref. But we're naming it `@table` which is a global atom.
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
      _ ->
        :ok
    end
    {:ok, %{}}
  end
end

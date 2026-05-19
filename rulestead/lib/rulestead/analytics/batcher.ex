defmodule Rulestead.Analytics.Batcher do
  @moduledoc false
  # High-throughput, non-blocking ingestion buffer for analytics events.
  # Uses ETS as a buffer and periodically flushes to the database.

  use GenServer
  require Logger

  alias Rulestead.Analytics.EventMapper
  alias Rulestead.Analytics.Event
  alias Rulestead.Repo

  @table :rulestead_analytics_batcher
  @default_flush_interval 5_000
  @default_max_size 50_000
  @default_batch_size 2_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Inserts a raw event into the ETS buffer. Non-blocking.
  Drops the event if the buffer is full.
  """
  def insert(event) do
    try do
      if buffer_full?() do
        :ok # Drop event
      else
        key = System.unique_integer([:monotonic])
        :ets.insert(@table, {key, event})
        :ok
      end
    rescue
      ArgumentError ->
        # Table does not exist (likely test environment not starting Batcher)
        :ok
    end
  end

  def table_name, do: @table

  @impl true
  def init(opts) do
    case :ets.info(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
      _ ->
        :ok
    end

    flush_interval = Keyword.get(opts, :flush_interval, @default_flush_interval)
    
    # Don't schedule flush if interval is 0 or false (useful for tests)
    if flush_interval && flush_interval > 0 do
      schedule_flush(flush_interval)
    end

    state = %{
      flush_interval: flush_interval,
      batch_size: Keyword.get(opts, :batch_size, @default_batch_size),
      max_size: Keyword.get(opts, :max_size, @default_max_size)
    }

    :persistent_term.put({__MODULE__, :max_size}, state.max_size)

    {:ok, state}
  end

  @impl true
  def handle_info(:flush, state) do
    flush_events(state.batch_size)
    
    if state.flush_interval && state.flush_interval > 0 do
      schedule_flush(state.flush_interval)
    end
    
    {:noreply, state}
  end

  @doc false
  # Exposed for testing
  def flush_now(batch_size \\ @default_batch_size) do
    flush_events(batch_size)
  end

  defp schedule_flush(interval) do
    Process.send_after(self(), :flush, interval)
  end

  defp buffer_full? do
    max_size = :persistent_term.get({__MODULE__, :max_size}, @default_max_size)
    case :ets.info(@table, :size) do
      size when is_integer(size) and size >= max_size -> true
      _ -> false
    end
  end

  defp flush_events(batch_size) do
    # We select up to `batch_size` items and delete them
    match_spec = [{:"$1", [], [:"$1"]}]
    case :ets.select(@table, match_spec, batch_size) do
      :"$end_of_table" ->
        :ok

      {matches, _continuation} ->
        # matches is a list of {key, event}
        events = Enum.map(matches, fn {_key, event} -> event end)
        
        # Atomically remove them from ETS so we don't process them again
        # since we might only take a partial batch, we explicitly delete these keys
        Enum.each(matches, fn {key, _} -> :ets.delete(@table, key) end)
        
        insert_to_db(events)
        
        # If we hit the limit, there might be more, but we'll get them next flush
        # or we could recursively call flush_events until empty. For now, just batch_size per flush.
        :ok
    end
  rescue
    ArgumentError ->
      # Table doesn't exist
      :ok
  end

  defp insert_to_db([]), do: :ok
  defp insert_to_db(raw_events) do
    insert_maps = Enum.map(raw_events, &EventMapper.to_insert_map/1)

    try do
      Repo.insert_all(Event, insert_maps)
    rescue
      e ->
        Logger.error("Failed to insert analytics events: #{inspect(e)}")
        # In a robust system we might want to retry, but for high throughput analytics
        # dropping on DB failure is often preferred to crashing the app.
        :ok
    end
  end
end

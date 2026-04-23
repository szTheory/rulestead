defmodule Rulestead.Runtime.Refresh do
  @moduledoc false

  use GenServer

  alias Rulestead.{Error, Telemetry}
  alias Rulestead.Runtime.{Backup, Cache, Config, Snapshot}
  alias Rulestead.Store.Command

  @refresh_message :rulestead_runtime_refresh

  @type state :: %{
          environment_key: String.t(),
          store: module() | nil,
          pubsub: module() | atom() | nil,
          pubsub_topic: String.t(),
          poll_interval_ms: pos_integer(),
          refresh_jitter_ms: non_neg_integer(),
          backoff_ms: [pos_integer()],
          attempt: non_neg_integer(),
          next_due_ms: integer(),
          next_backoff_ms: non_neg_integer(),
          auto_tick?: boolean(),
          snapshot_opts: keyword(),
          clock: (() -> DateTime.t())
        }

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    environment_key = opts |> Keyword.fetch!(:environment_key) |> to_string()

    %{
      id: {__MODULE__, environment_key},
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  @spec sync(GenServer.server()) :: :ok
  def sync(server), do: GenServer.call(server, :sync)

  @spec tick(GenServer.server()) :: :ok
  def tick(server), do: GenServer.call(server, :tick)

  @spec refresh_now(GenServer.server()) :: :ok
  def refresh_now(server), do: GenServer.call(server, :refresh_now)

  @spec status(GenServer.server()) :: map()
  def status(server), do: GenServer.call(server, :status)

  @impl true
  def init(opts) do
    snapshot_config = Config.snapshot(opts)
    environment_key = opts |> Keyword.fetch!(:environment_key) |> to_string()

    state = %{
      environment_key: environment_key,
      store: Keyword.get(opts, :store, Config.store(opts)),
      pubsub: Keyword.get(opts, :pubsub),
      pubsub_topic: Keyword.get(opts, :pubsub_topic, snapshot_config[:pubsub_topic]),
      poll_interval_ms: Keyword.get(opts, :poll_interval_ms, snapshot_config[:refresh_interval_ms]),
      refresh_jitter_ms: Keyword.get(opts, :refresh_jitter_ms, snapshot_config[:refresh_jitter_ms]),
      backoff_ms: Keyword.get(opts, :backoff_ms, snapshot_config[:backoff_ms]),
      attempt: 0,
      next_due_ms: 0,
      next_backoff_ms: 0,
      auto_tick?: Keyword.get(opts, :auto_tick?, true),
      snapshot_opts: snapshot_config,
      clock: Keyword.get(opts, :clock, default_clock(Keyword.get(opts, :store, Config.store(opts))))
    }

    Cache.register_environment(environment_key)
    :ok = Backup.restore(environment_key, opts)
    subscribe(state)
    state = refresh(state)
    {:ok, schedule_next(state)}
  end

  @impl true
  def handle_call(:sync, _from, state), do: {:reply, :ok, state}

  def handle_call(:tick, _from, state) do
    now_ms = now_ms(state)

    next_state =
      if now_ms >= state.next_due_ms do
        state |> refresh() |> schedule_next()
      else
        state
      end

    {:reply, :ok, next_state}
  end

  def handle_call(:refresh_now, _from, state) do
    next_state = state |> refresh() |> schedule_next()
    {:reply, :ok, next_state}
  end

  def handle_call(:status, _from, state) do
    refresh_status =
      case Cache.runtime_metadata(state.environment_key) do
        {:ok, metadata} -> metadata.refresh_status
        {:error, _error} -> :degraded
      end

    {:reply, %{attempt: state.attempt, next_backoff_ms: state.next_backoff_ms, refresh_status: refresh_status}, state}
  end

  @impl true
  def handle_info(:tick, state) do
    now_ms = now_ms(state)

    next_state =
      if now_ms >= state.next_due_ms do
        state |> refresh() |> schedule_next()
      else
        schedule_next(state)
      end

    {:noreply, next_state}
  end

  def handle_info({@refresh_message, payload}, state) do
    next_state =
      if matches_environment?(payload, state.environment_key) and newer_version?(payload, state.environment_key) do
        state |> refresh() |> schedule_next()
      else
        state
      end

    {:noreply, next_state}
  end

  defp refresh(state) do
    Telemetry.execute(
      [:rulestead, :runtime, :cache, :refresh],
      %{count: 1},
      Telemetry.metadata(%{environment: state.environment_key, reason: :refresh})
    )

    case fetch_snapshot(state) do
      {:ok, snapshot} ->
        with {:ok, compiled} <- Snapshot.compile(snapshot),
             {:ok, _applied} <- Cache.apply(compiled, source: :ets) do
          emit_snapshot_applied(compiled, :ets)
          :ok = Backup.persist(compiled, snapshot: state.snapshot_opts)
          %{state | attempt: 0, next_backoff_ms: 0, next_due_ms: now_ms(state) + poll_delay(state)}
        else
          {:error, error} -> fail_refresh(state, error)
        end

      {:error, error} ->
        fail_refresh(state, error)
    end
  end

  defp fetch_snapshot(%{environment_key: environment_key, store: adapter}) when is_atom(adapter) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, :fetch_snapshot, 1) do
      command = Command.FetchSnapshot.new(environment_key)

      Telemetry.span(
        [:rulestead, :store, :read],
        Telemetry.metadata(Telemetry.command_metadata(command, %{operation: "fetch_snapshot"})),
        fn ->
          result = adapter.fetch_snapshot(command)
          {result, refresh_store_stop_metadata(result)}
        end
      )
    else
      {:error, :store_unavailable}
    end
  end

  defp fetch_snapshot(_state), do: {:error, :store_unavailable}

  defp fail_refresh(state, error) do
    Cache.mark_refresh_failed(state.environment_key, error)
    next_backoff_ms = next_backoff(state)

    %{
      state
      | attempt: state.attempt + 1,
        next_backoff_ms: next_backoff_ms,
        next_due_ms: now_ms(state) + next_backoff_ms
    }
  end

  defp next_backoff(%{backoff_ms: []}), do: 1_000

  defp next_backoff(%{backoff_ms: backoff_ms, attempt: attempt}) do
    Enum.at(backoff_ms, attempt, List.last(backoff_ms))
  end

  defp schedule_next(%{auto_tick?: false} = state), do: state

  defp schedule_next(state) do
    delay = max(state.next_due_ms - now_ms(state), 0)
    Process.send_after(self(), :tick, delay)
    state
  end

  defp subscribe(%{pubsub: pubsub, pubsub_topic: topic}) when not is_nil(pubsub) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.subscribe(pubsub, topic)
    end
  end

  defp subscribe(_state), do: :ok

  defp now_ms(%{clock: clock}) do
    clock.() |> DateTime.to_unix(:millisecond)
  end

  defp poll_delay(state) do
    state.poll_interval_ms + state.refresh_jitter_ms
  end

  defp default_clock(Rulestead.Fake), do: &Rulestead.Fake.Control.now!/0
  defp default_clock(_store), do: &DateTime.utc_now/0

  defp matches_environment?(payload, environment_key) when is_map(payload) do
    payload_environment_key =
      Map.get(payload, :environment_key) || Map.get(payload, "environment_key")

    to_string(payload_environment_key) == environment_key
  end

  defp matches_environment?(_payload, _environment_key), do: false

  defp newer_version?(payload, environment_key) do
    incoming_version = Map.get(payload, :snapshot_version) || Map.get(payload, "snapshot_version") || 0

    current_version =
      case Cache.runtime_metadata(environment_key) do
        {:ok, %{snapshot_version: version}} when is_integer(version) -> version
        _ -> 0
      end

    incoming_version > current_version
  end

  defp emit_snapshot_applied(compiled, source) do
    Telemetry.execute(
      [:rulestead, :runtime, :snapshot, :applied],
      %{count: 1},
      Telemetry.metadata(%{
        environment: compiled.environment_key,
        snapshot_version: compiled.version,
        reason: :applied,
        source: source
      })
    )
  end

  defp refresh_store_stop_metadata({:ok, snapshot}) when is_map(snapshot) do
    %{
      environment: snapshot[:environment_key],
      snapshot_version: snapshot[:version],
      reason: :fetched
    }
  end

  defp refresh_store_stop_metadata({:error, %Error{} = error}) do
    %{reason: error.type}
  end

  defp refresh_store_stop_metadata({:error, error}) when is_atom(error) do
    %{reason: error}
  end
end

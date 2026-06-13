# credo:disable-for-this-file
defmodule Rulestead.Redis.Publisher do
  @moduledoc false

  use GenServer

  require Logger

  alias Rulestead.Redis
  alias Rulestead.Store.Command

  @handler_id "rulestead-redis-publisher"
  @event [:rulestead, :runtime, :snapshot, :published]
  @max_fetch_attempts 10
  @fetch_retry_delay_ms 25

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(_opts) do
    attach()
    {:ok, %{}}
  end

  @impl true
  def terminate(_reason, _state) do
    :telemetry.detach(@handler_id)
    :ok
  end

  @impl true
  def handle_cast({:publish_snapshot, snapshot}, state) do
    write_snapshot(snapshot)
    {:noreply, state}
  end

  def handle_cast({:publish_snapshot_command, store, command, attempt}, state) do
    publish_snapshot_command(store, command, attempt)
    {:noreply, state}
  end

  @impl true
  def handle_info({:retry_publish_snapshot_command, store, command, attempt}, state) do
    publish_snapshot_command(store, command, attempt)
    {:noreply, state}
  end

  defp write_snapshot(snapshot) do
    case Redis.client().command(
           Redis.name(),
           ["SET", Redis.snapshot_key(snapshot.environment_key), :erlang.term_to_binary(snapshot)]
         ) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.warning("Redis snapshot publish failed: #{inspect(reason)}")
        :ok
    end
  end

  defp publish_snapshot_command(store, command, attempt) do
    case store.fetch_snapshot(command) do
      {:ok, snapshot} ->
        write_snapshot(snapshot)

      {:error, error} ->
        if attempt < @max_fetch_attempts do
          Process.send_after(
            self(),
            {:retry_publish_snapshot_command, store, command, attempt + 1},
            @fetch_retry_delay_ms
          )
        else
          Logger.warning("Redis publisher could not load snapshot: #{inspect(error)}")
        end
    end
  end

  @spec attach() :: :ok
  def attach do
    case :telemetry.attach(@handler_id, @event, &__MODULE__.handle_event/4, nil) do
      :ok -> :ok
      {:error, :already_exists} -> :ok
    end
  end

  @doc false
  def handle_event(@event, _measurements, metadata, _config) do
    if Redis.enabled?() do
      environment_key = metadata[:environment] || metadata[:environment_key]
      version = metadata[:snapshot_version]

      if environment_key do
        command =
          if is_integer(version) and version > 0 do
            Command.FetchSnapshot.new(environment_key, version: version)
          else
            Command.FetchSnapshot.new(environment_key)
          end

        with store when is_atom(store) <- Redis.publisher_store(),
             true <- function_exported?(store, :fetch_snapshot, 1),
             false <- same_process_store?(store) do
          GenServer.cast(__MODULE__, {:publish_snapshot_command, store, command, 0})
        else
          _ -> :ok
        end
      end
    end

    :ok
  end

  defp same_process_store?(store) when is_atom(store) do
    case Process.whereis(store) do
      pid when is_pid(pid) -> pid == self()
      _other -> false
    end
  end
end

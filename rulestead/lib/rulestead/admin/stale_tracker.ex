defmodule Rulestead.Admin.StaleTracker do
  @moduledoc false

  use GenServer

  @handler_id {__MODULE__, :runtime_eval_stop}
  @flush_interval 50
  @max_pending 500

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5_000
    }
  end

  @impl GenServer
  def init(opts) do
    :ok =
      Rulestead.Telemetry.attach_many(
        @handler_id,
        [[:rulestead, :eval, :decide, :stop]],
        &__MODULE__.handle_event/4,
        %{tracker: self()}
      )

    {:ok, %{pending: %{}, timer: nil, flush_interval: Keyword.get(opts, :flush_interval, @flush_interval)}}
  end

  @impl GenServer
  def terminate(_reason, _state) do
    Rulestead.Telemetry.detach(@handler_id)
    :ok
  end

  @impl GenServer
  def handle_cast({:record, flag_key, environment_key, recorded_at}, state) do
    pending =
      state.pending
      |> Map.put({flag_key, environment_key}, recorded_at)
      |> trim_pending()

    timer = state.timer || Process.send_after(self(), :flush, state.flush_interval)
    {:noreply, %{state | pending: pending, timer: timer}}
  end

  @impl GenServer
  def handle_info(:flush, state) do
    Enum.each(state.pending, fn {{flag_key, environment_key}, recorded_at} ->
      _ = Rulestead.record_evaluation(flag_key, environment_key, recorded_at)
    end)

    {:noreply, %{state | pending: %{}, timer: nil}}
  end

  @spec handle_event([atom()], map(), map(), map()) :: :ok
  def handle_event(_event, _measurements, metadata, %{tracker: tracker}) do
    with true <- runtime_eval_event?(metadata),
         flag_key when is_binary(flag_key) <- metadata[:flag_key],
         environment_key when is_binary(environment_key) <- metadata[:environment],
         true <- metadata[:reason] not in [:flag_not_found, :store_not_configured, :store_adapter_invalid] do
      recorded_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
      GenServer.cast(tracker, {:record, flag_key, environment_key, recorded_at})
    else
      _ -> :ok
    end

    :ok
  end

  defp runtime_eval_event?(metadata) do
    is_binary(metadata[:flag_key]) and
      is_binary(metadata[:environment]) and
      (not is_nil(metadata[:refresh_status]) or not is_nil(metadata[:source]))
  end

  defp trim_pending(pending) when map_size(pending) <= @max_pending, do: pending

  defp trim_pending(pending) do
    pending
    |> Enum.take(-@max_pending)
    |> Map.new()
  end
end

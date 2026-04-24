defmodule Rulestead.Oban.ScheduledExecutionWorker do
  @moduledoc false

  use Rulestead.Oban.Worker

  alias Rulestead.{Context, Telemetry}
  alias Rulestead.Store.Command

  @spec perform(map()) :: {:ok, map()} | {:error, term()}
  def perform(job) when is_map(job) do
    context = rulestead_context(job)
    args = Map.get(job, :args, %{})
    scheduled_execution_id = fetch_arg(args, "scheduled_execution_id")
    correlation_id = fetch_arg(args, "correlation_id")
    governed_action = fetch_arg(args, "governed_action")
    environment_key = fetch_arg(args, "environment_key")

    scheduled_execution = fetch_scheduled_execution(scheduled_execution_id)

    command =
      Command.ExecuteScheduledExecution.new(scheduled_execution_id,
        actor: execution_actor(context),
        reason: "scheduled execution due",
        metadata: %{
          request_id: correlation_id,
          source: "scheduled_execution_worker",
          environment_key: environment_key,
          governed_action: governed_action,
          emit_lifecycle_telemetry: false
        }
      )

    if telemetry_transition?(scheduled_execution, :started) do
      maybe_emit(:started, scheduled_execution, command, nil)
    end

    case configured_store().execute_scheduled_execution(command) do
      {:ok, %{scheduled_execution: completed} = result} ->
        if telemetry_transition?(scheduled_execution, :succeeded) do
          maybe_emit(:succeeded, completed, command, nil)
        end

        {:ok, result}

      {:error, _reason} = error ->
        case fetch_scheduled_execution(scheduled_execution_id) do
          %{state: state} = latest when state in [:quarantined, :failed, :scheduled] ->
            event = if state == :quarantined, do: :quarantined, else: :failed
            maybe_emit(event, latest, command, nil)
            error

          _other ->
            error
        end
    end
  end

  defp configured_store do
    Application.get_env(:rulestead, :store) ||
      Application.get_env(:rulestead, :store_adapter) ||
      raise "scheduled execution worker requires a configured store"
  end

  defp execution_actor(%Context{actor: nil}),
    do: %{"id" => "system:scheduler", "type" => "system", "display" => "Scheduler"}

  defp execution_actor(%Context{actor: actor}) when is_map(actor), do: Map.new(actor)
  defp execution_actor(_context), do: %{"id" => "system:scheduler", "type" => "system", "display" => "Scheduler"}

  defp fetch_arg(args, key), do: Map.get(args, key) || Map.get(args, String.to_atom(key))

  defp fetch_scheduled_execution(scheduled_execution_id) do
    case configured_store().fetch_scheduled_execution(
           Command.FetchScheduledExecution.new(scheduled_execution_id)
         ) do
      {:ok, %{scheduled_execution: scheduled_execution}} -> scheduled_execution
      _other -> nil
    end
  end

  defp maybe_emit(_event, nil, _command, _audit_event_id), do: :ok

  defp maybe_emit(event, scheduled_execution, command, audit_event_id) do
    Telemetry.execute(
      Telemetry.scheduled_execution_event(event),
      %{count: 1},
      Telemetry.metadata(
        Telemetry.scheduled_execution_metadata(scheduled_execution, %{
          action: scheduled_execution.action,
          environment_key: scheduled_execution.environment_key,
          attempt_count: attempt_count_for(event, scheduled_execution),
          audit_event_id: audit_event_id,
          executed_by: executed_by(command.actor),
          event: event
        })
      )
    )
  end

  defp attempt_count_for(:started, scheduled_execution), do: scheduled_execution.attempt_count + 1
  defp attempt_count_for(_event, scheduled_execution), do: scheduled_execution.attempt_count

  defp telemetry_transition?(%{state: state}, event)
       when event in [:started, :succeeded] and state in [:completed, :cancelled, :quarantined],
       do: false

  defp telemetry_transition?(_scheduled_execution, _event), do: true

  defp executed_by(actor) when is_map(actor) do
    case Map.get(actor, "id") || Map.get(actor, :id) do
      "system:scheduler" -> "scheduler"
      "scheduler" -> "scheduler"
      _other -> "scheduler"
    end
  end

  defp executed_by(_actor), do: "scheduler"
end

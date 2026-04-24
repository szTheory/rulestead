defmodule Rulestead.Oban.ScheduledExecutionWorker do
  @moduledoc false

  use Rulestead.Oban.Worker

  alias Rulestead.Context
  alias Rulestead.Store.Command

  @spec perform(map()) :: {:ok, map()} | {:error, term()}
  def perform(job) when is_map(job) do
    context = rulestead_context(job)
    args = Map.get(job, :args, %{})
    scheduled_execution_id = fetch_arg(args, "scheduled_execution_id")
    correlation_id = fetch_arg(args, "correlation_id")
    governed_action = fetch_arg(args, "governed_action")
    environment_key = fetch_arg(args, "environment_key")

    command =
      Command.ExecuteScheduledExecution.new(scheduled_execution_id,
        actor: execution_actor(context),
        reason: "scheduled execution due",
        metadata: %{
          request_id: correlation_id,
          source: "scheduled_execution_worker",
          environment_key: environment_key,
          governed_action: governed_action
        }
      )

    configured_store().execute_scheduled_execution(command)
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
end

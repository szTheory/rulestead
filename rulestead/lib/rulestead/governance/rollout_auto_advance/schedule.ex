defmodule Rulestead.Governance.RolloutAutoAdvance.Schedule do
  @moduledoc false

  alias Rulestead.Store.Command

  @scheduler_actor %{"id" => "system:scheduler", "type" => "system", "display" => "Scheduler"}

  @spec scheduler_actor() :: map()
  def scheduler_actor, do: @scheduler_actor

  @spec schedule_metadata() :: map()
  def schedule_metadata do
    %{
      "source" => "guardrail_automation",
      "automation_phase" => "evaluate_and_advance"
    }
  end

  @spec schedulable?(Command.AdvanceRollout.t(), map()) :: boolean()
  def schedulable?(%Command.AdvanceRollout{} = command, policy) do
    policy_enabled?(policy) and policy_complete?(policy) and
      match?(%DateTime{}, command.monitoring_window_ends_at)
  end

  @spec idempotency_key(Command.AdvanceRollout.t()) :: String.t()
  def idempotency_key(%Command.AdvanceRollout{} = command) do
    "scheduled_execution:auto_advance:#{command.flag_key}:#{command.environment_key}:#{command.rule_key}:#{command.stage}:#{DateTime.to_iso8601(command.monitoring_window_ends_at)}"
  end

  @spec command_snapshot(Command.AdvanceRollout.t(), map()) :: map()
  def command_snapshot(%Command.AdvanceRollout{} = command, policy) do
    %{
      "rollout" => %{
        "rule_key" => command.rule_key,
        "stage" => command.stage,
        "percentage" => command.percentage,
        "monitoring_window_started_at" => command.monitoring_window_started_at,
        "monitoring_window_ends_at" => command.monitoring_window_ends_at
      },
      "auto_advance" => %{
        "policy_next_stage" => Map.get(policy, :next_stage) || Map.get(policy, "next_stage"),
        "policy_next_percentage" =>
          Map.get(policy, :next_percentage) || Map.get(policy, "next_percentage"),
        "observation_window_seconds" =>
          Map.get(policy, :observation_window_seconds) ||
            Map.get(policy, "observation_window_seconds")
      },
      "signal_facts" => []
    }
  end

  @spec schedule_command(Command.AdvanceRollout.t(), map()) :: Command.ScheduleGovernedAction.t()
  def schedule_command(%Command.AdvanceRollout{} = command, policy) do
    Command.ScheduleGovernedAction.new(
      %{
        action: :advance_rollout,
        environment_key: command.environment_key,
        resource_type: "flag",
        resource_key: command.flag_key,
        command: command_snapshot(command, policy),
        scheduled_for: command.monitoring_window_ends_at,
        execution_mode: :policy_bypass,
        idempotency_key: idempotency_key(command)
      },
      actor: scheduler_actor(),
      reason: "auto_advance observation window close",
      metadata: schedule_metadata()
    )
  end

  defp policy_enabled?(policy) do
    Map.get(policy, :enabled, Map.get(policy, "enabled")) == true
  end

  defp policy_complete?(policy) do
    observation_window_seconds =
      Map.get(policy, :observation_window_seconds) ||
        Map.get(policy, "observation_window_seconds")

    next_stage = Map.get(policy, :next_stage) || Map.get(policy, "next_stage")
    next_percentage = Map.get(policy, :next_percentage) || Map.get(policy, "next_percentage")

    not blank?(observation_window_seconds) and not blank?(next_stage) and
      not blank?(next_percentage)
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false
end

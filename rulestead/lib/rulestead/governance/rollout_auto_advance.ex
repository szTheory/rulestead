defmodule Rulestead.Governance.RolloutAutoAdvance do
  @moduledoc false

  alias Rulestead.Governance.RolloutAutoAdvance.Schedule
  alias Rulestead.Guardrails.AutoAdvance.Eligibility
  alias Rulestead.Guardrails.SignalFact
  alias Rulestead.Store.Command
  alias Rulestead.StoreError

  @spec automation_tick?(map()) :: boolean()
  def automation_tick?(metadata) when is_map(metadata) do
    source = Map.get(metadata, "source") || Map.get(metadata, :source)

    source == "guardrail_automation" or source == :guardrail_automation
  end

  def automation_tick?(_metadata), do: false

  @spec execute_scheduled_tick(module(), map(), Command.ExecuteScheduledExecution.t()) ::
          {:ok, map() | Command.AdvanceRollout.t()}
          | {:error, Rulestead.Error.t() | String.t()}
  def execute_scheduled_tick(store, scheduled_execution, execute_command) do
    with {:ok, snapshot_rollout} <- snapshot_rollout(scheduled_execution),
         :ok <- validate_snapshot_freshness(store, scheduled_execution, snapshot_rollout) do
      case fetch_enabled_policy(store, scheduled_execution, snapshot_rollout) do
        {:blocked, eligibility} ->
          {:ok, blocked_result(eligibility)}

        {:ok, policy} ->
          execute_with_policy(
            store,
            scheduled_execution,
            execute_command,
            snapshot_rollout,
            policy
          )
      end
    end
  end

  defp execute_with_policy(
         store,
         scheduled_execution,
         execute_command,
         snapshot_rollout,
         policy
       ) do
    with {:ok, signal_facts} <-
           resolve_signal_facts(store, scheduled_execution, snapshot_rollout),
         {:ok, eligibility} <-
           evaluate_rollout_auto_advance(
             store,
             scheduled_execution,
             snapshot_rollout,
             signal_facts
           ) do
      case eligibility.status do
        :blocked ->
          {:ok, blocked_result(eligibility)}

        :eligible ->
          build_advance_command(
            store,
            scheduled_execution,
            execute_command,
            snapshot_rollout,
            policy,
            eligibility,
            signal_facts
          )
      end
    end
  end

  defp snapshot_rollout(%{command_snapshot: command_snapshot}) when is_map(command_snapshot) do
    rollout = command_snapshot["rollout"] || command_snapshot[:rollout]

    case rollout do
      %{} = rollout when map_size(rollout) > 0 -> {:ok, rollout}
      _ -> {:error, StoreError.invalid_command("rollout_stage_conflict")}
    end
  end

  defp snapshot_rollout(_scheduled_execution),
    do: {:error, StoreError.invalid_command("rollout_stage_conflict")}

  defp validate_snapshot_freshness(store, scheduled_execution, snapshot_rollout) do
    fetch_command =
      Command.FetchGuardrailStatus.new(
        scheduled_execution.resource_key,
        scheduled_execution.environment_key,
        rule_key: snapshot_rollout["rule_key"] || snapshot_rollout[:rule_key],
        stage: snapshot_rollout["stage"] || snapshot_rollout[:stage]
      )

    case store.fetch_guardrail_status(fetch_command) do
      {:ok, status} ->
        decision = Map.get(status, :decision) || Map.get(status, "decision")
        compare_snapshot_to_live(snapshot_rollout, decision)

      {:error, _error} ->
        {:error, StoreError.invalid_command("auto_advance_superseded")}
    end
  end

  defp compare_snapshot_to_live(snapshot_rollout, decision) do
    live_stage = decision_field(decision, :stage)
    live_percentage = decision_field(decision, :effective_percentage)
    live_window_ends = decision_field(decision, :monitoring_window_ends_at)

    snapshot_stage =
      snapshot_rollout["stage"] || snapshot_rollout[:stage]
      |> to_string()

    snapshot_percentage = snapshot_rollout["percentage"] || snapshot_rollout[:percentage]

    snapshot_window_ends =
      parse_datetime(
        snapshot_rollout["monitoring_window_ends_at"] ||
          snapshot_rollout[:monitoring_window_ends_at]
      )

    cond do
      to_string(live_stage || "") != snapshot_stage ->
        {:error, StoreError.invalid_command("auto_advance_superseded")}

      live_percentage != snapshot_percentage ->
        {:error, StoreError.invalid_command("rollout_stage_conflict")}

      not datetimes_equal?(live_window_ends, snapshot_window_ends) ->
        {:error, StoreError.invalid_command("auto_advance_superseded")}

      true ->
        :ok
    end
  end

  defp fetch_enabled_policy(store, scheduled_execution, snapshot_rollout) do
    rule_key = snapshot_rollout["rule_key"] || snapshot_rollout[:rule_key]

    fetch_command =
      Command.FetchRolloutAutoAdvancePolicy.new(
        scheduled_execution.resource_key,
        scheduled_execution.environment_key,
        rule_key
      )

    case store.fetch_rollout_auto_advance_policy(fetch_command) do
      {:ok, %{policy: policy}} ->
        if policy_enabled_complete?(policy) do
          {:ok, policy}
        else
          {:blocked, blocked_eligibility_from_policy(policy)}
        end

      {:error, _error} ->
        {:blocked, blocked_eligibility(["auto_advance_disabled"])}
    end
  end

  defp resolve_signal_facts(store, scheduled_execution, snapshot_rollout) do
    with {:ok, flag_payload} <-
           store.fetch_flag(
             Command.FetchFlag.new(
               scheduled_execution.resource_key,
               scheduled_execution.environment_key
             )
           ) do
      rule_key = snapshot_rollout["rule_key"] || snapshot_rollout[:rule_key]

      guardrails = rollout_guardrails(flag_payload, rule_key)

      facts =
        Enum.map(guardrails, fn guardrail ->
          guardrail
          |> Map.put(:environment_key, scheduled_execution.environment_key)
          |> Rulestead.Guardrails.fetch_signal()
          |> SignalFact.metadata()
        end)

      {:ok, facts}
    end
  end

  defp evaluate_rollout_auto_advance(store, scheduled_execution, snapshot_rollout, signal_facts) do
    rule_key = snapshot_rollout["rule_key"] || snapshot_rollout[:rule_key]

    evaluated_at =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    monitoring_window_ends_at =
      parse_datetime(
        snapshot_rollout["monitoring_window_ends_at"] ||
          snapshot_rollout[:monitoring_window_ends_at]
      )

    evaluate_command =
      Command.EvaluateRolloutAutoAdvance.new(
        scheduled_execution.resource_key,
        scheduled_execution.environment_key,
        rule_key,
        %{
          monitoring_window_ends_at: monitoring_window_ends_at,
          evaluated_at: evaluated_at,
          signal_facts: signal_facts
        }
      )

    case store.evaluate_rollout_auto_advance(evaluate_command) do
      {:ok, %{eligibility: eligibility}} -> {:ok, eligibility}
      {:ok, %Eligibility{} = eligibility} -> {:ok, eligibility}
      other -> other
    end
  end

  defp build_advance_command(
         store,
         scheduled_execution,
         execute_command,
         snapshot_rollout,
         policy,
         eligibility,
         signal_facts
       ) do
    rule_key = snapshot_rollout["rule_key"] || snapshot_rollout[:rule_key]
    next_stage = policy_field(policy, :next_stage)
    next_percentage = policy_field(policy, :next_percentage)
    observation_window_seconds = policy_field(policy, :observation_window_seconds)

    evaluated_at =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    with :ok <- validate_next_stage_in_ruleset(store, scheduled_execution, rule_key, next_stage),
         %DateTime{} = window_ends_at <-
           DateTime.add(evaluated_at, observation_window_seconds, :second) do
      advance_command =
        Command.AdvanceRollout.new(
          scheduled_execution.resource_key,
          scheduled_execution.environment_key,
          %{
            rule_key: rule_key,
            stage: next_stage,
            percentage: next_percentage,
            monitoring_window_started_at: evaluated_at,
            monitoring_window_ends_at: window_ends_at,
            signal_facts: signal_facts
          },
          actor: execute_command.actor || Schedule.scheduler_actor(),
          reason: execute_command.reason || "auto-advance observation window close",
          metadata: %{
            "source" => "guardrail_automation",
            "scheduled_execution_id" => scheduled_execution.id,
            "eligibility" => eligibility_snapshot(eligibility),
            "request_id" =>
              execute_command.metadata["request_id"] || execute_command.metadata[:request_id]
          }
        )

      {:ok, advance_command}
    else
      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, StoreError.invalid_command("auto_advance_ruleset_conflict")}
    end
  end

  defp validate_next_stage_in_ruleset(store, scheduled_execution, rule_key, next_stage) do
    with {:ok, flag_payload} <-
           store.fetch_flag(
             Command.FetchFlag.new(
               scheduled_execution.resource_key,
               scheduled_execution.environment_key
             )
           ),
         %{} = _rollout_rule <- find_rollout_rule(flag_payload, rule_key),
         false <- blank?(next_stage) do
      :ok
    else
      nil -> {:error, StoreError.invalid_command("auto_advance_ruleset_conflict")}
      true -> {:error, StoreError.invalid_command("auto_advance_ruleset_conflict")}
      {:error, error} -> {:error, error}
    end
  end

  defp blocked_result(%Eligibility{} = eligibility) do
    %{
      outcome: :blocked,
      eligibility: eligibility,
      reasons: eligibility.reasons
    }
  end

  defp blocked_eligibility(reasons) do
    %Eligibility{
      status: :blocked,
      reasons: reasons,
      policy_snapshot: nil,
      decision_summary: nil,
      monitoring_window_closed?: nil
    }
  end

  defp blocked_eligibility_from_policy(policy) do
    reasons =
      cond do
        not policy_enabled?(policy) ->
          ["auto_advance_disabled"]

        not policy_complete?(policy) ->
          ["auto_advance_policy_incomplete"]

        true ->
          ["auto_advance_disabled"]
      end

    blocked_eligibility(reasons)
  end

  defp eligibility_snapshot(%Eligibility{} = eligibility) do
    %{
      status: eligibility.status,
      reasons: eligibility.reasons,
      policy_snapshot: eligibility.policy_snapshot,
      decision_summary: eligibility.decision_summary,
      monitoring_window_closed?: eligibility.monitoring_window_closed?
    }
  end

  defp rollout_guardrails(flag_payload, rule_key) do
    case find_rollout_rule(flag_payload, rule_key) do
      %{} = rule ->
        rollout = Map.get(rule, :rollout) || Map.get(rule, "rollout") || %{}
        guardrails = Map.get(rollout, :guardrails) || Map.get(rollout, "guardrails") || []
        Enum.filter(guardrails, &guardrail_configured?/1)

      _ ->
        []
    end
  end

  defp find_rollout_rule(flag_payload, rule_key) do
    active_ruleset = Map.get(flag_payload, :active_ruleset) || Map.get(flag_payload, "active_ruleset")
    rules = Map.get(active_ruleset || %{}, :rules) || Map.get(active_ruleset || %{}, "rules") || []
    rule_key = to_string(rule_key || "")

    Enum.find(rules, fn rule ->
      key = Map.get(rule, :key) || Map.get(rule, "key")
      rollout = Map.get(rule, :rollout) || Map.get(rule, "rollout")
      to_string(key || "") == rule_key and not is_nil(rollout)
    end)
  end

  defp guardrail_configured?(guardrail) do
    signal_key = Map.get(guardrail, :signal_key) || Map.get(guardrail, "signal_key")
    not blank?(signal_key)
  end

  defp policy_enabled_complete?(policy) do
    policy_enabled?(policy) and policy_complete?(policy)
  end

  defp policy_enabled?(policy) do
    policy_field(policy, :enabled) == true
  end

  defp policy_complete?(policy) do
    observation_window_seconds = policy_field(policy, :observation_window_seconds)
    next_stage = policy_field(policy, :next_stage)
    next_percentage = policy_field(policy, :next_percentage)

    not blank?(observation_window_seconds) and not blank?(next_stage) and
      not blank?(next_percentage)
  end

  defp policy_field(policy, key) do
    Map.get(policy, key) || Map.get(policy, Atom.to_string(key))
  end

  defp decision_field(decision, key) when is_map(decision) do
    Map.get(decision, key) || Map.get(decision, Atom.to_string(key))
  end

  defp decision_field(_decision, _key), do: nil

  defp datetimes_equal?(left, right) do
    case {parse_datetime(left), parse_datetime(right)} do
      {%DateTime{} = a, %DateTime{} = b} ->
        DateTime.compare(truncate_second(a), truncate_second(b)) == :eq

      _ ->
        false
    end
  end

  defp parse_datetime(%DateTime{} = value), do: truncate_second(value)

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> truncate_second(datetime)
      _ -> nil
    end
  end

  defp parse_datetime(_value), do: nil

  defp truncate_second(%DateTime{} = value), do: DateTime.truncate(value, :second)

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false
end

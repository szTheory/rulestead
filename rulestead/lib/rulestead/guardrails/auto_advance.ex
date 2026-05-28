defmodule Rulestead.Guardrails.AutoAdvance do
  @moduledoc false

  alias Rulestead.Guardrails.AutoAdvance.Eligibility
  alias Rulestead.Guardrails.Decision

  @policy_fields [
    :enabled,
    :observation_window_seconds,
    :next_stage,
    :next_percentage,
    :flag_key,
    :environment_key,
    :rule_key
  ]

  @spec evaluate_eligibility(map(), keyword() | map()) :: {:ok, Eligibility.t()}
  def evaluate_eligibility(policy, opts \\ []) when is_map(policy) do
    opts = normalize_opts(opts)
    signal_facts = Keyword.get(opts, :signal_facts, [])
    monitoring_window_ends_at = Keyword.get(opts, :monitoring_window_ends_at)

    evaluated_at =
      Keyword.get(opts, :evaluated_at, DateTime.utc_now())
      |> DateTime.truncate(:second)

    policy_snapshot = policy_snapshot(policy)

    cond do
      not policy_enabled?(policy) ->
        blocked(policy_snapshot, nil, false, ["auto_advance_disabled"])

      not policy_complete?(policy) ->
        blocked(policy_snapshot, nil, false, ["auto_advance_policy_incomplete"])

      is_nil(monitoring_window_ends_at) ->
        blocked(policy_snapshot, nil, false, ["monitoring_window_unset"])

      true ->
        decision =
          Decision.evaluate(signal_facts,
            evaluated_at: evaluated_at,
            monitoring_window_ends_at: monitoring_window_ends_at
          )

        decision_summary = decision_summary(decision)
        window_closed? = decision.monitoring_window_closed?

        eligibility_from_decision(
          signal_facts,
          decision,
          policy_snapshot,
          decision_summary,
          window_closed?
        )
    end
  end

  defp eligibility_from_decision([], _decision, policy_snapshot, decision_summary, true) do
    blocked(policy_snapshot, decision_summary, true, ["monitoring_window_expired"])
  end

  defp eligibility_from_decision(
         _signal_facts,
         %{state: state, reason: reason},
         policy_snapshot,
         decision_summary,
         window_closed?
       )
       when state != :healthy do
    blocked(
      policy_snapshot,
      decision_summary,
      window_closed?,
      ["guardrail_#{state}:#{reason}"]
    )
  end

  defp eligibility_from_decision(
         _signal_facts,
         _decision,
         policy_snapshot,
         decision_summary,
         false
       ) do
    blocked(policy_snapshot, decision_summary, false, ["monitoring_window_active"])
  end

  defp eligibility_from_decision(
         _signal_facts,
         _decision,
         policy_snapshot,
         decision_summary,
         true
       ) do
    {:ok,
     %Eligibility{
       status: :eligible,
       reasons: [],
       policy_snapshot: policy_snapshot,
       decision_summary: decision_summary,
       monitoring_window_closed?: true
     }}
  end

  defp blocked(policy_snapshot, decision_summary, window_closed?, reasons) do
    {:ok,
     %Eligibility{
       status: :blocked,
       reasons: reasons,
       policy_snapshot: policy_snapshot,
       decision_summary: decision_summary,
       monitoring_window_closed?: window_closed?
     }}
  end

  defp policy_snapshot(policy) do
    Map.new(@policy_fields, fn field ->
      {field, fetch_policy_field(policy, field)}
    end)
  end

  defp decision_summary(%Decision{} = decision) do
    %{
      state: decision.state,
      reason: decision.reason,
      monitoring_window_closed?: decision.monitoring_window_closed?
    }
  end

  defp policy_enabled?(policy) do
    fetch_policy_field(policy, :enabled) == true
  end

  defp policy_complete?(policy) do
    observation_window_seconds = fetch_policy_field(policy, :observation_window_seconds)
    next_stage = fetch_policy_field(policy, :next_stage)
    next_percentage = fetch_policy_field(policy, :next_percentage)

    not blank?(observation_window_seconds) and not blank?(next_stage) and
      not blank?(next_percentage)
  end

  defp fetch_policy_field(policy, key) do
    Map.get(policy, key) || Map.get(policy, Atom.to_string(key))
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false

  defp normalize_opts(opts) when is_list(opts), do: opts
  defp normalize_opts(opts) when is_map(opts), do: Map.to_list(opts)
end

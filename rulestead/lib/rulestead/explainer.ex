defmodule Rulestead.Explainer do
  @moduledoc false

  @spec explain(map() | nil) :: String.t()
  def explain(%{outcome: :default, rule_traces: rule_traces}) do
    skipped =
      rule_traces
      |> Enum.map_join("; ", fn trace ->
        "#{trace.rule_key || "unnamed-rule"} skipped (#{trace.reason || "no match"})"
      end)

    if skipped == "" do
      "No rule matched. The evaluator returned the default value."
    else
      "No rule matched. The evaluator returned the default value after #{skipped}."
    end
  end

  def explain(%{matched_rule: matched_rule, rule_traces: rule_traces}) do
    rollout_bucket =
      rule_traces
      |> List.last()
      |> case do
        %{rollout: %{bucket: bucket}} -> bucket
        _ -> nil
      end

    audience_summary = audience_trace_summary(rule_traces)

    base =
      if is_integer(rollout_bucket) do
        "Matched rule #{matched_rule}. Bucket #{rollout_bucket} determined the rollout path."
      else
        "Matched rule #{matched_rule}."
      end

    case audience_summary do
      "" -> base
      summary -> base <> " " <> summary
    end
  end

  def explain(_trace), do: "No evaluation trace was available."

  defp audience_trace_summary(rule_traces) when is_list(rule_traces) do
    rule_traces
    |> Enum.flat_map(fn trace ->
      case Map.get(trace, :audience_trace) do
        %{audience_key: key, matched?: true, reason: :matched} ->
          ["Audience #{key} matched."]

        %{audience_key: key, matched?: false, reason: :missed} ->
          ["Audience #{key} missed."]

        %{audience_key: key, reason: :missing} ->
          ["Audience #{key} is missing from the snapshot."]

        %{audience_key: key, reason: :archived} ->
          ["Audience #{key} is archived."]

        _ ->
          []
      end
    end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp audience_trace_summary(_rule_traces), do: ""

  @spec runtime_explain(map() | nil, map()) :: String.t()
  def runtime_explain(trace, runtime_metadata) do
    base = explain(trace)
    environment_key = runtime_metadata[:environment_key] || "unknown"
    snapshot_version = runtime_metadata[:snapshot_version] || "unknown"
    source = runtime_metadata[:source] || :unknown
    cache_age_ms = runtime_metadata[:cache_age_ms] || 0

    base <>
      " Environment #{environment_key} used snapshot v#{snapshot_version} from source #{source} (cache age #{cache_age_ms}ms)."
  end
end

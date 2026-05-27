# credo:disable-for-this-file
defmodule Rulestead.Targeting.AudienceDependencies do
  @moduledoc false

  @segment_match "segment_match"
  @unavailable %{available?: false}

  @spec summarize(String.t() | atom() | nil, list()) :: [map()]
  def summarize(audience_key, authored_flags_or_payloads) when is_list(authored_flags_or_payloads) do
    target_audience_key = normalize_string(audience_key)

    authored_flags_or_payloads
    |> Enum.flat_map(&references_for_payload(target_audience_key, &1))
    |> Enum.sort_by(&sort_key/1)
  end

  def summarize(_audience_key, _authored_flags_or_payloads), do: []

  @spec reference_keys(list()) :: [String.t()]
  def reference_keys(references) when is_list(references) do
    references
    |> Enum.map(&(fetch(&1, :reference_key) |> normalize_string()))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def reference_keys(_references), do: []

  defp references_for_payload(nil, _payload), do: []

  defp references_for_payload(target_audience_key, payload) when is_map(payload) do
    flag = fetch(payload, :flag) || %{}
    ruleset = fetch(payload, :active_ruleset) || %{}
    flag_key = normalize_string(fetch(flag, :key) || fetch(payload, :flag_key))
    rules = fetch(ruleset, :rules) || []

    rules
    |> Enum.filter(&segment_match_for_audience?(&1, target_audience_key))
    |> Enum.map(fn rule ->
      build_reference(payload, flag_key, ruleset, rule)
    end)
  end

  defp references_for_payload(_target_audience_key, _payload), do: []

  defp segment_match_for_audience?(rule, target_audience_key) when is_map(rule) do
    rule_strategy(rule) == @segment_match and
      normalize_string(fetch(rule, :audience_key)) == target_audience_key
  end

  defp segment_match_for_audience?(_rule, _target_audience_key), do: false

  defp build_reference(payload, flag_key, ruleset, rule) do
    ruleset_version = fetch(ruleset, :version)
    rule_key = normalize_string(fetch(rule, :key))

    %{
      reference_key: reference_key(flag_key, ruleset_version, rule_key),
      resource_type: "flag",
      flag_key: flag_key,
      ruleset_version: ruleset_version,
      ruleset_status: normalize_string(fetch(ruleset, :status)),
      rule_key: rule_key,
      rule_strategy: @segment_match,
      rollout_context: context_or_unavailable(fetch(rule, :rollout)),
      lifecycle_context: context_or_unavailable(fetch(rule, :lifecycle) || fetch(payload, :lifecycle)),
      environment_key: normalize_string(fetch(payload, :environment_key)),
      tenant_key: normalize_string(fetch(payload, :tenant_key))
    }
  end

  defp reference_key(flag_key, ruleset_version, rule_key) do
    "flag:#{flag_key}:ruleset:#{ruleset_version}:rule:#{rule_key}"
  end

  defp sort_key(reference) do
    {
      reference.environment_key || "",
      reference.tenant_key || "",
      reference.flag_key || "",
      reference.ruleset_version || 0,
      reference.rule_key || ""
    }
  end

  defp rule_strategy(rule) do
    rule
    |> fetch(:strategy)
    |> normalize_string()
  end

  defp context_or_unavailable(nil), do: @unavailable

  defp context_or_unavailable(context) when is_map(context) do
    if map_size(context) == 0 do
      @unavailable
    else
      normalize_context(context)
    end
  end

  defp context_or_unavailable(_context), do: @unavailable

  defp normalize_context(context) do
    Map.new(context, fn {key, value} -> {normalize_context_key(key), normalize_context_value(value)} end)
  end

  defp normalize_context_key(key) when is_atom(key), do: key
  defp normalize_context_key(key), do: to_string(key)

  defp normalize_context_value(value) when is_map(value), do: normalize_context(value)
  defp normalize_context_value(value) when is_list(value), do: Enum.map(value, &normalize_context_value/1)
  defp normalize_context_value(value), do: value

  defp fetch(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
  defp fetch(_map, _key), do: nil

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp normalize_string(value), do: value
end

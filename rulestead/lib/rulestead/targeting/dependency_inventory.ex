defmodule Rulestead.Targeting.DependencyInventory do
  @moduledoc false

  @required_fields [
    :environment_key,
    :tenant_key,
    :flag_key,
    :ruleset_version,
    :rule_key,
    :audience_key
  ]

  @unavailable_context %{available?: false}

  @type entry :: %{
          environment_key: String.t() | nil,
          tenant_key: String.t() | nil,
          audience_key: String.t() | nil,
          flag_key: String.t() | nil,
          ruleset_version: pos_integer() | nil,
          rule_key: String.t() | nil,
          ruleset_status: String.t() | nil,
          rollout_context: map(),
          lifecycle_context: map(),
          visibility: map(),
          reference_count: non_neg_integer(),
          hidden_reference_count: non_neg_integer(),
          malformed?: boolean(),
          malformed_reasons: [map()]
        }

  @spec normalize_entry(map()) :: entry()
  def normalize_entry(entry) when is_map(entry) do
    normalized = %{
      environment_key: normalize_string(fetch(entry, :environment_key)),
      tenant_key: normalize_string(fetch(entry, :tenant_key)),
      audience_key: normalize_string(fetch(entry, :audience_key)),
      flag_key: normalize_string(fetch(entry, :flag_key)),
      ruleset_version: normalize_ruleset_version(fetch(entry, :ruleset_version)),
      rule_key: normalize_string(fetch(entry, :rule_key)),
      ruleset_status: normalize_string(fetch(entry, :ruleset_status)),
      rollout_context: normalize_context(fetch(entry, :rollout_context)),
      lifecycle_context: normalize_context(fetch(entry, :lifecycle_context)),
      visibility: normalize_visibility(fetch(entry, :visibility)),
      reference_count: normalize_count(fetch(entry, :reference_count), 1),
      hidden_reference_count: normalize_count(fetch(entry, :hidden_reference_count), 0)
    }

    case missing_required_fields(normalized) do
      [] ->
        normalized
        |> Map.put(:malformed?, false)
        |> Map.put(:malformed_reasons, [])

      missing ->
        normalized
        |> Map.put(:malformed?, true)
        |> Map.put(
          :malformed_reasons,
          [
            %{
              code: "missing_required_scope_or_identity",
              fields: Enum.map(missing, &to_string/1)
            }
          ]
        )
    end
  end

  def normalize_entry(_value), do: normalize_entry(%{})

  @spec sort_entries([map()]) :: [entry()]
  def sort_entries(entries) when is_list(entries) do
    entries
    |> Enum.map(&normalize_entry/1)
    |> Enum.sort_by(fn entry ->
      {sort_tuple(entry), malformed_rank(entry)}
    end)
  end

  def sort_entries(_entries), do: []

  @spec redacted_result([map()], keyword()) :: map()
  def redacted_result(entries, opts \\ [])

  def redacted_result(entries, opts) when is_list(entries) do
    include_redacted_placeholders? = Keyword.get(opts, :include_redacted_placeholders?, false)

    {visible_entries, hidden_count, redacted_entries} =
      entries
      |> sort_entries()
      |> Enum.reduce({[], 0, []}, fn entry, {visible, hidden, redacted} ->
        if visible?(entry, opts) do
          {[entry | visible], hidden, redacted}
        else
          next_redacted =
            if include_redacted_placeholders? do
              [redacted_placeholder(entry) | redacted]
            else
              redacted
            end

          {visible, hidden + entry.reference_count, next_redacted}
        end
      end)

    %{
      entries: Enum.reverse(visible_entries),
      reference_count: Enum.count(entries),
      hidden_reference_count: hidden_count,
      redacted: hidden_count > 0,
      redacted_entries: Enum.reverse(redacted_entries)
    }
  end

  def redacted_result(_entries, _opts),
    do: %{entries: [], reference_count: 0, hidden_reference_count: 0, redacted: false, redacted_entries: []}

  defp sort_tuple(entry) do
    # Canonical semantic order: environment_key, tenant_key, flag_key, ruleset_version, rule_key, audience_key
    {
      entry.environment_key || "",
      entry.tenant_key || "",
      entry.flag_key || "",
      entry.ruleset_version || 0,
      entry.rule_key || "",
      entry.audience_key || ""
    }
  end

  defp malformed_rank(%{malformed?: true}), do: 1
  defp malformed_rank(_entry), do: 0

  defp missing_required_fields(entry) do
    Enum.filter(@required_fields, fn field ->
      missing_required_value?(Map.get(entry, field))
    end)
  end

  defp missing_required_value?(nil), do: true
  defp missing_required_value?(value) when is_binary(value), do: String.trim(value) == ""
  defp missing_required_value?(_value), do: false

  defp normalize_context(context) when is_map(context) do
    if map_size(context) == 0 do
      @unavailable_context
    else
      Map.new(context, fn {key, value} -> {normalize_context_key(key), normalize_context_value(value)} end)
    end
  end

  defp normalize_context(_context), do: @unavailable_context

  defp normalize_context_key(key) when is_atom(key), do: key
  defp normalize_context_key(key), do: to_string(key)

  defp normalize_context_value(value) when is_map(value), do: normalize_context(value)
  defp normalize_context_value(value) when is_list(value), do: Enum.map(value, &normalize_context_value/1)
  defp normalize_context_value(value), do: value

  defp normalize_visibility(nil), do: %{status: "visible"}

  defp normalize_visibility(value) when is_map(value) do
    %{
      status:
        value
        |> fetch(:status)
        |> normalize_string()
        |> Kernel.||("visible"),
      reason: value |> fetch(:reason) |> normalize_string()
    }
  end

  defp normalize_visibility(_value), do: %{status: "visible"}

  defp normalize_ruleset_version(value) when is_integer(value) and value > 0, do: value

  defp normalize_ruleset_version(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      normalized ->
        case Integer.parse(normalized) do
          {version, ""} when version > 0 -> version
          _other -> nil
        end
    end
  end

  defp normalize_ruleset_version(_value), do: nil

  defp normalize_count(value, _default) when is_integer(value) and value >= 0, do: value

  defp normalize_count(value, default) when is_binary(value) do
    case Integer.parse(String.trim(value)) do
      {parsed, ""} when parsed >= 0 -> parsed
      _other -> default
    end
  end

  defp normalize_count(_value, default), do: default

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(value), do: to_string(value) |> normalize_string()

  defp visible?(entry, opts) do
    visibility_resolver = Keyword.get(opts, :visibility_resolver)

    cond do
      is_function(visibility_resolver, 1) ->
        visibility_resolver.(entry)

      true ->
        visible_audience_keys = Keyword.get(opts, :visible_audience_keys)

        case visible_audience_keys do
          nil ->
            true

          keys when is_list(keys) ->
            entry.audience_key in Enum.map(keys, &normalize_string/1)

          _other ->
            true
        end
    end
  end

  defp redacted_placeholder(entry) do
    %{
      environment_key: entry.environment_key,
      tenant_key: entry.tenant_key,
      audience_key: "[REDACTED]",
      flag_key: entry.flag_key,
      ruleset_version: entry.ruleset_version,
      rule_key: entry.rule_key,
      ruleset_status: entry.ruleset_status,
      rollout_context: @unavailable_context,
      lifecycle_context: @unavailable_context,
      visibility: %{status: "redacted", reason: "policy_denied"},
      reference_count: entry.reference_count,
      hidden_reference_count: entry.reference_count,
      malformed?: entry.malformed?,
      malformed_reasons: entry.malformed_reasons
    }
  end

  defp fetch(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
  defp fetch(_map, _key), do: nil
end

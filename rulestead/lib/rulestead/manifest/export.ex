# credo:disable-for-this-file
defmodule Rulestead.Manifest.Export do
  @moduledoc false

  alias Rulestead.Manifest

  @default_limit 10_000

  @spec export(String.t() | atom(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def export(environment_key, opts \\ []) do
    environment_key = Manifest.normalize_string(environment_key)
    requested_flag_keys = Manifest.normalize_string_list(Keyword.get(opts, :flag_keys, []))

    tenant_key = Manifest.normalize_string(Keyword.get(opts, :tenant_key))

    with {:ok, environment} <- fetch_environment(environment_key),
         {:ok, page} <-
           Rulestead.list_flags(
             environment_key: environment.key,
             include_archived?: true,
             limit: Keyword.get(opts, :limit, @default_limit),
             sort: :flag_key
           ),
         :ok <- validate_requested_flag_keys(page.entries, requested_flag_keys),
         {:ok, flags} <-
           export_flags(
             page.entries,
             environment.key,
             requested_flag_keys,
             tenant_key || "global"
           ) do
      {:ok,
       %{
         "schema_version" => Manifest.schema_version(),
         "kind" => Manifest.kind(),
         "environment_key" => environment.key,
         "flags" => flags
       }
       |> maybe_put("tenant_key", tenant_key)}
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp export_flags(entries, environment_key, requested_flag_keys, tenant_key) do
    entries
    |> Enum.map(& &1.flag.key)
    |> Enum.uniq()
    |> Enum.sort()
    |> maybe_filter_requested_flag_keys(requested_flag_keys)
    |> Enum.reduce_while({:ok, []}, fn flag_key, {:ok, acc} ->
      case Rulestead.fetch_flag(flag_key, environment_key) do
        {:ok, payload} ->
          case export_entry(payload, environment_key, tenant_key) do
            nil -> {:cont, {:ok, acc}}
            entry -> {:cont, {:ok, [entry | acc]}}
          end

        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, flags} -> {:ok, Enum.reverse(flags)}
      {:error, error} -> {:error, error}
    end
  end

  defp fetch_environment(nil) do
    {:error, Manifest.invalid("export requires an environment key")}
  end

  defp fetch_environment(environment_key) do
    with {:ok, environments} <- Rulestead.list_environments(limit: @default_limit) do
      case Enum.find(environments, &(&1.key == environment_key)) do
        nil ->
          {:error,
           Manifest.invalid("environment was not found",
             metadata: %{environment_key: environment_key}
           )}

        environment ->
          {:ok, environment}
      end
    end
  end

  defp validate_requested_flag_keys(_entries, []), do: :ok

  defp validate_requested_flag_keys(entries, requested_flag_keys) do
    available_flag_keys =
      entries
      |> Enum.map(& &1.flag.key)
      |> Enum.uniq()
      |> Enum.sort()
      |> MapSet.new()

    missing_flag_keys =
      requested_flag_keys
      |> Enum.reject(&MapSet.member?(available_flag_keys, &1))

    case missing_flag_keys do
      [] ->
        :ok

      _other ->
        environment_key =
          case List.first(entries) do
            nil -> nil
            entry -> entry.environment.key
          end

        {:error,
         Manifest.invalid("one or more requested flags were not found for the environment",
           metadata: %{
             missing_flag_keys: Enum.join(missing_flag_keys, ","),
             environment: environment_key
           }
         )}
    end
  end

  defp maybe_filter_requested_flag_keys(flag_keys, []), do: flag_keys
  defp maybe_filter_requested_flag_keys(_flag_keys, requested_flag_keys), do: requested_flag_keys

  defp export_entry(payload, environment_key, tenant_key) do
    active_ruleset =
      project_ruleset(
        payload[:active_ruleset] || payload["active_ruleset"],
        environment_key,
        tenant_key
      )

    if is_nil(active_ruleset) do
      nil
    else
      flag = payload[:flag] || payload["flag"] || %{}

      %{
        "flag_key" => Manifest.normalize_string(flag[:key] || flag["key"]),
        "flag" => project_flag(flag),
        "environment" =>
          project_environment(payload[:flag_environment] || payload["flag_environment"] || %{}),
        "active_ruleset" => active_ruleset
      }
    end
  end

  defp project_flag(flag) do
    ownership = Map.get(flag, :ownership) || Map.get(flag, "ownership") || %{}
    lifecycle = Map.get(flag, :lifecycle) || Map.get(flag, "lifecycle") || %{}

    %{}
    |> maybe_put("description", flag[:description] || flag["description"])
    |> maybe_put("flag_type", to_string(flag[:flag_type] || flag["flag_type"]))
    |> maybe_put("value_type", to_string(flag[:value_type] || flag["value_type"]))
    |> maybe_put(
      "default_value",
      Manifest.normalize_value(flag[:default_value] || flag["default_value"])
    )
    |> maybe_put(
      "owner",
      flag[:owner] || flag["owner"] || Map.get(ownership, :owner_display) ||
        Map.get(ownership, "owner_display") || Map.get(ownership, :owner_ref) ||
        Map.get(ownership, "owner_ref")
    )
    |> maybe_put(
      "expected_expiration",
      flag[:expected_expiration] || flag["expected_expiration"] || Map.get(lifecycle, :review_by) ||
        Map.get(lifecycle, "review_by")
    )
    |> maybe_put(
      "permanent",
      flag[:permanent] || flag["permanent"] ||
        ((Map.get(lifecycle, :mode) || Map.get(lifecycle, "mode")) == :permanent or
           (Map.get(lifecycle, :mode) || Map.get(lifecycle, "mode")) == "permanent")
    )
    |> maybe_put("tags", Manifest.normalize_string_list(flag[:tags] || flag["tags"] || []))
  end

  defp project_environment(flag_environment) do
    %{}
    |> maybe_put("status", to_string(flag_environment[:status] || flag_environment["status"]))
    |> maybe_put(
      "active_ruleset_version",
      flag_environment[:active_ruleset_version] || flag_environment["active_ruleset_version"]
    )
  end

  defp project_ruleset(nil, _environment_key, _tenant_key), do: nil

  defp project_ruleset(ruleset, environment_key, tenant_key) do
    %{}
    |> maybe_put("version", ruleset[:version] || ruleset["version"])
    |> maybe_put("salt", ruleset[:salt] || ruleset["salt"])
    |> maybe_put(
      "metadata",
      Manifest.normalize_map(ruleset[:metadata] || ruleset["metadata"] || %{})
    )
    |> maybe_put_normalized(
      "rules",
      ruleset
      |> Map.get(:rules, Map.get(ruleset, "rules", []))
      |> Enum.map(&project_rule(&1, environment_key, tenant_key))
    )
  end

  defp project_rule(rule, environment_key, tenant_key) do
    strategy = to_string(rule[:strategy] || rule["strategy"])
    metadata = rule[:metadata] || rule["metadata"] || %{}

    base_rule =
      %{}
      |> maybe_put("key", rule[:key] || rule["key"])
      |> maybe_put("name", rule[:name] || rule["name"])
      |> maybe_put("description", rule[:description] || rule["description"])
      |> maybe_put("strategy", strategy)
      |> maybe_put("value", Manifest.normalize_map(rule[:value] || rule["value"] || %{}))
      |> maybe_put("audience_key", rule[:audience_key] || rule["audience_key"])
      |> maybe_put(
        "conditions",
        rule
        |> Map.get(:conditions, Map.get(rule, "conditions", []))
        |> Enum.map(&project_condition/1)
      )
      |> maybe_put(
        "variants",
        rule
        |> Map.get(:variants, Map.get(rule, "variants", []))
        |> Enum.map(&project_variant/1)
      )
      |> maybe_put(
        "rollout",
        rule
        |> Map.get(:rollout, Map.get(rule, "rollout"))
        |> case do
          nil -> nil
          rollout -> Manifest.normalize_map(rollout)
        end
      )

    if strategy == "segment_match" do
      base_rule
      |> maybe_put("environment_key", environment_key)
      |> maybe_put("tenant_key", tenant_key)
      |> maybe_put(
        "audience_schema_version",
        rule[:audience_schema_version] || rule["audience_schema_version"] ||
          metadata[:audience_schema_version] || metadata["audience_schema_version"]
      )
      |> maybe_put(
        "audience_version_hash",
        rule[:audience_version_hash] || rule["audience_version_hash"] ||
          metadata[:audience_version_hash] || metadata["audience_version_hash"]
      )
    else
      base_rule
    end
  end

  defp project_condition(condition) do
    %{}
    |> maybe_put("attribute", condition[:attribute] || condition["attribute"])
    |> maybe_put("operator", to_string(condition[:operator] || condition["operator"]))
    |> maybe_put("value", Manifest.normalize_map(condition[:value] || condition["value"] || %{}))
  end

  defp project_variant(variant) do
    %{}
    |> maybe_put("key", variant[:key] || variant["key"])
    |> maybe_put_normalized("weight", variant[:weight] || variant["weight"])
    |> maybe_put_normalized(
      "value",
      Manifest.normalize_map(variant[:value] || variant["value"] || %{})
    )
  end

  defp maybe_put_normalized(map, _key, nil), do: map
  defp maybe_put_normalized(map, _key, []), do: map

  defp maybe_put_normalized(map, key, value),
    do: Map.put(map, key, Manifest.normalize_value(value))
end

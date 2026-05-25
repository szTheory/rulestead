defmodule Rulestead.Manifest.Load do
  @moduledoc false

  alias Rulestead.Manifest

  @spec load(binary() | map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def load(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, manifest} -> load(manifest)
      {:error, _reason} -> {:error, Manifest.invalid("manifest is not valid JSON")}
    end
  end

  def load(manifest) when is_map(manifest) do
    with :ok <- validate_kind(manifest),
         :ok <- validate_schema_version(manifest),
         {:ok, environment_key} <- fetch_required_string(manifest, "environment_key"),
         {:ok, flags} <- load_flags(Map.get(manifest, "flags", Map.get(manifest, :flags))) do
      {:ok,
       %{
         "schema_version" => Manifest.schema_version(),
         "kind" => Manifest.kind(),
         "environment_key" => environment_key,
         "flags" => flags
       }
       |> maybe_put(
         "tenant_key",
         Manifest.normalize_string(
           Map.get(manifest, "tenant_key", Map.get(manifest, :tenant_key))
         )
       )}
    end
  end

  def load(_content), do: {:error, Manifest.invalid("manifest content must be a JSON object")}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp validate_kind(manifest) do
    case Manifest.normalize_string(Map.get(manifest, "kind", Map.get(manifest, :kind))) do
      kind ->
        if kind == Manifest.kind() do
          :ok
        else
          {:error, Manifest.invalid("manifest kind is unsupported")}
        end
    end
  end

  defp validate_schema_version(manifest) do
    case Map.get(manifest, "schema_version", Map.get(manifest, :schema_version)) do
      version ->
        if version == Manifest.schema_version() do
          :ok
        else
          {:error, Manifest.invalid("manifest schema version is unsupported")}
        end
    end
  end

  defp load_flags(nil), do: {:ok, []}

  defp load_flags(flags) when is_list(flags) do
    flags
    |> Enum.map(&load_flag/1)
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, flag}, {:ok, acc} -> {:cont, {:ok, [flag | acc]}}
      {:error, error}, _acc -> {:halt, {:error, error}}
    end)
    |> case do
      {:ok, loaded_flags} ->
        {:ok, Enum.sort_by(loaded_flags, & &1["flag_key"])}

      {:error, error} ->
        {:error, error}
    end
  end

  defp load_flags(_flags), do: {:error, Manifest.invalid("manifest flags must be a list")}

  defp load_flag(flag) when is_map(flag) do
    with {:ok, flag_key} <- fetch_required_string(flag, "flag_key"),
         {:ok, flag_payload} <- load_flag_payload(Map.get(flag, "flag", Map.get(flag, :flag))),
         {:ok, environment} <-
           load_environment(Map.get(flag, "environment", Map.get(flag, :environment))),
         {:ok, active_ruleset} <-
           load_ruleset(Map.get(flag, "active_ruleset", Map.get(flag, :active_ruleset))) do
      {:ok,
       %{
         "flag_key" => flag_key,
         "flag" => flag_payload,
         "environment" => environment,
         "active_ruleset" => active_ruleset
       }}
    end
  end

  defp load_flag(_flag), do: {:error, Manifest.invalid("manifest flag entries must be objects")}

  defp load_flag_payload(flag) when is_map(flag) do
    {:ok,
     %{}
     |> maybe_put("description", Map.get(flag, "description", Map.get(flag, :description)))
     |> maybe_put("flag_type", Map.get(flag, "flag_type", Map.get(flag, :flag_type)))
     |> maybe_put("value_type", Map.get(flag, "value_type", Map.get(flag, :value_type)))
     |> maybe_put("default_value", Map.get(flag, "default_value", Map.get(flag, :default_value)))
     |> maybe_put("owner", Map.get(flag, "owner", Map.get(flag, :owner)))
     |> maybe_put(
       "expected_expiration",
       Map.get(flag, "expected_expiration", Map.get(flag, :expected_expiration))
     )
     |> maybe_put("permanent", Map.get(flag, "permanent", Map.get(flag, :permanent)))
     |> maybe_put("tags", Map.get(flag, "tags", Map.get(flag, :tags, [])))}
  end

  defp load_flag_payload(_flag),
    do: {:error, Manifest.invalid("manifest flag payload must be an object")}

  defp load_environment(environment) when is_map(environment) do
    {:ok,
     %{}
     |> maybe_put("status", Map.get(environment, "status", Map.get(environment, :status)))
     |> maybe_put(
       "active_ruleset_version",
       Map.get(
         environment,
         "active_ruleset_version",
         Map.get(environment, :active_ruleset_version)
       )
     )}
  end

  defp load_environment(_environment),
    do: {:error, Manifest.invalid("manifest environment payload must be an object")}

  defp load_ruleset(ruleset) when is_map(ruleset) do
    rules =
      ruleset
      |> Map.get("rules", Map.get(ruleset, :rules, []))
      |> Enum.map(&load_rule/1)
      |> Enum.reduce_while({:ok, []}, fn
        {:ok, rule}, {:ok, acc} -> {:cont, {:ok, [rule | acc]}}
        {:error, error}, _acc -> {:halt, {:error, error}}
      end)

    case rules do
      {:ok, loaded_rules} ->
        {:ok,
         %{}
         |> maybe_put("version", Map.get(ruleset, "version", Map.get(ruleset, :version)))
         |> maybe_put("salt", Map.get(ruleset, "salt", Map.get(ruleset, :salt)))
         |> maybe_put("metadata", Map.get(ruleset, "metadata", Map.get(ruleset, :metadata, %{})))
         |> maybe_put("rules", Enum.reverse(loaded_rules))}

      {:error, error} ->
        {:error, error}
    end
  end

  defp load_ruleset(_ruleset),
    do: {:error, Manifest.invalid("manifest active_ruleset must be an object")}

  defp load_rule(rule) when is_map(rule) do
    {:ok,
     %{}
     |> maybe_put("key", Map.get(rule, "key", Map.get(rule, :key)))
     |> maybe_put("name", Map.get(rule, "name", Map.get(rule, :name)))
     |> maybe_put("description", Map.get(rule, "description", Map.get(rule, :description)))
     |> maybe_put("strategy", Map.get(rule, "strategy", Map.get(rule, :strategy)))
     |> maybe_put("value", Map.get(rule, "value", Map.get(rule, :value, %{})))
     |> maybe_put("audience_key", Map.get(rule, "audience_key", Map.get(rule, :audience_key)))
     |> maybe_put(
       "conditions",
       rule
       |> Map.get("conditions", Map.get(rule, :conditions, []))
       |> Enum.map(&load_condition/1)
       |> unwrap_loaded_list()
     )
     |> maybe_put(
       "variants",
       rule
       |> Map.get("variants", Map.get(rule, :variants, []))
       |> Enum.map(&load_variant/1)
       |> unwrap_loaded_list()
     )
     |> maybe_put("rollout", Map.get(rule, "rollout", Map.get(rule, :rollout)))}
  end

  defp load_rule(_rule), do: {:error, Manifest.invalid("manifest rules must be objects")}

  defp load_condition(condition) when is_map(condition) do
    {:ok,
     %{}
     |> maybe_put("attribute", Map.get(condition, "attribute", Map.get(condition, :attribute)))
     |> maybe_put("operator", Map.get(condition, "operator", Map.get(condition, :operator)))
     |> maybe_put("value", Map.get(condition, "value", Map.get(condition, :value, %{})))}
  end

  defp load_condition(_condition),
    do: {:error, Manifest.invalid("manifest conditions must be objects")}

  defp load_variant(variant) when is_map(variant) do
    {:ok,
     %{}
     |> maybe_put("key", Map.get(variant, "key", Map.get(variant, :key)))
     |> maybe_put("weight", Map.get(variant, "weight", Map.get(variant, :weight)))
     |> maybe_put("value", Map.get(variant, "value", Map.get(variant, :value, %{})))}
  end

  defp load_variant(_variant), do: {:error, Manifest.invalid("manifest variants must be objects")}

  defp fetch_required_string(map, key) do
    case Manifest.normalize_string(Map.get(map, key, Map.get(map, String.to_atom(key), nil))) do
      nil -> {:error, Manifest.invalid("manifest is missing required field #{key}")}
      value -> {:ok, value}
    end
  end

  defp unwrap_loaded_list(items) do
    items
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, item}, {:ok, acc} -> {:cont, {:ok, [item | acc]}}
      {:error, error}, _acc -> {:halt, {:error, error}}
    end)
    |> case do
      {:ok, loaded_items} -> Enum.reverse(loaded_items)
      {:error, error} -> raise error
    end
  end
end

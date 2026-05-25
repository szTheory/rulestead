defmodule Rulestead.Manifest.Plan do
  @moduledoc false

  alias Rulestead.Manifest

  @schema_version 1
  @kind "rulestead_apply_plan"
  @modes ~w(import promote)
  @statuses ~w(no_changes changes governance_required)

  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @spec kind() :: String.t()
  def kind, do: @kind

  @spec load(binary() | map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def load(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, plan} -> load(plan)
      {:error, _reason} -> {:error, Manifest.invalid("apply plan is not valid JSON")}
    end
  end

  def load(plan) when is_map(plan) do
    with :ok <- validate_kind(plan),
         :ok <- validate_schema_version(plan),
         {:ok, mode} <- fetch_required_string(plan, "mode"),
         :ok <- validate_mode(mode),
         {:ok, target_environment_key} <- fetch_required_string(plan, "target_environment_key"),
         {:ok, plan_token} <- fetch_required_string(plan, "plan_token"),
         {:ok, target_fingerprint} <- fetch_required_string(plan, "target_fingerprint"),
         {:ok, dependency_closure_keys} <- load_string_list(plan, "dependency_closure_keys"),
         {:ok, proposed_target_bundle} <- load_bundle(plan),
         {:ok, status} <- load_status(plan) do
      normalized =
        %{
          "schema_version" => @schema_version,
          "kind" => @kind,
          "mode" => mode,
          "status" => status,
          "target_environment_key" => target_environment_key,
          "plan_token" => plan_token,
          "target_fingerprint" => target_fingerprint,
          "dependency_closure_keys" => dependency_closure_keys,
          "proposed_target_bundle" => proposed_target_bundle
        }
        |> maybe_put("tenant_key", fetch_optional_string(plan, "tenant_key"))
        |> maybe_put(
          "source_environment_key",
          fetch_optional_string(plan, "source_environment_key")
        )
        |> maybe_put("compare_token", fetch_optional_string(plan, "compare_token"))
        |> maybe_put("source_fingerprint", fetch_optional_string(plan, "source_fingerprint"))
        |> maybe_put(
          "flag_keys",
          Manifest.normalize_string_list(
            Map.get(plan, "flag_keys", Map.get(plan, :flag_keys, []))
          )
        )

      {:ok, normalized}
    end
  end

  def load(_content), do: {:error, Manifest.invalid("apply plan content must be a JSON object")}

  @spec serialize(map()) :: {:ok, binary()} | {:error, Rulestead.Error.t()}
  def serialize(plan) when is_map(plan) do
    with {:ok, normalized} <- load(plan) do
      {:ok, encode_json(normalized)}
    end
  end

  def serialize(_plan), do: {:error, Manifest.invalid("apply plan content must be a JSON object")}

  @spec build_import(map()) :: map()
  def build_import(attrs) do
    bundle =
      attrs
      |> Map.fetch!(:proposed_target_bundle)
      |> normalize_bundle()

    dependency_closure_keys =
      attrs
      |> Map.get(:dependency_closure_keys, Map.get(attrs, "dependency_closure_keys", []))
      |> Manifest.normalize_string_list()

    target_environment_key =
      attrs
      |> Map.get(:target_environment_key, Map.get(attrs, "target_environment_key"))
      |> Manifest.normalize_string()

    source_environment_key =
      attrs
      |> Map.get(:source_environment_key, Map.get(attrs, "source_environment_key"))
      |> Manifest.normalize_string()

    target_fingerprint =
      attrs
      |> Map.get(:target_fingerprint, Map.get(attrs, "target_fingerprint"))
      |> Manifest.normalize_string()

    tenant_key =
      attrs
      |> Map.get(:tenant_key, Map.get(attrs, "tenant_key"))
      |> Manifest.normalize_string()

    status =
      attrs
      |> Map.get(:status, Map.get(attrs, "status", "changes"))
      |> to_string()

    plan_seed =
      %{
        "mode" => "import",
        "target_environment_key" => target_environment_key,
        "target_fingerprint" => target_fingerprint,
        "dependency_closure_keys" => dependency_closure_keys,
        "proposed_target_bundle" => bundle
      }
      |> maybe_put("source_environment_key", source_environment_key)
      |> maybe_put("tenant_key", tenant_key)

    %{
      "schema_version" => @schema_version,
      "kind" => @kind,
      "mode" => "import",
      "status" => status,
      "source_environment_key" => source_environment_key,
      "target_environment_key" => target_environment_key,
      "tenant_key" => tenant_key,
      "plan_token" => plan_token(plan_seed),
      "target_fingerprint" => target_fingerprint,
      "dependency_closure_keys" => dependency_closure_keys,
      "flag_keys" => Map.keys(bundle) |> Enum.sort(),
      "proposed_target_bundle" => bundle
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @spec build_promote(map()) :: map()
  def build_promote(attrs) do
    bundle =
      attrs
      |> Map.fetch!(:proposed_target_bundle)
      |> normalize_bundle()

    dependency_closure_keys =
      attrs
      |> Map.get(:dependency_closure_keys, Map.get(attrs, "dependency_closure_keys", []))
      |> Manifest.normalize_string_list()

    source_environment_key =
      attrs
      |> Map.get(:source_environment_key, Map.get(attrs, "source_environment_key"))
      |> Manifest.normalize_string()

    target_environment_key =
      attrs
      |> Map.get(:target_environment_key, Map.get(attrs, "target_environment_key"))
      |> Manifest.normalize_string()

    tenant_key =
      attrs
      |> Map.get(:tenant_key, Map.get(attrs, "tenant_key"))
      |> Manifest.normalize_string()

    compare_token =
      attrs
      |> Map.get(:compare_token, Map.get(attrs, "compare_token"))
      |> Manifest.normalize_string()

    source_fingerprint =
      attrs
      |> Map.get(:source_fingerprint, Map.get(attrs, "source_fingerprint"))
      |> Manifest.normalize_string()

    target_fingerprint =
      attrs
      |> Map.get(:target_fingerprint, Map.get(attrs, "target_fingerprint"))
      |> Manifest.normalize_string()

    status =
      attrs
      |> Map.get(:status, Map.get(attrs, "status", "changes"))
      |> to_string()

    plan_seed =
      %{
        "mode" => "promote",
        "source_environment_key" => source_environment_key,
        "target_environment_key" => target_environment_key,
        "compare_token" => compare_token,
        "source_fingerprint" => source_fingerprint,
        "target_fingerprint" => target_fingerprint,
        "dependency_closure_keys" => dependency_closure_keys,
        "proposed_target_bundle" => bundle
      }
      |> maybe_put("tenant_key", tenant_key)

    %{
      "schema_version" => @schema_version,
      "kind" => @kind,
      "mode" => "promote",
      "status" => status,
      "source_environment_key" => source_environment_key,
      "target_environment_key" => target_environment_key,
      "tenant_key" => tenant_key,
      "plan_token" => plan_token(plan_seed),
      "compare_token" => compare_token,
      "source_fingerprint" => source_fingerprint,
      "target_fingerprint" => target_fingerprint,
      "dependency_closure_keys" => dependency_closure_keys,
      "flag_keys" => Map.keys(bundle) |> Enum.sort(),
      "proposed_target_bundle" => bundle
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  @spec fingerprint(map()) :: String.t()
  def fingerprint(map) when is_map(map) do
    "sha256:" <>
      (:crypto.hash(:sha256, encode_json(Manifest.normalize_map(map)))
       |> Base.encode16(case: :lower))
  end

  @spec dependency_closure_from_bundle(map()) :: [String.t()]
  def dependency_closure_from_bundle(bundle) when is_map(bundle) do
    bundle
    |> Map.values()
    |> Enum.flat_map(fn state ->
      state
      |> Map.get("active_ruleset", %{})
      |> Map.get("rules", [])
      |> Enum.flat_map(fn rule ->
        case Manifest.normalize_string(Map.get(rule, "audience_key")) do
          nil -> []
          audience_key -> ["audience:" <> audience_key]
        end
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def dependency_closure_from_bundle(_bundle), do: []

  defp normalize_bundle(bundle) when is_map(bundle) do
    bundle
    |> Enum.map(fn {flag_key, state} ->
      {Manifest.normalize_string(flag_key), Manifest.normalize_map(state)}
    end)
    |> Enum.reject(fn {flag_key, _state} -> is_nil(flag_key) end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Map.new()
  end

  defp normalize_bundle(_bundle), do: %{}

  defp plan_token(plan_seed) do
    "plan_" <>
      (:crypto.hash(:sha256, encode_json(Manifest.normalize_map(plan_seed)))
       |> Base.encode16(case: :lower)
       |> binary_part(0, 24))
  end

  defp validate_kind(plan) do
    if fetch_optional_string(plan, "kind") == @kind do
      :ok
    else
      {:error, Manifest.invalid("apply plan kind is unsupported")}
    end
  end

  defp validate_schema_version(plan) do
    if Map.get(plan, "schema_version", Map.get(plan, :schema_version)) == @schema_version do
      :ok
    else
      {:error, Manifest.invalid("apply plan schema version is unsupported")}
    end
  end

  defp validate_mode(mode) when mode in @modes, do: :ok
  defp validate_mode(_mode), do: {:error, Manifest.invalid("apply plan mode is unsupported")}

  defp load_status(plan) do
    status = Map.get(plan, "status", Map.get(plan, :status, "changes")) |> to_string()

    if status in @statuses do
      {:ok, status}
    else
      {:error, Manifest.invalid("apply plan status is unsupported")}
    end
  end

  defp load_string_list(plan, key) do
    {:ok,
     Manifest.normalize_string_list(Map.get(plan, key, Map.get(plan, String.to_atom(key), [])))}
  end

  defp load_bundle(plan) do
    bundle = Map.get(plan, "proposed_target_bundle", Map.get(plan, :proposed_target_bundle))

    if is_map(bundle) do
      {:ok, normalize_bundle(bundle)}
    else
      {:error, Manifest.invalid("apply plan proposed_target_bundle must be an object")}
    end
  end

  defp fetch_required_string(map, key) do
    case fetch_optional_string(map, key) do
      nil -> {:error, Manifest.invalid("apply plan is missing required field #{key}")}
      value -> {:ok, value}
    end
  end

  defp fetch_optional_string(map, key) do
    Manifest.normalize_string(Map.get(map, key, Map.get(map, String.to_atom(key))))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp encode_json(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {to_string(key), encode_json(value)} end)
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map_join(",", fn {key, value} -> Jason.encode!(key) <> ":" <> value end)
    |> then(&("{" <> &1 <> "}"))
  end

  defp encode_json(list) when is_list(list),
    do: "[" <> Enum.map_join(list, ",", &encode_json/1) <> "]"

  defp encode_json(value) when is_binary(value), do: Jason.encode!(value)
  defp encode_json(value) when is_boolean(value), do: Jason.encode!(value)
  defp encode_json(value) when is_integer(value), do: Jason.encode!(value)
  defp encode_json(value) when is_float(value), do: Jason.encode!(value)
  defp encode_json(nil), do: "null"
end

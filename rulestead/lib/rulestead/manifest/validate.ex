# credo:disable-for-this-file
defmodule Rulestead.Manifest.Validate do
  @moduledoc false

  alias Rulestead.Manifest
  alias Rulestead.Manifest.Result

  @spec validate(binary() | map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def validate(content) do
    with {:ok, raw_manifest} <- decode_raw(content),
         {:ok, manifest} <- Manifest.load(raw_manifest) do
      findings =
        duplicate_flag_key_findings(raw_manifest) ++
          dependency_findings(manifest) ++ lifecycle_findings(manifest)

      status = if(findings == [], do: "ok", else: "invalid")

      {:ok,
       Result.new(%{
         status: status,
         command: "validate",
         summary: %{
           "environment_key" => manifest["environment_key"],
           "flag_count" => length(manifest["flags"]),
           "finding_count" => length(findings)
         },
         findings: findings,
         details: %{"manifest" => manifest}
       })}
    end
  end

  defp decode_raw(content) when is_binary(content) do
    case Jason.decode(content) do
      {:ok, manifest} -> {:ok, manifest}
      {:error, _reason} -> {:error, Manifest.invalid("manifest is not valid JSON")}
    end
  end

  defp decode_raw(content) when is_map(content), do: {:ok, content}

  defp decode_raw(_content),
    do: {:error, Manifest.invalid("manifest content must be a JSON object")}

  defp duplicate_flag_key_findings(raw_manifest) do
    raw_manifest
    |> Map.get("flags", [])
    |> Enum.map(&Manifest.normalize_string(Map.get(&1, "flag_key", Map.get(&1, :flag_key))))
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
    |> Enum.flat_map(fn
      {flag_key, count} when count > 1 ->
        [
          Result.finding("duplicate_flag_key", "blocker", "manifest",
            message: "flag #{flag_key} appears more than once"
          )
        ]

      _other ->
        []
    end)
  end

  defp dependency_findings(manifest) do
    manifest["flags"]
    |> Enum.flat_map(fn flag ->
      flag_key = flag["flag_key"]

      flag["active_ruleset"]["rules"]
      |> Enum.flat_map(fn rule ->
        strategy = rule["strategy"]
        audience_key = rule["audience_key"]

        if strategy == "segment_match" and is_nil(audience_key) do
          [
            Result.finding("missing_dependency", "blocker", "flag:#{flag_key}",
              message: "segment_match rules require audience_key"
            )
          ]
        else
          []
        end
      end)
    end)
  end

  defp lifecycle_findings(manifest) do
    manifest["flags"]
    |> Enum.flat_map(fn flag ->
      if flag["environment"]["status"] == "archived" do
        [
          Result.finding("archived_environment_state", "warning", "flag:#{flag["flag_key"]}",
            message: "manifest includes archived environment state"
          )
        ]
      else
        []
      end
    end)
  end
end

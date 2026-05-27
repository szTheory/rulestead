# credo:disable-for-this-file
defmodule Rulestead.Manifest.Validate do
  @moduledoc false

  alias Rulestead.Manifest
  alias Rulestead.Manifest.Result
  alias Rulestead.Targeting.{DependencyInventory, DependencyValidator}

  @spec validate(binary() | map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def validate(content) do
    with {:ok, raw_manifest} <- decode_raw(content),
         {:ok, manifest} <- Manifest.load(raw_manifest) do
      dependency_findings = dependency_findings(manifest)

      findings =
        duplicate_flag_key_findings(raw_manifest) ++
          dependency_summary_findings(dependency_findings) ++ lifecycle_findings(manifest)

      status = if(findings == [], do: "ok", else: "invalid")

      {:ok,
       Result.new(%{
         status: status,
         command: "validate",
         summary: %{
           "environment_key" => manifest["environment_key"],
           "flag_count" => length(manifest["flags"]),
           "finding_count" => length(findings),
           "dependency_finding_count" => length(dependency_findings)
         },
         findings: findings,
         dependency_findings: dependency_findings,
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
    findings =
      DependencyValidator.validate(
        %{
          tenant_key: manifest["tenant_key"],
          audiences: dependency_validation_audiences()
        },
        dependency_entries(manifest)
      )
      |> DependencyValidator.sort_findings()

    Enum.map(findings, fn finding ->
      environment_key = finding.environment_key || manifest["environment_key"]
      tenant_key = finding.tenant_key || manifest["tenant_key"] || "global"

      %{
        "code" => to_string(finding.code),
        "severity" => to_string(finding.severity),
        "message" => finding.message,
        "environment_key" => environment_key,
        "tenant_key" => tenant_key,
        "flag_key" => finding.flag_key,
        "ruleset_version" => finding.ruleset_version,
        "rule_key" => finding.rule_key,
        "audience_key" => finding.audience_key,
        "scope" => dependency_scope(environment_key, tenant_key, finding)
      }
    end)
    |> Result.sort_findings()
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

  defp dependency_summary_findings(dependency_findings) do
    Enum.map(dependency_findings, fn finding ->
      Result.finding(
        finding["code"],
        finding["severity"],
        finding["scope"],
        message: finding["message"]
      )
    end)
  end

  defp dependency_entries(manifest) do
    environment_key = manifest["environment_key"]
    tenant_key = manifest["tenant_key"] || "global"

    manifest["flags"]
    |> Enum.flat_map(fn flag ->
      flag_key = flag["flag_key"]
      ruleset = flag["active_ruleset"] || %{}
      ruleset_version = ruleset["version"]

      Map.get(ruleset, "rules", [])
      |> Enum.flat_map(fn rule ->
        if rule["strategy"] == "segment_match" do
          [
            DependencyInventory.normalize_entry(%{
              environment_key: rule["environment_key"] || environment_key,
              tenant_key: rule["tenant_key"] || tenant_key,
              audience_key: rule["audience_key"],
              flag_key: flag_key,
              ruleset_version: ruleset_version,
              rule_key: rule["key"],
              ruleset_status: "published",
              rollout_context: rule["rollout"] || %{},
              lifecycle_context: %{available?: false},
              visibility: %{status: "visible"},
              reference_count: 1,
              hidden_reference_count: 0,
              audience_schema_version: rule["audience_schema_version"],
              audience_version_hash: rule["audience_version_hash"]
            })
          ]
        else
          []
        end
      end)
    end)
    |> Enum.reject(&(&1.malformed? or is_nil(&1.audience_key)))
    |> DependencyInventory.sort_entries()
  end

  defp dependency_validation_audiences do
    case Rulestead.list_audiences(include_archived?: true, limit: 10_000) do
      {:ok, audiences} ->
        Map.new(audiences, fn audience ->
          {audience.key,
           %{
             key: audience.key,
             archived_at: Map.get(audience, :archived_at),
             tenant_key: Map.get(audience, :tenant_key),
             definition: Map.get(audience, :definition)
           }}
        end)

      {:error, _error} ->
        %{}
    end
  end

  defp dependency_scope(environment_key, tenant_key, finding) do
    [
      "env=#{environment_key}",
      "tenant=#{tenant_key}",
      "flag=#{finding.flag_key}",
      "ruleset=#{finding.ruleset_version}",
      "rule=#{finding.rule_key}",
      "audience=#{finding.audience_key}"
    ]
    |> Enum.join("|")
  end
end

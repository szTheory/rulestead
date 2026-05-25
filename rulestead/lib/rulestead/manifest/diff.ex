defmodule Rulestead.Manifest.Diff do
  @moduledoc false

  alias Rulestead.Manifest
  alias Rulestead.Manifest.Result
  alias Rulestead.Promotion.Compare

  @spec diff(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def diff(source_content, opts) do
    with {:ok, source_manifest} <- Manifest.load(source_content),
         {:ok, target_manifest} <- load_target(opts),
         {:ok, compare} <- compare_manifests(source_manifest, target_manifest) do
      {:ok, build_result(compare, source_manifest, target_manifest)}
    end
  end

  defp load_target(opts) do
    cond do
      Keyword.has_key?(opts, :target_manifest) ->
        Manifest.load(Keyword.fetch!(opts, :target_manifest))

      Keyword.has_key?(opts, :target_environment) ->
        Rulestead.export_manifest(Keyword.fetch!(opts, :target_environment))

      true ->
        {:error, Manifest.invalid("diff requires either a target manifest or target environment")}
    end
  end

  defp compare_manifests(source_manifest, target_manifest) do
    source_environment = %{"key" => source_manifest["environment_key"]}
    target_environment = %{"key" => target_manifest["environment_key"]}
    audiences = audience_presence_map(source_manifest, target_manifest)

    compare =
      Compare.compare_projected(%{
        source_environment: source_environment,
        target_environment: target_environment,
        source_flags: to_compare_payloads(source_manifest),
        target_flags: to_compare_payloads(target_manifest),
        audiences: audiences
      })

    {:ok, {compare, audiences}}
  end

  defp build_result({compare, audiences}, source_manifest, target_manifest) do
    findings = compare_findings(compare, audiences)
    changed_flag_count = meaningful_flag_count(compare, audiences)

    status =
      cond do
        findings == [] and changed_flag_count == 0 -> "no_changes"
        Enum.any?(findings, &(&1["code"] == "compare_token_stale")) -> "stale"
        Enum.any?(findings, &(&1["severity"] == "blocker")) -> "blocked"
        true -> "changes"
      end

    Result.new(%{
      status: status,
      command: "diff",
      summary: %{
        "source_environment_key" => source_manifest["environment_key"],
        "target_environment_key" => target_manifest["environment_key"],
        "changed_flag_count" => changed_flag_count,
        "finding_count" => length(findings)
      },
      findings: findings,
      details: %{
        "compare" => %{
          "compare_token" => compare.compare_token,
          "overall_status" => to_string(compare.overall_status),
          "dependency_closure_keys" => compare.dependency_closure_keys,
          "flags" => compare.flags
        }
      }
    })
  end

  defp compare_findings(compare, audiences) do
    top_findings =
      compare.findings
      |> Enum.reject(&ignore_compare_finding?(&1, audiences))
      |> Enum.map(&to_result_finding(&1, "manifest"))

    flag_findings =
      compare.flags
      |> Enum.flat_map(fn flag ->
        flag.findings
        |> Enum.reject(&ignore_compare_finding?(&1, audiences))
        |> Enum.map(&to_result_finding(&1, "flag:#{flag.flag_key}"))
      end)

    Result.sort_findings(top_findings ++ flag_findings)
  end

  defp meaningful_flag_count(compare, audiences) do
    Enum.count(compare.flags, fn flag ->
      changed_fields = flag[:changed_fields] || flag["changed_fields"] || []

      filtered_findings =
        flag[:findings] || flag["findings"] ||
          []
          |> Enum.reject(&ignore_compare_finding?(&1, audiences))

      changed_fields != [] or filtered_findings != []
    end)
  end

  defp ignore_compare_finding?(finding, audiences) do
    code = finding[:code] || finding["code"]

    case code do
      "protected_target_environment" ->
        true

      "missing_dependency" ->
        dependency_key =
          finding
          |> Map.get(:metadata, Map.get(finding, "metadata", %{}))
          |> then(fn metadata ->
            Map.get(metadata, :dependency_key) || Map.get(metadata, "dependency_key")
          end)

        case dependency_key do
          "audience:" <> audience_key -> Map.has_key?(audiences, audience_key)
          _other -> false
        end

      _other ->
        false
    end
  end

  defp to_result_finding(finding, scope) do
    Result.finding(
      finding[:code] || finding["code"],
      finding[:severity] || finding["severity"],
      scope,
      message: finding[:message] || finding["message"]
    )
  end

  defp to_compare_payloads(manifest) do
    manifest["flags"]
    |> Map.new(fn flag ->
      flag_key = flag["flag_key"]

      payload = %{
        "flag" => Map.put(flag["flag"], "key", flag_key),
        "flag_environment" => flag["environment"],
        "active_ruleset" => Map.put(flag["active_ruleset"], "status", "published")
      }

      {flag_key, payload}
    end)
  end

  defp audience_presence_map(source_manifest, target_manifest) do
    [source_manifest, target_manifest]
    |> Enum.flat_map(fn manifest ->
      manifest["flags"]
      |> Enum.flat_map(fn flag ->
        (flag["active_ruleset"]["rules"] || [])
        |> Enum.map(& &1["audience_key"])
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Map.new(&{&1, %{"key" => &1}})
  end
end

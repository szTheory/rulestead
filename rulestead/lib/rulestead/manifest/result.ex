# credo:disable-for-this-file
defmodule Rulestead.Manifest.Result do
  @moduledoc false

  @statuses ~w(ok no_changes changes governance_required invalid blocked stale applied queued error)
  @severity_rank %{"blocker" => 0, "warning" => 1, "info" => 2}

  @spec new(map()) :: map()
  def new(attrs) do
    findings =
      attrs
      |> Map.get(:findings, Map.get(attrs, "findings", []))
      |> sort_findings()

    dependency_findings =
      attrs
      |> Map.get(:dependency_findings, Map.get(attrs, "dependency_findings", []))
      |> sort_dependency_findings()

    %{
      "status" => normalize_status(Map.get(attrs, :status, Map.get(attrs, "status"))),
      "command" => to_string(Map.get(attrs, :command, Map.get(attrs, "command"))),
      "summary" => normalize_map(Map.get(attrs, :summary, Map.get(attrs, "summary", %{}))),
      "findings" => findings,
      "dependency_findings" => dependency_findings,
      "details" => normalize_map(Map.get(attrs, :details, Map.get(attrs, "details", %{})))
    }
  end

  @spec finding(String.t() | atom(), String.t() | atom(), String.t() | atom(), keyword()) :: map()
  def finding(code, severity, scope, opts \\ []) do
    %{
      "code" => to_string(code),
      "severity" => to_string(severity),
      "scope" => to_string(scope)
    }
    |> maybe_put("message", Keyword.get(opts, :message))
  end

  @spec exit_code(map()) :: 0 | 1 | 2 | 3
  def exit_code(result) do
    case result["status"] do
      "ok" -> 0
      "no_changes" -> 0
      "applied" -> 0
      "queued" -> 0
      "changes" -> 2
      "governance_required" -> 3
      "invalid" -> 3
      "blocked" -> 3
      "stale" -> 3
      _other -> 1
    end
  end

  @spec sort_findings([map()]) :: [map()]
  def sort_findings(findings) do
    Enum.sort_by(findings, fn finding ->
      {
        Map.get(@severity_rank, finding["severity"] || to_string(finding[:severity]), 99),
        finding["code"] || to_string(finding[:code]),
        finding["scope"] || to_string(finding[:scope])
      }
    end)
  end

  defp normalize_status(status) when status in @statuses, do: status
  defp normalize_status(status) when is_atom(status), do: normalize_status(Atom.to_string(status))
  defp normalize_status(_status), do: "error"

  @spec sort_dependency_findings([map()]) :: [map()]
  defp sort_dependency_findings(findings) when is_list(findings) do
    Enum.sort_by(findings, fn finding ->
      {
        Map.get(@severity_rank, finding["severity"] || to_string(finding[:severity]), 99),
        finding["code"] || to_string(finding[:code]),
        finding["environment_key"] || to_string(finding[:environment_key]),
        finding["tenant_key"] || to_string(finding[:tenant_key]),
        finding["flag_key"] || to_string(finding[:flag_key]),
        finding["ruleset_version"] || finding[:ruleset_version] || 0,
        finding["rule_key"] || to_string(finding[:rule_key]),
        finding["audience_key"] || to_string(finding[:audience_key])
      }
    end)
  end

  defp sort_dependency_findings(_findings), do: []

  defp normalize_map(value), do: Rulestead.Manifest.normalize_map(value)

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

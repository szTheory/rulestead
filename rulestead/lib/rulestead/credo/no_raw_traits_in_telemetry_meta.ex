defmodule Rulestead.Credo.NoRawTraitsInTelemetryMeta do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Telemetry metadata must not include raw trait-like keys such as email or IP.
      Emit redacted or allowlisted fields only.
      """
    ]

  alias Credo.SourceFile

  @sensitive_keys ~w(email ip phone name user_agent)a
  @message "Telemetry metadata must not include raw trait keys. Redact or allowlist before emitting telemetry."

  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), [])
    |> Enum.reverse()
  end

  defp traverse({{:., _, [{:__aliases__, _, [:Telemetry]}, :emit]}, _, args} = ast, issues, issue_meta) do
    {ast, issues ++ issues_for_args(args, issue_meta)}
  end

  defp traverse({{:., _, [:telemetry, :execute]}, _, args} = ast, issues, issue_meta) do
    {ast, issues ++ issues_for_args(args, issue_meta)}
  end

  defp traverse({{:., _, [:telemetry, :span]}, _, args} = ast, issues, issue_meta) do
    {ast, issues ++ issues_for_args(args, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp issues_for_args(args, issue_meta) do
    args
    |> Enum.drop(2)
    |> Enum.flat_map(&issues_for_meta_ast(&1, issue_meta))
  end

  defp issues_for_meta_ast({:%{}, _, pairs}, issue_meta) do
    Enum.flat_map(pairs, &issue_for_pair(&1, issue_meta))
  end

  defp issues_for_meta_ast(_ast, _issue_meta), do: []

  defp issue_for_pair({key_ast, _value_ast}, issue_meta) do
    case normalize_key(key_ast) do
      {:ok, key, meta} when key in @sensitive_keys ->
        [
          format_issue(issue_meta,
            message: @message,
            trigger: Atom.to_string(key),
            line_no: meta[:line],
            column: meta[:column]
          )
        ]

      _ ->
        []
    end
  end

  defp normalize_key({key, meta, nil}) when is_atom(key), do: {:ok, key, meta}
  defp normalize_key(key) when is_atom(key), do: {:ok, key, [line: nil, column: nil]}
  defp normalize_key({:__block__, meta, [key]}) when is_atom(key), do: {:ok, key, meta}
  defp normalize_key(_key), do: :error
end

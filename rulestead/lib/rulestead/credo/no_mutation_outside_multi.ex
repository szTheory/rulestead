defmodule Rulestead.Credo.NoMutationOutsideMulti do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Rulestead writes must stay inside an Ecto.Multi so audit rows and data mutations
      stay atomic.
      """
    ]

  alias Credo.SourceFile

  @message "Rulestead writes must happen inside an Ecto.Multi-backed flow so audit discipline stays atomic."
  @repo_mutations ~w(insert update delete insert! update! delete! insert_all update_all delete_all)a
  @rulestead_modules ~w(Flag FlagEnvironment Ruleset AuditEvent Audience KillSwitchOverride Environment)a

  @impl true
  def run(%SourceFile{} = source_file, params) do
    if lintable_file?(source_file.filename) do
      issue_meta = IssueMeta.for(source_file, params)

      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), [])
      |> Enum.reverse()
    else
      []
    end
  end

  defp traverse({{:., _, [repo_ast, function]}, meta, args} = ast, issues, issue_meta)
       when function in @repo_mutations do
    if repo_call?(repo_ast) and rulestead_target?(args) do
      issue =
        format_issue(issue_meta,
          message: @message,
          trigger: Atom.to_string(function),
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, [issue | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp repo_call?({:__aliases__, _, [:Repo]}), do: true
  defp repo_call?({:__aliases__, _, [:Rulestead, :Repo]}), do: true
  defp repo_call?(_ast), do: false

  defp rulestead_target?([target | _rest]), do: rulestead_schema?(target)
  defp rulestead_target?(_args), do: false

  defp rulestead_schema?({:%, _, [schema_ast, _map_ast]}), do: rulestead_schema?(schema_ast)
  defp rulestead_schema?({:__aliases__, _, [:Rulestead, module]}) when module in @rulestead_modules, do: true
  defp rulestead_schema?({:__aliases__, _, [module]}) when module in @rulestead_modules, do: true
  defp rulestead_schema?(_ast), do: false

  defp lintable_file?(filename) when is_binary(filename) do
    not String.contains?(filename, "test/") or String.contains?(filename, "credo_fixtures")
  end

  defp lintable_file?(_filename), do: true
end

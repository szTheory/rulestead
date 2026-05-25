# credo:disable-for-this-file
if Code.ensure_loaded?(Credo.Check) and Code.ensure_loaded?(Credo.SourceFile) do
  defmodule Rulestead.Credo.NoEvalOutsideContext do
    use Credo.Check,
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        Runtime evaluation must go through the public Rulestead facade so context shaping,
        telemetry, and explainability stay on the intended path.
        """
      ]

    alias Credo.SourceFile

    @message "Call the public Rulestead facade, not Rulestead.Evaluator directly, so evaluation stays on the designated context path."
    @forbidden_calls ~w(enabled? get_value get_variant explain evaluate)a

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), [])
      |> Enum.reverse()
    end

    defp traverse(
           {{:., _, [{:__aliases__, _, [:Rulestead, :Evaluator]}, function]}, meta, _args} = ast,
           issues,
           issue_meta
         )
         when function in @forbidden_calls do
      issue =
        format_issue(issue_meta,
          message: @message,
          trigger: Atom.to_string(function),
          line_no: meta[:line],
          column: meta[:column]
        )

      {ast, [issue | issues]}
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}
  end
else
  defmodule Rulestead.Credo.NoEvalOutsideContext do
  end
end

# credo:disable-for-this-file
if Code.ensure_loaded?(Credo.Check) and Code.ensure_loaded?(Credo.SourceFile) do
  defmodule Rulestead.Credo.NoSocketCapturedInAsync do
    use Credo.Check,
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        LiveView async callbacks must not capture `socket`; copy only the data the task
        needs before starting async work.
        """
      ]

    alias Credo.SourceFile

    @async_functions ~w(start_async assign_async stream_async)a
    @message "Async LiveView closures must not capture `socket`; copy the needed data before starting async work."

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)

      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), [])
      |> Enum.reverse()
    end

    defp traverse({function, meta, args} = ast, issues, issue_meta)
         when function in @async_functions do
      {ast, issues ++ issues_for_async_args(args, function, meta, issue_meta)}
    end

    defp traverse(ast, issues, _issue_meta), do: {ast, issues}

    defp issues_for_async_args(args, function, meta, issue_meta) do
      args
      |> Enum.filter(&closure?/1)
      |> Enum.flat_map(fn closure ->
        if captures_socket?(closure) do
          [
            format_issue(issue_meta,
              message: @message,
              trigger: Atom.to_string(function),
              line_no: meta[:line],
              column: meta[:column]
            )
          ]
        else
          []
        end
      end)
    end

    defp closure?({:fn, _, _}), do: true
    defp closure?(_ast), do: false

    defp captures_socket?(closure_ast) do
      Credo.Code.prewalk(closure_ast, &scan_socket/2, false)
    end

    defp scan_socket({:socket, _, context} = ast, _acc) when is_atom(context), do: {ast, true}
    defp scan_socket(ast, acc), do: {ast, acc}
  end
else
  defmodule Rulestead.Credo.NoSocketCapturedInAsync do
  end
end

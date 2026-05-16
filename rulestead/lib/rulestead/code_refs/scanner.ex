defmodule Rulestead.CodeRefs.Scanner do
  @moduledoc """
  Scans Elixir source code to find usages of `Rulestead.evaluate`.
  """

  @doc """
  Scans a directory for `.ex` and `.exs` files and returns a list of references.
  """
  def scan_dir(dir_path) do
    dir_path
    |> Path.join("**/*.{ex,exs}")
    |> Path.wildcard()
    |> Enum.flat_map(fn file_path ->
      case File.read(file_path) do
        {:ok, content} -> scan_string(content, file_path)
        _ -> []
      end
    end)
  end

  @doc """
  Scans a single string of Elixir code for usages of `Rulestead.evaluate`.
  """
  def scan_string(code, file_path) do
    case Code.string_to_quoted(code, columns: true) do
      {:ok, ast} ->
        extract_references(ast, file_path)

      {:error, _} ->
        []
    end
  end

  defp extract_references(ast, file_path) do
    {_ast, acc} = Macro.prewalk(ast, [], fn
      # Rulestead.evaluate(context, "flag_key", opts)
      {{:., _, [{:__aliases__, _, [:Rulestead]}, :evaluate]}, meta, [_context, flag_key | _rest]} = node, acc
      when is_binary(flag_key) ->
        {node, [%{file: file_path, line: Keyword.get(meta, :line), flag_key: flag_key} | acc]}

      node, acc ->
        {node, acc}
    end)

    Enum.reverse(acc)
  end
end

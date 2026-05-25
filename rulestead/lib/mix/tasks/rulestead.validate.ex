defmodule Mix.Tasks.Rulestead.Validate do
  @moduledoc false

  use Mix.Task

  alias Rulestead.Manifest.Result
  alias Rulestead.Manifest.{Render, Validate}

  @shortdoc "Validates a deterministic environment manifest"
  @switches [file: :string, format: :string]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)

    content = read_input(Keyword.fetch!(opts, :file))

    case compute(content) do
      {:ok, result} ->
        emit(result, Keyword.get(opts, :format, "text"))
        System.halt(Result.exit_code(result))

      {:error, %Rulestead.Error{} = error} ->
        Mix.raise(error.message)
    end
  end

  @spec compute(binary() | map()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute(content), do: Validate.validate(content)

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise("usage: mix rulestead.validate --file <path|-> [--format text|json]")
    end

    if is_nil(Keyword.get(opts, :file)) do
      Mix.raise("validate requires --file <path|->")
    end
  end

  defp emit(result, "json"), do: IO.write(Render.render_json(result) <> "\n")
  defp emit(result, _other), do: Mix.shell().info(Render.render_text(result))

  defp read_input("-"), do: IO.read(:stdio, :eof)
  defp read_input(path), do: File.read!(path)
end

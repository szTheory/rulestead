defmodule Mix.Tasks.Rulestead.Diff do
  @moduledoc false

  use Mix.Task

  alias Rulestead.Manifest.Result
  alias Rulestead.Manifest.{Diff, Render}

  @shortdoc "Diffs a source manifest against another manifest or live authored state"
  @switches [source: :string, target: :string, environment: :string, format: :string]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)

    source = read_input(Keyword.fetch!(opts, :source))

    diff_opts =
      if target = Keyword.get(opts, :target) do
        [target_manifest: read_input(target)]
      else
        [target_environment: Keyword.fetch!(opts, :environment)]
      end

    case compute(source, diff_opts) do
      {:ok, result} ->
        emit(result, Keyword.get(opts, :format, "text"))
        System.halt(Result.exit_code(result))

      {:error, %Rulestead.Error{} = error} ->
        Mix.raise(error.message)
    end
  end

  @spec compute(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute(source, opts), do: Diff.diff(source, opts)

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise(
        "usage: mix rulestead.diff --source <path|-> [--target <path|-> | --environment <environment_key>] [--format text|json]"
      )
    end

    unless Keyword.get(opts, :source) do
      Mix.raise("diff requires --source <path|->")
    end

    if is_nil(Keyword.get(opts, :target)) and is_nil(Keyword.get(opts, :environment)) do
      Mix.raise("diff requires either --target <path|-> or --environment <environment_key>")
    end
  end

  defp emit(result, "json"), do: IO.write(Render.render_json(result) <> "\n")
  defp emit(result, _other), do: Mix.shell().info(Render.render_text(result))

  defp read_input("-"), do: IO.read(:stdio, :eof)
  defp read_input(path), do: File.read!(path)
end

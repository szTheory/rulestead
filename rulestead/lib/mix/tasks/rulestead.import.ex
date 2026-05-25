defmodule Mix.Tasks.Rulestead.Import do
  @moduledoc false

  use Mix.Task

  alias Rulestead.Manifest.{Plan, Render, Result}

  @shortdoc "Previews or applies a manifest import through a saved plan artifact"
  @switches [
    file: :string,
    out: :string,
    environment: :string,
    format: :string,
    reason: :string,
    plan: :boolean,
    apply: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)
    validate_args!(opts, argv, invalid)

    content = read_input(Keyword.fetch!(opts, :file))

    result =
      cond do
        Keyword.get(opts, :plan) ->
          compute_plan(content, target_environment: Keyword.get(opts, :environment))

        Keyword.get(opts, :apply) ->
          compute_apply(content, reason: Keyword.get(opts, :reason))
      end

    case result do
      {:ok, envelope} ->
        maybe_write_plan(envelope, Keyword.get(opts, :out))
        emit(envelope, Keyword.get(opts, :format, "text"))
        System.halt(Result.exit_code(envelope))

      {:error, %Rulestead.Error{} = error} ->
        Mix.raise(error.message)
    end
  end

  @spec compute_plan(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute_plan(content, opts \\ []) do
    Rulestead.import_manifest(content, opts)
  end

  @spec compute_apply(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute_apply(content, opts \\ []) do
    Rulestead.apply_manifest_plan(content, opts)
  end

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise("usage: mix rulestead.import --plan --file <manifest_path|-> [--environment <environment_key>] [--out <plan_path>] [--format text|json] OR mix rulestead.import --apply --file <plan_path|-> --reason <reason> [--format text|json]")
    end

    unless Keyword.get(opts, :file) do
      Mix.raise("import requires --file <path|->")
    end

    modes = Enum.count([Keyword.get(opts, :plan), Keyword.get(opts, :apply)], & &1)

    if modes != 1 do
      Mix.raise("import requires exactly one of --plan or --apply")
    end

    if Keyword.get(opts, :apply) and is_nil(Keyword.get(opts, :reason)) do
      Mix.raise("import apply requires --reason <reason>")
    end
  end

  defp maybe_write_plan(_result, nil), do: :ok

  defp maybe_write_plan(result, path) do
    case get_in(result, ["details", "plan"]) do
      nil ->
        :ok

      plan ->
        {:ok, payload} = Plan.serialize(plan)

        case path do
          "-" -> IO.write(payload <> "\n")
          other -> File.write!(other, payload <> "\n")
        end
    end
  end

  defp emit(result, "json"), do: IO.write(Render.render_json(result) <> "\n")
  defp emit(result, _other), do: Mix.shell().info(Render.render_text(result))

  defp read_input("-"), do: IO.read(:stdio, :eof)
  defp read_input(path), do: File.read!(path)
end

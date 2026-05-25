defmodule Mix.Tasks.Rulestead.Promote do
  @moduledoc false

  use Mix.Task

  alias Rulestead.Manifest.{Plan, Render, Result}

  @shortdoc "Previews or applies environment promotion through a saved plan artifact"
  @switches [
    source: :string,
    target: :string,
    file: :string,
    out: :string,
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

    result =
      cond do
        Keyword.get(opts, :plan) ->
          compute_plan(
            Keyword.fetch!(opts, :source),
            Keyword.fetch!(opts, :target)
          )

        Keyword.get(opts, :apply) ->
          Keyword.fetch!(opts, :file)
          |> read_input()
          |> compute_apply(reason: Keyword.get(opts, :reason))
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

  @spec compute_plan(String.t() | atom(), String.t() | atom(), keyword()) ::
          {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute_plan(source_environment_key, target_environment_key, opts \\ []) do
    Rulestead.plan_promotion(source_environment_key, target_environment_key, opts)
  end

  @spec compute_apply(binary() | map(), keyword()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
  def compute_apply(content, opts \\ []) do
    Rulestead.apply_promotion_plan(content, opts)
  end

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise(
        "usage: mix rulestead.promote --plan --source <environment_key> --target <environment_key> [--out <plan_path>] [--format text|json] OR mix rulestead.promote --apply --file <plan_path|-> --reason <reason> [--format text|json]"
      )
    end

    modes = Enum.count([Keyword.get(opts, :plan), Keyword.get(opts, :apply)], & &1)

    if modes != 1 do
      Mix.raise("promote requires exactly one of --plan or --apply")
    end

    if Keyword.get(opts, :plan) do
      unless Keyword.get(opts, :source) do
        Mix.raise("promote plan requires --source <environment_key>")
      end

      unless Keyword.get(opts, :target) do
        Mix.raise("promote plan requires --target <environment_key>")
      end
    end

    if Keyword.get(opts, :apply) do
      unless Keyword.get(opts, :file) do
        Mix.raise("promote apply requires --file <plan_path|->")
      end

      if Keyword.get(opts, :source) || Keyword.get(opts, :target) do
        Mix.raise(
          "promote apply does not accept raw --source/--target inputs; pass a saved plan via --file"
        )
      end

      if is_nil(Keyword.get(opts, :reason)) do
        Mix.raise("promote apply requires --reason <reason>")
      end
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

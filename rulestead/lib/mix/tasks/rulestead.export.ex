defmodule Mix.Tasks.Rulestead.Export do
  @moduledoc false

  use Mix.Task

  alias Rulestead.Manifest

  @shortdoc "Exports a deterministic authored-state manifest for one environment"

  @switches [environment: :string, out: :string, flag: :keep]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    validate_args!(opts, argv, invalid)

    environment_key = Keyword.fetch!(opts, :environment)
    flag_keys = Keyword.get_values(opts, :flag)

    with {:ok, manifest} <- Rulestead.export_manifest(environment_key, flag_keys: flag_keys),
         {:ok, encoded} <- Manifest.serialize(manifest) do
      write_output(encoded <> "\n", Keyword.get(opts, :out))
    else
      {:error, %Rulestead.Error{} = error} ->
        Mix.raise(error.message)
    end
  end

  defp validate_args!(opts, argv, invalid) do
    if argv != [] or invalid != [] do
      Mix.raise("usage: mix rulestead.export --environment <environment_key> [--flag <flag_key>] [--out <path>|-]")
    end

    if is_nil(Keyword.get(opts, :environment)) do
      Mix.raise("export requires --environment <environment_key>")
    end
  end

  defp write_output(payload, nil), do: IO.write(payload)
  defp write_output(payload, "-"), do: IO.write(payload)
  defp write_output(payload, path), do: File.write!(path, payload)
end

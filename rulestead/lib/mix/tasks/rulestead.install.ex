defmodule Mix.Tasks.Rulestead.Install do
  use Mix.Task

  alias Rulestead.Install

  @shortdoc "Copies rulestead migrations and config into the host app"

  @switches [repo: :string]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

    case Install.run(opts) do
      {:ok, messages} ->
        shell = Mix.shell()
        Enum.each(messages, fn message -> shell.info(message) end)

      {:error, error} ->
        Mix.raise(error.message)
    end
  end
end

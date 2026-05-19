defmodule Mix.Tasks.Verify.WorkspaceClean do
  @moduledoc false

  use Mix.Task

  @shortdoc "Fails when publishable rulestead surfaces are dirty"
  @switches []

  @impl Mix.Task
  def run(args) do
    {_opts, _argv} = parse_args!(args)
    paths = scoped_paths()

    case verify_paths(paths) do
      :ok ->
        Mix.shell().info("workspace clean")

      {:dirty, dirty_paths} ->
        Mix.raise(
          "publishable workspace is dirty:\n" <>
            Enum.map_join(dirty_paths, "\n", &"  - #{&1}")
        )
    end
  end

  def scoped_paths(project_config \\ Mix.Project.config()) do
    project_config
    |> Keyword.get(:package, [])
    |> Keyword.get(:files, [])
    |> Kernel.++(["test"])
    |> Enum.uniq()
    |> Enum.sort()
  end

  def verify_paths(paths, cmd_runner \\ &default_status_cmd/1) do
    case cmd_runner.(paths) do
      {output, 0} -> verify_status(output)
      {output, status} -> Mix.raise("git status failed with exit #{status}: #{String.trim(output)}")
    end
  end

  def verify_status(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_status_line/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> :ok
      dirty_paths -> {:dirty, dirty_paths}
    end
  end

  defp parse_args!(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    case invalid do
      [] -> {opts, argv}
      [{flag, _value} | _rest] -> Mix.raise("unknown option: #{flag}")
    end
  end

  defp parse_status_line(line) do
    case Regex.run(~r/^(?:..)\s+(.+)$/, line, capture: :all_but_first) do
      [path] -> path
      _other -> nil
    end
  end

  defp default_status_cmd(paths) do
    System.cmd(
      "git",
      ["status", "--porcelain", "--untracked-files=all", "--"] ++ paths,
      cd: File.cwd!(),
      stderr_to_stdout: true
    )
  end
end

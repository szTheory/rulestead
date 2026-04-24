defmodule Mix.Tasks.Verify.ReleasePublish do
  use Mix.Task

  @shortdoc "Verifies published rulestead artifacts from fresh consumer fixtures"
  @switches []
  @default_fixture_module Rulestead.Test.ReleasePublishFixture

  @impl Mix.Task
  def run(args) do
    {_opts, argv} = parse_args!(args)

    version =
      case argv do
        [value] -> validate_version!(value)
        _other -> Mix.raise("expected a published version argument, e.g. mix verify.release_publish 0.1.0")
      end

    tmp_dir = tmp_dir()

    try do
      plan = plan(version, tmp_dir: tmp_dir)

      case verify(plan) do
        {:ok, _report} ->
          Mix.shell().info("published release verified for #{version}")

        {:error, reason} ->
          Mix.raise(format_error(reason))
      end
    after
      File.rm_rf!(tmp_dir)
    end
  end

  def validate_version!(version) when is_binary(version) do
    trimmed = String.trim(version)

    cond do
      trimmed == "" ->
        Mix.raise("expected a published version argument")

      String.contains?(trimmed, "path:") or String.contains?(trimmed, "/") ->
        Mix.raise("expected a published version, got local path input: #{trimmed}")

      not Regex.match?(~r/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z\.-]+)?$/, trimmed) ->
        Mix.raise("expected a published version, got: #{trimmed}")

      true ->
        trimmed
    end
  end

  def plan(version, opts \\ []) do
    fixture_module = Keyword.get(opts, :fixture_module, @default_fixture_module)
    tmp_dir = Keyword.get(opts, :tmp_dir, tmp_dir())
    fixture_opts = Keyword.drop(opts, [:fixture_module, :tmp_dir])

    %{
      version: validate_version!(version),
      tmp_dir: tmp_dir,
      hexdocs_url: hexdocs_url(version),
      consumers: [
        fixture_module.setup_core_consumer!(tmp_dir, version, fixture_opts),
        fixture_module.setup_admin_consumer!(tmp_dir, version, fixture_opts)
      ]
    }
  end

  def verify(plan, opts \\ []) do
    http_get = Keyword.get(opts, :http_get, &default_http_get/1)
    command_runner = Keyword.get(opts, :command_runner, &default_command_runner/3)

    with :ok <- validate_consumers(plan.consumers),
         {:ok, docs_status} <- check_hexdocs(plan.hexdocs_url, http_get),
         {:ok, consumers} <- run_consumer_checks(plan.consumers, command_runner) do
      {:ok, %{hexdocs: docs_status, consumers: consumers}}
    end
  end

  def hexdocs_url(version), do: "https://hexdocs.pm/rulestead/#{version}"

  defp parse_args!(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    case invalid do
      [] -> {opts, argv}
      [{flag, _value} | _rest] -> Mix.raise("unknown option: #{flag}")
    end
  end

  defp validate_consumers(consumers) do
    consumers
    |> Enum.find_value(:ok, fn consumer ->
      consumer.deps
      |> Enum.find_value(fn dep ->
        cond do
          Map.has_key?(dep, :path) -> {:error, {:local_path_dependency, dep.app}}
          not is_binary(dep[:requirement]) -> {:error, {:missing_version_requirement, dep.app}}
          true -> nil
        end
      end)
    end)
  end

  defp check_hexdocs(url, http_get) do
    case http_get.(url) do
      {:ok, 200} -> {:ok, {:ok, 200}}
      {:ok, status} -> {:error, {:hexdocs_unreachable, url, status}}
      {:error, reason} -> {:error, {:hexdocs_request_failed, url, reason}}
    end
  end

  defp run_consumer_checks(consumers, command_runner) do
    consumers
    |> Enum.reduce_while({:ok, []}, fn consumer, {:ok, reports} ->
      case run_consumer_check(consumer, command_runner) do
        {:ok, report} -> {:cont, {:ok, reports ++ [report]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp run_consumer_check(consumer, command_runner) do
    consumer.checks
    |> Enum.reduce_while({:ok, []}, fn check, {:ok, completed} ->
      case command_runner.(check.cmd, check.args, cd: consumer.app_dir, stderr_to_stdout: true) do
        {output, 0} ->
          {:cont, {:ok, completed ++ [%{cmd: check.cmd, args: check.args, output: output}]}}

        {output, status} ->
          {:halt,
           {:error,
            {:consumer_command_failed, consumer.name, check.cmd, check.args, status, output}}}
      end
    end)
    |> case do
      {:ok, completed} -> {:ok, %{name: consumer.name, checks: completed}}
      error -> error
    end
  end

  defp default_http_get(url) do
    :inets.start()
    :ssl.start()

    case :httpc.request(:get, {String.to_charlist(url), []}, [], [{:body_format, :binary}]) do
      {:ok, {{_http_version, status, _reason}, _headers, _body}} -> {:ok, status}
      {:error, reason} -> {:error, reason}
    end
  end

  defp default_command_runner(cmd, args, opts) do
    System.cmd(cmd, args, opts)
  end

  defp format_error({:local_path_dependency, app}),
    do: "published release verification rejected local path dependency fallback for #{app}"

  defp format_error({:missing_version_requirement, app}),
    do: "published release verification requires an explicit package version for #{app}"

  defp format_error({:hexdocs_unreachable, url, status}),
    do: "versioned HexDocs URL did not return 200: #{url} (status #{status})"

  defp format_error({:hexdocs_request_failed, url, reason}),
    do: "HexDocs reachability check failed for #{url}: #{inspect(reason)}"

  defp format_error({:consumer_command_failed, name, cmd, args, status, output}) do
    "consumer #{name} command failed with exit #{status}: #{cmd} #{Enum.join(args, " ")}\n#{output}"
  end

  defp tmp_dir do
    path =
      Path.join(
        System.tmp_dir!(),
        "rulestead-release-publish-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end
end

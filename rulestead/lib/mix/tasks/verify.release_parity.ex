defmodule Mix.Tasks.Verify.ReleaseParity do
  @moduledoc false

  use Mix.Task

  @shortdoc "Diffs the git tag contents against the published Hex tarball"
  @switches []

  @impl Mix.Task
  def run(args) do
    {_opts, argv} = parse_args!(args)

    version =
      case argv do
        [value] -> value
        _other -> Mix.raise("expected a version argument, e.g. mix verify.release_parity 0.1.0")
      end

    result =
      case default_loader(version) do
        {:ok, {tag_manifest, tarball_manifest}} -> compute(tag_manifest, tarball_manifest)
        {:error, reason} -> {:error, reason}
      end

    shell = Mix.shell()

    case result do
      {:ok, _report} -> shell.info("release parity confirmed for #{version}")
      {:drift, report} -> shell.error(format_drift(report.drift))
      {:error, reason} -> shell.error("release parity failed: #{inspect(reason)}")
    end

    System.halt(exit_code(result))
  end

  def compute(tag_manifest, tarball_manifest) when is_map(tag_manifest) and is_map(tarball_manifest) do
    tag_paths = Map.keys(tag_manifest) |> MapSet.new()
    tarball_paths = Map.keys(tarball_manifest) |> MapSet.new()

    missing =
      tag_paths
      |> MapSet.difference(tarball_paths)
      |> MapSet.to_list()
      |> Enum.sort()

    extra =
      tarball_paths
      |> MapSet.difference(tag_paths)
      |> MapSet.to_list()
      |> Enum.sort()

    changed =
      tag_manifest
      |> Enum.reduce([], fn {path, digest}, acc ->
        case Map.fetch(tarball_manifest, path) do
          {:ok, ^digest} -> acc
          {:ok, _other_digest} -> [path | acc]
          :error -> acc
        end
      end)
      |> Enum.sort()

    drift = %{missing: missing, extra: extra, changed: changed}

    if missing == [] and extra == [] and changed == [] do
      {:ok, %{status: :parity, drift: drift}}
    else
      {:drift, %{status: :drift, drift: drift}}
    end
  end

  def exit_code({:ok, _report}), do: 0
  def exit_code({:drift, _report}), do: 2
  def exit_code({:error, _reason}), do: 1

  defp parse_args!(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

    case invalid do
      [] -> {opts, argv}
      [{flag, _value} | _rest] -> Mix.raise("unknown option: #{flag}")
    end
  end

  defp default_loader(version) do
    with {:ok, tag_manifest} <- git_tag_manifest(version),
         {:ok, tarball_manifest} <- hex_tarball_manifest(version) do
      {:ok, {tag_manifest, tarball_manifest}}
    end
  end

  defp git_tag_manifest(version) do
    tag = "v#{version}"
    package_root = "rulestead"

    with {paths_output, 0} <-
           System.cmd("git", ["ls-tree", "-r", "--name-only", tag, package_root],
             cd: repo_root(),
             stderr_to_stdout: true
           ) do
      paths =
        paths_output
        |> String.split("\n", trim: true)
        |> Enum.map(&Path.relative_to(&1, package_root))

      manifest =
        Enum.reduce(paths, %{}, fn relative_path, acc ->
          {contents, 0} =
            System.cmd("git", ["show", "#{tag}:#{package_root}/#{relative_path}"],
              cd: repo_root(),
              stderr_to_stdout: true
            )

          Map.put(acc, relative_path, digest(contents))
        end)

      {:ok, manifest}
    else
      {output, status} -> {:error, {:git_tag_manifest_failed, status, output}}
    end
  end

  defp hex_tarball_manifest(version) do
    url = "https://repo.hex.pm/tarballs/rulestead-#{version}.tar"

    with {:ok, body} <- fetch_binary(url),
         {:ok, outer_entries} <- extract_memory_tar(body),
         {:ok, contents_tar_gz} <- fetch_entry(outer_entries, ~c"contents.tar.gz"),
         {:ok, inner_entries} <- extract_memory_tar(contents_tar_gz, [:compressed]) do
      manifest =
        inner_entries
        |> Enum.reduce(%{}, fn {path, binary}, acc ->
          Map.put(acc, List.to_string(path), digest(binary))
        end)

      {:ok, manifest}
    end
  end

  defp fetch_binary(url) do
    :inets.start()
    :ssl.start()

    case :httpc.request(:get, {String.to_charlist(url), []}, [], [{:body_format, :binary}]) do
      {:ok, {{_http_version, 200, _reason}, _headers, body}} -> {:ok, body}
      {:ok, {{_http_version, status, _reason}, _headers, _body}} -> {:error, {:hex_tarball_status, status}}
      {:error, reason} -> {:error, {:hex_tarball_request_failed, reason}}
    end
  end

  defp extract_memory_tar(binary, opts \\ []) do
    case :erl_tar.extract({:binary, binary}, [:memory | opts]) do
      {:ok, entries} -> {:ok, entries}
      {:error, reason} -> {:error, {:tar_extract_failed, reason}}
    end
  end

  defp fetch_entry(entries, name) do
    case Enum.find(entries, fn {entry_name, _binary} -> entry_name == name end) do
      {_entry_name, binary} -> {:ok, binary}
      nil -> {:error, {:missing_tar_entry, List.to_string(name)}}
    end
  end

  defp digest(binary) do
    :crypto.hash(:sha256, binary)
    |> Base.encode16(case: :lower)
  end

  defp format_drift(drift) do
    "release parity drift detected: missing=#{inspect(drift.missing)} extra=#{inspect(drift.extra)} changed=#{inspect(drift.changed)}"
  end

  defp repo_root do
    Path.expand("..", File.cwd!())
  end
end

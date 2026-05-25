defmodule Rulestead.Test.InstallFixture do
  @moduledoc false

  @tmp_root_prefix "rulestead-install-fixture"
  @normalized_timestamp "TIMESTAMP_"
  @hex_env [{"HEX_HTTP_CONCURRENCY", "1"}, {"HEX_HTTP_TIMEOUT", "120"}]

  @generator_args [
    "phx.new",
    "host_app",
    "--database",
    "postgres",
    "--no-assets",
    "--no-dashboard",
    "--no-mailer",
    "--no-install"
  ]

  @tracked_tree_paths [
    "config/config.exs",
    "config/rulestead.exs",
    "lib/host_app_web/endpoint.ex",
    "lib/host_app_web/router.ex",
    "priv/repo/migrations/TIMESTAMP_create_rulestead_tables.exs"
  ]

  @skip_tree_prefixes ["_build/", "deps/", ".elixir_ls/"]

  defstruct [:app_dir, :tmp_dir, :stdout, :rerun_stdout, :hex_home]

  @type result :: %__MODULE__{
          app_dir: Path.t(),
          tmp_dir: Path.t(),
          stdout: String.t(),
          rerun_stdout: String.t() | nil,
          hex_home: Path.t()
        }

  @spec setup_tmp_app!(keyword()) :: result()
  def setup_tmp_app!(opts \\ []) do
    tmp_dir = create_tmp_dir!()
    app_dir = Path.join(tmp_dir, "host_app")
    hex_home = Path.join(tmp_dir, ".hex")
    run_env = [{"HEX_HOME", hex_home} | @hex_env]
    File.mkdir_p!(hex_home)

    run!("mix", @generator_args, cd: tmp_dir, env: run_env)
    configure_host_dependency!(app_dir)
    configure_host_repo!(app_dir)
    run!("mix", ["deps.get"], cd: app_dir, env: run_env)

    install_args = install_args(opts)
    stdout = run!("mix", install_args, cd: app_dir, env: run_env)

    if Keyword.get(opts, :migrate?, true) do
      run!("mix", ["ecto.create"], cd: app_dir, env: run_env)
      run!("mix", ["ecto.migrate"], cd: app_dir, env: run_env)
    end

    rerun_stdout =
      if Keyword.get(opts, :rerun_install?, false) do
        run!("mix", install_args, cd: app_dir, env: run_env)
      end

    %__MODULE__{
      app_dir: app_dir,
      tmp_dir: tmp_dir,
      stdout: stdout,
      rerun_stdout: rerun_stdout,
      hex_home: hex_home
    }
  end

  @spec cleanup_tmp_app!(result()) :: :ok
  def cleanup_tmp_app!(%__MODULE__{tmp_dir: tmp_dir}) do
    File.rm_rf!(tmp_dir)
    :ok
  end

  @spec normalize_stdout(String.t()) :: String.t()
  def normalize_stdout(stdout) do
    stdout
    |> normalize_line_endings()
    |> normalize_timestamps()
    |> String.split("\n", trim: true)
    |> Enum.filter(fn line ->
      String.starts_with?(line, "copy ") or
        String.starts_with?(line, "write ") or
        String.starts_with?(line, "skip ")
    end)
    |> Enum.join("\n")
    |> then(fn
      "" -> ""
      normalized -> normalized <> "\n"
    end)
  end

  @spec normalize_tree(Path.t()) :: %{Path.t() => String.t()}
  def normalize_tree(app_dir) do
    app_dir
    |> collect_tree_files()
    |> Enum.map(fn relative_path ->
      normalized_path = normalize_path(relative_path)

      contents =
        app_dir
        |> Path.join(relative_path)
        |> File.read!()
        |> normalize_line_endings()
        |> normalize_timestamps()
        |> normalize_generated_secrets()

      {normalized_path, contents}
    end)
    |> Map.new()
  end

  @spec write_normalized_tree!(Path.t(), %{Path.t() => String.t()}) :: :ok
  def write_normalized_tree!(root, tree) do
    File.rm_rf!(root)
    File.mkdir_p!(root)

    Enum.each(tree, fn {relative_path, contents} ->
      path = Path.join(root, relative_path)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
    end)
  end

  @spec read_tree_fixture!(Path.t()) :: %{Path.t() => String.t()}
  def read_tree_fixture!(root) do
    root
    |> collect_tree_files()
    |> Enum.map(fn relative_path ->
      {relative_path, root |> Path.join(relative_path) |> File.read!() |> normalize_line_endings()}
    end)
    |> Map.new()
  end

  @spec tracked_tree_paths() :: [Path.t()]
  def tracked_tree_paths, do: @tracked_tree_paths

  defp create_tmp_dir! do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "#{@tmp_root_prefix}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp_dir)
    tmp_dir
  end

  defp install_args(opts) do
    repo = Keyword.get(opts, :repo, "HostApp.Repo")
    ["rulestead.install", "--yes", "--repo", repo]
  end

  defp configure_host_dependency!(app_dir) do
    mix_path = Path.join(app_dir, "mix.exs")
    mix_contents = File.read!(mix_path)
    rulestead_path = File.cwd!()
    rulestead_admin_path = Path.join(Path.dirname(rulestead_path), "rulestead_admin")

    updated_mix =
      String.replace(
        mix_contents,
        "defp deps do\n    [",
        "defp deps do\n    [\n      {:rulestead, path: #{inspect(rulestead_path)}},\n      {:rulestead_admin, path: #{inspect(rulestead_admin_path)}},"
      )

    File.write!(mix_path, updated_mix)
  end

  defp configure_host_repo!(app_dir) do
    db_username =
      System.get_env("PGUSER") || System.get_env("USER") || "postgres"

    Enum.each(["dev.exs", "test.exs"], fn config_name ->
      path = Path.join([app_dir, "config", config_name])
      contents = File.read!(path)
      database_name = unique_database_name(config_name)

      updated_contents =
        contents
        |> then(&Regex.replace(~r/database: .+/, &1, ~s(database: "#{database_name}",)))
        |> then(&Regex.replace(~r/username: "[^\"]+"/, &1, ~s(username: "#{db_username}")))

      File.write!(path, updated_contents)
    end)
  end

  defp unique_database_name(config_name) do
    base =
      config_name
      |> Path.rootname()
      |> String.replace(~r/[^a-z0-9_]/, "_")

    "rulestead_install_#{base}_#{System.unique_integer([:positive])}"
  end

  defp collect_tree_files(root) do
    root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, root))
    |> Enum.reject(fn relative_path ->
      Enum.any?(@skip_tree_prefixes, &String.starts_with?(relative_path, &1))
    end)
    |> Enum.filter(fn relative_path ->
      normalize_path(relative_path) in @tracked_tree_paths
    end)
    |> Enum.sort()
  end

  defp normalize_path(path) do
    path
    |> String.replace(~r/\d{14}_/, @normalized_timestamp)
  end

  defp normalize_timestamps(contents) do
    String.replace(contents, ~r/\d{14}/, String.trim_trailing(@normalized_timestamp, "_"))
  end

  defp normalize_line_endings(contents) do
    String.replace(contents, "\r\n", "\n")
  end

  defp normalize_generated_secrets(contents) do
    Regex.replace(~r/signing_salt: "[^"]+"/, contents, ~s(signing_salt: "SIGNING_SALT"))
  end

  defp run!(command, args, opts) do
    {output, status} = System.cmd(command, args, Keyword.put(opts, :stderr_to_stdout, true))

    if status == 0 do
      output
    else
      raise """
      command failed: #{command} #{Enum.join(args, " ")}
      #{output}
      """
    end
  end
end

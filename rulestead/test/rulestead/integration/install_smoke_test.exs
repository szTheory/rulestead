defmodule Rulestead.Integration.InstallSmokeTest do
  use ExUnit.Case, async: false

  @moduletag timeout: 300_000

  test "fresh host app can install and migrate rulestead schema" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "rulestead-smoke-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    app_dir = Path.join(tmp_dir, "host_app")

    {generator_output, generator_status} =
      System.cmd(
        "mix",
        [
          "phx.new",
          "host_app",
          "--database",
          "postgres",
          "--no-assets",
          "--no-dashboard",
          "--no-mailer",
          "--no-install"
        ],
        cd: tmp_dir,
        stderr_to_stdout: true
      )

    assert generator_status == 0, generator_output

    configure_host_dependency(app_dir)
    configure_host_repo(app_dir)

    {hex_output, hex_status} =
      System.cmd("mix", ["local.hex", "--force"], cd: app_dir, stderr_to_stdout: true)

    assert hex_status == 0, hex_output

    {rebar_output, rebar_status} =
      System.cmd("mix", ["local.rebar", "--force"], cd: app_dir, stderr_to_stdout: true)

    assert rebar_status == 0, rebar_output

    {deps_output, deps_status} =
      System.cmd("mix", ["deps.get"], cd: app_dir, stderr_to_stdout: true)

    assert deps_status == 0, deps_output

    {install_output, install_status} =
      System.cmd("mix", ["rulestead.install", "--repo", "HostApp.Repo"],
        cd: app_dir,
        stderr_to_stdout: true
      )

    assert install_status == 0, install_output

    {create_output, create_status} =
      System.cmd("mix", ["ecto.create"], cd: app_dir, stderr_to_stdout: true)

    assert create_status == 0, create_output

    {migrate_output, migrate_status} =
      System.cmd("mix", ["ecto.migrate"], cd: app_dir, stderr_to_stdout: true)

    assert migrate_status == 0, migrate_output

    assert File.exists?(Path.join(app_dir, "config/rulestead.exs"))

    assert File.exists?(
             Path.join(
               app_dir,
               "priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs"
             )
           )

    assert File.exists?(
             Path.join(
               app_dir,
               "priv/repo/migrations/20260423020200_seed_default_environments.exs"
             )
           )

    assert File.read!(Path.join(app_dir, "config/config.exs")) =~
             ~s(import_config "rulestead.exs")

    {probe_output, probe_status} =
      System.cmd("mix", ["run", "-e", probe_script()], cd: app_dir, stderr_to_stdout: true)

    assert probe_status == 0, probe_output
    assert probe_output =~ "tables=audit_events,environments,flag_environments,flags,rulesets"
    assert probe_output =~ "envs=development,production,staging,test"
  end

  defp configure_host_dependency(app_dir) do
    mix_path = Path.join(app_dir, "mix.exs")
    mix_contents = File.read!(mix_path)

    updated_mix =
      String.replace(
        mix_contents,
        "defp deps do\n    [",
        "defp deps do\n    [\n      {:rulestead, path: #{inspect(File.cwd!())}},"
      )

    File.write!(mix_path, updated_mix)
  end

  defp configure_host_repo(app_dir) do
    dev_config_path = Path.join(app_dir, "config/dev.exs")
    dev_config = File.read!(dev_config_path)
    database_name = "rulestead_install_smoke_#{System.unique_integer([:positive])}"

    updated_config =
      Regex.replace(~r/database: "[^\"]+"/, dev_config, ~s(database: "#{database_name}"))

    File.write!(dev_config_path, updated_config)
  end

  defp probe_script do
    """
    alias HostApp.Repo

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Repo.start_link()

    {:ok, %{rows: table_rows}} =
      Ecto.Adapters.SQL.query(
        Repo,
        "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('flags', 'environments', 'flag_environments', 'rulesets', 'audit_events') order by table_name",
        []
      )

    {:ok, %{rows: env_rows}} =
      Ecto.Adapters.SQL.query(Repo, "select key from environments order by key", [])

    IO.puts("tables=" <> Enum.map_join(table_rows, ",", &hd/1))
    IO.puts("envs=" <> Enum.map_join(env_rows, ",", &hd/1))
    """
  end
end

defmodule Rulestead.Integration.InstallSmokeTest do
  use ExUnit.Case, async: false

  import Rulestead.Test.InstallFixture

  @moduletag timeout: 300_000

  test "fresh host app installs, migrates, and boots with the phase 5 host seam" do
    result = setup_tmp_app!()
    on_exit(fn -> cleanup_tmp_app!(result) end)

    app_dir = result.app_dir
    install_output = normalize_stdout(result.stdout)

    assert install_output =~ "write config/rulestead.exs"
    assert install_output =~ "write config/config.exs import"
    assert install_output =~ "write lib/host_app_web/endpoint.ex plug"
    assert install_output =~ "write lib/host_app_web/router.ex admin helper"
    assert install_output =~ "write lib/host_app_web/router.ex admin mount"

    config_config = File.read!(Path.join(app_dir, "config/config.exs"))
    endpoint = File.read!(Path.join(app_dir, "lib/host_app_web/endpoint.ex"))
    router = File.read!(Path.join(app_dir, "lib/host_app_web/router.ex"))
    rulestead_config = File.read!(Path.join(app_dir, "config/rulestead.exs"))

    assert config_config =~ ~s(import_config "rulestead.exs")
    assert endpoint =~ "plug Rulestead.Plug"
    assert router =~ "use RulesteadAdmin.Router"
    assert router =~ ~s(rulestead_admin "/flags")
    assert rulestead_config =~ "middlewares: [{Rulestead.Oban.Middleware, []}]"

    probe_output = run_probe!(result)
    assert probe_output =~ "tables=audit_events,environments,flag_environments,flags,rulesets"
    assert probe_output =~ "envs=development,production,staging,test"
    assert probe_output =~ "admin_mount=true"
    assert probe_output =~ "plug_wired=true"
    assert probe_output =~ "oban_middleware=true"
    assert probe_output =~ "app_started=true"
  end

  defp run_probe!(result) do
    {probe_output, probe_status} =
      System.cmd("mix", ["run", "-e", probe_script()],
        cd: result.app_dir,
        stderr_to_stdout: true,
        env: [{"HEX_HOME", result.hex_home}]
      )

    assert probe_status == 0, probe_output
    probe_output
  end

  defp probe_script do
    """
    alias HostApp.Repo

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    case Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    {:ok, _} = Application.ensure_all_started(:host_app)

    {:ok, %{rows: table_rows}} =
      Ecto.Adapters.SQL.query(
        Repo,
        "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('flags', 'environments', 'flag_environments', 'rulesets', 'audit_events') order by table_name",
        []
      )

    {:ok, %{rows: env_rows}} =
      Ecto.Adapters.SQL.query(Repo, "select key from environments order by key", [])

    endpoint_source = File.read!("lib/host_app_web/endpoint.ex")
    router_source = File.read!("lib/host_app_web/router.ex")
    rulestead_config = File.read!("config/rulestead.exs")

    IO.puts("tables=" <> Enum.map_join(table_rows, ",", &hd/1))
    IO.puts("envs=" <> Enum.map_join(env_rows, ",", &hd/1))
    IO.puts("admin_mount=" <> to_string(String.contains?(router_source, ~s(rulestead_admin "/flags"))))
    IO.puts("plug_wired=" <> to_string(String.contains?(endpoint_source, "plug Rulestead.Plug")))
    IO.puts("oban_middleware=" <> to_string(String.contains?(rulestead_config, "Rulestead.Oban.Middleware")))
    IO.puts("app_started=true")
    """
  end
end

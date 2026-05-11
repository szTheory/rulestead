defmodule Rulestead.Mix.Tasks.RulesteadInstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Rulestead.Config
  alias Rulestead.Install.{ConfigWriter, MigrationWriter, RepoLocator}

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "rulestead-install-#{System.unique_integer([:positive])}")

    previous_repos = Application.get_env(:rulestead, :ecto_repos)

    File.mkdir_p!(Path.join(tmp_dir, "config"))

    File.write!(
      Path.join(tmp_dir, "config/config.exs"),
      """
      import Config

      config :my_app, Oban,
        repo: MyApp.Repo,
        plugins: [],
        queues: [default: 10]
      """
    )

    File.mkdir_p!(Path.join(tmp_dir, "priv/repo/migrations"))
    File.mkdir_p!(Path.join(tmp_dir, "lib/my_app_web"))

    File.write!(
      Path.join(tmp_dir, "lib/my_app_web/endpoint.ex"),
      """
      defmodule MyAppWeb.Endpoint do
        use Phoenix.Endpoint, otp_app: :my_app

        plug Plug.RequestId
        plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
        plug MyAppWeb.Router
      end
      """
    )

    File.write!(
      Path.join(tmp_dir, "lib/my_app_web/router.ex"),
      """
      defmodule MyAppWeb.Router do
        use MyAppWeb, :router

        pipeline :browser do
          plug :accepts, ["html"]
          plug :fetch_session
          plug :fetch_live_flash
          plug :put_root_layout, html: {MyAppWeb.Layouts, :root}
          plug :protect_from_forgery
          plug :put_secure_browser_headers
        end

        scope "/", MyAppWeb do
          pipe_through :browser
        end
      end
      """
    )

    Application.put_env(:rulestead, :ecto_repos, [MyApp.Repo])

    on_exit(fn ->
      File.rm_rf!(tmp_dir)

      case previous_repos do
        nil -> Application.delete_env(:rulestead, :ecto_repos)
        repos -> Application.put_env(:rulestead, :ecto_repos, repos)
      end
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "requires an explicit repo when multiple repos are configured" do
    assert {:error, error} =
             RepoLocator.resolve(repos: [MyApp.Repo, AnotherApp.Repo])

    assert error.type == :repo_ambiguous
  end

  test "fails when no repo is configured" do
    assert {:error, error} = RepoLocator.resolve(repos: [])
    assert error.type == :repo_not_configured
  end

  test "copies migrations idempotently", %{tmp_dir: tmp_dir} do
    target = Path.join(tmp_dir, "priv/repo/migrations")

    assert {:ok, first_messages} =
             MigrationWriter.copy_migrations(MyApp.Repo, migrations_path: target)

    assert Enum.any?(first_messages, &String.starts_with?(&1, "copy "))

    assert {:ok, second_messages} =
             MigrationWriter.copy_migrations(MyApp.Repo, migrations_path: target)

    assert Enum.all?(second_messages, &String.starts_with?(&1, "skip "))
  end

  test "writes rulestead config and injects import idempotently", %{tmp_dir: tmp_dir} do
    config_path = Path.join(tmp_dir, "config")

    assert {:ok, first_messages} = ConfigWriter.write(MyApp.Repo, config_path: config_path)
    assert Enum.any?(first_messages, &String.contains?(&1, "rulestead.exs"))

    rulestead_config = File.read!(Path.join(config_path, "rulestead.exs"))
    assert rulestead_config =~ "MyApp.Repo"

    updated_config = File.read!(Path.join(config_path, "config.exs"))
    assert updated_config =~ ~s(import_config "rulestead.exs")

    assert {:ok, second_messages} = ConfigWriter.write(MyApp.Repo, config_path: config_path)

    assert Enum.all?(
             second_messages,
             &(String.starts_with?(&1, "skip ") or String.starts_with?(&1, "write "))
           )

    assert File.read!(Path.join(config_path, "config.exs")) == updated_config
  end

  test "validates explicit phase 5 seam settings through NimbleOptions defaults" do
    defaults = Config.defaults()

    assert defaults[:environment_key] == "dev"
    assert defaults[:plug][:context_assign] == :rulestead_context
    assert defaults[:live_view][:assign_flags_mode] == :enabled
    assert defaults[:oban][:middlewares] == [{Rulestead.Oban.Middleware, []}]
    assert defaults[:runtime][:api] == Rulestead.Runtime

    assert {:ok, validated} =
             Config.validate(
               environment_key: "prod",
               plug: [context_assign: :host_context],
               live_view: [assign_flags_mode: :variant],
               oban: [enabled: false]
             )

    assert validated[:environment_key] == "prod"
    assert validated[:plug][:context_assign] == :host_context
    assert validated[:live_view][:assign_flags_mode] == :variant
    assert validated[:oban][:enabled] == false

    assert {:error, error} =
             Config.validate(live_view: [assign_flags_mode: :invalid_mode])

    assert Exception.message(error) =~ "assign_flags_mode"
  end

  test "mix task writes deterministic host wiring and reruns idempotently", %{tmp_dir: tmp_dir} do
    previous = File.cwd!()
    File.cd!(tmp_dir)

    first_output =
      capture_io(fn ->
        Mix.Tasks.Rulestead.Install.run(["--yes", "--repo", "MyApp.Repo"])
      end)

    installed_files = snapshot_files(tmp_dir)

    second_output =
      capture_io(fn ->
        Mix.Task.reenable("rulestead.install")
        Mix.Tasks.Rulestead.Install.run(["--yes", "--repo", "MyApp.Repo"])
      end)

    File.cd!(previous)

    assert output_lines(first_output) == [
             "copy priv/repo/migrations/.keep",
             "copy priv/repo/migrations/20260423020100_create_rulestead_authoring_tables.exs",
             "copy priv/repo/migrations/20260423020200_seed_default_environments.exs",
             "copy priv/repo/migrations/20260423020300_create_rulestead_runtime_snapshots.exs",
             "write config/rulestead.exs",
             "write config/config.exs import",
             "write lib/my_app_web/endpoint.ex plug",
             "write lib/my_app_web/router.ex admin helper",
             "write lib/my_app_web/router.ex admin mount",
             "write config/config.exs Oban middlewares"
           ]

    assert Enum.all?(output_lines(second_output), &String.starts_with?(&1, "skip "))
    assert snapshot_files(tmp_dir) == installed_files

    endpoint = File.read!(Path.join(tmp_dir, "lib/my_app_web/endpoint.ex"))
    assert endpoint =~ "plug Rulestead.Plug"
    assert endpoint =~ "plug MyAppWeb.Router"

    router = File.read!(Path.join(tmp_dir, "lib/my_app_web/router.ex"))
    assert router =~ "use RulesteadAdmin.Router"
    assert router =~ ~s(rulestead_admin "/flags")

    config = File.read!(Path.join(tmp_dir, "config/config.exs"))
    assert config =~ ~s(import_config "rulestead.exs")
    assert config =~ "middlewares: [{Rulestead.Oban.Middleware, []}]"

    rulestead_config = File.read!(Path.join(tmp_dir, "config/rulestead.exs"))
    assert rulestead_config =~ "environment_key: \"dev\""
    assert rulestead_config =~ "api: Rulestead.Runtime"
  end

  defp output_lines(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp snapshot_files(tmp_dir) do
    %{
      endpoint: File.read!(Path.join(tmp_dir, "lib/my_app_web/endpoint.ex")),
      router: File.read!(Path.join(tmp_dir, "lib/my_app_web/router.ex")),
      config: File.read!(Path.join(tmp_dir, "config/config.exs")),
      rulestead_config: File.read!(Path.join(tmp_dir, "config/rulestead.exs"))
    }
  end
end

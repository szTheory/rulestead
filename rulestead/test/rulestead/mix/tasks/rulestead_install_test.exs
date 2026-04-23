defmodule Rulestead.Mix.Tasks.RulesteadInstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Rulestead.Install.{ConfigWriter, MigrationWriter, RepoLocator}

  setup do
    tmp_dir =
      Path.join(System.tmp_dir!(), "rulestead-install-#{System.unique_integer([:positive])}")

    previous_repos = Application.get_env(:rulestead, :ecto_repos)

    File.mkdir_p!(Path.join(tmp_dir, "config"))
    File.write!(Path.join(tmp_dir, "config/config.exs"), "import Config\n")
    File.mkdir_p!(Path.join(tmp_dir, "priv/repo/migrations"))
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

  test "mix task only touches migrations and config files", %{tmp_dir: tmp_dir} do
    previous = File.cwd!()
    File.cd!(tmp_dir)

    output =
      capture_io(fn ->
        Mix.Tasks.Rulestead.Install.run(["--repo", "MyApp.Repo"])
      end)

    File.cd!(previous)

    assert output =~ "config/rulestead.exs"
    assert output =~ "priv/repo/migrations"
    refute File.exists?(Path.join(tmp_dir, "lib/my_app_web/router.ex"))
    refute File.exists?(Path.join(tmp_dir, "lib/my_app_web/endpoint.ex"))
    refute File.exists?(Path.join(tmp_dir, "lib/my_app/application.ex"))
  end
end

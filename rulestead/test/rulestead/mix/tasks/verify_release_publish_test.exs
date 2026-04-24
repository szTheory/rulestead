defmodule Rulestead.Mix.Tasks.VerifyReleasePublishTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify.ReleasePublish

  defmodule FixtureDouble do
    def setup_core_consumer!(tmp_dir, version, opts) do
      send(opts[:notify], {:fixture, :core, version})

      %{
        name: :rulestead,
        app_dir: Path.join(tmp_dir, "core_consumer"),
        deps: [%{app: :rulestead, requirement: "~> #{version}"}],
        checks: [
          %{cmd: "mix", args: ["deps.get"]},
          %{cmd: "mix", args: ["test"]}
        ]
      }
    end

    def setup_admin_consumer!(tmp_dir, version, opts) do
      send(opts[:notify], {:fixture, :admin, version})

      %{
        name: :rulestead_admin,
        app_dir: Path.join(tmp_dir, "admin_consumer"),
        deps: [
          %{app: :rulestead, requirement: "~> #{version}"},
          %{app: :rulestead_admin, requirement: "~> #{version}"}
        ],
        checks: [
          %{cmd: "mix", args: ["deps.get"]},
          %{cmd: "mix", args: ["compile"]}
        ],
        contract: %{
          mount_path: "/flags",
          session_keys: [
            "current_actor",
            "rulestead_admin_environments",
            "rulestead_admin_last_env"
          ],
          env_query_param: "env"
        }
      }
    end
  end

  test "requires an explicit published version" do
    assert_raise Mix.Error, ~r/published version/, fn ->
      ReleasePublish.run([])
    end

    assert_raise Mix.Error, ~r/published version/, fn ->
      ReleasePublish.validate_version!("path:../rulestead")
    end
  end

  test "plans published artifact verification for both sibling packages and HexDocs" do
    plan = ReleasePublish.plan("0.1.0", fixture_module: FixtureDouble, notify: self())

    assert plan.version == "0.1.0"
    assert plan.hexdocs_url == "https://hexdocs.pm/rulestead/0.1.0"
    assert Enum.map(plan.consumers, & &1.name) == [:rulestead, :rulestead_admin]
    assert_received {:fixture, :core, "0.1.0"}
    assert_received {:fixture, :admin, "0.1.0"}

    admin = Enum.find(plan.consumers, &(&1.name == :rulestead_admin))
    assert admin.contract.mount_path == "/flags"
    assert admin.contract.session_keys == [
             "current_actor",
             "rulestead_admin_environments",
             "rulestead_admin_last_env"
           ]
    assert admin.contract.env_query_param == "env"
  end

  test "rejects local path dependency fallbacks and verifies HexDocs reachability" do
    bad_plan = %{
      version: "0.1.0",
      hexdocs_url: "https://hexdocs.pm/rulestead/0.1.0",
      consumers: [
        %{
          name: :rulestead,
          app_dir: "/tmp/core",
          deps: [%{app: :rulestead, path: "../rulestead"}],
          checks: []
        }
      ]
    }

    assert {:error, {:local_path_dependency, :rulestead}} =
             ReleasePublish.verify(bad_plan,
               http_get: fn _url -> {:ok, 200} end,
               command_runner: fn _cmd, _args, _opts -> {"", 0} end
             )

    good_plan = ReleasePublish.plan("0.1.0", fixture_module: FixtureDouble, notify: self())

    assert {:ok, report} =
             ReleasePublish.verify(good_plan,
               http_get: fn "https://hexdocs.pm/rulestead/0.1.0" -> {:ok, 200} end,
               command_runner: fn _cmd, _args, _opts -> {"", 0} end
             )

    assert report.hexdocs == {:ok, 200}
    assert Enum.map(report.consumers, & &1.name) == [:rulestead, :rulestead_admin]
  end
end

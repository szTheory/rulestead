defmodule Rulestead.Mix.Tasks.VerifyReleasePublishTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Verify.ReleasePublish
  alias Rulestead.Test.ReleasePublishFixture

  @root_readme_path Path.expand("../../../../../README.md", __DIR__)
  @runtime_readme_path Path.expand("../../../../README.md", __DIR__)
  @admin_readme_path Path.expand("../../../../../rulestead_admin/README.md", __DIR__)

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
          package_order: [:rulestead, :rulestead_admin],
          mount_path: "/flags",
          session_keys: [
            "current_actor",
            "rulestead_admin_environments",
            "rulestead_admin_last_env"
          ],
          env_query_param: "env",
          runtime_config: %{
            environment_key: "dev",
            api: Rulestead.Runtime,
            notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
            pubsub: AdminConsumer.PubSub,
            pubsub_topic: "rulestead:runtime_snapshot"
          }
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
    assert admin.contract.package_order == [:rulestead, :rulestead_admin]
    assert admin.contract.mount_path == "/flags"

    assert admin.contract.session_keys == [
             "current_actor",
             "rulestead_admin_environments",
             "rulestead_admin_last_env"
           ]

    assert admin.contract.env_query_param == "env"

    assert admin.contract.runtime_config == %{
             environment_key: "dev",
             api: Rulestead.Runtime,
             notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
             pubsub: AdminConsumer.PubSub,
             pubsub_topic: "rulestead:runtime_snapshot"
           }
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

  test "shared fixture helper writes a fresh mix new consumer with versioned Hex deps" do
    tmp_dir = tmp_dir()
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    consumer =
      ReleasePublishFixture.setup_core_consumer!(tmp_dir, "0.1.0",
        generator_runner: &generator_runner/4
      )

    mix_exs = File.read!(Path.join(consumer.app_dir, "mix.exs"))

    assert mix_exs =~ ~s({:rulestead, "~> 0.1.0"})
    refute mix_exs =~ "path:"
    assert consumer.deps == [%{app: :rulestead, requirement: "~> 0.1.0"}]
  end

  test "shared fixture helper encodes the admin mount, session, and env-query contract" do
    tmp_dir = tmp_dir()
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    consumer =
      ReleasePublishFixture.setup_admin_consumer!(tmp_dir, "0.1.0",
        generator_runner: &generator_runner/4
      )

    mix_exs = File.read!(Path.join(consumer.app_dir, "mix.exs"))
    router = File.read!(Path.join(consumer.app_dir, "lib/admin_consumer_web/router.ex"))

    contract =
      File.read!(Path.join(consumer.app_dir, "config/rulestead_release_publish_contract.exs"))

    assert mix_exs =~ ~s({:rulestead, "~> 0.1.0"})
    assert mix_exs =~ ~s({:rulestead_admin, "~> 0.1.0"})
    refute mix_exs =~ "path:"
    assert router =~ "use RulesteadAdmin.Router"
    assert router =~ ~s(scope "/admin" do)
    assert router =~ ~s(rulestead_admin "/flags", policy: AdminConsumer.RulesteadPolicy)

    assert File.exists?(
             Path.join(consumer.app_dir, "lib/admin_consumer/rulestead_policy.ex")
           )
    assert contract =~ "package_order: [:rulestead, :rulestead_admin]"
    assert contract =~ ~s(mount_path: "/flags")
    assert contract =~ ~s(env_query_param: "env")
    assert contract =~ ~s(environment_key: "dev")
    assert contract =~ "Rulestead.Runtime.Notifier.PhoenixPubSub"
    assert contract =~ "pubsub: AdminConsumer.PubSub"
    assert contract =~ ~s(pubsub_topic: "rulestead:runtime_snapshot")
    assert consumer.contract.package_order == [:rulestead, :rulestead_admin]
    assert consumer.contract.mount_path == "/flags"

    assert consumer.contract.session_keys == [
             "current_actor",
             "rulestead_admin_environments",
             "rulestead_admin_last_env"
           ]

    assert consumer.contract.env_query_param == "env"

    assert consumer.contract.runtime_config == %{
             environment_key: "dev",
             api: Rulestead.Runtime,
             notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
             pubsub: AdminConsumer.PubSub,
             pubsub_topic: "rulestead:runtime_snapshot"
           }
  end

  @published_smoke_version "0.1.1"

  test "admin consumer fixture compiles against published Hex packages" do
    tmp_dir = tmp_dir()
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    consumer =
      ReleasePublishFixture.setup_admin_consumer!(tmp_dir, @published_smoke_version)

    for check <- consumer.checks do
      {output, status} =
        System.cmd(check.cmd, check.args, cd: consumer.app_dir, stderr_to_stdout: true)

      assert status == 0, """
      #{check.cmd} #{Enum.join(check.args, " ")} failed in #{consumer.app_dir}:
      #{output}
      """
    end
  end

  test "verify.release_publish can plan with the shared fixture helper" do
    tmp_dir = tmp_dir()
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    plan =
      ReleasePublish.plan("0.1.0",
        fixture_module: ReleasePublishFixture,
        tmp_dir: tmp_dir,
        generator_runner: &generator_runner/4
      )

    assert Enum.map(plan.consumers, & &1.name) == [:rulestead, :rulestead_admin]

    assert Enum.all?(plan.consumers, fn consumer ->
             Enum.all?(consumer.deps, &(Map.get(&1, :path) == nil))
           end)
  end

  test "published release verification still depends on lifecycle doc discoverability" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)

    assert root_readme =~ "guides/flows/flag-lifecycle.md"
    assert root_readme =~ "RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh"
    refute root_readme =~ "flag_live/form_test"
    refute root_readme =~ "admin_mount_test"
    assert runtime_readme =~ "flag-lifecycle"
    assert admin_readme =~ "mounted companion"
    assert admin_readme =~ "fails closed"
    assert admin_readme =~ "fallback-only convenience"
  end

  test "published release verification keeps guarded rollout support truth bounded" do
    root_readme = File.read!(@root_readme_path)
    runtime_readme = File.read!(@runtime_readme_path)
    admin_readme = File.read!(@admin_readme_path)

    assert root_readme =~ "guarded rollout foundations"
    assert root_readme =~ "host-supplied normalized guardrail facts"
    assert root_readme =~ "fail closed"
    assert root_readme =~ "pending_data"
    assert root_readme =~ "held"
    assert root_readme =~ "rollback_triggered"
    assert root_readme =~ "audited hold and rollback"

    assert root_readme =~
             "RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh"

    assert runtime_readme =~ "host-owned metrics provider seam"
    assert runtime_readme =~ "deterministic sticky rollout decisions"
    assert runtime_readme =~ "audited hold and rollback"
    assert runtime_readme =~ "no metrics ingestion"
    assert runtime_readme =~ "no dashboards"
    assert runtime_readme =~ "no statistics engine"
    assert runtime_readme =~ "no built-in provider adapters"

    assert admin_readme =~ "mounted companion status contract"
    assert admin_readme =~ "reads core guardrail status and audit truth"
    assert admin_readme =~ "thresholds, freshness, and reasons"
    assert admin_readme =~ "fails closed on missing prerequisites"
    assert admin_readme =~ "not a standalone admin"

    refute root_readme =~ "built-in observability"
    refute runtime_readme =~ "real-time dashboards"
    refute admin_readme =~ "standalone rulestead_admin"
  end

  defp tmp_dir do
    path =
      Path.join(
        System.tmp_dir!(),
        "release-publish-fixture-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(path)
    path
  end

  defp generator_runner("mix", ["new", app_name | _rest], cd, _opts) do
    app_dir = Path.join(cd, app_name)
    File.mkdir_p!(app_dir)

    File.write!(Path.join(app_dir, "mix.exs"), minimal_mix_exs(module_name(app_name)))
    :ok
  end

  defp generator_runner("mix", ["phx.new", app_name | _rest], cd, _opts) do
    app_dir = Path.join(cd, app_name)
    router_path = Path.join([app_dir, "lib", "#{app_name}_web", "router.ex"])

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.join(app_dir, "config"))

    File.write!(Path.join(app_dir, "mix.exs"), minimal_mix_exs(module_name(app_name)))

    File.write!(
      router_path,
      """
      defmodule #{module_name(app_name)}Web.Router do
        use #{module_name(app_name)}Web, :router

        pipeline :browser do
          plug :fetch_session
        end
      end
      """
    )

    :ok
  end

  defp minimal_mix_exs(module_name) do
    """
    defmodule #{module_name}.MixProject do
      use Mix.Project

      def project do
        [app: :#{Macro.underscore(module_name)}, version: "0.1.0", deps: deps()]
      end

      def application do
        [extra_applications: [:logger]]
      end

      defp deps do
        []
      end
    end
    """
  end

  defp module_name(app_name) do
    app_name
    |> Macro.camelize()
  end
end

defmodule Rulestead.Runtime.ClusterRefreshTest do
  use ExUnit.Case, async: false

  alias Rulestead.Context
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.ClusterCase

  test "two runtime nodes converge on the newer snapshot version after one invalidation" do
    environment_key = "cluster-#{System.unique_integer([:positive])}"
    cluster = ClusterCase.setup_cluster!(environment_key)
    on_exit(fn -> ClusterCase.teardown_cluster(cluster) end)

    context = Context.new(actor: %{key: "user-1"})

    assert {:ok, true} = Rulestead.Runtime.enabled?(environment_key, "checkout-redesign", context)
    assert :ok =
             ClusterCase.assert_eventually(fn ->
               match?({:ok, true}, ClusterCase.remote_enabled?(cluster.peer_node, environment_key, context))
             end)

    version_two = ClusterCase.publish_ruleset_version(environment_key, false)
    started_at = System.monotonic_time(:millisecond)

    Control.publish!(cluster.pubsub_name, environment_key, version_two.version)

    assert :ok =
             ClusterCase.assert_eventually(fn ->
               local_ready? =
                 match?({:ok, false}, Rulestead.Runtime.enabled?(environment_key, "checkout-redesign", context))

               remote_ready? =
                 match?({:ok, false}, ClusterCase.remote_enabled?(cluster.peer_node, environment_key, context))

               local_ready? and remote_ready?
             end)

    elapsed_ms = System.monotonic_time(:millisecond) - started_at

    assert elapsed_ms < ClusterCase.convergence_timeout_ms()

    assert %{
             environments: [
               %{environment_key: ^environment_key, snapshot_version: local_version} | _
             ]
           } = Rulestead.Runtime.diagnostics()

    assert %{environments: remote_environments} = ClusterCase.remote_diagnostics(cluster.peer_node)
    remote_environment = Enum.find(remote_environments, &(&1.environment_key == environment_key))

    assert local_version == version_two.version
    assert remote_environment.snapshot_version == version_two.version
  end
end

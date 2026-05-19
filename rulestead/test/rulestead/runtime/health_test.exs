defmodule Rulestead.Runtime.HealthTest do
  use ExUnit.Case, async: false

  alias Rulestead.Runtime.{Cache, Health, Snapshot}

  setup do
    original_runtime = Application.get_env(:rulestead, :runtime)
    original_host = Application.get_env(:rulestead, :host)
    original_redis = Application.get_env(:rulestead, :redis)
    original_repo = Application.get_env(:rulestead, Rulestead.Repo)

    Application.delete_env(:rulestead, :runtime)
    Application.delete_env(:rulestead, :host)
    Application.put_env(:rulestead, :redis, enabled: false)
    Application.delete_env(:rulestead, Rulestead.Repo)

    environment_key = "health-#{System.unique_integer([:positive])}"
    snapshot = published_snapshot(environment_key)

    {:ok, compiled} = Snapshot.compile(snapshot)
    {:ok, _applied} = Cache.apply(compiled)

    on_exit(fn ->
      Cache.reset(environment_key)
      restore_env(:runtime, original_runtime)
      restore_env(:host, original_host)
      restore_env(:redis, original_redis)
      restore_repo_env(original_repo)
    end)

    %{environment_key: environment_key}
  end

  test "current-node health reports bounded freshness, latency, and adapter rows", %{
    environment_key: environment_key
  } do
    assert %{node: current_node, topology_scope: :current_node, peer_nodes: [], environments: environments} =
             Health.current()

    assert current_node == node()

    assert [%{environment_key: ^environment_key} = environment] = environments
    assert environment.snapshot_version == 9
    assert environment.cache_age_ms >= 0
    assert environment.sync_latency_ms >= 4_500
    assert environment.sync_latency_ms < 6_000
    assert environment.refresh_status == :ready
    assert environment.refresh_worker_status == %{attempt: 0, next_backoff_ms: 0, refresh_status: :ready}
    assert environment.adapter_health.repo == %{configured?: false, status: :not_configured}
    assert environment.adapter_health.redis == %{configured?: false, status: :not_configured}
    assert environment.adapter_health.pubsub == %{configured?: false, status: :not_configured}

    refute Map.has_key?(environment, :metadata)
    refute Map.has_key?(environment, :published_at)
    refute Map.has_key?(environment, :applied_at)
    refute Map.has_key?(environment, :applied_monotonic_ms)
  end

  test "peer topology stays explicit host input instead of implicit discovery", %{
    environment_key: environment_key
  } do
    peer_snapshot = %{
      node: :"peer@node",
      topology_scope: :peer_snapshot,
      environments: [%{environment_key: environment_key, refresh_status: :ready}]
    }

    assert %{topology_scope: :current_node, peer_nodes: []} = Health.current()

    assert %{topology_scope: :host_provided, peer_nodes: [^peer_snapshot]} =
             Health.current(peer_nodes: [peer_snapshot])
  end

  test "host-provided peer module feeds the public infrastructure health seam" do
    previous_runtime = Application.get_env(:rulestead, :runtime)

    Application.put_env(:rulestead, :runtime,
      Keyword.merge(previous_runtime || [], health_peer_provider: __MODULE__.PeerProvider)
    )

    on_exit(fn -> restore_env(:runtime, previous_runtime) end)

    assert %{topology_scope: :host_provided, peer_nodes: [peer]} = Rulestead.infrastructure_health()
    assert peer.node == :"peer@node"
    assert [%{environment_key: "health-provider", refresh_status: :ready}] = peer.environments
  end

  test "public facade matches the runtime health projection", %{environment_key: environment_key} do
    assert Rulestead.infrastructure_health() == Health.current()

    assert %{environments: [%{environment_key: ^environment_key} = environment]} =
             Rulestead.infrastructure_health()

    assert Map.has_key?(environment, :refresh_worker_status)
    refute Map.has_key?(environment, :metadata)
  end

  defp restore_env(key, nil), do: Application.delete_env(:rulestead, key)
  defp restore_env(key, value), do: Application.put_env(:rulestead, key, value)

  defp restore_repo_env(nil), do: Application.delete_env(:rulestead, Rulestead.Repo)
  defp restore_repo_env(value), do: Application.put_env(:rulestead, Rulestead.Repo, value)

  defmodule PeerProvider do
    @behaviour Rulestead.Runtime.HealthPeerProvider

    @impl true
    def peer_nodes do
      [
        %{
          node: :"peer@node",
          topology_scope: :peer_snapshot,
          environments: [%{environment_key: "health-provider", refresh_status: :ready}]
        }
      ]
    end
  end

  defp published_snapshot(environment_key) do
    now = DateTime.utc_now()

    payload = %{
      schema_version: 1,
      environment_key: environment_key,
      generated_at: DateTime.add(now, -5, :second),
      flags: %{
        "checkout-redesign" => %{
          flag: %{key: "checkout-redesign", default_value: %{value: false}},
          environment: %{key: environment_key},
          flag_environment: %{key: "checkout-redesign:#{environment_key}", status: :active},
          active_ruleset: %{
            version: 4,
            salt: "checkout:v4",
            rules: [
              %{
                key: "variant-rollout",
                strategy: :variant_split,
                rollout: %{bucket_by: :subject, percentage: 100, salt: "v4"},
                variants: [
                  %{key: "on", weight: 100, value: %{value: true}}
                ]
              }
            ]
          }
        }
      }
    }

    %{
      environment_key: environment_key,
      version: 9,
      payload: :erlang.term_to_binary(payload),
      payload_checksum: "checksum",
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: DateTime.add(now, -4_500, :millisecond)
    }
  end
end

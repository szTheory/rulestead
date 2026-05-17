defmodule Rulestead.Runtime.Health do
  @moduledoc false

  alias Rulestead.Redis
  alias Rulestead.Runtime.{Cache, Config}

  @spec current(keyword()) :: map()
  def current(opts \\ []) do
    peer_nodes = Keyword.get(opts, :peer_nodes, [])

    %{
      node: node(),
      topology_scope: topology_scope(peer_nodes),
      peer_nodes: peer_nodes,
      environments: environments()
    }
  end

  defp environments do
    adapter_health = adapter_health()

    Cache.diagnostics()
    |> Enum.map(fn environment ->
      Map.take(environment, [:environment_key, :snapshot_version, :cache_age_ms, :refresh_status])
      |> Map.put(:sync_latency_ms, sync_latency_ms(environment))
      |> Map.put(:refresh_worker_status, refresh_worker_status(environment))
      |> Map.put(:adapter_health, adapter_health)
    end)
  end

  defp topology_scope([]), do: :current_node
  defp topology_scope(_peer_nodes), do: :host_provided

  defp sync_latency_ms(%{published_at: %DateTime{} = published_at, applied_at: %DateTime{} = applied_at}) do
    applied_at
    |> DateTime.diff(published_at, :millisecond)
    |> max(0)
  end

  defp sync_latency_ms(_environment), do: nil

  defp refresh_worker_status(%{refresh_status: refresh_status}) do
    %{
      attempt: 0,
      next_backoff_ms: 0,
      refresh_status: refresh_status
    }
  end

  defp adapter_health do
    %{
      repo: repo_health(),
      redis: redis_health(),
      pubsub: pubsub_health()
    }
  end

  defp repo_health do
    case Application.get_env(:rulestead, Rulestead.Repo) do
      nil ->
        %{configured?: false, status: :not_configured}

      _config ->
        %{configured?: true, status: process_status(Rulestead.Repo)}
    end
  end

  defp redis_health do
    if Redis.enabled?() do
      %{configured?: true, status: process_status(Redis.name())}
    else
      %{configured?: false, status: :not_configured}
    end
  end

  defp pubsub_health do
    case Config.pubsub() do
      nil ->
        %{configured?: false, status: :not_configured}

      pubsub ->
        %{configured?: true, status: process_status(pubsub)}
    end
  end

  defp process_status(name) do
    if Process.whereis(name), do: :up, else: :down
  end
end

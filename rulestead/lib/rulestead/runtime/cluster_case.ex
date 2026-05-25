# credo:disable-for-this-file
defmodule Rulestead.Runtime.ClusterCase do
  @moduledoc false

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Notifier.PhoenixPubSub, Supervisor}

  @convergence_timeout_ms 500
  @poll_interval_ms 25

  defmodule StoreProxy do
    @moduledoc false

    def fetch_snapshot(command) do
      case :rpc.call(controller_node(), Rulestead.Fake, :fetch_snapshot, [command]) do
        {:ok, %{payload: payload} = snapshot} when is_binary(payload) ->
          _ = :erlang.binary_to_term(payload)
          {:ok, snapshot}

        other ->
          other
      end
    end

    defp controller_node do
      Application.fetch_env!(:rulestead, :cluster_store_controller)
    end
  end

  @spec convergence_timeout_ms() :: pos_integer()
  def convergence_timeout_ms, do: @convergence_timeout_ms

  @spec setup_cluster!(String.t()) :: map()
  def setup_cluster!(environment_key) do
    ensure_distribution!()
    Control.reset!()
    pubsub_name = :"rulestead-cluster-pubsub-#{System.unique_integer([:positive])}"
    Application.put_env(:rulestead, :cluster_store_controller, node())
    Application.put_env(:rulestead, :cluster_case_pubsub_name, pubsub_name)
    {:ok, pubsub_pid} = start_pubsub!(pubsub_name)

    {peer_ref, peer_node} = start_peer!("runtime")

    :ok = seed_environment(environment_key)
    initial_snapshot = publish_ruleset_version(environment_key, true)
    local_refresh_name = :"cluster-refresh-local-#{System.unique_integer([:positive])}"
    remote_refresh_name = :"cluster-refresh-remote-#{System.unique_integer([:positive])}"
    notifier = PhoenixPubSub

    {:ok, local_runtime} =
      Supervisor.start_link(
        name: nil,
        environment_keys: [environment_key],
        notifier: notifier,
        store: StoreProxy,
        pubsub: pubsub_name,
        auto_tick?: false,
        refresh_name: local_refresh_name
      )

    :ok =
      rpc!(peer_node, __MODULE__, :start_runtime_detached!, [
        [
          name: nil,
          environment_keys: [environment_key],
          notifier: notifier,
          store: StoreProxy,
          pubsub: pubsub_name,
          auto_tick?: false,
          refresh_name: remote_refresh_name
        ]
      ])

    wait_for_remote_runtime!(peer_node, environment_key)
    :ok = Rulestead.Runtime.Refresh.refresh_now(local_refresh_name)
    :ok = rpc!(peer_node, Rulestead.Runtime.Refresh, :refresh_now, [remote_refresh_name])

    %{
      environment_key: environment_key,
      initial_snapshot: initial_snapshot,
      notifier: notifier,
      pubsub_name: pubsub_name,
      pubsub_pid: pubsub_pid,
      local_runtime: local_runtime,
      local_refresh_name: local_refresh_name,
      peer_ref: peer_ref,
      peer_node: peer_node,
      remote_refresh_name: remote_refresh_name,
      remote_runtime: :detached
    }
  end

  @spec teardown_cluster(map()) :: :ok
  def teardown_cluster(cluster) do
    stop_process(cluster[:local_runtime])
    stop_process(cluster[:pubsub_pid])

    if cluster[:peer_ref] do
      try do
        :peer.stop(cluster.peer_ref)
      catch
        :exit, _reason -> :ok
      end
    end

    :ok
  end

  @spec publish_ruleset_version(String.t(), boolean()) :: map()
  def publish_ruleset_version(environment_key, forced_value) do
    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Rulestead.Store.Command.SaveDraftRuleset.new("checkout-redesign", environment_key, %{
          salt: "checkout:#{System.unique_integer([:positive])}",
          rules: [
            %{
              key: "beta-rollout",
              strategy: :forced_value,
              value: %{value: forced_value},
              conditions: [
                %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
              ]
            }
          ]
        })
      )

    {:ok, _published} =
      Rulestead.publish_ruleset(
        Rulestead.Store.Command.PublishRuleset.new("checkout-redesign", environment_key)
      )

    Control.latest_snapshot!(environment_key)
  end

  @spec seed_environment(String.t()) :: :ok
  def seed_environment(environment_key) do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Control.put_environment!(%{key: environment_key, name: "Cluster #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "ops",
      expected_expiration: Date.utc_today(),
      environment_keys: [environment_key]
    })

    :ok
  end

  @spec remote_enabled?(node(), String.t(), Rulestead.Context.t()) ::
          {:ok, boolean()} | {:error, term()}
  def remote_enabled?(peer_node, environment_key, context) do
    :rpc.call(peer_node, Rulestead.Runtime, :enabled?, [
      environment_key,
      "checkout-redesign",
      context
    ])
  end

  @spec remote_diagnostics(node()) :: map()
  def remote_diagnostics(peer_node) do
    :rpc.call(peer_node, Rulestead.Runtime, :diagnostics, [])
  end

  @spec assert_eventually((-> truthy), keyword()) :: :ok when truthy: term()
  def assert_eventually(fun, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout, @convergence_timeout_ms)
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_assert_eventually(fun, deadline)
  end

  defp do_assert_eventually(fun, deadline) do
    if fun.() do
      :ok
    else
      if System.monotonic_time(:millisecond) >= deadline do
        raise "condition did not become true within timeout"
      end

      Process.sleep(@poll_interval_ms)
      do_assert_eventually(fun, deadline)
    end
  end

  defp ensure_distribution! do
    if Node.alive?() do
      :ok
    else
      _ = System.cmd("epmd", ["-daemon"])
      name = :"rulestead_test_#{System.unique_integer([:positive])}"

      case Node.start(name, :shortnames) do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, reason} -> raise "failed to start distributed node: #{inspect(reason)}"
      end
    end
  end

  defp start_peer!(suffix) do
    peer_name = :"#{suffix}_#{System.unique_integer([:positive])}"
    {:ok, peer_ref, peer_node} = :peer.start_link(%{name: peer_name})
    :ok = rpc!(peer_node, :code, :add_paths, [:code.get_path()])
    {:ok, _started} = rpc!(peer_node, :application, :ensure_all_started, [:rulestead])
    :ok = rpc!(peer_node, :application, :set_env, [:rulestead, :cluster_store_controller, node()])

    :ok =
      rpc!(peer_node, :application, :set_env, [
        :rulestead,
        :cluster_case_pubsub_name,
        cluster_pubsub_name()
      ])

    :ok = rpc!(peer_node, __MODULE__, :start_pubsub_detached!, [cluster_pubsub_name()])
    wait_for_remote_pubsub!(peer_node, cluster_pubsub_name())
    {peer_ref, peer_node}
  end

  @spec start_pubsub!(atom()) :: {:ok, pid()}
  def start_pubsub!(pubsub_name) do
    Elixir.Supervisor.start_link([{Phoenix.PubSub, name: pubsub_name}], strategy: :one_for_one)
  end

  @spec start_pubsub_detached!(atom()) :: :ok
  def start_pubsub_detached!(pubsub_name) do
    spawn(fn ->
      {:ok, _pid} = start_pubsub!(pubsub_name)
      Process.sleep(:infinity)
    end)

    :ok
  end

  @spec start_runtime_detached!(keyword()) :: :ok
  def start_runtime_detached!(opts) do
    spawn(fn ->
      {:ok, _pid} = Supervisor.start_link(opts)
      Process.sleep(:infinity)
    end)

    :ok
  end

  defp cluster_pubsub_name do
    Application.fetch_env!(:rulestead, :cluster_case_pubsub_name)
  rescue
    _error -> nil
  end

  defp rpc!(peer_node, module, function, args) do
    case :rpc.call(peer_node, module, function, args) do
      {:badrpc, reason} ->
        raise "rpc #{inspect(module)}.#{function}/#{length(args)} failed: #{inspect(reason)}"

      result ->
        result
    end
  end

  defp wait_for_remote_pubsub!(peer_node, pubsub_name) do
    assert_eventually(fn ->
      match?(pid when is_pid(pid), :rpc.call(peer_node, Process, :whereis, [pubsub_name]))
    end)
  end

  defp wait_for_remote_runtime!(peer_node, environment_key) do
    assert_eventually(fn ->
      case remote_diagnostics(peer_node) do
        %{environments: environments} ->
          Enum.any?(environments, &(&1.environment_key == environment_key))

        _other ->
          false
      end
    end)
  end

  defp stop_process(nil), do: :ok

  defp stop_process(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      Process.exit(pid, :shutdown)
    else
      :ok
    end
  rescue
    _error -> :ok
  end
end

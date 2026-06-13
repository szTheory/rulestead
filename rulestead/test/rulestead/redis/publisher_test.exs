defmodule Rulestead.Redis.PublisherTest do
  use ExUnit.Case, async: false

  alias Rulestead.Redis.Publisher
  alias Rulestead.Store.Command
  alias Rulestead.Test.RedisClient

  defmodule StoreStub do
    alias Rulestead.StoreError

    def fetch_snapshot(%Command.FetchSnapshot{} = command) do
      case Application.get_env(:rulestead, :redis_test_snapshot) do
        nil -> {:error, StoreError.snapshot_not_found(command.environment_key)}
        snapshot -> {:ok, snapshot}
      end
    end
  end

  defmodule ActiveStoreStub do
    alias Rulestead.StoreError

    def fetch_snapshot(%Command.FetchSnapshot{} = command) do
      if pid = Application.get_env(:rulestead, :redis_test_pid) do
        send(pid, {:active_store_fetch_snapshot, command})
      end

      case Application.get_env(:rulestead, :redis_test_snapshot) do
        nil -> {:error, StoreError.snapshot_not_found(command.environment_key)}
        snapshot -> {:ok, snapshot}
      end
    end
  end

  setup do
    previous_redis = Application.get_env(:rulestead, :redis, [])
    previous_snapshot = Application.get_env(:rulestead, :redis_test_snapshot)
    previous_store = Application.get_env(:rulestead, :store)
    previous_pid = Application.get_env(:rulestead, :redis_test_pid)
    client_name = :"redis-publisher-test-#{System.unique_integer([:positive])}"
    start_supervised!({RedisClient, name: client_name})
    start_supervised!(Publisher)
    Application.put_env(:rulestead, :redis_test_pid, self())

    Application.put_env(:rulestead, :redis,
      enabled: false,
      client: RedisClient,
      name: client_name,
      publisher_store: StoreStub
    )

    on_exit(fn ->
      Application.put_env(:rulestead, :redis, previous_redis)

      if is_nil(previous_snapshot) do
        Application.delete_env(:rulestead, :redis_test_snapshot)
      else
        Application.put_env(:rulestead, :redis_test_snapshot, previous_snapshot)
      end

      if is_nil(previous_store) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, previous_store)
      end

      if is_nil(previous_pid) do
        Application.delete_env(:rulestead, :redis_test_pid)
      else
        Application.put_env(:rulestead, :redis_test_pid, previous_pid)
      end
    end)

    %{client_name: client_name}
  end

  test "handle_event/4 loads the published snapshot and pushes it to Redis", %{
    client_name: client_name
  } do
    snapshot = %{
      environment_key: "test",
      version: 4,
      payload: :erlang.term_to_binary(%{flags: %{}}),
      payload_checksum: String.duplicate("b", 64),
      metadata: %{schema_version: 1, flag_count: 0},
      published_at: ~U[2026-05-17 12:30:00Z]
    }

    Application.put_env(:rulestead, :redis_test_snapshot, snapshot)

    Application.put_env(:rulestead, :redis,
      enabled: true,
      client: RedisClient,
      name: client_name,
      publisher_store: StoreStub
    )

    :ok =
      Publisher.handle_event(
        [:rulestead, :runtime, :snapshot, :published],
        %{count: 1},
        %{environment: "test", snapshot_version: 4},
        nil
      )

    assert_eventually(fn ->
      case RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test")) do
        nil -> false
        payload -> :erlang.binary_to_term(payload) == snapshot
      end
    end)
  end

  test "handle_event/4 retries the snapshot load after telemetry returns", %{
    client_name: client_name
  } do
    snapshot = %{
      environment_key: "test",
      version: 5,
      payload: :erlang.term_to_binary(%{flags: %{deferred: true}}),
      payload_checksum: String.duplicate("d", 64),
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: ~U[2026-05-17 12:30:00Z]
    }

    Application.delete_env(:rulestead, :redis_test_snapshot)

    Application.put_env(:rulestead, :redis,
      enabled: true,
      client: RedisClient,
      name: client_name,
      publisher_store: StoreStub
    )

    :ok =
      Publisher.handle_event(
        [:rulestead, :runtime, :snapshot, :published],
        %{count: 1},
        %{environment: "test", snapshot_version: 5},
        nil
      )

    Application.put_env(:rulestead, :redis_test_snapshot, snapshot)

    assert_eventually(fn ->
      case RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test")) do
        nil -> false
        payload -> :erlang.binary_to_term(payload) == snapshot
      end
    end)
  end

  test "handle_event/4 is a no-op when Redis is disabled", %{client_name: client_name} do
    snapshot = %{
      environment_key: "test",
      version: 2,
      payload: :erlang.term_to_binary(%{flags: %{}}),
      payload_checksum: String.duplicate("a", 64),
      metadata: %{schema_version: 1, flag_count: 0},
      published_at: ~U[2026-05-17 12:30:00Z]
    }

    Application.put_env(:rulestead, :redis_test_snapshot, snapshot)
    Application.put_env(:rulestead, :store, ActiveStoreStub)

    :ok =
      Publisher.handle_event(
        [:rulestead, :runtime, :snapshot, :published],
        %{count: 1},
        %{environment: "test", snapshot_version: 2},
        nil
      )

    refute_received {:active_store_fetch_snapshot, _command}
    assert RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test")) == nil
  end

  test "handle_event/4 defaults to the active store when publisher_store is unset", %{
    client_name: client_name
  } do
    snapshot = %{
      environment_key: "test",
      version: 3,
      payload: :erlang.term_to_binary(%{flags: %{test: true}}),
      payload_checksum: String.duplicate("c", 64),
      metadata: %{schema_version: 1, flag_count: 1},
      published_at: ~U[2026-05-17 12:30:00Z]
    }

    Application.put_env(:rulestead, :redis_test_snapshot, snapshot)
    Application.put_env(:rulestead, :store, ActiveStoreStub)

    Application.put_env(:rulestead, :redis,
      enabled: true,
      client: RedisClient,
      name: client_name
    )

    :ok =
      Publisher.handle_event(
        [:rulestead, :runtime, :snapshot, :published],
        %{count: 1},
        %{environment: "test", snapshot_version: 3},
        nil
      )

    assert_receive {:active_store_fetch_snapshot, %Command.FetchSnapshot{} = command}, 100
    assert command.environment_key == "test"
    assert command.version == 3

    assert_eventually(fn ->
      case RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test")) do
        nil -> false
        payload -> :erlang.binary_to_term(payload) == snapshot
      end
    end)
  end

  defp assert_eventually(fun, attempts \\ 20)

  defp assert_eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      assert true
    else
      Process.sleep(25)
      assert_eventually(fun, attempts - 1)
    end
  end

  defp assert_eventually(_fun, 0), do: flunk("condition did not become true")
end

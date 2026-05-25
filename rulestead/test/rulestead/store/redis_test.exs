# credo:disable-for-this-file
defmodule Rulestead.Store.RedisTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Error, StoreFixtures}
  alias Rulestead.Store.Redis
  alias Rulestead.Test.RedisClient

  setup do
    previous_redis = Application.get_env(:rulestead, :redis, [])
    client_name = :"redis-store-test-#{System.unique_integer([:positive])}"
    start_supervised!({RedisClient, name: client_name})

    Application.put_env(:rulestead, :redis,
      enabled: false,
      client: RedisClient,
      name: client_name
    )

    on_exit(fn ->
      Application.put_env(:rulestead, :redis, previous_redis)
    end)

    %{client_name: client_name}
  end

  test "fetch_snapshot/1 returns the latest snapshot from Redis", %{client_name: client_name} do
    snapshot = %{
      environment_key: "test",
      version: 2,
      payload: :erlang.term_to_binary(%{flags: %{}}),
      payload_checksum: String.duplicate("a", 64),
      metadata: %{schema_version: 1, flag_count: 0},
      published_at: ~U[2026-05-17 12:00:00Z]
    }

    key = Rulestead.Redis.snapshot_key("test")
    {:ok, "OK"} = RedisClient.command(client_name, ["SET", key, :erlang.term_to_binary(snapshot)])

    assert {:ok, ^snapshot} = Redis.fetch_snapshot(StoreFixtures.fetch_snapshot_command("test"))
  end

  test "fetch_snapshot/1 normalizes Redis misses into snapshot_not_found errors" do
    assert {:error, %Error{domain: :store, type: :snapshot_not_found} = error} =
             Redis.fetch_snapshot(StoreFixtures.fetch_snapshot_command("missing", version: 3))

    assert error.metadata.environment_key == "missing"
    assert error.metadata.version == 3
  end

  test "fetch_snapshot/1 treats poisoned payloads as unavailable errors", %{
    client_name: client_name
  } do
    key = Rulestead.Redis.snapshot_key("test")
    {:ok, "OK"} = RedisClient.command(client_name, ["SET", key, <<131, 100, 0, 15, 255>>])

    assert {:error, %Error{domain: :store, type: :store_unavailable}} =
             Redis.fetch_snapshot(StoreFixtures.fetch_snapshot_command("test"))
  end

  test "mutation callbacks reject writes because the adapter is read-only" do
    assert {:error,
            %Error{domain: :store, type: :invalid_command, message: "Redis adapter is read-only"}} =
             Redis.create_flag(
               Rulestead.StoreFixtures.valid_flag_attrs()
               |> Rulestead.Store.Command.CreateFlag.new()
             )
  end
end

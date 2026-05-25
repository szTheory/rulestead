defmodule Rulestead.Redis.IntegrationTest do
  use Rulestead.RepoCase, async: false

  alias Ecto.Adapters.SQL.Sandbox

  alias Rulestead.{
    Context,
    Environment,
    Flag,
    FlagEnvironment,
    Repo,
    Runtime,
    RuntimeSnapshot,
    StoreFixtures
  }

  alias Rulestead.Redis.Publisher
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Test.RedisClient

  setup do
    Sandbox.mode(Repo, {:shared, self()})
    reset_repo!()

    previous_store = Application.get_env(:rulestead, :store)
    previous_redis = Application.get_env(:rulestead, :redis, [])
    client_name = :"redis-integration-test-#{System.unique_integer([:positive])}"

    start_supervised!({RedisClient, name: client_name})
    start_supervised!(Publisher)

    Application.put_env(:rulestead, :store, Rulestead.Store.Ecto)

    Application.put_env(:rulestead, :redis,
      enabled: true,
      client: RedisClient,
      name: client_name,
      publisher_store: Rulestead.Store.Ecto
    )

    on_exit(fn ->
      if is_nil(previous_store) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, previous_store)
      end

      Application.put_env(:rulestead, :redis, previous_redis)
      Cache.reset("test")
    end)

    %{client_name: client_name}
  end

  test "Ecto publishes snapshots to Redis and runtime refresh degrades gracefully on Redis failures",
       %{
         client_name: client_name
       } do
    seed_flag!("test", true, "checkout:v1")

    snapshot_v1 =
      assert_eventually_value(fn ->
        RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test"))
      end)
      |> :erlang.binary_to_term()

    assert snapshot_v1.version == 1

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: "test",
         store: Rulestead.Store.Redis,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         backoff_ms: [1_000, 2_000, 4_000]}
      )

    assert {:ok, true} =
             Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    publish_flag_value!("test", false, "checkout:v2", 2)

    snapshot_v2 =
      assert_eventually_value(fn ->
        RedisClient.get(client_name, Rulestead.Redis.snapshot_key("test"))
      end)
      |> :erlang.binary_to_term()

    assert snapshot_v2.version == 2

    RedisClient.fail_command(client_name, :get, :disconnected)
    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, true} =
             Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert %{refresh_status: :stale} = Refresh.status(worker)

    RedisClient.clear_failures(client_name)
    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, false} =
             Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
  end

  defp seed_flag!(environment_key, value, salt) do
    assert {:ok, _flag} =
             Rulestead.create_flag(%{
               key: "checkout-redesign",
               description: "Checkout rollout",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               ownership: %{owner_ref: "growth", owner_kind: :team},
               lifecycle: %{mode: :permanent},
               environment_keys: [environment_key],
               actor: %{id: "seed-operator", roles: [:operator]}
             })

    publish_flag_value!(environment_key, value, salt, 1)
  end

  defp publish_flag_value!(environment_key, value, salt, version) do
    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: salt,
        rules: [
          %{
            key: "force-enabled",
            name: "Force enabled",
            strategy: :forced_value,
            value: %{value: value},
            conditions: [
              %{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}
            ]
          }
        ]
      })

    assert {:ok, %{version: ^version}} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", environment_key, ruleset,
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", environment_key,
                 actor: %{id: "seed-operator", roles: [:operator]},
                 version: version
               )
             )
  end

  defp reset_repo! do
    Repo.delete_all(Rulestead.AuditEvent)
    Repo.delete_all(RuntimeSnapshot)
    Repo.delete_all(Rulestead.Ruleset)
    Repo.delete_all(FlagEnvironment)
    Repo.delete_all(Flag)
    Repo.delete_all(Environment)

    Enum.each(default_environments(), fn attrs ->
      %Environment{} |> Environment.changeset(attrs) |> Repo.insert!()
    end)
  end

  defp default_environments do
    [
      %{
        key: "development",
        name: "Development",
        description: "Local and developer-owned environments"
      },
      %{key: "staging", name: "Staging", description: "Pre-production validation environments"},
      %{key: "production", name: "Production", description: "Live customer-facing environments"},
      %{key: "test", name: "Test", description: "Automated and ephemeral test environments"}
    ]
  end

  defp assert_eventually_value(fun, attempts \\ 20)

  defp assert_eventually_value(fun, attempts) when attempts > 0 do
    case fun.() do
      nil ->
        Process.sleep(25)
        assert_eventually_value(fun, attempts - 1)

      value ->
        value
    end
  end

  defp assert_eventually_value(_fun, 0), do: flunk("value did not become available")
end

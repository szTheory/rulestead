defmodule Rulestead.Runtime.RefreshTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}

  setup do
    Control.reset!()
    store_config = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, Rulestead.Fake)

    environment_key = "refresh-#{System.unique_integer([:positive])}"
    pubsub_name = :"rulestead-pubsub-#{System.unique_integer([:positive])}"

    Control.put_environment!(%{key: environment_key, name: "Refresh #{environment_key}"})
    seed_flag_versions(environment_key)

    start_supervised!({Phoenix.PubSub, name: pubsub_name})

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: environment_key,
         store: Rulestead.Fake,
         pubsub: pubsub_name,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         backoff_ms: [1_000, 2_000, 4_000]}
      )

    on_exit(fn ->
      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end

      Cache.reset(environment_key)
    end)

    %{environment_key: environment_key, pubsub_name: pubsub_name, worker: worker}
  end

  test "a PubSub invalidation wake-up fetches and applies a newer snapshot version locally", %{
    environment_key: environment_key,
    pubsub_name: pubsub_name,
    worker: worker
  } do
    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    version_two = publish_ruleset_version(environment_key, false)

    Control.publish!(pubsub_name, environment_key, version_two.version)
    assert :ok = Refresh.sync(worker)

    assert {:ok, false} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert %{environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    assert environment.snapshot_version == version_two.version
    assert environment.refresh_status == :ready
  end

  test "missed PubSub delivery is corrected by polling reconciliation", %{
    environment_key: environment_key,
    worker: worker
  } do
    version_two = publish_ruleset_version(environment_key, false)

    Control.advance_time!(5)
    assert :ok = Refresh.tick(worker)

    assert {:ok, false} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert %{environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    assert environment.snapshot_version == version_two.version
  end

  test "refresh failures back off and keep serving the last known good snapshot", %{
    environment_key: environment_key,
    worker: worker
  } do
    _version_two = publish_ruleset_version(environment_key, false)
    Control.disconnect!()

    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert %{attempt: 1, next_backoff_ms: 1_000, refresh_status: :stale} = Refresh.status(worker)

    Control.advance_time!(1)
    assert :ok = Refresh.tick(worker)
    assert %{attempt: 2, next_backoff_ms: 2_000, refresh_status: :stale} = Refresh.status(worker)

    Control.reconnect!()
    Control.advance_time!(2)
    assert :ok = Refresh.tick(worker)

    assert {:ok, false} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))
  end

  defp seed_flag_versions(environment_key) do
    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "ops",
      expected_expiration: Date.utc_today(),
      environment_keys: [environment_key]
    })

    publish_ruleset_version(environment_key, true)
  end

  defp publish_ruleset_version(environment_key, forced_value) do
    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Rulestead.Store.Command.SaveDraftRuleset.new("checkout-redesign", environment_key, %{
          salt: "checkout:#{System.unique_integer([:positive])}",
          rules: [
            %{
              key: "beta-rollout",
              strategy: :forced_value,
              value: %{value: forced_value},
              conditions: [%{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}]
            }
          ]
        })
      )

    {:ok, _published} =
      Rulestead.publish_ruleset(Rulestead.Store.Command.PublishRuleset.new("checkout-redesign", environment_key))

    Control.latest_snapshot!(environment_key)
  end
end

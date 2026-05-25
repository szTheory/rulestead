defmodule Rulestead.Runtime.RefreshTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}

  defmodule TestNotifier do
    @behaviour Rulestead.Runtime.Notifier

    @impl true
    def broadcast(notice, opts) do
      Rulestead.Runtime.Notifier.PhoenixPubSub.broadcast(notice, opts)
    end

    @impl true
    def subscribe(opts) do
      send(
        Keyword.fetch!(opts, :test_pid),
        {:notifier_subscribed, opts[:pubsub], opts[:pubsub_topic]}
      )

      Rulestead.Runtime.Notifier.PhoenixPubSub.subscribe(opts)
    end
  end

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
         notifier: TestNotifier,
         test_pid: self(),
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
    assert_receive {:notifier_subscribed, ^pubsub_name, _topic}

    assert {:ok, true} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    version_two = publish_ruleset_version(environment_key, false)

    Control.publish!(pubsub_name, environment_key, version_two.version, notifier: TestNotifier)
    assert :ok = Refresh.sync(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    assert environment.snapshot_version == version_two.version
    assert environment.refresh_status == :ready
  end

  test "duplicate and stale invalidation notices are ignored without regressing the applied snapshot",
       %{
         environment_key: environment_key,
         pubsub_name: pubsub_name,
         worker: worker
       } do
    version_two = publish_ruleset_version(environment_key, false)

    Control.publish!(pubsub_name, environment_key, version_two.version, notifier: TestNotifier)
    assert :ok = Refresh.sync(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{attempt: 0, next_backoff_ms: 0, refresh_status: :ready} = Refresh.status(worker)
    applied_version = snapshot_version!(environment_key)
    assert applied_version == version_two.version

    Control.publish!(pubsub_name, environment_key, version_two.version, notifier: TestNotifier)
    assert :ok = Refresh.sync(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{attempt: 0, next_backoff_ms: 0, refresh_status: :ready} = Refresh.status(worker)
    assert snapshot_version!(environment_key) == applied_version

    Control.publish!(pubsub_name, environment_key, version_two.version - 1,
      notifier: TestNotifier
    )

    assert :ok = Refresh.sync(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{attempt: 0, next_backoff_ms: 0, refresh_status: :ready} = Refresh.status(worker)
    assert snapshot_version!(environment_key) == applied_version
  end

  test "missed PubSub delivery is corrected by polling reconciliation", %{
    environment_key: environment_key,
    worker: worker
  } do
    version_two = publish_ruleset_version(environment_key, false)

    Control.advance_time!(5)
    assert :ok = Refresh.tick(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

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
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{attempt: 1, next_backoff_ms: 1_000, refresh_status: :stale} = Refresh.status(worker)

    Control.advance_time!(1)
    assert :ok = Refresh.tick(worker)
    assert %{attempt: 2, next_backoff_ms: 2_000, refresh_status: :stale} = Refresh.status(worker)

    Control.reconnect!()
    Control.advance_time!(2)
    assert :ok = Refresh.tick(worker)

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )
  end

  test "failed refresh after invalidation keeps serving the last known good snapshot", %{
    environment_key: environment_key,
    pubsub_name: pubsub_name,
    worker: worker
  } do
    _version_two = publish_ruleset_version(environment_key, false)
    Control.disconnect!()

    Control.publish!(pubsub_name, environment_key, 2, notifier: TestNotifier)
    assert :ok = Refresh.sync(worker)

    assert {:ok, true} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert %{attempt: 1, next_backoff_ms: 1_000, refresh_status: :stale} = Refresh.status(worker)
    assert snapshot_version!(environment_key) == 1
  end

  defp seed_flag_versions(environment_key) do
    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "ops", owner_kind: :team},
      lifecycle: %{mode: :expiring, review_by: Date.utc_today(), default_source: :flag_type, default_overridden: false},
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

  defp snapshot_version!(environment_key) do
    assert %{environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    environment.snapshot_version
  end
end

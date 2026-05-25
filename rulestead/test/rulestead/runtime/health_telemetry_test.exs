defmodule Rulestead.Runtime.HealthTelemetryTest do
  use ExUnit.Case, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.Refresh
  alias Rulestead.Store.Command

  @moduletag :telemetry

  setup do
    Control.reset!()

    store_config = Application.get_env(:rulestead, :store)
    environment_key = "health-telemetry-#{System.unique_integer([:positive])}"
    pubsub_name = :"rulestead-health-pubsub-#{System.unique_integer([:positive])}"

    Application.put_env(:rulestead, :store, Rulestead.Fake)

    Control.put_environment!(%{key: environment_key, name: "Health #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "ops", owner_kind: :team},
      lifecycle: %{mode: :expiring, review_by: Date.utc_today(), default_source: :flag_type, default_overridden: false},
      environment_keys: [environment_key]
    })

    start_supervised!({Phoenix.PubSub, name: pubsub_name})

    on_exit(fn ->
      Rulestead.Runtime.Cache.reset(environment_key)

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end
    end)

    %{environment_key: environment_key, pubsub_name: pubsub_name}
  end

  test "compatibility aliases emit alongside runtime invalidation events with bounded metadata", %{
    environment_key: environment_key,
    pubsub_name: pubsub_name
  } do
    _version_one = publish_ruleset_version(environment_key, true)

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: environment_key,
         store: Rulestead.Fake,
         notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
         pubsub: pubsub_name,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)
    flush_telemetry_events()

    handler_id = "health-telemetry-#{System.unique_integer([:positive])}"

    attach_test_handler(handler_id, [
      [:rulestead, :runtime, :invalidation, :received],
      [:rulestead, :runtime, :invalidation, :refresh_triggered],
      [:rulestead, :cache, :invalidation],
      [:rulestead, :sync, :delta_received]
    ])

    version_two = publish_ruleset_version(environment_key, false)

    Control.publish!(pubsub_name, environment_key, version_two.version,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub
    )

    assert :ok = Refresh.sync(worker)

    runtime_received = assert_receive_event([:rulestead, :runtime, :invalidation, :received])
    delta_received = assert_receive_event([:rulestead, :sync, :delta_received])

    runtime_triggered =
      assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_triggered])

    cache_invalidation = assert_receive_event([:rulestead, :cache, :invalidation])

    assert runtime_received.environment == environment_key
    assert runtime_received.snapshot_version == version_two.version
    assert runtime_received.reason == :invalidation_received

    assert runtime_triggered.environment == environment_key
    assert runtime_triggered.snapshot_version == version_two.version
    assert runtime_triggered.reason == :refresh_triggered_from_invalidation
    assert runtime_triggered.refresh_status == :ready

    assert cache_invalidation == runtime_triggered
    assert delta_received == runtime_received

    assert_bounded_metadata_keys(cache_invalidation)
    assert_bounded_metadata_keys(delta_received)
  end

  defp publish_ruleset_version(environment_key, forced_value) do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(forced_value)
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

    Control.latest_snapshot!(environment_key)
  end

  defp ruleset_attrs(forced_value) do
    %{
      salt: "checkout:#{System.unique_integer([:positive])}",
      metadata: %{request_id: "req-#{System.unique_integer([:positive])}"},
      rules: [
        %{
          key: "beta-rollout",
          strategy: :forced_value,
          value: %{value: forced_value, raw_attribute: "secret"},
          conditions: [%{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}]
        }
      ]
    }
  end

  defp attach_test_handler(handler_id, events) do
    :ok =
      :telemetry.attach_many(
        handler_id,
        events,
        fn event, _measurements, metadata, test_pid ->
          send(test_pid, {:telemetry_event, event, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
  end

  defp flush_telemetry_events do
    receive do
      {:telemetry_event, _event, _metadata} -> flush_telemetry_events()
    after
      0 -> :ok
    end
  end

  defp assert_receive_event(event_name) do
    deadline = System.monotonic_time(:millisecond) + 1_000
    do_assert_receive_event(event_name, deadline)
  end

  defp do_assert_receive_event(event_name, deadline) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:telemetry_event, ^event_name, metadata} ->
        metadata

      {:telemetry_event, _other_event, _metadata} ->
        do_assert_receive_event(event_name, deadline)
    after
      remaining ->
        flunk("expected telemetry event #{inspect(event_name)}")
    end
  end

  defp assert_bounded_metadata_keys(metadata) do
    extra_keys =
      metadata
      |> Map.keys()
      |> Enum.sort()
      |> Kernel.--([:environment, :refresh_status, :reason, :snapshot_version])

    assert extra_keys == []
  end
end

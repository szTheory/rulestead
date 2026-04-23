defmodule Rulestead.TelemetryTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command

  @moduletag :telemetry

  setup do
    Control.reset!()

    store_config = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, Rulestead.Fake)

    environment_key = "telemetry-#{System.unique_integer([:positive])}"
    pubsub_name = :"rulestead-telemetry-pubsub-#{System.unique_integer([:positive])}"

    Control.put_environment!(%{key: environment_key, name: "Telemetry #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false, raw_attribute: "secret"},
      owner: "ops",
      expected_expiration: Date.utc_today(),
      environment_keys: [environment_key]
    })

    start_supervised!({Phoenix.PubSub, name: pubsub_name})

    on_exit(fn ->
      Cache.reset(environment_key)

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end
    end)

    %{environment_key: environment_key, pubsub_name: pubsub_name}
  end

  test "public eval runtime and store operations emit the phase 4 event families with the shared metadata spine", %{
    environment_key: environment_key
  } do
    handler_id = "telemetry-contract-#{System.unique_integer([:positive])}"

    attach_test_handler(handler_id, [
      [:rulestead, :store, :write, :start],
      [:rulestead, :store, :write, :stop],
      [:rulestead, :runtime, :snapshot, :published],
      [:rulestead, :runtime, :cache, :refresh],
      [:rulestead, :runtime, :snapshot, :applied],
      [:rulestead, :eval, :decide, :start],
      [:rulestead, :eval, :decide, :stop],
      [:rulestead, :runtime, :cache, :hit],
      [:rulestead, :store, :read, :start],
      [:rulestead, :store, :read, :stop]
    ])

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", environment_key, ruleset_attrs(true))
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", environment_key))

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: environment_key,
         store: Rulestead.Fake,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    store_write_start = assert_receive_event([:rulestead, :store, :write, :start])
    assert store_write_start.flag_key == "checkout-redesign"
    assert store_write_start.environment == environment_key
    assert store_write_start.has_targeting_key? == false

    store_write_stop = assert_receive_event([:rulestead, :store, :write, :stop])
    assert store_write_stop.snapshot_version == 1
    assert store_write_stop.reason in [nil, :stored]

    snapshot_published = assert_receive_event([:rulestead, :runtime, :snapshot, :published])
    assert snapshot_published.snapshot_version == 1
    refute Map.has_key?(snapshot_published, :attributes)
    refute Map.has_key?(snapshot_published, :value)
    refute Map.has_key?(snapshot_published, :raw_attribute)

    assert_receive_event([:rulestead, :runtime, :cache, :refresh])

    store_read_start = assert_receive_event([:rulestead, :store, :read, :start])
    assert store_read_start.environment == environment_key

    store_read_stop = assert_receive_event([:rulestead, :store, :read, :stop])
    assert store_read_stop.snapshot_version == 1

    snapshot_applied = assert_receive_event([:rulestead, :runtime, :snapshot, :applied])
    assert snapshot_applied.snapshot_version == 1

    eval_start = assert_receive_event([:rulestead, :eval, :decide, :start])
    assert eval_start.flag_key == "checkout-redesign"
    assert eval_start.environment == environment_key
    assert eval_start.flag_type == :release
    assert eval_start.has_targeting_key? == true

    cache_hit = assert_receive_event([:rulestead, :runtime, :cache, :hit])
    assert cache_hit.reason == :cache_hit
    assert is_integer(cache_hit.cache_age_ms)

    eval_stop = assert_receive_event([:rulestead, :eval, :decide, :stop])
    assert eval_stop.reason == :rule_match
    assert eval_stop.snapshot_version == 1
    assert eval_stop.matched_rule_count == 1
    assert is_integer(eval_stop.cache_age_ms)

    detach_test_handler(handler_id)
  end

  test "safe handler attachment isolates handler exceptions and unknown reason atoms from the instrumented operation", %{
    environment_key: environment_key
  } do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", environment_key, ruleset_attrs(true))
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", environment_key))

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: environment_key,
         store: Rulestead.Fake,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)

    handler_id = "telemetry-safe-handler-#{System.unique_integer([:positive])}"
    parent = self()

    assert :ok =
             Rulestead.Telemetry.attach_many(
               handler_id,
               [
                 [:rulestead, :eval, :decide, :stop],
                 [:rulestead, :runtime, :cache, :stale_used]
               ],
               fn event, _measurements, metadata, _config ->
                 send(parent, {:safe_event, event, metadata.reason})
                 raise "boom"
               end,
               nil
             )

    on_exit(fn -> Rulestead.Telemetry.detach(handler_id) end)

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    Control.disconnect!()
    publish_ruleset_version(environment_key, false)
    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert_receive {:safe_event, [:rulestead, :eval, :decide, :stop], :rule_match}, 1_000
    assert_receive {:safe_event, [:rulestead, :runtime, :cache, :stale_used], reason}, 1_000
    assert is_atom(reason)
  end

  test "stale cache usage and snapshot lifecycle events omit raw payloads and framework structs", %{
    environment_key: environment_key
  } do
    handler_id = "telemetry-redaction-#{System.unique_integer([:positive])}"

    attach_test_handler(handler_id, [
      [:rulestead, :runtime, :snapshot, :published],
      [:rulestead, :runtime, :snapshot, :applied],
      [:rulestead, :runtime, :cache, :stale_used]
    ])

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", environment_key, ruleset_attrs(true))
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", environment_key))

    worker =
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: environment_key,
         store: Rulestead.Fake,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )

    assert :ok = Refresh.sync(worker)

    _snapshot_published = assert_receive_event([:rulestead, :runtime, :snapshot, :published])
    _snapshot_applied = assert_receive_event([:rulestead, :runtime, :snapshot, :applied])

    Control.disconnect!()
    publish_ruleset_version(environment_key, false)
    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    stale_used = assert_receive_event([:rulestead, :runtime, :cache, :stale_used])
    assert stale_used.reason == :stale_snapshot
    refute Map.has_key?(stale_used, :attributes)
    refute Map.has_key?(stale_used, :value)
    refute Map.has_key?(stale_used, :conn)
    refute Map.has_key?(stale_used, :socket)
    refute Map.has_key?(stale_used, :job)

    detach_test_handler(handler_id)
  end

  defp publish_ruleset_version(environment_key, forced_value) do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new("checkout-redesign", environment_key, ruleset_attrs(forced_value))
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", environment_key))
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

  defp detach_test_handler(handler_id) do
    :telemetry.detach(handler_id)
  end

  defp assert_receive_event(event_name) do
    receive_matching_event(event_name, 1_000)
  end

  defp receive_matching_event(event_name, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_receive_matching_event(event_name, deadline)
  end

  defp do_receive_matching_event(event_name, deadline) do
    remaining = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      {:telemetry_event, ^event_name, metadata} ->
        metadata

      {:telemetry_event, _other_event, _metadata} ->
        do_receive_matching_event(event_name, deadline)
    after
      remaining ->
        flunk("expected telemetry event #{inspect(event_name)}")
    end
  end
end

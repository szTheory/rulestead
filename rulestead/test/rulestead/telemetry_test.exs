defmodule Rulestead.TelemetryTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Refresh}
  alias Rulestead.Store.Command

  defmodule RaisingSnapshotStore do
    def fetch_snapshot(_command), do: raise("snapshot fetch exploded")
  end

  defmodule RaisingWriteStore do
    def save_draft_ruleset(_command), do: raise("store write exploded")
  end

  @moduletag :telemetry

  setup do
    Control.reset!()

    store_config = Application.get_env(:rulestead, :store)
    policy_config = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, Rulestead.AllowPolicy)

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

      if is_nil(policy_config) do
        Application.delete_env(:rulestead, :admin_policy)
      else
        Application.put_env(:rulestead, :admin_policy, policy_config)
      end
    end)

    %{environment_key: environment_key, pubsub_name: pubsub_name}
  end

  test "public eval runtime and store operations emit the phase 4 event families with the shared metadata spine",
       %{
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
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

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
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

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

  test "safe handler attachment isolates handler exceptions and unknown reason atoms from the instrumented operation",
       %{
         environment_key: environment_key
       } do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

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
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    Control.disconnect!()
    publish_ruleset_version(environment_key, false)
    assert :ok = Refresh.refresh_now(worker)

    assert {:ok, true} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert_receive {:safe_event, [:rulestead, :eval, :decide, :stop], :rule_match}, 1_000
    assert_receive {:safe_event, [:rulestead, :runtime, :cache, :stale_used], reason}, 1_000
    assert is_atom(reason)
  end

  test "admin mutation spans emit the documented start and stop events with bounded metadata", %{
    environment_key: environment_key
  } do
    handler_id = "telemetry-admin-#{System.unique_integer([:positive])}"

    attach_test_handler(handler_id, [
      [:rulestead, :admin, :mutation, :start],
      [:rulestead, :admin, :mutation, :stop]
    ])

    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    save_start = assert_receive_event([:rulestead, :admin, :mutation, :start])
    assert save_start.operation == "save_draft_ruleset"
    assert save_start.audit_action == "save_draft_ruleset"
    assert save_start.environment == environment_key

    save_stop = assert_receive_event([:rulestead, :admin, :mutation, :stop])
    assert save_stop.operation == "save_draft_ruleset"
    assert save_stop.audit_action == "save_draft_ruleset"
    assert save_stop.reason == :ok

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

    publish_start = assert_receive_event([:rulestead, :admin, :mutation, :start])
    assert publish_start.operation == "publish_ruleset"
    assert publish_start.audit_action == "publish_ruleset"

    publish_stop = assert_receive_event([:rulestead, :admin, :mutation, :stop])
    assert publish_stop.operation == "publish_ruleset"
    assert publish_stop.audit_action == "publish_ruleset"
    assert publish_stop.snapshot_version == 1

    detach_test_handler(handler_id)
  end

  test "cache miss and store read exception events emit the documented metadata shapes", %{
    environment_key: environment_key
  } do
    assert {:ok, _draft} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

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

    cache_handler = "telemetry-cache-miss-#{System.unique_integer([:positive])}"

    attach_test_handler(cache_handler, [
      [:rulestead, :runtime, :cache, :miss],
      [:rulestead, :eval, :decide, :stop]
    ])

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Runtime.enabled?(
               environment_key,
               "missing-flag",
               Context.new(actor: %{key: "user-1"})
             )

    cache_miss = assert_receive_event([:rulestead, :runtime, :cache, :miss])
    assert cache_miss.environment == environment_key
    assert cache_miss.flag_key == "missing-flag"
    assert cache_miss.reason == :cache_miss
    assert is_integer(cache_miss.cache_age_ms)

    eval_stop = assert_receive_event([:rulestead, :eval, :decide, :stop])
    assert eval_stop.environment == environment_key
    assert eval_stop.flag_key == "missing-flag"
    assert eval_stop.reason == :flag_not_found
    assert eval_stop.matched_rule_count == 0

    detach_test_handler(cache_handler)

    exception_handler = "telemetry-store-read-exception-#{System.unique_integer([:positive])}"

    attach_test_handler(exception_handler, [
      [:rulestead, :store, :read, :start],
      [:rulestead, :store, :read, :exception]
    ])

    assert_raise RuntimeError, fn ->
      start_supervised!(
        {Refresh,
         name: nil,
         environment_key: "#{environment_key}-boom",
         store: RaisingSnapshotStore,
         pubsub: nil,
         poll_interval_ms: 5_000,
         refresh_jitter_ms: 0,
         auto_tick?: false}
      )
    end

    store_read_start = assert_receive_event([:rulestead, :store, :read, :start])
    assert store_read_start.environment == "#{environment_key}-boom"
    assert store_read_start.operation == "fetch_snapshot"

    store_read_exception = assert_receive_event([:rulestead, :store, :read, :exception])
    assert store_read_exception.environment == "#{environment_key}-boom"
    assert %RuntimeError{message: "snapshot fetch exploded"} = store_read_exception.reason

    detach_test_handler(exception_handler)
  end

  test "eval and store write exception events emit the documented metadata shapes", %{
    environment_key: environment_key
  } do
    eval_handler = "telemetry-eval-exception-#{System.unique_integer([:positive])}"

    attach_test_handler(eval_handler, [
      [:rulestead, :eval, :decide, :exception]
    ])

    malformed_flag = %{
      flag: %{key: "broken-flag", flag_type: :release, default_value: %{value: false}},
      environment: %{key: environment_key},
      active_ruleset: %{
        version: 1,
        salt: "broken",
        rules: [
          %{
            key: "broken-rule",
            strategy: :variant_split,
            rollout: %{bucket_by: :subject, percentage: 100, salt: "broken"},
            variants: [
              %{key: "on", weight: "oops", value: %{value: true}}
            ]
          }
        ]
      }
    }

    assert_raise ArithmeticError, fn ->
      Rulestead.evaluate(malformed_flag, Context.new(actor: %{key: "user-1"}))
    end

    eval_exception = assert_receive_event([:rulestead, :eval, :decide, :exception])
    assert eval_exception.flag_key == "broken-flag"
    assert eval_exception.environment == environment_key
    assert eval_exception.has_targeting_key? == true
    assert eval_exception.kind == :error
    assert eval_exception.reason == :badarith
    assert is_list(eval_exception.stacktrace)

    detach_test_handler(eval_handler)

    store_config = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, RaisingWriteStore)

    on_exit(fn ->
      Application.put_env(:rulestead, :store, store_config)
    end)

    store_handler = "telemetry-store-write-exception-#{System.unique_integer([:positive])}"

    attach_test_handler(store_handler, [
      [:rulestead, :store, :write, :exception]
    ])

    assert {:error, %Rulestead.Error{type: :store_unavailable}} =
             Rulestead.save_draft_ruleset(
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    store_write_exception = assert_receive_event([:rulestead, :store, :write, :exception])
    assert store_write_exception.flag_key == "checkout-redesign"
    assert store_write_exception.environment == environment_key
    assert store_write_exception.operation == "save_draft_ruleset"
    assert store_write_exception.kind == :error
    assert %RuntimeError{message: "store write exploded"} = store_write_exception.reason
    assert is_list(store_write_exception.stacktrace)

    detach_test_handler(store_handler)
  end

  test "stale cache usage and snapshot lifecycle events omit raw payloads and framework structs",
       %{
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
               Command.SaveDraftRuleset.new(
                 "checkout-redesign",
                 environment_key,
                 ruleset_attrs(true)
               )
             )

    assert {:ok, _published} =
             Rulestead.publish_ruleset(
               Command.PublishRuleset.new("checkout-redesign", environment_key)
             )

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
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    stale_used = assert_receive_event([:rulestead, :runtime, :cache, :stale_used])
    assert stale_used.reason == :stale_snapshot
    refute Map.has_key?(stale_used, :attributes)
    refute Map.has_key?(stale_used, :value)
    refute Map.has_key?(stale_used, :conn)
    refute Map.has_key?(stale_used, :socket)
    refute Map.has_key?(stale_used, :job)

    detach_test_handler(handler_id)
  end

  test "invalidation telemetry distinguishes received, ignored, triggered, and failed refresh outcomes",
       %{
         environment_key: environment_key,
         pubsub_name: pubsub_name
       } do
    version_one = publish_ruleset_version(environment_key, true)

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

    handler_id = "telemetry-invalidation-#{System.unique_integer([:positive])}"

    attach_test_handler(handler_id, [
      [:rulestead, :runtime, :invalidation, :received],
      [:rulestead, :runtime, :invalidation, :ignored],
      [:rulestead, :runtime, :invalidation, :refresh_triggered],
      [:rulestead, :runtime, :invalidation, :refresh_failed],
      [:rulestead, :cache, :invalidation],
      [:rulestead, :sync, :delta_received]
    ])

    version_two = publish_ruleset_version(environment_key, false)

    Control.publish!(pubsub_name, environment_key, version_two.version,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub
    )

    assert :ok = Refresh.sync(worker)

    received = assert_receive_event([:rulestead, :runtime, :invalidation, :received])
    delta_received = assert_receive_event([:rulestead, :sync, :delta_received])
    assert received.environment == environment_key
    assert received.snapshot_version == version_two.version
    assert received.reason == :invalidation_received
    assert delta_received == received

    refresh_triggered =
      assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_triggered])

    cache_invalidation = assert_receive_event([:rulestead, :cache, :invalidation])

    assert refresh_triggered.environment == environment_key
    assert refresh_triggered.snapshot_version == version_two.version
    assert refresh_triggered.reason == :refresh_triggered_from_invalidation
    assert refresh_triggered.refresh_status == :ready
    assert cache_invalidation == refresh_triggered

    Control.publish!(pubsub_name, environment_key, version_two.version,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub
    )

    assert :ok = Refresh.sync(worker)

    duplicate_received = assert_receive_event([:rulestead, :runtime, :invalidation, :received])
    duplicate_delta_received = assert_receive_event([:rulestead, :sync, :delta_received])
    assert duplicate_received.snapshot_version == version_two.version
    assert duplicate_delta_received == duplicate_received

    duplicate_ignored = assert_receive_event([:rulestead, :runtime, :invalidation, :ignored])
    duplicate_cache_invalidation = assert_receive_event([:rulestead, :cache, :invalidation])
    assert duplicate_ignored.environment == environment_key
    assert duplicate_ignored.snapshot_version == version_two.version
    assert duplicate_ignored.reason == :stale_snapshot_version
    assert duplicate_ignored.refresh_status == :ready
    assert duplicate_cache_invalidation == duplicate_ignored

    Phoenix.PubSub.broadcast(
      pubsub_name,
      Rulestead.Runtime.Config.pubsub_topic(),
      {:rulestead_runtime_refresh, %{environment_key: environment_key}}
    )

    assert :ok = Refresh.sync(worker)

    missing_version_received =
      assert_receive_event([:rulestead, :runtime, :invalidation, :received])

    missing_version_delta_received =
      assert_receive_event([:rulestead, :sync, :delta_received])

    assert missing_version_received.environment == environment_key
    refute Map.has_key?(missing_version_received, :snapshot_version)
    assert missing_version_delta_received == missing_version_received

    missing_version_ignored =
      assert_receive_event([:rulestead, :runtime, :invalidation, :ignored])

    missing_version_cache_invalidation =
      assert_receive_event([:rulestead, :cache, :invalidation])

    assert missing_version_ignored.environment == environment_key
    assert missing_version_ignored.reason == :missing_snapshot_version
    assert missing_version_ignored.refresh_status == :ready
    refute Map.has_key?(missing_version_ignored, :snapshot_version)
    assert missing_version_cache_invalidation == missing_version_ignored

    version_three = publish_ruleset_version(environment_key, true)
    Control.disconnect!()

    Control.publish!(pubsub_name, environment_key, version_three.version,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub
    )

    assert :ok = Refresh.sync(worker)

    failed_received = assert_receive_event([:rulestead, :runtime, :invalidation, :received])
    failed_delta_received = assert_receive_event([:rulestead, :sync, :delta_received])
    assert failed_received.snapshot_version == version_three.version
    assert failed_delta_received == failed_received

    failed_triggered =
      assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_triggered])

    failed_cache_invalidation =
      assert_receive_event([:rulestead, :cache, :invalidation])

    assert failed_triggered.snapshot_version == version_three.version
    assert failed_triggered.reason == :refresh_triggered_from_invalidation
    assert failed_cache_invalidation == failed_triggered

    refresh_failed = assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_failed])
    failed_refresh_cache_invalidation = assert_receive_event([:rulestead, :cache, :invalidation])
    assert refresh_failed.environment == environment_key
    assert refresh_failed.snapshot_version == version_three.version
    assert refresh_failed.reason == :refresh_failed_after_invalidation
    assert refresh_failed.refresh_status == :stale
    assert failed_refresh_cache_invalidation == refresh_failed

    assert {:ok, false} =
             Runtime.enabled?(
               environment_key,
               "checkout-redesign",
               Context.new(actor: %{key: "user-1"})
             )

    assert_bounded_metadata_keys(received)
    assert_bounded_metadata_keys(delta_received)
    assert_bounded_metadata_keys(cache_invalidation)
    assert_bounded_metadata_keys(refresh_triggered)
    assert_bounded_metadata_keys(duplicate_received)
    assert_bounded_metadata_keys(duplicate_delta_received)
    assert_bounded_metadata_keys(duplicate_cache_invalidation)
    assert_bounded_metadata_keys(duplicate_ignored)
    assert_bounded_metadata_keys(missing_version_received)
    assert_bounded_metadata_keys(missing_version_delta_received)
    assert_bounded_metadata_keys(missing_version_cache_invalidation)
    assert_bounded_metadata_keys(missing_version_ignored)
    assert_bounded_metadata_keys(failed_received)
    assert_bounded_metadata_keys(failed_delta_received)
    assert_bounded_metadata_keys(failed_cache_invalidation)
    assert_bounded_metadata_keys(failed_refresh_cache_invalidation)
    assert_bounded_metadata_keys(failed_triggered)
    assert_bounded_metadata_keys(refresh_failed)

    detach_test_handler(handler_id)
    assert version_one.version == 1
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

  defp detach_test_handler(handler_id) do
    :telemetry.detach(handler_id)
  end

  defp flush_telemetry_events do
    receive do
      {:telemetry_event, _event, _metadata} -> flush_telemetry_events()
    after
      0 -> :ok
    end
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

  defp assert_bounded_metadata_keys(metadata) do
    extra_keys =
      metadata
      |> Map.keys()
      |> Enum.sort()
      |> Kernel.--([:environment, :refresh_status, :reason, :snapshot_version])

    assert extra_keys == []

    refute Map.has_key?(metadata, :payload)
    refute Map.has_key?(metadata, :flags)
    refute Map.has_key?(metadata, :attributes)
    refute Map.has_key?(metadata, :value)
    refute Map.has_key?(metadata, :raw_attribute)
  end
end

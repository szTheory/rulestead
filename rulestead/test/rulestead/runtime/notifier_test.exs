# credo:disable-for-this-file
defmodule Rulestead.Runtime.NotifierTest do
  use ExUnit.Case, async: false

  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.Notifier
  alias Rulestead.Runtime.Notifier.PhoenixPubSub
  alias Rulestead.Store.Command

  setup do
    Control.reset!()
    original_runtime = Application.get_env(:rulestead, :runtime)

    on_exit(fn ->
      if is_nil(original_runtime) do
        Application.delete_env(:rulestead, :runtime)
      else
        Application.put_env(:rulestead, :runtime, original_runtime)
      end
    end)

    :ok
  end

  test "phoenix adapter broadcasts and subscribes using the configured pubsub server and topic" do
    pubsub_name = :"rulestead-notifier-#{System.unique_integer([:positive])}"
    start_supervised!({Phoenix.PubSub, name: pubsub_name})

    assert :ok =
             PhoenixPubSub.subscribe(
               pubsub: pubsub_name,
               pubsub_topic: "rulestead:test:runtime"
             )

    assert :ok =
             PhoenixPubSub.broadcast(
               %{environment_key: "prod", snapshot_version: 7},
               pubsub: pubsub_name,
               pubsub_topic: "rulestead:test:runtime"
             )

    assert_receive {:rulestead_runtime_refresh, %{environment_key: "prod", snapshot_version: 7}}
  end

  test "missing pubsub configuration degrades to a no-op" do
    assert :ok =
             PhoenixPubSub.subscribe(
               pubsub: nil,
               pubsub_topic: "rulestead:test:runtime"
             )

    assert :ok =
             PhoenixPubSub.broadcast(
               %{environment_key: "prod", snapshot_version: 3},
               pubsub: nil,
               pubsub_topic: "rulestead:test:runtime"
             )
  end

  test "fake snapshot publication emits the exact invalidation notice contract" do
    pubsub_name = :"rulestead-notifier-fake-#{System.unique_integer([:positive])}"
    start_supervised!({Phoenix.PubSub, name: pubsub_name})

    Application.put_env(
      :rulestead,
      :runtime,
      notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
      pubsub: pubsub_name,
      pubsub_topic: "rulestead:test:runtime"
    )

    assert :ok =
             Notifier.subscribe(
               Rulestead.Runtime.Config.notifier(),
               pubsub: pubsub_name,
               pubsub_topic: "rulestead:test:runtime"
             )

    environment_key = "notifier-#{System.unique_integer([:positive])}"
    seed_flag_versions(environment_key)
    flush_refresh_messages()

    version_two = publish_ruleset_version(environment_key, false)

    assert_receive {:rulestead_runtime_refresh,
                    %{environment_key: ^environment_key, snapshot_version: snapshot_version}}

    assert snapshot_version == version_two.version
  end

  defp flush_refresh_messages do
    receive do
      {:rulestead_runtime_refresh, _payload} -> flush_refresh_messages()
    after
      0 -> :ok
    end
  end

  defp seed_flag_versions(environment_key) do
    Control.put_environment!(%{key: environment_key, name: "Notifier #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      ownership: %{owner_ref: "ops", owner_kind: :team},
      lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false},
      environment_keys: [environment_key]
    })

    publish_ruleset_version(environment_key, true)
  end

  defp publish_ruleset_version(environment_key, forced_value) do
    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Command.SaveDraftRuleset.new("checkout-redesign", environment_key, %{
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
      Rulestead.publish_ruleset(Command.PublishRuleset.new("checkout-redesign", environment_key))

    Control.latest_snapshot!(environment_key)
  end
end

defmodule Rulestead.ConfigTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Config, Runtime}

  test "runtime host config validates explicit pubsub wiring and notifier overrides" do
    assert {:ok, validated} =
             Config.validate(
               runtime: [
                 api: Runtime,
                 notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
                 health_peer_provider: HostApp.RuntimeHealthPeers,
                 pubsub: HostApp.PubSub,
                 pubsub_topic: "host:runtime"
               ]
             )

    assert validated[:runtime][:api] == Runtime
    assert validated[:runtime][:notifier] == Rulestead.Runtime.Notifier.PhoenixPubSub
    assert validated[:runtime][:health_peer_provider] == HostApp.RuntimeHealthPeers
    assert validated[:runtime][:pubsub] == HostApp.PubSub
    assert validated[:runtime][:pubsub_topic] == "host:runtime"
  end

  test "runtime host config keeps pubsub optional for polling-only deployments" do
    assert {:ok, validated} =
             Config.validate(
               runtime: [
                 api: Runtime,
                 notifier: Rulestead.Runtime.Notifier.PhoenixPubSub,
                 health_peer_provider: nil,
                 pubsub: nil,
                 pubsub_topic: "rulestead:runtime_snapshot"
               ]
             )

    assert validated[:runtime][:pubsub] == nil
  end

  test "tenancy config defaults to SingleTenant when valid" do
    assert {:ok, validated} = Config.validate([])

    assert validated[:tenancy][:module] == Rulestead.Tenancy.SingleTenant
  end

  test "tenancy config validates custom tenancy module" do
    assert {:ok, validated} =
             Config.validate(
               tenancy: [
                 module: HostApp.Tenancy
               ]
             )

    assert validated[:tenancy][:module] == HostApp.Tenancy
  end
end

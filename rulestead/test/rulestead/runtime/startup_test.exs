defmodule Rulestead.Runtime.StartupTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Result, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Supervisor}

  setup do
    Control.reset!()

    runtime_config = Application.get_env(:rulestead, :runtime, [])
    store_config = Application.get_env(:rulestead, :store)

    on_exit(fn ->
      Application.put_env(:rulestead, :runtime, runtime_config)

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end
    end)

    :ok
  end

  test "the runtime subsystem starts under supervision without store connectivity or host-managed ordering" do
    environment_key = unique_environment_key("degraded-boot")

    Application.put_env(:rulestead, :runtime, environment_keys: [environment_key])
    Application.put_env(:rulestead, :store, Rulestead.MissingStore)

    supervisor =
      start_supervised!(
        {Supervisor, name: nil, environment_keys: [environment_key], store: Rulestead.MissingStore}
      )

    assert Process.alive?(supervisor)

    assert %{node: _, environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    assert environment
    assert environment.refresh_status == :degraded
    assert environment.snapshot_version == nil
    assert environment.source == :none
  end

  test "runtime APIs report degraded mode instead of crashing when no snapshot exists yet" do
    environment_key = unique_environment_key("degraded-runtime")

    start_supervised!(
      {Supervisor, name: nil, environment_keys: [environment_key], store: Rulestead.MissingStore}
    )

    assert {:ok, %Result{} = result} =
             Runtime.evaluate(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert result.enabled? == false
    assert result.value == nil
    assert result.reason == :default
    assert result.flag_key == "checkout-redesign"
    assert result.cache_age_ms == nil

    assert {:ok, false} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert {:ok, :fallback} =
             Runtime.get_value(environment_key, "checkout-redesign", %{}, :fallback)

    assert {:ok, nil} = Runtime.get_variant(environment_key, "checkout-redesign", %{})
  end

  test "runtime keeps serving the last known good snapshot during startup failures" do
    environment_key = unique_environment_key("stale-startup")
    snapshot = publish_snapshot(environment_key)

    assert {:ok, compiled} = Rulestead.Runtime.Snapshot.compile(snapshot)
    assert {:ok, %{applied?: true}} = Cache.apply(compiled)

    start_supervised!(
      {Supervisor, name: nil, environment_keys: [environment_key], store: Rulestead.MissingStore}
    )

    assert {:ok, true} =
             Runtime.enabled?(environment_key, "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert %{environments: environments} = Runtime.diagnostics()
    environment = Enum.find(environments, &(&1.environment_key == environment_key))
    assert environment
    assert environment.snapshot_version == snapshot.version
    assert environment.source == :ets
    assert environment.refresh_status == :stale
  end

  defp publish_snapshot(environment_key) do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Control.put_environment!(%{key: environment_key, name: "Test #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "ops",
      expected_expiration: Date.utc_today(),
      environment_keys: [environment_key]
    })

    {:ok, _draft} =
      Rulestead.save_draft_ruleset(
        Rulestead.Store.Command.SaveDraftRuleset.new("checkout-redesign", environment_key, %{
          salt: "checkout:v1",
          rules: [
            %{
              key: "beta-rollout",
              strategy: :forced_value,
              value: %{value: true},
              conditions: [%{attribute: "actor.key", operator: :equals, value: %{equals: "user-1"}}]
            }
          ]
        })
      )

    {:ok, _published} =
      Rulestead.publish_ruleset(Rulestead.Store.Command.PublishRuleset.new("checkout-redesign", environment_key))

    %{snapshots: snapshots} = Control.snapshot!()

    snapshots
    |> Map.fetch!(environment_key)
    |> Map.values()
    |> Enum.max_by(& &1.version)
  end

  defp unique_environment_key(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end
end

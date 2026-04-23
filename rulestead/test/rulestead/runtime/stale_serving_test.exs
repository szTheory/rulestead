defmodule Rulestead.Runtime.StaleServingTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.Fake.Control
  alias Rulestead.Runtime.{Cache, Supervisor}

  setup do
    Control.reset!()

    runtime_config = Application.get_env(:rulestead, :runtime, [])
    store_config = Application.get_env(:rulestead, :store)
    snapshot_config = Application.get_env(:rulestead, :snapshot, [])

    backup_root =
      System.tmp_dir!()
      |> Path.join("rulestead-stale-runtime-#{System.unique_integer([:positive])}")

    File.rm_rf!(backup_root)
    File.mkdir_p!(backup_root)

    on_exit(fn ->
      Application.put_env(:rulestead, :runtime, runtime_config)

      if is_nil(store_config) do
        Application.delete_env(:rulestead, :store)
      else
        Application.put_env(:rulestead, :store, store_config)
      end

      Application.put_env(:rulestead, :snapshot, snapshot_config)
      File.rm_rf!(backup_root)
    end)

    %{backup_root: backup_root}
  end

  test "runtime keeps serving stale last-known-good data after store connectivity is lost", %{
    backup_root: backup_root
  } do
    environment_key = unique_environment_key("stale-serving")
    seed_snapshot(environment_key, true)

    supervisor = start_runtime(environment_key, backup_root, named_refresh?: true)
    assert Process.alive?(supervisor)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    publish_ruleset_version(environment_key, false)
    Control.disconnect!()

    assert :ok = Rulestead.Runtime.Refresh.refresh_now(refresh_name(environment_key))
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    assert {:ok, environment} = Cache.environment(environment_key)
    assert environment.refresh_status == :stale
    assert environment.source == :ets
  end

  test "offline restart restores from disk backup and keeps serving the last-known-good snapshot", %{
    backup_root: backup_root
  } do
    environment_key = unique_environment_key("offline-restart")
    seed_snapshot(environment_key, true)

    supervisor = start_runtime(environment_key, backup_root)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    shutdown_supervisor(supervisor)
    Cache.reset(environment_key)
    Control.disconnect!()

    restarted_supervisor = start_runtime(environment_key, backup_root)
    assert Process.alive?(restarted_supervisor)
    assert {:ok, true} = Runtime.enabled?(environment_key, "checkout-redesign", actor_context())

    assert {:ok, environment} = Cache.environment(environment_key)
    assert environment.source == :disk
    assert environment.disk_backup_status in [:loaded, :persisted]
  end

  defp start_runtime(environment_key, backup_root, opts \\ []) do
    Application.put_env(
      :rulestead,
      :snapshot,
      backup: [enabled: true, path: backup_root]
    )

    Application.put_env(:rulestead, :store, Rulestead.Fake)

    start_supervised!(%{
      id: {:stale_runtime_supervisor, environment_key, System.unique_integer([:positive])},
      start:
        {Supervisor, :start_link,
         [[
           name: nil,
           environment_keys: [environment_key],
           store: Rulestead.Fake,
           refresh_name: if(Keyword.get(opts, :named_refresh?, false), do: refresh_name(environment_key))
         ]]},
      type: :supervisor
    })
  end

  defp seed_snapshot(environment_key, forced_value) do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Control.put_environment!(%{key: environment_key, name: "Stale #{environment_key}"})

    Control.put_flag!(%{
      key: "checkout-redesign",
      flag_type: :release,
      value_type: :boolean,
      default_value: %{value: false},
      owner: "ops",
      expected_expiration: Date.utc_today(),
      environment_keys: [environment_key]
    })

    publish_ruleset_version(environment_key, forced_value)
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
  end

  defp refresh_name(environment_key), do: :"stale-refresh-#{environment_key}"
  defp actor_context, do: Context.new(actor: %{key: "user-1"})

  defp shutdown_supervisor(supervisor) do
    :ok = Elixir.Supervisor.stop(supervisor, :shutdown, 1_000)
  end

  defp unique_environment_key(prefix) do
    "#{prefix}-#{System.unique_integer([:positive])}"
  end
end

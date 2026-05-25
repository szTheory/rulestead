defmodule Rulestead.Integration.AdminLifecycleRuntimeTest do
  use ExUnit.Case, async: false

  alias Rulestead.{Context, Runtime}
  alias Rulestead.StoreFixtures
  alias Rulestead.Runtime.{Cache, Snapshot}

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_lifecycle = Application.get_env(:rulestead, :admin_lifecycle)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.delete_env(:rulestead, :admin_policy)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )
    Rulestead.Fake.Control.reset!()

    on_exit(fn ->
      if previous_store, do: Application.put_env(:rulestead, :store, previous_store), else: Application.delete_env(:rulestead, :store)
      if previous_policy, do: Application.put_env(:rulestead, :admin_policy, previous_policy), else: Application.delete_env(:rulestead, :admin_policy)
      if previous_lifecycle, do: Application.put_env(:rulestead, :admin_lifecycle, previous_lifecycle), else: Application.delete_env(:rulestead, :admin_lifecycle)
    end)

    :ok
  end

  test "telemetry-driven stale tracking records freshness asynchronously and archived flags stay out of runtime evaluation" do
    now = ~U[2026-04-23 16:00:00Z]
    Rulestead.Fake.Control.set_now!(now)

    assert {:ok, _} =
             Rulestead.create_flag(%{
               key: "checkout-redesign",
               description: "Checkout rollout",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               ownership: %{owner_ref: "growth", owner_kind: :team},
      lifecycle: %{mode: :expiring, default_source: :flag_type, default_overridden: false},
               expected_expiration: ~D[2026-05-01],
               environment_keys: ["test"],
               tags: ["checkout"],
               actor: %{id: "seed-operator", roles: [:operator]}
             })

    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: "checkout-redesign:v1",
        rules: [
          %{
            key: "force-enabled",
            name: "Force enabled",
            strategy: :forced_value,
            value: %{value: true},
            conditions: [
              %{
                attribute: "actor.key",
                operator: :equals,
                value: %{equals: "user-1"}
              }
            ]
          }
        ]
      })

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset,
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test",
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )
    apply_latest_snapshot!("test")

    stale_detail = Rulestead.fetch_flag!("checkout-redesign", "test")
    assert stale_detail.lifecycle.state == :potentially_stale

    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert_eventually(fn ->
      refreshed_detail = Rulestead.fetch_flag!("checkout-redesign", "test")
      refreshed_detail.lifecycle.state == :active and
        not is_nil(refreshed_detail.lifecycle.last_evaluated_at)
    end)

    assert {:ok, archived} =
             Rulestead.archive_flag(
               StoreFixtures.archive_flag_command("checkout-redesign",
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )
    assert archived.archived?

    archived_detail = Rulestead.fetch_flag!("checkout-redesign", "test")
    assert archived_detail.flag.archived_at
    assert archived_detail.flag_environment.status == :archived
    assert archived_detail.lifecycle.state == :archived

    apply_latest_snapshot!("test")

    assert {:error, %Rulestead.Error{type: :flag_not_found}} =
             Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
  end

  test "kill switch publishes fresh runtime snapshots and refresh changes live evaluation" do
    Rulestead.Fake.Control.set_now!(~U[2026-04-23 16:00:00Z])

    assert {:ok, _} =
             Rulestead.create_flag(%{
               key: "checkout-redesign",
               description: "Checkout rollout",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               ownership: %{owner_ref: "growth", owner_kind: :team},
      lifecycle: %{mode: :permanent, default_source: :flag_type, default_overridden: false},
               environment_keys: ["test"],
               actor: %{id: "seed-operator", roles: [:operator]}
             })

    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: "checkout-redesign:v1",
        rules: [
          %{
            key: "force-enabled",
            name: "Force enabled",
            strategy: :forced_value,
            value: %{value: true},
            conditions: [
              %{
                attribute: "actor.key",
                operator: :equals,
                value: %{equals: "user-1"}
              }
            ]
          }
        ]
      })

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               StoreFixtures.save_draft_command("checkout-redesign", "test", ruleset,
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               StoreFixtures.publish_ruleset_command("checkout-redesign", "test",
                 actor: %{id: "seed-operator", roles: [:operator]}
               )
             )

    baseline_snapshot = Rulestead.Fake.Control.latest_snapshot!("test")
    apply_latest_snapshot!("test")

    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert {:ok, _} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "incident"
             )

    kill_snapshot = Rulestead.Fake.Control.latest_snapshot!("test")
    assert kill_snapshot.version > baseline_snapshot.version
    apply_latest_snapshot!("test")

    assert {:ok, false} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))

    assert {:ok, _} =
             Rulestead.release_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "resolved"
             )

    release_snapshot = Rulestead.Fake.Control.latest_snapshot!("test")
    assert release_snapshot.version > kill_snapshot.version
    apply_latest_snapshot!("test")

    assert {:ok, true} = Runtime.enabled?("test", "checkout-redesign", Context.new(actor: %{key: "user-1"}))
  end

  defp assert_eventually(fun, attempts \\ 20)

  defp assert_eventually(fun, attempts) when attempts > 0 do
    if fun.() do
      assert true
    else
      Process.sleep(25)
      assert_eventually(fun, attempts - 1)
    end
  end

  defp assert_eventually(_fun, 0), do: flunk("condition did not become true")

  defp apply_latest_snapshot!(environment_key) do
    snapshot = Rulestead.Fake.Control.latest_snapshot!(environment_key)
    :ok = Cache.reset(environment_key)
    {:ok, compiled} = Snapshot.compile(snapshot)
    {:ok, _applied} = Cache.apply(compiled)
  end
end

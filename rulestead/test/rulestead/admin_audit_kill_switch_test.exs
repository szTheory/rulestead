defmodule Rulestead.AdminAuditKillSwitchFakeTest do
  use ExUnit.Case, async: false

  alias Rulestead.StoreFixtures

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.AllowPolicy)
    Rulestead.Fake.Control.reset!()

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end

      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    :ok
  end

  test "engage and release kill switch without mutating authored rules and keep release idempotent" do
    seed_flag!()

    assert {:ok, engaged} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "incident"
             )

    assert engaged.flag_environment.status == :killswitched
    assert engaged.flag_environment.kill_switch_variant_key == "default"
    assert engaged.active_ruleset.version == 1

    assert {:ok, released} =
             Rulestead.release_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "resolved"
             )

    assert released.flag_environment.status == :active
    assert is_nil(released.flag_environment.kill_switch_variant_key)
    assert released.active_ruleset.version == 1

    assert {:ok, idempotent_release} =
             Rulestead.release_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "resolved"
             )

    assert idempotent_release.flag_environment.status == :active
    assert is_nil(idempotent_release.flag_environment.kill_switch_variant_key)
  end

  test "successful and denied kill switch actions append audit rows with normalized metadata" do
    seed_flag!()

    assert {:ok, _engaged} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "incident",
               metadata: %{request_id: "req-1", traits: %{email: "ops@example.com", plan: "enterprise"}}
             )

    Application.put_env(:rulestead, :admin_policy, __MODULE__.DenyPolicy)

    assert {:error, %Rulestead.Error{type: :unauthorized}} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "viewer-1", roles: [:viewer]},
               reason: "nope",
               metadata: %{request_id: "req-2", traits: %{email: "viewer@example.com", plan: "free"}}
             )

    Application.put_env(:rulestead, :admin_policy, __MODULE__.AllowPolicy)

    assert {:ok, page} =
             Rulestead.list_audit_events(flag_key: "checkout-redesign", environment_key: "test", actor: %{id: "aud-1", roles: [:auditor]})

    assert Enum.count(page.entries) == 2

    assert [%{event_type: "kill_switch.engage", result: :denied}, %{event_type: "kill_switch.engage", result: :ok}] =
             Enum.map(page.entries, &Map.take(&1, [:event_type, :result]))
  end

  test "rollback writes a new linked audit event instead of mutating history" do
    seed_flag!()

    assert {:ok, _engaged} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "incident"
             )

    assert {:ok, page_before} =
             Rulestead.list_audit_events(flag_key: "checkout-redesign", environment_key: "test", actor: %{id: "aud-1", roles: [:auditor]})

    [original] = page_before.entries

    assert {:ok, rollback} =
             Rulestead.rollback_audit_event(original.id, actor: %{id: "op-1", roles: [:operator]}, reason: "revert")

    assert rollback.audit_event.metadata["rollback_of_event_id"] == original.id

    assert {:ok, page_after} =
             Rulestead.list_audit_events(flag_key: "checkout-redesign", environment_key: "test", actor: %{id: "aud-1", roles: [:auditor]})

    assert Enum.count(page_after.entries) == 2
    assert Enum.any?(page_after.entries, &(&1.id == original.id))
    assert Enum.any?(page_after.entries, &(&1.metadata["rollback_of_event_id"] == original.id))
  end

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true
  end

  defmodule DenyPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: false
  end

  defp seed_flag! do
    assert {:ok, _} =
             Rulestead.create_flag(StoreFixtures.valid_flag_attrs(%{permanent: true}))

    assert {:ok, _} = Rulestead.save_draft_ruleset(StoreFixtures.save_draft_command())
    assert {:ok, _} = Rulestead.publish_ruleset(StoreFixtures.publish_ruleset_command())
  end
end

defmodule Rulestead.AdminAuditKillSwitchEctoTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    previous_policy = Application.get_env(:rulestead, :admin_policy)

    Application.put_env(:rulestead, :store, StoreEcto)
    Application.put_env(:rulestead, :admin_policy, Rulestead.AdminAuditKillSwitchFakeTest.AllowPolicy)
    ensure_phase7_schema!()

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end

      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end
    end)

    :ok
  end

  test "ecto adapter matches fake kill switch and audit rollback semantics" do
    seed_environment!("test")

    assert {:ok, _} =
             StoreEcto.create_flag(Command.CreateFlag.new(StoreFixtures.valid_flag_attrs(%{permanent: true})))
    assert {:ok, _} = StoreEcto.save_draft_ruleset(StoreFixtures.save_draft_command())
    assert {:ok, _} = StoreEcto.publish_ruleset(StoreFixtures.publish_ruleset_command())

    assert {:ok, engaged} =
             Rulestead.engage_kill_switch("checkout-redesign", "test", %{id: "op-1", roles: [:operator]},
               reason: "incident"
             )

    assert engaged.flag_environment.status == :killswitched
    assert engaged.flag_environment.kill_switch_variant_key == "default"

    assert {:ok, audit_page} =
             Rulestead.list_audit_events(flag_key: "checkout-redesign", environment_key: "test", actor: %{id: "aud-1", roles: [:auditor]})

    [event] = audit_page.entries

    assert {:ok, rollback} =
             Rulestead.rollback_audit_event(event.id, actor: %{id: "op-1", roles: [:operator]}, reason: "revert")

    assert rollback.audit_event.metadata["rollback_of_event_id"] == event.id
  end

  defp seed_environment!(key) do
    attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})
    changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)
    assert {:ok, _env} = Rulestead.Repo.insert(changeset)
  end

  defp ensure_phase7_schema! do
    Rulestead.Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false")
    Rulestead.Repo.query!("ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone")
  end
end

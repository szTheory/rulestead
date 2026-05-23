defmodule Rulestead.StoreEctoAdminTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  setup do
    previous_store = Application.get_env(:rulestead, :store)
    Application.put_env(:rulestead, :store, StoreEcto)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )

    on_exit(fn ->
      if previous_store do
        Application.put_env(:rulestead, :store, previous_store)
      else
        Application.delete_env(:rulestead, :store)
      end
      Application.delete_env(:rulestead, :admin_lifecycle)
    end)

    ensure_phase6_schema!()
    :ok
  end

  test "ecto list_flags/1 and fetch_flag/1 expose admin payloads, filters, and cursor navigation" do
    seed_environment!("qa")
    seed_flag!("checkout-redesign", owner: "growth", tags: ["checkout"], permanent: true)
    seed_flag!("ops-cleanup", owner: "ops", tags: ["infra"], expected_expiration: ~D[2026-04-20], permanent: false)
    seed_flag!("search-ranking", owner: "growth", tags: ["search"], expected_expiration: ~D[2026-04-28], permanent: false)

    publish_flag!("checkout-redesign")
    publish_flag!("ops-cleanup")
    publish_flag!("search-ranking")

    now = ~U[2026-04-23 16:00:00Z]
    assert {:ok, _} = StoreEcto.record_evaluation(Command.RecordEvaluation.new("checkout-redesign", "test", DateTime.add(now, -600, :second)))
    assert {:ok, _} = StoreEcto.record_evaluation(Command.RecordEvaluation.new("ops-cleanup", "test", DateTime.add(now, -7_200, :second)))
    assert {:ok, _} = StoreEcto.record_evaluation(Command.RecordEvaluation.new("search-ranking", "test", DateTime.add(now, -2_700, :second)))

    assert {:ok, %Command.Page{} = page} =
             StoreEcto.list_flags(Command.ListFlags.new(environment_key: "test", owner: "growth", limit: 1))

    assert [%{flag: %{key: "checkout-redesign"}, lifecycle: %{state: :active}}] = page.entries
    assert is_binary(page.next_cursor)
    assert page.has_next_page?

    assert {:ok, %Command.Page{} = next_page} =
             StoreEcto.list_flags(Command.ListFlags.new(environment_key: "test", owner: "growth", limit: 1, after: page.next_cursor))

    assert [%{flag: %{key: "search-ranking"}, lifecycle: %{state: :potentially_stale}}] = next_page.entries

    assert {:ok, detail} = StoreEcto.fetch_flag(StoreFixtures.fetch_flag_command("checkout-redesign", "test"))
    assert detail.flag.key == "checkout-redesign"
    assert detail.lifecycle.state == :active
    assert Enum.any?(detail.environments, &(&1.key == "test"))
    assert Enum.any?(detail.environment_cards, &(&1.environment.key == "test"))
    assert detail.recent_owners == ["growth", "ops"]

    assert {:ok, stale_page} =
             StoreEcto.list_flags(Command.ListFlags.new(environment_key: "test", stale: :stale, lifecycle: :stale))

    assert [%{flag: %{key: "ops-cleanup"}, lifecycle: %{state: :stale}}] = stale_page.entries
  end

  test "ecto metadata verbs create, update, list environments, and reject writes to archived flags" do
    seed_environment!("qa")

    create_command =
      Command.CreateFlag.new(%{
        key: "inventory-admin",
        description: "Inventory control plane",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: "platform",
        permanent: true,
        environment_keys: ["test", "qa"],
        tags: ["admin", "inventory"]
      })

    assert {:ok, created} = StoreEcto.create_flag(create_command)
    assert created.flag.key == "inventory-admin"
    assert Enum.sort(created.environment_keys) == ["qa", "test"]

    assert {:ok, updated} =
             StoreEcto.update_flag(Command.UpdateFlag.new("inventory-admin", %{
               description: "Updated inventory control plane",
               owner: "ops",
               permanent: false,
               expected_expiration: ~D[2026-05-15],
               tags: ["admin", "critical"]
             }))

    assert updated.flag.owner == "ops"
    assert updated.flag.expected_expiration == ~D[2026-05-15]
    assert updated.lifecycle.owner == "ops"
    assert updated.recent_owners == ["ops", "platform"]

    assert {:ok, environments} = StoreEcto.list_environments(Command.ListEnvironments.new(query: "q", limit: 10))
    assert Enum.any?(environments, &(&1.key == "qa"))

    assert {:ok, _archived} = StoreEcto.archive_flag(StoreFixtures.archive_flag_command("inventory-admin"))

    assert {:error, %Rulestead.Error{type: :flag_archived}} =
             StoreEcto.update_flag(Command.UpdateFlag.new("inventory-admin", %{owner: "growth"}))
  end

  defp seed_environment!(key) do
    attrs = StoreFixtures.valid_environment_attrs(%{key: key, name: String.upcase(key)})
    changeset = Rulestead.Environment.changeset(%Rulestead.Environment{}, attrs)
    assert {:ok, _env} = Rulestead.Repo.insert(changeset)
  end

  defp seed_flag!(key, opts) do
    attrs =
      %{
        key: key,
        description: "Flag #{key}",
        flag_type: :release,
        value_type: :boolean,
        default_value: %{value: false},
        owner: Keyword.fetch!(opts, :owner),
        tags: Keyword.get(opts, :tags, []),
        permanent: Keyword.get(opts, :permanent),
        expected_expiration: Keyword.get(opts, :expected_expiration),
        environment_keys: ["test"]
      }

    assert {:ok, _payload} = StoreEcto.create_flag(Command.CreateFlag.new(attrs))
  end

  defp publish_flag!(flag_key) do
    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: "#{flag_key}:v1",
        metadata: %{source: "ecto-admin-test"}
      })

    assert {:ok, _} = StoreEcto.save_draft_ruleset(StoreFixtures.save_draft_command(flag_key, "test", ruleset))
    assert {:ok, _} = StoreEcto.publish_ruleset(StoreFixtures.publish_ruleset_command(flag_key, "test"))
  end

  defp ensure_phase6_schema! do
    Rulestead.Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS permanent boolean DEFAULT false")
    Rulestead.Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS ownership jsonb NOT NULL DEFAULT '{}'::jsonb")
    Rulestead.Repo.query!("ALTER TABLE flags ADD COLUMN IF NOT EXISTS lifecycle jsonb NOT NULL DEFAULT '{}'::jsonb")
    Rulestead.Repo.query!("ALTER TABLE flag_environments ADD COLUMN IF NOT EXISTS last_evaluated_at timestamp(6) with time zone")
  end
end

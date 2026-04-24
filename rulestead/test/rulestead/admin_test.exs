defmodule Rulestead.AdminTest do
  use ExUnit.Case, async: false

  alias Rulestead.Store.Command
  alias Rulestead.StoreFixtures

  setup do
    Application.put_env(:rulestead, :store, Rulestead.Fake)
    Application.put_env(:rulestead, :admin_lifecycle,
      warning_after_seconds: 1_800,
      stale_after_seconds: 3_600,
      now: ~U[2026-04-23 16:00:00Z]
    )
    Rulestead.Fake.Control.reset!()
    :ok
  end

  test "list_flags/1 filters by environment, lifecycle, owner, stale status, and tags with cursor metadata" do
    now = ~U[2026-04-23 16:00:00Z]
    Rulestead.Fake.Control.set_now!(now)

    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      permanent: true
    )

    seed_flag!(
      key: "ops-cleanup",
      owner: "ops",
      tags: ["infra"],
      expected_expiration: ~D[2026-04-20],
      permanent: false
    )

    seed_flag!(
      key: "search-ranking",
      owner: "growth",
      tags: ["search"],
      expected_expiration: ~D[2026-04-28],
      permanent: false
    )

    publish_flag!("checkout-redesign")
    publish_flag!("ops-cleanup")
    publish_flag!("search-ranking")

    evaluated_recently_at = DateTime.add(now, -600, :second)
    evaluated_warning_at = DateTime.add(now, -2_700, :second)
    evaluated_stale_at = DateTime.add(now, -7_200, :second)

    assert {:ok, _} = Rulestead.record_evaluation("checkout-redesign", "test", evaluated_recently_at)
    assert {:ok, _} = Rulestead.record_evaluation("search-ranking", "test", evaluated_warning_at)
    assert {:ok, _} = Rulestead.record_evaluation("ops-cleanup", "test", evaluated_stale_at)

    assert {:ok, %Command.Page{} = page} =
             Rulestead.list_flags(
               environment_key: "test",
               owner: "growth",
               tags: ["checkout"],
               lifecycle: :active,
               stale: :fresh,
               limit: 1
             )

    assert page.limit == 1
    refute page.has_next_page?
    refute page.has_previous_page?
    assert is_nil(page.next_cursor)
    assert is_nil(page.prev_cursor)

    assert [
             %{
               flag: %{key: "checkout-redesign", owner: "growth", tags: ["checkout", "release"]},
               environment: %{key: "test"},
               active_ruleset: %{version: 1},
               draft_rulesets: [],
               lifecycle: %{state: :active},
               has_draft_ruleset?: false
             }
           ] = page.entries

    assert {:ok, %Command.Page{} = stale_page} =
             Rulestead.list_flags(
               environment_key: "test",
               stale: :stale,
               lifecycle: :stale,
               limit: 10
             )

    assert [%{flag: %{key: "ops-cleanup"}, lifecycle: %{state: :stale}}] = stale_page.entries

    assert {:ok, %Command.Page{} = cursor_page} =
             Rulestead.list_flags(environment_key: "test", owner: "growth", limit: 1)

    assert cursor_page.has_next_page?
    assert is_binary(cursor_page.next_cursor)

    assert {:ok, %Command.Page{} = next_page} =
             Rulestead.list_flags(environment_key: "test", owner: "growth", limit: 1, after: cursor_page.next_cursor)

    assert next_page.has_previous_page?
    assert is_binary(next_page.prev_cursor)
    assert [%{flag: %{key: "search-ranking"}, lifecycle: %{state: :potentially_stale}}] = next_page.entries
  end

  test "fetch_flag/2 and root metadata verbs return detail payloads and enforce archived read-only behavior" do
    seed_flag!(
      key: "checkout-redesign",
      owner: "growth",
      tags: ["checkout", "release"],
      expected_expiration: ~D[2026-05-01],
      permanent: false
    )

    publish_flag!("checkout-redesign")

    assert {:ok, detail} = Rulestead.fetch_flag("checkout-redesign", "test")
    assert detail.flag.key == "checkout-redesign"
    assert detail.environment.key == "test"
    assert detail.flag_environment.status == :active
    assert detail.active_ruleset.version == 1
    assert detail.lifecycle.owner == "growth"
    assert detail.lifecycle.state in [:active, :potentially_stale]
    assert detail.has_draft_ruleset? == false
    assert detail.recent_owners == ["growth"]
    assert Enum.any?(detail.environments, &(&1.key == "test"))
    assert Enum.any?(detail.environment_cards, &(&1.environment.key == "test"))

    assert {:ok, updated} =
             Rulestead.update_flag("checkout-redesign", %{
               description: "Updated description",
               owner: "platform",
               tags: ["checkout", "critical"],
               permanent: true,
               expected_expiration: nil
             })

    assert updated.flag.description == "Updated description"
    assert updated.flag.owner == "platform"
    assert updated.flag.permanent == true
    assert updated.recent_owners == ["platform", "growth"]

    assert {:ok, created} =
             Rulestead.create_flag(%{
               key: "inventory-admin",
               description: "Admin inventory page",
               flag_type: :release,
               value_type: :boolean,
               default_value: %{value: false},
               owner: "platform",
               permanent: true,
               environment_keys: ["test", "production"],
               tags: ["admin", "inventory"]
             })

    assert created.flag.key == "inventory-admin"
    assert Enum.sort(created.environment_keys) == ["production", "test"]

    assert {:ok, archived} = Rulestead.archive_flag(StoreFixtures.archive_flag_command("checkout-redesign"))
    assert archived.archived?

    assert {:error, %Rulestead.Error{type: :flag_archived}} =
             Rulestead.update_flag("checkout-redesign", %{owner: "ops"})
  end

  test "fake adapter list/detail semantics stay aligned with root facade pagination and archive rules" do
    seed_flag!(
      key: "alpha-flag",
      owner: "growth",
      permanent: true
    )

    seed_flag!(
      key: "beta-flag",
      owner: "growth",
      permanent: true
    )

    publish_flag!("alpha-flag")
    publish_flag!("beta-flag")

    assert {:ok, %Command.Page{} = first_page} =
             Rulestead.list_flags(environment_key: "test", limit: 1)

    assert [%{flag: %{key: "alpha-flag"}}] = first_page.entries
    assert is_binary(first_page.next_cursor)

    assert {:ok, %Command.Page{} = second_page} =
             Rulestead.list_flags(environment_key: "test", limit: 1, after: first_page.next_cursor)

    assert [%{flag: %{key: "beta-flag"}}] = second_page.entries

    assert {:ok, archived} = Rulestead.archive_flag(StoreFixtures.archive_flag_command("beta-flag"))
    assert archived.archived?

    assert {:ok, %Command.Page{entries: entries}} = Rulestead.list_flags(environment_key: "test", limit: 10)
    assert Enum.map(entries, & &1.flag.key) == ["alpha-flag"]
  end

  defp seed_flag!(attrs) do
    attrs =
      attrs
      |> Enum.into(%{})
      |> Map.put_new(:description, "Flag #{attrs[:key]}")
      |> Map.put_new(:flag_type, :release)
      |> Map.put_new(:value_type, :boolean)
      |> Map.put_new(:default_value, %{value: false})
      |> Map.put_new(:environment_keys, ["test"])
      |> Map.put_new(:tags, [])

    assert {:ok, _payload} = Rulestead.create_flag(attrs)
  end

  defp publish_flag!(flag_key) do
    ruleset =
      StoreFixtures.valid_ruleset_attrs(%{
        salt: "#{flag_key}:v1",
        metadata: %{source: "admin-test"}
      })

    assert {:ok, _} = Rulestead.save_draft_ruleset(StoreFixtures.save_draft_command(flag_key, "test", ruleset))
    assert {:ok, _} = Rulestead.publish_ruleset(StoreFixtures.publish_ruleset_command(flag_key, "test"))
  end
end

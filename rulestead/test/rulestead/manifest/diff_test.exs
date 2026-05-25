defmodule Rulestead.Manifest.DiffTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.Fake
  alias Rulestead.Manifest.Diff
  alias Rulestead.Store.Command

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)

    seed_fixture!()

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "returns no_changes for identical source and target manifests" do
    {:ok, source} = Rulestead.export_manifest("staging")
    {:ok, target} = Rulestead.export_manifest("test")

    # Align test with staging for a clean diff.
    identical_target =
      put_in(
        target,
        ["flags", Access.at(0), "active_ruleset", "salt"],
        get_in(source, ["flags", Access.at(0), "active_ruleset", "salt"])
      )

    assert {:ok, result} = Diff.diff(source, target_manifest: identical_target)
    assert result["status"] == "no_changes"
    assert result["summary"]["changed_flag_count"] == 0
  end

  test "returns changes and compare-style findings for manifest drift" do
    assert {:ok, source} = Rulestead.export_manifest("staging")
    assert {:ok, result} = Diff.diff(source, target_environment: "test")

    assert result["status"] == "changes"
    assert result["summary"]["changed_flag_count"] == 1
    assert Enum.any?(result["findings"], &(&1["code"] == "target_drift"))
  end

  test "json rendering stays pure and deterministic" do
    assert {:ok, source} = Rulestead.export_manifest("staging")
    assert {:ok, result} = Diff.diff(source, target_environment: "test")

    json = Rulestead.Manifest.Render.render_json(result)
    assert {:ok, decoded} = Jason.decode(json)
    assert decoded["status"] == "changes"
    assert json == Rulestead.Manifest.Render.render_json(decoded)
  end

  defp seed_fixture! do
    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging", "test"]})
               )
             )

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command("checkout-redesign", "staging", valid_ruleset_attrs(%{salt: "checkout-redesign:v2"}))
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "staging")
             )

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command("checkout-redesign", "test", valid_ruleset_attrs(%{salt: "checkout-redesign:v1"}))
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "test")
             )
  end
end

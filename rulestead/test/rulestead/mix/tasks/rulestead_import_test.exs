# credo:disable-for-this-file
defmodule Rulestead.Mix.Tasks.RulesteadImportTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Mix.Tasks.Rulestead.Import
  alias Rulestead.Fake
  alias Rulestead.Manifest.{Plan, Result}
  alias Rulestead.Store.Command

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)

    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   key: "checkout-redesign",
                   environment_keys: ["staging", "test"]
                 })
               )
             )

    publish_ruleset!(
      "checkout-redesign",
      "staging",
      valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
    )

    publish_ruleset!(
      "checkout-redesign",
      "test",
      valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
    )

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "compute_plan returns a saved plan artifact and locked exit code semantics" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    assert {:ok, result} = Import.compute_plan(manifest, target_environment: "test")

    assert result["status"] == "changes"
    assert Result.exit_code(result) == 2

    assert {:ok, serialized} = Plan.serialize(result["details"]["plan"])
    assert {:ok, reloaded} = Plan.load(serialized)
    assert reloaded["target_environment_key"] == "test"
  end

  test "compute_apply requires a plan artifact plus a reason" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    assert {:ok, planned} = Import.compute_plan(manifest, target_environment: "test")
    plan = planned["details"]["plan"]

    assert {:ok, applied} = Import.compute_apply(plan, reason: "sync target")
    assert applied["status"] == "applied"
    assert Result.exit_code(applied) == 0

    assert {:ok, invalid} = Import.compute_apply(plan, [])
    assert invalid["status"] == "invalid"
    assert Result.exit_code(invalid) == 3
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset_attrs) do
    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command(flag_key, environment_key, ruleset_attrs)
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(publish_ruleset_command(flag_key, environment_key))
  end
end

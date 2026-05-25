defmodule Rulestead.Manifest.ImportTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.Fake
  alias Rulestead.Manifest.{Import, Plan}
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

  test "plan builds a deterministic saved plan artifact without mutating" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    assert {:ok, result} = Import.plan(manifest, target_environment: "test")

    assert result["status"] == "changes"
    assert result["summary"]["target_environment_key"] == "test"

    plan = result["details"]["plan"]
    assert plan["mode"] == "import"
    assert plan["target_environment_key"] == "test"
    assert plan["flag_keys"] == ["checkout-redesign"]
    assert String.starts_with?(plan["plan_token"], "plan_")
    assert plan["dependency_closure_keys"] == ["audience:vip-users"]

    assert {:ok, serialized} = Plan.serialize(plan)
    assert {:ok, reloaded} = Plan.load(serialized)
    assert reloaded == plan

    assert {:ok, target_payload} = Rulestead.fetch_flag("checkout-redesign", "test")
    assert target_payload.active_ruleset.salt == "checkout-redesign:v1"
  end

  test "apply only accepts a saved plan artifact and detects stale target drift" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    assert {:ok, planned} = Import.plan(manifest, target_environment: "test")
    plan = planned["details"]["plan"]

    assert {:error, %Rulestead.Error{message: "apply plan kind is unsupported"}} =
             Import.apply(manifest, reason: "raw manifest should fail")

    publish_ruleset!("checkout-redesign", "test", valid_ruleset_attrs(%{salt: "checkout-redesign:v3"}))

    assert {:ok, stale} = Import.apply(plan, reason: "retry")
    assert stale["status"] == "stale"
  end

  test "apply from a saved plan mutates non-protected targets" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    assert {:ok, planned} = Import.plan(manifest, target_environment: "test")
    plan = planned["details"]["plan"]

    assert {:ok, applied} = Import.apply(plan, reason: "sync test from staging")
    assert applied["status"] == "applied"

    assert {:ok, payload} = Rulestead.fetch_flag("checkout-redesign", "test")
    assert payload.active_ruleset.salt == "checkout-redesign:v2"
  end

  test "import preview emits tenant-sensitive findings on mismatch and widening" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging", tenant_key: "acme")

    assert {:ok, mismatch_result} = Import.plan(manifest, target_environment: "test", tenant_key: "other")
    assert Enum.any?(mismatch_result["findings"], &(&1["code"] == "mismatched_tenant_scope"))

    assert {:ok, widen_result} = Import.plan(manifest, target_environment: "test")
    assert Enum.any?(widen_result["findings"], &(&1["code"] == "widened_tenant_scope"))
  end

  test "apply rejects saved plan when live scope diverges" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging", tenant_key: "acme")
    assert {:ok, planned} = Import.plan(manifest, target_environment: "test", tenant_key: "acme")
    plan = planned["details"]["plan"]

    assert {:ok, result1} = Import.apply(plan, reason: "tenant drifted", tenant_key: "other")
    assert result1["status"] == "stale"
    assert Enum.any?(result1["findings"], &(&1["message"] =~ "tenant drifted"))

    assert {:ok, result2} = Import.apply(plan, reason: "tenant drifted without tenant_key")
    assert result2["status"] == "stale"
    assert Enum.any?(result2["findings"], &(&1["message"] =~ "tenant drifted"))
  end

  defp seed_fixture! do
    seed_fake_audience!("vip-users")

    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "checkout-redesign", environment_keys: ["staging", "test"]})
               )
             )

    publish_ruleset!("checkout-redesign", "staging", valid_ruleset_attrs(%{salt: "checkout-redesign:v2"}))
    publish_ruleset!("checkout-redesign", "test", valid_ruleset_attrs(%{salt: "checkout-redesign:v1"}))
  end

  defp seed_fake_audience!(key) do
    now = Rulestead.Fake.Control.now!()

    Rulestead.Fake.Control.restore!(
      Rulestead.Fake.Control.snapshot!()
      |> Map.update!(:audiences, fn audiences ->
        Map.put(audiences, key, %{
          id: "aud-#{key}",
          key: key,
          name: "Audience #{key}",
          description: "Seeded audience",
          inserted_at: now,
          updated_at: now,
          archived_at: nil
        })
      end)
    )
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset_attrs) do
    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command(flag_key, environment_key, ruleset_attrs)
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               publish_ruleset_command(flag_key, environment_key)
             )
  end
end

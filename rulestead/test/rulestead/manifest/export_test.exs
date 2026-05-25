defmodule Rulestead.Manifest.ExportTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{Fake, Manifest}
  alias Rulestead.Store.Command

  setup do
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)

    on_exit(fn ->
      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    seed_manifest_fixture!()

    :ok
  end

  test "exports one deterministic environment-bounded manifest with published authored state only" do
    assert {:ok, manifest} = Rulestead.export_manifest("staging")

    assert manifest["schema_version"] == 1
    assert manifest["kind"] == "rulestead_environment_manifest"
    assert manifest["environment_key"] == "staging"
    assert Enum.map(manifest["flags"], & &1["flag_key"]) == ["beta-banner", "checkout-redesign"]

    checkout =
      Enum.find(manifest["flags"], &(&1["flag_key"] == "checkout-redesign"))

    assert checkout["flag"] == %{
             "default_value" => %{"value" => false},
             "description" => "Release the new checkout flow",
             "flag_type" => "release",
             "owner" => "growth",
             "permanent" => true,
             "tags" => ["checkout", "release"],
             "value_type" => "boolean"
           }

    assert checkout["environment"] == %{
             "active_ruleset_version" => 1,
             "status" => "active"
           }

    assert checkout["active_ruleset"]["version"] == 1
    assert checkout["active_ruleset"]["salt"] == "checkout-redesign:v1"
    assert checkout["active_ruleset"]["metadata"] == %{"source" => "contract"}
    assert Enum.any?(checkout["active_ruleset"]["rules"], &(&1["audience_key"] == "vip-users"))

    refute manifest_json(manifest) =~ "draft_rulesets"
    refute manifest_json(manifest) =~ "inserted_at"
    refute manifest_json(manifest) =~ "updated_at"
    refute manifest_json(manifest) =~ "kill_switch_variant_key"
    refute manifest_json(manifest) =~ "compare_token"
  end

  test "supports explicit sorted flag filters" do
    assert {:ok, manifest} =
             Rulestead.export_manifest("staging", flag_keys: ["checkout-redesign", "beta-banner"])

    assert Enum.map(manifest["flags"], & &1["flag_key"]) == ["beta-banner", "checkout-redesign"]
  end

  test "omits flags without a published ruleset in the selected environment" do
    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{key: "draft-only", environment_keys: ["staging"]})
               )
             )

    assert {:ok, manifest} = Rulestead.export_manifest("staging")
    refute Enum.any?(manifest["flags"], &(&1["flag_key"] == "draft-only"))
  end

  test "returns an error when the environment does not exist" do
    assert {:error, %Rulestead.Error{message: "environment was not found"}} =
             Rulestead.export_manifest("missing")
  end

  defp seed_manifest_fixture! do
    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   key: "checkout-redesign",
                   environment_keys: ["staging", "production"]
                 })
               )
             )

    assert {:ok, _} =
             Rulestead.create_flag(
               Command.CreateFlag.new(
                 valid_flag_attrs(%{
                   key: "beta-banner",
                   description: "Ship the beta banner",
                   environment_keys: ["staging"],
                   tags: ["banner", "beta"]
                 })
               )
             )

    publish_ruleset!("checkout-redesign", "staging", valid_ruleset_attrs())

    publish_ruleset!(
      "checkout-redesign",
      "production",
      valid_ruleset_attrs(%{salt: "checkout-redesign:prod"})
    )

    publish_ruleset!("beta-banner", "staging", valid_ruleset_attrs(%{salt: "beta-banner:v1"}))

    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 "staging",
                 valid_ruleset_attrs(%{salt: "checkout-redesign:draft"})
               )
             )
  end

  defp publish_ruleset!(flag_key, environment_key, ruleset_attrs, publish_opts \\ []) do
    assert {:ok, _} =
             Rulestead.save_draft_ruleset(
               save_draft_command(flag_key, environment_key, ruleset_attrs)
             )

    assert {:ok, _} =
             Rulestead.publish_ruleset(
               publish_ruleset_command(flag_key, environment_key, publish_opts)
             )
  end

  defp manifest_json(manifest) do
    {:ok, json} = Manifest.serialize(manifest)
    json
  end
end

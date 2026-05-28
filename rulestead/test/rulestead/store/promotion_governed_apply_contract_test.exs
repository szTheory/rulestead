# credo:disable-for-this-file
defmodule Rulestead.Store.PromotionGovernedApplyContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{Fake, Store.Command}

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)

    seed_promotable_flag!()

    on_exit(fn ->
      case previous_policy do
        nil -> Application.delete_env(:rulestead, :admin_policy)
        value -> Application.put_env(:rulestead, :admin_policy, value)
      end

      case previous_store do
        nil -> Application.delete_env(:rulestead, :store)
        value -> Application.put_env(:rulestead, :store, value)
      end
    end)

    :ok
  end

  test "saved-plan promote apply submits governed execution instead of direct protected-target rejection" do
    assert {:ok, planned} =
             Rulestead.plan_promotion("staging", "production", tenant_key: "acme")

    plan = planned["details"]["plan"]

    assert plan["mode"] == "promote"
    assert plan["status"] == "governance_required"
    assert plan["tenant_key"] == "acme"

    assert {:ok, queued} =
             Rulestead.apply_promotion_plan(plan,
               reason: "Ship reviewed promotion",
               tenant_key: "acme"
             )

    assert queued["status"] == "queued"
    assert queued["summary"]["target_environment_key"] == "production"

    change_request_id = queued["summary"]["change_request_id"]

    assert {:ok, %{change_request: change_request}} =
             Rulestead.fetch_change_request(Command.FetchChangeRequest.new(change_request_id))

    assert change_request.action == :promote_environment
    assert change_request.environment_key == "production"
    assert change_request.command["tenant_key"] == "acme"
    assert change_request.command["compare_token"] == plan["compare_token"]
    assert change_request.command["target_fingerprint"] == plan["target_fingerprint"]
  end

  defp seed_promotable_flag! do
    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["staging", "production"]
      })
    )

    assert {:ok, _} =
             Rulestead.Fake.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 "staging",
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v2"})
               )
             )

    assert {:ok, _} =
             Rulestead.Fake.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "staging")
             )

    assert {:ok, _} =
             Rulestead.Fake.save_draft_ruleset(
               save_draft_command(
                 "checkout-redesign",
                 "production",
                 valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
               )
             )

    assert {:ok, _} =
             Rulestead.Fake.publish_ruleset(
               publish_ruleset_command("checkout-redesign", "production")
             )
  end

  defmodule GovernancePolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, :promote_environment, _resource, "production"), do: true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
  end
end

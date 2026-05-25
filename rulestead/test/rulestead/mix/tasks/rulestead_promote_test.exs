defmodule Rulestead.Mix.Tasks.RulesteadPromoteTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Mix.Tasks.Rulestead.Promote
  alias Rulestead.{Fake, Manifest.Result, Store.Command}

  setup do
    previous_policy = Application.get_env(:rulestead, :admin_policy)
    previous_store = Application.get_env(:rulestead, :store)

    Rulestead.Fake.Control.ensure_started()
    Rulestead.Fake.Control.reset!()
    Application.put_env(:rulestead, :store, Fake)
    Application.put_env(:rulestead, :admin_policy, __MODULE__.AllowPolicy)

    seed_fake_audience!("vip-users")
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

  test "compute_plan returns a deterministic saved promote plan artifact" do
    assert {:ok, result} =
             Promote.compute_plan("staging", "test", tenant_key: "acme")

    assert result["status"] == "changes"
    assert Result.exit_code(result) == 2

    plan = result["details"]["plan"]
    assert plan["mode"] == "promote"
    assert plan["source_environment_key"] == "staging"
    assert plan["target_environment_key"] == "test"
    assert plan["flag_keys"] == ["checkout-redesign"]
    assert plan["tenant_key"] == "acme"
    assert String.starts_with?(plan["compare_token"], "cmp_")
    assert String.starts_with?(plan["plan_token"], "plan_")
  end

  test "compute_apply applies non-protected plans and reports stale drift" do
    assert {:ok, planned} = Promote.compute_plan("staging", "test")
    plan = planned["details"]["plan"]

    assert {:ok, applied} = Promote.compute_apply(plan, reason: "sync test")
    assert applied["status"] == "applied"
    assert Result.exit_code(applied) == 0

    publish_ruleset!(
      "checkout-redesign",
      "test",
      valid_ruleset_attrs(%{salt: "checkout-redesign:v3"})
    )

    assert {:ok, stale_plan} = Promote.compute_plan("staging", "test")
    stale = stale_plan["details"]["plan"]

    publish_ruleset!(
      "checkout-redesign",
      "test",
      valid_ruleset_attrs(%{salt: "checkout-redesign:v4"})
    )

    assert {:ok, stale_result} = Promote.compute_apply(stale, reason: "retry")
    assert stale_result["status"] == "stale"
    assert Result.exit_code(stale_result) == 3
  end

  test "compute_apply queues protected-target plans through governance" do
    Application.put_env(:rulestead, :admin_policy, __MODULE__.GovernancePolicy)

    assert {:ok, planned} =
             Promote.compute_plan("staging", "production", tenant_key: "acme")

    assert planned["status"] == "governance_required"

    plan = planned["details"]["plan"]

    assert {:ok, queued} =
             Promote.compute_apply(plan,
               reason: "ship reviewed promotion",
               tenant_key: "acme"
             )

    assert queued["status"] == "queued"
    assert Result.exit_code(queued) == 0

    assert {:ok, %{change_request: change_request}} =
             Rulestead.fetch_change_request(
               Command.FetchChangeRequest.new(queued["summary"]["change_request_id"])
             )

    assert change_request.command["tenant_key"] == "acme"
    assert change_request.command["compare_token"] == plan["compare_token"]
  end

  defp seed_promotable_flag! do
    Rulestead.Fake.Control.put_flag!(
      valid_flag_attrs(%{
        key: "checkout-redesign",
        environment_keys: ["staging", "test", "production"]
      })
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

    publish_ruleset!(
      "checkout-redesign",
      "production",
      valid_ruleset_attrs(%{salt: "checkout-redesign:v1"})
    )
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
             Rulestead.publish_ruleset(publish_ruleset_command(flag_key, environment_key))
  end

  defmodule AllowPolicy do
    @behaviour Rulestead.Admin.Policy

    @impl true
    def can?(_actor, _action, _resource, _environment_key), do: true

    @impl true
    def change_request_required?(_actor, _action, _resource, _environment_key), do: false

    @impl true
    def allow_self_approval?(_actor, _action, _resource, _environment_key), do: true
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

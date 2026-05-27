# credo:disable-for-this-file
defmodule Rulestead.RolloutAutoAdvanceContractTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_phase50_schema!()
    ensure_auto_advance_schema!()
    :ok
  end

  test "upsert and fetch policy round-trip" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-roundtrip-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      policy_attrs = %{
        enabled: true,
        observation_window_seconds: 300,
        next_stage: "canary-50",
        next_percentage: 50
      }

      assert {:ok, %{policy: upserted}} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   policy_attrs
                 )
               )

      assert upserted.enabled == true
      assert upserted.observation_window_seconds == 300
      assert upserted.next_stage == "canary-50"
      assert upserted.next_percentage == 50

      assert {:ok, %{policy: fetched}} =
               adapter.fetch_rollout_auto_advance_policy(
                 Command.FetchRolloutAutoAdvancePolicy.new(flag_key, "test", "variant-split")
               )

      assert fetched.enabled == upserted.enabled
      assert fetched.observation_window_seconds == upserted.observation_window_seconds
      assert fetched.next_stage == upserted.next_stage
      assert fetched.next_percentage == upserted.next_percentage
    end)
  end

  test "evaluate blocked when policy disabled" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-disabled-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, _} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   %{enabled: false}
                 )
               )

      assert {:ok, %{eligibility: eligibility}} =
               adapter.evaluate_rollout_auto_advance(
                 Command.EvaluateRolloutAutoAdvance.new(
                   flag_key,
                   "test",
                   "variant-split",
                   %{
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     evaluated_at: ~U[2025-12-31 12:06:00Z],
                     signal_facts: [healthy_signal_fact()]
                   }
                 )
               )

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "auto_advance_disabled"))
    end)
  end

  test "evaluate eligible when healthy after window close" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-eligible-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, _} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   complete_policy_attrs()
                 )
               )

      assert {:ok, %{eligibility: eligibility}} =
               adapter.evaluate_rollout_auto_advance(
                 Command.EvaluateRolloutAutoAdvance.new(
                   flag_key,
                   "test",
                   "variant-split",
                   %{
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     evaluated_at: ~U[2025-12-31 12:06:00Z],
                     signal_facts: [healthy_signal_fact()]
                   }
                 )
               )

      assert eligibility.status == :eligible
      assert eligibility.reasons == []
    end)
  end

  test "evaluate blocked on pending_data before window close" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-pending-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, _} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   complete_policy_attrs()
                 )
               )

      assert {:ok, %{eligibility: eligibility}} =
               adapter.evaluate_rollout_auto_advance(
                 Command.EvaluateRolloutAutoAdvance.new(
                   flag_key,
                   "test",
                   "variant-split",
                   %{
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     evaluated_at: ~U[2025-12-31 12:04:00Z],
                     signal_facts: [healthy_signal_fact(~U[2025-12-31 12:04:00Z])]
                   }
                 )
               )

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "monitoring_window_active"))
    end)
  end

  test "evaluate does not advance rollout stage" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-no-advance-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, %{decision: _advanced}} =
               adapter.advance_rollout(
                 Command.AdvanceRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-50",
                     percentage: 50,
                     monitoring_window_started_at: ~U[2025-12-31 12:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z]
                   },
                   metadata: %{request_id: "req-#{flag_key}-advance", source: :admin_ui}
                 )
               )

      assert {:ok, %{decision: stabilized}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-50",
                     monitoring_window_started_at: ~U[2025-12-31 12:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     signal_facts: [healthy_signal_fact()]
                   },
                   metadata: %{request_id: "req-#{flag_key}-healthy", source: :guardrail_automation}
                 )
               )

      assert stabilized.decision_state == :healthy

      assert {:ok, _} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   complete_policy_attrs(%{next_stage: "canary-100", next_percentage: 100})
                 )
               )

      assert {:ok, payload_before} =
               adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, "test"))

      rule_before =
        Enum.find(payload_before.active_ruleset.rules, &(&1.key == "variant-split"))

      assert rule_before.rollout.percentage == 50

      assert {:ok, %{decision: status_before}} =
               adapter.fetch_guardrail_status(
                 Command.FetchGuardrailStatus.new(flag_key, "test",
                   rule_key: "variant-split",
                   stage: "canary-50"
                 )
               )

      assert {:ok, %{eligibility: eligibility}} =
               adapter.evaluate_rollout_auto_advance(
                 Command.EvaluateRolloutAutoAdvance.new(
                   flag_key,
                   "test",
                   "variant-split",
                   %{
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     evaluated_at: ~U[2025-12-31 12:06:00Z],
                     signal_facts: [healthy_signal_fact()]
                   }
                 )
               )

      assert eligibility.status == :eligible

      assert {:ok, payload_after} =
               adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, "test"))

      rule_after = Enum.find(payload_after.active_ruleset.rules, &(&1.key == "variant-split"))
      assert rule_after.rollout.percentage == 50

      assert {:ok, %{decision: status_after}} =
               adapter.fetch_guardrail_status(
                 Command.FetchGuardrailStatus.new(flag_key, "test",
                   rule_key: "variant-split",
                   stage: "canary-50"
                 )
               )

      assert status_after.decision_state == status_before.decision_state
      assert status_after.effective_percentage == status_before.effective_percentage
    end)
  end

  test "ROL-07 guarded rollout rollback still works with auto-advance policy enabled" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      suffix = adapter_suffix(adapter)
      flag_key = "aa-rollback-#{suffix}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, _} =
               adapter.upsert_rollout_auto_advance_policy(
                 Command.UpsertRolloutAutoAdvancePolicy.new(
                   flag_key,
                   "test",
                   "variant-split",
                   complete_policy_attrs()
                 )
               )

      assert {:ok, %{decision: _advanced}} =
               adapter.advance_rollout(
                 Command.AdvanceRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-50",
                     percentage: 50,
                     monitoring_window_started_at: ~U[2025-12-31 12:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z]
                   },
                   metadata: %{request_id: "req-#{flag_key}-advance-50", source: :admin_ui}
                 )
               )

      assert {:ok, %{decision: stabilized}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-50",
                     monitoring_window_started_at: ~U[2025-12-31 12:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 12:05:00Z],
                     signal_facts: [healthy_signal_fact()]
                   },
                   metadata: %{request_id: "req-#{flag_key}-healthy", source: :guardrail_automation}
                 )
               )

      assert stabilized.decision_state == :healthy

      assert {:ok, %{decision: _advanced}} =
               adapter.advance_rollout(
                 Command.AdvanceRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-100",
                     percentage: 100,
                     monitoring_window_started_at: ~U[2025-12-31 13:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 13:05:00Z]
                   },
                   metadata: %{request_id: "req-#{flag_key}-advance-100", source: :admin_ui}
                 )
               )

      assert {:ok, %{decision: breached}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-100",
                     monitoring_window_started_at: ~U[2025-12-31 13:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 13:05:00Z],
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :breached,
                         reason: :breached,
                         threshold_operator: :gte,
                         threshold_value: 0.05,
                         observed_value: 0.14,
                         evaluated_at: ~U[2025-12-31 13:06:00Z]
                       }
                     ]
                   },
                   metadata: %{request_id: "req-#{flag_key}-breach", source: :guardrail_automation}
                 )
               )

      assert breached.decision_state == :rollback_triggered

      assert {:ok, payload} =
               adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, "test"))

      rule = Enum.find(payload.active_ruleset.rules, &(&1.key == "variant-split"))
      assert rule.rollout.percentage == 50

      assert {:ok, %{decision: latest}} =
               adapter.fetch_guardrail_status(
                 Command.FetchGuardrailStatus.new(flag_key, "test",
                   rule_key: "variant-split",
                   stage: "canary-100"
                 )
               )

      assert latest.decision_state == :rollback_triggered
    end)
  end

  defp complete_policy_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        enabled: true,
        observation_window_seconds: 300,
        next_stage: "canary-50",
        next_percentage: 50
      },
      overrides
    )
  end

  defp healthy_signal_fact(evaluated_at \\ ~U[2025-12-31 12:06:00Z]) do
    %{
      signal_key: "checkout_error_rate",
      status: :healthy,
      reason: :healthy,
      threshold_operator: :gte,
      threshold_value: 0.05,
      observed_value: 0.01,
      evaluated_at: evaluated_at
    }
  end

  defp seed_published_rollout!(adapter, flag_key) do
    assert {:ok, _} =
             adapter.create_flag(
               Command.CreateFlag.new(
                 StoreFixtures.valid_flag_attrs(%{key: flag_key, permanent: true}),
                 actor: %{id: "creator", type: "operator", display: "Creator"}
               )
             )

    assert {:ok, _} =
             adapter.save_draft_ruleset(
               StoreFixtures.save_draft_command(
                 flag_key,
                 "test",
                 StoreFixtures.guarded_rollout_ruleset_attrs()
               )
             )

    assert {:ok, _} =
             adapter.publish_ruleset(StoreFixtures.publish_ruleset_command(flag_key, "test"))
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()
  defp reset_adapter!(StoreEcto), do: :ok

  defp adapter_suffix(Rulestead.Fake), do: "fake"
  defp adapter_suffix(StoreEcto), do: "ecto"

  defp ensure_phase50_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS guardrail_decisions (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      flag_key text NOT NULL,
      environment_key text NOT NULL,
      rule_key text NOT NULL,
      stage text NOT NULL,
      tenant_key text,
      decision_state text NOT NULL,
      action_type text NOT NULL,
      decision_reason text,
      effective_percentage integer,
      rollout_salt text,
      variant_fingerprint text,
      monitoring_window_started_at timestamp(6) with time zone,
      monitoring_window_ends_at timestamp(6) with time zone,
      occurred_at timestamp(6) with time zone NOT NULL,
      signal_facts jsonb[] NOT NULL DEFAULT '{}',
      guardrail_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
      authored_snapshot jsonb,
      rollback_target_snapshot jsonb,
      correlation_id text,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone
    )")
  end

  defp ensure_auto_advance_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rollout_auto_advance_policies (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      flag_key text NOT NULL,
      environment_key text NOT NULL,
      rule_key text NOT NULL,
      enabled boolean NOT NULL DEFAULT false,
      observation_window_seconds integer,
      next_stage text,
      next_percentage integer,
      metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
      inserted_at timestamp(6) with time zone NOT NULL,
      updated_at timestamp(6) with time zone
    )")

    Rulestead.Repo.query!(
      "CREATE UNIQUE INDEX IF NOT EXISTS rollout_auto_advance_policies_flag_key_environment_key_rule_key_index ON rollout_auto_advance_policies (flag_key, environment_key, rule_key)"
    )
  end
end

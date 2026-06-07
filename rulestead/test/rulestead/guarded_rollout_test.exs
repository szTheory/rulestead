# credo:disable-for-this-file
defmodule Rulestead.GuardedRolloutTest do
  use Rulestead.RepoCase, async: false

  alias Rulestead.Store.Command
  alias Rulestead.Store.Ecto, as: StoreEcto
  alias Rulestead.StoreFixtures

  @adapters [Rulestead.Fake, StoreEcto]

  setup do
    ensure_phase50_schema!()
    :ok
  end

  test "guarded rollout records a stable healthy stage and rolls back to it on breach" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "checkout-rollback-#{adapter_suffix(adapter)}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, %{decision: advanced}} =
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

      assert advanced.decision_state == :pending_data

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
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :healthy,
                         reason: :healthy,
                         threshold_operator: :gte,
                         threshold_value: 0.05,
                         observed_value: 0.01,
                         evaluated_at: ~U[2025-12-31 12:06:00Z]
                       }
                     ]
                   },
                   metadata: %{
                     request_id: "req-#{flag_key}-healthy",
                     source: :guardrail_automation
                   }
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
                   metadata: %{
                     request_id: "req-#{flag_key}-breach",
                     source: :guardrail_automation
                   }
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

  test "stale data after the monitoring window holds the rollout without mutating authored state" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "checkout-held-#{adapter_suffix(adapter)}"

      seed_published_rollout!(adapter, flag_key)

      assert {:ok, %{decision: _advanced}} =
               adapter.advance_rollout(
                 Command.AdvanceRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-60",
                     percentage: 60,
                     monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z]
                   },
                   metadata: %{request_id: "req-#{flag_key}-advance", source: :admin_ui}
                 )
               )

      assert {:ok, %{decision: held}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-60",
                     monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z],
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :failed_closed,
                         reason: :stale,
                         evaluated_at: ~U[2025-12-31 14:06:00Z]
                       }
                     ]
                   },
                   metadata: %{request_id: "req-#{flag_key}-held", source: :guardrail_automation}
                 )
               )

      assert held.decision_state == :held
      assert held.decision_reason == "stale"

      assert {:ok, payload} =
               adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, "test"))

      rule = Enum.find(payload.active_ruleset.rules, &(&1.key == "variant-split"))
      assert rule.rollout.percentage == 60
    end)
  end

  test "insufficient sample after the monitoring window holds the rollout without mutating authored state" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "checkout-insufficient-sample-#{adapter_suffix(adapter)}"

      seed_published_rollout!(adapter, flag_key)
      advance_rollout!(adapter, flag_key, "canary-60", 60)

      assert {:ok, %{decision: held}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-60",
                     monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z],
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :failed_closed,
                         reason: :insufficient_sample,
                         evaluated_at: ~U[2025-12-31 14:06:00Z]
                       }
                     ]
                   },
                   metadata: %{request_id: "req-#{flag_key}-held", source: :guardrail_automation}
                 )
               )

      assert held.decision_state == :held
      assert held.decision_reason == "insufficient_sample"
      assert_rollout_percentage(adapter, flag_key, 60)
    end)
  end

  test "terminal host seam faults hold the rollout without mutating authored state" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "checkout-unsupported-signal-#{adapter_suffix(adapter)}"

      seed_published_rollout!(adapter, flag_key)
      advance_rollout!(adapter, flag_key, "canary-60", 60)

      assert {:ok, %{decision: held}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-60",
                     monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z],
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :failed_closed,
                         reason: :unsupported_signal,
                         evaluated_at: ~U[2025-12-31 14:06:00Z]
                       }
                     ]
                   },
                   metadata: %{request_id: "req-#{flag_key}-held", source: :guardrail_automation}
                 )
               )

      assert held.decision_state == :held
      assert held.decision_reason == "unsupported_signal"
      assert_rollout_percentage(adapter, flag_key, 60)
    end)
  end

  test "breach without a recorded stable target degrades to hold" do
    Enum.each(@adapters, fn adapter ->
      reset_adapter!(adapter)
      flag_key = "checkout-missing-stable-target-#{adapter_suffix(adapter)}"

      seed_published_rollout!(adapter, flag_key)
      advance_rollout!(adapter, flag_key, "canary-60", 60)

      assert {:ok, %{decision: held}} =
               adapter.evaluate_guarded_rollout(
                 Command.EvaluateGuardedRollout.new(
                   flag_key,
                   "test",
                   %{
                     rule_key: "variant-split",
                     stage: "canary-60",
                     monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                     monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z],
                     signal_facts: [
                       %{
                         signal_key: "checkout_error_rate",
                         status: :breached,
                         reason: :breached,
                         threshold_operator: :gte,
                         threshold_value: 0.05,
                         observed_value: 0.14,
                         evaluated_at: ~U[2025-12-31 14:06:00Z]
                       }
                     ]
                   },
                   metadata: %{request_id: "req-#{flag_key}-held", source: :guardrail_automation}
                 )
               )

      assert held.decision_state == :held
      assert held.decision_reason == "stable_target_missing"
      assert_rollout_percentage(adapter, flag_key, 60)
    end)
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

  defp advance_rollout!(adapter, flag_key, stage, percentage) do
    assert {:ok, %{decision: _advanced}} =
             adapter.advance_rollout(
               Command.AdvanceRollout.new(
                 flag_key,
                 "test",
                 %{
                   rule_key: "variant-split",
                   stage: stage,
                   percentage: percentage,
                   monitoring_window_started_at: ~U[2025-12-31 14:00:00Z],
                   monitoring_window_ends_at: ~U[2025-12-31 14:05:00Z]
                 },
                 metadata: %{request_id: "req-#{flag_key}-advance", source: :admin_ui}
               )
             )
  end

  defp assert_rollout_percentage(adapter, flag_key, percentage) do
    assert {:ok, payload} = adapter.fetch_flag(StoreFixtures.fetch_flag_command(flag_key, "test"))
    rule = Enum.find(payload.active_ruleset.rules, &(&1.key == "variant-split"))
    assert rule.rollout.percentage == percentage
  end

  defp reset_adapter!(Rulestead.Fake), do: Rulestead.Fake.Control.reset!()
  defp reset_adapter!(StoreEcto), do: :ok

  defp adapter_suffix(Rulestead.Fake), do: "fake"
  defp adapter_suffix(StoreEcto), do: "ecto"

  defp ensure_phase50_schema! do
    Rulestead.Repo.query!("CREATE TABLE IF NOT EXISTS rulestead.guardrail_decisions (
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
end

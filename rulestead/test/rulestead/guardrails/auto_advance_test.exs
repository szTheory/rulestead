defmodule Rulestead.Guardrails.AutoAdvanceTest do
  use ExUnit.Case, async: true

  alias Rulestead.Guardrails.AutoAdvance

  @complete_policy %{
    enabled: true,
    observation_window_seconds: 300,
    next_stage: "canary-50",
    next_percentage: 50,
    flag_key: "f",
    environment_key: "test",
    rule_key: "r"
  }

  @healthy_fact %{
    signal_key: "err",
    status: :healthy,
    reason: :healthy,
    evaluated_at: ~U[2025-12-31 12:06:00Z]
  }

  @ends_at ~U[2025-12-31 12:05:00Z]
  @evaluated_at ~U[2025-12-31 12:06:00Z]

  defp evaluate(policy, opts) do
    {:ok, eligibility} = AutoAdvance.evaluate_eligibility(policy, opts)
    eligibility
  end

  defp base_opts(overrides \\ []) do
    Keyword.merge(
      [
        signal_facts: [@healthy_fact],
        monitoring_window_ends_at: @ends_at,
        evaluated_at: @evaluated_at
      ],
      overrides
    )
  end

  describe "evaluate_eligibility/2 fail-closed matrix" do
    test "blocks disabled policy" do
      eligibility =
        evaluate(
          Map.put(@complete_policy, :enabled, false),
          base_opts()
        )

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "auto_advance_disabled"))
    end

    test "blocks enabled policy missing next_stage" do
      eligibility =
        evaluate(
          Map.put(@complete_policy, :next_stage, nil),
          base_opts()
        )

      assert eligibility.status == :blocked

      assert Enum.any?(
               eligibility.reasons,
               &String.contains?(&1, "auto_advance_policy_incomplete")
             )
    end

    test "blocks when monitoring_window_ends_at is nil" do
      eligibility =
        evaluate(@complete_policy, base_opts(monitoring_window_ends_at: nil))

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "monitoring_window_unset"))
    end

    test "blocks when evaluated before monitoring window ends" do
      eligibility =
        evaluate(
          @complete_policy,
          base_opts(evaluated_at: ~U[2025-12-31 12:04:00Z])
        )

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "monitoring_window_active"))
    end

    test "blocks empty facts after monitoring window closes" do
      eligibility =
        evaluate(@complete_policy, base_opts(signal_facts: []))

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "monitoring_window_expired"))
    end

    test "blocks pending_data when stale facts arrive before window close" do
      stale_fact = %{
        signal_key: "err",
        status: :failed_closed,
        reason: :stale,
        evaluated_at: ~U[2025-12-31 12:04:00Z]
      }

      eligibility =
        evaluate(
          @complete_policy,
          base_opts(signal_facts: [stale_fact], evaluated_at: ~U[2025-12-31 12:04:00Z])
        )

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "guardrail_pending_data"))
    end

    test "blocks held when stale facts arrive after window close" do
      stale_fact = %{
        signal_key: "err",
        status: :failed_closed,
        reason: :stale,
        evaluated_at: @evaluated_at
      }

      eligibility =
        evaluate(@complete_policy, base_opts(signal_facts: [stale_fact]))

      assert eligibility.status == :blocked
      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "guardrail_held"))
    end

    test "blocks rollback_triggered when breached fact is present" do
      breached_fact = %{
        signal_key: "err",
        status: :breached,
        reason: :breached,
        threshold_operator: :gte,
        threshold_value: 0.05,
        observed_value: 0.14,
        evaluated_at: @evaluated_at
      }

      eligibility =
        evaluate(@complete_policy, base_opts(signal_facts: [breached_fact]))

      assert eligibility.status == :blocked

      assert Enum.any?(eligibility.reasons, &String.contains?(&1, "guardrail_rollback_triggered"))
    end

    test "eligible with healthy facts, complete policy, and closed monitoring window" do
      eligibility = evaluate(@complete_policy, base_opts())

      assert eligibility.status == :eligible
      assert eligibility.reasons == []
      assert eligibility.monitoring_window_closed? == true
      assert eligibility.decision_summary.state == :healthy
    end
  end
end

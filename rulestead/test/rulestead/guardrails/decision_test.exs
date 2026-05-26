defmodule Rulestead.Guardrails.DecisionTest do
  use ExUnit.Case, async: true

  alias Rulestead.Guardrails.{Decision, SignalFact}

  test "recoverable evidence gaps stay pending during the monitoring window and hold after expiry" do
    fact =
      SignalFact.new(%{
        signal_key: "checkout_error_rate",
        reason: :stale,
        status: :failed_closed,
        evaluated_at: ~U[2026-05-26 12:00:00Z]
      })

    pending =
      Decision.evaluate([fact],
        evaluated_at: ~U[2026-05-26 12:00:00Z],
        monitoring_window_ends_at: ~U[2026-05-26 12:05:00Z]
      )

    held =
      Decision.evaluate([fact],
        evaluated_at: ~U[2026-05-26 12:06:00Z],
        monitoring_window_ends_at: ~U[2026-05-26 12:05:00Z]
      )

    assert pending.state == :pending_data
    assert pending.reason == "stale"
    refute pending.monitoring_window_closed?

    assert held.state == :held
    assert held.reason == "stale"
    assert held.monitoring_window_closed?
  end

  test "terminal seam faults fail closed to held and explicit breaches trigger rollback" do
    held =
      Decision.evaluate([
        SignalFact.new(%{
          signal_key: "checkout_error_rate",
          reason: :unsupported_scope,
          status: :failed_closed
        })
      ])

    rollback =
      Decision.evaluate([
        SignalFact.new(%{
          signal_key: "checkout_error_rate",
          reason: :breached,
          status: :breached,
          threshold_operator: :gte,
          threshold_value: 0.05,
          observed_value: 0.11
        })
      ])

    assert held.state == :held
    assert held.reason == "unsupported_scope"

    assert rollback.state == :rollback_triggered
    assert rollback.reason == "breached"
  end
end

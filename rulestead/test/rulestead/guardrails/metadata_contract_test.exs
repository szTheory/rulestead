defmodule Rulestead.Guardrails.MetadataContractTest do
  use ExUnit.Case, async: true

  alias Rulestead.{AuditEvent, Telemetry}
  alias Rulestead.Guardrails.SignalFact

  test "guardrail metadata reuses tenant provenance validation and bounded evidence context" do
    fact =
      SignalFact.new(%{
        signal_key: "checkout_error_rate",
        status: :failed_closed,
        reason: :stale,
        environment_key: "production",
        tenant_key: "tenant-a",
        environment_scope: :environment,
        tenant_scope: :required,
        scope_source: "explicit",
        threshold_operator: :gte,
        threshold_value: 0.05,
        observed_value: 0.04,
        freshness_window_seconds: 300,
        sample_size: 120,
        min_sample_size: 100,
        captured_at: "2026-05-26T12:00:00Z",
        evaluated_at: "2026-05-26T12:10:00Z",
        metadata: %{source: "host", session_token: "secret"}
      })

    metadata = SignalFact.metadata(fact)

    assert metadata["scope_source"] == "explicit"
    assert metadata["tenant"]["tenant_key"] == "tenant-a"
    assert metadata["tenant"]["validation"]["status"] == "passed"
    assert metadata["evidence"]["reason"] == "stale"
    assert metadata["evidence"]["freshness_window_seconds"] == 300
    assert metadata["evidence"]["sample_size"] == 120
    refute Map.has_key?(metadata["evidence"]["metadata"], "session_token")
  end

  test "audit and telemetry helpers preserve the same bounded guardrail evidence envelope" do
    guardrail = %{
      signal_key: "checkout_error_rate",
      environment_key: "production",
      tenant_key: "tenant-a",
      environment_scope: :environment,
      tenant_scope: :required,
      scope_source: "explicit",
      status: :failed_closed,
      reason: :provider_missing,
      threshold_operator: :gte,
      threshold_value: 0.05,
      observed_value: 0.0,
      freshness_window_seconds: 300,
      sample_size: 0,
      min_sample_size: 100,
      metadata: %{source: "host", session_token: "secret"}
    }

    audit_metadata = AuditEvent.metadata(%{guardrail: guardrail})
    telemetry_metadata = Telemetry.guardrail_metadata(guardrail)

    assert audit_metadata["guardrail"]["tenant"]["validation"]["evidence"] == "same_tenant_guard"
    assert audit_metadata["guardrail"]["evidence"]["reason"] == "provider_missing"
    assert telemetry_metadata[:signal_key] == "checkout_error_rate"
    assert telemetry_metadata[:guardrail_reason] == :provider_missing
    assert telemetry_metadata[:tenant]["tenant_key"] == "tenant-a"
    assert telemetry_metadata[:evidence]["threshold_operator"] == "gte"
  end
end

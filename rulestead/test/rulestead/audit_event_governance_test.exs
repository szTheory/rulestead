defmodule Rulestead.AuditEventGovernanceTest do
  use ExUnit.Case, async: true

  alias Rulestead.AuditEvent

  test "governance metadata fields serialize deterministically" do
    metadata =
      AuditEvent.metadata(%{
        before: %{status: :submitted},
        after: %{status: :approved},
        context: %{
          request_id: "req-123",
          source: "admin_ui",
          change_request_id: "cr-123",
          approval_id: "ap-456",
          governance_action: :publish_ruleset,
          execution_stage: :approval
        },
        request_id: "req-123",
        source: "admin_ui"
      })

    event =
      AuditEvent.serialize(%AuditEvent{
        metadata: metadata
      })

    assert event.metadata["change_request_id"] == "cr-123"
    assert event.metadata["approval_id"] == "ap-456"
    assert event.metadata["governance_action"] == "publish_ruleset"
    assert event.metadata["execution_stage"] == "approval"
    assert event.metadata["request_id"] == "req-123"
    assert event.metadata["source"] == "admin_ui"
  end

  test "governance metadata remains optional and excludes raw session data" do
    metadata =
      AuditEvent.metadata(%{
        context: %{
          request_id: "req-789",
          change_request_id: "cr-789",
          source: "admin_ui",
          nested: %{approval_id: "ap-789"},
          session_id: "sess-123",
          session_token: "secret-token"
        }
      })

    assert metadata["change_request_id"] == "cr-789"
    assert metadata["approval_id"] == nil
    assert metadata["governance_action"] == nil
    assert metadata["execution_stage"] == nil
    assert metadata["context"]["nested"]["approval_id"] == "ap-789"
    refute Map.has_key?(metadata["context"], "session_id")
    refute Map.has_key?(metadata["context"], "session_token")
  end
end

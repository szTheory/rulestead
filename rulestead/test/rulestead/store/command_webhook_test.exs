# credo:disable-for-this-file
defmodule Rulestead.Store.CommandWebhookTest do
  use ExUnit.Case, async: true

  alias Rulestead.Store.Command.ReceiveInboundWebhook
  alias Rulestead.Store.Command.FetchWebhookRecord
  alias Rulestead.Store.Command.ListWebhookRecords

  test "ReceiveInboundWebhook command validates required fields" do
    now = DateTime.utc_now()

    attrs = %{
      provider: "github",
      endpoint_key: "default",
      delivery_id: "del_123",
      received_at: now,
      raw_body_sha256: "sha256:abc",
      verified_state: :accepted,
      correlation_id: "corr_123"
    }

    command = ReceiveInboundWebhook.new(attrs)
    assert command.provider == "github"
    assert command.received_at == now
  end

  test "FetchWebhookRecord command" do
    command = FetchWebhookRecord.new("receipt_123")
    assert command.receipt_id == "receipt_123"
  end

  test "ListWebhookRecords command" do
    command = ListWebhookRecords.new(provider: "github", verified_state: :accepted)
    assert command.provider == "github"
    assert command.verified_state == :accepted
    assert command.limit == 50
  end
end

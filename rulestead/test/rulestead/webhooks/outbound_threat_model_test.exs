# credo:disable-for-this-file
defmodule Rulestead.Webhooks.OutboundThreatModelTest do
  use ExUnit.Case, async: true

  alias Rulestead.Webhooks.DeliverySigner

  test "sign_payload includes deterministic timestamp and signature" do
    headers = DeliverySigner.sign_payload("{\"foo\":\"bar\"}", "secret_123")

    assert Map.has_key?(headers, "Rulestead-Signature")

    sig = headers["Rulestead-Signature"]
    assert sig =~ ~r/^t=\d+,v1=[a-f0-9]{64}$/
  end

  test "sign_payload with nil secret returns empty headers" do
    assert %{} = DeliverySigner.sign_payload("{\"foo\":\"bar\"}", nil)
  end
end

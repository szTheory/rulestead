defmodule Rulestead.Webhooks.InboundHttpTest do
  use Plug.Test
  use Rulestead.RepoCase, async: true

  alias Rulestead.Webhooks.IngressPlug

  defmodule TestAdapter do
    @behaviour Rulestead.Webhooks.Verifier.ProviderAdapter
    def verify_signature(_body, %{"x-test-signature" => "valid"}, _secret), do: :ok
    def verify_signature(_body, _headers, _secret), do: {:error, :invalid_signature}

    def normalize_payload(body, _headers) do
      {:ok,
       %{
         provider: "test",
         endpoint_key: "default",
         delivery_id: "del_123",
         received_at: DateTime.utc_now(),
         payload: Jason.decode!(body),
         metadata: %{},
         correlation_id: "corr_123"
       }}
    end

    def get_delivery_id(_headers), do: "del_123"
    def get_timestamp(_headers), do: nil
  end

  test "successful webhook ingress" do
    body = Jason.encode!(%{action: "ping"})

    conn =
      conn(:post, "/webhooks/test", body)
      |> put_req_header("x-test-signature", "valid")
      |> IngressPlug.call(
        provider: "test",
        provider_adapter: TestAdapter,
        endpoint_key: "default",
        secret: "shhh"
      )

    # IngressPlug doesn't send response on success, it continues to next plug/controller
    assert conn.status == nil
    assert conn.assigns[:rulestead_inbound_event].payload == %{"action" => "ping"}
    assert conn.assigns[:rulestead_webhook_receipt].verified_state == :accepted
  end

  test "failed signature returns 401" do
    body = Jason.encode!(%{action: "ping"})

    conn =
      conn(:post, "/webhooks/test", body)
      |> put_req_header("x-test-signature", "invalid")
      |> IngressPlug.call(
        provider: "test",
        provider_adapter: TestAdapter,
        endpoint_key: "default",
        secret: "shhh"
      )

    assert conn.status == 401
    assert conn.halted
    assert Jason.decode!(conn.resp_body) == %{"error" => "invalid signature"}

    # Check that a rejected receipt was recorded
    {:ok, page} =
      Rulestead.list_webhook_records(
        provider: "test",
        verified_state: :rejected,
        actor: %{id: "admin", roles: [:admin]}
      )

    assert length(page.entries) == 1
  end
end

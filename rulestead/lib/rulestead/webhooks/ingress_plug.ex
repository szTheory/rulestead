# credo:disable-for-this-file
defmodule Rulestead.Webhooks.IngressPlug do
  @moduledoc false
  # Library-owned Plug for inbound webhook ingress.
  # Captures the raw body, verifies signatures, and records receipts.

  import Plug.Conn
  alias Rulestead.Store.Command
  alias Rulestead.Webhooks.Verifier

  def init(opts), do: opts

  def call(conn, opts) do
    provider = Keyword.fetch!(opts, :provider)
    provider_adapter = Keyword.fetch!(opts, :provider_adapter)
    endpoint_key = Keyword.fetch!(opts, :endpoint_key)
    secret = Keyword.fetch!(opts, :secret)

    # We expect raw body to be cached by a custom body reader if Plug.Parsers is used,
    # or we read it here if it's not.
    case get_raw_body(conn) do
      {:ok, raw_body, conn} ->
        headers = Map.new(conn.req_headers)

        case Verifier.verify(raw_body, headers, secret, provider_adapter, opts) do
          {:ok, event} ->
            receipt_command =
              Command.ReceiveInboundWebhook.new(%{
                provider: provider,
                endpoint_key: endpoint_key,
                delivery_id: event.delivery_id,
                attempt_id: event.attempt_id,
                topic: event.topic,
                occurred_at: event.occurred_at,
                received_at: event.received_at,
                raw_body_sha256: :crypto.hash(:sha256, raw_body) |> Base.encode16(case: :lower),
                verification_metadata: event.metadata,
                normalized_payload: event.payload,
                verified_state: :accepted,
                correlation_id: event.correlation_id
              })

            case Rulestead.receive_inbound_webhook(receipt_command) do
              {:ok, receipt} ->
                conn
                |> assign(:rulestead_inbound_event, event)
                |> assign(:rulestead_webhook_receipt, receipt)

              {:error, _error} ->
                # Even if recording fails, we have the verified event
                conn
                |> assign(:rulestead_inbound_event, event)
            end

          {:error, {state, reason}} ->
            # Record rejection
            receipt_command =
              Command.ReceiveInboundWebhook.new(%{
                provider: provider,
                endpoint_key: endpoint_key,
                delivery_id: provider_adapter.get_delivery_id(headers) || "unknown",
                received_at: DateTime.utc_now(),
                raw_body_sha256: :crypto.hash(:sha256, raw_body) |> Base.encode16(case: :lower),
                verified_state: state,
                rejection_reason: reason,
                correlation_id: Ecto.UUID.generate()
              })

            _ = Rulestead.receive_inbound_webhook(receipt_command)

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: reason}))
            |> halt()
        end

      {:error, :body_already_read} ->
        # If body was already read and not cached, we can't verify
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "raw body not available for verification"}))
        |> halt()
    end
  end

  defp get_raw_body(conn) do
    cond do
      # Custom convention for Rulestead body reader
      body = conn.assigns[:rulestead_raw_body] ->
        {:ok, body, conn}

      # Standard Plug body reading
      true ->
        case read_body(conn) do
          {:ok, body, conn} -> {:ok, body, conn}
          {:more, _body, conn} -> {:ok, "", conn}
          _ -> {:error, :body_already_read}
        end
    end
  end
end

defmodule Rulestead.Webhooks.DeliverySigner do
  @moduledoc """
  Explicit signing helper for outbound HTTP payloads and headers.
  Constructs signed headers without exposing secrets in audit logs.
  """

  @doc """
  Signs the JSON string payload with the given secret.
  Returns a map of headers containing the signature.
  """
  def sign_payload(payload_string, secret) when is_binary(payload_string) and is_binary(secret) do
    timestamp = System.system_time(:second) |> to_string()
    
    # Standard HMAC-SHA256 of "timestamp.payload"
    signed_content = "#{timestamp}.#{payload_string}"
    signature = :crypto.mac(:hmac, :sha256, secret, signed_content) |> Base.encode16(case: :lower)

    %{
      "Rulestead-Signature" => "t=#{timestamp},v1=#{signature}"
    }
  end

  def sign_payload(payload_string, nil) when is_binary(payload_string) do
    %{}
  end
end

defmodule Rulestead.Webhooks.Verifier do
  @moduledoc """
  Verifier boundary for raw-body signature, freshness, and replay checks.
  """
  alias Rulestead.Webhooks.InboundEvent

  @type outcome ::
          {:ok, InboundEvent.t()}
          | {:error, {verified_state :: atom(), reason :: String.t()}}

  defmodule ProviderAdapter do
    @moduledoc """
    Behavior for provider-specific webhook verification and normalization.
    """
    @callback verify_signature(raw_body :: String.t(), headers :: map(), secret :: String.t()) ::
                :ok | {:error, :invalid_signature}

    @callback normalize_payload(raw_body :: String.t(), headers :: map()) ::
                {:ok, map()} | {:error, :malformed}

    @callback get_delivery_id(headers :: map()) :: String.t() | nil
    @callback get_timestamp(headers :: map()) :: DateTime.t() | nil
  end

  def verify(raw_body, headers, secret, provider_adapter, opts \\ []) do
    with :ok <- provider_adapter.verify_signature(raw_body, headers, secret),
         :ok <- check_freshness(headers, provider_adapter, opts),
         {:ok, normalized} <- provider_adapter.normalize_payload(raw_body, headers) do
      {:ok, InboundEvent.new(normalized)}
    else
      {:error, :invalid_signature} -> {:error, {:rejected, "invalid signature"}}
      {:error, :stale} -> {:error, {:stale, "webhook delivery is stale"}}
      {:error, :malformed} -> {:error, {:malformed, "payload is malformed"}}
      other -> other
    end
  end

  defp check_freshness(headers, adapter, opts) do
    case adapter.get_timestamp(headers) do
      nil ->
        :ok

      %DateTime{} = timestamp ->
        tolerance = Keyword.get(opts, :tolerance_seconds, 300)
        now = DateTime.utc_now()
        diff = DateTime.diff(now, timestamp)

        if abs(diff) <= tolerance do
          :ok
        else
          {:error, :stale}
        end
    end
  end
end

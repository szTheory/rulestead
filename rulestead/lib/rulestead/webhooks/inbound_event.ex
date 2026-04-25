defmodule Rulestead.Webhooks.InboundEvent do
  @moduledoc """
  A canonical internal envelope representing a verified inbound webhook event.
  """
  defstruct [
    :provider,
    :endpoint_key,
    :delivery_id,
    :attempt_id,
    :topic,
    :occurred_at,
    :received_at,
    :payload,
    :metadata,
    :correlation_id
  ]

  @type t :: %__MODULE__{
          provider: String.t(),
          endpoint_key: String.t(),
          delivery_id: String.t(),
          attempt_id: String.t() | nil,
          topic: String.t() | nil,
          occurred_at: DateTime.t() | nil,
          received_at: DateTime.t(),
          payload: map(),
          metadata: map(),
          correlation_id: String.t()
        }

  def new(attrs) do
    struct!(__MODULE__, attrs)
  end
end

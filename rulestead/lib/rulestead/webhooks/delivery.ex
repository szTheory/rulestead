defmodule Rulestead.Webhooks.Delivery do
  @moduledoc """
  A durable outbound webhook delivery attempt.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "webhook_deliveries" do
    belongs_to :webhook_destination, Rulestead.Webhooks.Destination, type: :binary_id
    belongs_to :webhook_outbound_event, Rulestead.Webhooks.OutboundEvent, type: :binary_id
    
    field :state, Ecto.Enum, values: [:pending, :delivering, :succeeded, :failed, :exhausted], default: :pending
    field :attempt_count, :integer, default: 0
    field :last_attempt_at, :utc_datetime_usec
    field :next_attempt_at, :utc_datetime_usec
    field :terminal_failure_reason, :string
    
    field :last_response_code, :integer
    field :last_response_body, :string
    
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(delivery, attrs) do
    delivery
    |> cast(attrs, [:webhook_destination_id, :webhook_outbound_event_id, :state, :attempt_count, :last_attempt_at, :next_attempt_at, :terminal_failure_reason, :last_response_code, :last_response_body])
    |> validate_required([:webhook_destination_id, :webhook_outbound_event_id, :state, :attempt_count])
  end
end

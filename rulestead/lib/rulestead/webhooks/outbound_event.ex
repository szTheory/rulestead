defmodule Rulestead.Webhooks.OutboundEvent do
  @moduledoc """
  A durable outbound webhook event.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "webhook_outbound_events" do
    field :event_type, :string
    field :payload, :map, default: %{}
    field :resource_type, :string
    field :resource_key, :string
    field :environment_key, :string
    field :correlation_id, :string

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :payload, :resource_type, :resource_key, :environment_key, :correlation_id])
    |> validate_required([:event_type, :payload, :correlation_id])
  end
end

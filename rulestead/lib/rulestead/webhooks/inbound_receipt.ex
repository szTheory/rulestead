defmodule Rulestead.Webhooks.InboundReceipt do
  @moduledoc false
  # A durable record of an inbound webhook delivery attempt.

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "webhook_receipts" do
    field(:provider, :string)
    field(:endpoint_key, :string)
    field(:delivery_id, :string)
    field(:attempt_id, :string)
    field(:topic, :string)
    field(:occurred_at, :utc_datetime_usec)
    field(:received_at, :utc_datetime_usec)
    field(:raw_body_sha256, :string)
    field(:verification_metadata, :map, default: %{})
    field(:normalized_payload, :map)
    field(:dedupe_key, :string)

    field(:verified_state, Ecto.Enum,
      values: [:accepted, :rejected, :malformed, :unsigned, :stale, :replayed]
    )

    field(:rejection_reason, :string)
    field(:correlation_id, :string)
    field(:change_request_id, :binary_id)
    field(:scheduled_execution_id, :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [
      :provider,
      :endpoint_key,
      :delivery_id,
      :attempt_id,
      :topic,
      :occurred_at,
      :received_at,
      :raw_body_sha256,
      :verification_metadata,
      :normalized_payload,
      :dedupe_key,
      :verified_state,
      :rejection_reason,
      :correlation_id,
      :change_request_id,
      :scheduled_execution_id
    ])
    |> validate_required([
      :provider,
      :endpoint_key,
      :delivery_id,
      :received_at,
      :raw_body_sha256,
      :verified_state,
      :correlation_id
    ])
    |> unique_constraint(:correlation_id)
  end

  def accepted?(%__MODULE__{verified_state: :accepted}), do: true
  def accepted?(_), do: false

  def rejected?(%__MODULE__{verified_state: state}) when state != :accepted, do: true
  def rejected?(_), do: false
end

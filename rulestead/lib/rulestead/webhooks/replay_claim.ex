defmodule Rulestead.Webhooks.ReplayClaim do
  @moduledoc """
  A durable record of a seen webhook delivery identity to prevent replays.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "webhook_replay_claims" do
    field :provider, :string, primary_key: true
    field :delivery_id, :string, primary_key: true
    belongs_to :receipt, Rulestead.Webhooks.InboundReceipt, type: :binary_id

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:provider, :delivery_id, :receipt_id])
    |> validate_required([:provider, :delivery_id, :receipt_id])
    |> unique_constraint([:provider, :delivery_id], name: :webhook_replay_claims_pkey)
  end
end

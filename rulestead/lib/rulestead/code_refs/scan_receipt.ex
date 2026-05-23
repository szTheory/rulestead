defmodule Rulestead.CodeRefs.ScanReceipt do
  @moduledoc false
  # Records when the latest accepted code-reference scan dataset arrived.

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "code_reference_scans" do
    field :received_at, :utc_datetime_usec
    field :reference_count, :integer, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(scan_receipt, attrs) do
    scan_receipt
    |> cast(attrs, [:received_at, :reference_count])
    |> validate_required([:received_at, :reference_count])
    |> validate_number(:reference_count, greater_than_or_equal_to: 0)
  end

  @spec latest_query() :: Ecto.Query.t()
  def latest_query do
    from(scan_receipt in __MODULE__,
      order_by: [desc: scan_receipt.received_at, desc: scan_receipt.inserted_at],
      limit: 1
    )
  end
end

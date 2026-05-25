defmodule Rulestead.Flag.LifecycleMetadata do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @modes [:expiring, :permanent]
  @default_sources [:flag_type, :operator_override, :operator_required, :legacy_backfill]

  embedded_schema do
    field(:mode, Ecto.Enum, values: @modes)
    field(:review_by, :date)
    field(:default_source, Ecto.Enum, values: @default_sources)
    field(:default_overridden, :boolean, default: false)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(lifecycle, attrs) do
    lifecycle
    |> cast(attrs, [:mode, :review_by, :default_source, :default_overridden])
    |> validate_required([:mode, :default_source, :default_overridden])
  end
end

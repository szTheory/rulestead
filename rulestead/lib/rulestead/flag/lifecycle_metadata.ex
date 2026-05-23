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

  @spec mode_from_flag(map()) :: :expiring | :permanent
  def mode_from_flag(flag_like) do
    permanent? =
      case Map.get(flag_like, :permanent) || Map.get(flag_like, "permanent") do
        value when value in [true, "true", 1, "1"] -> true
        _other -> false
      end

    if permanent?, do: :permanent, else: :expiring
  end

  @spec default_from_flag(map()) :: map()
  def default_from_flag(flag_like) do
    %{
      mode: mode_from_flag(flag_like),
      review_by:
        Map.get(flag_like, :expected_expiration) || Map.get(flag_like, "expected_expiration"),
      default_source: :legacy_backfill,
      default_overridden: false
    }
  end
end

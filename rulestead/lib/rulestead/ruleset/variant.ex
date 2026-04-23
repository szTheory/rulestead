defmodule Rulestead.Ruleset.Variant do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field(:key, :string)
    field(:value, :map, default: %{})
    field(:weight, :integer)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, [:key, :value, :weight])
    |> update_change(:key, &normalize_string/1)
    |> validate_required([:key, :weight])
    |> validate_length(:key, min: 1, max: 128)
    |> validate_number(:weight, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

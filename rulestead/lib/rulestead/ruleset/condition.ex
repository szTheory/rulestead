defmodule Rulestead.Ruleset.Condition do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  @operators [:equals, :in, :not_in, :gt, :lt, :gte, :lte, :regex, :exists]

  embedded_schema do
    field(:attribute, :string)
    field(:operator, Ecto.Enum, values: @operators)
    field(:value, :map, default: %{})
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(condition, attrs) do
    condition
    |> cast(attrs, [:attribute, :operator, :value])
    |> update_change(:attribute, &normalize_string/1)
    |> validate_required([:attribute, :operator])
    |> validate_length(:attribute, min: 1, max: 255)
  end

  @spec operators() :: [atom()]
  def operators, do: @operators

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

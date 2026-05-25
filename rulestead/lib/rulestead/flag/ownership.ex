defmodule Rulestead.Flag.Ownership do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @owner_kinds [:person, :team, :service]

  embedded_schema do
    field(:owner_ref, :string)
    field(:owner_kind, Ecto.Enum, values: @owner_kinds)
    field(:owner_display, :string)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(ownership, attrs) do
    ownership
    |> cast(attrs, [:owner_ref, :owner_kind, :owner_display])
    |> update_change(:owner_ref, &normalize_string/1)
    |> update_change(:owner_display, &normalize_optional_string/1)
    |> validate_required([:owner_ref, :owner_kind])
    |> validate_length(:owner_ref, min: 1, max: 255)
    |> validate_length(:owner_display, max: 255)
  end

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value), do: value

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(value), do: value
end

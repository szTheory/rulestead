defmodule Rulestead.Audience do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audiences" do
    field(:key, :string)
    field(:description, :string)
    field(:definition, :map, default: %{})
    field(:archived_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(audience, attrs) do
    audience
    |> cast(attrs, [:key, :description, :definition, :archived_at])
    |> update_change(:key, &normalize_key/1)
    |> validate_required([:key, :definition])
    |> validate_length(:key, min: 2, max: 128)
    |> validate_format(:key, ~r/^[a-z0-9][a-z0-9:_-]*$/)
    |> unique_constraint(:key)
  end

  defp normalize_key(value) when is_binary(value), do: String.trim(value)
  defp normalize_key(value), do: value
end

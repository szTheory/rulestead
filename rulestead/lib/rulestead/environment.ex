defmodule Rulestead.Environment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "environments" do
    field(:key, :string)
    field(:name, :string)
    field(:description, :string)

    has_many(:flag_environments, Rulestead.FlagEnvironment)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(environment, attrs) do
    environment
    |> cast(attrs, [:key, :name, :description])
    |> update_change(:key, &normalize_key/1)
    |> update_change(:name, &normalize_string/1)
    |> validate_required([:key, :name])
    |> validate_length(:key, min: 2, max: 64)
    |> validate_length(:name, min: 1, max: 128)
    |> validate_format(:key, ~r/^[a-z0-9][a-z0-9_-]*$/)
    |> unique_constraint(:key)
  end

  defp normalize_key(value) when is_binary(value), do: String.trim(value)
  defp normalize_key(value), do: value

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

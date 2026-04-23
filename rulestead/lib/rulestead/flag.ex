defmodule Rulestead.Flag do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @flag_types [
    :release,
    :experiment,
    :kill_switch,
    :permission,
    :remote_config,
    :operational,
    :migration
  ]
  @value_types [:boolean, :string, :integer, :float, :json, :variant]

  schema "flags" do
    field(:key, :string)
    field(:description, :string)
    field(:flag_type, Ecto.Enum, values: @flag_types)
    field(:value_type, Ecto.Enum, values: @value_types)
    field(:default_value, :map, default: %{})
    field(:owner, :string)
    field(:expected_expiration, :date)
    field(:tags, {:array, :string}, default: [])
    field(:archived_at, :utc_datetime_usec)

    has_many(:flag_environments, Rulestead.FlagEnvironment)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(flag, attrs) do
    flag
    |> cast(attrs, [
      :key,
      :description,
      :flag_type,
      :value_type,
      :default_value,
      :owner,
      :expected_expiration,
      :tags,
      :archived_at
    ])
    |> update_change(:key, &normalize_key/1)
    |> update_change(:owner, &normalize_string/1)
    |> update_change(:tags, &normalize_tags/1)
    |> validate_required([:key, :flag_type, :value_type, :default_value, :owner])
    |> validate_length(:key, min: 2, max: 128)
    |> validate_length(:owner, min: 1, max: 255)
    |> validate_format(:key, ~r/^[a-z0-9][a-z0-9:_-]*$/)
    |> unique_constraint(:key)
  end

  @spec flag_types() :: [atom()]
  def flag_types, do: @flag_types

  @spec value_types() :: [atom()]
  def value_types, do: @value_types

  defp normalize_key(value) when is_binary(value), do: String.trim(value)
  defp normalize_key(value), do: value

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value

  defp normalize_tags(tags) when is_list(tags) do
    tags
    |> Enum.map(&normalize_tag/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp normalize_tags(tags), do: tags

  defp normalize_tag(tag) when is_binary(tag) do
    case String.trim(tag) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_tag(_tag), do: nil
end

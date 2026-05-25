defmodule Rulestead.EnvironmentVersion do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "environment_versions" do
    field(:environment_key, :string)
    field(:version, :integer)
    field(:authored_snapshot, :map, default: %{})
    field(:source_environment_key, :string)
    field(:target_environment_key, :string)
    field(:compare_token, :string)
    field(:source_fingerprint, :string)
    field(:target_fingerprint, :string)
    field(:dependency_closure_keys, {:array, :string}, default: [])
    field(:applied_flag_keys, {:array, :string}, default: [])
    field(:tenant_key, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(environment_version, attrs) do
    environment_version
    |> cast(attrs, [
      :environment_key,
      :tenant_key,
      :version,
      :authored_snapshot,
      :source_environment_key,
      :target_environment_key,
      :compare_token,
      :source_fingerprint,
      :target_fingerprint,
      :dependency_closure_keys,
      :applied_flag_keys,
      :metadata
    ])
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:tenant_key, &normalize_string/1)
    |> update_change(:source_environment_key, &normalize_string/1)
    |> update_change(:target_environment_key, &normalize_string/1)
    |> update_change(:compare_token, &normalize_string/1)
    |> update_change(:source_fingerprint, &normalize_string/1)
    |> update_change(:target_fingerprint, &normalize_string/1)
    |> update_change(:dependency_closure_keys, &normalize_list/1)
    |> update_change(:applied_flag_keys, &normalize_list/1)
    |> update_change(:authored_snapshot, &normalize_map/1)
    |> update_change(:metadata, &normalize_map/1)
    |> validate_required([:environment_key, :version, :authored_snapshot])
    |> validate_number(:version, greater_than: 0)
    |> validate_length(:environment_key, max: 128)
    |> validate_length(:tenant_key, max: 128)
    |> validate_length(:source_environment_key, max: 128)
    |> validate_length(:target_environment_key, max: 128)
    |> validate_length(:compare_token, max: 256)
    |> validate_length(:source_fingerprint, max: 256)
    |> validate_length(:target_fingerprint, max: 256)
    |> unique_constraint([:environment_key, :version])
  end

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(value), do: value

  defp normalize_list(nil), do: []

  defp normalize_list(values) when is_list(values) do
    values
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp normalize_list(value), do: normalize_list([value])

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
      {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
      {key, value} -> {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_map(_value), do: %{}

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(nil), do: nil
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value
end

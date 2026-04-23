defmodule Rulestead.RuntimeSnapshot do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @max_environment_key_length 128
  @max_checksum_length 64
  @max_payload_bytes 1_000_000

  schema "runtime_snapshots" do
    field(:environment_key, :string)
    field(:version, :integer)
    field(:payload, :binary)
    field(:payload_checksum, :string)
    field(:metadata, :map, default: %{})
    field(:published_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(runtime_snapshot, attrs) do
    runtime_snapshot
    |> cast(attrs, [
      :environment_key,
      :version,
      :payload,
      :payload_checksum,
      :metadata,
      :published_at
    ])
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:payload_checksum, &normalize_string/1)
    |> validate_required([
      :environment_key,
      :version,
      :payload,
      :payload_checksum,
      :metadata,
      :published_at
    ])
    |> validate_length(:environment_key, max: @max_environment_key_length)
    |> validate_length(:payload_checksum, max: @max_checksum_length)
    |> validate_number(:version, greater_than: 0)
    |> validate_change(:payload, &validate_payload_size/2)
    |> unique_constraint([:environment_key, :version])
  end

  defp validate_payload_size(:payload, payload) when is_binary(payload) do
    if byte_size(payload) <= @max_payload_bytes do
      []
    else
      [payload: "should be at most #{@max_payload_bytes} bytes"]
    end
  end

  defp validate_payload_size(_field, _payload), do: []

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

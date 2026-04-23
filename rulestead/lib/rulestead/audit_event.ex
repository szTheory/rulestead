defmodule Rulestead.AuditEvent do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @results [:ok, :denied, :error]

  schema "audit_events" do
    field(:event_type, :string)
    field(:resource_type, :string)
    field(:resource_id, :binary_id)
    field(:resource_key, :string)
    field(:environment_key, :string)
    field(:actor_id, :string)
    field(:actor_type, :string)
    field(:actor_display, :string)
    field(:reason, :string)
    field(:result, Ecto.Enum, values: @results, default: :ok)
    field(:metadata, :map, default: %{})
    field(:correlation_id, :string)
    field(:occurred_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(audit_event, attrs) do
    audit_event
    |> cast(attrs, [
      :event_type,
      :resource_type,
      :resource_id,
      :resource_key,
      :environment_key,
      :actor_id,
      :actor_type,
      :actor_display,
      :reason,
      :result,
      :metadata,
      :correlation_id,
      :occurred_at
    ])
    |> update_change(:event_type, &normalize_string/1)
    |> update_change(:resource_type, &normalize_string/1)
    |> update_change(:resource_key, &normalize_string/1)
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:actor_id, &normalize_string/1)
    |> update_change(:actor_type, &normalize_string/1)
    |> update_change(:actor_display, &normalize_string/1)
    |> update_change(:reason, &normalize_string/1)
    |> update_change(:correlation_id, &normalize_string/1)
    |> put_occurred_at()
    |> validate_required([:event_type, :resource_type, :result, :occurred_at])
    |> validate_length(:event_type, min: 3, max: 128)
    |> validate_length(:resource_type, min: 2, max: 64)
  end

  @spec results() :: [atom()]
  def results, do: @results

  defp put_occurred_at(changeset) do
    case get_field(changeset, :occurred_at) do
      nil ->
        put_change(changeset, :occurred_at, DateTime.utc_now() |> DateTime.truncate(:microsecond))

      _occurred_at ->
        changeset
    end
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

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

  @spec metadata(map() | keyword()) :: map()
  def metadata(attrs \\ %{}) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)
    context = normalize_context(Map.get(attrs, :context) || Map.get(attrs, "context"))

    %{
      "before" => normalize_map(Map.get(attrs, :before) || Map.get(attrs, "before")),
      "after" => normalize_map(Map.get(attrs, :after) || Map.get(attrs, "after")),
      "diff" => normalize_map(Map.get(attrs, :diff) || Map.get(attrs, "diff")),
      "links" => normalize_map(Map.get(attrs, :links) || Map.get(attrs, "links")),
      "context" => context
    }
    |> maybe_put("request_id", Map.get(attrs, :request_id) || Map.get(attrs, "request_id"))
    |> maybe_put("source", Map.get(attrs, :source) || Map.get(attrs, "source"))
    |> maybe_put("rollback_of_event_id", Map.get(attrs, :rollback_of_event_id) || Map.get(attrs, "rollback_of_event_id"))
    |> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
    |> maybe_put("approval_id", governance_value(attrs, context, :approval_id))
    |> maybe_put("governance_action", governance_value(attrs, context, :governance_action))
    |> maybe_put("execution_stage", governance_value(attrs, context, :execution_stage))
    |> maybe_put("scheduled_execution_id", scheduled_value(attrs, context, :scheduled_execution_id))
    |> maybe_put("attempt_count", scheduled_value(attrs, context, :attempt_count))
    |> maybe_put("scheduled_for", scheduled_value(attrs, context, :scheduled_for))
    |> maybe_put("executed_at", scheduled_value(attrs, context, :executed_at))
    |> maybe_put("failure_reason", scheduled_value(attrs, context, :failure_reason))
    |> maybe_put("execution_mode", scheduled_value(attrs, context, :execution_mode))
    |> maybe_put("executed_by", scheduled_value(attrs, context, :executed_by))
    |> maybe_put("scheduled_by", scheduled_value(attrs, context, :scheduled_by))
    |> maybe_put("approved_by", scheduled_value(attrs, context, :approved_by))
  end

  @spec serialize(t()) :: map()
  def serialize(%__MODULE__{} = audit_event) do
    %{
      id: audit_event.id,
      event_type: audit_event.event_type,
      resource_type: audit_event.resource_type,
      resource_id: audit_event.resource_id,
      resource_key: audit_event.resource_key,
      environment_key: audit_event.environment_key,
      actor_id: audit_event.actor_id,
      actor_type: audit_event.actor_type,
      actor_display: audit_event.actor_display,
      reason: audit_event.reason,
      result: audit_event.result,
      metadata: normalize_map(audit_event.metadata),
      correlation_id: audit_event.correlation_id,
      occurred_at: audit_event.occurred_at,
      inserted_at: audit_event.inserted_at
    }
  end

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

  defp normalize_map(nil), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
      {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
      {key, value} -> {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_map(_value), do: %{}

  defp normalize_context(nil), do: %{}

  defp normalize_context(map) when is_map(map) do
    map
    |> normalize_map()
    |> drop_sensitive_context_keys()
  end

  defp normalize_context(_value), do: %{}

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)
  defp normalize_value(value), do: value

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp governance_value(attrs, context, key) do
    attrs
    |> Map.get(key)
    |> Kernel.||(Map.get(attrs, Atom.to_string(key)))
    |> Kernel.||(Map.get(context, Atom.to_string(key)))
    |> normalize_governance_value()
  end

  defp scheduled_value(attrs, context, key) do
    attrs
    |> Map.get(key)
    |> Kernel.||(Map.get(attrs, Atom.to_string(key)))
    |> Kernel.||(Map.get(context, Atom.to_string(key)))
    |> normalize_scheduled_value()
  end

  defp drop_sensitive_context_keys(map) do
    map
    |> Map.drop(["session", "session_data", "session_id", "session_token", "socket_session"])
    |> Map.new(fn
      {key, value} when is_map(value) -> {key, drop_sensitive_context_keys(value)}
      {key, value} when is_list(value) -> {key, Enum.map(value, &drop_sensitive_list_value/1)}
      entry -> entry
    end)
  end

  defp drop_sensitive_list_value(value) when is_map(value), do: drop_sensitive_context_keys(value)
  defp drop_sensitive_list_value(value), do: value

  defp normalize_governance_value(value) when is_atom(value) and not is_nil(value),
    do: Atom.to_string(value)

  defp normalize_governance_value(value), do: value

  defp normalize_scheduled_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp normalize_scheduled_value(value) when is_atom(value) and not is_nil(value), do: Atom.to_string(value)
  defp normalize_scheduled_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_scheduled_value(value) when is_list(value), do: Enum.map(value, &normalize_scheduled_value/1)
  defp normalize_scheduled_value(value), do: value
end

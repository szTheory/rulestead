defmodule Rulestead.Governance.ExecutionAttempt do
  @moduledoc """
  Append-only execution attempt contract for scheduled execution retries.
  """

  @states [:running, :completed, :failed, :quarantined, :cancelled]

  @enforce_keys [:scheduled_execution_id, :attempt_number, :state]
  defstruct [
    :id,
    :scheduled_execution_id,
    :attempt_number,
    :state,
    :started_at,
    :finished_at,
    :failure_reason,
    :metadata
  ]

  @type state :: :running | :completed | :failed | :quarantined | :cancelled

  @type t :: %__MODULE__{
          id: String.t() | nil,
          scheduled_execution_id: String.t() | nil,
          attempt_number: pos_integer(),
          state: state(),
          started_at: DateTime.t() | nil,
          finished_at: DateTime.t() | nil,
          failure_reason: String.t() | nil,
          metadata: map()
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = execution_attempt), do: execution_attempt

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      id: normalize_string(fetch(attrs, :id)),
      scheduled_execution_id: normalize_string(fetch(attrs, :scheduled_execution_id)),
      attempt_number: normalize_attempt_number(fetch(attrs, :attempt_number)),
      state: normalize_state(fetch(attrs, :state)),
      started_at: fetch(attrs, :started_at),
      finished_at: fetch(attrs, :finished_at),
      failure_reason: normalize_string(fetch(attrs, :failure_reason)),
      metadata: fetch(attrs, :metadata) |> normalize_map() |> drop_sensitive_keys()
    }
  end

  @spec states() :: [state()]
  def states, do: @states

  @spec serialize(t() | map() | keyword()) :: map()
  def serialize(execution_attempt) do
    execution_attempt = new(execution_attempt)

    %{
      id: execution_attempt.id,
      scheduled_execution_id: execution_attempt.scheduled_execution_id,
      attempt_number: execution_attempt.attempt_number,
      state: execution_attempt.state,
      started_at: execution_attempt.started_at,
      finished_at: execution_attempt.finished_at,
      failure_reason: execution_attempt.failure_reason,
      metadata: execution_attempt.metadata
    }
  end

  defp fetch(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_attempt_number(value) when is_integer(value) and value > 0, do: value
  defp normalize_attempt_number(_value), do: 1

  defp normalize_state(state) when state in @states, do: state
  defp normalize_state(_state), do: :failed

  defp normalize_map(nil), do: %{}
  defp normalize_map(value) when is_list(value), do: value |> Map.new() |> normalize_map()

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
  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(value), do: value

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(_value), do: nil

  defp drop_sensitive_keys(map) do
    map
    |> Map.drop(["admin_session", "session", "session_data", "session_id", "session_token", "socket", "socket_session"])
    |> Map.new(fn
      {key, value} when is_map(value) -> {key, drop_sensitive_keys(value)}
      {key, value} when is_list(value) -> {key, Enum.map(value, &drop_sensitive_value/1)}
      entry -> entry
    end)
  end

  defp drop_sensitive_value(value) when is_map(value), do: drop_sensitive_keys(value)
  defp drop_sensitive_value(value), do: value
end

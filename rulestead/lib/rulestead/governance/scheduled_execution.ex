defmodule Rulestead.Governance.ScheduledExecution do
  @moduledoc false
  # Canonical durable contract for a future-dated governed mutation.


  @states [:scheduled, :running, :completed, :failed, :quarantined, :cancelled]
  @terminal_states [:completed, :failed, :quarantined, :cancelled]
  @governed_actions [
    :publish_ruleset,
    :advance_rollout,
    :engage_kill_switch,
    :release_kill_switch,
    :promote_environment
  ]
  @execution_modes [:change_request, :policy_bypass, :emergency_bypass]

  @enforce_keys [:state, :action, :scheduled_for, :correlation_id, :idempotency_key]
  defstruct [
    :id,
    :state,
    :action,
    :change_request_id,
    :environment_key,
    :resource_type,
    :resource_key,
    :execution_mode,
    :scheduled_by,
    :approved_by_snapshot,
    :execution_metadata,
    :scheduled_for,
    :executed_at,
    :attempt_count,
    :failure_reason,
    :last_oban_job_id,
    :correlation_id,
    :idempotency_key,
    :command_snapshot,
    :approval_requirement_snapshot,
    :metadata
  ]

  @type state :: :scheduled | :running | :completed | :failed | :quarantined | :cancelled
  @type action ::
          :publish_ruleset
          | :advance_rollout
          | :engage_kill_switch
          | :release_kill_switch
          | :promote_environment
  @type execution_mode :: :change_request | :policy_bypass | :emergency_bypass

  @type actor_summary :: %{
          optional(String.t()) => String.t()
        }

  @type t :: %__MODULE__{
          id: String.t() | nil,
          state: state(),
          action: action(),
          change_request_id: String.t() | nil,
          environment_key: String.t() | nil,
          resource_type: String.t() | nil,
          resource_key: String.t() | nil,
          execution_mode: execution_mode(),
          scheduled_by: actor_summary(),
          approved_by_snapshot: [actor_summary()],
          execution_metadata: map(),
          scheduled_for: DateTime.t() | nil,
          executed_at: DateTime.t() | nil,
          attempt_count: non_neg_integer(),
          failure_reason: String.t() | nil,
          last_oban_job_id: integer() | nil,
          correlation_id: String.t() | nil,
          idempotency_key: String.t() | nil,
          command_snapshot: map(),
          approval_requirement_snapshot: map(),
          metadata: map()
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = scheduled_execution), do: scheduled_execution

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      id: normalize_string(fetch(attrs, :id)),
      state: normalize_state(fetch(attrs, :state)),
      action: normalize_action(fetch(attrs, :action)),
      change_request_id: normalize_string(fetch(attrs, :change_request_id)),
      environment_key: normalize_string(fetch(attrs, :environment_key)),
      resource_type: normalize_string(fetch(attrs, :resource_type)),
      resource_key: normalize_string(fetch(attrs, :resource_key)),
      execution_mode: normalize_execution_mode(fetch(attrs, :execution_mode)),
      scheduled_by: normalize_actor_summary(fetch(attrs, :scheduled_by)),
      approved_by_snapshot: normalize_actor_list(fetch(attrs, :approved_by_snapshot)),
      execution_metadata: normalize_metadata(fetch(attrs, :execution_metadata)),
      scheduled_for: fetch(attrs, :scheduled_for),
      executed_at: fetch(attrs, :executed_at),
      attempt_count: normalize_attempt_count(fetch(attrs, :attempt_count)),
      failure_reason: normalize_string(fetch(attrs, :failure_reason)),
      last_oban_job_id: normalize_integer(fetch(attrs, :last_oban_job_id)),
      correlation_id: normalize_string(fetch(attrs, :correlation_id)),
      idempotency_key: normalize_string(fetch(attrs, :idempotency_key)),
      command_snapshot: normalize_map(fetch(attrs, :command_snapshot)),
      approval_requirement_snapshot: normalize_map(fetch(attrs, :approval_requirement_snapshot)),
      metadata: normalize_metadata(fetch(attrs, :metadata))
    }
  end

  @spec states() :: [state()]
  def states, do: @states

  @spec terminal_states() :: [state()]
  def terminal_states, do: @terminal_states

  @spec governed_actions() :: [action()]
  def governed_actions, do: @governed_actions

  @spec execution_modes() :: [execution_mode()]
  def execution_modes, do: @execution_modes

  @spec serialize(t() | map() | keyword()) :: map()
  def serialize(scheduled_execution) do
    scheduled_execution = new(scheduled_execution)

    %{
      id: scheduled_execution.id,
      state: scheduled_execution.state,
      action: scheduled_execution.action,
      change_request_id: scheduled_execution.change_request_id,
      environment_key: scheduled_execution.environment_key,
      resource_type: scheduled_execution.resource_type,
      resource_key: scheduled_execution.resource_key,
      execution_mode: scheduled_execution.execution_mode,
      scheduled_by: scheduled_execution.scheduled_by,
      approved_by_snapshot: scheduled_execution.approved_by_snapshot,
      execution_metadata: scheduled_execution.execution_metadata,
      scheduled_for: scheduled_execution.scheduled_for,
      executed_at: scheduled_execution.executed_at,
      attempt_count: scheduled_execution.attempt_count,
      failure_reason: scheduled_execution.failure_reason,
      last_oban_job_id: scheduled_execution.last_oban_job_id,
      correlation_id: scheduled_execution.correlation_id,
      idempotency_key: scheduled_execution.idempotency_key,
      command_snapshot: scheduled_execution.command_snapshot,
      approval_requirement_snapshot: scheduled_execution.approval_requirement_snapshot,
      metadata: scheduled_execution.metadata
    }
  end

  defp fetch(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

  defp normalize_state(state) when state in @states, do: state
  defp normalize_state(_state), do: :scheduled

  defp normalize_action(action) when action in @governed_actions, do: action
  defp normalize_action(_action), do: :publish_ruleset

  defp normalize_execution_mode(mode) when mode in @execution_modes, do: mode
  defp normalize_execution_mode(_mode), do: :change_request

  defp normalize_actor_summary(actor) when is_list(actor) or is_map(actor) do
    actor = Map.new(actor)

    %{}
    |> maybe_put("id", normalize_string(fetch(actor, :id)))
    |> maybe_put("type", normalize_string(fetch(actor, :type)))
    |> maybe_put("display", normalize_string(fetch(actor, :display)))
  end

  defp normalize_actor_summary(_actor), do: %{}

  defp normalize_actor_list(actors) when is_list(actors), do: Enum.map(actors, &normalize_actor_summary/1)
  defp normalize_actor_list(_actors), do: []

  defp normalize_metadata(metadata), do: metadata |> normalize_map() |> drop_sensitive_keys()

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

  defp normalize_attempt_count(value) when is_integer(value) and value >= 0, do: value
  defp normalize_attempt_count(_value), do: 0

  defp normalize_integer(value) when is_integer(value), do: value
  defp normalize_integer(_value), do: nil

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(nil), do: nil
  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(value) when is_integer(value), do: value |> Integer.to_string() |> normalize_string()
  defp normalize_string(_value), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

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

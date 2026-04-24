defmodule Rulestead.Governance.ChangeRequest do
  @moduledoc """
  Canonical governed mutation contract for approvals-first workflows.
  """

  alias Rulestead.Governance.ApprovalRequirement

  @states [:submitted, :approved, :rejected, :cancelled, :executed]
  @terminal_states [:rejected, :cancelled, :executed]
  @governed_actions [:publish_ruleset, :advance_rollout, :engage_kill_switch, :release_kill_switch]

  @enforce_keys [
    :state,
    :action,
    :environment_key,
    :resource_type,
    :resource_key,
    :submitted_by,
    :command,
    :approval_requirement,
    :correlation_id
  ]
  defstruct [
    :id,
    :state,
    :action,
    :environment_key,
    :resource_type,
    :resource_key,
    :submitted_by,
    :command,
    :approval_requirement,
    :correlation_id
  ]

  @type state :: :submitted | :approved | :rejected | :cancelled | :executed
  @type action :: :publish_ruleset | :advance_rollout | :engage_kill_switch | :release_kill_switch

  @type actor_summary :: %{
          optional(:id) => String.t(),
          optional(:type) => String.t(),
          optional(:display) => String.t()
        }

  @type t :: %__MODULE__{
          id: String.t() | nil,
          state: state(),
          action: action(),
          environment_key: String.t() | nil,
          resource_type: String.t() | nil,
          resource_key: String.t() | nil,
          submitted_by: actor_summary(),
          command: map(),
          approval_requirement: ApprovalRequirement.t(),
          correlation_id: String.t() | nil
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = change_request), do: change_request

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      id: normalize_string(Map.get(attrs, :id)),
      state: normalize_state(Map.get(attrs, :state)),
      action: normalize_action(Map.get(attrs, :action)),
      environment_key: normalize_string(Map.get(attrs, :environment_key)),
      resource_type: normalize_string(Map.get(attrs, :resource_type)),
      resource_key: normalize_string(Map.get(attrs, :resource_key)),
      submitted_by: normalize_actor_summary(Map.get(attrs, :submitted_by)),
      command: normalize_command(Map.get(attrs, :command)),
      approval_requirement: ApprovalRequirement.new(Map.get(attrs, :approval_requirement, %{})),
      correlation_id: normalize_string(Map.get(attrs, :correlation_id))
    }
  end

  @spec states() :: [state()]
  def states, do: @states

  @spec terminal_states() :: [state()]
  def terminal_states, do: @terminal_states

  @spec governed_actions() :: [action()]
  def governed_actions, do: @governed_actions

  @spec serialize(t() | map() | keyword()) :: map()
  def serialize(change_request) do
    change_request = new(change_request)

    %{
      state: change_request.state,
      action: change_request.action,
      environment_key: change_request.environment_key,
      resource_type: change_request.resource_type,
      resource_key: change_request.resource_key,
      submitted_by: change_request.submitted_by,
      command: change_request.command,
      approval_requirement: ApprovalRequirement.serialize(change_request.approval_requirement),
      correlation_id: change_request.correlation_id
    }
  end

  defp normalize_state(state) when state in @states, do: state
  defp normalize_state(_state), do: :submitted

  defp normalize_action(action) when action in @governed_actions, do: action
  defp normalize_action(_action), do: hd(@governed_actions)

  defp normalize_actor_summary(actor) when is_map(actor) do
    %{}
    |> maybe_put(:id, normalize_string(Map.get(actor, :id) || Map.get(actor, "id")))
    |> maybe_put(:type, normalize_string(Map.get(actor, :type) || Map.get(actor, "type")))
    |> maybe_put(:display, normalize_string(Map.get(actor, :display) || Map.get(actor, "display")))
  end

  defp normalize_actor_summary(_actor), do: %{}

  defp normalize_command(command) when is_map(command), do: normalize_map(command)
  defp normalize_command(_command), do: %{}

  defp normalize_map(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
      {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
      {key, value} -> {to_string(key), normalize_value(value)}
    end)
  end

  defp normalize_value(value) when is_map(value), do: normalize_map(value)
  defp normalize_value(value) when is_list(value), do: Enum.map(value, &normalize_value/1)

  defp normalize_value(value)
       when is_nil(value) or is_boolean(value) or is_integer(value) or is_float(value) or is_binary(value),
       do: value

  defp normalize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_value(_value), do: nil

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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

defmodule Rulestead.Governance.ApprovalRequirement do
  @moduledoc false
  # Snapshot of the approval policy applied to a governed change request.


  @enforce_keys [
    :action,
    :environment_key,
    :required_approvals,
    :change_request_required?,
    :self_approval_allowed?
  ]
  defstruct [:action, :environment_key, :required_approvals, :change_request_required?, :self_approval_allowed?]

  @governed_actions [
    :publish_ruleset,
    :advance_rollout,
    :engage_kill_switch,
    :release_kill_switch,
    :promote_environment
  ]

  @type action ::
          :publish_ruleset
          | :advance_rollout
          | :engage_kill_switch
          | :release_kill_switch
          | :promote_environment

  @type t :: %__MODULE__{
          action: action(),
          environment_key: String.t() | nil,
          required_approvals: non_neg_integer(),
          change_request_required?: boolean(),
          self_approval_allowed?: boolean()
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = approval_requirement), do: approval_requirement

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      action: normalize_action(Map.get(attrs, :action)),
      environment_key: normalize_string(Map.get(attrs, :environment_key)),
      required_approvals: normalize_required_approvals(Map.get(attrs, :required_approvals)),
      change_request_required?: normalize_boolean(Map.get(attrs, :change_request_required?)),
      self_approval_allowed?: normalize_boolean(Map.get(attrs, :self_approval_allowed?))
    }
  end

  @spec serialize(t() | map() | keyword()) :: map()
  def serialize(approval_requirement) do
    approval_requirement = new(approval_requirement)

    %{
      action: approval_requirement.action,
      environment_key: approval_requirement.environment_key,
      required_approvals: approval_requirement.required_approvals,
      change_request_required?: approval_requirement.change_request_required?,
      self_approval_allowed?: approval_requirement.self_approval_allowed?
    }
  end

  defp normalize_action(action) when action in @governed_actions, do: action

  defp normalize_action(_action), do: hd(@governed_actions)

  defp normalize_required_approvals(value) when is_integer(value) and value >= 0, do: value
  defp normalize_required_approvals(_value), do: 0

  defp normalize_boolean(value) when is_boolean(value), do: value
  defp normalize_boolean(_value), do: false

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
end

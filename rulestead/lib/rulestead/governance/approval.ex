defmodule Rulestead.Governance.Approval do
  @moduledoc false
  # Review decision recorded against a governed change request.

  @enforce_keys [:change_request_id, :decision, :reviewed_by, :correlation_id]
  defstruct [:change_request_id, :decision, :reviewed_by, :reason, :correlation_id]

  @type decision :: :approved | :rejected

  @type reviewer :: %{
          optional(:id) => String.t(),
          optional(:type) => String.t(),
          optional(:display) => String.t()
        }

  @type t :: %__MODULE__{
          change_request_id: String.t() | nil,
          decision: decision(),
          reviewed_by: reviewer(),
          reason: String.t() | nil,
          correlation_id: String.t() | nil
        }

  @spec new(t() | map() | keyword()) :: t()
  def new(%__MODULE__{} = approval), do: approval

  def new(attrs) when is_list(attrs) or is_map(attrs) do
    attrs = Map.new(attrs)

    %__MODULE__{
      change_request_id: normalize_string(Map.get(attrs, :change_request_id)),
      decision: normalize_decision(Map.get(attrs, :decision)),
      reviewed_by: normalize_actor_summary(Map.get(attrs, :reviewed_by)),
      reason: normalize_string(Map.get(attrs, :reason)),
      correlation_id: normalize_string(Map.get(attrs, :correlation_id))
    }
  end

  @spec decisions() :: [decision()]
  def decisions, do: [:approved, :rejected]

  @spec serialize(t() | map() | keyword()) :: map()
  def serialize(approval) do
    approval = new(approval)

    %{
      change_request_id: approval.change_request_id,
      decision: approval.decision,
      reviewed_by: approval.reviewed_by,
      reason: approval.reason,
      correlation_id: approval.correlation_id
    }
  end

  defp normalize_decision(decision) when decision in [:approved, :rejected], do: decision
  defp normalize_decision(_decision), do: :rejected

  defp normalize_actor_summary(actor) when is_map(actor) do
    %{}
    |> maybe_put(:id, normalize_string(Map.get(actor, :id) || Map.get(actor, "id")))
    |> maybe_put(:type, normalize_string(Map.get(actor, :type) || Map.get(actor, "type")))
    |> maybe_put(
      :display,
      normalize_string(Map.get(actor, :display) || Map.get(actor, "display"))
    )
  end

  defp normalize_actor_summary(_actor), do: %{}

  defp normalize_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_string()

  defp normalize_string(_value), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end

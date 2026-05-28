defmodule Rulestead.GuardrailDecision do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Store.Command

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @decision_states [:healthy, :pending_data, :held, :rollback_triggered]
  @action_types [:advance, :evaluate, :hold, :rollback]

  schema "guardrail_decisions" do
    field(:flag_key, :string)
    field(:environment_key, :string)
    field(:rule_key, :string)
    field(:stage, :string)
    field(:tenant_key, :string)
    field(:decision_state, Ecto.Enum, values: @decision_states)
    field(:action_type, Ecto.Enum, values: @action_types)
    field(:decision_reason, :string)
    field(:effective_percentage, :integer)
    field(:rollout_salt, :string)
    field(:variant_fingerprint, :string)
    field(:monitoring_window_started_at, :utc_datetime_usec)
    field(:monitoring_window_ends_at, :utc_datetime_usec)
    field(:occurred_at, :utc_datetime_usec)
    field(:signal_facts, {:array, :map}, default: [])
    field(:guardrail_evidence, :map, default: %{})
    field(:authored_snapshot, :map)
    field(:rollback_target_snapshot, :map)
    field(:correlation_id, :string)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(decision, attrs) do
    decision
    |> cast(attrs, [
      :flag_key,
      :environment_key,
      :rule_key,
      :stage,
      :tenant_key,
      :decision_state,
      :action_type,
      :decision_reason,
      :effective_percentage,
      :rollout_salt,
      :variant_fingerprint,
      :monitoring_window_started_at,
      :monitoring_window_ends_at,
      :occurred_at,
      :signal_facts,
      :guardrail_evidence,
      :authored_snapshot,
      :rollback_target_snapshot,
      :correlation_id,
      :metadata
    ])
    |> update_change(:flag_key, &normalize_string/1)
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:rule_key, &normalize_string/1)
    |> update_change(:stage, &normalize_string/1)
    |> update_change(:tenant_key, &normalize_string/1)
    |> update_change(:decision_reason, &normalize_string/1)
    |> update_change(:rollout_salt, &normalize_string/1)
    |> update_change(:variant_fingerprint, &normalize_string/1)
    |> update_change(:correlation_id, &normalize_string/1)
    |> update_change(:signal_facts, &normalize_signal_facts/1)
    |> update_change(:guardrail_evidence, &normalize_map/1)
    |> update_change(:authored_snapshot, &normalize_map/1)
    |> update_change(:rollback_target_snapshot, &normalize_map/1)
    |> update_change(:metadata, &Command.GovernanceSupport.normalize_metadata/1)
    |> put_default_occurred_at()
    |> validate_required([
      :flag_key,
      :environment_key,
      :rule_key,
      :stage,
      :decision_state,
      :action_type,
      :occurred_at
    ])
    |> validate_number(:effective_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
  end

  @spec serialize(t()) :: map()
  def serialize(%__MODULE__{} = decision) do
    %{
      id: decision.id,
      flag_key: decision.flag_key,
      environment_key: decision.environment_key,
      rule_key: decision.rule_key,
      stage: decision.stage,
      tenant_key: decision.tenant_key,
      decision_state: decision.decision_state,
      action_type: decision.action_type,
      decision_reason: decision.decision_reason,
      effective_percentage: decision.effective_percentage,
      rollout_salt: decision.rollout_salt,
      variant_fingerprint: decision.variant_fingerprint,
      monitoring_window_started_at: decision.monitoring_window_started_at,
      monitoring_window_ends_at: decision.monitoring_window_ends_at,
      occurred_at: decision.occurred_at,
      signal_facts: normalize_signal_facts(decision.signal_facts || []),
      guardrail_evidence: normalize_map(decision.guardrail_evidence),
      authored_snapshot: normalize_map(decision.authored_snapshot),
      rollback_target_snapshot: normalize_map(decision.rollback_target_snapshot),
      correlation_id: decision.correlation_id,
      metadata: Command.GovernanceSupport.normalize_metadata(decision.metadata),
      inserted_at: decision.inserted_at
    }
  end

  @spec decision_states() :: [atom()]
  def decision_states, do: @decision_states

  @spec action_types() :: [atom()]
  def action_types, do: @action_types

  defp put_default_occurred_at(changeset) do
    case get_field(changeset, :occurred_at) do
      nil ->
        put_change(changeset, :occurred_at, DateTime.utc_now() |> DateTime.truncate(:microsecond))

      _value ->
        changeset
    end
  end

  defp normalize_signal_facts(facts) when is_list(facts) do
    Enum.map(facts, &normalize_map/1)
  end

  defp normalize_signal_facts(_facts), do: []

  defp normalize_map(nil), do: nil
  defp normalize_map(map) when is_list(map), do: map |> Map.new() |> normalize_map()
  defp normalize_map(map) when is_map(map), do: Command.GovernanceSupport.normalize_map(map)
  defp normalize_map(_map), do: nil

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

  defp normalize_string(value), do: value
end

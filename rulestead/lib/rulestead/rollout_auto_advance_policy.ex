defmodule Rulestead.RolloutAutoAdvancePolicy do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Store.Command

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "rollout_auto_advance_policies" do
    field(:flag_key, :string)
    field(:environment_key, :string)
    field(:rule_key, :string)
    field(:enabled, :boolean, default: false)
    field(:observation_window_seconds, :integer)
    field(:next_stage, :string)
    field(:next_percentage, :integer)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          flag_key: String.t() | nil,
          environment_key: String.t() | nil,
          rule_key: String.t() | nil,
          enabled: boolean(),
          observation_window_seconds: non_neg_integer() | nil,
          next_stage: String.t() | nil,
          next_percentage: non_neg_integer() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [
      :flag_key,
      :environment_key,
      :rule_key,
      :enabled,
      :observation_window_seconds,
      :next_stage,
      :next_percentage,
      :metadata
    ])
    |> update_change(:flag_key, &normalize_string/1)
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:rule_key, &normalize_string/1)
    |> update_change(:next_stage, &normalize_string/1)
    |> update_change(:metadata, &Command.GovernanceSupport.normalize_metadata/1)
    |> validate_required([:flag_key, :environment_key, :rule_key])
    |> validate_enabled_fields()
    |> validate_number(:next_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> validate_number(:observation_window_seconds, greater_than: 0)
  end

  defp validate_enabled_fields(changeset) do
    if get_field(changeset, :enabled) do
      validate_required(changeset, [
        :observation_window_seconds,
        :next_stage,
        :next_percentage
      ])
    else
      changeset
    end
  end

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

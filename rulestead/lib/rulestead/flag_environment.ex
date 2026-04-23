defmodule Rulestead.FlagEnvironment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:draft, :active, :archived, :killswitched]

  schema "flag_environments" do
    field(:status, Ecto.Enum, values: @statuses, default: :draft)
    field(:kill_switch_variant_key, :string)
    field(:last_published_at, :utc_datetime_usec)

    belongs_to(:flag, Rulestead.Flag)
    belongs_to(:environment, Rulestead.Environment)
    belongs_to(:active_ruleset, Rulestead.Ruleset, foreign_key: :active_ruleset_id)

    has_many(:rulesets, Rulestead.Ruleset)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(flag_environment, attrs) do
    flag_environment
    |> cast(attrs, [
      :flag_id,
      :environment_id,
      :active_ruleset_id,
      :status,
      :kill_switch_variant_key,
      :last_published_at
    ])
    |> update_change(:kill_switch_variant_key, &normalize_string/1)
    |> validate_required([:flag_id, :environment_id, :status])
    |> foreign_key_constraint(:flag_id)
    |> foreign_key_constraint(:environment_id)
    |> foreign_key_constraint(:active_ruleset_id)
    |> unique_constraint([:flag_id, :environment_id])
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

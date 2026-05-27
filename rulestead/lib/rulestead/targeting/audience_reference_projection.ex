defmodule Rulestead.Targeting.AudienceReferenceProjection do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audience_reference_projection" do
    field :environment_key, :string
    field :tenant_key, :string
    field :audience_key, :string
    field :flag_key, :string
    field :ruleset_version, :integer
    field :rule_key, :string
    field :rule_strategy, :string
    field :ruleset_status, :string
    field :rollout_context, :map, default: %{}
    field :lifecycle_context, :map, default: %{}
    field :visibility, :map, default: %{}
    field :reference_count, :integer, default: 1
    field :hidden_reference_count, :integer, default: 0

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(projection, attrs) do
    projection
    |> cast(attrs, [
      :environment_key,
      :tenant_key,
      :audience_key,
      :flag_key,
      :ruleset_version,
      :rule_key,
      :rule_strategy,
      :ruleset_status,
      :rollout_context,
      :lifecycle_context,
      :visibility,
      :reference_count,
      :hidden_reference_count
    ])
    |> update_change(:environment_key, &normalize_string/1)
    |> update_change(:tenant_key, &normalize_string/1)
    |> update_change(:audience_key, &normalize_string/1)
    |> update_change(:flag_key, &normalize_string/1)
    |> update_change(:rule_key, &normalize_string/1)
    |> update_change(:rule_strategy, &normalize_string/1)
    |> update_change(:ruleset_status, &normalize_string/1)
    |> update_change(:rollout_context, &normalize_map/1)
    |> update_change(:lifecycle_context, &normalize_map/1)
    |> update_change(:visibility, &normalize_map/1)
    |> update_change(:reference_count, &normalize_count/1)
    |> update_change(:hidden_reference_count, &normalize_count/1)
    |> validate_required([
      :environment_key,
      :tenant_key,
      :audience_key,
      :flag_key,
      :ruleset_version,
      :rule_key
    ])
    |> validate_number(:ruleset_version, greater_than: 0)
    |> validate_number(:reference_count, greater_than_or_equal_to: 0)
    |> validate_number(:hidden_reference_count, greater_than_or_equal_to: 0)
    |> unique_constraint(
      [:environment_key, :tenant_key, :flag_key, :ruleset_version, :rule_key, :audience_key],
      name: :audience_reference_projection_identity_index
    )
  end

  defp normalize_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_string(value) when is_atom(value), do: value |> Atom.to_string() |> normalize_string()
  defp normalize_string(value), do: value

  defp normalize_map(value) when is_map(value), do: value
  defp normalize_map(_value), do: %{}

  defp normalize_count(value) when is_integer(value) and value >= 0, do: value
  defp normalize_count(_value), do: 0
end

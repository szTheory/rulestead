defmodule Rulestead.Ruleset.Rule do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Ruleset.{Condition, Rollout, Variant}

  @primary_key false

  @strategies [:forced_value, :percentage_rollout, :variant_split, :segment_match]

  embedded_schema do
    field(:key, :string)
    field(:name, :string)
    field(:description, :string)
    field(:strategy, Ecto.Enum, values: @strategies)
    field(:value, :map, default: %{})
    field(:audience_id, :binary_id)
    field(:audience_key, :string)

    embeds_many(:conditions, Condition, on_replace: :delete)
    embeds_many(:variants, Variant, on_replace: :delete)
    embeds_one(:rollout, Rollout, on_replace: :update)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [:key, :name, :description, :strategy, :value, :audience_id, :audience_key])
    |> update_change(:key, &normalize_string/1)
    |> update_change(:name, &normalize_string/1)
    |> update_change(:description, &normalize_string/1)
    |> update_change(:audience_key, &normalize_string/1)
    |> cast_embed(:conditions, with: &Condition.changeset/2)
    |> cast_embed(:variants, with: &Variant.changeset/2)
    |> cast_embed(:rollout, with: &Rollout.changeset/2)
    |> validate_required([:key, :strategy])
    |> validate_length(:key, min: 1, max: 128)
    |> validate_rule_shape()
  end

  @spec strategies() :: [atom()]
  def strategies, do: @strategies

  defp validate_rule_shape(changeset) do
    changeset
    |> validate_audience_reference()
    |> validate_variant_weights()
    |> validate_rollout_requirements()
    |> validate_forced_value()
  end

  defp validate_audience_reference(changeset) do
    if get_field(changeset, :strategy) == :segment_match and
         is_nil(get_field(changeset, :audience_id)) and
         blank?(get_field(changeset, :audience_key)) do
      add_error(changeset, :audience_key, "must reference an audience for segment_match rules")
    else
      changeset
    end
  end

  defp validate_variant_weights(changeset) do
    variants = get_field(changeset, :variants, [])

    cond do
      variants == [] and get_field(changeset, :strategy) == :variant_split ->
        add_error(changeset, :variants, "must include at least one variant")

      variants == [] ->
        changeset

      Enum.sum(Enum.map(variants, &(&1.weight || 0))) == 100 ->
        changeset

      true ->
        add_error(changeset, :variants, "weights must sum to 100")
    end
  end

  defp validate_rollout_requirements(changeset) do
    strategy = get_field(changeset, :strategy)
    rollout = get_field(changeset, :rollout)
    variants = get_field(changeset, :variants, [])

    cond do
      strategy == :percentage_rollout and is_nil(rollout) ->
        add_error(changeset, :rollout, "must be present for percentage_rollout rules")

      strategy == :variant_split and is_nil(rollout) ->
        add_error(changeset, :rollout, "must be present for variant_split rules")

      strategy == :variant_split and variants == [] ->
        add_error(changeset, :variants, "must include at least one variant")

      strategy not in [:percentage_rollout, :variant_split] and not is_nil(rollout) ->
        add_error(changeset, :rollout, "is only supported for percentage_rollout and variant_split rules")

      true ->
        changeset
    end
  end

  defp validate_forced_value(changeset) do
    if get_field(changeset, :strategy) == :forced_value and
         get_field(changeset, :value) in [nil, %{}] do
      add_error(changeset, :value, "must be present for forced_value rules")
    else
      changeset
    end
  end

  defp blank?(value) when value in [nil, ""], do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: false

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

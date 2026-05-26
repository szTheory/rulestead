defmodule Rulestead.Ruleset.Guardrail do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Guardrails.Query

  @primary_key false

  @threshold_operators Query.threshold_operators()
  @environment_scopes Query.environment_scopes()
  @tenant_scopes Query.tenant_scopes()

  embedded_schema do
    field(:signal_key, :string)
    field(:threshold_operator, Ecto.Enum, values: @threshold_operators)
    field(:threshold_value, :float)
    field(:freshness_window_seconds, :integer)
    field(:min_sample_size, :integer)
    field(:environment_scope, Ecto.Enum, values: @environment_scopes, default: :environment)
    field(:tenant_scope, Ecto.Enum, values: @tenant_scopes, default: :not_applicable)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(guardrail, attrs) do
    guardrail
    |> cast(attrs, [
      :signal_key,
      :threshold_operator,
      :threshold_value,
      :freshness_window_seconds,
      :min_sample_size,
      :environment_scope,
      :tenant_scope
    ])
    |> update_change(:signal_key, &normalize_string/1)
    |> validate_required([
      :signal_key,
      :threshold_operator,
      :threshold_value,
      :freshness_window_seconds,
      :min_sample_size,
      :environment_scope,
      :tenant_scope
    ])
    |> validate_number(:threshold_value, greater_than_or_equal_to: 0.0)
    |> validate_number(:freshness_window_seconds, greater_than_or_equal_to: 0)
    |> validate_number(:min_sample_size, greater_than_or_equal_to: 0)
    |> validate_length(:signal_key, min: 1, max: 255)
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

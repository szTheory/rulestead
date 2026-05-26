defmodule Rulestead.Ruleset.Rollout do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Ruleset.Guardrail

  @primary_key false

  @bucket_by_values [:subject, :account, :tenant, :session]

  embedded_schema do
    field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
    field(:percentage, :integer)
    field(:salt, :string)
    embeds_many(:guardrails, Guardrail, on_replace: :delete)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(rollout, attrs) do
    rollout
    |> cast(attrs, [:bucket_by, :percentage, :salt])
    |> update_change(:salt, &normalize_string/1)
    |> cast_embed(:guardrails, with: &Guardrail.changeset/2)
    |> validate_required([:bucket_by, :percentage])
    |> validate_number(:percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_length(:salt, max: 255)
  end

  @spec bucket_by_values() :: [atom()]
  def bucket_by_values, do: @bucket_by_values

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

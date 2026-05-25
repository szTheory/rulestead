defmodule Rulestead.Ruleset.Experiment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  @bucket_by_values [:subject, :account, :tenant, :session]

  embedded_schema do
    field(:iteration_salt, :string)
    field(:bucket_by, Ecto.Enum, values: @bucket_by_values, default: :subject)
    field(:holdout_percentage, :integer, default: 5)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(experiment, attrs) do
    experiment
    |> cast(attrs, [:iteration_salt, :bucket_by, :holdout_percentage])
    |> update_change(:iteration_salt, &normalize_string/1)
    |> validate_required([:iteration_salt, :bucket_by, :holdout_percentage])
    |> validate_number(:holdout_percentage,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100
    )
    |> validate_length(:iteration_salt, max: 255)
  end

  @spec bucket_by_values() :: [atom()]
  def bucket_by_values, do: @bucket_by_values

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

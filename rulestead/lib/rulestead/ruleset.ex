defmodule Rulestead.Ruleset do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Rulestead.Ruleset.Rule

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:draft, :published]

  schema "rulesets" do
    field(:version, :integer)
    field(:status, Ecto.Enum, values: @statuses, default: :draft)
    field(:salt, :string)
    field(:published_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    belongs_to(:flag_environment, Rulestead.FlagEnvironment)

    embeds_many(:rules, Rule, on_replace: :delete)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(ruleset, attrs) do
    ruleset
    |> cast(attrs, [:flag_environment_id, :version, :status, :salt, :published_at, :metadata])
    |> update_change(:salt, &normalize_string/1)
    |> cast_embed(:rules, with: &Rule.changeset/2)
    |> validate_required([:flag_environment_id, :version, :status])
    |> validate_number(:version, greater_than: 0)
    |> validate_length(:salt, max: 255)
    |> validate_published_status()
    |> foreign_key_constraint(:flag_environment_id)
    |> unique_constraint([:flag_environment_id, :version])
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  defp validate_published_status(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    case status do
      :published when published_at == nil ->
        add_error(changeset, :published_at, "must be present for published rulesets")

      :draft when published_at != nil ->
        add_error(changeset, :published_at, "must be empty for draft rulesets")

      _status ->
        changeset
    end
  end

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value
end

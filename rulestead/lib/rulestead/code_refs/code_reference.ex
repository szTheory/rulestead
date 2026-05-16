defmodule Rulestead.CodeRefs.CodeReference do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "code_references" do
    field(:flag_key, :string)
    field(:file, :string)
    field(:line, :integer)

    timestamps(type: :utc_datetime_usec)
  end

  @type t :: %__MODULE__{}

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(code_reference, attrs) do
    code_reference
    |> cast(attrs, [:flag_key, :file, :line])
    |> validate_required([:flag_key, :file, :line])
    |> validate_number(:line, greater_than: 0)
  end
end

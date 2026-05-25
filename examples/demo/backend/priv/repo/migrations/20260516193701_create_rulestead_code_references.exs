defmodule Rulestead.Repo.Migrations.CreateRulesteadCodeReferences do
  use Ecto.Migration

  def change do
    create table(:code_references, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :flag_key, :text, null: false
      add :file, :text, null: false
      add :line, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:code_references, [:flag_key])
  end
end

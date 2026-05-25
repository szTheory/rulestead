defmodule Rulestead.Repo.Migrations.CreateRulesteadEnvironmentVersions do
  use Ecto.Migration

  def change do
    create table(:environment_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :environment_key, :string, null: false
      add :version, :integer, null: false
      add :authored_snapshot, :map, null: false, default: %{}
      add :source_environment_key, :string
      add :target_environment_key, :string
      add :compare_token, :string
      add :source_fingerprint, :string
      add :target_fingerprint, :string
      add :dependency_closure_keys, {:array, :string}, null: false, default: []
      add :applied_flag_keys, {:array, :string}, null: false, default: []
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:environment_versions, [:environment_key, :version])
    create index(:environment_versions, [:environment_key])
    create index(:environment_versions, [:target_environment_key])
  end
end

defmodule Rulestead.Repo.Migrations.CreateRulesteadCodeReferenceScans do
  use Ecto.Migration

  def change do
    create table(:code_reference_scans, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :received_at, :utc_datetime_usec, null: false
      add :reference_count, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:code_reference_scans, [:received_at])

    create constraint(
             :code_reference_scans,
             :code_reference_scans_reference_count_must_be_non_negative,
             check: "reference_count >= 0"
           )
  end
end

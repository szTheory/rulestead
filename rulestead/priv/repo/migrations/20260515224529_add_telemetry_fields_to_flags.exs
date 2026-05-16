defmodule Rulestead.Repo.Migrations.AddTelemetryFieldsToFlags do
  use Ecto.Migration

  def change do
    alter table(:flag_environments) do
      add :variants_served, :map, default: %{}
    end
  end
end

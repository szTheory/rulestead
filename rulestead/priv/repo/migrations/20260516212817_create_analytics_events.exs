defmodule Rulestead.Repo.Migrations.CreateAnalyticsEvents do
  use Ecto.Migration

  def change do
    create table(:rulestead_analytics_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :kind, :string, null: false
      add :actor_id, :string
      add :event_name, :string
      add :env, :string
      add :metadata, :map, default: %{}
      add :occurred_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:rulestead_analytics_events, [:occurred_at])
  end
end

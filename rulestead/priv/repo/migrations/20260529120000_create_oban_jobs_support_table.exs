defmodule Rulestead.Repo.Migrations.CreateObanJobsSupportTable do
  use Ecto.Migration

  def up do
    create table(:oban_jobs) do
      add(:state, :text, null: false, default: "scheduled")
      add(:queue, :text, null: false, default: "default")
      add(:worker, :text, null: false)
      add(:args, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:meta, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:tags, {:array, :text}, null: false, default: [])
      add(:errors, {:array, :map}, null: false, default: [])
      add(:attempt, :integer, null: false, default: 0)
      add(:max_attempts, :integer, null: false, default: 3)
      add(:priority, :integer, null: false, default: 0)
      add(:attempted_by, {:array, :text})
      add(:attempted_at, :utc_datetime_usec)
      add(:cancelled_at, :utc_datetime_usec)
      add(:completed_at, :utc_datetime_usec)
      add(:discarded_at, :utc_datetime_usec)
      add(:inserted_at, :utc_datetime_usec, null: false)
      add(:scheduled_at, :utc_datetime_usec, null: false)
    end

    create(index(:oban_jobs, [:queue, :state, :scheduled_at]))
    create(index(:oban_jobs, [:worker]))
  end

  def down do
    drop(table(:oban_jobs))
  end
end

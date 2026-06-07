defmodule Rulestead.Repo.Migrations.CreateObanJobsSupportTable do
  use Rulestead.Migration, prefix: "rulestead", create_schema: true

  def up do
    create rulestead_table(:oban_jobs, primary_key: false) do
      add(:id, :bigserial, primary_key: true)
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
      # oban_jobs is queried schemaless (raw insert_all/from), so timestamps must be
      # `timestamptz` to read back as DateTime — matching the test-support DDL exactly.
      add(:attempted_at, :timestamptz)
      add(:cancelled_at, :timestamptz)
      add(:completed_at, :timestamptz)
      add(:discarded_at, :timestamptz)
      add(:inserted_at, :timestamptz, null: false)
      add(:scheduled_at, :timestamptz, null: false)
    end

    create(rulestead_index(:oban_jobs, [:queue, :state, :scheduled_at]))
    create(rulestead_index(:oban_jobs, [:worker]))
  end

  def down do
    drop(rulestead_table(:oban_jobs))
  end
end

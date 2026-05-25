defmodule Rulestead.Repo.Migrations.CreateRulesteadRuntimeSnapshots do
  use Ecto.Migration

  def up do
    create table(:runtime_snapshots, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:environment_key, :text, null: false)
      add(:version, :integer, null: false)
      add(:payload, :binary, null: false)
      add(:payload_checksum, :text, null: false)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:published_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:runtime_snapshots, [:environment_key, :version]))
    create(index(:runtime_snapshots, [:environment_key, :inserted_at]))

    create(
      constraint(:runtime_snapshots, :runtime_snapshots_version_must_be_positive,
        check: "version > 0"
      )
    )

    execute(
      """
      CREATE FUNCTION rulestead_prevent_runtime_snapshot_mutation()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'runtime_snapshots is append-only';
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS rulestead_prevent_runtime_snapshot_mutation()"
    )

    execute(
      """
      CREATE TRIGGER runtime_snapshots_prevent_update
      BEFORE UPDATE ON runtime_snapshots
      FOR EACH ROW
      EXECUTE FUNCTION rulestead_prevent_runtime_snapshot_mutation()
      """,
      "DROP TRIGGER IF EXISTS runtime_snapshots_prevent_update ON runtime_snapshots"
    )

    execute(
      """
      CREATE TRIGGER runtime_snapshots_prevent_delete
      BEFORE DELETE ON runtime_snapshots
      FOR EACH ROW
      EXECUTE FUNCTION rulestead_prevent_runtime_snapshot_mutation()
      """,
      "DROP TRIGGER IF EXISTS runtime_snapshots_prevent_delete ON runtime_snapshots"
    )
  end

  def down do
    execute("DROP TRIGGER IF EXISTS runtime_snapshots_prevent_delete ON runtime_snapshots")
    execute("DROP TRIGGER IF EXISTS runtime_snapshots_prevent_update ON runtime_snapshots")
    execute("DROP FUNCTION IF EXISTS rulestead_prevent_runtime_snapshot_mutation()")

    drop(table(:runtime_snapshots))
  end
end

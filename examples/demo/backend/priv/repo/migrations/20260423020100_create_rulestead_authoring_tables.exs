defmodule Rulestead.Repo.Migrations.CreateRulesteadAuthoringTables do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto", "DROP EXTENSION IF EXISTS pgcrypto")

    create table(:flags, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:description, :text)
      add(:flag_type, :text, null: false)
      add(:value_type, :text, null: false)
      add(:default_value, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:owner, :text, null: false)
      add(:expected_expiration, :date)
      add(:tags, {:array, :text}, null: false, default: [])
      add(:archived_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:flags, [:key]))

    create(
      constraint(:flags, :flags_flag_type_must_be_valid,
        check:
          "flag_type IN ('release', 'experiment', 'kill_switch', 'permission', 'remote_config', 'operational', 'migration')"
      )
    )

    create(
      constraint(:flags, :flags_value_type_must_be_valid,
        check: "value_type IN ('boolean', 'string', 'integer', 'float', 'json', 'variant')"
      )
    )

    create table(:environments, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:name, :text, null: false)
      add(:description, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:environments, [:key]))

    create table(:audiences, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:description, :text)
      add(:definition, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:archived_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:audiences, [:key]))

    create table(:flag_environments, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:flag_id, references(:flags, type: :uuid, on_delete: :delete_all), null: false)

      add(:environment_id, references(:environments, type: :uuid, on_delete: :restrict),
        null: false
      )

      add(:status, :text, null: false, default: "draft")
      add(:kill_switch_variant_key, :text)
      add(:last_published_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:flag_environments, [:flag_id, :environment_id]))

    create(
      constraint(:flag_environments, :flag_environments_status_must_be_valid,
        check: "status IN ('draft', 'active', 'archived', 'killswitched')"
      )
    )

    create table(:rulesets, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :flag_environment_id,
        references(:flag_environments, type: :uuid, on_delete: :delete_all), null: false)

      add(:version, :integer, null: false)
      add(:status, :text, null: false, default: "draft")
      add(:salt, :text)
      add(:published_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:rules, :map, null: false, default: fragment("'[]'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:rulesets, [:flag_environment_id, :version]))
    create(index(:rulesets, [:flag_environment_id, :status]))

    create(
      constraint(:rulesets, :rulesets_status_must_be_valid,
        check: "status IN ('draft', 'published')"
      )
    )

    create(constraint(:rulesets, :rulesets_version_must_be_positive, check: "version > 0"))

    create(
      constraint(:rulesets, :rulesets_published_rows_require_timestamp,
        check:
          "(status = 'draft' AND published_at IS NULL) OR (status = 'published' AND published_at IS NOT NULL)"
      )
    )

    alter table(:flag_environments) do
      add(:active_ruleset_id, references(:rulesets, type: :uuid, on_delete: :nilify_all))
    end

    create(index(:flag_environments, [:active_ruleset_id]))

    create table(:audit_events, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:event_type, :text, null: false)
      add(:resource_type, :text, null: false)
      add(:resource_id, :uuid)
      add(:resource_key, :text)
      add(:environment_key, :text)
      add(:actor_id, :text)
      add(:actor_type, :text)
      add(:actor_display, :text)
      add(:reason, :text)
      add(:result, :text, null: false, default: "ok")
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:correlation_id, :text)
      add(:occurred_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:audit_events, [:occurred_at]))
    create(index(:audit_events, [:resource_type, :resource_key, :occurred_at]))
    create(index(:audit_events, [:correlation_id], where: "correlation_id IS NOT NULL"))

    create(
      constraint(:audit_events, :audit_events_result_must_be_valid,
        check: "result IN ('ok', 'denied', 'error')"
      )
    )

    execute(
      """
      CREATE FUNCTION rulestead_prevent_published_ruleset_mutation()
      RETURNS trigger AS $$
      BEGIN
        IF OLD.status = 'published' OR OLD.published_at IS NOT NULL THEN
          RAISE EXCEPTION 'published rulesets are immutable';
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS rulestead_prevent_published_ruleset_mutation()"
    )

    execute(
      """
      CREATE TRIGGER rulesets_prevent_published_mutation
      BEFORE UPDATE ON rulesets
      FOR EACH ROW
      EXECUTE FUNCTION rulestead_prevent_published_ruleset_mutation()
      """,
      "DROP TRIGGER IF EXISTS rulesets_prevent_published_mutation ON rulesets"
    )

    execute(
      """
      CREATE FUNCTION rulestead_prevent_audit_event_mutation()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_events is append-only';
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS rulestead_prevent_audit_event_mutation()"
    )

    execute(
      """
      CREATE TRIGGER audit_events_prevent_update
      BEFORE UPDATE ON audit_events
      FOR EACH ROW
      EXECUTE FUNCTION rulestead_prevent_audit_event_mutation()
      """,
      "DROP TRIGGER IF EXISTS audit_events_prevent_update ON audit_events"
    )

    execute(
      """
      CREATE TRIGGER audit_events_prevent_delete
      BEFORE DELETE ON audit_events
      FOR EACH ROW
      EXECUTE FUNCTION rulestead_prevent_audit_event_mutation()
      """,
      "DROP TRIGGER IF EXISTS audit_events_prevent_delete ON audit_events"
    )
  end

  def down do
    execute("DROP TRIGGER IF EXISTS audit_events_prevent_delete ON audit_events")
    execute("DROP TRIGGER IF EXISTS audit_events_prevent_update ON audit_events")
    execute("DROP FUNCTION IF EXISTS rulestead_prevent_audit_event_mutation()")
    execute("DROP TRIGGER IF EXISTS rulesets_prevent_published_mutation ON rulesets")
    execute("DROP FUNCTION IF EXISTS rulestead_prevent_published_ruleset_mutation()")

    drop(table(:audit_events))

    alter table(:flag_environments) do
      remove(:active_ruleset_id)
    end

    drop(table(:rulesets))
    drop(table(:flag_environments))
    drop(table(:audiences))
    drop(table(:environments))
    drop(table(:flags))
  end
end

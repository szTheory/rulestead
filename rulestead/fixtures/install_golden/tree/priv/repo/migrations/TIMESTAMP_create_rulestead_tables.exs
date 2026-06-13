defmodule Rulestead.Repo.Migrations.CreateRulesteadTables do
  use Rulestead.Migration, prefix: "rulestead", create_schema: true

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto", "DROP EXTENSION IF EXISTS pgcrypto")
    create_rulestead_schema()

    flags = rulestead_qualified("flags")
    environments = rulestead_qualified("environments")
    audit_events = rulestead_qualified("audit_events")
    rulesets = rulestead_qualified("rulesets")
    runtime_snapshots = rulestead_qualified("runtime_snapshots")

    prevent_published_ruleset_mutation =
      rulestead_qualified("rulestead_prevent_published_ruleset_mutation")

    prevent_audit_event_mutation = rulestead_qualified("rulestead_prevent_audit_event_mutation")

    prevent_runtime_snapshot_mutation =
      rulestead_qualified("rulestead_prevent_runtime_snapshot_mutation")

    create rulestead_table(:flags, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:description, :text)
      add(:flag_type, :text, null: false)
      add(:value_type, :text, null: false)
      add(:default_value, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:tags, {:array, :text}, null: false, default: [])
      add(:archived_at, :utc_datetime_usec)
      add(:ownership, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:lifecycle, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:flags, [:key]))

    create(
      rulestead_constraint(:flags, :flags_flag_type_must_be_valid,
        check:
          "flag_type IN ('release', 'experiment', 'kill_switch', 'permission', 'remote_config', 'operational', 'migration')"
      )
    )

    create(
      rulestead_constraint(:flags, :flags_value_type_must_be_valid,
        check: "value_type IN ('boolean', 'string', 'integer', 'float', 'json', 'variant')"
      )
    )

    execute(
      """
      ALTER TABLE #{flags}
      ADD CONSTRAINT flags_ownership_requires_owner_ref
      CHECK (
        ownership ? 'owner_ref'
        AND ownership ? 'owner_kind'
        AND (ownership->>'owner_kind') IN ('person', 'team', 'service')
      )
      """,
      "ALTER TABLE #{flags} DROP CONSTRAINT IF EXISTS flags_ownership_requires_owner_ref"
    )

    execute(
      """
      ALTER TABLE #{flags}
      ADD CONSTRAINT flags_lifecycle_requires_mode
      CHECK (
        lifecycle ? 'mode'
        AND lifecycle ? 'default_source'
        AND lifecycle ? 'default_overridden'
        AND (lifecycle->>'mode') IN ('expiring', 'permanent')
        AND (lifecycle->>'default_source') IN ('flag_type', 'operator_override', 'operator_required', 'legacy_backfill')
      )
      """,
      "ALTER TABLE #{flags} DROP CONSTRAINT IF EXISTS flags_lifecycle_requires_mode"
    )

    create rulestead_table(:environments, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:name, :text, null: false)
      add(:description, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:environments, [:key]))

    execute("""
    INSERT INTO #{environments} (id, key, name, description, inserted_at, updated_at)
    VALUES
      (gen_random_uuid(), 'development', 'Development', 'Local and developer-owned environments', NOW(), NOW()),
      (gen_random_uuid(), 'staging', 'Staging', 'Pre-production validation environments', NOW(), NOW()),
      (gen_random_uuid(), 'production', 'Production', 'Live customer-facing environments', NOW(), NOW()),
      (gen_random_uuid(), 'test', 'Test', 'Automated and ephemeral test environments', NOW(), NOW())
    ON CONFLICT (key) DO NOTHING
    """)

    create rulestead_table(:audiences, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:key, :text, null: false)
      add(:description, :text)
      add(:definition, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:archived_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:audiences, [:key]))

    create rulestead_table(:flag_environments, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:flag_id, rulestead_references(:flags, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:environment_id, rulestead_references(:environments, type: :uuid, on_delete: :restrict),
        null: false
      )

      add(:status, :text, null: false, default: "draft")
      add(:kill_switch_variant_key, :text)
      add(:last_published_at, :utc_datetime_usec)
      add(:last_evaluated_at, :utc_datetime_usec)
      add(:variants_served, :map, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:flag_environments, [:flag_id, :environment_id]))
    create(rulestead_index(:flag_environments, [:last_evaluated_at]))

    create(
      rulestead_constraint(:flag_environments, :flag_environments_status_must_be_valid,
        check: "status IN ('draft', 'active', 'archived', 'killswitched')"
      )
    )

    create rulestead_table(:rulesets, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :flag_environment_id,
        rulestead_references(:flag_environments, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:version, :integer, null: false)
      add(:status, :text, null: false, default: "draft")
      add(:salt, :text)
      add(:published_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:rules, :map, null: false, default: fragment("'[]'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:rulesets, [:flag_environment_id, :version]))
    create(rulestead_index(:rulesets, [:flag_environment_id, :status]))

    create(
      rulestead_constraint(:rulesets, :rulesets_status_must_be_valid,
        check: "status IN ('draft', 'published')"
      )
    )

    create(
      rulestead_constraint(:rulesets, :rulesets_version_must_be_positive, check: "version > 0")
    )

    create(
      rulestead_constraint(:rulesets, :rulesets_published_rows_require_timestamp,
        check:
          "(status = 'draft' AND published_at IS NULL) OR (status = 'published' AND published_at IS NOT NULL)"
      )
    )

    alter rulestead_table(:flag_environments) do
      add(
        :active_ruleset_id,
        rulestead_references(:rulesets, type: :uuid, on_delete: :nilify_all)
      )
    end

    create(rulestead_index(:flag_environments, [:active_ruleset_id]))

    create rulestead_table(:audit_events, primary_key: false) do
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

    create(rulestead_index(:audit_events, [:occurred_at]))
    create(rulestead_index(:audit_events, [:resource_type, :resource_key, :occurred_at]))
    create(rulestead_index(:audit_events, [:correlation_id], where: "correlation_id IS NOT NULL"))

    create(
      rulestead_constraint(:audit_events, :audit_events_result_must_be_valid,
        check: "result IN ('ok', 'denied', 'error')"
      )
    )

    execute(
      """
      CREATE FUNCTION #{prevent_published_ruleset_mutation}()
      RETURNS trigger AS $$
      BEGIN
        IF OLD.status = 'published' OR OLD.published_at IS NOT NULL THEN
          RAISE EXCEPTION 'published rulesets are immutable';
        END IF;

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS #{prevent_published_ruleset_mutation}()"
    )

    execute(
      """
      CREATE TRIGGER rulesets_prevent_published_mutation
      BEFORE UPDATE ON #{rulesets}
      FOR EACH ROW
      EXECUTE FUNCTION #{prevent_published_ruleset_mutation}()
      """,
      "DROP TRIGGER IF EXISTS rulesets_prevent_published_mutation ON #{rulesets}"
    )

    execute(
      """
      CREATE FUNCTION #{prevent_audit_event_mutation}()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_events is append-only';
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS #{prevent_audit_event_mutation}()"
    )

    execute(
      """
      CREATE TRIGGER audit_events_prevent_update
      BEFORE UPDATE ON #{audit_events}
      FOR EACH ROW
      EXECUTE FUNCTION #{prevent_audit_event_mutation}()
      """,
      "DROP TRIGGER IF EXISTS audit_events_prevent_update ON #{audit_events}"
    )

    execute(
      """
      CREATE TRIGGER audit_events_prevent_delete
      BEFORE DELETE ON #{audit_events}
      FOR EACH ROW
      EXECUTE FUNCTION #{prevent_audit_event_mutation}()
      """,
      "DROP TRIGGER IF EXISTS audit_events_prevent_delete ON #{audit_events}"
    )

    create rulestead_table(:runtime_snapshots, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:environment_key, :text, null: false)
      add(:version, :integer, null: false)
      add(:payload, :binary, null: false)
      add(:payload_checksum, :text, null: false)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:published_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:runtime_snapshots, [:environment_key, :version]))
    create(rulestead_index(:runtime_snapshots, [:environment_key, :inserted_at]))

    create(
      rulestead_constraint(:runtime_snapshots, :runtime_snapshots_version_must_be_positive,
        check: "version > 0"
      )
    )

    execute(
      """
      CREATE FUNCTION #{prevent_runtime_snapshot_mutation}()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'runtime_snapshots is append-only';
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS #{prevent_runtime_snapshot_mutation}()"
    )

    execute(
      """
      CREATE TRIGGER runtime_snapshots_prevent_update
      BEFORE UPDATE ON #{runtime_snapshots}
      FOR EACH ROW
      EXECUTE FUNCTION #{prevent_runtime_snapshot_mutation}()
      """,
      "DROP TRIGGER IF EXISTS runtime_snapshots_prevent_update ON #{runtime_snapshots}"
    )

    execute(
      """
      CREATE TRIGGER runtime_snapshots_prevent_delete
      BEFORE DELETE ON #{runtime_snapshots}
      FOR EACH ROW
      EXECUTE FUNCTION #{prevent_runtime_snapshot_mutation}()
      """,
      "DROP TRIGGER IF EXISTS runtime_snapshots_prevent_delete ON #{runtime_snapshots}"
    )

    create rulestead_table(:change_requests, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:status, :text, null: false, default: "submitted")
      add(:governed_action, :text, null: false)
      add(:environment_key, :text, null: false)
      add(:resource_type, :text, null: false)
      add(:resource_key, :text, null: false)
      add(:submitter_id, :text, null: false)
      add(:submitter_type, :text, null: false)
      add(:submitter_display, :text)
      add(:reason, :text)
      add(:approval_requirement_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:command_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:correlation_id, :text, null: false)
      add(:submitted_at, :utc_datetime_usec, null: false)
      add(:resolved_at, :utc_datetime_usec)
      add(:executed_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:change_requests, [:environment_key, :status]))
    create(rulestead_index(:change_requests, [:resource_type, :resource_key, :inserted_at]))
    create(rulestead_unique_index(:change_requests, [:correlation_id]))

    create(
      rulestead_constraint(:change_requests, :change_requests_status_must_be_valid,
        check: "status IN ('submitted', 'approved', 'rejected', 'cancelled', 'executed')"
      )
    )

    create(
      rulestead_constraint(:change_requests, :change_requests_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings', 'promote_environment', 'apply_audience_mutation')"
      )
    )

    create rulestead_table(:approvals, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :change_request_id,
        rulestead_references(:change_requests, type: :uuid, on_delete: :delete_all), null: false)

      add(:decision, :text, null: false)
      add(:reviewer_id, :text, null: false)
      add(:reviewer_type, :text, null: false)
      add(:reviewer_display, :text)
      add(:reason, :text)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:correlation_id, :text, null: false)
      add(:reviewed_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(rulestead_index(:approvals, [:change_request_id, :reviewed_at]))
    create(rulestead_index(:approvals, [:correlation_id]))
    create(rulestead_unique_index(:approvals, [:change_request_id, :reviewer_id]))

    create(
      rulestead_constraint(:approvals, :approvals_decision_must_be_valid,
        check: "decision IN ('approved', 'rejected')"
      )
    )

    create rulestead_table(:webhook_receipts, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:provider, :text, null: false)
      add(:endpoint_key, :text, null: false)
      add(:delivery_id, :text, null: false)
      add(:attempt_id, :text)
      add(:topic, :text)

      add(:occurred_at, :utc_datetime_usec)
      add(:received_at, :utc_datetime_usec, null: false)

      add(:raw_body_sha256, :text, null: false)
      add(:verification_metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:normalized_payload, :map)
      add(:dedupe_key, :text)

      add(:verified_state, :text, null: false)
      add(:rejection_reason, :text)

      add(:correlation_id, :text, null: false)

      add(:change_request_id, :uuid)
      add(:scheduled_execution_id, :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:webhook_receipts, [:provider, :delivery_id]))
    create(rulestead_index(:webhook_receipts, [:endpoint_key]))
    create(rulestead_index(:webhook_receipts, [:verified_state]))
    create(rulestead_unique_index(:webhook_receipts, [:correlation_id]))

    create(
      rulestead_constraint(:webhook_receipts, :webhook_receipts_verified_state_must_be_valid,
        check:
          "verified_state IN ('accepted', 'rejected', 'malformed', 'unsigned', 'stale', 'replayed')"
      )
    )

    create rulestead_table(:webhook_replay_claims, primary_key: false) do
      add(:provider, :text, primary_key: true)
      add(:delivery_id, :text, primary_key: true)

      add(
        :receipt_id,
        rulestead_references(:webhook_receipts, type: :uuid, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(rulestead_index(:webhook_replay_claims, [:receipt_id]))

    create rulestead_table(:webhook_destinations, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :text, null: false)
      add(:description, :text)
      add(:url, :text, null: false)
      add(:secret_id, :text)
      add(:environment_key, :text, null: false)
      add(:subscriptions, {:array, :text}, null: false, default: [])
      add(:enabled, :boolean, null: false, default: true)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:webhook_destinations, [:environment_key]))
    create(rulestead_unique_index(:webhook_destinations, [:environment_key, :name]))

    create rulestead_table(:webhook_outbound_events, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:event_type, :text, null: false)
      add(:payload, :map, null: false)
      add(:resource_type, :text)
      add(:resource_key, :text)
      add(:environment_key, :text)
      add(:correlation_id, :text, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(rulestead_index(:webhook_outbound_events, [:correlation_id]))
    create(rulestead_index(:webhook_outbound_events, [:event_type]))

    create rulestead_table(:webhook_deliveries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :webhook_destination_id,
        rulestead_references(:webhook_destinations, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(
        :webhook_outbound_event_id,
        rulestead_references(:webhook_outbound_events, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:state, :text, null: false)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:last_attempt_at, :utc_datetime_usec)
      add(:next_attempt_at, :utc_datetime_usec)
      add(:terminal_failure_reason, :text)

      add(:last_response_code, :integer)
      add(:last_response_body, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:webhook_deliveries, [:webhook_destination_id]))
    create(rulestead_index(:webhook_deliveries, [:webhook_outbound_event_id]))
    create(rulestead_index(:webhook_deliveries, [:state]))
    create(rulestead_index(:webhook_deliveries, [:next_attempt_at]))

    create(
      rulestead_constraint(:webhook_deliveries, :webhook_deliveries_state_must_be_valid,
        check: "state IN ('pending', 'delivering', 'succeeded', 'failed', 'exhausted')"
      )
    )

    create rulestead_table(:scheduled_executions, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:state, :text, null: false, default: "scheduled")

      add(
        :change_request_id,
        rulestead_references(:change_requests, type: :uuid, on_delete: :nilify_all)
      )

      add(:governed_action, :text, null: false)
      add(:environment_key, :text)
      add(:resource_type, :text)
      add(:resource_key, :text)
      add(:execution_mode, :text, null: false, default: "change_request")

      add(:scheduled_by_id, :text, null: false)
      add(:scheduled_by_type, :text, null: false)
      add(:scheduled_by_display, :text)
      add(:approved_by_snapshot, {:array, :map}, null: false, default: [])
      add(:execution_metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      add(:scheduled_for, :utc_datetime_usec, null: false)
      add(:executed_at, :utc_datetime_usec)
      add(:attempt_count, :integer, null: false, default: 0)
      add(:failure_reason, :text)
      add(:last_oban_job_id, :bigint)

      add(:command_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:approval_requirement_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:correlation_id, :text, null: false)
      add(:idempotency_key, :text, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:scheduled_executions, [:state, :scheduled_for]))
    create(rulestead_index(:scheduled_executions, [:change_request_id]))

    create(
      rulestead_index(:scheduled_executions, [:environment_key, :resource_type, :resource_key])
    )

    create(rulestead_unique_index(:scheduled_executions, [:idempotency_key]))
    create(rulestead_unique_index(:scheduled_executions, [:correlation_id]))

    create(
      rulestead_constraint(:scheduled_executions, :scheduled_executions_state_must_be_valid,
        check:
          "state IN ('scheduled', 'running', 'completed', 'failed', 'quarantined', 'cancelled')"
      )
    )

    create(
      rulestead_constraint(
        :scheduled_executions,
        :scheduled_executions_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'release_kill_switch', 'promote_environment')"
      )
    )

    create(
      rulestead_constraint(
        :scheduled_executions,
        :scheduled_executions_execution_mode_must_be_valid,
        check: "execution_mode IN ('change_request', 'policy_bypass', 'emergency_bypass')"
      )
    )

    create(
      rulestead_constraint(
        :scheduled_executions,
        :scheduled_executions_attempt_count_must_be_non_negative, check: "attempt_count >= 0")
    )

    create rulestead_table(:execution_attempts, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :scheduled_execution_id,
        rulestead_references(:scheduled_executions, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:attempt_number, :integer, null: false)
      add(:state, :text, null: false)
      add(:started_at, :utc_datetime_usec, null: false)
      add(:finished_at, :utc_datetime_usec)
      add(:failure_reason, :text)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(
      rulestead_unique_index(:execution_attempts, [:scheduled_execution_id, :attempt_number])
    )

    create(
      rulestead_constraint(:execution_attempts, :execution_attempts_state_must_be_valid,
        check: "state IN ('running', 'completed', 'failed', 'quarantined', 'cancelled')"
      )
    )

    create(
      rulestead_constraint(
        :execution_attempts,
        :execution_attempts_attempt_number_must_be_positive, check: "attempt_number > 0")
    )

    create rulestead_table(:code_references, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:flag_key, :text, null: false)
      add(:file, :text, null: false)
      add(:line, :integer, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:code_references, [:flag_key]))

    create rulestead_table(:rulestead_analytics_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:kind, :string, null: false)
      add(:actor_id, :string)
      add(:event_name, :string)
      add(:env, :string)
      add(:metadata, :map, default: fragment("'{}'::jsonb"))
      add(:occurred_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:rulestead_analytics_events, [:occurred_at]))

    create rulestead_table(:environment_versions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:tenant_key, :string)
      add(:environment_key, :string, null: false)
      add(:version, :integer, null: false)
      add(:authored_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:source_environment_key, :string)
      add(:target_environment_key, :string)
      add(:compare_token, :string)
      add(:source_fingerprint, :string)
      add(:target_fingerprint, :string)
      add(:dependency_closure_keys, {:array, :string}, null: false, default: [])
      add(:applied_flag_keys, {:array, :string}, null: false, default: [])
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_unique_index(:environment_versions, [:environment_key, :version]))
    create(rulestead_index(:environment_versions, [:environment_key]))
    create(rulestead_index(:environment_versions, [:target_environment_key]))

    create rulestead_table(:code_reference_scans, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:received_at, :utc_datetime_usec, null: false)
      add(:reference_count, :integer, null: false, default: 0)

      timestamps(type: :utc_datetime_usec)
    end

    create(rulestead_index(:code_reference_scans, [:received_at]))

    create(
      rulestead_constraint(
        :code_reference_scans,
        :code_reference_scans_reference_count_must_be_non_negative,
        check: "reference_count >= 0"
      )
    )
  end

  def down do
    flags = rulestead_qualified("flags")
    environments = rulestead_qualified("environments")
    audit_events = rulestead_qualified("audit_events")
    rulesets = rulestead_qualified("rulesets")
    runtime_snapshots = rulestead_qualified("runtime_snapshots")

    prevent_published_ruleset_mutation =
      rulestead_qualified("rulestead_prevent_published_ruleset_mutation")

    prevent_audit_event_mutation = rulestead_qualified("rulestead_prevent_audit_event_mutation")

    prevent_runtime_snapshot_mutation =
      rulestead_qualified("rulestead_prevent_runtime_snapshot_mutation")

    execute("DROP TRIGGER IF EXISTS audit_events_prevent_delete ON #{audit_events}")
    execute("DROP TRIGGER IF EXISTS audit_events_prevent_update ON #{audit_events}")
    execute("DROP FUNCTION IF EXISTS #{prevent_audit_event_mutation}()")

    execute("DROP TRIGGER IF EXISTS rulesets_prevent_published_mutation ON #{rulesets}")
    execute("DROP FUNCTION IF EXISTS #{prevent_published_ruleset_mutation}()")

    execute("DROP TRIGGER IF EXISTS runtime_snapshots_prevent_delete ON #{runtime_snapshots}")
    execute("DROP TRIGGER IF EXISTS runtime_snapshots_prevent_update ON #{runtime_snapshots}")
    execute("DROP FUNCTION IF EXISTS #{prevent_runtime_snapshot_mutation}()")

    drop(rulestead_table(:code_reference_scans))
    drop(rulestead_table(:environment_versions))
    drop(rulestead_table(:rulestead_analytics_events))
    drop(rulestead_table(:code_references))
    drop(rulestead_table(:execution_attempts))
    drop(rulestead_table(:scheduled_executions))
    drop(rulestead_table(:webhook_deliveries))
    drop(rulestead_table(:webhook_outbound_events))
    drop(rulestead_table(:webhook_destinations))
    drop(rulestead_table(:webhook_replay_claims))
    drop(rulestead_table(:webhook_receipts))
    drop(rulestead_table(:approvals))
    drop(rulestead_table(:change_requests))
    drop(rulestead_table(:runtime_snapshots))
    drop(rulestead_table(:audit_events))

    alter rulestead_table(:flag_environments) do
      remove(:active_ruleset_id)
    end

    drop(rulestead_table(:rulesets))
    drop(rulestead_table(:flag_environments))
    drop(rulestead_table(:audiences))

    execute("""
    DELETE FROM #{environments}
    WHERE key IN ('development', 'staging', 'production', 'test')
    """)

    drop(rulestead_table(:environments))

    execute("ALTER TABLE #{flags} DROP CONSTRAINT IF EXISTS flags_lifecycle_requires_mode")
    execute("ALTER TABLE #{flags} DROP CONSTRAINT IF EXISTS flags_ownership_requires_owner_ref")

    drop(rulestead_table(:flags))
    drop_rulestead_schema()
  end
end

defmodule Rulestead.Repo.Migrations.CreateRulesteadScheduledExecutionsAndAttempts do
  use Ecto.Migration

  def up do
    create table(:scheduled_executions, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:state, :text, null: false, default: "scheduled")

      add(:change_request_id, references(:change_requests, type: :uuid, on_delete: :nilify_all))
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

    create(index(:scheduled_executions, [:state, :scheduled_for]))
    create(index(:scheduled_executions, [:change_request_id]))
    create(index(:scheduled_executions, [:environment_key, :resource_type, :resource_key]))
    create(unique_index(:scheduled_executions, [:idempotency_key]))
    create(unique_index(:scheduled_executions, [:correlation_id]))

    create(
      constraint(:scheduled_executions, :scheduled_executions_state_must_be_valid,
        check:
          "state IN ('scheduled', 'running', 'completed', 'failed', 'quarantined', 'cancelled')"
      )
    )

    create(
      constraint(:scheduled_executions, :scheduled_executions_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'release_kill_switch')"
      )
    )

    create(
      constraint(:scheduled_executions, :scheduled_executions_execution_mode_must_be_valid,
        check: "execution_mode IN ('change_request', 'policy_bypass', 'emergency_bypass')"
      )
    )

    create(
      constraint(:scheduled_executions, :scheduled_executions_attempt_count_must_be_non_negative,
        check: "attempt_count >= 0"
      )
    )

    create table(:execution_attempts, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(
        :scheduled_execution_id,
        references(:scheduled_executions, type: :uuid, on_delete: :delete_all),
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

    create(unique_index(:execution_attempts, [:scheduled_execution_id, :attempt_number]))

    create(
      constraint(:execution_attempts, :execution_attempts_state_must_be_valid,
        check: "state IN ('running', 'completed', 'failed', 'quarantined', 'cancelled')"
      )
    )

    create(
      constraint(:execution_attempts, :execution_attempts_attempt_number_must_be_positive,
        check: "attempt_number > 0"
      )
    )
  end

  def down do
    drop(table(:execution_attempts))
    drop(table(:scheduled_executions))
  end
end

defmodule Rulestead.Repo.Migrations.CreateRulesteadChangeRequestsAndApprovals do
  use Ecto.Migration

  def up do
    create table(:change_requests, primary_key: false) do
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

    create(index(:change_requests, [:environment_key, :status]))
    create(index(:change_requests, [:resource_type, :resource_key, :inserted_at]))
    create(unique_index(:change_requests, [:correlation_id]))

    create(
      constraint(:change_requests, :change_requests_status_must_be_valid,
        check: "status IN ('submitted', 'approved', 'rejected', 'cancelled', 'executed')"
      )
    )

    create(
      constraint(:change_requests, :change_requests_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings')"
      )
    )

    create table(:approvals, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:change_request_id, references(:change_requests, type: :uuid, on_delete: :delete_all),
        null: false
      )

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

    create(index(:approvals, [:change_request_id, :reviewed_at]))
    create(index(:approvals, [:correlation_id]))
    create(unique_index(:approvals, [:change_request_id, :reviewer_id]))

    create(
      constraint(:approvals, :approvals_decision_must_be_valid,
        check: "decision IN ('approved', 'rejected')"
      )
    )
  end

  def down do
    drop(table(:approvals))
    drop(table(:change_requests))
  end
end

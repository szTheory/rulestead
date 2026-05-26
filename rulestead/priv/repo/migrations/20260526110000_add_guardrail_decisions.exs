defmodule Rulestead.Repo.Migrations.AddGuardrailDecisions do
  use Ecto.Migration

  def change do
    create table(:guardrail_decisions, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:flag_key, :text, null: false)
      add(:environment_key, :text, null: false)
      add(:rule_key, :text, null: false)
      add(:stage, :text, null: false)
      add(:tenant_key, :text)
      add(:decision_state, :text, null: false)
      add(:action_type, :text, null: false)
      add(:decision_reason, :text)
      add(:effective_percentage, :integer)
      add(:rollout_salt, :text)
      add(:variant_fingerprint, :text)
      add(:monitoring_window_started_at, :utc_datetime_usec)
      add(:monitoring_window_ends_at, :utc_datetime_usec)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:signal_facts, {:array, :map}, null: false, default: [])
      add(:guardrail_evidence, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:authored_snapshot, :map)
      add(:rollback_target_snapshot, :map)
      add(:correlation_id, :text)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:guardrail_decisions, [:flag_key, :environment_key, :occurred_at]))
    create(index(:guardrail_decisions, [:flag_key, :environment_key, :rule_key, :stage, :occurred_at]))
    create(index(:guardrail_decisions, [:correlation_id]))

    create(
      constraint(:guardrail_decisions, :guardrail_decisions_decision_state_must_be_valid,
        check:
          "decision_state IN ('healthy', 'pending_data', 'held', 'rollback_triggered')"
      )
    )

    create(
      constraint(:guardrail_decisions, :guardrail_decisions_action_type_must_be_valid,
        check: "action_type IN ('advance', 'evaluate', 'hold', 'rollback')"
      )
    )

    create(
      constraint(:guardrail_decisions, :guardrail_decisions_effective_percentage_bounds,
        check:
          "effective_percentage IS NULL OR (effective_percentage >= 0 AND effective_percentage <= 100)"
      )
    )
  end
end

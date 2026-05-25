defmodule Rulestead.Repo.Migrations.CreateRulesteadWebhookReceiptsAndReplayClaims do
  use Ecto.Migration

  def up do
    create table(:webhook_receipts, primary_key: false) do
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
      
      # Optional links to governance objects
      add(:change_request_id, :uuid)
      add(:scheduled_execution_id, :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:webhook_receipts, [:provider, :delivery_id]))
    create(index(:webhook_receipts, [:endpoint_key]))
    create(index(:webhook_receipts, [:verified_state]))
    create(unique_index(:webhook_receipts, [:correlation_id]))

    create(
      constraint(:webhook_receipts, :webhook_receipts_verified_state_must_be_valid,
        check: "verified_state IN ('accepted', 'rejected', 'malformed', 'unsigned', 'stale', 'replayed')"
      )
    )

    create table(:webhook_replay_claims, primary_key: false) do
      add(:provider, :text, primary_key: true)
      add(:delivery_id, :text, primary_key: true)
      add(:receipt_id, references(:webhook_receipts, type: :uuid, on_delete: :delete_all), null: false)
      
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:webhook_replay_claims, [:receipt_id]))
  end

  def down do
    drop(table(:webhook_replay_claims))
    drop(table(:webhook_receipts))
  end
end

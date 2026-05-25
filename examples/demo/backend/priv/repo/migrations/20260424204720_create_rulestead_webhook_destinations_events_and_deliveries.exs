defmodule Rulestead.Repo.Migrations.CreateRulesteadWebhookDestinationsEventsAndDeliveries do
  use Ecto.Migration

  def up do
    create table(:webhook_destinations, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:name, :text, null: false)
      add(:description, :text)
      add(:url, :text, null: false)
      add(:secret_id, :text) # Reference to host-managed secret storage
      add(:environment_key, :text, null: false)
      add(:subscriptions, {:array, :text}, null: false, default: [])
      add(:enabled, :boolean, null: false, default: true)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:webhook_destinations, [:environment_key]))
    create(unique_index(:webhook_destinations, [:environment_key, :name]))

    create table(:webhook_outbound_events, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:event_type, :text, null: false)
      add(:payload, :map, null: false)
      add(:resource_type, :text)
      add(:resource_key, :text)
      add(:environment_key, :text)
      add(:correlation_id, :text, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(index(:webhook_outbound_events, [:correlation_id]))
    create(index(:webhook_outbound_events, [:event_type]))

    create table(:webhook_deliveries, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:webhook_destination_id, references(:webhook_destinations, type: :uuid, on_delete: :delete_all), null: false)
      add(:webhook_outbound_event_id, references(:webhook_outbound_events, type: :uuid, on_delete: :delete_all), null: false)

      add(:state, :text, null: false) # pending, delivering, succeeded, failed, exhausted
      add(:attempt_count, :integer, null: false, default: 0)
      add(:last_attempt_at, :utc_datetime_usec)
      add(:next_attempt_at, :utc_datetime_usec)
      add(:terminal_failure_reason, :text)

      add(:last_response_code, :integer)
      add(:last_response_body, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create(index(:webhook_deliveries, [:webhook_destination_id]))
    create(index(:webhook_deliveries, [:webhook_outbound_event_id]))
    create(index(:webhook_deliveries, [:state]))
    create(index(:webhook_deliveries, [:next_attempt_at]))

    create(
      constraint(:webhook_deliveries, :webhook_deliveries_state_must_be_valid,
        check: "state IN ('pending', 'delivering', 'succeeded', 'failed', 'exhausted')"
      )
    )
  end

  def down do
    drop(table(:webhook_deliveries))
    drop(table(:webhook_outbound_events))
    drop(table(:webhook_destinations))
  end
end

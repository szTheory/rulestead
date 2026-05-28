defmodule Rulestead.Repo.Migrations.AddRolloutAutoAdvancePolicies do
  use Ecto.Migration

  def change do
    create table(:rollout_auto_advance_policies, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:flag_key, :text, null: false)
      add(:environment_key, :text, null: false)
      add(:rule_key, :text, null: false)
      add(:enabled, :boolean, null: false, default: false)
      add(:observation_window_seconds, :integer)
      add(:next_stage, :text)
      add(:next_percentage, :integer)
      add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))

      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:rollout_auto_advance_policies, [:flag_key, :environment_key, :rule_key])
    )

    create(
      constraint(:rollout_auto_advance_policies, :observation_window_positive,
        check: "observation_window_seconds IS NULL OR observation_window_seconds > 0"
      )
    )

    create(
      constraint(:rollout_auto_advance_policies, :next_percentage_bounds,
        check: "next_percentage IS NULL OR (next_percentage >= 0 AND next_percentage <= 100)"
      )
    )
  end
end

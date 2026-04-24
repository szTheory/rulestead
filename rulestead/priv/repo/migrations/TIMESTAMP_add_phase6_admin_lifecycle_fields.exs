defmodule Rulestead.Repo.Migrations.AddPhase6AdminLifecycleFields do
  use Ecto.Migration

  def up do
    alter table(:flags) do
      add(:permanent, :boolean, null: false, default: false)
    end

    execute(
      """
      UPDATE flags
      SET permanent = CASE
        WHEN expected_expiration IS NULL THEN true
        ELSE false
      END
      """,
      "UPDATE flags SET permanent = false"
    )

    create(
      constraint(:flags, :flags_require_expiration_or_permanent,
        check:
          "(permanent = true AND expected_expiration IS NULL) OR (permanent = false AND expected_expiration IS NOT NULL)"
      )
    )

    alter table(:flag_environments) do
      add(:last_evaluated_at, :utc_datetime_usec)
    end

    create(index(:flag_environments, [:last_evaluated_at]))
  end

  def down do
    drop(index(:flag_environments, [:last_evaluated_at]))
    drop(constraint(:flags, :flags_require_expiration_or_permanent))

    alter table(:flag_environments) do
      remove(:last_evaluated_at)
    end

    alter table(:flags) do
      remove(:permanent)
    end
  end
end

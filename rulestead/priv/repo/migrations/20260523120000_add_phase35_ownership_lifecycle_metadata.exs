defmodule Rulestead.Repo.Migrations.AddPhase35OwnershipLifecycleMetadata do
  use Ecto.Migration

  def up do
    alter table(:flags) do
      add(:ownership, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:lifecycle, :map, null: false, default: fragment("'{}'::jsonb"))
    end

    execute(
      """
      UPDATE flags
      SET ownership = jsonb_build_object(
            'owner_ref', trim(owner),
            'owner_kind', 'team',
            'owner_display', nullif(trim(owner), '')
          ),
          lifecycle = jsonb_strip_nulls(
            jsonb_build_object(
              'mode', CASE WHEN permanent THEN 'permanent' ELSE 'expiring' END,
              'review_by', expected_expiration,
              'default_source', 'legacy_backfill',
              'default_overridden', false
            )
          )
      WHERE trim(owner) <> ''
      """,
      """
      UPDATE flags
      SET ownership = '{}'::jsonb,
          lifecycle = '{}'::jsonb
      """
    )

    execute(
      """
      ALTER TABLE flags
      ADD CONSTRAINT flags_ownership_requires_owner_ref
      CHECK (
        ownership ? 'owner_ref'
        AND ownership ? 'owner_kind'
        AND (ownership->>'owner_kind') IN ('person', 'team', 'service')
      )
      """,
      "ALTER TABLE flags DROP CONSTRAINT IF EXISTS flags_ownership_requires_owner_ref"
    )

    execute(
      """
      ALTER TABLE flags
      ADD CONSTRAINT flags_lifecycle_requires_mode
      CHECK (
        lifecycle ? 'mode'
        AND lifecycle ? 'default_source'
        AND lifecycle ? 'default_overridden'
        AND (lifecycle->>'mode') IN ('expiring', 'permanent')
        AND (lifecycle->>'default_source') IN ('flag_type', 'operator_override', 'operator_required', 'legacy_backfill')
      )
      """,
      "ALTER TABLE flags DROP CONSTRAINT IF EXISTS flags_lifecycle_requires_mode"
    )
  end

  def down do
    execute("ALTER TABLE flags DROP CONSTRAINT IF EXISTS flags_lifecycle_requires_mode")
    execute("ALTER TABLE flags DROP CONSTRAINT IF EXISTS flags_ownership_requires_owner_ref")

    alter table(:flags) do
      remove(:lifecycle)
      remove(:ownership)
    end
  end
end

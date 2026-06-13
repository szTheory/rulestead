defmodule Rulestead.Repo.Migrations.CreateAudienceReferenceProjection do
  use Rulestead.Migration, prefix: "rulestead", create_schema: true

  def change do
    create rulestead_table(:audience_reference_projection, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:environment_key, :text, null: false)
      add(:tenant_key, :text, null: false)
      add(:audience_key, :text, null: false)
      add(:flag_key, :text, null: false)
      add(:ruleset_version, :integer, null: false)
      add(:rule_key, :text, null: false)
      add(:rule_strategy, :text)
      add(:ruleset_status, :text)
      add(:rollout_context, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:lifecycle_context, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:visibility, :map, null: false, default: fragment("'{}'::jsonb"))
      add(:reference_count, :integer, null: false, default: 1)
      add(:hidden_reference_count, :integer, null: false, default: 0)

      timestamps(type: :utc_datetime_usec)
    end

    create(
      rulestead_unique_index(
        :audience_reference_projection,
        [:environment_key, :tenant_key, :flag_key, :ruleset_version, :rule_key, :audience_key],
        name: :audience_reference_projection_identity_index
      )
    )

    create(rulestead_index(:audience_reference_projection, [:environment_key, :tenant_key]))
    create(rulestead_index(:audience_reference_projection, [:audience_key]))

    create(
      rulestead_index(:audience_reference_projection, [:flag_key, :ruleset_version, :rule_key])
    )

    create(
      rulestead_constraint(
        :audience_reference_projection,
        :audience_reference_projection_ruleset_positive, check: "ruleset_version > 0")
    )

    create(
      rulestead_constraint(
        :audience_reference_projection,
        :audience_reference_projection_reference_count_non_negative,
        check: "reference_count >= 0"
      )
    )

    create(
      rulestead_constraint(
        :audience_reference_projection,
        :audience_reference_projection_hidden_reference_count_non_negative,
        check: "hidden_reference_count >= 0"
      )
    )
  end
end

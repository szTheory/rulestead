defmodule Rulestead.Repo.Migrations.ExtendRulesteadScheduledExecutionActionsForPromotion do
  use Ecto.Migration

  def up do
    drop_if_exists(
      constraint(:scheduled_executions, :scheduled_executions_governed_action_must_be_valid)
    )

    create(
      constraint(:scheduled_executions, :scheduled_executions_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'release_kill_switch', 'promote_environment')"
      )
    )
  end

  def down do
    drop_if_exists(
      constraint(:scheduled_executions, :scheduled_executions_governed_action_must_be_valid)
    )

    create(
      constraint(:scheduled_executions, :scheduled_executions_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'release_kill_switch')"
      )
    )
  end
end

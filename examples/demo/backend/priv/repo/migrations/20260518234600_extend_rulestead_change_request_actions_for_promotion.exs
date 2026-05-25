defmodule Rulestead.Repo.Migrations.ExtendRulesteadChangeRequestActionsForPromotion do
  use Ecto.Migration

  def up do
    drop_if_exists(
      constraint(:change_requests, :change_requests_governed_action_must_be_valid)
    )

    create(
      constraint(:change_requests, :change_requests_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings', 'promote_environment')"
      )
    )
  end

  def down do
    drop_if_exists(
      constraint(:change_requests, :change_requests_governed_action_must_be_valid)
    )

    create(
      constraint(:change_requests, :change_requests_governed_action_must_be_valid,
        check:
          "governed_action IN ('publish_ruleset', 'advance_rollout', 'engage_kill_switch', 'manage_settings')"
      )
    )
  end
end

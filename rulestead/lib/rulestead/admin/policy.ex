defmodule Rulestead.Admin.Policy do
  @moduledoc false
  # Host-owned authorization seam for mounted admin actions.
  #
  # `rulestead_admin` calls `can?/4` with explicit actor, action, resource,
  # and environment scope rather than inferring authorization from roles.

  @type governance_action ::
          :publish_ruleset
          | :advance_rollout
          | :engage_kill_switch
          | :release_kill_switch
          | :promote_environment

  @type viewer_action ::
          :read_flags
          | :read_rulesets
          | :read_rollouts
          | :simulate_flag
          | :explain_flag
          | :list_audit_events
          | :read_change_requests
          | :read_schedules
          | :list_webhook_records
          | :fetch_webhook_record
          | :read_diagnostics
          | :compare_environments

  @type editor_action ::
          :create_flag
          | :update_flag
          | :archive_flag
          | :save_draft
          | :submit_change_request
          | :cancel_own_change_request
          | :create_schedule

  @type admin_action ::
          :approve_change_request
          | :reject_change_request
          | :execute_change_request
          | :cancel_schedule
          | :requeue_schedule
          | :recover_schedule
          | :rollback_audit
          | :export_audit
          | :manage_webhooks
          | :manage_settings

  @type action ::
          governance_action() | viewer_action() | editor_action() | admin_action() | atom()

  @type environment_key :: String.t() | atom() | nil
  @type resource :: term()
  @type actor :: term()

  @governance_actions [
    :publish_ruleset,
    :advance_rollout,
    :engage_kill_switch,
    :release_kill_switch,
    :promote_environment
  ]

  @viewer_actions [
    :read_flags,
    :read_rulesets,
    :read_rollouts,
    :simulate_flag,
    :explain_flag,
    :list_audit_events,
    :read_change_requests,
    :read_schedules,
    :list_webhook_records,
    :fetch_webhook_record,
    :read_diagnostics,
    :compare_environments
  ]

  @editor_actions [
    :create_flag,
    :update_flag,
    :archive_flag,
    :save_draft,
    :submit_change_request,
    :cancel_own_change_request,
    :create_schedule
  ]

  @admin_actions [
    :approve_change_request,
    :reject_change_request,
    :execute_change_request,
    :cancel_schedule,
    :requeue_schedule,
    :recover_schedule,
    :rollback_audit,
    :export_audit,
    :manage_webhooks,
    :manage_settings
  ]

  @spec governance_actions() :: [governance_action()]
  def governance_actions, do: @governance_actions

  @spec viewer_actions() :: [viewer_action()]
  def viewer_actions, do: @viewer_actions

  @spec editor_actions() :: [editor_action()]
  def editor_actions, do: @editor_actions

  @spec admin_actions() :: [admin_action()]
  def admin_actions, do: @admin_actions

  @callback can?(
              actor :: actor(),
              action :: action(),
              resource :: resource(),
              environment_key :: environment_key()
            ) :: boolean()

  @callback change_request_required?(
              actor :: term(),
              action :: governance_action(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
            ) :: boolean()

  @callback allow_self_approval?(
              actor :: term(),
              action :: governance_action(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
            ) :: boolean()

  @optional_callbacks change_request_required?: 4, allow_self_approval?: 4
end

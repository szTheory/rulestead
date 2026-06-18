defmodule Rulestead.Admin.Policy do
  @moduledoc """
  Host-owned authorization seam for the mounted admin and governed actions.

  Rulestead does not ship an auth stack. You implement this behaviour in your
  application and pass it to `RulesteadAdmin.Router.rulestead_admin/2` (and it is
  consulted for governed runtime mutations). Each call is explicit about *who*
  (`actor`), *what* (`action`), *which resource*, and *which environment* — there
  is no implicit role inference.

      defmodule MyApp.RulesteadPolicy do
        @behaviour Rulestead.Admin.Policy

        @impl true
        def can?(actor, action, _resource, _environment_key) do
          action in Rulestead.Admin.Policy.viewer_actions() or admin?(actor)
        end
      end

  ## Canonical role model

  Actions map to the Viewer / Editor / Admin model. The action catalogs are
  introspectable via the read-only role-vocabulary helpers: `viewer_actions/0`,
  `editor_actions/0`, `admin_actions/0`, and `governance_actions/0`.

  ## Callbacks

  `c:can?/4` is required. `c:change_request_required?/4` and
  `c:allow_self_approval?/4` are optional and default to safe (governed) behavior.
  """

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
          | :preview_audience_impact
          | :list_audience_dependencies

  @type editor_action ::
          :create_flag
          | :update_flag
          | :archive_flag
          | :save_draft
          | :apply_audience_mutation
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
    :compare_environments,
    :preview_audience_impact,
    :list_audience_dependencies
  ]

  @editor_actions [
    :create_flag,
    :update_flag,
    :archive_flag,
    :save_draft,
    :apply_audience_mutation,
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

  @doc """
  Role-vocabulary / introspection helper (read-only catalog).

  Returns the list of `t:governance_action/0` atoms representing high-impact
  mutations that typically require change-request approval:

  - `:publish_ruleset`
  - `:advance_rollout`
  - `:engage_kill_switch`
  - `:release_kill_switch`
  - `:promote_environment`

  Use this catalog in your `c:can?/4` and `c:change_request_required?/4`
  implementations to guard these actions without hard-coding the atom list.
  This is a read-only catalog — calling it has no side effects.
  """
  @spec governance_actions() :: [governance_action()]
  def governance_actions, do: @governance_actions

  @doc """
  Role-vocabulary / introspection helper (read-only catalog).

  Returns the list of `t:viewer_action/0` atoms representing read-only or safe
  simulation actions available to the Viewer role (14 atoms). Includes actions
  such as `:read_flags`, `:simulate_flag`, `:explain_flag`, `:read_diagnostics`,
  and related read-only operations.

  Use this catalog in `c:can?/4` to define Viewer-level access without
  hard-coding the full atom list.
  """
  @spec viewer_actions() :: [viewer_action()]
  def viewer_actions, do: @viewer_actions

  @doc """
  Role-vocabulary / introspection helper (read-only catalog).

  Returns the list of `t:editor_action/0` atoms representing authoring operations
  available to the Editor role (8 atoms). Includes actions such as `:create_flag`,
  `:update_flag`, `:archive_flag`, `:save_draft`, and `:submit_change_request`.

  Use this catalog in `c:can?/4` to define Editor-level access without
  hard-coding the full atom list.
  """
  @spec editor_actions() :: [editor_action()]
  def editor_actions, do: @editor_actions

  @doc """
  Role-vocabulary / introspection helper (read-only catalog).

  Returns the list of `t:admin_action/0` atoms representing administrative
  operations available to the Admin role (10 atoms). Includes approval and
  rejection of change requests, schedule management, audit export, webhooks, and
  settings. These include the review side of the change-request workflow.

  Use this catalog in `c:can?/4` to define Admin-level access without
  hard-coding the full atom list.
  """
  @spec admin_actions() :: [admin_action()]
  def admin_actions, do: @admin_actions

  @doc """
  Required callback. Returns `true` if `actor` is permitted to perform `action`
  on `resource` in `environment_key`.

  Called by the mounted admin and by governed runtime mutations. Each argument is
  explicit — there is no implicit role inference from the actor's shape.

  Implement this callback to map your application's identity and permission model
  onto Rulestead's action vocabulary. The action catalogs (`viewer_actions/0`,
  `editor_actions/0`, `admin_actions/0`, `governance_actions/0`) are available as
  read-only helpers for building your implementation.
  """
  @callback can?(
              actor :: actor(),
              action :: action(),
              resource :: resource(),
              environment_key :: environment_key()
            ) :: boolean()

  @doc """
  Optional callback. Returns `true` if the given `action` requires a change
  request (human approval) before being applied.

  Called only for `t:governance_action/0` atoms. When not implemented, the default
  behavior is `false` — no change request required. Return `true` for governance
  actions that must go through an approval workflow before taking effect
  (e.g. requiring approval before publishing a ruleset to production).
  """
  @callback change_request_required?(
              actor :: term(),
              action :: governance_action(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
            ) :: boolean()

  @doc """
  Optional callback. Returns `true` if `actor` is permitted to approve their own
  change request for `action`.

  Called only when a change request exists and the submitter is the same actor
  attempting to approve it. When not implemented, the default behavior is `false`
  — the submitter cannot approve their own request. Return `true` to allow
  self-approval (e.g. for admin users who are trusted to approve their own
  governed actions).
  """
  @callback allow_self_approval?(
              actor :: term(),
              action :: governance_action(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
            ) :: boolean()

  @optional_callbacks change_request_required?: 4, allow_self_approval?: 4
end

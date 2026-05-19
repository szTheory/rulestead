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

  @governance_actions [
    :publish_ruleset,
    :advance_rollout,
    :engage_kill_switch,
    :release_kill_switch,
    :promote_environment
  ]

  @spec governance_actions() :: [governance_action()]
  def governance_actions, do: @governance_actions

  @callback can?(
              actor :: term(),
              action :: atom(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
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

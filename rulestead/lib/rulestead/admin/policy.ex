defmodule Rulestead.Admin.Policy do
  @moduledoc """
  Host-owned authorization seam for mounted admin actions.

  `rulestead_admin` calls `can?/4` with explicit actor, action, resource,
  and environment scope rather than inferring authorization from roles.
  """

  @callback can?(
              actor :: term(),
              action :: atom(),
              resource :: term(),
              environment_key :: String.t() | atom() | nil
            ) :: boolean()
end

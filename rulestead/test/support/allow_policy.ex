defmodule Rulestead.AllowPolicy do
  @moduledoc false
  @behaviour Rulestead.Admin.Policy
  def can?(_actor, _action, _resource, _env), do: true
  def change_request_required?(_actor, _action, _resource, _env), do: false
  def allow_self_approval?(_actor, _action, _resource, _env), do: true
end

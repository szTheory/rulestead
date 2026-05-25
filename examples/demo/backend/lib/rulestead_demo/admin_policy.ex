defmodule RulesteadDemo.AdminPolicy do
  @moduledoc false

  @behaviour Rulestead.Admin.Policy

  alias Rulestead.Admin.Policy

  @viewer_actions Policy.viewer_actions() ++ [:access_admin]
  @editor_actions Policy.editor_actions()
  @admin_actions Policy.governance_actions() ++ Policy.admin_actions()

  @impl true
  def can?(actor, action, _resource, environment_key) do
    roles = actor_roles(actor)

    cond do
      "admin" in roles ->
        true

      action in @admin_actions ->
        false

      action in @editor_actions ->
        "editor" in roles and non_production?(environment_key)

      action in @viewer_actions ->
        Enum.any?(roles, &(&1 in ["viewer", "editor"]))

      true ->
        false
    end
  end

  @impl true
  def change_request_required?(actor, action, _resource, environment_key) do
    "admin" not in actor_roles(actor) and action in Policy.governance_actions() and production?(environment_key)
  end

  @impl true
  def allow_self_approval?(actor, _action, _resource, _environment_key) do
    "admin" in actor_roles(actor)
  end

  defp actor_roles(actor) when is_map(actor) do
    actor
    |> Map.get(:roles, Map.get(actor, "roles", []))
    |> List.wrap()
    |> Enum.map(&to_string/1)
  end

  defp actor_roles(_actor), do: []

  defp production?(environment_key), do: to_string(environment_key) in ["prod", "production"]
  defp non_production?(environment_key), do: not production?(environment_key)
end

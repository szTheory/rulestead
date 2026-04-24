defmodule Rulestead.Admin.Authorizer do
  @moduledoc """
  Central policy gate for Phase 7 admin reads and writes.
  """

  alias Rulestead.AuthError

  @viewer_roles ~w(viewer auditor operator engineer admin incident_commander prod_operator)a
  @editor_roles ~w(operator engineer admin incident_commander prod_operator)a
  @production_roles ~w(admin incident_commander prod_operator)a

  @type audit_payload :: %{
          required(:action) => atom(),
          required(:result) => :allowed | :denied,
          required(:environment_key) => String.t() | nil,
          required(:resource) => map(),
          required(:actor) => map()
        }

  @spec authorize(term(), atom(), term(), String.t() | atom() | nil) ::
          :ok | {:error, Rulestead.Error.t(), audit_payload()}
  def authorize(actor, action, resource, environment_key) do
    normalized_environment = normalize_environment(environment_key)
    normalized_actor = normalize_actor(actor)
    normalized_resource = normalize_resource(resource)

    if allowed?(normalized_actor, action, normalized_resource, normalized_environment) do
      :ok
    else
      metadata =
        %{
          action: Atom.to_string(action),
          environment_key: normalized_environment
        }
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)
        |> Map.new()

      {:error, AuthError.unauthorized(metadata: metadata),
       %{
         action: action,
         result: :denied,
         environment_key: normalized_environment,
         resource: normalized_resource,
         actor: normalized_actor
       }}
    end
  end

  defp allowed?(actor, action, resource, environment_key) do
    case policy_module() do
      nil -> fallback_allow?(actor, action, environment_key)
      policy -> policy.can?(actor, action, resource, environment_key) || fallback_allow?(actor, action, environment_key)
    end
  rescue
    _error -> false
  end

  defp fallback_allow?(actor, action, environment_key) do
    roles = actor.roles

    cond do
      action in [:list_audit_events, :simulate_flag, :explain_flag] ->
        Enum.any?(roles, &(&1 in @viewer_roles))

      production_environment?(environment_key) ->
        Enum.any?(roles, &(&1 in @production_roles))

      true ->
        Enum.any?(roles, &(&1 in @editor_roles))
    end
  end

  defp policy_module do
    Application.get_env(:rulestead, :admin_policy)
  end

  defp production_environment?(environment_key), do: environment_key in ["prod", "production"]

  defp normalize_environment(nil), do: nil
  defp normalize_environment(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_environment(value) when is_binary(value), do: String.trim(value)
  defp normalize_environment(_value), do: nil

  defp normalize_actor(actor) when is_map(actor) do
    id = actor[:id] || actor["id"]
    display = actor[:display] || actor["display"] || actor[:name] || actor["name"]

    roles =
      actor[:roles] || actor["roles"] || [actor[:role] || actor["role"]]

    %{
      id: stringify(id),
      display: stringify(display),
      roles: roles |> List.wrap() |> Enum.map(&normalize_role/1) |> Enum.reject(&is_nil/1)
    }
  end

  defp normalize_actor(_actor), do: %{id: nil, display: nil, roles: []}

  defp normalize_resource(resource) when is_map(resource) do
    %{
      resource_type: normalize_role(resource[:resource_type] || resource["resource_type"]),
      resource_key: stringify(resource[:resource_key] || resource["resource_key"] || resource[:flag_key] || resource["flag_key"])
    }
  end

  defp normalize_resource(_resource), do: %{resource_type: nil, resource_key: nil}

  defp normalize_role(nil), do: nil
  defp normalize_role(value) when is_atom(value), do: value
  defp normalize_role(value) when is_binary(value), do: value |> String.trim() |> String.to_atom()
  defp normalize_role(_value), do: nil

  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: String.trim(value)
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify(_value), do: nil
end

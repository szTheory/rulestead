defmodule Rulestead.Admin.Authorizer do
  @moduledoc """
  Central policy gate for Phase 7 admin reads and writes.
  """

  alias Rulestead.{AuthError, Governance.ApprovalRequirement}

  @viewer_roles ~w(viewer auditor operator engineer admin incident_commander prod_operator)a
  @editor_roles ~w(operator engineer admin incident_commander prod_operator)a
  @production_roles ~w(admin incident_commander prod_operator)a
  @governed_actions [:publish_ruleset, :advance_rollout, :engage_kill_switch, :release_kill_switch]

  @type audit_payload :: %{
          required(:action) => atom(),
          required(:result) => :allowed | :denied,
          required(:environment_key) => String.t() | nil,
          required(:resource) => map(),
          required(:actor) => map(),
          optional(:reason) => atom(),
          optional(:approval_requirement) => ApprovalRequirement.t()
        }

  @spec authorize(term(), atom(), term(), String.t() | atom() | nil) ::
          :ok | {:error, Rulestead.Error.t(), audit_payload()}
  def authorize(actor, action, resource, environment_key) do
    normalized_environment = normalize_environment(environment_key)
    normalized_actor = normalize_actor(actor)
    normalized_resource = normalize_resource(resource)

    case authorize_normalized(
           normalized_actor,
           action,
           normalized_resource,
           normalized_environment
         ) do
      :ok -> :ok
      {:error, error, audit_payload} -> {:error, error, audit_payload}
    end
  end

  @spec authorize_governed_action(term(), atom(), term(), String.t() | atom() | nil) ::
          {:ok, ApprovalRequirement.t()} | {:error, Rulestead.Error.t(), audit_payload()}
  def authorize_governed_action(actor, action, resource, environment_key) do
    normalized_environment = normalize_environment(environment_key)
    normalized_actor = normalize_actor(actor)
    normalized_resource = normalize_resource(resource)

    with :ok <-
           authorize_normalized(
             normalized_actor,
             action,
             normalized_resource,
             normalized_environment
           ),
         %ApprovalRequirement{} = requirement <-
           resolve_approval_requirement(
             normalized_actor,
             action,
             normalized_resource,
             normalized_environment
           ),
         false <- requirement.change_request_required? do
      {:ok, requirement}
    else
      {:error, error, audit_payload} ->
        {:error, error, audit_payload}

      true ->
        requirement =
          resolve_approval_requirement(
            normalized_actor,
            action,
            normalized_resource,
            normalized_environment
          )

        deny(
          :change_request_required,
          normalized_actor,
          action,
          normalized_resource,
          normalized_environment,
          approval_requirement: requirement
        )
    end
  end

  @spec approval_requirement(term(), atom(), term(), String.t() | atom() | nil) ::
          ApprovalRequirement.t()
  def approval_requirement(actor, action, resource, environment_key) do
    resolve_approval_requirement(
      normalize_actor(actor),
      action,
      normalize_resource(resource),
      normalize_environment(environment_key)
    )
  end

  @spec authorize_change_request_approval(
          term(),
          term(),
          atom(),
          term(),
          String.t() | atom() | nil
        ) :: {:ok, ApprovalRequirement.t()} | {:error, Rulestead.Error.t(), audit_payload()}
  def authorize_change_request_approval(actor, submitter, action, resource, environment_key) do
    normalized_environment = normalize_environment(environment_key)
    normalized_actor = normalize_actor(actor)
    normalized_submitter = normalize_actor(submitter)
    normalized_resource = normalize_resource(resource)

    requirement =
      resolve_approval_requirement(
        normalized_actor,
        action,
        normalized_resource,
        normalized_environment
      )

    with :ok <-
           authorize_normalized(
             normalized_actor,
             :approve_change_request,
             normalized_resource,
             normalized_environment
           ),
         :ok <- ensure_self_approval_allowed(normalized_actor, normalized_submitter, requirement) do
      {:ok, requirement}
    else
      {:error, error, audit_payload} ->
        {:error, error, audit_payload}

      :self_approval_forbidden ->
        deny(
          :self_approval_forbidden,
          normalized_actor,
          :approve_change_request,
          normalized_resource,
          normalized_environment,
          approval_requirement: requirement
        )
    end
  end

  defp allowed?(actor, action, resource, environment_key) do
    case policy_module() do
      nil -> fallback_allow?(actor, action, environment_key)
      policy -> policy.can?(actor, action, resource, environment_key)
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

  defp authorize_normalized(actor, action, resource, environment_key) do
    if allowed?(actor, action, resource, environment_key) do
      :ok
    else
      deny(:unauthorized, actor, action, resource, environment_key)
    end
  end

  defp resolve_approval_requirement(actor, action, resource, environment_key) do
    change_request_required? =
      policy_flag(
        :change_request_required?,
        actor,
        action,
        resource,
        environment_key,
        default_change_request_required?(action, environment_key)
      )

    self_approval_allowed? =
      policy_flag(
        :allow_self_approval?,
        actor,
        action,
        resource,
        environment_key,
        default_self_approval_allowed?(environment_key)
      )

    ApprovalRequirement.new(
      action: action,
      environment_key: environment_key,
      required_approvals: if(change_request_required?, do: 1, else: 0),
      change_request_required?: change_request_required?,
      self_approval_allowed?: self_approval_allowed?
    )
  end

  defp ensure_self_approval_allowed(actor, submitter, %ApprovalRequirement{} = requirement) do
    if requirement.self_approval_allowed? or actor.id != submitter.id do
      :ok
    else
      :self_approval_forbidden
    end
  end

  defp policy_flag(callback, actor, action, resource, environment_key, default) do
    case policy_module() do
      nil ->
        default

      policy ->
        if function_exported?(policy, callback, 4) do
          case apply(policy, callback, [actor, action, resource, environment_key]) do
            value when is_boolean(value) -> value
            _other -> default
          end
        else
          default
        end
    end
  rescue
    _error -> default
  end

  defp default_change_request_required?(action, environment_key) do
    production_environment?(environment_key) and action in @governed_actions
  end

  defp default_self_approval_allowed?(environment_key) do
    not production_environment?(environment_key)
  end

  defp deny(reason, actor, action, resource, environment_key, opts \\ []) do
    metadata =
      %{
        action: Atom.to_string(action),
        environment_key: environment_key,
        reason: normalize_reason(reason)
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    audit_payload =
      %{
        action: action,
        result: :denied,
        environment_key: environment_key,
        resource: resource,
        actor: actor
      }
      |> maybe_put(:reason, audit_reason(reason))
      |> maybe_put(:approval_requirement, Keyword.get(opts, :approval_requirement))

    {:error, AuthError.unauthorized(metadata: metadata), audit_payload}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp normalize_reason(:unauthorized), do: nil
  defp normalize_reason(reason) when is_atom(reason), do: Atom.to_string(reason)

  defp audit_reason(:unauthorized), do: nil
  defp audit_reason(reason) when is_atom(reason), do: reason

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
      resource_type:
        normalize_resource_type(resource[:resource_type] || resource["resource_type"]),
      resource_key:
        stringify(
          resource[:resource_key] || resource["resource_key"] || resource[:flag_key] ||
            resource["flag_key"]
        )
    }
  end

  defp normalize_resource(_resource), do: %{resource_type: nil, resource_key: nil}

  defp normalize_role(nil), do: nil
  defp normalize_role(value) when is_atom(value), do: value

  defp normalize_role(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      "viewer" -> :viewer
      "auditor" -> :auditor
      "operator" -> :operator
      "engineer" -> :engineer
      "admin" -> :admin
      "incident_commander" -> :incident_commander
      "prod_operator" -> :prod_operator
      _ -> nil
    end
  end

  defp normalize_role(_value), do: nil

  defp normalize_resource_type(nil), do: nil
  defp normalize_resource_type(value) when is_atom(value), do: value

  defp normalize_resource_type(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      "flag" -> :flag
      "audit_event" -> :audit_event
      "ruleset" -> :ruleset
      _ -> nil
    end
  end

  defp normalize_resource_type(_value), do: nil

  defp stringify(nil), do: nil
  defp stringify(value) when is_binary(value), do: String.trim(value)
  defp stringify(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify(value) when is_integer(value), do: Integer.to_string(value)
  defp stringify(_value), do: nil
end

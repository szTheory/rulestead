# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.Session do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_patch: 2]

  alias Phoenix.LiveView.Socket

  @type environment :: %{key: String.t(), name: String.t()}
  @type tenant :: %{key: String.t(), name: String.t()}
  @type resolved :: %{
          actor: term(),
          environment: environment(),
          environments: [environment()],
          env_source: :url | :remembered | :default,
          tenant: tenant() | nil,
          tenants: [tenant()],
          tenant_source: :url | :remembered | :default | nil,
          mount_path: String.t(),
          policy: module()
        }

  def on_mount(:default, params, session, socket) do
    resolved =
      resolve(params, session, policy: session["policy"], mount_path: session["mount_path"])

    if allowed?(resolved) do
      socket =
        socket
        |> assign(:current_actor, resolved.actor)
        |> assign(:current_environment, resolved.environment)
        |> assign(:available_environments, resolved.environments)
        |> assign(:current_tenant, resolved.tenant)
        |> assign(:available_tenants, resolved.tenants)
        |> assign(:rulestead_admin_policy, resolved.policy)
        |> assign(:rulestead_admin_mount_path, resolved.mount_path)
        |> assign(:rulestead_admin_env_source, resolved.env_source)
        |> assign(:rulestead_admin_tenant_source, resolved.tenant_source)
        |> assign(:rulestead_admin_policy_state, policy_state(resolved))
        |> assign(:rulestead_admin_session, resolved)

      {:cont, socket}
    else
      {:halt, push_patch(socket, to: resolved.mount_path)}
    end
  end

  @spec resolve(map(), map(), keyword()) :: resolved()
  def resolve(params, session, opts) when is_map(params) and is_map(session) and is_list(opts) do
    policy = Keyword.fetch!(opts, :policy)
    mount_path = Keyword.fetch!(opts, :mount_path)
    actor = Map.get(session, "current_actor")
    environments = normalize_environments(Map.get(session, "rulestead_admin_environments"))
    remembered_env = Map.get(session, "rulestead_admin_last_env")
    url_env = blank_to_nil(Map.get(params, "env"))
    tenants = normalize_tenants(Map.get(session, "rulestead_admin_tenants"))
    remembered_tenant = blank_to_nil(Map.get(session, "rulestead_admin_last_tenant"))
    default_tenant = blank_to_nil(Map.get(session, "rulestead_admin_default_tenant"))
    url_tenant = blank_to_nil(Map.get(params, "tenant"))

    {environment, env_source} =
      cond do
        selected = find_environment(environments, url_env) ->
          {selected, :url}

        present?(url_env) ->
          {default_environment(environments), :default}

        selected = find_environment(environments, remembered_env) ->
          {selected, :remembered}

        true ->
          {default_environment(environments), :default}
      end

    {tenant, tenant_source} =
      cond do
        selected = find_tenant(tenants, url_tenant) ->
          {selected, :url}

        selected = find_tenant(tenants, remembered_tenant) ->
          {selected, :remembered}

        selected = find_tenant(tenants, default_tenant) ->
          {selected, :default}

        true ->
          {default_tenant(tenants), default_source(tenants)}
      end

    %{
      actor: actor,
      environment: environment,
      environments: environments,
      env_source: env_source,
      tenant: tenant,
      tenants: tenants,
      tenant_source: tenant_source,
      mount_path: mount_path,
      policy: policy
    }
  end

  @spec current_path(Socket.t() | map(), String.t(), map()) :: String.t()
  def current_path(socket_or_assigns, base_path, params \\ %{})
      when is_binary(base_path) and is_map(params) do
    env_key =
      socket_or_assigns
      |> fetch_assign(:current_environment, %{})
      |> Map.get(:key, "dev")

    tenant_key =
      socket_or_assigns
      |> fetch_assign(:current_tenant, %{})
      |> Kernel.||(%{})
      |> Map.get(:key)

    params
    |> Map.put("env", env_key)
    |> maybe_put_scope_param("tenant", tenant_key)
    |> encode_params()
    |> then(&"#{base_path}?#{&1}")
  end

  @spec env_links(Socket.t() | map(), String.t(), map()) :: %{required(String.t()) => String.t()}
  def env_links(socket_or_assigns, base_path, params \\ %{})
      when is_binary(base_path) and is_map(params) do
    socket_or_assigns
    |> fetch_assign(:available_environments, [])
    |> Enum.into(%{}, fn env ->
      {
        env.key,
        current_path(
          %{
            current_environment: env,
            current_tenant: fetch_assign(socket_or_assigns, :current_tenant)
          },
          base_path,
          params
        )
      }
    end)
  end

  @spec canonical_return_to(Socket.t() | map(), String.t() | nil, String.t(), map()) :: String.t()
  def canonical_return_to(socket_or_assigns, return_to, fallback_base_path, fallback_params \\ %{})
      when is_binary(fallback_base_path) and is_map(fallback_params) do
    fallback = current_path(socket_or_assigns, fallback_base_path, fallback_params)

    case normalize_mounted_path(socket_or_assigns, return_to) do
      nil -> fallback
      {base_path, params} -> current_path(socket_or_assigns, base_path, params)
    end
  end

  @spec path_with_return_to(Socket.t() | map(), String.t(), String.t()) :: String.t()
  def path_with_return_to(socket_or_assigns, base_path, return_to)
      when is_binary(base_path) and is_binary(return_to) do
    current_path(socket_or_assigns, base_path, %{"return_to" => return_to})
  end

  @spec tenant_links(Socket.t() | map(), String.t(), map()) :: %{
          required(String.t()) => String.t()
        }
  def tenant_links(socket_or_assigns, base_path, params \\ %{})
      when is_binary(base_path) and is_map(params) do
    socket_or_assigns
    |> fetch_assign(:available_tenants, [])
    |> Enum.into(%{}, fn tenant ->
      {
        tenant.key,
        current_path(
          %{
            current_environment: fetch_assign(socket_or_assigns, :current_environment),
            current_tenant: tenant
          },
          base_path,
          params
        )
      }
    end)
  end

  @spec policy_state(Socket.t() | map() | resolved()) :: map()
  def policy_state(%{environment: environment, actor: actor}) when is_map(environment) do
    tone = if production_env?(environment), do: "critical", else: "warning"
    label = if production_env?(environment), do: "Production policy", else: "Environment policy"

    alias Rulestead.Admin.Authorizer

    can_read? = Authorizer.authorize(actor, :read_flags, nil, environment.key) == :ok
    can_edit? = Authorizer.authorize(actor, :create_flag, nil, environment.key) == :ok
    can_execute? = Authorizer.authorize(actor, :publish_ruleset, nil, environment.key) == :ok

    # We resolve the requirement for execution to see if it's proposal-only
    requirement = Authorizer.approval_requirement(actor, :publish_ruleset, nil, environment.key)
    proposal_only? = requirement.change_request_required?

    can_admin? = Authorizer.authorize(actor, :manage_settings, nil, environment.key) == :ok

    capabilities = %{
      read?: can_read?,
      edit?: can_edit?,
      execute?: can_execute?,
      propose?: proposal_only?,
      admin?: can_admin?
    }

    %{
      environment_key: environment.key,
      production?: production_env?(environment),
      tone: tone,
      label: label,
      summary: policy_summary(environment),
      capabilities: capabilities
    }
  end

  def policy_state(socket_or_assigns) do
    environment = fetch_assign(socket_or_assigns, :current_environment)
    actor = fetch_assign(socket_or_assigns, :current_actor, %{id: nil, roles: []})

    policy_state(%{environment: environment, actor: actor})
  end

  @spec placeholder_assigns(Socket.t() | map(), keyword()) :: map()
  def placeholder_assigns(socket_or_assigns, opts) do
    current_path = Keyword.fetch!(opts, :current_path)
    page_title = Keyword.fetch!(opts, :page_title)
    page_kicker = Keyword.fetch!(opts, :page_kicker)
    page_summary = Keyword.fetch!(opts, :page_summary)

    %{
      page_title: page_title,
      page_kicker: page_kicker,
      page_summary: page_summary,
      current_environment: fetch_assign(socket_or_assigns, :current_environment),
      environments: fetch_assign(socket_or_assigns, :available_environments, []),
      current_tenant: fetch_assign(socket_or_assigns, :current_tenant),
      tenants: fetch_assign(socket_or_assigns, :available_tenants, []),
      current_path: current_path(socket_or_assigns, current_path),
      env_links: env_links(socket_or_assigns, current_path),
      tenant_links: tenant_links(socket_or_assigns, current_path),
      policy_state: policy_state(socket_or_assigns)
    }
  end

  defp allowed?(%{policy: policy, actor: actor, environment: environment} = resolved) do
    tenant_scope_available?(resolved) and
      policy.can?(actor, :access_admin, :flags, environment.key)
  end

  defp normalize_environments(nil) do
    [
      %{key: "dev", name: "Development"},
      %{key: "staging", name: "Staging"},
      %{key: "prod", name: "Production"}
    ]
  end

  defp normalize_environments(environments) when is_list(environments) do
    Enum.map(environments, fn env ->
      key = env |> fetch_value("key") |> to_string()
      name = env |> fetch_value("name") |> to_string()
      %{key: key, name: name}
    end)
  end

  defp normalize_tenants(nil), do: []

  defp normalize_tenants(tenants) when is_list(tenants) do
    Enum.map(tenants, fn
      tenant when is_binary(tenant) ->
        %{key: tenant, name: tenant}

      tenant ->
        key = tenant |> fetch_value("key") |> to_string()
        name = tenant |> fetch_value("name") |> blank_to_nil() || key
        %{key: key, name: name}
    end)
  end

  defp find_environment(_environments, nil), do: nil

  defp find_environment(environments, env_key) do
    target = to_string(env_key)
    Enum.find(environments, &(&1.key == target))
  end

  defp find_tenant(_tenants, nil), do: nil

  defp find_tenant(tenants, tenant_key) do
    target = to_string(tenant_key)
    Enum.find(tenants, &(&1.key == target))
  end

  defp default_environment([environment | _rest]), do: environment
  defp default_environment([]), do: %{key: "dev", name: "Development"}
  defp default_tenant([tenant | _rest]), do: tenant
  defp default_tenant([]), do: nil
  defp default_source([]), do: nil
  defp default_source(_tenants), do: :default

  defp tenant_scope_available?(%{tenant: nil, tenants: []}), do: true
  defp tenant_scope_available?(%{tenant: tenant}) when is_map(tenant), do: true
  defp tenant_scope_available?(_resolved), do: false

  defp production_env?(%{key: key}) when key in ["prod", "production"], do: true
  defp production_env?(_environment), do: false

  defp policy_summary(environment) do
    if production_env?(environment) do
      "Production actions should stay explicit and auditable."
    else
      "Confirm environment scope before saving or publishing changes."
    end
  end

  defp fetch_assign(socket_or_assigns, key, default \\ nil)
  defp fetch_assign(%Socket{} = socket, key, default), do: Map.get(socket.assigns, key, default)

  defp fetch_assign(assigns, key, default) when is_map(assigns),
    do: Map.get(assigns, key, default)

  defp normalize_mounted_path(_socket_or_assigns, nil), do: nil
  defp normalize_mounted_path(_socket_or_assigns, ""), do: nil

  defp normalize_mounted_path(socket_or_assigns, path) when is_binary(path) do
    parsed = URI.parse(path)
    mount_path = fetch_assign(socket_or_assigns, :rulestead_admin_mount_path, "")

    cond do
      parsed.scheme not in [nil, ""] ->
        nil

      parsed.host not in [nil, ""] ->
        nil

      not mounted_path?(parsed.path, mount_path) ->
        nil

      true ->
        {parsed.path || mount_path, decode_query(parsed.query)}
    end
  end

  defp fetch_value(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, String.to_atom(key))

  defp mounted_path?(nil, _mount_path), do: false
  defp mounted_path?(path, mount_path) when path == mount_path, do: true
  defp mounted_path?(path, mount_path), do: String.starts_with?(path, mount_path <> "/")

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp present?(value), do: not is_nil(blank_to_nil(value))

  defp maybe_put_scope_param(params, _key, nil), do: params
  defp maybe_put_scope_param(params, key, value), do: Map.put(params, key, value)

  defp encode_params(params) do
    params
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> URI.encode_query()
  end

  defp decode_query(nil), do: %{}
  defp decode_query(query), do: URI.decode_query(query)
end

defmodule RulesteadAdmin.Live.Session do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [push_patch: 2]

  alias Phoenix.LiveView.Socket

  @type environment :: %{key: String.t(), name: String.t()}
  @type resolved :: %{
          actor: term(),
          environment: environment(),
          environments: [environment()],
          env_source: :url | :remembered | :default,
          mount_path: String.t(),
          policy: module()
        }

  def on_mount(:default, params, session, socket) do
    resolved = resolve(params, session, policy: session["policy"], mount_path: session["mount_path"])

    if allowed?(resolved) do
      socket =
        socket
        |> assign(:current_actor, resolved.actor)
        |> assign(:current_environment, resolved.environment)
        |> assign(:available_environments, resolved.environments)
        |> assign(:rulestead_admin_policy, resolved.policy)
        |> assign(:rulestead_admin_mount_path, resolved.mount_path)
        |> assign(:rulestead_admin_env_source, resolved.env_source)
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

    %{
      actor: actor,
      environment: environment,
      environments: environments,
      env_source: env_source,
      mount_path: mount_path,
      policy: policy
    }
  end

  @spec env_links(Socket.t() | map(), String.t()) :: %{required(String.t()) => String.t()}
  def env_links(socket_or_assigns, current_path) when is_binary(current_path) do
    socket_or_assigns
    |> fetch_assign(:available_environments, [])
    |> Enum.into(%{}, fn env ->
      {env.key, current_path <> "?env=" <> env.key}
    end)
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
      env_links: env_links(socket_or_assigns, current_path)
    }
  end

  defp allowed?(%{policy: policy, actor: actor, environment: environment}) do
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

  defp find_environment(_environments, nil), do: nil

  defp find_environment(environments, env_key) do
    target = to_string(env_key)
    Enum.find(environments, &(&1.key == target))
  end

  defp default_environment([environment | _rest]), do: environment
  defp default_environment([]), do: %{key: "dev", name: "Development"}

  defp fetch_assign(socket_or_assigns, key, default \\ nil)
  defp fetch_assign(%Socket{} = socket, key, default), do: Map.get(socket.assigns, key, default)
  defp fetch_assign(assigns, key, default) when is_map(assigns), do: Map.get(assigns, key, default)

  defp fetch_value(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, String.to_atom(key))

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp present?(value), do: not is_nil(blank_to_nil(value))
end

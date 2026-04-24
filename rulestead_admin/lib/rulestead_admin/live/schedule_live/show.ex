defmodule RulesteadAdmin.Live.ScheduleLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page, nil) |> assign(:scheduled_execution_id, nil)}
  end

  @impl true
  def handle_params(%{"scheduled_execution_id" => id} = params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    base_path = "#{index_path()}/#{id}"
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path))}
    else
      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path,
          page_title: "Scheduled execution",
          page_kicker: "Scheduled changes",
          page_summary:
            "Execution detail route for state, actor chain, related change request, and explicit follow-up actions."
        )
        |> Map.merge(%{
          navigation_links: navigation_links(socket, :schedule),
          schedule_path: Session.current_path(socket, index_path()),
          change_requests_path: Session.current_path(socket, change_requests_path()),
          audit_path: Session.current_path(socket, audit_path()),
          scheduled_execution_id: id
        })

      {:noreply,
       socket
       |> assign(:scheduled_execution_id, id)
       |> assign(:page, page)}
    end
  end

  @impl true
  def render(%{page: page} = assigns) when is_map(page) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <Shell.page
      page_title={@page.page_title}
      page_kicker={@page.page_kicker}
      page_summary={@page.page_summary}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
      navigation_links={@page.navigation_links}
    >
      <section>
        <h2>Scheduled execution <code><%= @page.scheduled_execution_id %></code></h2>
        <p>Execution detail remains route-backed so retries, quarantine context, and audit links stay explicit.</p>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.schedule_path}>Back to schedule</a></li>
          <li><a href={@page.change_requests_path}>Open change requests</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp index_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

  defp navigation_links(socket, current) do
    [
      nav_link("Flags", Session.current_path(socket, mount_path(socket)), current == :flags),
      nav_link(
        "Change requests",
        Session.current_path(socket, change_requests_path()),
        current == :change_requests
      ),
      nav_link("Schedule", Session.current_path(socket, index_path()), current == :schedule),
      nav_link("Audit", Session.current_path(socket, audit_path()), current == :audit)
    ]
  end

  defp nav_link(label, path, current?), do: %{label: label, path: path, current?: current?}

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp apply_resolved(socket, params) do
    resolved =
      Session.resolve(
        params,
        %{
          "current_actor" => socket.assigns.current_actor,
          "rulestead_admin_environments" => socket.assigns.available_environments,
          "rulestead_admin_last_env" => socket.assigns.current_environment.key
        },
        policy: socket.assigns.rulestead_admin_policy,
        mount_path: socket.assigns.rulestead_admin_mount_path
      )

    socket
    |> assign(:current_environment, resolved.environment)
    |> assign(:available_environments, resolved.environments)
    |> assign(:rulestead_admin_env_source, resolved.env_source)
    |> assign(:rulestead_admin_policy_state, Session.policy_state(resolved))
    |> assign(:rulestead_admin_session, resolved)
  end

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end
end

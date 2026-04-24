defmodule RulesteadAdmin.Live.ScheduleLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page, nil)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path()))}
    else
      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(),
          page_title: "Schedule",
          page_kicker: "Scheduled changes",
          page_summary: "Dense route-backed list home for upcoming, running, completed, failed, quarantined, and cancelled executions."
        )
        |> Map.merge(%{
          sample_schedule_path: Session.current_path(socket, "#{base_path()}/sched-456"),
          change_requests_path: Session.current_path(socket, change_requests_path()),
          audit_path: Session.current_path(socket, audit_path()),
          flags_path: Session.current_path(socket, mount_path(socket))
        })

      {:noreply, assign(socket, :page, page)}
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
    >
      <section>
        <h2>List-first operator console</h2>
        <p>Scheduled execution visibility stays list-first so operators can scan state without a calendar workbench.</p>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.sample_schedule_path}>Open example scheduled execution</a></li>
          <li><a href={@page.change_requests_path}>Open change requests</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li><a href={@page.flags_path}>Back to flag inventory</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

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

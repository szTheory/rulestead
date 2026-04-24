defmodule RulesteadAdmin.Live.ChangeRequestLive.Index do
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
          page_title: "Change requests",
          page_kicker: "Governance",
          page_summary: "Route-backed review queue for governed mutations, approvals, and explicit execution follow-through."
        )
        |> Map.merge(%{
          sample_request_path: Session.current_path(socket, "#{base_path()}/req-123"),
          schedule_path: Session.current_path(socket, schedule_base_path()),
          audit_path: Session.current_path(socket, audit_base_path()),
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
        <h2>Route-backed review queue</h2>
        <p>This queue stays route-backed so review and execution work can grow without crowding flag detail.</p>
      </section>

      <section>
        <h2>Next routes</h2>
        <ul>
          <li><a href={@page.sample_request_path}>Open example change request review</a></li>
          <li><a href={@page.schedule_path}>Open schedule</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li><a href={@page.flags_path}>Back to flag inventory</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/change-requests"
  defp schedule_base_path, do: "/admin/flags/schedule"
  defp audit_base_path, do: "/admin/flags/audit"

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

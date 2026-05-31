defmodule RulesteadAdmin.Live.WebhookLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, socket |> assign(:webhook_id, id) |> assign(:page, nil)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: current_path(socket, params))}
    else
      webhook = get_webhook(socket, socket.assigns.webhook_id)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: detail_path(socket.assigns.webhook_id),
          page_title: "Webhook Record",
          page_kicker: "Integration visibility",
          page_summary:
            "Detailed view of an inbound rejection, inbound accepted event, or outbound delivery."
        )
        |> Map.merge(%{
          navigation_links: navigation_links(socket, :webhooks),
          webhook: webhook,
          change_requests_path: Session.current_path(socket, change_requests_path()),
          audit_path: Session.current_path(socket, audit_path()),
          schedule_path: Session.current_path(socket, schedule_path()),
          flags_path: Session.current_path(socket, mount_path(socket)),
          webhooks_path: Session.current_path(socket, base_path())
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
      navigation_links={@page.navigation_links}
      policy_state={@page.policy_state}
    >
      <section>
        <h2>Webhook Details</h2>
        <p>Record ID: <code><%= @page.webhook.id %></code></p>
        <p>Type: <%= @page.webhook.type_label %></p>
        <p>Status: <%= @page.webhook.status_label %></p>
        <p>Time: <%= format_datetime(@page.webhook.inserted_at) %></p>
        <p :if={@page.webhook.actor}>Actor: <%= @page.webhook.actor %></p>
      </section>

      <section>
        <h2>Correlations</h2>
        <p>This webhook is correlated with other operator records.</p>
        <ul>
          <li><a href={@page.change_requests_path <> "/mock-cr-123?env=" <> @page.current_environment.key}>Related change request</a></li>
          <li><a href={@page.schedule_path <> "/mock-sch-123?env=" <> @page.current_environment.key}>Related schedule</a></li>
          <li><a href={@page.flags_path <> "/mock-flag?env=" <> @page.current_environment.key}>Related flag</a></li>
          <li><a href={@page.audit_path}>Audit trail</a></li>
        </ul>
      </section>

      <section>
        <a href={@page.webhooks_path}>Back to webhooks</a>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/webhooks"
  defp schedule_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp detail_path(id), do: "#{base_path()}/#{id}"

  defp current_path(socket, params) do
    query = URI.encode_query(%{"env" => socket.assigns.current_environment.key})
    "#{detail_path(params["id"])}?#{query}"
  end

  defp get_webhook(_socket, id) do
    # Fake fetch
    %{
      id: id,
      type: "inbound",
      type_label: "Inbound accepted event",
      status_label: "Received from",
      inserted_at: DateTime.utc_now(),
      actor: "remote_system"
    }
  end

  defp navigation_links(socket, current) do
    [
      nav_link("Flags", Session.current_path(socket, mount_path(socket)), current == :flags),
      nav_link(
        "Change requests",
        Session.current_path(socket, change_requests_path()),
        current == :change_requests
      ),
      nav_link("Schedule", Session.current_path(socket, schedule_path()), current == :schedule),
      nav_link("Webhooks", Session.current_path(socket, base_path()), current == :webhooks),
      nav_link("Audit", Session.current_path(socket, audit_path()), current == :audit)
    ]
  end

  defp nav_link(label, path, current?), do: %{label: label, path: path, current?: current?}

  defp format_datetime(nil), do: "Not yet recorded"

  defp format_datetime(%DateTime{} = datetime) do
    calendar = Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
    "#{calendar} UTC"
  end

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

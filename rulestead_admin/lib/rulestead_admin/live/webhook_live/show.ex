defmodule RulesteadAdmin.Live.WebhookLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{OperatorComponents, Shell}
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
          page_title: "Webhook record",
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
      current_tenant={@page.current_tenant}
      tenants={@page.tenants}
      tenant_links={@page.tenant_links}
      navigation_links={@page.navigation_links}
      policy_state={@page.policy_state}
    >
      <OperatorComponents.empty_state
        title="Webhook record detail not available"
        body="This webhook record is a routing placeholder. Real inbound and outbound delivery details will appear here once webhook integrations are active."
        variant="hero"
      >
        <:actions>
          <OperatorComponents.related_links links={related_links(@page)} />
        </:actions>
      </OperatorComponents.empty_state>
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
    %{
      id: id,
      type: "inbound",
      type_label: "Inbound accepted event",
      status_label: "Received from",
      inserted_at: DateTime.utc_now(),
      actor: "remote_system"
    }
  end

  defp webhook_rows(webhook) do
    [
      %{label: "Record ID", value: webhook.id},
      %{label: "Type", value: webhook.type_label},
      %{label: "Status", value: webhook.status_label},
      %{label: "Time", value: format_datetime(webhook.inserted_at)},
      %{label: "Actor", value: webhook.actor || "Not recorded"}
    ]
  end

  defp related_links(page) do
    [
      %{label: "Back to webhooks", path: page.webhooks_path},
      %{label: "Open change requests", path: page.change_requests_path},
      %{label: "Open schedule", path: page.schedule_path},
      %{label: "Open audit timeline", path: page.audit_path},
      %{label: "Back to flag inventory", path: page.flags_path}
    ]
  end

  defp navigation_links(socket, current) do
    mp = mount_path(socket)
    sep = %{separator: true, path: "", label: "", current?: false}

    [
      nav_link("Flags", Session.current_path(socket, mp), current == :flags),
      nav_link(
        "Audiences",
        Session.current_path(socket, "#{mp}/audiences"),
        current == :audiences
      ),
      nav_link(
        "Experiments",
        Session.current_path(socket, "#{mp}/experiments"),
        current == :experiments
      ),
      nav_link("Compare", Session.current_path(socket, "#{mp}/compare"), current == :compare),
      sep,
      nav_link(
        "Change requests",
        Session.current_path(socket, change_requests_path()),
        current == :change_requests
      ),
      nav_link("Schedule", Session.current_path(socket, schedule_path()), current == :schedule),
      nav_link("Audit", Session.current_path(socket, audit_path()), current == :audit),
      nav_link("Webhooks", Session.current_path(socket, base_path()), current == :webhooks),
      sep,
      nav_link(
        "Diagnostics",
        Session.current_path(socket, "#{mp}/diagnostics"),
        current == :diagnostics
      )
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

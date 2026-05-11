defmodule RulesteadAdmin.Live.WebhookLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @default_limit 100

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page, nil) |> assign(:filters, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path()))}
    else
      filters = normalize_filters(params)
      webhooks = list_webhooks(socket, filters)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(),
          page_title: "Webhooks",
          page_kicker: "Integration visibility",
          page_summary:
            "Calm route-backed hub for inbound rejections, inbound accepted events, and outbound delivery records."
        )
        |> Map.merge(%{
          navigation_links: navigation_links(socket, :webhooks),
          filter_links: filter_links(socket, filters),
          filters: filters,
          webhooks: webhooks,
          change_requests_path: Session.current_path(socket, change_requests_path()),
          audit_path: Session.current_path(socket, audit_path()),
          schedule_path: Session.current_path(socket, schedule_path()),
          flags_path: Session.current_path(socket, mount_path(socket))
        })

      {:noreply, socket |> assign(:filters, filters) |> assign(:page, page)}
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
        <h2>Webhook list</h2>
        <p>
          Triage inbound and outbound webhook state securely without secrets. Operators can filter for inbound rejections or track outbound delivery attempts.
        </p>
      </section>

      <section aria-label="Type filters">
        <h2>Filters</h2>
        <div class="rs-webhook-filter-links">
          <a :for={filter <- @page.filter_links} href={filter.path} aria-current={if(filter.current?, do: "page", else: nil)}>
            <%= filter.label %>
          </a>
        </div>
      </section>

      <section>
        <p :if={@page.webhooks == []}>No webhook records match the current filter.</p>

        <article :for={webhook <- @page.webhooks} class="rs-webhook-row">
          <header>
            <h4>
              <a href={detail_path(@page.current_environment.key, webhook.id)}>
                <%= webhook.id %>
              </a>
            </h4>
            <p>
              <span><%= webhook.type_label %></span>
              <span>·</span>
              <span><%= webhook.status_label %></span>
            </p>
          </header>

          <dl>
            <div>
              <dt>Time</dt>
              <dd><%= format_datetime(webhook.inserted_at) %></dd>
            </div>
            <div :if={webhook.actor}>
              <dt>Actor</dt>
              <dd><%= webhook.actor %></dd>
            </div>
          </dl>
        </article>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.schedule_path}>Open schedule</a></li>
          <li><a href={@page.change_requests_path}>Open change requests</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li><a href={@page.flags_path}>Back to flag inventory</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/webhooks"
  defp schedule_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp detail_path(environment_key, id),
    do: "#{base_path()}/#{id}?env=#{environment_key}"

  defp list_webhooks(_socket, filters) do
    # Fake list for UI routing. In a real integration this calls `Rulestead.list_webhooks/1`.
    case filters["type"] do
      "inbound_rejection" -> [%{id: "wh_in_rej_1", type: "inbound", type_label: "Inbound rejection", status_label: "Rejected by verifier", inserted_at: DateTime.utc_now(), actor: "remote_system"}]
      "inbound_accepted" -> [%{id: "wh_in_acc_1", type: "inbound", type_label: "Inbound accepted event", status_label: "Received from", inserted_at: DateTime.utc_now(), actor: "remote_system"}]
      "outbound_delivery" -> [%{id: "wh_out_del_1", type: "outbound", type_label: "Outbound delivery", status_label: "Delivered to", inserted_at: DateTime.utc_now(), actor: "scheduler"}]
      _ -> []
    end
  end

  defp normalize_filters(params) do
    %{"type" => params["type"]}
  end

  defp filter_links(socket, %{"type" => nil}) do
    [
      %{label: "All", path: Session.current_path(socket, base_path()), current?: true},
      %{label: "Inbound rejections", path: Session.current_path(socket, base_path(), %{"type" => "inbound_rejection"}), current?: false},
      %{label: "Inbound accepted", path: Session.current_path(socket, base_path(), %{"type" => "inbound_accepted"}), current?: false},
      %{label: "Outbound deliveries", path: Session.current_path(socket, base_path(), %{"type" => "outbound_delivery"}), current?: false}
    ]
  end

  defp filter_links(socket, %{"type" => type}) when is_binary(type) do
    [
      %{label: "Clear filter", path: Session.current_path(socket, base_path()), current?: false},
      %{
        label: "Current: #{type}",
        path: Session.current_path(socket, base_path(), %{"type" => type}),
        current?: true
      }
    ]
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

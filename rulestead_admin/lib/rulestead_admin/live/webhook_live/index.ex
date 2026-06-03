defmodule RulesteadAdmin.Live.WebhookLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page, nil) |> assign(:filters, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path(socket)))}
    else
      filters = normalize_filters(params)
      webhooks = list_webhooks(socket, filters)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(socket),
          page_title: "Webhooks",
          page_kicker: "Integration visibility",
          page_summary:
            "Calm route-backed hub for inbound rejections, inbound accepted events, and outbound delivery records."
        )
        |> Map.merge(%{
          filter_links: filter_links(socket, filters),
          filters: filters,
          webhooks: webhooks,
          change_requests_path: Session.current_path(socket, change_requests_path(socket)),
          audit_path: Session.current_path(socket, audit_path(socket)),
          schedule_path: Session.current_path(socket, schedule_path(socket)),
          flags_path: Session.current_path(socket, mount_path(socket) <> "/flags")
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
      current_tenant={@page.current_tenant}
      tenants={@page.tenants}
      tenant_links={@page.tenant_links}
      base_path={@rulestead_admin_mount_path}
      current_section={:webhooks}
      policy_state={@page.policy_state}
    >
      <OperatorComponents.empty_state
        title="Webhook records not yet available"
        body="Inbound rejections, accepted inbound events, and outbound delivery records will appear here once webhook integrations are configured and active."
        variant="hero"
      >
        <:actions>
          <OperatorComponents.related_links links={related_links(@page)} />
        </:actions>
      </OperatorComponents.empty_state>
    </Shell.page>
    """
  end

  defp base_path(socket), do: "#{mount_path(socket)}/webhooks"
  defp schedule_path(socket), do: "#{mount_path(socket)}/schedule"
  defp change_requests_path(socket), do: "#{mount_path(socket)}/change-requests"
  defp audit_path(socket), do: "#{mount_path(socket)}/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp list_webhooks(_socket, filters) do
    # Fake list for UI routing. In a real integration this calls `Rulestead.list_webhooks/1`.
    case filters["type"] do
      "inbound_rejection" ->
        [
          %{
            id: "wh_in_rej_1",
            type: "inbound",
            type_label: "Inbound rejection",
            status_label: "Rejected by verifier",
            inserted_at: DateTime.utc_now(),
            actor: "remote_system"
          }
        ]

      "inbound_accepted" ->
        [
          %{
            id: "wh_in_acc_1",
            type: "inbound",
            type_label: "Inbound accepted event",
            status_label: "Received from",
            inserted_at: DateTime.utc_now(),
            actor: "remote_system"
          }
        ]

      "outbound_delivery" ->
        [
          %{
            id: "wh_out_del_1",
            type: "outbound",
            type_label: "Outbound delivery",
            status_label: "Delivered to",
            inserted_at: DateTime.utc_now(),
            actor: "scheduler"
          }
        ]

      _ ->
        [
          %{
            id: "wh_in_rej_1",
            type: "inbound",
            type_label: "Inbound rejection",
            status_label: "Rejected by verifier",
            inserted_at: DateTime.utc_now(),
            actor: "remote_system"
          },
          %{
            id: "wh_in_acc_1",
            type: "inbound",
            type_label: "Inbound accepted event",
            status_label: "Received from",
            inserted_at: DateTime.utc_now(),
            actor: "remote_system"
          },
          %{
            id: "wh_out_del_1",
            type: "outbound",
            type_label: "Outbound delivery",
            status_label: "Delivered to",
            inserted_at: DateTime.utc_now(),
            actor: "scheduler"
          }
        ]
    end
  end

  defp related_links(page) do
    [
      %{label: "Open schedule", path: page.schedule_path},
      %{label: "Open change requests", path: page.change_requests_path},
      %{label: "Open audit timeline", path: page.audit_path},
      %{label: "Back to flag inventory", path: page.flags_path}
    ]
  end

  defp normalize_filters(params) do
    %{"type" => params["type"]}
  end

  defp filter_links(socket, %{"type" => nil}) do
    [
      %{label: "All", path: Session.current_path(socket, base_path(socket)), current?: true},
      %{
        label: "Inbound rejections",
        path: Session.current_path(socket, base_path(socket), %{"type" => "inbound_rejection"}),
        current?: false
      },
      %{
        label: "Inbound accepted",
        path: Session.current_path(socket, base_path(socket), %{"type" => "inbound_accepted"}),
        current?: false
      },
      %{
        label: "Outbound deliveries",
        path: Session.current_path(socket, base_path(socket), %{"type" => "outbound_delivery"}),
        current?: false
      }
    ]
  end

  defp filter_links(socket, %{"type" => type}) when is_binary(type) do
    [
      %{
        label: "Clear filter",
        path: Session.current_path(socket, base_path(socket)),
        current?: false
      },
      %{
        label: "Current: #{type}",
        path: Session.current_path(socket, base_path(socket), %{"type" => type}),
        current?: true
      }
    ]
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

defmodule RulesteadAdmin.Live.FlagLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:detail, nil)
     |> assign(:change_request_preview, [])
     |> assign(:scheduled_execution_preview, [])
     |> assign(:error_message, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    query = query_params(uri)
    key = params["key"]
    env = query["env"] || socket.assigns.current_environment.key
    base_path = detail_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_detail(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker="Flag detail"
      page_summary="Calm read surface for flag metadata, lifecycle, and environment rules status."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@detail} class="rs-detail">
        <div class="rs-detail__actions">
          <a href={path_for(assigns, "/#{@detail.flag.key}/edit")}>Edit metadata</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/rules")}>Open rules workspace</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/kill")}>Open kill switch</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/timeline")}>Open audit timeline</a>
        </div>

        <AuditComponents.kill_switch_banner
          :if={kill_switch_active?(@detail)}
          active?={true}
          flag_key={@detail.flag.key}
          environment_name={@detail.environment.name}
          reason={latest_reason(@detail, @current_actor)}
          kill_path={path_for(assigns, "/#{@detail.flag.key}/kill")}
          timeline_path={path_for(assigns, "/#{@detail.flag.key}/timeline")}
          show_release_button={true}
        />

        <div class="rs-detail__hero">
          <div>
            <h2><code><%= @detail.flag.key %></code></h2>
            <p><%= @detail.flag.description %></p>
            <FlagComponents.tag_list tags={@detail.flag.tags} />
          </div>
          <div class="rs-detail__stats">
            <FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} tone="neutral" />
            <FlagComponents.stat title="Owner" value={@detail.lifecycle.owner} tone="neutral" />
            <FlagComponents.stat title="Type" value={humanize(@detail.flag.flag_type)} tone="neutral" />
            <FlagComponents.stat title="Value type" value={humanize(@detail.flag.value_type)} tone="neutral" />
            <FlagComponents.stat title="Default value" value={inspect(@detail.flag.default_value.value)} tone="neutral" />
            <FlagComponents.stat title="Environment status" value={humanize(@detail.flag_environment.status)} tone="neutral" />
          </div>
        </div>

        <FlagComponents.section_card title="Lifecycle">
          <p>
            <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
            <%= if @detail.lifecycle.state in [:stale, :potentially_stale] do %>
              <a href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}>
                <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
              </a>
            <% else %>
              <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
            <% end %>
            <span>Owner: <%= @detail.lifecycle.owner %></span>
          </p>
          <p>
            <%= if @detail.flag.permanent do %>
              Permanent
            <% else %>
              Expected expiration: <%= @detail.flag.expected_expiration %>
            <% end %>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Environment overview">
          <ul>
            <%= for card <- @detail.environment_cards do %>
              <li>
                <strong><%= card.environment.name %></strong>
                <FlagComponents.environment_status status={card.flag_environment.status} />
                <span><%= humanize(card.lifecycle.state) %></span>
              </li>
            <% end %>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Rules status">
          <div>
            <h3>Active ruleset</h3>
            <p :if={@detail.active_ruleset}>Version <%= @detail.active_ruleset.version %></p>
            <p :if={is_nil(@detail.active_ruleset)}>No published ruleset yet.</p>
          </div>

          <div :if={@detail.has_draft_ruleset?}>
            <h3>Draft ruleset</h3>
            <p>Version <%= List.first(@detail.draft_rulesets).version %></p>
            <p>Draft changes exist for <%= @detail.environment.name %>. Use the dedicated workspace to review and publish.</p>
          </div>

          <div :if={!@detail.has_draft_ruleset?}>
            <h3>Draft ruleset</h3>
            <p>No draft ruleset for <%= @detail.environment.name %>.</p>
          </div>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Open change requests">
          <p :if={@change_request_preview == []}>
            No open change requests for this flag in <%= @current_environment.name %>.
          </p>

          <ul :if={@change_request_preview != []}>
            <li :for={entry <- @change_request_preview}>
              <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
            </li>
          </ul>

          <p>
            <a href={path_for(assigns, "/change-requests")}>Open change requests</a>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Scheduled changes">
          <p :if={@scheduled_execution_preview == []}>
            No scheduled changes for this flag in <%= @current_environment.name %>.
          </p>

          <ul :if={@scheduled_execution_preview != []}>
            <li :for={entry <- @scheduled_execution_preview}>
              <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
            </li>
          </ul>

          <p>
            <a href={path_for(assigns, "/schedule")}>Scheduled changes</a>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Audit">
          <p>This screen stays focused on current state. Use the dedicated timeline for append-only history and rollback context.</p>
        </FlagComponents.section_card>
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("release_kill_switch", _params, socket) do
    case Rulestead.release_kill_switch(
           socket.assigns.flag_key,
           socket.assigns.current_environment.key,
           socket.assigns.current_actor,
           reason: "Released from flag detail banner"
         ) do
      {:ok, _payload} ->
        {:noreply,
         socket
         |> assign(:error_message, nil)
         |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}

      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        assign(socket, :detail, detail)
        |> assign(:change_request_preview, load_change_request_preview(key, env))
        |> assign(:scheduled_execution_preview, load_scheduled_execution_preview(key, env))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:change_request_preview, [])
        |> assign(:scheduled_execution_preview, [])
        |> assign(:error_message, error.message)
    end
  end

  defp load_change_request_preview(flag_key, env) do
    case Rulestead.list_change_requests(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.filter(&(&1.state in [:submitted, :approved]))
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: get_in(entry.command, ["diff", "title"]) || humanize(entry.action),
            path: "/admin/flags/change-requests/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
  end

  defp load_scheduled_execution_preview(flag_key, env) do
    case Rulestead.list_scheduled_executions(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: "#{humanize(entry.action)} at #{format_schedule(entry.scheduled_for)}",
            path: "/admin/flags/schedule/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
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

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp page_title(%{flag_key: flag_key}) when is_binary(flag_key), do: flag_key
  defp page_title(_assigns), do: "Flag detail"

  defp kill_switch_active?(detail), do: detail.flag_environment.status == :killswitched

  defp latest_reason(detail, actor) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: actor
           ),
         event when is_map(event) <-
           Enum.find(
             page.entries,
             &(&1.event_type in ["kill_switch.engage", "kill_switch.release"])
           ) do
      event.reason
    else
      _ -> nil
    end
  end

  defp detail_base_path(socket, key), do: admin_base_path(socket, "/#{key}")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp format_schedule(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_schedule(_datetime), do: "pending"
end

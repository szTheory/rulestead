defmodule RulesteadAdmin.Live.FlagLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, "/admin/flags")
      |> assign(:detail, nil)
     |> assign(:error_message, nil)
      |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    query = query_params(uri)
    key = params["key"]
    env = query["env"] || socket.assigns.current_environment.key
    current_path = build_path("/admin/flags/#{key}", env)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, current_path)
      |> assign(:env_links, detail_env_links(key, socket.assigns.available_environments))
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
          <a href={"/admin/flags/#{@detail.flag.key}/edit?env=#{@detail.environment.key}"}>Edit metadata</a>
          <a href={"/admin/flags/#{@detail.flag.key}/rules?env=#{@detail.environment.key}"}>Open rules workspace</a>
          <a href={"/admin/flags/#{@detail.flag.key}/kill?env=#{@detail.environment.key}"}>Open kill switch</a>
          <a href={"/admin/flags/#{@detail.flag.key}/timeline?env=#{@detail.environment.key}"}>Open audit timeline</a>
        </div>

        <AuditComponents.kill_switch_banner
          :if={kill_switch_active?(@detail)}
          active?={true}
          flag_key={@detail.flag.key}
          environment_name={@detail.environment.name}
          reason={latest_reason(@detail)}
          kill_path={"/admin/flags/#{@detail.flag.key}/kill?env=#{@detail.environment.key}"}
          timeline_path={"/admin/flags/#{@detail.flag.key}/timeline?env=#{@detail.environment.key}"}
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
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp detail_env_links(key, environments) do
    Enum.into(environments, %{}, fn environment ->
      {environment.key, build_path("/admin/flags/#{key}", environment.key)}
    end)
  end

  defp build_path(base, env), do: "#{base}?env=#{env}"

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
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
  defp humanize(value), do: to_string(value)

  defp page_title(%{flag_key: flag_key}) when is_binary(flag_key), do: flag_key
  defp page_title(_assigns), do: "Flag detail"

  defp kill_switch_active?(detail), do: detail.flag_environment.status == :killswitched

  defp latest_reason(detail) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: %{id: "detail-page", roles: [:auditor]}
           ),
         event when is_map(event) <-
           Enum.find(page.entries, &(&1.event_type in ["kill_switch.engage", "kill_switch.release"])) do
      event.reason
    else
      _ -> nil
    end
  end
end

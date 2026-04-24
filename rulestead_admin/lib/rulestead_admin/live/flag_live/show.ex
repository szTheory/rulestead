defmodule RulesteadAdmin.Live.FlagLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.Redaction
  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:mode, :detail)
     |> assign(:flag_key, nil)
      |> assign(:current_path, "/admin/flags")
      |> assign(:detail, nil)
     |> assign(:entries, [])
     |> assign(:filters, default_audit_filters())
      |> assign(:error_message, nil)
      |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    query = query_params(uri)
    key = params["key"]

    if key == "audit" do
      filters =
        default_audit_filters()
        |> Map.merge(%{
          "actor" => Map.get(params, "actor", ""),
          "mutation" => Map.get(params, "mutation", ""),
          "from" => Map.get(params, "from", ""),
          "to" => Map.get(params, "to", ""),
          "env_filter" => Map.get(params, "env_filter", "all")
        })

      socket =
        socket
        |> assign(:mode, :global_audit)
        |> assign(:flag_key, key)
        |> assign(:filters, filters)
        |> assign(:current_path, build_audit_path(filters))
        |> assign(:env_links, audit_env_links(socket.assigns.available_environments, filters))
        |> load_global_audit(filters)

      {:noreply, socket}
    else
      env = query["env"] || socket.assigns.current_environment.key
      current_path = build_path("/admin/flags/#{key}", env)

      socket =
        socket
        |> assign(:mode, :detail)
        |> assign(:flag_key, key)
        |> assign(:current_path, current_path)
        |> assign(:env_links, detail_env_links(key, socket.assigns.available_environments))
        |> load_detail(key, env)

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker={page_kicker(assigns)}
      page_summary={page_summary(assigns)}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@mode == :global_audit}>
        <FlagComponents.section_card title="Filters">
          <form phx-change="filter_audit" phx-submit="filter_audit" aria-label="Audit filters">
            <label>
              Actor
              <input type="text" name="filters[actor]" value={@filters["actor"]} aria-label="Actor filter" />
            </label>

            <label>
              Environment
              <select name="filters[env_filter]" aria-label="Environment filter">
                <option value="all" selected={@filters["env_filter"] == "all"}>All environments</option>
                <option :for={env <- @available_environments} value={env.key} selected={@filters["env_filter"] == env.key}>
                  {env.name}
                </option>
              </select>
            </label>

            <label>
              Mutation type
              <select name="filters[mutation]" aria-label="Mutation type filter">
                <option value="" selected={@filters["mutation"] == ""}>All mutations</option>
                <option value="kill_switch.engage" selected={@filters["mutation"] == "kill_switch.engage"}>Kill switch engage</option>
                <option value="kill_switch.release" selected={@filters["mutation"] == "kill_switch.release"}>Kill switch release</option>
                <option value="audit.rollback" selected={@filters["mutation"] == "audit.rollback"}>Rollback</option>
              </select>
            </label>

            <label>
              From
              <input type="date" name="filters[from]" value={@filters["from"]} aria-label="From date" />
            </label>

            <label>
              To
              <input type="date" name="filters[to]" value={@filters["to"]} aria-label="To date" />
            </label>
          </form>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Ledger">
          <p>Global audit reads the same append-only ledger as the per-flag timeline, but projects it across flags for investigation.</p>
        </FlagComponents.section_card>

        <FlagComponents.section_card :if={@entries == []} title="Empty state">
          <p>No audit entries match the selected filters.</p>
        </FlagComponents.section_card>

        <div :for={entry <- @entries}>
          <AuditComponents.timeline_row entry={entry} show_flag={true} />
          <AuditComponents.diff_card :if={entry.show_diff?} entry={entry} />
        </div>
      </div>

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

  @impl true
  def handle_event("filter_audit", %{"filters" => filters}, socket) do
    merged = Map.merge(socket.assigns.filters, filters)
    {:noreply, push_patch(socket, to: build_audit_path(merged))}
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

  defp load_global_audit(socket, filters) do
    command_env =
      case filters["env_filter"] do
        "all" -> nil
        nil -> nil
        "" -> nil
        value -> value
      end

    case Rulestead.list_audit_events(environment_key: command_env, actor: socket.assigns.current_actor) do
      {:ok, page} ->
        socket
        |> assign(:detail, nil)
        |> assign(:entries, page.entries |> Enum.map(&audit_entry_view/1) |> filter_audit_entries(filters))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:entries, [])
        |> assign(:error_message, error.message)
    end
  end

  defp detail_env_links(key, environments) do
    Enum.into(environments, %{}, fn environment ->
      {environment.key, build_path("/admin/flags/#{key}", environment.key)}
    end)
  end

  defp audit_env_links(environments, filters) do
    Enum.into(environments, %{}, fn environment ->
      {environment.key, build_audit_path(Map.put(filters, "env_filter", environment.key))}
    end)
  end

  defp build_path(base, env), do: "#{base}?env=#{env}"

  defp build_audit_path(filters) do
    params =
      filters
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> Map.new()

    query = URI.encode_query(params)
    if query == "", do: "/admin/flags/audit", else: "/admin/flags/audit?" <> query
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
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
  defp humanize(value), do: to_string(value)

  defp page_title(%{mode: :global_audit}), do: "Audit timeline"
  defp page_title(%{flag_key: flag_key}) when is_binary(flag_key), do: flag_key
  defp page_title(_assigns), do: "Flag detail"

  defp page_kicker(%{mode: :global_audit}), do: "Audit"
  defp page_kicker(_assigns), do: "Flag detail"

  defp page_summary(%{mode: :global_audit}),
    do: "Global audit route reserved for actor, environment, and mutation filters across every flag."

  defp page_summary(_assigns),
    do: "Calm read surface for flag metadata, lifecycle, and environment rules status."

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

  defp default_audit_filters do
    %{"actor" => "", "mutation" => "", "from" => "", "to" => "", "env_filter" => "all"}
  end

  defp audit_entry_view(event) do
    metadata = redacted_metadata(event.metadata)
    before_state = metadata["before"] || %{}
    after_state = metadata["after"] || %{}

    %{
      id: event.id,
      title: audit_title_for(event),
      meta: audit_meta_for(event),
      summary: audit_summary_for(event, before_state, after_state),
      reason: event.reason,
      raw: %{event: Map.take(event, [:event_type, :result, :resource_key, :environment_key, :actor_display, :occurred_at]), metadata: metadata},
      result: event.result,
      before_summary: audit_state_summary(before_state),
      after_summary: audit_state_summary(after_state),
      rollback_of_event_id: metadata["rollback_of_event_id"],
      show_diff?: map_size(before_state) > 0 or map_size(after_state) > 0,
      event_type: event.event_type,
      actor_display: event.actor_display || event.actor_id || "",
      resource_key: event.resource_key,
      occurred_at: event.occurred_at
    }
  end

  defp filter_audit_entries(entries, filters) do
    entries
    |> Enum.filter(&matches_actor?(&1, filters["actor"]))
    |> Enum.filter(&matches_mutation?(&1, filters["mutation"]))
    |> Enum.filter(&matches_date_range?(&1, filters["from"], filters["to"]))
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
  end

  defp matches_actor?(_entry, nil), do: true
  defp matches_actor?(_entry, ""), do: true

  defp matches_actor?(entry, actor) do
    String.contains?(entry.actor_display |> to_string() |> String.downcase(), String.downcase(actor))
  end

  defp matches_mutation?(_entry, nil), do: true
  defp matches_mutation?(_entry, ""), do: true
  defp matches_mutation?(entry, mutation), do: entry.event_type == mutation

  defp matches_date_range?(entry, from, to) do
    with {:ok, from_date} <- parse_optional_date(from),
         {:ok, to_date} <- parse_optional_date(to) do
      occurred_on = DateTime.to_date(entry.occurred_at)
      after_from = is_nil(from_date) or Date.compare(occurred_on, from_date) in [:eq, :gt]
      before_to = is_nil(to_date) or Date.compare(occurred_on, to_date) in [:eq, :lt]
      after_from and before_to
    else
      _ -> true
    end
  end

  defp parse_optional_date(nil), do: {:ok, nil}
  defp parse_optional_date(""), do: {:ok, nil}
  defp parse_optional_date(value), do: Date.from_iso8601(value)

  defp redacted_metadata(metadata) do
    metadata
    |> Redaction.redact_metadata(
      allow: [
        "before.status",
        "before.kill_switch_variant_key",
        "after.status",
        "after.kill_switch_variant_key",
        "rollback_of_event_id",
        "links.inverse_event_type"
      ]
    )
    |> Map.fetch!(:audit)
  end

  defp audit_title_for(%{event_type: "kill_switch.engage", result: :ok}), do: "Kill switch engaged"
  defp audit_title_for(%{event_type: "kill_switch.release", result: :ok}), do: "Kill switch released"
  defp audit_title_for(%{event_type: "audit.rollback"}), do: "Rollback applied"
  defp audit_title_for(%{event_type: event_type, result: :denied}), do: "#{audit_humanize_event(event_type)} denied"
  defp audit_title_for(%{event_type: event_type}), do: audit_humanize_event(event_type)

  defp audit_meta_for(event) do
    actor = event.actor_display || event.actor_id || "Unknown actor"
    result = event.result |> to_string() |> String.upcase()
    time = if(event.occurred_at, do: Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S UTC"), else: "Unknown time")
    "#{actor} • #{event.environment_key} • #{result} • #{time}"
  end

  defp audit_summary_for(event, before_state, after_state) do
    case event.result do
      :denied ->
        "Denied action remains visible in the audit ledger. Requested change: #{audit_state_summary(after_state)}."

      _ ->
        "#{audit_humanize_event(event.event_type)} changed #{audit_state_summary(before_state)} to #{audit_state_summary(after_state)}."
    end
  end

  defp audit_state_summary(state) when map_size(state) == 0, do: "no recorded state"

  defp audit_state_summary(state) do
    status = state["status"] || state[:status] || "unknown"
    variant = state["kill_switch_variant_key"] || state[:kill_switch_variant_key] || "none"
    "status #{status}, kill variant #{variant}"
  end

  defp audit_humanize_event(event_type) do
    event_type
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end

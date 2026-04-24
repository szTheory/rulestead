defmodule RulesteadAdmin.Live.AuditLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.Redaction
  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:entries, [])
     |> assign(:filters, default_filters())
     |> assign(:error_message, nil)
     |> assign(:notice, nil)
     |> assign(:current_path, "/admin/flags/audit")
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filters =
      socket.assigns.filters
      |> Map.merge(%{
        "actor" => Map.get(params, "actor", ""),
        "mutation" => Map.get(params, "mutation", ""),
        "from" => Map.get(params, "from", ""),
        "to" => Map.get(params, "to", ""),
        "env_filter" => Map.get(params, "env_filter", socket.assigns.current_environment.key)
      })

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:current_path, build_path(filters))
      |> assign(:env_links, detail_env_links(socket.assigns.available_environments, filters))
      |> load_entries(filters)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Audit timeline"
      page_kicker="Audit"
      page_summary="Global audit route reserved for actor, environment, and mutation filters across every flag."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <FlagComponents.section_card title="Filters">
        <form phx-change="filter" phx-submit="filter" aria-label="Audit filters">
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
    </Shell.page>
    """
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    merged = Map.merge(socket.assigns.filters, filters)
    {:noreply, push_patch(socket, to: build_path(merged))}
  end

  defp load_entries(socket, filters) do
    command_env =
      case filters["env_filter"] do
        "all" -> nil
        nil -> socket.assigns.current_environment.key
        "" -> socket.assigns.current_environment.key
        value -> value
      end

    case Rulestead.list_audit_events(environment_key: command_env, actor: socket.assigns.current_actor) do
      {:ok, page} ->
        socket
        |> assign(:entries, page.entries |> Enum.map(&entry_view/1) |> filter_entries(filters))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:entries, [])
        |> assign(:error_message, error.message)
    end
  end

  defp entry_view(event) do
    metadata = redacted_metadata(event.metadata)
    before_state = metadata["before"] || %{}
    after_state = metadata["after"] || %{}

    %{
      id: event.id,
      title: title_for(event),
      meta: meta_for(event),
      summary: summary_for(event, before_state, after_state),
      reason: event.reason,
      raw: %{event: Map.take(event, [:event_type, :result, :resource_key, :environment_key, :actor_display, :occurred_at]), metadata: metadata},
      before_summary: state_summary(before_state),
      after_summary: state_summary(after_state),
      rollback_of_event_id: metadata["rollback_of_event_id"],
      show_diff?: map_size(before_state) > 0 or map_size(after_state) > 0,
      result: event.result,
      event_type: event.event_type,
      actor_display: event.actor_display || event.actor_id || "",
      environment_key: event.environment_key,
      resource_key: event.resource_key,
      occurred_at: event.occurred_at
    }
  end

  defp filter_entries(entries, filters) do
    entries
    |> Enum.filter(&matches_actor?(&1, filters["actor"]))
    |> Enum.filter(&matches_mutation?(&1, filters["mutation"]))
    |> Enum.filter(&matches_date_range?(&1, filters["from"], filters["to"]))
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
  end

  defp matches_actor?(_entry, nil), do: true
  defp matches_actor?(_entry, ""), do: true

  defp matches_actor?(entry, actor) do
    String.contains?(String.downcase(entry.actor_display), String.downcase(actor))
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

  defp title_for(%{event_type: "kill_switch.engage", result: :ok}), do: "Kill switch engaged"
  defp title_for(%{event_type: "kill_switch.release", result: :ok}), do: "Kill switch released"
  defp title_for(%{event_type: "audit.rollback"}), do: "Rollback applied"
  defp title_for(%{event_type: event_type, result: :denied}), do: "#{humanize_event(event_type)} denied"
  defp title_for(%{event_type: event_type}), do: humanize_event(event_type)

  defp meta_for(event) do
    actor = event.actor_display || event.actor_id || "Unknown actor"
    result = event.result |> to_string() |> String.upcase()
    time = if(event.occurred_at, do: Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S UTC"), else: "Unknown time")
    "#{actor} • #{event.environment_key} • #{result} • #{time}"
  end

  defp summary_for(event, before_state, after_state) do
    case event.result do
      :denied ->
        "Denied action remains visible in the audit ledger. Requested change: #{state_summary(after_state)}."

      _ ->
        "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
    end
  end

  defp state_summary(state) when map_size(state) == 0, do: "no recorded state"

  defp state_summary(state) do
    status = state["status"] || state[:status] || "unknown"
    variant = state["kill_switch_variant_key"] || state[:kill_switch_variant_key] || "none"
    "status #{status}, kill variant #{variant}"
  end

  defp humanize_event(event_type) do
    event_type
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp default_filters do
    %{"actor" => "", "mutation" => "", "from" => "", "to" => "", "env_filter" => "prod"}
  end

  defp build_path(filters) do
    params =
      filters
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> Map.new()

    query = URI.encode_query(params)
    if query == "", do: "/admin/flags/audit", else: "/admin/flags/audit?" <> query
  end

  defp detail_env_links(environments, filters) do
    Enum.into(environments, %{}, fn environment ->
      {environment.key, build_path(Map.put(filters, "env_filter", environment.key))}
    end)
  end
end

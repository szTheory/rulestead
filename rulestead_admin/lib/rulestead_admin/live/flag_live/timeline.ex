defmodule RulesteadAdmin.Live.FlagLive.Timeline do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.Redaction
  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:entries, [])
     |> assign(:error_message, nil)
     |> assign(:notice, nil)
     |> assign(:flag_key, nil)
     |> assign(:current_path, "/admin/flags")
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    env = query_params(uri)["env"] || socket.assigns.current_environment.key

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, build_path("/admin/flags/#{key}/timeline", env))
      |> assign(:env_links, detail_env_links(key, socket.assigns.available_environments))
      |> load_page(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} audit timeline", else: "Audit timeline")}
      page_kicker="Timeline"
      page_summary="Per-flag audit route reserved for append-only history, readable diffs, and linked rollback context."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a :if={@flag_key} href={"/admin/flags/#{@flag_key}?env=#{@current_environment.key}"}>Back to detail</a>
        <a href={"/admin/flags/audit?env_filter=#{@current_environment.key}"}>Open global audit</a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <FlagComponents.section_card :if={@detail} title="Timeline summary">
        <p>
          One redacted ledger projects into this per-flag view for <code>{@detail.flag.key}</code> in
          {@detail.environment.name}.
        </p>
        <p>Rollback writes a new inverse event linked to the original row. Earlier history remains intact.</p>
      </FlagComponents.section_card>

      <FlagComponents.section_card :if={@entries == []} title="Empty state">
        <p>No audit entries are available for this flag in the current environment.</p>
      </FlagComponents.section_card>

      <div :for={entry <- @entries}>
        <AuditComponents.timeline_row entry={entry} show_rollback={entry.rollback_allowed?} />
        <AuditComponents.diff_card :if={entry.show_diff?} entry={entry} />
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("rollback", %{"id" => audit_event_id}, socket) do
    case Rulestead.rollback_audit_event(audit_event_id,
           actor: socket.assigns.current_actor,
           reason: "Rollback requested from per-flag timeline"
         ) do
      {:ok, %{audit_event: audit_event}} ->
        {:noreply,
         socket
         |> assign(:notice, "Rollback appended as audit event #{audit_event.id}.")
         |> assign(:error_message, nil)
         |> load_page(socket.assigns.flag_key, socket.assigns.current_environment.key)}

      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  defp load_page(socket, key, env) do
    with {:ok, detail} <- Rulestead.fetch_flag(key, env),
         {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: key,
             environment_key: env,
             actor: socket.assigns.current_actor
           ) do
      socket
      |> assign(:detail, detail)
      |> assign(:entries, build_entries(page.entries))
      |> assign(:error_message, nil)
    else
      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:entries, [])
        |> assign(:error_message, error.message)
    end
  end

  defp build_entries(entries) do
    entries
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
    |> Enum.map(&entry_view/1)
  end

  defp entry_view(event) do
    metadata = redacted_metadata(event.metadata)
    before_state = metadata["before"] || %{}
    after_state = metadata["after"] || %{}
    rollback_of_event_id = metadata["rollback_of_event_id"]

    %{
      id: event.id,
      title: title_for(event),
      meta: meta_for(event),
      summary: summary_for(event, before_state, after_state),
      reason: event.reason,
      raw: %{event: Map.take(event, [:event_type, :result, :resource_key, :environment_key, :actor_display, :occurred_at]), metadata: metadata},
      result: event.result,
      before_summary: state_summary(before_state),
      after_summary: state_summary(after_state),
      rollback_of_event_id: rollback_of_event_id,
      rollback_allowed?: rollback_allowed?(event),
      show_diff?: map_size(before_state) > 0 or map_size(after_state) > 0
    }
  end

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

  defp summary_for(%{event_type: "audit.rollback"} = event, _before_state, after_state) do
    "Inverse write restored #{state_summary(after_state)} and linked this row back to #{event.metadata["rollback_of_event_id"] || "the original event"}."
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

  defp rollback_allowed?(%{event_type: event_type, result: :ok}),
    do: event_type in ["kill_switch.engage", "kill_switch.release"]

  defp rollback_allowed?(_event), do: false

  defp humanize_event(event_type) do
    event_type
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp detail_env_links(key, environments) do
    Enum.into(environments, %{}, fn environment ->
      {environment.key, build_path("/admin/flags/#{key}/timeline", environment.key)}
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
end

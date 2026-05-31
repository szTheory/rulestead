# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.DiagnosticsLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Phoenix.LiveView.AsyncResult
  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:health_snapshot, AsyncResult.loading())
     |> assign(:refresh_notice, nil)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    page =
      Session.placeholder_assigns(socket,
        current_path: "/admin/flags/diagnostics",
        page_title: "Infrastructure health",
        page_kicker: "Diagnostics",
        page_summary:
          "Read current-node cache freshness, sync latency, and adapter health without leaving the mounted admin surface."
      )

    socket =
      socket
      |> assign(:page, page)
      |> assign(:refresh_notice, nil)
      |> assign(:health_snapshot, AsyncResult.loading())
      |> maybe_load_health()

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket =
      socket
      |> assign(
        :refresh_notice,
        "Refresh requested for #{socket.assigns.page.current_environment.name}."
      )
      |> assign(:health_snapshot, AsyncResult.loading())
      |> load_health()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @page do %>
      <Shell.page
        page_title={@page.page_title}
        page_kicker={@page.page_kicker}
        page_summary={@page.page_summary}
        current_environment={@page.current_environment}
        environments={@page.environments}
        env_links={@page.env_links}
        policy_state={@page.policy_state}
      >
        <:header_actions>
          <button type="button" phx-click="refresh" aria-label="Refresh diagnostics">Refresh diagnostics</button>
        </:header_actions>

        <OperatorComponents.banner
          title={scope_title(@health_snapshot)}
          body={scope_body(@health_snapshot, @page.current_environment)}
          tone={scope_tone(@health_snapshot)}
          aria_label="Topology scope"
        />

        <p :if={@refresh_notice} role="status"><%= @refresh_notice %></p>

        <.async_result :let={health_view} assign={@health_snapshot}>
          <:loading>
            <FlagComponents.section_card title="Current health summary">
              <p>Loading current-node health for <%= @page.current_environment.name %>.</p>
            </FlagComponents.section_card>
          </:loading>

          <:failed :let={_failure}>
          <OperatorComponents.banner
            title="Health snapshot unavailable"
            body={"We could not load current-node diagnostics for #{@page.current_environment.key}. Use refresh after a sync lands."}
            tone="critical"
            aria_label="Health snapshot unavailable"
          />
          </:failed>

          <%= if health_view.environment do %>
          <FlagComponents.section_card title="Current health summary">
            <OperatorComponents.summary_grid
              items={health_view.summary_items}
              aria_label="Infrastructure health summary"
            />
          </FlagComponents.section_card>

            <FlagComponents.section_card title="Freshness details">
              <OperatorComponents.trace_panel
                title="Freshness details"
                summary="Current-node cache freshness and refresh timing for the selected environment."
                rows={health_view.freshness_rows}
              />
            </FlagComponents.section_card>

            <FlagComponents.section_card title="Sync and invalidation">
              <OperatorComponents.trace_panel
                title="Sync and invalidation"
                summary="Use refresh state first, then inspect worker backoff and invalidation timing if freshness drifts."
                rows={health_view.sync_rows}
              />
            </FlagComponents.section_card>

            <FlagComponents.section_card title="Adapter health">
              <OperatorComponents.status_list
                title="Adapter health"
                entries={health_view.adapter_entries}
              />
            </FlagComponents.section_card>
          <% else %>
            <OperatorComponents.banner
              title="Health snapshot unavailable"
              body={"No current-node runtime snapshot is loaded for #{@page.current_environment.key}. Use refresh after a sync lands."}
              tone="critical"
              aria_label="Health snapshot unavailable"
            />

            <FlagComponents.section_card title="Current health summary">
              <p>Current node only. This screen does not infer peer health without explicit host-supplied data.</p>
            </FlagComponents.section_card>
          <% end %>
        </.async_result>
      </Shell.page>
    <% end %>
    """
  end

  defp maybe_load_health(socket) do
    if connected?(socket), do: load_health(socket), else: socket
  end

  defp load_health(socket) do
    environment_key = socket.assigns.page.current_environment.key

    assign_async(socket, :health_snapshot, fn ->
      {:ok, %{health_snapshot: build_health_view(environment_key)}}
    end)
  end

  defp build_health_view(environment_key) do
    snapshot = Rulestead.infrastructure_health()
    environment = Enum.find(snapshot.environments, &(&1.environment_key == environment_key))

    %{
      topology_scope: snapshot.topology_scope,
      environment: environment,
      summary_items: summary_items(environment),
      freshness_rows: freshness_rows(environment),
      sync_rows: sync_rows(environment),
      adapter_entries: adapter_entries(environment)
    }
  end

  defp summary_items(nil), do: []

  defp summary_items(environment) do
    [
      %{
        title: "Cache age",
        value: human_duration(environment.cache_age_ms),
        tone: freshness_tone(environment.cache_age_ms)
      },
      %{
        title: "Sync latency",
        value: human_duration(environment.sync_latency_ms),
        tone: freshness_tone(environment.sync_latency_ms)
      },
      %{
        title: "Snapshot version",
        value: to_string(environment.snapshot_version || "none"),
        tone: "neutral"
      },
      %{
        title: "Refresh state",
        value: humanize(environment.refresh_status),
        tone: refresh_tone(environment.refresh_status)
      }
    ]
  end

  defp freshness_rows(nil), do: []

  defp freshness_rows(environment) do
    [
      %{label: "Environment", value: environment.environment_key},
      %{label: "Cache age", value: human_duration(environment.cache_age_ms)},
      %{label: "Sync latency", value: human_duration(environment.sync_latency_ms)},
      %{label: "Snapshot version", value: to_string(environment.snapshot_version || "none")}
    ]
  end

  defp sync_rows(nil), do: []

  defp sync_rows(environment) do
    worker_status = environment.refresh_worker_status || %{}

    [
      %{label: "Refresh state", value: humanize(environment.refresh_status)},
      %{label: "Worker status", value: humanize(worker_status[:refresh_status])},
      %{label: "Retry attempt", value: to_string(worker_status[:attempt] || 0)},
      %{label: "Next backoff", value: human_duration(worker_status[:next_backoff_ms] || 0)}
    ]
  end

  defp adapter_entries(nil), do: []

  defp adapter_entries(environment) do
    environment.adapter_health
    |> List.wrap()
    |> Enum.flat_map(fn adapter_health ->
      [
        adapter_entry("Repo", adapter_health.repo),
        adapter_entry("Redis", adapter_health.redis),
        adapter_entry("PubSub", adapter_health.pubsub)
      ]
    end)
  end

  defp adapter_entry(label, %{configured?: configured?, status: status}) do
    %{
      label: label,
      value: adapter_value(configured?, status),
      summary: adapter_summary(configured?, status),
      tone: adapter_tone(configured?, status)
    }
  end

  defp scope_title(%AsyncResult{ok?: true, result: %{topology_scope: :host_provided}}),
    do: "Host-provided topology"

  defp scope_title(_health_snapshot), do: "Current node only"

  defp scope_body(
         %AsyncResult{ok?: true, result: %{topology_scope: :host_provided}},
         _environment
       ) do
    "This screen includes host-supplied peer context. Treat only the rendered rows as known health facts."
  end

  defp scope_body(_health_snapshot, environment) do
    "This screen reports only the connected node for #{environment.name}. It does not imply undiscovered peers are healthy."
  end

  defp scope_tone(%AsyncResult{ok?: true, result: %{topology_scope: :host_provided}}),
    do: "neutral"

  defp scope_tone(_health_snapshot), do: "warning"

  defp human_duration(nil), do: "Not available"
  defp human_duration(ms) when ms < 1_000, do: "#{ms} ms"
  defp human_duration(ms), do: :io_lib.format("~.1fs", [ms / 1_000]) |> IO.iodata_to_binary()

  defp humanize(nil), do: "Not available"

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp freshness_tone(nil), do: "critical"
  defp freshness_tone(ms) when ms >= 5_000, do: "warning"
  defp freshness_tone(_ms), do: "positive"

  defp refresh_tone(:ready), do: "positive"
  defp refresh_tone(:stale), do: "warning"
  defp refresh_tone(:degraded), do: "critical"
  defp refresh_tone(_status), do: "neutral"

  defp adapter_value(false, _status), do: "Not configured"
  defp adapter_value(true, status), do: humanize(status)

  defp adapter_summary(false, _status), do: "Host config has not enabled this adapter path."
  defp adapter_summary(true, :up), do: "Configured and running on this node."
  defp adapter_summary(true, :down), do: "Configured but not reachable on this node."
  defp adapter_summary(true, status), do: "Configured with status #{humanize(status)}."

  defp adapter_tone(false, _status), do: "neutral"
  defp adapter_tone(true, :up), do: "positive"
  defp adapter_tone(true, :down), do: "critical"
  defp adapter_tone(true, _status), do: "warning"
end

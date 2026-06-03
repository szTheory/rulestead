# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AuditLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.Redaction
  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:entries, [])
     |> assign(:filters, default_filters())
     |> assign(:error_message, nil)
     |> assign(:notice, nil)
     |> assign(:current_path, nil)
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
      |> assign(:current_path, build_path(socket, filters))
      |> assign(:env_links, detail_env_links(socket, filters))
      |> load_entries(filters)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Audit timeline"
      page_kicker="Change history"
      page_summary="Append-only record of every mutation across all flags. Filter by actor, environment, mutation type, or date range. For flag-scoped history, use the flag's own Timeline tab."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
      base_path={@rulestead_admin_mount_path}
      current_section={:audit}
    >
      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <FlagComponents.section_card title="Filters">
        <form phx-change="filter" phx-submit="filter" aria-label="Audit filters" class="rs-filter-grid">
          <div class="rs-form-field">
            <label for="audit_filter_actor">Actor</label>
            <input
              id="audit_filter_actor"
              type="text"
              name="filters[actor]"
              value={@filters["actor"]}
              placeholder="Filter by actor ID"
            />
          </div>

          <div class="rs-form-field">
            <label for="audit_filter_env">Environment</label>
            <select id="audit_filter_env" name="filters[env_filter]">
              <option value="all" selected={@filters["env_filter"] == "all"}>All environments</option>
              <option :for={env <- @available_environments} value={env.key} selected={@filters["env_filter"] == env.key}>
                {env.name}
              </option>
            </select>
          </div>

          <div class="rs-form-field">
            <label for="audit_filter_mutation">Mutation type</label>
            <select id="audit_filter_mutation" name="filters[mutation]">
              <option value="" selected={@filters["mutation"] == ""}>All mutations</option>
              <option value="kill_switch.engage" selected={@filters["mutation"] == "kill_switch.engage"}>Kill switch engage</option>
              <option value="kill_switch.release" selected={@filters["mutation"] == "kill_switch.release"}>Kill switch release</option>
              <option value="ruleset.publish" selected={@filters["mutation"] == "ruleset.publish"}>Ruleset publish</option>
              <option value="audit.rollback" selected={@filters["mutation"] == "audit.rollback"}>Rollback</option>
            </select>
          </div>

          <div class="rs-form-field">
            <label for="audit_filter_from">From</label>
            <input id="audit_filter_from" type="date" name="filters[from]" value={@filters["from"]} />
          </div>

          <div class="rs-form-field">
            <label for="audit_filter_to">To</label>
            <input id="audit_filter_to" type="date" name="filters[to]" value={@filters["to"]} />
          </div>
        </form>
      </FlagComponents.section_card>

      <OperatorComponents.empty_state
        :if={@entries == []}
        title="No audit events match these filters"
        body="Widen the actor, environment, mutation type, or date range filters to inspect more of the append-only ledger. For flag-scoped history, open the flag and use its Timeline tab."
        variant="compact"
      />

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
    {:noreply, push_patch(socket, to: build_path(socket, merged))}
  end

  defp load_entries(socket, filters) do
    command_env =
      case filters["env_filter"] do
        "all" -> nil
        nil -> socket.assigns.current_environment.key
        "" -> socket.assigns.current_environment.key
        value -> value
      end

    mount_path = socket.assigns.rulestead_admin_mount_path

    case Rulestead.list_audit_events(
           environment_key: command_env,
           actor: socket.assigns.current_actor
         ) do
      {:ok, page} ->
        socket
        |> assign(
          :entries,
          page.entries |> Enum.map(&entry_view(&1, mount_path)) |> filter_entries(filters)
        )
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:entries, [])
        |> assign(:error_message, error.message)
    end
  end

  defp entry_view(event, mount_path) do
    metadata = redacted_metadata(event.metadata)
    before_state = metadata["before"] || %{}
    after_state = metadata["after"] || %{}
    diff_state = metadata["diff"] || %{}

    %{
      id: event.id,
      resource_type: event.resource_type,
      resource_nav: resource_nav(mount_path, event),
      title: title_for(event),
      meta: meta_for(event),
      summary: summary_for(event, before_state, after_state, diff_state),
      reason: event.reason,
      raw: %{
        event:
          Map.take(event, [
            :event_type,
            :result,
            :resource_type,
            :resource_key,
            :environment_key,
            :actor_display,
            :occurred_at
          ]),
        metadata: metadata
      },
      before_summary: state_summary(before_state),
      after_summary: state_summary(after_state),
      diff_lines: diff_lines(event.event_type, diff_state),
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
    |> Enum.filter(
      &(matches_actor?(&1, filters["actor"]) and matches_mutation?(&1, filters["mutation"]))
    )
    |> Enum.filter(&matches_date_range?(&1, filters["from"], filters["to"]))
    |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
  end

  defp matches_actor?(_entry, nil), do: true
  defp matches_actor?(_entry, ""), do: true

  defp matches_actor?(entry, actor) do
    actor_display =
      entry.actor_display
      |> to_string()
      |> String.downcase()

    String.contains?(actor_display, String.downcase(actor))
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
        "before.rules",
        "after.status",
        "after.kill_switch_variant_key",
        "after.rules",
        "diff.rules",
        "rollback_of_event_id",
        "links.inverse_event_type"
      ]
    )
    |> Map.fetch!(:audit)
  end

  defp title_for(%{event_type: "kill_switch.engage", result: :ok}), do: "Kill switch engaged"
  defp title_for(%{event_type: "kill_switch.release", result: :ok}), do: "Kill switch released"
  defp title_for(%{event_type: "audit.rollback"}), do: "Rollback applied"

  defp title_for(%{event_type: event_type, result: :denied}),
    do: "#{humanize_event(event_type)} denied"

  defp title_for(%{event_type: event_type}), do: humanize_event(event_type)

  defp meta_for(event) do
    actor = event.actor_display || event.actor_id || "Unknown actor"
    result = event.result |> to_string() |> String.upcase()

    time =
      if event.occurred_at do
        Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S UTC")
      else
        "Unknown time"
      end

    "#{actor} • #{event.environment_key} • #{result} • #{time}"
  end

  defp summary_for(%{event_type: "ruleset.publish"}, _before_state, _after_state, diff_state) do
    "Ruleset publish updated ordered rule positions: #{Enum.join(diff_lines("ruleset.publish", diff_state), "; ")}."
  end

  defp summary_for(event, before_state, after_state, _diff_state) do
    case event.result do
      :denied ->
        "Denied action remains visible in the audit ledger. Requested change: #{state_summary(after_state)}."

      _ ->
        "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
    end
  end

  defp state_summary(state) when map_size(state) == 0, do: "no recorded state"

  defp state_summary(state) do
    rules = Map.get(state, "rules") || Map.get(state, :rules)

    if is_list(rules) and rules != [] do
      rules
      |> Enum.map(fn rule ->
        "#{rule["key"] || rule[:key]} @ #{rule["position"] || rule[:position]}"
      end)
      |> Enum.join(", ")
    else
      status = state["status"] || state[:status] || "unknown"
      variant = state["kill_switch_variant_key"] || state[:kill_switch_variant_key] || "none"
      "status #{status}, kill variant #{variant}"
    end
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

  defp build_path(socket, filters) do
    params =
      filters
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> Map.new()

    Session.current_path(socket, admin_base_path(socket, "/audit"), params)
  end

  defp detail_env_links(socket, filters) do
    Enum.into(socket.assigns.available_environments, %{}, fn environment ->
      {environment.key, build_path(socket, Map.put(filters, "env_filter", environment.key))}
    end)
  end

  # Resolve a row's resource into navigable links so the cross-flag audit ledger
  # is never a dead end (Support/SRE land here and need to jump to the flag, its
  # timeline, or the decision explainer). Only resources with detail routes are
  # linked; environment-scoped rows render as a plain label.
  defp resource_nav(_mount_path, %{resource_key: key}) when key in [nil, ""], do: nil

  defp resource_nav(mount_path, %{resource_type: "flag", resource_key: key} = event) do
    env_q = env_query(event.environment_key)

    %{
      label: "Flag",
      key: key,
      primary: "#{mount_path}/#{key}#{env_q}",
      actions: [
        %{label: "Timeline", href: "#{mount_path}/#{key}/timeline#{env_q}"},
        %{label: "Explain", href: "#{mount_path}/#{key}/explain#{env_q}"}
      ]
    }
  end

  defp resource_nav(mount_path, %{resource_type: "audience", resource_key: key} = event) do
    %{
      label: "Audience",
      key: key,
      primary: "#{mount_path}/audiences/#{key}#{env_query(event.environment_key)}",
      actions: []
    }
  end

  defp resource_nav(_mount_path, %{resource_type: resource_type, resource_key: key}) do
    %{label: resource_label(resource_type), key: key, primary: nil, actions: []}
  end

  defp resource_label(nil), do: "Resource"
  defp resource_label(resource_type), do: resource_type |> to_string() |> String.capitalize()

  defp env_query(env_key) when env_key in [nil, ""], do: ""
  defp env_query(env_key), do: "?env=#{env_key}"

  defp diff_lines("ruleset.publish", %{"rules" => rules}) when is_list(rules) do
    Enum.map(rules, fn rule ->
      "#{rule["key"]} from #{inspect(rule["from"])} to #{inspect(rule["to"])}"
    end)
  end

  defp diff_lines(_event_type, _diff_state), do: []

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
end

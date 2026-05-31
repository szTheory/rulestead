# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Timeline do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Admin.Redaction
  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:entries, [])
     |> assign(:error_message, nil)
     |> assign(:notice, nil)
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})
     |> assign(:show_rollback_guidance?, false)}
  end

  @impl true
  def handle_params(%{"key" => key}, _uri, socket) do
    env = socket.assigns.current_environment.key
    base_path = build_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_page(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} audit timeline", else: "Audit timeline")}
      page_kicker="Timeline"
      page_summary="History for this flag in the selected environment."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <:header_actions>
        <a :if={@flag_key} href={path_for(assigns, "/#{@flag_key}")}>Back to detail</a>
        <a href={Session.current_path(assigns, admin_base_path(assigns, "/audit"), %{"env_filter" => @current_environment.key})}>
          Open global audit
        </a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <section :if={@detail} class="rs-timeline-context" aria-label="Timeline context">
        <p>
          Use this timeline to see when <code>{@detail.flag.key}</code> changed in
          {@detail.environment.name}, who changed it, and the recorded reason.
        </p>
        <p :if={@show_rollback_guidance?}>
          Rollback creates a new audit event that reverses the selected change. The original event
          stays in history.
        </p>
      </section>

      <FlagComponents.section_card :if={@entries == []} title="Empty state">
        <p>No audit entries are available for this flag in the current environment.</p>
      </FlagComponents.section_card>

      <ol :if={@entries != []} class="rs-event-timeline" aria-label="Flag audit events">
        <AuditComponents.timeline_item
          :for={entry <- @entries}
          entry={entry}
          show_rollback={entry.rollback_allowed? and (@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?)}
        />
      </ol>
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
      entries = build_entries(page.entries)

      socket
      |> assign(:detail, detail)
      |> assign(:entries, entries)
      |> assign(:show_rollback_guidance?, Enum.any?(entries, & &1.rollback_allowed?))
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
    diff_state = metadata["diff"] || %{}
    change = change_view(event, before_state, after_state, diff_state, rollback_of_event_id)

    %{
      id: event.id,
      title: title_for(event),
      meta: meta_for(event),
      resource_key: event.resource_key,
      actor_label: event.actor_display || event.actor_id || "Unknown actor",
      environment_key: event.environment_key,
      occurred_at_iso: occurred_at_iso(event.occurred_at),
      occurred_at_label: occurred_at_label(event.occurred_at),
      summary:
        summary_for(event, metadata, before_state, after_state, diff_state, rollback_of_event_id),
      reason: event.reason,
      automatic?: guardrail_automation_event?(event),
      source_label: source_label(metadata),
      raw: %{
        event:
          Map.take(event, [
            :event_type,
            :result,
            :resource_key,
            :environment_key,
            :actor_display,
            :occurred_at
          ]),
        metadata: metadata
      },
      result: event.result,
      change_label: change.change_label,
      source_summary: change.source_summary,
      source_diff_label: change.source_label,
      proposed_target_summary: change.proposed_target_summary,
      proposed_target_diff_label: change.proposed_target_label,
      diff_lines: change.diff_lines,
      rollback_of_event_id: rollback_of_event_id,
      rollback_allowed?: rollback_allowed?(event),
      show_diff?: change.show?
    }
  end

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
        "guardrail.signal_key",
        "guardrail.environment_key",
        "guardrail.tenant_key",
        "guardrail.status",
        "guardrail.reason",
        "guardrail.threshold_operator",
        "guardrail.threshold_value",
        "guardrail.observed_value",
        "guardrail.freshness_window_seconds",
        "guardrail.sample_size",
        "guardrail.min_sample_size",
        "guardrail.evaluated_at",
        "links.guardrail_decision_id",
        "links.stable_guardrail_decision_id",
        "rollback_of_event_id",
        "links.inverse_event_type",
        "source",
        "request_id",
        "context.source",
        "context.eligibility",
        "context.scheduled_execution_id",
        "context.observation_window_started_at",
        "context.observation_window_ends_at",
        "context.observation_window_seconds",
        "context.eligibility.policy_snapshot",
        "context.eligibility.policy_snapshot.next_stage",
        "context.eligibility.policy_snapshot.next_percentage",
        "context.eligibility.policy_snapshot.observation_window_seconds",
        "links.scheduled_execution_id",
        "links.change_request_id"
      ]
    )
    |> Map.fetch!(:audit)
  end

  defp guardrail_automation_event?(%{event_type: "rollout.advance"} = event) do
    metadata = event.metadata || %{}
    source = metadata["source"] || metadata[:source]
    source in ["guardrail_automation", :guardrail_automation]
  end

  defp guardrail_automation_event?(%{event_type: event_type}) do
    event_type in [
      "rollout.guardrail_held",
      "rollout.guardrail_rollback",
      "rollout.guardrail_evaluated"
    ]
  end

  defp source_label(%{"source" => "guardrail_automation"}), do: "Guardrail automation"
  defp source_label(%{"source" => "admin_ui"}), do: "Admin UI"
  defp source_label(%{"source" => source}) when is_binary(source), do: humanize_event(source)
  defp source_label(_metadata), do: nil

  defp title_for(%{event_type: "rollout.guardrail_held"}), do: "Automatic guardrail hold"

  defp title_for(%{event_type: "rollout.guardrail_rollback"}),
    do: "Automatic guardrail rollback"

  defp title_for(%{event_type: "rollout.guardrail_evaluated"}), do: "Guardrail evaluated"

  defp title_for(%{event_type: "rollout.advance"} = event) do
    if guardrail_automation_event?(event),
      do: "Automatic rollout advance",
      else: humanize_event("rollout.advance")
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
      if(event.occurred_at,
        do: Calendar.strftime(event.occurred_at, "%Y-%m-%d %H:%M:%S UTC"),
        else: "Unknown time"
      )

    "#{actor} • #{event.environment_key} • #{result} • #{time}"
  end

  defp occurred_at_iso(%DateTime{} = occurred_at), do: DateTime.to_iso8601(occurred_at)
  defp occurred_at_iso(_occurred_at), do: nil

  defp occurred_at_label(%DateTime{} = occurred_at),
    do: Calendar.strftime(occurred_at, "%b %d, %Y %H:%M UTC")

  defp occurred_at_label(_occurred_at), do: "Unknown time"

  defp summary_for(
         %{event_type: "audit.rollback"} = event,
         _metadata,
         _before_state,
         after_state,
         _diff_state,
         rollback_of_event_id
       ) do
    linked =
      rollback_of_event_id || event.metadata["rollback_of_event_id"] || "the original event"

    "Restored #{serving_state_label(after_state)} and linked this correction to #{linked}."
  end

  defp summary_for(
         %{event_type: "ruleset.publish"},
         _metadata,
         _before_state,
         _after_state,
         diff_state,
         _rollback_of_event_id
       ) do
    case rules_added(diff_state) do
      [rule | _rest] -> "Published a ruleset. #{rule_label(rule)} is now the first rule."
      [] -> "Published a ruleset for this flag."
    end
  end

  defp summary_for(
         %{event_type: "flag.archive"},
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    "Archived this flag and removed it from active inventory. The history remains available here."
  end

  defp summary_for(
         %{event_type: "kill_switch.engage", result: :ok},
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    "Turned the kill switch on. This environment now serves the configured fallback variant."
  end

  defp summary_for(
         %{event_type: "kill_switch.release", result: :ok},
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    "Turned the kill switch off. Normal flag rules are serving again."
  end

  defp summary_for(
         %{event_type: "rollout.guardrail_held"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    append_reason(
      "Guardrail automation held this rollout fail-closed. Review the missing or stale signal before advancing.",
      event
    )
  end

  defp summary_for(
         %{event_type: "rollout.guardrail_rollback"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    append_reason(
      "A confirmed threshold breach triggered rollback to the last stable rollout snapshot.",
      event
    )
  end

  defp summary_for(
         %{event_type: "rollout.guardrail_evaluated"} = event,
         _metadata,
         _before_state,
         _after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    append_reason(
      "Automation is waiting for valid guardrail evidence and will not assume the stage is healthy.",
      event
    )
  end

  defp summary_for(
         %{event_type: "rollout.advance"} = event,
         metadata,
         before_state,
         after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    if guardrail_automation_event?(event) do
      automatic_rollout_advance_summary(metadata, before_state, after_state)
    else
      case event.result do
        :denied ->
          "Request was denied. No serving change was applied."

        _ ->
          "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
      end
    end
  end

  defp summary_for(
         event,
         _metadata,
         before_state,
         after_state,
         _diff_state,
         _rollback_of_event_id
       ) do
    case event.result do
      :denied ->
        "Request was denied. No serving change was applied."

      _ ->
        "#{humanize_event(event.event_type)} changed #{state_summary(before_state)} to #{state_summary(after_state)}."
    end
  end

  defp automatic_rollout_advance_summary(metadata, before_state, after_state) do
    context = metadata["context"] || metadata[:context] || %{}
    eligibility = context["eligibility"] || context[:eligibility] || %{}
    snapshot = eligibility["policy_snapshot"] || eligibility[:policy_snapshot] || %{}

    stage = snapshot["next_stage"] || snapshot[:next_stage]
    percentage = snapshot["next_percentage"] || snapshot[:next_percentage]

    {stage, percentage} =
      if present?(stage) do
        {stage, percentage}
      else
        advance_target_from_rules(after_state) || advance_target_from_rules(before_state) ||
          {nil, nil}
      end

    window_ends =
      context["observation_window_ends_at"] || context[:observation_window_ends_at]

    base =
      cond do
        present?(stage) and present?(percentage) ->
          "Advanced to #{stage} at #{percentage}%"

        present?(stage) ->
          "Advanced to #{stage}"

        true ->
          "Automatic rollout advanced"
      end

    if present?(window_ends) do
      "#{base} after observation window closed at #{format_observation_timestamp(window_ends)}."
    else
      "#{base} after observation window closed."
    end
  end

  defp advance_target_from_rules(state) do
    rules = Map.get(state, "rules") || Map.get(state, :rules) || []

    case List.first(rules) do
      %{} = rule ->
        rollout = Map.get(rule, "rollout") || Map.get(rule, :rollout) || %{}
        stage = Map.get(rollout, "stage") || Map.get(rollout, :stage)
        percentage = Map.get(rollout, "percentage") || Map.get(rollout, :percentage)
        if present?(stage), do: {stage, percentage}, else: nil

      _ ->
        nil
    end
  end

  defp format_observation_timestamp(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")

  defp format_observation_timestamp(value) when is_binary(value), do: value
  defp format_observation_timestamp(_), do: "closed"

  defp present?(value), do: not is_nil(value) and value != ""

  defp append_reason(summary, %{reason: reason}) when is_binary(reason) and reason != "",
    do: "#{summary} Reason: #{reason}"

  defp append_reason(summary, _event), do: summary

  defp change_view(%{event_type: "ruleset.publish"}, before_state, after_state, diff_state, _id) do
    %{
      show?: true,
      change_label: "Rules",
      source_label: "Previous rules",
      source_summary: rules_summary(before_state, :previous),
      proposed_target_label: "Published rules",
      proposed_target_summary: rules_summary(after_state, :published),
      diff_lines: ruleset_diff_lines(diff_state)
    }
  end

  defp change_view(%{event_type: "flag.archive"}, before_state, after_state, _diff_state, _id) do
    %{
      show?: true,
      change_label: "Inventory state",
      source_label: "Previous state",
      source_summary: inventory_state_label(before_state, "Active"),
      proposed_target_label: "New state",
      proposed_target_summary: inventory_state_label(after_state, "Archived"),
      diff_lines: [
        "Removed from active inventory. Current flag configuration remains available for audit."
      ]
    }
  end

  defp change_view(%{event_type: event_type}, before_state, after_state, _diff_state, _id)
       when event_type in ["kill_switch.engage", "kill_switch.release"] do
    %{
      show?: true,
      change_label: "Serving state",
      source_label: "Previous state",
      source_summary: kill_switch_summary(before_state),
      proposed_target_label: "New state",
      proposed_target_summary: kill_switch_summary(after_state),
      diff_lines: []
    }
  end

  defp change_view(%{event_type: "audit.rollback"}, _before_state, after_state, _diff_state, id) do
    %{
      show?: true,
      change_label: "Correction",
      source_label: "Restored state",
      source_summary: serving_state_label(after_state),
      proposed_target_label: "Linked event",
      proposed_target_summary: id || "Original event",
      diff_lines: []
    }
  end

  defp change_view(_event, before_state, after_state, diff_state, _id) do
    %{
      show?: map_size(before_state) > 0 or map_size(after_state) > 0,
      change_label: "State",
      source_label: "Previous state",
      source_summary: state_summary(before_state),
      proposed_target_label: "New state",
      proposed_target_summary: state_summary(after_state),
      diff_lines: diff_lines(nil, diff_state)
    }
  end

  defp rules_summary(state, empty_kind) do
    rules = Map.get(state, "rules") || Map.get(state, :rules) || []

    case rules do
      [] when empty_kind == :previous -> "No published rules"
      [] -> "No rules"
      rules when is_list(rules) -> Enum.map_join(rules, ", ", &rule_label/1)
      _other -> "No rules"
    end
  end

  defp rule_label(rule) when is_map(rule) do
    key = rule["key"] || rule[:key] || "unnamed rule"
    position = rule["position"] || rule[:position]

    case position do
      nil -> key
      position when is_integer(position) -> "#{key} at position #{position + 1}"
      position -> "#{key} at position #{position}"
    end
  end

  defp inventory_state_label(state, fallback) do
    state
    |> Map.get("status", Map.get(state, :status, fallback))
    |> to_string()
    |> humanize_event()
  end

  defp kill_switch_summary(state) do
    "#{serving_state_label(state)}; fallback variant #{variant_label(state)}"
  end

  defp serving_state_label(state) do
    case Map.get(state, "status") || Map.get(state, :status) do
      "killswitched" -> "Kill switch on"
      :killswitched -> "Kill switch on"
      "active" -> "Active"
      :active -> "Active"
      nil -> "Unknown"
      status -> humanize_event(to_string(status))
    end
  end

  defp variant_label(state) do
    case Map.get(state, "kill_switch_variant_key") || Map.get(state, :kill_switch_variant_key) do
      nil -> "None"
      "" -> "None"
      value -> to_string(value)
    end
  end

  defp state_summary(state) when map_size(state) == 0, do: "no recorded state"

  defp state_summary(state) do
    rules = Map.get(state, "rules") || Map.get(state, :rules)

    if is_list(rules) and rules != [] do
      rules
      |> Enum.map_join(", ", fn rule ->
        "#{rule["key"] || rule[:key]} @ #{rule["position"] || rule[:position]}"
      end)
    else
      status = state["status"] || state[:status] || "unknown"
      variant = state["kill_switch_variant_key"] || state[:kill_switch_variant_key] || "none"
      "status #{status}, kill variant #{variant}"
    end
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

  defp rules_added(%{"rules" => rules}) when is_list(rules) do
    Enum.filter(rules, fn rule -> is_nil(rule["from"]) and not is_nil(rule["to"]) end)
  end

  defp rules_added(_diff_state), do: []

  defp ruleset_diff_lines(%{"rules" => rules}) when is_list(rules) do
    Enum.map(rules, fn rule ->
      key = rule["key"] || "Unnamed rule"

      cond do
        is_nil(rule["from"]) and not is_nil(rule["to"]) ->
          "Added #{key} as the #{ordinal(rule["to"] + 1)} rule."

        not is_nil(rule["from"]) and is_nil(rule["to"]) ->
          "Removed #{key} from the published rules."

        true ->
          "Moved #{key} from position #{rule["from"] + 1} to #{rule["to"] + 1}."
      end
    end)
  end

  defp ruleset_diff_lines(_diff_state), do: []

  defp diff_lines(_event_type, _diff_state), do: []

  defp ordinal(1), do: "first"
  defp ordinal(2), do: "second"
  defp ordinal(3), do: "third"
  defp ordinal(number), do: "#{number}th"

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/timeline")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
end

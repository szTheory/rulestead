# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.HomeLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session
  alias RulesteadAdmin.Navigation

  # Event types worth surfacing on the operations home — the changes an operator
  # most wants to notice when they land here under pressure.
  @high_impact_events ~w(
    kill_switch.engage kill_switch.release
    rollout.guardrail_held rollout.guardrail_rollback
    ruleset.publish flag.archive
  )

  # One-line summaries for the task launcher, keyed by nav item. Structure and
  # labels come from RulesteadAdmin.Navigation so the launcher and the left rail
  # can never drift apart again.
  @launcher_summaries %{
    flags: "Inventory of every flag in this environment.",
    experiments: "Experiment-type flags and their lifecycle.",
    audiences: "Reusable targeting rules and their dependents.",
    schedule: "Upcoming and in-flight scheduled changes.",
    diagnostics: "Cache freshness, sync latency, and adapter health.",
    audit: "Append-only history of every change, across all flags.",
    compare: "Diff flag state across environments before promoting.",
    change_requests: "Review queue for governed mutations and approvals.",
    webhooks: "Inbound and outbound integration delivery records."
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    mount_path = socket.assigns.rulestead_admin_mount_path
    env = socket.assigns.current_environment

    socket =
      socket
      |> assign(:current_path, Session.current_path(socket, mount_path))
      |> assign(:env_links, Session.env_links(socket, mount_path))
      |> assign(:current_uri, uri)
      |> assign_async(:summary, fn -> {:ok, %{summary: load_summary(mount_path, env.key)}} end)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    base = assigns.rulestead_admin_mount_path
    env_key = assigns.current_environment.key

    assigns =
      assigns
      |> assign(:caps, assigns.rulestead_admin_policy_state.capabilities)
      |> assign(:env_q, "?env=" <> env_key)
      |> assign(:base, base)
      |> assign(:launcher_groups, launcher_groups(base, env_key, assigns.current_environment))

    ~H"""
    <Shell.page
      page_title={"What's happening in #{@current_environment.name}"}
      page_kicker="Rulestead"
      page_summary="A live read of this environment — what's serving, what's moving, and what needs you."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      policy_state={@rulestead_admin_policy_state}
      base_path={@rulestead_admin_mount_path}
      current_section={:home}
    >
      <.async_result :let={summary} assign={@summary}>
        <:loading>
          <section class="rs-page-section" aria-label="Loading current state">
            <p class="rs-eyebrow">Needs you now</p>
            <p class="rs-attention-empty" aria-live="polite">Reading current state…</p>
          </section>
        </:loading>
        <:failed :let={_reason}>
          <OperatorComponents.banner
            title="Live state is unavailable"
            body="The operational summary could not be loaded. The task launcher below still works, and the cached snapshot keeps serving."
            tone="warning"
          />
        </:failed>

        <% attention = attention_items(summary, @base, @env_q) %>
        <section class="rs-page-section" aria-label="Needs you now">
          <header class="rs-section-header">
            <div>
              <p class="rs-eyebrow">Needs you now</p>
              <h2>What needs attention in {@current_environment.name}</h2>
            </div>
          </header>

          <p :if={attention == []} class="rs-attention-empty">
            Nothing needs your attention in {@current_environment.name} right now.
          </p>

          <div :if={attention != []} class="rs-attention">
            <a :for={item <- attention} class="rs-attention__card" data-tone={item.tone} href={item.href}>
              <span class="rs-attention__count">{item.count}</span>
              <span class="rs-attention__label">{item.label}</span>
              <span class="rs-attention__hint">{item.hint}</span>
            </a>
          </div>
        </section>

        <section
          :if={summary.high_impact != [] or summary.running > 0 or summary.upcoming > 0}
          class="rs-page-section"
          aria-label="What's live and moving"
        >
          <header class="rs-section-header">
            <div>
              <p class="rs-eyebrow">What's live &amp; moving</p>
              <h2>Recent changes in {@current_environment.name}</h2>
            </div>
            <a :if={summary.upcoming > 0 or summary.running > 0} href={@base <> "/schedule" <> @env_q}>
              {schedule_label(summary)}
            </a>
          </header>

          <p :if={summary.high_impact == []} class="rs-attention-empty">
            No high-impact changes recorded recently.
          </p>

          <div :if={summary.high_impact != []} class="rs-record-list">
            <OperatorComponents.record_row
              :for={event <- summary.high_impact}
              title={event.title}
              href={event.flag_path || (@base <> "/audit" <> @env_q)}
              meta={event.meta}
              tone={event.tone}
            >
              <:actions>
                <a :if={event.flag_path} href={event.flag_path}>Open flag</a>
                <a href={@base <> "/audit" <> @env_q}>Audit</a>
              </:actions>
            </OperatorComponents.record_row>
          </div>
        </section>
      </.async_result>

      <nav class="rs-task-board" aria-label="Start a task">
        <section :for={group <- @launcher_groups} class="rs-task-group" aria-label={group.title}>
          <h2>{group.title}</h2>
          <OperatorComponents.task_link
            :if={group.create_action? and (@caps.edit? or @caps.admin?)}
            title="Create a flag"
            summary="Author a new flag, variant, or remote-config value."
            href={@base <> "/new" <> @env_q}
            primary?={true}
          />
          <OperatorComponents.task_link
            :for={item <- group.items}
            title={item.label}
            summary={item.summary}
            href={item.path}
          />
        </section>
      </nav>
    </Shell.page>
    """
  end

  # --- Launcher (structure + labels sourced from Navigation) ---------------

  defp launcher_groups(base_path, env_key, _environment) do
    base_path
    |> Navigation.groups(env_key)
    |> Enum.map(fn group ->
      %{
        title: group.title,
        create_action?: Enum.any?(group.items, &(&1.key == :flags)),
        items:
          Enum.map(group.items, fn item ->
            Map.put(item, :summary, Map.get(@launcher_summaries, item.key))
          end)
      }
    end)
  end

  # --- Attention band ------------------------------------------------------

  defp attention_items(summary, base, env_q) do
    [
      kill_item(summary, base, env_q),
      pending_item(summary, base, env_q),
      failed_item(summary, base, env_q),
      stale_item(summary, base, env_q)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp kill_item(%{kill_engaged: list}, base, env_q) when list != [] do
    count = length(list)

    href =
      case list do
        [%{flag_key: key}] -> "#{base}/#{key}/kill#{env_q}"
        _ -> "#{base}/audit#{env_q}"
      end

    %{
      count: count,
      label: pluralize(count, "kill switch engaged", "kill switches engaged"),
      hint: "Review forced evaluations",
      tone: "critical",
      href: href
    }
  end

  defp kill_item(_summary, _base, _env_q), do: nil

  defp pending_item(%{pending_changes: count}, base, env_q) when count > 0 do
    %{
      count: count,
      label:
        pluralize(count, "change request awaiting review", "change requests awaiting review"),
      hint: "Approve, reject, or schedule",
      tone: "warning",
      href: "#{base}/change-requests#{env_q}"
    }
  end

  defp pending_item(_summary, _base, _env_q), do: nil

  defp failed_item(%{failed: count}, base, env_q) when count > 0 do
    %{
      count: count,
      label:
        pluralize(count, "scheduled change needs attention", "scheduled changes need attention"),
      hint: "Failed or quarantined executions",
      tone: "critical",
      href: "#{base}/schedule#{env_q}"
    }
  end

  defp failed_item(_summary, _base, _env_q), do: nil

  defp stale_item(%{stale_candidates: count}, base, env_q) when count > 0 do
    %{
      count: count,
      label: pluralize(count, "flag ready for cleanup", "flags ready for cleanup"),
      hint: "Archive candidates",
      tone: "warning",
      href: "#{base}/flags#{env_q}&view=archive_candidates"
    }
  end

  defp stale_item(_summary, _base, _env_q), do: nil

  # --- Summary loaders (env-scoped, capped — never full scans) -------------

  defp load_summary(mount_path, env_key) do
    {kill_engaged, stale_candidates} = summarize_flags(env_key)
    executions = summarize_executions(env_key)

    %{
      pending_changes: count_pending(env_key),
      kill_engaged: kill_engaged,
      stale_candidates: stale_candidates,
      failed: executions.failed,
      upcoming: executions.upcoming,
      running: executions.running,
      high_impact: recent_high_impact(mount_path, env_key)
    }
  end

  defp count_pending(env_key) do
    case Rulestead.list_change_requests(environment_key: env_key, status: :submitted, limit: 50) do
      {:ok, page} -> length(page.entries)
      _ -> 0
    end
  end

  # Kill-switch and archive-candidate state have no cross-flag aggregate API, so
  # both are derived from a single capped flag scan. On very large tenants this
  # caps at the first page; that is an accepted top-N tradeoff for the home.
  defp summarize_flags(env_key) do
    case Rulestead.list_flags(environment_key: env_key, limit: 100) do
      {:ok, page} ->
        kill_engaged =
          page.entries
          |> Enum.filter(&killswitched?/1)
          |> Enum.map(&%{flag_key: &1.flag.key})

        stale = Enum.count(page.entries, &archive_candidate?/1)
        {kill_engaged, stale}

      _ ->
        {[], 0}
    end
  end

  defp killswitched?(entry), do: get_in(entry, [:flag_environment, :status]) == :killswitched

  defp archive_candidate?(entry),
    do: get_in(entry, [:lifecycle, :archive_readiness, :state]) == :archive_candidate

  defp summarize_executions(env_key) do
    case Rulestead.list_scheduled_executions(environment_key: env_key, limit: 50) do
      {:ok, page} ->
        counts = Enum.frequencies_by(page.entries, & &1.state)

        %{
          failed: Map.get(counts, :failed, 0) + Map.get(counts, :quarantined, 0),
          upcoming: Map.get(counts, :scheduled, 0),
          running: Map.get(counts, :running, 0)
        }

      _ ->
        %{failed: 0, upcoming: 0, running: 0}
    end
  end

  defp recent_high_impact(mount_path, env_key) do
    case Rulestead.list_audit_events(environment_key: env_key, limit: 50) do
      {:ok, page} ->
        page.entries
        |> Enum.filter(&(&1.event_type in @high_impact_events))
        |> Enum.sort_by(& &1.occurred_at, {:desc, DateTime})
        |> Enum.take(5)
        |> Enum.map(&high_impact_view(mount_path, &1))

      _ ->
        []
    end
  end

  defp high_impact_view(mount_path, event) do
    actor = event.actor_display || event.actor_id || "Unknown actor"

    %{
      title: high_impact_title(event),
      meta: "#{actor} · #{format_time(event.occurred_at)}",
      tone: high_impact_tone(event),
      flag_path: flag_path(mount_path, event)
    }
  end

  defp flag_path(mount_path, %{resource_type: "flag", resource_key: key, environment_key: env})
       when is_binary(key) do
    "#{mount_path}/#{key}?env=#{env}"
  end

  defp flag_path(_mount_path, _event), do: nil

  defp high_impact_title(%{event_type: "kill_switch.engage", resource_key: key}),
    do: "Kill switch engaged — #{key}"

  defp high_impact_title(%{event_type: "kill_switch.release", resource_key: key}),
    do: "Kill switch released — #{key}"

  defp high_impact_title(%{event_type: "rollout.guardrail_held", resource_key: key}),
    do: "Rollout held by guardrail — #{key}"

  defp high_impact_title(%{event_type: "rollout.guardrail_rollback", resource_key: key}),
    do: "Rollout rolled back — #{key}"

  defp high_impact_title(%{event_type: "ruleset.publish", resource_key: key}),
    do: "Ruleset published — #{key}"

  defp high_impact_title(%{event_type: "flag.archive", resource_key: key}),
    do: "Flag archived — #{key}"

  defp high_impact_title(%{resource_key: key}), do: "Change — #{key}"

  defp high_impact_tone(%{event_type: type})
       when type in ["kill_switch.engage", "rollout.guardrail_rollback"],
       do: "critical"

  defp high_impact_tone(%{event_type: "rollout.guardrail_held"}), do: "warning"
  defp high_impact_tone(%{event_type: "flag.archive"}), do: "muted"
  defp high_impact_tone(_event), do: "neutral"

  defp schedule_label(%{running: running, upcoming: upcoming}) do
    parts =
      [
        running > 0 && pluralize(running, "running", "running"),
        upcoming > 0 && pluralize(upcoming, "upcoming", "upcoming")
      ]
      |> Enum.reject(&(&1 == false))

    count = running + upcoming
    "#{count} scheduled (#{Enum.join(parts, ", ")}) →"
  end

  defp format_time(%DateTime{} = at), do: Calendar.strftime(at, "%Y-%m-%d %H:%M UTC")
  defp format_time(_), do: "Unknown time"

  defp pluralize(1, singular, _plural), do: "1 #{singular}"
  defp pluralize(count, _singular, plural), do: "#{count} #{plural}"
end

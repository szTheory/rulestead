defmodule RulesteadAdmin.Live.ScheduleLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Governance.ScheduledExecution
  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.{OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @states ScheduledExecution.states()
  @default_limit 100

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page, nil) |> assign(:filters, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path()))}
    else
      filters = normalize_filters(params)
      scheduled_executions = list_scheduled_executions(socket, filters)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(),
          page_title: "Schedule",
          page_kicker: "Scheduled changes",
          page_summary:
            "Dense route-backed list home for upcoming, running, completed, failed, quarantined, and cancelled executions."
        )
        |> Map.merge(%{
          navigation_links: navigation_links(socket, :schedule),
          filter_links: filter_links(socket, filters),
          filters: filters,
          grouped_scheduled_executions: grouped_scheduled_executions(scheduled_executions),
          change_requests_path: Session.current_path(socket, change_requests_path()),
          audit_path: Session.current_path(socket, audit_path()),
          flags_path: Session.current_path(socket, mount_path(socket))
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
      navigation_links={@page.navigation_links}
    >
      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <section>
        <h2>Dense operator list</h2>
        <p>
          Scheduled execution visibility stays list-first so operators can scan state without a calendar
          workbench. Actor wording stays explicit: scheduled by, approved by, executed by scheduler.
        </p>
        <p :if={@page.filters["state"]} class="rs-schedule-filter-summary">
          Filtered to <%= @page.filters["state"] %> executions in <%= @page.current_environment.name %>.
        </p>
      </section>

      <section aria-label="State filters">
        <h2>State filters</h2>
        <div class="rs-schedule-filter-links">
          <a :for={filter <- @page.filter_links} href={filter.path} aria-current={if(filter.current?, do: "page", else: nil)}>
            <%= filter.label %>
          </a>
        </div>
      </section>

      <section>
        <h2>Execution list</h2>
        <p>
          Requested for and execution result stay visible on every row so operators can compare planned
          timing with actual outcome before opening the detail route.
        </p>

        <section :for={group <- @page.grouped_scheduled_executions}>
          <h3><%= group.label %></h3>
          <p :if={group.entries == []}>No <%= String.downcase(group.label) %> executions in this environment.</p>

          <article :for={scheduled_execution <- group.entries} class="rs-schedule-row">
            <header>
              <h4>
                <a href={detail_path(@page.current_environment.key, scheduled_execution.id)}>
                  <%= scheduled_execution.resource_key %>
                </a>
              </h4>
              <p>
                <span><%= state_label(scheduled_execution.state) %></span>
                <span>·</span>
                <span><%= action_label(scheduled_execution.action) %></span>
              </p>
            </header>

            <dl>
              <div>
                <dt>Requested for</dt>
                <dd><%= format_datetime(scheduled_execution.scheduled_for) %></dd>
              </div>
              <div>
                <dt>Execution result</dt>
                <dd><%= execution_result_label(scheduled_execution) %></dd>
              </div>
              <div>
                <dt>Lifecycle</dt>
                <dd>
                  scheduled by <%= actor_name(scheduled_execution.scheduled_by) %>
                  <span :if={scheduled_execution.approved_by_snapshot != []}>
                    · approved by <%= joined_actor_names(scheduled_execution.approved_by_snapshot) %>
                  </span>
                  <span :if={scheduled_execution.attempt_count > 0 or scheduled_execution.executed_at}>
                    · executed by scheduler
                  </span>
                </dd>
              </div>
            </dl>

            <p :if={scheduled_execution.failure_reason}><%= scheduled_execution.failure_reason %></p>

            <p>
              <a href={flag_path(@page.current_environment.key, scheduled_execution.resource_key)}>Open flag</a>
              <span :if={scheduled_execution.change_request_id}>
                ·
                <a href={change_request_path(@page.current_environment.key, scheduled_execution.change_request_id)}>
                  Open change request
                </a>
              </span>
            </p>
          </article>
        </section>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.change_requests_path}>Open change requests</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li><a href={@page.flags_path}>Back to flag inventory</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp detail_path(environment_key, scheduled_execution_id),
    do: "#{base_path()}/#{scheduled_execution_id}?env=#{environment_key}"

  defp flag_path(environment_key, resource_key),
    do: "/admin/flags/#{resource_key}?env=#{environment_key}"

  defp change_request_path(environment_key, change_request_id),
    do: "#{change_requests_path()}/#{change_request_id}?env=#{environment_key}"

  defp grouped_scheduled_executions(entries) do
    Enum.map(@states, fn state ->
      %{
        state: state,
        label: state_label(state),
        entries: Enum.filter(entries, &(&1.state == state))
      }
    end)
    |> Enum.reject(&(&1.entries == [] and &1.state != :scheduled))
  end

  defp list_scheduled_executions(socket, filters) do
    command =
      Command.ListScheduledExecutions.new(
        environment_key: socket.assigns.current_environment.key,
        state: filters["state"],
        limit: @default_limit
      )

    case Rulestead.list_scheduled_executions(command) do
      {:ok, %Command.Page{entries: entries}} -> entries
      _ -> []
    end
  end

  defp normalize_filters(params) do
    %{"state" => parse_state(Map.get(params, "state"))}
  end

  defp filter_links(socket, %{"state" => nil}) do
    all_link = %{label: "All", path: Session.current_path(socket, base_path()), current?: true}

    state_links =
      Enum.map(@states, fn state ->
        state_string = Atom.to_string(state)

        %{
          label: state_label(state),
          path: Session.current_path(socket, base_path(), %{"state" => state_string}),
          current?: false
        }
      end)

    [all_link | state_links]
  end

  defp filter_links(socket, %{"state" => state}) when is_binary(state) do
    [
      %{label: "Clear filter", path: Session.current_path(socket, base_path()), current?: false},
      %{
        label: "Current: #{state}",
        path: Session.current_path(socket, base_path(), %{"state" => state}),
        current?: true
      }
    ]
  end

  defp navigation_links(socket, current) do
    [
      nav_link("Flags", Session.current_path(socket, mount_path(socket)), current == :flags),
      nav_link(
        "Change requests",
        Session.current_path(socket, change_requests_path()),
        current == :change_requests
      ),
      nav_link("Schedule", Session.current_path(socket, base_path()), current == :schedule),
      nav_link(
        "Webhooks",
        Session.current_path(socket, "/admin/flags/webhooks"),
        current == :webhooks
      ),
      nav_link("Audit", Session.current_path(socket, audit_path()), current == :audit)
    ]
  end

  defp nav_link(label, path, current?), do: %{label: label, path: path, current?: current?}

  defp state_label(state),
    do: state |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp action_label(action) do
    action
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp execution_result_label(%{state: :completed, executed_at: executed_at})
       when not is_nil(executed_at),
       do: "Completed at #{format_datetime(executed_at)}"

  defp execution_result_label(%{state: :cancelled, failure_reason: reason})
       when is_binary(reason), do: reason

  defp execution_result_label(%{state: :failed, failure_reason: reason}) when is_binary(reason),
    do: reason

  defp execution_result_label(%{state: :quarantined, failure_reason: reason})
       when is_binary(reason), do: reason

  defp execution_result_label(%{state: :running}), do: "Running now"
  defp execution_result_label(_scheduled_execution), do: "Waiting for scheduler"

  defp actor_name(actor) when is_map(actor),
    do: Map.get(actor, "display") || Map.get(actor, "id") || "Unknown actor"

  defp actor_name(_actor), do: "Unknown actor"

  defp joined_actor_names(actors),
    do: actors |> Enum.map(&actor_name/1) |> Enum.reject(&is_nil/1) |> Enum.join(", ")

  defp parse_state(nil), do: nil
  defp parse_state(""), do: nil

  defp parse_state(state) when is_binary(state) do
    normalized =
      try do
        String.to_existing_atom(state)
      rescue
        ArgumentError -> nil
      end

    if normalized in @states, do: state, else: nil
  end

  defp parse_state(_state), do: nil

  defp format_datetime(nil), do: "Not yet recorded"

  defp format_datetime(%DateTime{} = datetime) do
    calendar = Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
    "#{calendar} UTC"
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

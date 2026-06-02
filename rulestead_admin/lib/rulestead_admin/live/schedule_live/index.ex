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
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path(socket)))}
    else
      filters = normalize_filters(params)
      scheduled_executions = list_scheduled_executions(socket, filters)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(socket),
          page_title: "Schedule",
          page_kicker: "Scheduled changes",
          page_summary:
            "Dense route-backed list home for upcoming, running, completed, failed, quarantined, and cancelled executions."
        )
        |> Map.merge(%{
          filter_links: filter_links(socket, filters),
          filters: filters,
          grouped_scheduled_executions: grouped_scheduled_executions(scheduled_executions),
          related_links: related_links(socket),
          change_requests_path: Session.current_path(socket, change_requests_path(socket)),
          audit_path: Session.current_path(socket, audit_path(socket)),
          flags_path: Session.current_path(socket, mount_path(socket) <> "/flags")
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
      current_tenant={@page.current_tenant}
      tenants={@page.tenants}
      tenant_links={@page.tenant_links}
      base_path={@rulestead_admin_mount_path}
      current_section={:schedule}
      policy_state={@page.policy_state}
    >
      <OperatorComponents.page_section
        title="Dense operator list"
        summary="Route-backed queue for upcoming, running, failed, quarantined, completed, and cancelled scheduled work."
      >
        <p :if={@page.filters["state"]} class="rs-schedule-filter-summary">
          Filtered to <%= @page.filters["state"] %> executions in <%= @page.current_environment.name %>.
        </p>
      </OperatorComponents.page_section>

      <section class="rs-page-section" aria-label="State filters">
        <h2>State filters</h2>
        <div class="rs-segmented-links">
          <a :for={filter <- @page.filter_links} href={filter.path} aria-current={if(filter.current?, do: "page", else: nil)}>
            <%= filter.label %>
          </a>
        </div>
      </section>

      <section class="rs-page-section">
        <h2>Execution list</h2>
        <p>
          Requested for and execution result stay visible on every row so operators can compare planned
          timing with actual outcome before opening the detail route.
        </p>

        <section :for={group <- @page.grouped_scheduled_executions} class="rs-page-section">
          <h3><%= group.label %></h3>
          <p :if={group.entries == []}>No <%= String.downcase(group.label) %> executions in this environment.</p>

          <div class="rs-record-list">
            <OperatorComponents.record_row
              :for={scheduled_execution <- group.entries}
              title={scheduled_execution.resource_key}
              href={detail_path(@rulestead_admin_mount_path, @page.current_environment.key, scheduled_execution.id)}
              meta={"#{state_label(scheduled_execution.state)} · #{action_label(scheduled_execution.action)}"}
              tone={state_tone(scheduled_execution.state)}
            >
              <:actions>
                <a href={flag_path(@rulestead_admin_mount_path, @page.current_environment.key, scheduled_execution.resource_key)}>Open flag</a>
                <a
                  :if={scheduled_execution.change_request_id}
                  href={change_request_path(@rulestead_admin_mount_path, @page.current_environment.key, scheduled_execution.change_request_id)}
                >
                  Open change request
                </a>
              </:actions>
              <OperatorComponents.detail_grid rows={schedule_rows(scheduled_execution)} />
              <p :if={scheduled_execution.failure_reason} class="rs-record-row__body">
                <strong>Failure:</strong> <%= scheduled_execution.failure_reason %>
              </p>
            </OperatorComponents.record_row>
          </div>
        </section>
      </section>

      <section class="rs-page-section">
        <h2>Related routes</h2>
        <OperatorComponents.related_links links={@page.related_links} />
      </section>
    </Shell.page>
    """
  end

  defp base_path(socket), do: "#{mount_path(socket)}/schedule"
  defp change_requests_path(socket), do: "#{mount_path(socket)}/change-requests"
  defp audit_path(socket), do: "#{mount_path(socket)}/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp detail_path(mount_path, environment_key, scheduled_execution_id),
    do: "#{mount_path}/schedule/#{scheduled_execution_id}?env=#{environment_key}"

  defp flag_path(mount_path, environment_key, resource_key),
    do: "#{mount_path}/#{resource_key}?env=#{environment_key}"

  defp change_request_path(mount_path, environment_key, change_request_id),
    do: "#{mount_path}/change-requests/#{change_request_id}?env=#{environment_key}"

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
    all_link = %{
      label: "All",
      path: Session.current_path(socket, base_path(socket)),
      current?: true
    }

    state_links =
      Enum.map(@states, fn state ->
        state_string = Atom.to_string(state)

        %{
          label: state_label(state),
          path: Session.current_path(socket, base_path(socket), %{"state" => state_string}),
          current?: false
        }
      end)

    [all_link | state_links]
  end

  defp filter_links(socket, %{"state" => state}) when is_binary(state) do
    [
      %{
        label: "Clear filter",
        path: Session.current_path(socket, base_path(socket)),
        current?: false
      },
      %{
        label: "Current: #{state}",
        path: Session.current_path(socket, base_path(socket), %{"state" => state}),
        current?: true
      }
    ]
  end

  defp related_links(socket) do
    [
      %{
        label: "Open change requests",
        path: Session.current_path(socket, change_requests_path(socket))
      },
      %{label: "Open audit timeline", path: Session.current_path(socket, audit_path(socket))},
      %{
        label: "Back to flag inventory",
        path: Session.current_path(socket, mount_path(socket) <> "/flags")
      }
    ]
  end

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

  defp schedule_rows(scheduled_execution) do
    [
      %{label: "Requested for", value: format_datetime(scheduled_execution.scheduled_for)},
      %{label: "Execution result", value: execution_result_label(scheduled_execution)},
      %{label: "Lifecycle", value: lifecycle_label(scheduled_execution)}
    ]
  end

  defp lifecycle_label(scheduled_execution) do
    [
      "scheduled by #{actor_name(scheduled_execution.scheduled_by)}",
      approved_by_label(scheduled_execution),
      executed_by_label(scheduled_execution)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" · ")
  end

  defp approved_by_label(%{approved_by_snapshot: []}), do: nil

  defp approved_by_label(scheduled_execution),
    do: "approved by #{joined_actor_names(scheduled_execution.approved_by_snapshot)}"

  defp executed_by_label(%{attempt_count: attempt_count}) when attempt_count > 0,
    do: "executed by scheduler"

  defp executed_by_label(%{executed_at: %DateTime{}}), do: "executed by scheduler"
  defp executed_by_label(_scheduled_execution), do: nil

  defp state_tone(:failed), do: "critical"
  defp state_tone(:quarantined), do: "warning"
  defp state_tone(:completed), do: "positive"
  defp state_tone(_state), do: "neutral"

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

defmodule RulesteadAdmin.Live.ScheduleLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:scheduled_execution_id, nil)
     |> assign(:scheduled_execution, nil)
     |> assign(:action_notice, nil)
     |> assign(:action_error, nil)}
  end

  @impl true
  def handle_params(%{"scheduled_execution_id" => id} = params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    base_path = "#{index_path()}/#{id}"
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path))}
    else
      {scheduled_execution, error_message} = load_scheduled_execution(id)

      page =
        build_page(socket, scheduled_execution, id)
        |> Map.put(:error_message, error_message)

      {:noreply,
       socket
       |> assign(:scheduled_execution_id, id)
       |> assign(:scheduled_execution, scheduled_execution)
       |> assign(:page, page)}
    end
  end

  @impl true
  def handle_event("submit_action", %{"action" => %{"reason" => reason}}, socket) do
    reason = normalize_reason(reason)

    cond do
      is_nil(reason) ->
        {:noreply, assign(socket, :action_error, "Enter a reason before updating this execution")}

      is_nil(socket.assigns.scheduled_execution) ->
        {:noreply, assign(socket, :action_error, "Scheduled execution is unavailable")}

      socket.assigns.scheduled_execution.state == :scheduled ->
        cancel_scheduled_execution(socket, reason)

      socket.assigns.scheduled_execution.state == :quarantined ->
        requeue_scheduled_execution(socket, reason)

      true ->
        {:noreply, assign(socket, :action_error, "This execution is read-only from this screen")}
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
      policy_state={@page.policy_state}
    >
      <section :if={@page.error_message}>
        <p role="alert"><%= @page.error_message %></p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Scheduled execution <code><%= @scheduled_execution.id %></code></h2>
        <p>Execution detail remains route-backed so retries, quarantine context, and audit links stay explicit.</p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Status</h2>
        <p><%= humanize(@scheduled_execution.state) %></p>
        <p><%= humanize(@scheduled_execution.action) %></p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Change request</h2>
        <p :if={@page.change_request_path}>
          <a href={@page.change_request_path}><%= @scheduled_execution.change_request_id %></a>
        </p>
        <p :if={is_nil(@page.change_request_path)}>No linked change request.</p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Requested for</h2>
        <p><%= format_datetime(@scheduled_execution.scheduled_for) %></p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Attempt count</h2>
        <p><%= @scheduled_execution.attempt_count %></p>
        <p>scheduled by <%= actor_name(@scheduled_execution.scheduled_by) %></p>
        <p :if={@scheduled_execution.approved_by_snapshot != []}>
          approved by <%= joined_actor_names(@scheduled_execution.approved_by_snapshot) %>
        </p>
        <p :if={show_executed_by?(@scheduled_execution)}>executed by scheduler</p>
      </section>

      <section :if={@scheduled_execution}>
        <h2>Linked flag</h2>
        <p><a href={@page.flag_path}><%= @scheduled_execution.resource_key %></a></p>
      </section>

      <section :if={@scheduled_execution && @scheduled_execution.failure_reason}>
        <h2>Failure details</h2>
        <p><%= @scheduled_execution.failure_reason %></p>
      </section>

      <section :if={@scheduled_execution && @scheduled_execution.executed_at}>
        <h2>Executed at</h2>
        <p><%= format_datetime(@scheduled_execution.executed_at) %></p>
      </section>

      <section :if={@scheduled_execution}>
        <h2><%= action_panel_title(@scheduled_execution) %></h2>
        <p :if={!@action_notice}><%= action_panel_copy(@scheduled_execution) %></p>
        <p :if={@action_notice} role="status"><%= @action_notice %></p>
        <p :if={@action_error} role="alert"><%= @action_error %></p>

        <form
          :if={show_action_form?(@scheduled_execution) and (@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?)}
          id="scheduled-execution-action-form"
          phx-submit="submit_action"
        >
          <label>
            <span>Reason</span>
            <input type="text" name="action[reason]" value="" />
          </label>
          <button type="submit"><%= action_button_label(@scheduled_execution) %></button>
        </form>

        <div :if={show_action_form?(@scheduled_execution) and not @rulestead_admin_policy_state.capabilities.execute? and not @rulestead_admin_policy_state.capabilities.admin?} class="rs-actions-disabled">
          <RulesteadAdmin.Components.OperatorComponents.capability_explanation
            title="Execution required"
            reason="You do not have permission to modify scheduled executions."
          />
        </div>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.schedule_path}>Back to schedule</a></li>
          <li><a href={@page.change_requests_path}>Open change requests</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li :if={@page.webhooks_path}><a href={@page.webhooks_path}>Open webhooks</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp index_path, do: "/admin/flags/schedule"
  defp change_requests_path, do: "/admin/flags/change-requests"
  defp audit_path, do: "/admin/flags/audit"

  defp navigation_links(socket, current) do
    [
      nav_link("Flags", Session.current_path(socket, mount_path(socket)), current == :flags),
      nav_link(
        "Change requests",
        Session.current_path(socket, change_requests_path()),
        current == :change_requests
      ),
      nav_link("Schedule", Session.current_path(socket, index_path()), current == :schedule),
      nav_link(
        "Webhooks",
        Session.current_path(socket, "/admin/flags/webhooks"),
        current == :webhooks
      ),
      nav_link("Audit", Session.current_path(socket, audit_path()), current == :audit)
    ]
  end

  defp nav_link(label, path, current?), do: %{label: label, path: path, current?: current?}

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp build_page(socket, scheduled_execution, id) do
    base_path = "#{index_path()}/#{id}"

    socket.assigns
    |> Session.placeholder_assigns(
      current_path: base_path,
      page_title: "Scheduled execution",
      page_kicker: "Scheduled changes",
      page_summary:
        "Execution detail route for state, actor chain, related change request, and explicit follow-up actions."
    )
    |> Map.merge(%{
      navigation_links: navigation_links(socket, :schedule),
      schedule_path: Session.current_path(socket, index_path()),
      change_requests_path: Session.current_path(socket, change_requests_path()),
      audit_path: Session.current_path(socket, audit_path()),
      error_message: nil,
      scheduled_execution_id: id,
      change_request_path:
        if(scheduled_execution && scheduled_execution.change_request_id,
          do:
            Session.current_path(
              socket,
              "#{change_requests_path()}/#{scheduled_execution.change_request_id}"
            )
        ),
      flag_path:
        if(scheduled_execution && scheduled_execution.resource_key,
          do:
            Session.current_path(
              socket,
              "#{mount_path(socket)}/#{scheduled_execution.resource_key}"
            )
        ),
      webhooks_path: Session.current_path(socket, "/admin/flags/webhooks")
    })
  end

  defp load_scheduled_execution(id) do
    case Rulestead.fetch_scheduled_execution(Command.FetchScheduledExecution.new(id)) do
      {:ok, %{scheduled_execution: scheduled_execution}} -> {scheduled_execution, nil}
      {:error, error} -> {nil, error.message}
    end
  end

  defp cancel_scheduled_execution(socket, reason) do
    command =
      Command.CancelScheduledExecution.new(socket.assigns.scheduled_execution.id,
        actor: socket.assigns.current_actor,
        reason: reason,
        metadata: %{source: :admin_ui}
      )

    mutate_scheduled_execution(
      socket,
      command,
      &Rulestead.cancel_scheduled_execution/1,
      "Scheduled execution cancelled. #{reason}"
    )
  end

  defp requeue_scheduled_execution(socket, reason) do
    command =
      Command.RequeueScheduledExecution.new(socket.assigns.scheduled_execution.id,
        actor: socket.assigns.current_actor,
        reason: reason,
        metadata: %{source: :admin_ui}
      )

    mutate_scheduled_execution(
      socket,
      command,
      &Rulestead.requeue_scheduled_execution/1,
      "Scheduled execution requeued. #{reason}"
    )
  end

  defp mutate_scheduled_execution(socket, command, operation, notice) do
    case operation.(command) do
      {:ok, %{scheduled_execution: scheduled_execution}} ->
        {:noreply,
         socket
         |> assign(:scheduled_execution, scheduled_execution)
         |> assign(:action_notice, notice)
         |> assign(:action_error, nil)
         |> assign(:page, build_page(socket, scheduled_execution, scheduled_execution.id))}

      {:error, error} ->
        {:noreply, socket |> assign(:action_notice, nil) |> assign(:action_error, error.message)}
    end
  end

  defp normalize_reason(nil), do: nil

  defp normalize_reason(reason) when is_binary(reason) do
    case String.trim(reason) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_reason(_reason), do: nil

  defp show_action_form?(%{state: state}) when state in [:scheduled, :quarantined], do: true
  defp show_action_form?(_scheduled_execution), do: false

  defp action_button_label(%{state: :scheduled}), do: "Cancel execution"
  defp action_button_label(%{state: :quarantined}), do: "Requeue execution"
  defp action_button_label(_scheduled_execution), do: "Update execution"

  defp action_panel_title(%{state: :quarantined}), do: "Retry path"

  defp action_panel_title(%{state: state}) when state in [:failed, :completed, :cancelled],
    do: "History only"

  defp action_panel_title(_scheduled_execution), do: "Execution controls"

  defp action_panel_copy(%{state: :scheduled}),
    do: "Cancellation is only available while the execution is still queued."

  defp action_panel_copy(%{state: :quarantined}),
    do: "Requeue execution after documenting why the run is safe to retry."

  defp action_panel_copy(%{state: :failed}), do: "Read-only recovery guidance"
  defp action_panel_copy(%{state: :completed}), do: "History only"
  defp action_panel_copy(%{state: :cancelled}), do: "History only"
  defp action_panel_copy(_scheduled_execution), do: "Read-only recovery guidance"

  defp show_executed_by?(%{execution_mode: :change_request}), do: true

  defp show_executed_by?(%{attempt_count: attempt_count, executed_at: executed_at})
       when attempt_count > 0 or not is_nil(executed_at),
       do: true

  defp show_executed_by?(_scheduled_execution), do: false

  defp actor_name(actor) when is_map(actor),
    do: Map.get(actor, "display") || Map.get(actor, "id") || "Unknown actor"

  defp actor_name(_actor), do: "Unknown actor"

  defp joined_actor_names(actors),
    do: actors |> Enum.map(&actor_name/1) |> Enum.reject(&is_nil/1) |> Enum.join(", ")

  defp humanize(value) when is_atom(value), do: humanize(Atom.to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp format_datetime(nil), do: "Not yet recorded"

  defp format_datetime(%DateTime{} = datetime),
    do: "#{Calendar.strftime(datetime, "%Y-%m-%d %H:%M")} UTC"

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

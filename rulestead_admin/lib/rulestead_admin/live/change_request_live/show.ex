# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.ChangeRequestLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.GovernanceComponents
  alias RulesteadAdmin.Components.OperatorComponents
  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.AudienceLive.Governance
  alias RulesteadAdmin.Live.AudienceLive.Shared
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:change_request_id, nil)
     |> assign(:change_request, nil)
     |> assign(:approvals, [])
     |> assign(:audit_events, [])
     |> assign(:pending_action, nil)
     |> assign(:action_notice, nil)
     |> assign(:action_error, nil)
     |> assign(:governance_metadata, %{})
     |> assign(:blast_radius_assessment, nil)
     |> assign(:approve_blocked_reason, nil)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    base_path = "#{index_path()}/#{id}"
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path))}
    else
      {change_request, approvals, audit_events, error_message} = load_change_request(id)

      page =
        socket
        |> build_page(change_request, id)
        |> Map.put(:error_message, error_message)

      {:noreply,
       socket
       |> assign(:change_request_id, id)
       |> assign(:change_request, change_request)
       |> assign(:approvals, approvals)
       |> assign(:audit_events, audit_events)
       |> assign(:pending_action, nil)
       |> assign(:action_notice, nil)
       |> assign(:action_error, nil)
       |> assign_governance_review(change_request)
       |> assign(:page, page)}
    end
  end

  @impl true
  def handle_event("start_action", %{"action" => action}, socket) do
    {:noreply, socket |> assign(:pending_action, action) |> assign(:action_error, nil)}
  end

  @impl true
  def handle_event("cancel_action", _params, socket) do
    {:noreply, socket |> assign(:pending_action, nil) |> assign(:action_error, nil)}
  end

  @impl true
  def handle_event("submit_action", %{"action" => params}, socket) do
    reason = normalize_reason(Map.get(params, "reason"))

    cond do
      is_nil(socket.assigns.pending_action) ->
        {:noreply,
         assign(socket, :action_error, "Choose an action before submitting confirmation")}

      is_nil(reason) ->
        {:noreply, assign(socket, :action_error, "Enter a reason before continuing")}

      true ->
        submit_action(socket, socket.assigns.pending_action, params, reason)
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
      current_section={:change_requests}
      policy_state={@page.policy_state}
    >
      <p :if={@page.error_message} role="alert"><%= @page.error_message %></p>

      <section :if={@change_request} class="rs-card">
        <h2>Proposed change</h2>
        <p><strong><%= diff_title(@change_request) %></strong></p>
        <p><%= diff_summary(@change_request) %></p>
      </section>

      <section :if={@blast_radius_assessment}>
        <GovernanceComponents.blast_radius_panel
          assessment={@blast_radius_assessment}
          variant={:reviewer}
          visibility={:full}
          frozen?={true}
        />
      </section>

      <section :if={@change_request} class="rs-card">
        <h2>Review context</h2>
        <p class="hidden">requested by <%= actor_name(@change_request.submitted_by) %></p>
        <p class="hidden">Status: <%= humanize(@change_request.state) %></p>
        <p class="hidden">Required approvals: <%= @change_request.approval_requirement.required_approvals %></p>
        <OperatorComponents.detail_grid rows={review_context_rows(@change_request, @approvals)} />
      </section>

      <section :if={@change_request} class="rs-card">
        <h2>Simulation and audit context</h2>
        <p>Diff and operator state stay above the fold; simulation and audit context explain why this request is safe to continue.</p>
        <p :if={@audit_events != []}>Audit state: <%= latest_audit_state(@audit_events) %></p>
        <p :if={@audit_events == []}>No audit events have been recorded for this request yet.</p>
      </section>

      <section :if={@change_request} class="rs-card">
        <h2>Review actions</h2>
        <p>Preview, confirm, and audit are kept separate so reviewers can see exactly what will happen before mutation.</p>
        <p :if={@action_notice} role="status"><%= @action_notice %></p>
        <p :if={@action_error} role="alert"><%= @action_error %></p>

        <OperatorComponents.capability_explanation
          :if={
            @change_request.state == :submitted and not is_nil(@approve_blocked_reason) and
              (@rulestead_admin_policy_state.capabilities.execute? or
                 @rulestead_admin_policy_state.capabilities.admin?)
          }
          title="Broader flag read access required to approve this change."
          reason={@approve_blocked_reason}
        />

        <div :if={is_nil(@pending_action) and (@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?)} class="rs-detail__actions">
          <button
            :if={@change_request.state == :submitted and is_nil(@approve_blocked_reason)}
            type="button"
            phx-click="start_action"
            phx-value-action="approve"
          >
            Approve
          </button>
          <button
            :if={@change_request.state == :submitted}
            type="button"
            phx-click="start_action"
            phx-value-action="reject"
          >
            Reject
          </button>
          <button
            :if={@change_request.state == :approved}
            type="button"
            phx-click="start_action"
            phx-value-action="execute"
          >
            Execute now
          </button>
          <button
            :if={@change_request.state == :approved}
            type="button"
            phx-click="start_action"
            phx-value-action="schedule"
          >
            Schedule
          </button>
        </div>

        <div :if={is_nil(@pending_action) and not @rulestead_admin_policy_state.capabilities.execute? and not @rulestead_admin_policy_state.capabilities.admin?} class="rs-actions-disabled">
          <RulesteadAdmin.Components.OperatorComponents.capability_explanation
            title="Execution required"
            reason="You do not have permission to execute or approve change requests."
          />
        </div>

        <form
          :if={not is_nil(@pending_action) and (@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?)}
          id="change-request-action-form"
          phx-submit="submit_action"
          class="rs-inline-action-form"
        >
          <p>Confirm <%= humanize(@pending_action) %> before mutation.</p>
          <label>
            <span>Reason</span>
            <input type="text" name="action[reason]" value="" />
          </label>
          <label :if={@pending_action == "schedule"}>
            <span>Scheduled for</span>
            <input type="datetime-local" name="action[scheduled_for]" value="2026-04-25T16:00" />
          </label>
          <button type="submit">Confirm <%= humanize(@pending_action) %></button>
          <button type="button" phx-click="cancel_action">Back to preview</button>
        </form>
      </section>

      <section class="rs-page-section">
        <h2>Related routes</h2>
        <OperatorComponents.related_links links={related_links(@page)} />
      </section>
    </Shell.page>
    """
  end

  defp index_path, do: "/admin/flags/change-requests"
  defp schedule_path, do: "/admin/flags/schedule"
  defp audit_path, do: "/admin/flags/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp build_page(socket, change_request, id, scheduled_execution_id \\ nil) do
    base_path = "#{index_path()}/#{id}"

    socket.assigns
    |> Session.placeholder_assigns(
      current_path: base_path,
      page_title: "Change request review",
      page_kicker: "Governance",
      page_summary:
        "Dedicated review route for proposed changes, approval state, and explicit next-step execution decisions."
    )
    |> Map.merge(%{
      queue_path: Session.current_path(socket, index_path()),
      schedule_path: Session.current_path(socket, schedule_path()),
      audit_path: Session.current_path(socket, audit_path()),
      request_id: id,
      error_message: nil,
      flag_path:
        if(change_request && change_request.resource_key,
          do: Session.current_path(socket, "#{mount_path(socket)}/#{change_request.resource_key}")
        ),
      scheduled_execution_path:
        if(scheduled_execution_id,
          do: Session.current_path(socket, "#{schedule_path()}/#{scheduled_execution_id}")
        ),
      webhooks_path: Session.current_path(socket, "/admin/flags/webhooks")
    })
  end

  defp review_context_rows(change_request, approvals) do
    [
      %{label: "Status", value: humanize(change_request.state)},
      %{label: "Action", value: humanize(change_request.action)},
      %{label: "Resource", value: change_request.resource_key},
      %{label: "Environment", value: change_request.environment_key},
      %{label: "requested by", value: actor_name(change_request.submitted_by)},
      %{
        label: "Required approvals",
        value: to_string(change_request.approval_requirement.required_approvals)
      },
      %{
        label: "Approved by",
        value: if(approvals == [], do: "No approvals yet", else: joined_reviewers(approvals))
      }
    ]
  end

  defp related_links(page) do
    [
      %{label: "Back to change requests", path: page.queue_path},
      %{label: "Open schedule", path: page.schedule_path},
      %{label: "Open audit timeline", path: page.audit_path},
      if(page.flag_path, do: %{label: "Open flag", path: page.flag_path}),
      if(page.scheduled_execution_path,
        do: %{label: "Open scheduled execution", path: page.scheduled_execution_path}
      ),
      if(page.webhooks_path, do: %{label: "Open webhooks", path: page.webhooks_path})
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp load_change_request(id) do
    case Rulestead.fetch_change_request(Command.FetchChangeRequest.new(id)) do
      {:ok, %{change_request: change_request, approvals: approvals, audit_events: audit_events}} ->
        {change_request, approvals, audit_events, nil}

      {:error, error} ->
        {nil, [], [], error.message}
    end
  end

  defp submit_action(socket, "approve", _params, reason) do
    command =
      Command.ApproveChangeRequest.new(socket.assigns.change_request_id,
        actor: socket.assigns.current_actor,
        reason: reason,
        metadata: %{source: :admin_ui}
      )

    mutate_change_request(
      socket,
      &Rulestead.approve_change_request/1,
      command,
      "Change request approved."
    )
  end

  defp submit_action(socket, "reject", _params, reason) do
    command =
      Command.RejectChangeRequest.new(socket.assigns.change_request_id,
        actor: socket.assigns.current_actor,
        reason: reason,
        metadata: %{source: :admin_ui}
      )

    mutate_change_request(
      socket,
      &Rulestead.reject_change_request/1,
      command,
      "Change request rejected."
    )
  end

  defp submit_action(socket, "execute", _params, reason) do
    command =
      Command.ExecuteChangeRequest.new(socket.assigns.change_request_id,
        actor: socket.assigns.current_actor,
        reason: reason,
        metadata: %{source: :admin_ui}
      )

    mutate_change_request(
      socket,
      &Rulestead.execute_change_request/1,
      command,
      "Change request executed."
    )
  end

  defp submit_action(socket, "schedule", params, reason) do
    with {:ok, scheduled_for} <- parse_scheduled_for(Map.get(params, "scheduled_for")) do
      command =
        Command.ScheduleChangeRequest.new(%{
          change_request_id: socket.assigns.change_request_id,
          scheduled_for: scheduled_for,
          actor: socket.assigns.current_actor,
          reason: reason,
          metadata: %{source: :admin_ui}
        })

      case Rulestead.schedule_change_request(command) do
        {:ok, %{scheduled_execution: scheduled_execution}} ->
          {change_request, approvals, audit_events, _error} =
            load_change_request(socket.assigns.change_request_id)

          {:noreply,
           socket
           |> assign(:change_request, change_request)
           |> assign(:approvals, approvals)
           |> assign(:audit_events, audit_events)
           |> assign(:pending_action, nil)
           |> assign(:action_error, nil)
           |> assign(
             :action_notice,
             "Change request scheduled. Audit state: #{latest_audit_state(audit_events)}"
           )
           |> assign(
             :page,
             build_page(socket, change_request, change_request.id, scheduled_execution.id)
           )}

        {:error, error} ->
          {:noreply, assign(socket, :action_error, error.message)}
      end
    else
      {:error, message} -> {:noreply, assign(socket, :action_error, message)}
    end
  end

  defp submit_action(socket, _action, _params, _reason) do
    {:noreply, assign(socket, :action_error, "Unsupported review action")}
  end

  defp mutate_change_request(socket, operation, command, notice) do
    case operation.(command) do
      {:ok, %{change_request: change_request}} ->
        {_reloaded_change_request, approvals, audit_events, _error} =
          load_change_request(change_request.id)

        {:noreply,
         socket
         |> assign(:change_request, change_request)
         |> assign(:approvals, approvals)
         |> assign(:audit_events, audit_events)
         |> assign(:pending_action, nil)
         |> assign(:action_error, nil)
         |> assign(:action_notice, "#{notice} Audit state: #{latest_audit_state(audit_events)}")
         |> assign(:page, build_page(socket, change_request, change_request.id))}

      {:error, error} ->
        {:noreply, assign(socket, :action_error, error.message)}
    end
  end

  defp diff_title(%{action: :apply_audience_mutation} = change_request) do
    operation = command_field(change_request.command, "operation")
    audience_key = command_field(change_request.command, "audience_key")

    "Audience #{humanize(operation)} · #{audience_key || change_request.resource_key}"
  end

  defp diff_title(change_request) do
    get_in(change_request.command, ["diff", "title"]) || "Governed mutation preview"
  end

  defp diff_summary(%{action: :apply_audience_mutation} = change_request) do
    operation = command_field(change_request.command, "operation")
    audience_key = command_field(change_request.command, "audience_key")
    environment = change_request.environment_key

    "Proposed #{humanize(operation)} for audience #{audience_key || change_request.resource_key} in #{environment}."
  end

  defp diff_summary(change_request) do
    get_in(change_request.command, ["diff", "summary"]) || "No diff summary was recorded."
  end

  defp assign_governance_review(socket, %{action: :apply_audience_mutation} = change_request) do
    metadata = change_request.metadata || %{}
    assessment = Map.get(metadata, "blast_radius_assessment")
    tier = audience_visibility_tier(socket, change_request.resource_key)

    approve_blocked_reason =
      if tier != :full do
        "At least one affected reference is hidden by your permissions. Broader flag read access is required to approve this change."
      end

    socket
    |> assign(:governance_metadata, metadata)
    |> assign(:blast_radius_assessment, assessment)
    |> assign(:approve_blocked_reason, approve_blocked_reason)
  end

  defp assign_governance_review(socket, _change_request) do
    socket
    |> assign(:governance_metadata, %{})
    |> assign(:blast_radius_assessment, nil)
    |> assign(:approve_blocked_reason, nil)
  end

  defp audience_visibility_tier(socket, audience_key) when is_binary(audience_key) do
    deps_result =
      Rulestead.list_audience_dependencies(Shared.dependency_command(socket, audience_key))

    inventory = normalize_dependency_inventory(deps_result)
    Governance.visibility_tier(inventory)
  end

  defp audience_visibility_tier(_socket, _audience_key), do: :full

  defp normalize_dependency_inventory({:ok, result}) do
    %{
      summary: Shared.dependency_summary(result),
      entries: Map.get(result, :entries, []),
      redacted_entries: Map.get(result, :redacted_entries, []),
      hidden_count: Map.get(result, :hidden_reference_count, 0),
      denied?: false
    }
  end

  defp normalize_dependency_inventory({:error, error}) do
    if auth_error?(error) do
      %{
        summary: "Dependency list unavailable",
        entries: [],
        redacted_entries: [],
        hidden_count: 0,
        denied?: true
      }
    else
      %{
        summary: "Dependency list unavailable",
        entries: [],
        redacted_entries: [],
        hidden_count: 0,
        denied?: false
      }
    end
  end

  defp auth_error?(%{domain: :auth}), do: true
  defp auth_error?(%{domain: "auth"}), do: true
  defp auth_error?(_), do: false

  defp command_field(command, key) when is_map(command) do
    Map.get(command, key) || Map.get(command, String.to_atom(key))
  end

  defp command_field(_command, _key), do: nil

  defp actor_name(actor) when is_map(actor),
    do: actor[:display] || actor["display"] || actor[:id] || actor["id"] || "Unknown operator"

  defp actor_name(_actor), do: "Unknown operator"

  defp joined_reviewers(approvals),
    do: Enum.map_join(approvals, ", ", &actor_name(&1.reviewed_by))

  defp latest_audit_state([event | _]), do: event.event_type
  defp latest_audit_state([]), do: "pending"

  defp parse_scheduled_for(nil), do: {:error, "Choose when the change should run"}
  defp parse_scheduled_for(""), do: {:error, "Choose when the change should run"}

  defp parse_scheduled_for(value) do
    case NaiveDateTime.from_iso8601(value <> ":00") do
      {:ok, naive} -> {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
      _ -> {:error, "Choose a valid schedule time"}
    end
  end

  defp normalize_reason(nil), do: nil
  defp normalize_reason(""), do: nil
  defp normalize_reason(reason), do: String.trim(reason)

  defp humanize(value) when is_atom(value), do: humanize(Atom.to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

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

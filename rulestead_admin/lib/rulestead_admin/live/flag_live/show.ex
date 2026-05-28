defmodule RulesteadAdmin.Live.FlagLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:detail, nil)
     |> assign(:change_request_preview, [])
     |> assign(:scheduled_execution_preview, [])
     |> assign(:error_message, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(params, uri, socket) do
    query = query_params(uri)
    key = params["key"]
    env = query["env"] || socket.assigns.current_environment.key
    base_path = detail_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(
        :return_to,
        Session.canonical_return_to(
          socket,
          query["return_to"],
          socket.assigns.rulestead_admin_mount_path
        )
      )
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(
        :env_links,
        Session.env_links(socket, base_path, %{"return_to" => query["return_to"]})
      )
      |> load_detail(key, env)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker="Flag detail"
      page_summary="Calm read surface for flag metadata, lifecycle, and environment rules status."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a href={@return_to}>Back to queue</a>
      </:header_actions>

      <OperatorComponents.policy_state policy_state={@rulestead_admin_policy_state} />

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@detail} class="rs-detail">
        <div class="rs-detail__actions">
          <a :if={@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?} href={path_for(assigns, "/#{@detail.flag.key}/edit")}>Edit metadata</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/rules")}>Open rules workspace</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/simulate")}>Simulate</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/explain")}>Explain</a>
          <a href={path_for(assigns, "/audiences")}>Audiences</a>
          <a :if={@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?} href={path_for(assigns, "/#{@detail.flag.key}/kill")}>Open kill switch</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}>Review cleanup</a>
          <a href={path_for(assigns, "/#{@detail.flag.key}/timeline")}>Open audit timeline</a>
        </div>

        <AuditComponents.kill_switch_banner
          :if={kill_switch_active?(@detail)}
          active?={true}
          flag_key={@detail.flag.key}
          environment_name={@detail.environment.name}
          reason={latest_reason(@detail, @current_actor)}
          kill_path={path_for(assigns, "/#{@detail.flag.key}/kill")}
          timeline_path={path_for(assigns, "/#{@detail.flag.key}/timeline")}
          show_release_button={@rulestead_admin_policy_state.capabilities.execute? or @rulestead_admin_policy_state.capabilities.admin?}
        />

        <div class="rs-detail__hero">
          <div>
            <h2><code><%= @detail.flag.key %></code></h2>
            <p><%= @detail.flag.description %></p>
            <FlagComponents.tag_list tags={@detail.flag.tags} />
          </div>
          <div class="rs-detail__stats">
            <FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} tone="neutral" />
            <FlagComponents.stat
              title="Archive readiness"
              value={humanize(archive_readiness(@detail).readiness)}
              tone="neutral"
            />
            <FlagComponents.stat
              title="Evidence quality"
              value={humanize(archive_readiness(@detail).evidence_quality)}
              tone="neutral"
            />
            <FlagComponents.stat title="Owner" value={@detail.flag.ownership.owner_display || @detail.flag.ownership.owner_ref} tone="neutral" />
            <FlagComponents.stat
              title="Review by"
              value={@detail.lifecycle.review_by || "Not scheduled"}
              tone="neutral"
            />
            <FlagComponents.stat title="Type" value={humanize(@detail.flag.flag_type)} tone="neutral" />
            <FlagComponents.stat title="Value type" value={humanize(@detail.flag.value_type)} tone="neutral" />
            <FlagComponents.stat
              title="Default value"
              value={inspect(default_flag_value(@detail.flag.default_value))}
              tone="neutral"
            />
            <FlagComponents.stat
              title="Code references"
              value={humanize(freshness(@detail).code_references)}
              tone="neutral"
            />
            <FlagComponents.stat title="Environment status" value={humanize(@detail.flag_environment.status)} tone="neutral" />
          </div>
        </div>

        <FlagComponents.section_card title="Lifecycle posture">
          <p>
            <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
            <%= if @detail.lifecycle.state in [:stale, :potentially_stale] do %>
              <a href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}>
                <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
              </a>
            <% else %>
              <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
            <% end %>
            <span>Owner: <%= @detail.flag.ownership.owner_display || @detail.flag.ownership.owner_ref %></span>
          </p>
          <p>
            Lifecycle posture: <%= humanize(@detail.lifecycle.mode) %>
          </p>
          <p>
            Review by: <%= @detail.lifecycle.review_by || "Not scheduled" %>
          </p>
          <p>
            Suggested by: <%= humanize(@detail.lifecycle.default_source) %>
          </p>
          <p :if={@detail.lifecycle.default_overridden}>
            The operator overrode the suggested lifecycle default.
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Archive readiness guidance">
          <p>
            <FlagComponents.readiness_badge readiness={archive_readiness(@detail).readiness} />
            <FlagComponents.evidence_quality_badge quality={archive_readiness(@detail).evidence_quality} />
          </p>
          <p>
            <strong>Primary recommendation:</strong> <%= primary_action_label(archive_readiness(@detail)) %>
          </p>
          <p :if={guidance_limited?(archive_readiness(@detail))}>
            Guidance limited by missing evidence. Review this flag manually before choosing a cleanup path.
          </p>
          <p :if={archive_readiness(@detail).secondary_actions != []}>
            <strong>Secondary actions:</strong> <%= secondary_actions_label(archive_readiness(@detail).secondary_actions) %>
          </p>
          <p>
            <a href={path_for(assigns, "/#{@detail.flag.key}/cleanup")}>
              Review cleanup
            </a>
            to preserve this queue context before any archive flow.
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Evidence and uncertainty">
          <p><strong>Reasons:</strong> <%= joined_labels(archive_readiness(@detail).reasons, &reason_label/1, "No archive-positive signals yet.") %></p>
          <p><strong>Unknowns:</strong> <%= joined_labels(archive_readiness(@detail).unknowns, &unknown_label/1, "No known evidence gaps.") %></p>
          <p><strong>Blockers:</strong> <%= joined_labels(archive_readiness(@detail).blockers, &blocker_label/1, "No blockers identified.") %></p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Freshness evidence">
          <p><strong>Evaluation evidence:</strong> <%= freshness(@detail).evaluation |> humanize() %></p>
          <p><strong>Code-reference evidence:</strong> <%= freshness(@detail).code_references |> humanize() %></p>
          <p><strong>Latest scan receipt:</strong> <%= scan_label(freshness(@detail).code_refs_scan) %></p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Ownership">
          <p>Reference: <code><%= @detail.lifecycle.owner_ref || "Not set" %></code></p>
          <p>Kind: <%= humanize(@detail.lifecycle.owner_kind) %></p>
          <p>Display snapshot: <%= @detail.lifecycle.owner_display || "Not set" %></p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Environment overview">
          <ul>
            <%= for card <- @detail.environment_cards do %>
              <li>
                <strong><%= card.environment.name %></strong>
                <FlagComponents.environment_status status={card.flag_environment.status} />
                <span><%= humanize(card.lifecycle.state) %></span>
              </li>
            <% end %>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Rules status">
          <div>
            <h3>Active ruleset</h3>
            <p :if={@detail.active_ruleset}>Version <%= @detail.active_ruleset.version %></p>
            <p :if={is_nil(@detail.active_ruleset)}>No published ruleset yet.</p>
          </div>

          <div :if={@detail.has_draft_ruleset?}>
            <h3>Draft ruleset</h3>
            <p>Version <%= List.first(@detail.draft_rulesets).version %></p>
            <p>Draft changes exist for <%= @detail.environment.name %>. Use the dedicated workspace to review and publish.</p>
          </div>

          <div :if={!@detail.has_draft_ruleset?}>
            <h3>Draft ruleset</h3>
            <p>No draft ruleset for <%= @detail.environment.name %>.</p>
          </div>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Open change requests">
          <p :if={@change_request_preview == []}>
            No open change requests for this flag in <%= @current_environment.name %>.
          </p>

          <ul :if={@change_request_preview != []}>
            <li :for={entry <- @change_request_preview}>
              <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
            </li>
          </ul>

          <p>
            <a href={path_for(assigns, "/change-requests")}>Open change requests</a>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Scheduled changes">
          <p :if={@scheduled_execution_preview == []}>
            No scheduled changes for this flag in <%= @current_environment.name %>.
          </p>

          <ul :if={@scheduled_execution_preview != []}>
            <li :for={entry <- @scheduled_execution_preview}>
              <a href={entry.path}><%= humanize(entry.state) %> · <%= entry.title %></a>
            </li>
          </ul>

          <p>
            <a href={path_for(assigns, "/schedule")}>Scheduled changes</a>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Audit">
          <p>This screen stays focused on current state. Use the dedicated timeline for append-only history and rollback context.</p>
        </FlagComponents.section_card>
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("release_kill_switch", _params, socket) do
    case Rulestead.release_kill_switch(
           socket.assigns.flag_key,
           socket.assigns.current_environment.key,
           socket.assigns.current_actor,
           reason: "Released from flag detail banner"
         ) do
      {:ok, _payload} ->
        {:noreply,
         socket
         |> assign(:error_message, nil)
         |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}

      {:error, error} ->
        {:noreply, assign(socket, :error_message, error.message)}
    end
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        assign(socket, :detail, detail)
        |> assign(:change_request_preview, load_change_request_preview(key, env))
        |> assign(:scheduled_execution_preview, load_scheduled_execution_preview(key, env))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:change_request_preview, [])
        |> assign(:scheduled_execution_preview, [])
        |> assign(:error_message, error.message)
    end
  end

  defp load_change_request_preview(flag_key, env) do
    case Rulestead.list_change_requests(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.filter(&(&1.state in [:submitted, :approved]))
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: get_in(entry.command, ["diff", "title"]) || humanize(entry.action),
            path: "/admin/flags/change-requests/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
  end

  defp default_flag_value(%{value: value}), do: value
  defp default_flag_value(%{"value" => value}), do: value
  defp default_flag_value(value), do: value

  defp load_scheduled_execution_preview(flag_key, env) do
    case Rulestead.list_scheduled_executions(environment_key: env, resource_key: flag_key) do
      {:ok, page} ->
        page.entries
        |> Enum.take(3)
        |> Enum.map(fn entry ->
          %{
            state: entry.state,
            title: "#{humanize(entry.action)} at #{format_schedule(entry.scheduled_for)}",
            path: "/admin/flags/schedule/#{entry.id}?env=#{env}"
          }
        end)

      _ ->
        []
    end
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

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp page_title(%{flag_key: flag_key}) when is_binary(flag_key), do: flag_key
  defp page_title(_assigns), do: "Flag detail"

  defp kill_switch_active?(detail), do: detail.flag_environment.status == :killswitched
  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness
  defp freshness(detail), do: detail.lifecycle.freshness

  defp latest_reason(detail, actor) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: actor
           ),
         event when is_map(event) <-
           Enum.find(
             page.entries,
             &(&1.event_type in ["kill_switch.engage", "kill_switch.release"])
           ) do
      event.reason
    else
      _ -> nil
    end
  end

  defp detail_base_path(socket, key), do: admin_base_path(socket, "/#{key}")

  defp path_for(socket, suffix) do
    Session.path_with_return_to(
      socket,
      admin_base_path(socket, suffix),
      fetch_return_to(socket)
    )
  end

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp fetch_return_to(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns.return_to
  defp fetch_return_to(%{return_to: return_to}), do: return_to

  defp format_schedule(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_schedule(_datetime), do: "pending"

  defp primary_action_label(%{recommended_next_action: nil}),
    do: "No primary recommendation yet."

  defp primary_action_label(%{recommended_next_action: action}),
    do: action_label(action)

  defp secondary_actions_label(actions) do
    actions
    |> Enum.map_join(", ", &action_label/1)
  end

  defp guidance_limited?(%{evidence_quality: :weak}), do: true
  defp guidance_limited?(%{recommended_next_action: nil}), do: true
  defp guidance_limited?(_archive_readiness), do: false

  defp joined_labels([], _mapper, fallback), do: fallback

  defp joined_labels(values, mapper, _fallback) do
    values
    |> Enum.map_join(", ", mapper)
  end

  defp reason_label(:expiring_posture), do: "Expiring posture authored"
  defp reason_label(:review_horizon_passed), do: "Review horizon passed"
  defp reason_label(:stale_evaluation), do: "Evaluation has not run recently"
  defp reason_label(:never_evaluated), do: "Evaluation has never run"
  defp reason_label(:no_code_refs), do: "Fresh scan found no code references"
  defp reason_label(:already_archived), do: "Already archived"
  defp reason_label(reason), do: humanize(reason)

  defp unknown_label(:code_refs_scan_missing), do: "Code-reference scan receipt is missing"
  defp unknown_label(:code_refs_scan_stale), do: "Code-reference scan receipt is stale"
  defp unknown_label(:evaluation_missing), do: "Evaluation evidence is missing"
  defp unknown_label(reason), do: humanize(reason)

  defp blocker_label(:protected_flag_type), do: "Protected flag type resists archival"
  defp blocker_label(:permanent_posture), do: "Permanent posture keeps this flag active"

  defp blocker_label(:remote_config_requires_review),
    do: "Remote config flags require stronger review"

  defp blocker_label(:code_refs_present), do: "Code references are still present"
  defp blocker_label(:already_archived), do: "Already archived"
  defp blocker_label(reason), do: humanize(reason)

  defp action_label(:archive_ready), do: "Archive when the review is complete"
  defp action_label(:keep_active), do: "Keep active"
  defp action_label(:review_manually), do: "Review manually"
  defp action_label(:refresh_code_refs), do: "Refresh code references"
  defp action_label(:collect_eval_evidence), do: "Collect evaluation evidence"
  defp action_label(:remove_code_refs), do: "Remove code references"
  defp action_label(:mark_permanent), do: "Mark permanent"
  defp action_label(action), do: humanize(action)

  defp scan_label(nil), do: "No code-reference scan receipt yet."

  defp scan_label(%{received_at: %DateTime{} = received_at, reference_count: reference_count}) do
    "Received #{DateTime.to_iso8601(received_at)} with #{reference_count} references."
  end

  defp scan_label(_scan), do: "Scan receipt unavailable."
end

defmodule RulesteadAdmin.Live.FlagLive.Cleanup do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session
  import Ecto.Query, only: [from: 2]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})
     |> assign(:error_message, nil)
     |> assign(:code_references, [])}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

    if not capabilities.edit? and not capabilities.execute? and not capabilities.admin? do
      {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      env = query_params(uri)["env"] || socket.assigns.current_environment.key
      base_path = build_base_path(socket, key)

      socket =
        socket
        |> assign(:flag_key, key)
        |> assign(:current_path, Session.current_path(socket, base_path))
        |> assign(:env_links, Session.env_links(socket, base_path))
        |> load_detail(key, env)
        |> load_code_references(key)

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} cleanup", else: "Cleanup")}
      page_kicker="Cleanup"
      page_summary="Advisory cleanup analysis for code references, blockers, and next steps. Phase 36 stays read-only."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a :if={@flag_key} href={path_for(assigns, "/#{@flag_key}")}>Back to detail</a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>

      <div :if={@detail}>
        <div class="rs-summary-grid" aria-label="Cleanup summary">
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
          <FlagComponents.stat
            title="Code references"
            value={humanize(freshness(@detail).code_references)}
            tone="neutral"
          />
          <FlagComponents.stat
            title="Evaluation evidence"
            value={humanize(freshness(@detail).evaluation)}
            tone="neutral"
          />
        </div>

        <FlagComponents.section_card title="Phase boundary">
          <p>Phase 36 keeps cleanup advisory only. Archive preview, confirmation, and mutation follow in a later phase.</p>
          <p :if={guidance_limited?(archive_readiness(@detail))}>
            Guidance limited by missing evidence. Review this flag manually before choosing a cleanup path.
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Recommended next action">
          <p>
            <FlagComponents.readiness_badge readiness={archive_readiness(@detail).readiness} />
            <FlagComponents.evidence_quality_badge quality={archive_readiness(@detail).evidence_quality} />
          </p>
          <p><strong>Primary recommendation:</strong> <%= primary_action_label(archive_readiness(@detail)) %></p>
          <p :if={archive_readiness(@detail).secondary_actions != []}>
            <strong>Secondary actions:</strong> <%= secondary_actions_label(archive_readiness(@detail).secondary_actions) %>
          </p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Evidence and uncertainty">
          <p><strong>Reasons:</strong> <%= joined_labels(archive_readiness(@detail).reasons, &reason_label/1, "No archive-positive signals yet.") %></p>
          <p><strong>Unknowns:</strong> <%= joined_labels(archive_readiness(@detail).unknowns, &unknown_label/1, "No known evidence gaps.") %></p>
          <p><strong>Blockers:</strong> <%= joined_labels(archive_readiness(@detail).blockers, &blocker_label/1, "No blockers identified.") %></p>
          <p><strong>Latest scan receipt:</strong> <%= scan_label(freshness(@detail).code_refs_scan) %></p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Code References">
          <p :if={Enum.empty?(@code_references)}>No known code references.</p>
          <ul :if={not Enum.empty?(@code_references)}>
            <li :for={ref <- @code_references}>
              <code>{ref.file}:{ref.line}</code>
            </li>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Current lifecycle posture">
          <p>
            <FlagComponents.lifecycle_badge state={@detail.lifecycle} />
            <FlagComponents.stale_badge state={@detail.lifecycle.state} last_evaluated_at={@detail.lifecycle.last_evaluated_at} />
          </p>
          <p><strong>Lifecycle posture:</strong> <%= humanize(@detail.lifecycle.mode) %></p>
          <p><strong>Review by:</strong> <%= @detail.lifecycle.review_by || "Not scheduled" %></p>
        </FlagComponents.section_card>
      </div>
    </Shell.page>
    """
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:detail, detail)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp load_code_references(socket, key) do
    if Code.ensure_loaded?(Rulestead.Repo) do
      try do
        query = from(c in Rulestead.CodeRefs.CodeReference, where: c.flag_key == ^key, order_by: [asc: c.file, asc: c.line])
        refs = Rulestead.Repo.all(query)
        assign(socket, :code_references, refs)
      rescue
        _ -> assign(socket, :code_references, [])
      end
    else
      assign(socket, :code_references, [])
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

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/cleanup")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness
  defp freshness(detail), do: detail.lifecycle.freshness

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp primary_action_label(%{recommended_next_action: nil}),
    do: "No primary recommendation yet."

  defp primary_action_label(%{recommended_next_action: action}),
    do: action_label(action)

  defp secondary_actions_label(actions) do
    actions
    |> Enum.map(&action_label/1)
    |> Enum.join(", ")
  end

  defp guidance_limited?(%{evidence_quality: :weak}), do: true
  defp guidance_limited?(%{recommended_next_action: nil}), do: true
  defp guidance_limited?(_archive_readiness), do: false

  defp joined_labels([], _mapper, fallback), do: fallback

  defp joined_labels(values, mapper, _fallback) do
    values
    |> Enum.map(mapper)
    |> Enum.join(", ")
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
  defp blocker_label(:remote_config_requires_review), do: "Remote config flags require stronger review"
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

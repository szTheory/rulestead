# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.CleanupPreview do
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
     |> assign(:return_to, nil)
     |> assign(:env_links, %{})
     |> assign(:error_message, nil)
     |> assign(:code_references, [])
     |> assign(:drift_message, nil)}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

    if not capabilities.execute? and not capabilities.admin? do
      {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      query = query_params(uri)
      env = query["env"] || socket.assigns.current_environment.key
      base_path = build_base_path(socket, key)

      socket =
        socket
        |> assign(:flag_key, key)
        |> assign(:current_path, Session.current_path(socket, base_path))
        |> assign(
          :return_to,
          Session.canonical_return_to(
            socket,
            query["return_to"],
            socket.assigns.rulestead_admin_mount_path
          )
        )
        |> assign(:env_links, Session.env_links(socket, base_path, %{"return_to" => query["return_to"]}))
        |> assign(:drift_message, drift_message(query["drifted"]))
        |> load_detail(key, env)
        |> load_code_references(key)

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} archive preview", else: "Archive preview")}
      page_kicker="Cleanup preview"
      page_summary="Route-backed archive preview for readiness, evidence quality, reasons, unknowns, blockers, and archive consequences."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a :if={@return_to} href={@return_to}>Back to queue</a>
        <a :if={@flag_key} href={path_for(assigns, "/#{@flag_key}/cleanup")}>Back to cleanup review</a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>

      <FlagComponents.callout :if={@drift_message} title="Preview refreshed" tone="warning">
        <p>{@drift_message}</p>
      </FlagComponents.callout>

      <div :if={@detail}>
        <div class="rs-summary-grid" aria-label="Archive preview summary">
          <FlagComponents.stat title="Lifecycle state" value={humanize(@detail.lifecycle.state)} tone="neutral" />
          <FlagComponents.stat title="Archive readiness" value={humanize(archive_readiness(@detail).readiness)} tone="neutral" />
          <FlagComponents.stat title="Evidence quality" value={humanize(archive_readiness(@detail).evidence_quality)} tone="neutral" />
          <FlagComponents.stat title="Recommended next action" value={primary_action_label(archive_readiness(@detail))} tone="neutral" />
        </div>

        <FlagComponents.callout title="Archive this flag" tone="warning">
          <p>Archive preview is explicit and never automatic. Operators choose whether to continue after reviewing the latest lifecycle evidence.</p>
          <p>
            <strong>What archive changes:</strong> the flag leaves default workbench queues, every mounted environment is marked archived, and the audit timeline records the operator reason without deleting history.
          </p>
        </FlagComponents.callout>

        <FlagComponents.section_card title="Reasons, unknowns, and blockers">
          <p><strong>Reasons:</strong> <%= joined_labels(archive_readiness(@detail).reasons, &reason_label/1, "No archive-positive signals yet.") %></p>
          <p><strong>Unknowns:</strong> <%= joined_labels(archive_readiness(@detail).unknowns, &unknown_label/1, "No known evidence gaps.") %></p>
          <p><strong>Blockers:</strong> <%= joined_labels(archive_readiness(@detail).blockers, &blocker_label/1, "No blockers identified.") %></p>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Evidence quality and code references">
          <p><strong>Code references:</strong> <%= humanize(freshness(@detail).code_references) %></p>
          <p><strong>Latest scan receipt:</strong> <%= scan_label(freshness(@detail).code_refs_scan) %></p>
          <p :if={Enum.empty?(@code_references)}>No code references were found in the latest review payload.</p>
          <ul :if={not Enum.empty?(@code_references)}>
            <li :for={ref <- @code_references}>
              <code>{ref.file}:{ref.line}</code>
            </li>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Decision point">
          <p>Archive consequences stay explicit on this route. Continue only when the current readiness, evidence quality, and blockers match your intent.</p>
          <p>
            <a href={confirm_path(assigns)}>Continue to archive confirmation</a>
          </p>
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
        query =
          from(c in Rulestead.CodeRefs.CodeReference,
            where: c.flag_key == ^key,
            order_by: [asc: c.file, asc: c.line]
          )

        assign(socket, :code_references, Rulestead.Repo.all(query))
      rescue
        _ -> assign(socket, :code_references, [])
      end
    else
      assign(socket, :code_references, [])
    end
  end

  defp confirm_path(socket_or_assigns) do
    Session.path_with_return_to(
      socket_or_assigns,
      admin_base_path(socket_or_assigns, "/#{socket_or_assigns.flag_key}/cleanup/confirm"),
      fetch_return_to(socket_or_assigns)
    )
    |> append_params(%{"preview_signature" => preview_signature(socket_or_assigns.detail)})
  end

  defp preview_signature(detail) do
    payload = %{
      lifecycle_state: detail.lifecycle.state,
      readiness: archive_readiness(detail).readiness,
      evidence_quality: archive_readiness(detail).evidence_quality,
      recommended_next_action: archive_readiness(detail).recommended_next_action,
      reasons: archive_readiness(detail).reasons,
      unknowns: archive_readiness(detail).unknowns,
      blockers: archive_readiness(detail).blockers
    }

    payload
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp append_params(path, params) do
    parsed = URI.parse(path)

    query =
      parsed.query
      |> case do
        nil -> %{}
        value -> URI.decode_query(value)
      end
      |> Map.merge(params)
      |> URI.encode_query()

    %{parsed | query: query}
    |> URI.to_string()
  end

  defp drift_message("true"),
    do: "Cleanup evidence changed before archive confirmation. Review the latest preview before archiving."

  defp drift_message(_value), do: nil

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/cleanup/preview")

  defp path_for(socket, suffix) do
    Session.path_with_return_to(socket, admin_base_path(socket, suffix), fetch_return_to(socket))
  end

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp fetch_return_to(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns.return_to
  defp fetch_return_to(%{return_to: return_to}), do: return_to

  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness
  defp freshness(detail), do: detail.lifecycle.freshness

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))
  defp humanize(value) when is_binary(value), do: value |> String.replace("_", " ") |> String.capitalize()
  defp humanize(value), do: to_string(value)

  defp primary_action_label(%{recommended_next_action: nil}), do: "No primary recommendation yet."
  defp primary_action_label(%{recommended_next_action: action}), do: action_label(action)

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

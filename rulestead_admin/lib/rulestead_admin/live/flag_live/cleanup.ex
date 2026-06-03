# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Cleanup do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
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
     |> assign(:code_references, [])}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

    if not capabilities.read? do
      {:noreply, redirect(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      query = query_params(uri)
      env = query["env"] || socket.assigns.current_environment.key
      base_path = build_base_path(socket, key)

      socket =
        socket
        |> assign(:flag_key, key)
        |> assign(
          :return_to,
          Session.canonical_return_to(
            socket,
            query["return_to"],
            socket.assigns.rulestead_admin_mount_path <> "/flags"
          )
        )
        |> assign(:current_path, Session.current_path(socket, base_path))
        |> assign(
          :env_links,
          Session.env_links(socket, base_path, %{"return_to" => query["return_to"]})
        )
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
      page_summary="Canonical review surface for lifecycle evidence, archive consequences, and the explicit preview-before-mutation path."
      base_path={@rulestead_admin_mount_path}
      current_section={:flags}
      breadcrumbs={breadcrumbs(assigns)}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      env_context_help="Shows this flag key's cleanup evidence in the selected environment. Promotion uses Compare."
      policy_state={@rulestead_admin_policy_state}
    >
      <:header_actions>
        <a :if={@return_to} href={@return_to}>Back to flags</a>
        <a :if={@flag_key} href={path_for(assigns, "/#{@flag_key}")}>Back to flag</a>
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

        <FlagComponents.callout title="Cleanup verdict" tone="warning">
          <p>
            Review cleanup is the canonical pre-mutation checkpoint. Use the recommendation, evidence quality, and blockers below to decide whether this flag is ready to archive.
          </p>
          <p :if={guidance_limited?(archive_readiness(@detail))}>
            Guidance limited by missing evidence. Review this flag manually before choosing a cleanup path.
          </p>
          <p :if={can_preview_archive?(@rulestead_admin_policy_state.capabilities)}>
            <a class="rs-button rs-button--primary" href={path_for(assigns, "/#{@detail.flag.key}/cleanup/preview")}>Preview archive</a>
          </p>
        </FlagComponents.callout>

        <FlagComponents.section_card title="Recommended next action">
          <p>
            <FlagComponents.readiness_badge readiness={archive_readiness(@detail).readiness} />
            <FlagComponents.evidence_quality_badge quality={archive_readiness(@detail).evidence_quality} />
          </p>
          <OperatorComponents.detail_grid rows={[
            %{label: "Primary recommendation", value: primary_action_label(archive_readiness(@detail))},
            %{label: "Secondary actions", value: secondary_actions_label(archive_readiness(@detail).secondary_actions)},
            %{label: "Archive consequences", value: "Leaves default workbench queues, archives every mounted environment, and keeps the audit trail append-only."}
          ]} />
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Evidence and uncertainty">
          <OperatorComponents.detail_grid rows={[
            %{label: "Reasons", value: joined_labels(archive_readiness(@detail).reasons, &reason_label/1, "No archive-positive signals yet.")},
            %{label: "Unknowns", value: joined_labels(archive_readiness(@detail).unknowns, &unknown_label/1, "No known evidence gaps.")},
            %{label: "Blockers", value: joined_labels(archive_readiness(@detail).blockers, &blocker_label/1, "No blockers identified.")},
            %{label: "Latest scan receipt", value: scan_label(freshness(@detail).code_refs_scan)}
          ]} />
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Code references">
          <OperatorComponents.empty_state
            :if={Enum.empty?(@code_references)}
            title="No code references found"
            body="The latest review payload did not report active code references for this flag."
            icon="0"
            variant="compact"
          />
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
          <OperatorComponents.detail_grid rows={[
            %{label: "Lifecycle posture", value: humanize(@detail.lifecycle.mode)},
            %{label: "Review by", value: @detail.lifecycle.review_by || "Not scheduled"}
          ]} />
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

  defp breadcrumbs(%{flag_key: nil} = assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key
    [%{label: "Flags", path: mount <> "/flags?env=" <> env}]
  end

  defp breadcrumbs(assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key
    key = assigns.flag_key

    [
      %{label: "Flags", path: mount <> "/flags?env=" <> env},
      %{label: key, path: mount <> "/" <> key <> "?env=" <> env},
      %{label: "Cleanup", path: mount <> "/" <> key <> "/cleanup?env=" <> env}
    ]
  end

  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness
  defp freshness(detail), do: detail.lifecycle.freshness

  defp can_preview_archive?(capabilities) do
    capabilities.execute? or capabilities.admin?
  end

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp primary_action_label(%{recommended_next_action: nil}),
    do: "No primary recommendation yet."

  defp primary_action_label(%{recommended_next_action: action}),
    do: action_label(action)

  defp secondary_actions_label([]), do: "No secondary actions."

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

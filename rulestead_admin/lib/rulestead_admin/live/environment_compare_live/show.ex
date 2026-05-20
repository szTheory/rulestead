defmodule RulesteadAdmin.Live.EnvironmentCompareLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:compare, nil)
     |> assign(:flag, nil)
     |> assign(:flag_key, nil)
     |> assign(:source_env, nil)
     |> assign(:target_env, nil)
     |> assign(:compare_token_param, nil)
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    source_env = params["source_env"] || socket.assigns.current_environment.key
    target_env = params["target_env"] || socket.assigns.current_environment.key
    compare_token = blank_to_nil(params["compare_token"])
    flag_key = params["key"]

    page = build_page(socket, flag_key, source_env, target_env, compare_token)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:flag_key, flag_key)
      |> assign(:source_env, source_env)
      |> assign(:target_env, target_env)
      |> assign(:compare_token_param, compare_token)
      |> load_compare()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      :if={@page}
      page_title={@page.page_title}
      page_kicker={@page.page_kicker}
      page_summary={@page.page_summary}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
    >
      <OperatorComponents.policy_state policy_state={@page.policy_state} />

      <OperatorComponents.banner
        :if={stale?(@compare)}
        title="Staleness conflict"
        body="This preview is stale. Re-run compare before any later governed apply handoff."
        tone="critical"
        aria_label="Stale compare warning"
      />

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <%= if @flag do %>
        <FlagComponents.section_card title="Flag compare overview">
          <h2><code><%= @flag.flag_key %></code></h2>
          <p>Source <%= @source_env %>, current target <%= @target_env %>, proposed target after apply from the current published source state.</p>
        </FlagComponents.section_card>

        <section aria-label={"Compare findings for #{@flag.flag_key}"}>
          <OperatorComponents.status_list
            title="Compare findings"
            entries={flag_finding_entries(@flag)}
          />
        </section>

        <FlagComponents.section_card title="State review">
          <AuditComponents.diff_card
            entry={
              %{
              title: @flag.flag_key,
              source_summary: inspect(@flag.source_state, pretty: true),
              current_target_summary: inspect(@flag.current_target_state, pretty: true),
              proposed_target_summary: inspect(@flag.proposed_target_state, pretty: true),
              diff_lines: Enum.map(@flag.changed_fields, &"Changed field: #{&1}")
            }}
            source_label="Source"
            current_target_label="Current target"
            proposed_target_label="Proposed target after apply"
            structured_label={"Show structured diff for #{@flag.flag_key}"}
          />
        </FlagComponents.section_card>

        <section aria-label="Compare token metadata">
          <OperatorComponents.trace_panel
            title="compare token metadata"
            summary="compare token and scoped context for this flag review."
            rows={trace_rows(@compare, @flag)}
          />
        </section>

        <details aria-label={"Show raw compare payload for #{@flag.flag_key}"}>
          <summary>Show raw compare payload for <%= @flag.flag_key %></summary>
          <pre><%= inspect(@compare, pretty: true) %></pre>
        </details>
      <% end %>
    </Shell.page>
    """
  end

  defp build_page(socket, flag_key, source_env, target_env, compare_token) do
    params =
      %{"source_env" => source_env, "target_env" => target_env}
      |> maybe_put_param("compare_token", compare_token)

    %{
      page_title: "Environment compare",
      page_kicker: "Flag drill-in",
      page_summary:
        "Inspect one flag across source, current target, and proposed target after apply.",
      current_environment: socket.assigns.current_environment,
      environments: socket.assigns.available_environments,
      env_links:
        Session.env_links(socket, admin_base_path(socket, "/compare/#{flag_key}"), params),
      current_path:
        Session.current_path(socket, admin_base_path(socket, "/compare/#{flag_key}"), params),
      policy_state: Session.policy_state(socket)
    }
  end

  defp load_compare(socket) do
    opts =
      [flag_keys: [socket.assigns.flag_key]]
      |> maybe_put_opt(:compare_token, socket.assigns.compare_token_param)

    case Rulestead.compare_environments(
           socket.assigns.source_env,
           socket.assigns.target_env,
           opts
         ) do
      {:ok, compare} ->
        socket
        |> assign(:compare, compare)
        |> assign(:flag, List.first(compare.flags))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:compare, nil)
        |> assign(:flag, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp flag_finding_entries(flag) do
    flag.findings
    |> Enum.map(fn finding ->
      %{
        label: labelize(finding.class),
        value: labelize(finding.severity),
        summary: finding.message,
        tone: tone_for(finding.severity)
      }
    end)
  end

  defp trace_rows(compare, flag) do
    [
      %{label: "Compare token", value: compare.compare_token || "not generated"},
      %{label: "Schema version", value: to_string(compare.compare_schema_version)},
      %{label: "source_env", value: compare.source_environment.key},
      %{label: "target_env", value: compare.target_environment.key},
      %{label: "Flag key", value: flag.flag_key}
    ]
  end

  defp stale?(nil), do: false
  defp stale?(compare), do: Enum.any?(compare.findings, &(&1.class == :staleness_conflict))

  defp tone_for(:blocker), do: "critical"
  defp tone_for(:warning), do: "warning"
  defp tone_for(_severity), do: "neutral"

  defp labelize(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp maybe_put_opt(opts, _key, nil), do: opts
  defp maybe_put_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_put_param(params, _key, nil), do: params
  defp maybe_put_param(params, key, value), do: Map.put(params, key, value)

  defp admin_base_path(%Phoenix.LiveView.Socket{} = socket, suffix),
    do: "#{socket.assigns.rulestead_admin_mount_path}#{suffix}"
end

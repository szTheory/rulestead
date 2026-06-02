defmodule RulesteadAdmin.Live.EnvironmentCompareLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:compare, nil)
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

    page = build_page(socket, source_env, target_env, compare_token)

    socket =
      socket
      |> assign(:page, page)
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
      base_path={@rulestead_admin_mount_path}
      current_section={:compare}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
      current_tenant={@page.current_tenant}
      tenants={@page.tenants}
      tenant_links={@page.tenant_links}
      env_context_help="Sets the page scope only. Source and target environments are selected below."
      policy_state={@page.policy_state}
    >
      <OperatorComponents.banner
        :if={production_target?(@target_env)}
        title="Production target"
        body="Review blockers and governed-apply requirements before continuing."
        tone="critical"
        aria_label="Production target warning"
      />

      <FlagComponents.section_card title="Compare context">
        <p>
          Source <code><%= @source_env %></code>, current target <code><%= @target_env %></code>,
          proposed target after apply from the published source state only.
        </p>
        <p :if={@page.current_tenant}>
          Tenant scope <code><%= @page.current_tenant.key %></code> stays explicit across mounted
          compare navigation.
        </p>
        <p><code><%= @page.current_path %></code></p>
      </FlagComponents.section_card>

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <%= if @compare do %>
        <FlagComponents.section_card title="Compare summary">
          <OperatorComponents.summary_grid
            items={summary_items(@compare)}
            aria_label="Compare summary"
          />
        </FlagComponents.section_card>

        <section class="rs-card" aria-label="Compare findings">
          <OperatorComponents.status_list title="Compare findings" entries={finding_entries(@compare)} />
          <ul class="rs-compact-list">
            <li :for={finding <- @compare.findings}>
              <strong><%= humanize_status(finding.class) %></strong>: <%= finding.message %>
            </li>
          </ul>
        </section>

        <FlagComponents.section_card title="Audience dependencies">
          <p :if={@compare.dependency_findings == []}>No reusable audience dependency findings for this compare.</p>
          <ul :if={@compare.dependency_findings != []} class="rs-compact-list">
            <li :for={finding <- @compare.dependency_findings}>
              <strong><%= humanize_status(finding.severity) %></strong>
              <code><%= finding.code %></code>
              <span> — <%= finding.message %></span>
              <span :if={finding.audience_key}> · audience <code><%= finding.audience_key %></code></span>
              <span :if={finding.flag_key}>
                ·
                <a href={dependency_flag_path(@page, finding)}><code><%= finding.flag_key %></code></a>
              </span>
              <span :if={finding.audience_key}>
                ·
                <a href={dependency_audience_path(@page, finding)}><code>audience detail</code></a>
              </span>
            </li>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Flag results">
          <%= if @compare.flags == [] do %>
            <h3>No comparable differences found</h3>
            <p>
              Source and target match for the selected authored scope. Change the environment pair
              or open a flag to review exact published state.
            </p>
          <% else %>
            <ul class="rs-compact-list">
              <li :for={flag <- @compare.flags}>
                <a href={flag_path(@page, flag.flag_key, @compare.compare_token)}>
                  <strong><code><%= flag.flag_key %></code></strong>
                </a>
                <span> · <%= humanize_status(flag_status(flag)) %></span>
                <span> · <%= length(flag.changed_fields || []) %> changed fields</span>
                <span> · <%= length(flag.dependency_closure_keys || []) %> dependency keys</span>
              </li>
            </ul>
          <% end %>
        </FlagComponents.section_card>

        <section aria-label="Compare token metadata">
          <OperatorComponents.trace_panel
            title="Compare token metadata"
            summary="Keep the compare token with this preview so later governed apply can detect stale authored changes."
            rows={trace_rows(@compare)}
          />
        </section>

      <% end %>
    </Shell.page>
    """
  end

  defp build_page(socket, source_env, target_env, compare_token) do
    tenant = socket.assigns.current_tenant

    params =
      %{"source_env" => source_env, "target_env" => target_env}
      |> maybe_put_param("tenant", tenant && tenant.key)
      |> maybe_put_param("compare_token", compare_token)

    %{
      page_title: "Environment compare",
      page_kicker: "Promotion preview",
      page_summary:
        "Read a findings-first authored compare before any governed apply path exists.",
      current_environment: socket.assigns.current_environment,
      environments: socket.assigns.available_environments,
      current_tenant: tenant,
      tenants: socket.assigns.available_tenants,
      env_links: Session.env_links(socket, admin_base_path(socket, "/compare"), params),
      tenant_links: Session.tenant_links(socket, admin_base_path(socket, "/compare"), params),
      policy_state: Session.policy_state(socket),
      mount_path: socket.assigns.rulestead_admin_mount_path,
      source_env: source_env,
      target_env: target_env,
      current_path: Session.current_path(socket, admin_base_path(socket, "/compare"), params)
    }
  end

  defp load_compare(socket) do
    opts =
      []
      |> maybe_put_opt(:tenant_key, current_tenant_key(socket))
      |> maybe_put_opt(:compare_token, socket.assigns.compare_token_param)

    case Rulestead.compare_environments(
           socket.assigns.source_env,
           socket.assigns.target_env,
           opts
         ) do
      {:ok, compare} ->
        socket
        |> assign(:compare, compare)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:compare, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp summary_items(compare) do
    [
      %{
        title: "Overall status",
        value: humanize_status(compare.overall_status),
        tone: tone_for(compare.overall_status)
      },
      %{title: "Changed flags", value: Integer.to_string(length(compare.flags)), tone: "neutral"},
      %{title: "Blockers", value: finding_count(compare.findings, :blocker), tone: "critical"},
      %{title: "Warnings", value: finding_count(compare.findings, :warning), tone: "warning"},
      %{title: "Info", value: finding_count(compare.findings, :info), tone: "neutral"}
    ]
  end

  defp finding_entries(compare) do
    [
      %{
        label: "Blockers",
        value: finding_count(compare.findings, :blocker),
        summary: "Resolve invalid, stale, or missing prerequisite state before apply.",
        tone: "critical"
      },
      %{
        label: "Warnings",
        value: finding_count(compare.findings, :warning),
        summary: "Review unpublished work, operational override, and protected-target notices.",
        tone: "warning"
      },
      %{
        label: "Info",
        value: finding_count(compare.findings, :info),
        summary: "Observational authored drift outside the blocking path.",
        tone: "neutral"
      }
    ]
  end

  defp trace_rows(compare) do
    [
      %{label: "Compare token", value: compare.compare_token || "not generated"},
      %{label: "Schema version", value: to_string(compare.compare_schema_version)},
      %{label: "tenant", value: compare.tenant_key || "tenant=unset"},
      %{label: "source_env", value: "source_env=#{compare.source_environment.key}"},
      %{label: "target_env", value: "target_env=#{compare.target_environment.key}"}
    ]
  end

  defp flag_path(page, flag_key, compare_token) do
    params =
      %{
        "env" => page.current_environment.key,
        "source_env" => page.source_env,
        "target_env" => page.target_env
      }
      |> maybe_put_param("tenant", page.current_tenant && page.current_tenant.key)
      |> maybe_put_param("compare_token", compare_token)

    "#{page.mount_path}/compare/#{flag_key}?" <>
      URI.encode_query(params)
  end

  defp finding_count(findings, severity) do
    findings
    |> Enum.count(&(&1.severity == severity))
    |> Integer.to_string()
  end

  defp flag_status(flag) do
    flag.findings
    |> Enum.map(& &1.severity)
    |> Enum.min_by(&severity_rank/1, fn -> :in_sync end)
  end

  defp severity_rank(:blocker), do: 0
  defp severity_rank(:warning), do: 1
  defp severity_rank(:info), do: 2
  defp severity_rank(:in_sync), do: 3

  defp tone_for(:blocker), do: "critical"
  defp tone_for(:warning), do: "warning"
  defp tone_for(:info), do: "neutral"
  defp tone_for(:in_sync), do: "positive"

  defp humanize_status(status) do
    status
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp production_target?(target_env), do: target_env in ["prod", "production"]

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp maybe_put_opt(opts, _key, nil), do: opts
  defp maybe_put_opt(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_put_param(params, _key, nil), do: params
  defp maybe_put_param(params, key, value), do: Map.put(params, key, value)

  defp current_tenant_key(socket) do
    socket.assigns.current_tenant && socket.assigns.current_tenant.key
  end

  defp admin_base_path(%Phoenix.LiveView.Socket{} = socket, suffix),
    do: "#{socket.assigns.rulestead_admin_mount_path}#{suffix}"

  defp dependency_flag_path(page, finding) do
    params = %{"env" => finding.environment_key || page.current_environment.key}

    params =
      if page.current_tenant, do: Map.put(params, "tenant", page.current_tenant.key), else: params

    "#{page.mount_path}/#{finding.flag_key}/rules?#{URI.encode_query(params)}"
  end

  defp dependency_audience_path(page, finding) do
    params = %{"env" => finding.environment_key || page.current_environment.key}

    params =
      if page.current_tenant, do: Map.put(params, "tenant", page.current_tenant.key), else: params

    "#{page.mount_path}/audiences/#{finding.audience_key}?#{URI.encode_query(params)}"
  end
end

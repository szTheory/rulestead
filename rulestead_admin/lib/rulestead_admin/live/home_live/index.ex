# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.HomeLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    mount_path = socket.assigns.rulestead_admin_mount_path
    env = socket.assigns.current_environment

    socket =
      socket
      |> assign(:current_path, Session.current_path(socket, mount_path))
      |> assign(:env_links, Session.env_links(socket, mount_path))
      |> assign(:current_uri, uri)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:caps, assigns.rulestead_admin_policy_state.capabilities)
      |> assign(:env_q, "?env=" <> assigns.current_environment.key)
      |> assign(:base, assigns.rulestead_admin_mount_path)

    ~H"""
    <Shell.page
      page_title="Operations home"
      page_kicker="Rulestead"
      page_summary="Pick a task, or pick up where you left off. Everything you can do in this environment starts here."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      policy_state={@rulestead_admin_policy_state}
      base_path={@rulestead_admin_mount_path}
      current_section={:home}
    >
      <nav class="rs-task-board" aria-label="What do you want to do?">
        <section class="rs-task-group" aria-label="Operate">
          <h2>Operate</h2>
          <OperatorComponents.task_link
            title="Browse flags"
            summary="Inventory of every feature flag in this environment."
            href={@base <> "/flags" <> @env_q}
            primary?={true}
          />
          <OperatorComponents.task_link
            :if={@caps.edit? or @caps.admin?}
            title="Create a flag"
            summary="Author a new flag, variant, or remote-config value."
            href={@base <> "/new" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Audiences"
            summary="Reusable targeting rules and their dependents."
            href={@base <> "/audiences" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Schedule"
            summary="Upcoming and in-flight scheduled changes."
            href={@base <> "/schedule" <> @env_q}
          />
        </section>

        <section class="rs-task-group" aria-label="Debug">
          <h2>Debug</h2>
          <OperatorComponents.task_link
            title="Diagnostics"
            summary="Cache freshness, sync latency, and adapter health."
            href={@base <> "/diagnostics" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Compare environments"
            summary="Diff flag state across environments before promoting."
            href={@base <> "/compare" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Experiments"
            summary="Experiment-type flags and their lifecycle."
            href={@base <> "/experiments" <> @env_q}
          />
        </section>

        <section class="rs-task-group" aria-label="Govern">
          <h2>Govern</h2>
          <OperatorComponents.task_link
            title="Change requests"
            summary="Review queue for governed mutations and approvals."
            href={@base <> "/change-requests" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Audit timeline"
            summary="Append-only history of every change, across all flags."
            href={@base <> "/audit" <> @env_q}
          />
          <OperatorComponents.task_link
            title="Webhooks"
            summary="Inbound and outbound integration delivery records."
            href={@base <> "/webhooks" <> @env_q}
          />
        </section>
      </nav>
    </Shell.page>
    """
  end
end

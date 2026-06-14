# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.{AudienceLive.Shared, Session}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:audiences, [])
     |> assign(:error_message, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    base_path = "#{socket.assigns.rulestead_admin_mount_path}/audiences"

    socket =
      socket
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> assign(:tenant_links, Session.tenant_links(socket, base_path))
      |> load_audiences()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Audiences"
      page_kicker="Reusable targeting"
      page_summary="Shared audience definitions referenced across flags. Open a row for used-by detail and governed mutations."
      base_path={@rulestead_admin_mount_path}
      current_section={:audiences}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      tenant_links={@tenant_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <section class="rs-page-section" aria-label="Audience route summary">
        <header class="rs-section-header">
          <div>
            <p class="rs-eyebrow">Audience inventory</p>
            <h2>Review reusable targeting before changing flags</h2>
            <p>
              {@audiences |> length()} reusable audience{if length(@audiences) == 1, do: "", else: "s"} in this scope. Open a row to inspect used-by dependencies, hidden references, and governed edit or archive paths.
            </p>
          </div>
        </header>
        <OperatorComponents.state_note
          tone="warning"
          title="Dependency visibility can be partial"
          body="Archived audiences are read-only, and some flag references may be hidden by policy. The detail route names hidden or denied dependencies before mutation controls."
        />
      </section>

      <FlagComponents.section_card title="Audience library">
        <table :if={@audiences != []} aria-label="Audience list" class="rs-table">
          <thead>
            <tr>
              <th>Key</th>
              <th>Description</th>
              <th>Status</th>
              <th>Last modified</th>
              <th>Next action</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={audience <- @audiences}>
              <td>
                <a href={Shared.path(assigns, "/audiences/#{audience.key}")}><code><%= audience.key %></code></a>
              </td>
              <td><%= audience.description || "—" %></td>
              <td>
                <span class="rs-badge" data-tone={audience_tone(audience)}>
                  {audience_label(audience)}
                </span>
              </td>
              <td><%= format_time(audience.updated_at) %></td>
              <td>
                <a href={Shared.path(assigns, "/audiences/#{audience.key}")}>Review dependencies</a>
              </td>
            </tr>
          </tbody>
        </table>
        <OperatorComponents.empty_state
          :if={@audiences == []}
          id="audiences-empty"
          title="No audiences found for this scope"
          body="Reusable targeting is not configured here yet. Return to flag rules when you need to add inline targeting or choose a different environment."
          icon="∅"
        />
      </FlagComponents.section_card>
    </Shell.page>
    """
  end

  defp load_audiences(socket) do
    opts = Shared.scope_opts(socket)

    case Rulestead.list_audiences(opts) do
      {:ok, audiences} ->
        socket
        |> assign(:audiences, audiences)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:audiences, [])
        |> assign(:error_message, error.message)
    end
  end

  defp format_time(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  defp format_time(_), do: "—"

  defp audience_state(%{archived_at: archived_at}) when not is_nil(archived_at), do: :archived
  defp audience_state(_audience), do: :active

  defp audience_tone(audience),
    do: RulesteadAdmin.StatusTone.tone(:audience, audience_state(audience))

  defp audience_label(audience),
    do: RulesteadAdmin.StatusTone.label(:audience, audience_state(audience))
end

# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, Shell}
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
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      tenant_links={@tenant_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <FlagComponents.section_card title="Audience library">
        <table :if={@audiences != []} aria-label="Audience list">
          <thead>
            <tr>
              <th>Key</th>
              <th>Description</th>
              <th>Status</th>
              <th>Last modified</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={audience <- @audiences}>
              <td>
                <a href={Shared.path(assigns, "/audiences/#{audience.key}")}><code><%= audience.key %></code></a>
              </td>
              <td><%= audience.description || "—" %></td>
              <td><%= if audience.archived_at, do: "Archived", else: "Active" %></td>
              <td><%= format_time(audience.updated_at) %></td>
            </tr>
          </tbody>
        </table>
        <p :if={@audiences == []}>No audiences found for this scope.</p>
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
end

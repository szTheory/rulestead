# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AudienceComponents, FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.{AudienceLive.Shared, Session}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:audience_key, nil)
     |> assign(:audience, nil)
     |> assign(:dependencies, empty_dependencies())
     |> assign(:error_message, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, _uri, socket) do
    base_path = Shared.audience_base(socket, audience_key)

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> assign(:tenant_links, Session.tenant_links(socket, "#{socket.assigns.rulestead_admin_mount_path}/audiences"))
      |> load_audience(audience_key)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience, do: @audience.key, else: "Audience")}
      page_kicker="Audience detail"
      page_summary="Lifecycle context, authored used-by references, and governed mutation entry points."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      current_tenant={@current_tenant}
      tenants={@available_tenants}
      tenant_links={@tenant_links}
    >
      <:header_actions>
        <a href={Shared.path(assigns, "/audiences")}>Back to audiences</a>
      </:header_actions>

      <OperatorComponents.policy_state policy_state={@rulestead_admin_policy_state} />

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@audience}>
        <FlagComponents.section_card title="Summary">
          <p><strong>Key:</strong> <code><%= @audience.key %></code></p>
          <p><strong>Description:</strong> <%= @audience.description || "—" %></p>
          <p><strong>Status:</strong> <%= if @audience.archived_at, do: "Archived", else: "Active" %></p>
          <p><strong>Scope:</strong> <code><%= @current_environment.key %></code>
            <span :if={@current_tenant}> · tenant <code><%= @current_tenant.key %></code></span>
          </p>
        </FlagComponents.section_card>

        <AudienceComponents.used_by_table
          dependencies={@dependencies}
          mount_path={@rulestead_admin_mount_path}
          environment_key={@current_environment.key}
          tenant_key={@current_tenant && @current_tenant.key}
        />

        <FlagComponents.section_card :if={editable?(@audience)} title="Governed actions">
          <p>Every mutation uses preview, confirm, and audit.</p>
          <p>
            <a href={Shared.path(assigns, "/audiences/#{@audience.key}/edit/preview")}>Preview update</a>
            ·
            <a href={Shared.path(assigns, "/audiences/#{@audience.key}/archive/preview")}>Preview archive</a>
            ·
            <a href={Shared.path(assigns, "/audiences/#{@audience.key}/delete/preview")}>Preview delete attempt</a>
          </p>
        </FlagComponents.section_card>
      </div>
    </Shell.page>
    """
  end

  defp load_audience(socket, audience_key) do
    opts = Shared.scope_opts(socket)

    with {:ok, audiences} <- Rulestead.list_audiences(Keyword.put(opts, :include_archived?, true)),
         %{} = audience <- Enum.find(audiences, &(&1.key == audience_key)) do
      socket
      |> assign(:audience, audience)
      |> assign(:dependencies, load_dependencies(socket, audience_key))
      |> assign(:error_message, nil)
    else
      _ ->
        socket
        |> assign(:audience, nil)
        |> assign(:dependencies, empty_dependencies())
        |> assign(:error_message, "Audience was not found in this scope.")
    end
  end

  defp load_dependencies(socket, audience_key) do
    case Rulestead.list_audience_dependencies(Shared.dependency_command(socket, audience_key)) do
      {:ok, result} ->
        %{
          summary: Shared.dependency_summary(result),
          entries: result.entries,
          redacted_entries: Map.get(result, :redacted_entries, []),
          hidden_count: Map.get(result, :hidden_reference_count, 0),
          denied?: false
        }

      {:error, %{domain: :auth}} ->
        %{summary: "Dependency list unavailable", entries: [], redacted_entries: [], hidden_count: 0, denied?: true}

      {:error, _error} ->
        %{summary: "Dependency list unavailable", entries: [], redacted_entries: [], hidden_count: 0, denied?: true}
    end
  end

  defp empty_dependencies,
    do: %{summary: "Used by 0 authored references", entries: [], redacted_entries: [], hidden_count: 0, denied?: false}

  defp editable?(%{archived_at: nil}), do: true
  defp editable?(_), do: false
end

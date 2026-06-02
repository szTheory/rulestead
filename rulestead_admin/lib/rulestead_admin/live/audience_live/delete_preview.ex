# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.DeletePreview do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AudienceComponents, FlagComponents, Shell}
  alias RulesteadAdmin.Live.{AudienceLive.Shared, Session}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:audience_key, nil)
     |> assign(:preview, nil)
     |> assign(:error_message, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, _uri, socket) do
    base_path = "#{Shared.audience_base(socket, audience_key)}/delete/preview"

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_preview(audience_key)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience_key, do: "#{@audience_key} delete preview", else: "Delete preview")}
      page_kicker="Delete preview"
      page_summary="Delete is not supported. This preview shows the fail-closed outcome operators would see."
      base_path={@rulestead_admin_mount_path}
      current_section={:audiences}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <FlagComponents.callout title="Delete is unsupported" tone="warning">
        <p>Audience delete is not available in mounted admin. Use archive when you need to retire an audience.</p>
      </FlagComponents.callout>

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <AudienceComponents.impact_preview :if={@preview} preview={@preview} />

      <p><a href={Shared.path(assigns, "/audiences/#{@audience_key}")}>Back to audience</a></p>
    </Shell.page>
    """
  end

  defp load_preview(socket, audience_key) do
    opts = Keyword.merge(Shared.scope_opts(socket), reason: "Mounted delete attempt preview")

    case Rulestead.preview_audience_impact(audience_key, :delete_attempt, opts) do
      {:ok, preview} ->
        socket
        |> assign(:preview, preview)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:preview, nil)
        |> assign(:error_message, error.message)
    end
  end
end

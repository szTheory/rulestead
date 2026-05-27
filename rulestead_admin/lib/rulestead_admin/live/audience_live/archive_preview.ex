# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.ArchivePreview do
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
     |> assign(:drift_message, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, uri, socket) do
    query = Shared.query_params(uri)
    base_path = "#{Shared.audience_base(socket, audience_key)}/archive/preview"

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> assign(:drift_message, Shared.drift_message(query["drifted"]))
      |> load_preview(audience_key)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience_key, do: "#{@audience_key} archive preview", else: "Archive preview")}
      page_kicker="Audience archive preview"
      page_summary="Review dependency blockers and impact evidence before archiving a reusable audience."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>
      <FlagComponents.callout :if={@drift_message} title="Preview refreshed" tone="warning">
        <p>{@drift_message}</p>
      </FlagComponents.callout>

      <AudienceComponents.impact_preview :if={@preview} preview={@preview} />

      <FlagComponents.section_card :if={@preview} title="Continue">
        <p>
          <a href={confirm_path(assigns)}>Continue to archive confirm</a>
          ·
          <a href={Shared.path(assigns, "/audiences/#{@audience_key}")}>Back to audience</a>
        </p>
      </FlagComponents.section_card>
    </Shell.page>
    """
  end

  defp load_preview(socket, audience_key) do
    opts = Keyword.merge(Shared.scope_opts(socket), reason: "Mounted archive preview")

    case Rulestead.preview_audience_impact(audience_key, :archive, opts) do
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

  defp confirm_path(assigns) do
    preview = assigns.preview

    params = %{
      "preview_fingerprint" => preview.preview_fingerprint,
      "preview_schema_version" => to_string(preview.preview_schema_version)
    }

    Session.current_path(
      assigns,
      "#{Shared.mount_path(assigns)}/audiences/#{assigns.audience_key}/archive/confirm",
      params
    )
  end
end

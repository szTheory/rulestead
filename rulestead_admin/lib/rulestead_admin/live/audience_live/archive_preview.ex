# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.ArchivePreview do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{
    AudienceComponents,
    FlagComponents,
    GovernanceComponents,
    Shell
  }

  alias RulesteadAdmin.Live.{AudienceLive.Governance, AudienceLive.Shared, Session}

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
      base_path={@rulestead_admin_mount_path}
      current_section={:audiences}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>
      <FlagComponents.callout :if={@drift_message} title="Preview refreshed" tone="warning">
        <p>{@drift_message}</p>
      </FlagComponents.callout>

      <FlagComponents.callout
        :if={@preview && @governance_mode == :change_request}
        title="Change request required"
        tone="warning"
      >
        <p>
          This archive exceeds the direct-apply limit for <strong>{@current_environment.name}</strong>.
          You will submit a change request instead of archiving immediately.
        </p>
      </FlagComponents.callout>

      <GovernanceComponents.blast_radius_panel
        :if={@preview && @blast_radius_assessment}
        assessment={@blast_radius_assessment}
        variant={:operator}
        visibility={visibility_attr(@visibility_tier)}
        environment_label={@current_environment.name}
      />

      <AudienceComponents.impact_preview :if={@preview} preview={@preview} />

      <FlagComponents.section_card :if={@preview} title="Continue">
        <p>
          <a :if={@governance_mode != :blocked} href={confirm_path(assigns)}>
            {continue_link_text(@governance_mode)}
          </a>
          <span :if={@governance_mode != :blocked}> · </span>
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
        |> Governance.load_governance_context(preview, operation: :archive)

      {:error, error} ->
        socket
        |> assign(:preview, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp visibility_attr(:full), do: :full
  defp visibility_attr(_), do: :redacted

  defp continue_link_text(:change_request), do: "Continue to submit"
  defp continue_link_text(_), do: "Continue to archive confirm"

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

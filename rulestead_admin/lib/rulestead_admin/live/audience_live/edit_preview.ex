# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.EditPreview do
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
    base_path = "#{Shared.audience_base(socket, audience_key)}/edit/preview"

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> assign(:drift_message, Shared.drift_message(query["drifted"]))
      |> load_preview(audience_key, query)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience_key, do: "#{@audience_key} update preview", else: "Update preview")}
      page_kicker="Audience impact preview"
      page_summary="Review authored blast radius before confirming an audience update."
      base_path={@rulestead_admin_mount_path}
      current_section={:audiences}
      breadcrumbs={Shared.breadcrumbs(assigns, "Edit preview")}
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
          This change exceeds the direct-apply limit for <strong>{@current_environment.name}</strong>.
          You will submit a change request instead of applying immediately.
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
        <div class="rs-mutation-confirm__actions">
          <.link
            :if={@governance_mode != :blocked}
            navigate={confirm_path(assigns)}
            class="rs-button rs-button--primary"
          >
            {continue_link_text(@governance_mode)}
          </.link>
          <.link
            navigate={Shared.path(assigns, "/audiences/#{@audience_key}")}
            class="rs-button rs-button--text"
          >
            Back to audience
          </.link>
        </div>
      </FlagComponents.section_card>
    </Shell.page>
    """
  end

  defp load_preview(socket, audience_key, query) do
    with {:ok, audience} <- fetch_audience(socket, audience_key),
         after_definition <- definition_from_query(query, audience) do
      opts =
        Shared.scope_opts(socket)
        |> Keyword.merge(after_definition: after_definition, reason: "Mounted update preview")

      case Rulestead.preview_audience_impact(audience_key, :update, opts) do
        {:ok, preview} ->
          socket
          |> assign(:preview, preview)
          |> assign(:error_message, nil)
          |> Governance.load_governance_context(preview, operation: :update)

        {:error, error} ->
          socket
          |> assign(:preview, nil)
          |> assign(:error_message, error.message)
      end
    else
      {:error, message} ->
        socket
        |> assign(:preview, nil)
        |> assign(:error_message, message)
    end
  end

  defp fetch_audience(socket, audience_key) do
    opts = Keyword.merge(Shared.scope_opts(socket), include_archived?: true)

    case Rulestead.list_audiences(opts) do
      {:ok, audiences} ->
        case Enum.find(audiences, &(&1.key == audience_key)) do
          nil -> {:error, "Audience was not found."}
          audience -> {:ok, audience}
        end

      {:error, error} ->
        {:error, error.message}
    end
  end

  defp definition_from_query(query, audience) do
    case query["after_definition"] do
      nil -> audience.definition
      encoded -> Jason.decode!(encoded)
    end
  rescue
    _ -> audience.definition
  end

  defp visibility_attr(:full), do: :full
  defp visibility_attr(_), do: :redacted

  defp continue_link_text(:change_request), do: "Continue to submit"
  defp continue_link_text(_), do: "Continue to confirm"

  defp confirm_path(assigns) do
    preview = assigns.preview

    params = %{
      "preview_fingerprint" => preview.preview_fingerprint,
      "preview_schema_version" => to_string(preview.preview_schema_version)
    }

    Session.current_path(
      assigns,
      "#{Shared.mount_path(assigns)}/audiences/#{assigns.audience_key}/edit/confirm",
      params
    )
  end
end

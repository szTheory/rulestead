# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.ArchiveConfirm do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, Shell}
  alias RulesteadAdmin.Live.{AudienceLive.Shared, Session}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:audience_key, nil)
     |> assign(:preview, nil)
     |> assign(:error_message, nil)
     |> assign(:reason_value, "")
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, uri, socket) do
    query = Shared.query_params(uri)
    base_path = "#{Shared.audience_base(socket, audience_key)}/archive/confirm"

    socket =
      socket
      |> assign(:audience_key, audience_key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_preview(audience_key, query)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@audience_key, do: "#{@audience_key} archive confirm", else: "Archive confirm")}
      page_kicker="Archive confirm"
      page_summary="Archive only after preview evidence and an operator reason are recorded."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <FlagComponents.section_card :if={@preview} title="Confirm archive">
        <p><strong>Fingerprint:</strong> <code><%= @preview.preview_fingerprint %></code></p>
        <form phx-submit="apply" aria-label="Confirm audience archive">
          <label>
            <span>Reason (required)</span>
            <textarea name="reason"><%= @reason_value %></textarea>
          </label>
          <button type="submit">Apply archive</button>
        </form>
        <p><a href={Shared.path(assigns, "/audiences/#{@audience_key}/archive/preview")}>Back to preview</a></p>
      </FlagComponents.section_card>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("apply", %{"reason" => reason}, socket) do
    reason = String.trim(reason)

    with :ok <- validate_reason(reason),
         {:ok, preview} <- ensure_preview(socket),
         {:ok, _result} <- Rulestead.apply_audience_mutation(apply_attrs(socket, preview, reason)) do
      {:noreply,
       socket
       |> put_flash(:info, "Audience archived.")
       |> push_navigate(to: Shared.path(socket, "/audiences/#{socket.assigns.audience_key}"))}
    else
      {:error, :missing_reason} ->
        {:noreply, assign(socket, :error_message, "Reason is required.")}

      {:error, :missing_preview} ->
        {:noreply, assign(socket, :error_message, "Run impact preview before confirming.")}

      {:error, error} ->
        if Shared.stale_preview_error?(error) do
          {:noreply,
           push_navigate(socket,
             to:
               Shared.path(socket, "/audiences/#{socket.assigns.audience_key}/archive/preview?drifted=true")
           )}
        else
          {:noreply, assign(socket, :error_message, error.message)}
        end
    end
  end

  defp load_preview(socket, audience_key, query) do
    fingerprint = blank_to_nil(query["preview_fingerprint"])
    schema_version = blank_to_nil(query["preview_schema_version"])

    if fingerprint && schema_version do
      case Rulestead.preview_audience_impact(audience_key, :archive, Shared.scope_opts(socket)) do
        {:ok, preview} -> assign(socket, preview: preview, error_message: nil)
        {:error, error} -> assign(socket, preview: nil, error_message: error.message)
      end
    else
      assign(socket, preview: nil, error_message: "Run impact preview before confirming.")
    end
  end

  defp apply_attrs(socket, preview, reason) do
    %{
      environment_key: socket.assigns.current_environment.key,
      tenant_key: socket.assigns.current_tenant && socket.assigns.current_tenant.key,
      audience_key: socket.assigns.audience_key,
      operation: :archive,
      preview_schema_version: preview.preview_schema_version,
      preview_fingerprint: preview.preview_fingerprint,
      preview_basis: preview.preview_basis,
      affected_reference_keys:
        Enum.map(List.wrap(preview.affected_references), fn ref ->
          ref[:reference_key] || ref["reference_key"]
        end),
      actor: socket.assigns.current_actor,
      reason: reason
    }
  end

  defp ensure_preview(%{assigns: %{preview: %{} = preview}}), do: {:ok, preview}
  defp ensure_preview(_socket), do: {:error, :missing_preview}

  defp validate_reason(""), do: {:error, :missing_reason}
  defp validate_reason(_), do: :ok

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end

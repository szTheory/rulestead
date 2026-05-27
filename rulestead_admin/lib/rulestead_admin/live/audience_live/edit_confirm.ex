# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.AudienceLive.EditConfirm do
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
     |> assign(:notice, nil)
     |> assign(:reason_value, "")
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})}
  end

  @impl true
  def handle_params(%{"audience_key" => audience_key}, uri, socket) do
    query = Shared.query_params(uri)
    base_path = "#{Shared.audience_base(socket, audience_key)}/edit/confirm"

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
      page_title={if(@audience_key, do: "#{@audience_key} update confirm", else: "Update confirm")}
      page_kicker="Audience confirm"
      page_summary="Apply an audience update only after reviewing preview evidence and entering a reason."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>
      <p :if={@notice} role="status"><%= @notice %></p>

      <FlagComponents.section_card :if={@preview} title="Confirm update">
        <p><strong>Fingerprint:</strong> <code><%= @preview.preview_fingerprint %></code></p>
        <p><strong>Scope:</strong> <code><%= @current_environment.key %></code>
          <span :if={@current_tenant}> · tenant <code><%= @current_tenant.key %></code></span>
        </p>

        <form phx-submit="apply" aria-label="Confirm audience update">
          <label>
            <span>Reason (required)</span>
            <textarea name="reason"><%= @reason_value %></textarea>
          </label>
          <button type="submit">Apply update</button>
        </form>
        <p><a href={preview_path(assigns)}>Back to preview</a></p>
      </FlagComponents.section_card>

      <p :if={is_nil(@preview)}>Run impact preview before confirming.</p>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("apply", %{"reason" => reason}, socket) do
    reason = String.trim(reason)

    with :ok <- validate_reason(reason),
         {:ok, preview} <- ensure_preview(socket),
         {:ok, audience} <- fetch_audience(socket, socket.assigns.audience_key),
         attrs <- apply_attrs(socket, preview, audience, reason),
         {:ok, _result} <- Rulestead.apply_audience_mutation(attrs) do
      {:noreply,
       socket
       |> put_flash(:info, "Audience update applied.")
       |> push_navigate(to: Shared.path(socket, "/audiences/#{socket.assigns.audience_key}"))}
    else
      {:error, :missing_preview} ->
        {:noreply, assign(socket, :error_message, "Run impact preview before confirming.")}

      {:error, :missing_reason} ->
        {:noreply, assign(socket, :error_message, "Reason is required.")}

      {:error, error} when is_binary(error) ->
        {:noreply, assign(socket, :error_message, error)}

      {:error, error} ->
        if Shared.stale_preview_error?(error) do
          {:noreply,
           push_navigate(socket,
             to:
               Shared.path(socket, "/audiences/#{socket.assigns.audience_key}/edit/preview?drifted=true")
           )}
        else
          {:noreply, assign(socket, :error_message, error.message)}
        end
    end
  end

  defp load_preview(socket, audience_key, query) do
    fingerprint = blank_to_nil(query["preview_fingerprint"])
    schema_version = blank_to_nil(query["preview_schema_version"])

    cond do
      is_nil(fingerprint) or is_nil(schema_version) ->
        socket
        |> assign(:preview, nil)
        |> assign(:error_message, "Run impact preview before confirming.")

      true ->
        with {:ok, audience} <- fetch_audience(socket, audience_key) do
          opts =
            Shared.scope_opts(socket)
            |> Keyword.merge(
              after_definition: audience.definition,
              preview_fingerprint: fingerprint,
              preview_schema_version: schema_version
            )

          case Rulestead.preview_audience_impact(audience_key, :update, opts) do
            {:ok, preview} ->
              socket
              |> assign(:preview, preview)
              |> assign(:error_message, nil)

            {:error, error} ->
              socket
              |> assign(:preview, nil)
              |> assign(:error_message, error.message)
          end
        else
          {:error, message} ->
            assign(socket, :error_message, message)
        end
    end
  end

  defp apply_attrs(socket, preview, audience, reason) do
    %{
      environment_key: socket.assigns.current_environment.key,
      tenant_key: socket.assigns.current_tenant && socket.assigns.current_tenant.key,
      audience_key: socket.assigns.audience_key,
      operation: :update,
      preview_schema_version: preview.preview_schema_version,
      preview_fingerprint: preview.preview_fingerprint,
      preview_basis: preview.preview_basis,
      affected_reference_keys:
        Enum.map(List.wrap(preview.affected_references), fn ref ->
          ref[:reference_key] || ref["reference_key"]
        end),
      after_definition: audience.definition,
      actor: socket.assigns.current_actor,
      reason: reason
    }
  end

  defp ensure_preview(%{assigns: %{preview: %{} = preview}}), do: {:ok, preview}
  defp ensure_preview(_socket), do: {:error, :missing_preview}

  defp validate_reason(""), do: {:error, :missing_reason}
  defp validate_reason(_reason), do: :ok

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

  defp preview_path(assigns), do: Shared.path(assigns, "/audiences/#{assigns.audience_key}/edit/preview")

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end

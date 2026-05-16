defmodule RulesteadAdmin.Live.FlagLive.Cleanup do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session
  import Ecto.Query, only: [from: 2]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})
     |> assign(:error_message, nil)
     |> assign(:confirmation_error, nil)
     |> assign(:confirmation_value, "")
     |> assign(:reason_value, "")
     |> assign(:notice, nil)
     |> assign(:code_references, [])}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    env = query_params(uri)["env"] || socket.assigns.current_environment.key
    base_path = build_base_path(socket, key)

    socket =
      socket
      |> assign(:flag_key, key)
      |> assign(:current_path, Session.current_path(socket, base_path))
      |> assign(:env_links, Session.env_links(socket, base_path))
      |> load_detail(key, env)
      |> load_code_references(key)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} cleanup", else: "Cleanup")}
      page_kicker="Cleanup"
      page_summary="Review remaining code references and permanently archive this flag."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <:header_actions>
        <a :if={@flag_key} href={path_for(assigns, "/#{@flag_key}")}>Back to detail</a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <div :if={@detail}>
        <div class="rs-summary-grid" aria-label="Cleanup summary">
          <FlagComponents.stat
            title="Confirmation"
            value={confirmation_hint(@current_environment.key)}
            tone={if(production_env?(@current_environment.key), do: "critical", else: "warning")}
          />
        </div>

        <FlagComponents.section_card title="Code References">
          <p :if={Enum.empty?(@code_references)}>No known code references.</p>
          <ul :if={not Enum.empty?(@code_references)}>
            <li :for={ref <- @code_references}>
              <code>{ref.file}:{ref.line}</code>
            </li>
          </ul>
        </FlagComponents.section_card>

        <FlagComponents.section_card title="Archive Flag">
          <form phx-submit="archive" aria-label="Archive Flag Form">
            <div>
              <label for="confirmation">Confirm exact flag key</label>
              <input type="text" name="confirmation" id="confirmation" value={@confirmation_value} />
            </div>
            <div>
              <label for="reason">Reason</label>
              <input type="text" name="reason" id="reason" value={@reason_value} />
            </div>
            <p :if={@confirmation_error} role="alert">{@confirmation_error}</p>
            <button type="submit">Archive Flag</button>
          </form>
        </FlagComponents.section_card>
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("archive", params, socket) do
    reason = String.trim(Map.get(params, "reason", ""))
    confirmation = String.trim(Map.get(params, "confirmation", ""))

    with :ok <- validate_reason(reason),
         :ok <- validate_confirmation(socket.assigns.flag_key, socket.assigns.current_environment.key, confirmation),
         {:ok, _payload} <-
           Rulestead.archive_flag(
             Rulestead.Store.Command.ArchiveFlag.new(socket.assigns.flag_key, actor: socket.assigns.current_actor, reason: reason)
           ) do
      {:noreply,
       socket
       |> assign(:confirmation_error, nil)
       |> assign(:confirmation_value, "")
       |> assign(:reason_value, "")
       |> assign(:notice, "Flag archived successfully.")
       |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}
    else
      {:error, error} ->
        {:noreply, assign(socket, :confirmation_error, error.message) |> assign(:reason_value, reason) |> assign(:confirmation_value, confirmation)}

      {:validation, message} ->
        {:noreply, assign(socket, :confirmation_error, message) |> assign(:reason_value, reason) |> assign(:confirmation_value, confirmation)}
    end
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:detail, detail)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:error_message, error.message)
    end
  end

  defp load_code_references(socket, key) do
    if Code.ensure_loaded?(Rulestead.Repo) do
      try do
        query = from(c in Rulestead.CodeRefs.CodeReference, where: c.flag_key == ^key, order_by: [asc: c.file, asc: c.line])
        refs = Rulestead.Repo.all(query)
        assign(socket, :code_references, refs)
      rescue
        _ -> assign(socket, :code_references, [])
      end
    else
      assign(socket, :code_references, [])
    end
  end

  defp query_params(uri) do
    uri
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      nil -> %{}
      query -> URI.decode_query(query)
    end
  end

  defp production_env?(environment_key), do: environment_key in ["prod", "production"]

  defp confirmation_hint(environment_key) do
    if production_env?(environment_key) do
      "Typed key confirmation required for production."
    else
      "Standard confirmation required for non-production environments."
    end
  end

  defp validate_reason(""), do: {:validation, "Reason is required."}
  defp validate_reason(_reason), do: :ok

  defp validate_confirmation(flag_key, environment_key, confirmation) do
    if production_env?(environment_key) and confirmation != flag_key do
      {:validation, "Type the exact flag key to confirm this production action."}
    else
      :ok
    end
  end

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/cleanup")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
end

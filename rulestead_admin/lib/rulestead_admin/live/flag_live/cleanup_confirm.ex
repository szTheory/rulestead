defmodule RulesteadAdmin.Live.FlagLive.CleanupConfirm do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.{FlagComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:return_to, nil)
     |> assign(:env_links, %{})
     |> assign(:error_message, nil)
     |> assign(:notice, nil)
     |> assign(:reason_value, "")
     |> assign(:confirmation_value, "")
     |> assign(:preview_signature, nil)}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

    if not capabilities.execute? and not capabilities.admin? do
      {:noreply, redirect(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      query = query_params(uri)
      env = query["env"] || socket.assigns.current_environment.key
      base_path = build_base_path(socket, key)

      socket =
        socket
        |> assign(:flag_key, key)
        |> assign(:current_path, Session.current_path(socket, base_path))
        |> assign(
          :return_to,
          Session.canonical_return_to(
            socket,
            query["return_to"],
            socket.assigns.rulestead_admin_mount_path
          )
        )
        |> assign(
          :env_links,
          Session.env_links(socket, base_path, %{"return_to" => query["return_to"]})
        )
        |> assign(:preview_signature, query["preview_signature"])
        |> load_detail(key, env)

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} archive confirm", else: "Archive confirm")}
      page_kicker="Cleanup confirm"
      page_summary="Governed archive confirmation with required reason, production typed key checks, and revalidation before mutation."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <:header_actions>
        <a :if={@return_to} href={@return_to}>Back to queue</a>
        <a :if={@flag_key} href={preview_path(assigns)}>Back to archive preview</a>
      </:header_actions>

      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <div :if={@detail}>
        <div class="rs-summary-grid" aria-label="Archive confirm summary">
          <FlagComponents.stat title="Flag" value={@detail.flag.key} tone="neutral" />
          <FlagComponents.stat title="Environment" value={@current_environment.name} tone="neutral" />
          <FlagComponents.stat title="Archive readiness" value={humanize(archive_readiness(@detail).readiness)} tone="neutral" />
          <FlagComponents.stat title="Confirmation" value={confirmation_hint(@current_environment.key)} tone={if(production_env?(@current_environment.key), do: "critical", else: "warning")} />
        </div>

        <FlagComponents.callout title="Archive flag" tone="warning">
          <p>Archive this flag only after reviewing code references, evaluation evidence, and blockers. Enter a reason to continue.</p>
          <p><strong>Revalidation:</strong> this route checks the current lifecycle state again immediately before apply.</p>
        </FlagComponents.callout>

        <FlagComponents.section_card title="Archive confirmation form">
          <form phx-submit="archive" aria-label="Archive flag confirmation form">
            <label>
              <span>Reason</span>
              <textarea name="reason"><%= @reason_value %></textarea>
            </label>
            <label>
              <span>Typed confirmation</span>
              <input type="text" name="confirmation" value={@confirmation_value} />
            </label>
            <button type="submit">Archive this flag</button>
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
         :ok <-
           validate_confirmation(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             confirmation
           ),
         {:ok, current_detail} <-
           Rulestead.fetch_flag(socket.assigns.flag_key, socket.assigns.current_environment.key),
         :ok <- validate_preview_signature(socket.assigns.preview_signature, current_detail),
         {:ok, _payload} <-
           Rulestead.archive_flag(
             Command.ArchiveFlag.new(socket.assigns.flag_key,
               actor: socket.assigns.current_actor,
               reason: reason
             )
           ) do
      {:noreply, push_navigate(socket, to: queue_return_path(socket, reason))}
    else
      {:error, error} ->
        {:noreply,
         socket
         |> assign(:error_message, error.message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}

      {:validation, message} ->
        {:noreply,
         socket
         |> assign(:error_message, message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}

      {:drifted, _detail} ->
        {:noreply, push_navigate(socket, to: preview_path(socket, %{"drifted" => "true"}))}
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

  defp validate_reason(""), do: {:validation, "Reason is required."}
  defp validate_reason(_reason), do: :ok

  defp validate_confirmation(flag_key, environment_key, confirmation) do
    if production_env?(environment_key) and confirmation != flag_key do
      {:validation, "Type the exact flag key to confirm this production action."}
    else
      :ok
    end
  end

  defp validate_preview_signature(nil, _detail),
    do: {:validation, "Open the archive preview before confirming this action."}

  defp validate_preview_signature(signature, detail) do
    if signature == preview_signature(detail) do
      :ok
    else
      {:drifted, detail}
    end
  end

  defp queue_return_path(socket, reason) do
    socket.assigns.return_to
    |> append_params(%{
      "include_archived" => "true",
      "notice" => "archived",
      "flag_key" => socket.assigns.flag_key,
      "reason" => reason,
      "audit_path" => audit_path(socket),
      "highlight" => socket.assigns.flag_key
    })
  end

  defp preview_path(socket_or_assigns, extra_params \\ %{}) do
    flag_key = fetch_flag_key(socket_or_assigns)

    Session.path_with_return_to(
      socket_or_assigns,
      admin_base_path(socket_or_assigns, "/#{flag_key}/cleanup/preview"),
      fetch_return_to(socket_or_assigns)
    )
    |> append_params(extra_params)
  end

  defp audit_path(socket_or_assigns) do
    flag_key = fetch_flag_key(socket_or_assigns)

    Session.current_path(
      socket_or_assigns,
      admin_base_path(socket_or_assigns, "/#{flag_key}/timeline")
    )
  end

  defp preview_signature(detail) do
    payload = %{
      lifecycle_state: detail.lifecycle.state,
      readiness: archive_readiness(detail).readiness,
      evidence_quality: archive_readiness(detail).evidence_quality,
      recommended_next_action: archive_readiness(detail).recommended_next_action,
      reasons: archive_readiness(detail).reasons,
      unknowns: archive_readiness(detail).unknowns,
      blockers: archive_readiness(detail).blockers
    }

    payload
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp append_params(path, extra_params) do
    parsed = URI.parse(path)

    query =
      parsed.query
      |> case do
        nil -> %{}
        value -> URI.decode_query(value)
      end
      |> Map.merge(extra_params)
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> Map.new()
      |> URI.encode_query()

    %{parsed | query: query}
    |> URI.to_string()
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
      "Reason required for non-production environments."
    end
  end

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/cleanup/confirm")

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp fetch_flag_key(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns.flag_key
  defp fetch_flag_key(%{flag_key: flag_key}), do: flag_key

  defp fetch_return_to(%Phoenix.LiveView.Socket{} = socket), do: socket.assigns.return_to
  defp fetch_return_to(%{return_to: return_to}), do: return_to

  defp archive_readiness(detail), do: detail.lifecycle.archive_readiness

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)
end

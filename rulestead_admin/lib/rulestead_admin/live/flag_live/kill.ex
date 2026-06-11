# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Kill do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{AuditComponents, Shell}
  alias RulesteadAdmin.Components.OperatorComponents
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:detail, nil)
     |> assign(:recent_events, [])
     |> assign(:flag_key, nil)
     |> assign(:current_path, nil)
     |> assign(:env_links, %{})
     |> assign(:error_message, nil)
     |> assign(:confirmation_error, nil)
     |> assign(:confirmation_value, "")
     |> assign(:reason_value, "")
     |> assign(:notice, nil)}
  end

  @impl true
  def handle_params(%{"key" => key}, uri, socket) do
    capabilities = socket.assigns.rulestead_admin_policy_state.capabilities

    if not capabilities.execute? and not capabilities.propose? and not capabilities.admin? do
      {:noreply, push_navigate(socket, to: socket.assigns.rulestead_admin_mount_path)}
    else
      env = query_params(uri)["env"] || socket.assigns.current_environment.key
      base_path = build_base_path(socket, key)

      socket =
        socket
        |> assign(:flag_key, key)
        |> assign(:current_path, Session.current_path(socket, base_path))
        |> assign(:env_links, Session.env_links(socket, base_path))
        |> load_detail(key, env)

      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title={if(@flag_key, do: "#{@flag_key} kill switch", else: "Kill switch")}
      page_kicker="Kill switch"
      page_summary="Bookmarkable emergency override route reserved for explicit kill and restore flows."
      base_path={@rulestead_admin_mount_path}
      current_section={:flags}
      breadcrumbs={breadcrumbs(assigns)}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      env_context_help="Shows this flag key's kill-switch state in the selected environment. Promotion uses Compare."
      policy_state={@rulestead_admin_policy_state}
    >
      <p :if={@error_message} role="alert">{@error_message}</p>
      <p :if={@notice} role="status">{@notice}</p>

      <div :if={@detail} class="rs-runbook">
        <AuditComponents.kill_switch_banner
          active?={kill_switch_active?(@detail)}
          flag_key={@detail.flag.key}
          environment_name={@detail.environment.name}
          reason={latest_reason(@detail, @current_actor)}
          kill_path={@current_path}
          timeline_path={path_for(assigns, "/#{@detail.flag.key}/timeline")}
        />

        <section class="rs-runbook__state" aria-label="Kill switch state">
          <div>
            <p class="rs-eyebrow">Emergency state</p>
            <h2><%= if kill_switch_active?(@detail), do: "Override active", else: "Authored behavior active" %></h2>
            <p>
              <%= if kill_switch_active?(@detail) do %>
                <code><%= @detail.flag.key %></code> is forcing the default value in <%= @detail.environment.name %>.
              <% else %>
                <code><%= @detail.flag.key %></code> is following authored rules in <%= @detail.environment.name %>.
              <% end %>
            </p>
          </div>
          <div class="rs-runbook__signals">
            <OperatorComponents.signal
              label="Override state"
              value={if(kill_switch_active?(@detail), do: "Active", else: "Inactive")}
              tone={if(kill_switch_active?(@detail), do: "critical", else: "positive")}
            />
            <OperatorComponents.signal label="Environment" value={@detail.environment.name} />
            <OperatorComponents.signal label="Default served on kill" value={inspect(default_flag_value(@detail.flag.default_value))} />
            <OperatorComponents.signal
              label="Confirmation"
              value={confirmation_hint(@current_environment.key)}
              tone={if(production_env?(@current_environment.key), do: "critical", else: "warning")}
            />
          </div>
        </section>

        <section
          class="rs-runbook__action"
          data-mode={if(kill_switch_active?(@detail), do: "release", else: "engage")}
          aria-label={if(kill_switch_active?(@detail), do: "Release override", else: "Engage override")}
        >
          <div class="rs-runbook__action-copy">
            <p class="rs-eyebrow">Operator action</p>
            <h2><%= if(kill_switch_active?(@detail), do: "Release override", else: "Engage override") %></h2>
            <p>
              Underlying rules stay untouched. This route only manages the environment override record and writes an audit event.
            </p>
          </div>
          <AuditComponents.kill_switch_form
            mode={if(kill_switch_active?(@detail), do: :release, else: :engage)}
            flag_key={@detail.flag.key}
            production?={production_env?(@current_environment.key)}
            confirmation_value={@confirmation_value}
            reason_value={@reason_value}
            error={@confirmation_error}
          />
        </section>

        <section class="rs-runbook__context" aria-label="After-action context">
          <div class="rs-runbook__note">
            <h2>After action</h2>
            <p>Verify diagnostics, then use the audit timeline as the incident handoff trail.</p>
            <div class="rs-inline-actions">
              <.link class="rs-button" navigate={path_for(assigns, "/diagnostics")}>
                <OperatorComponents.action_icon name="diagnostics" />
                Open diagnostics
              </.link>
              <.link class="rs-button" navigate={path_for(assigns, "/#{@detail.flag.key}/timeline")}>
                <OperatorComponents.action_icon name="timeline" />
                Open audit timeline
              </.link>
            </div>
          </div>
          <div class="rs-runbook__history">
            <h2>Recent override history</h2>
            <p :if={@recent_events == []}>No kill switch engage or release events are visible for this flag.</p>
            <ol :if={@recent_events != []}>
              <li :for={event <- @recent_events}>
                <strong><%= event.title %></strong>
                <span><%= event.meta %></span>
                <p :if={event.reason}><%= event.reason %></p>
              </li>
            </ol>
          </div>
        </section>
      </div>
    </Shell.page>
    """
  end

  @impl true
  def handle_event("engage", params, socket) do
    reason = String.trim(Map.get(params, "reason", ""))
    confirmation = String.trim(Map.get(params, "confirmation", ""))

    with :ok <- validate_reason(reason),
         :ok <-
           validate_confirmation(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             confirmation
           ),
         {:ok, _payload} <-
           Rulestead.engage_kill_switch(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             socket.assigns.current_actor,
             reason: reason
           ) do
      {:noreply,
       socket
       |> assign(:confirmation_error, nil)
       |> assign(:confirmation_value, "")
       |> assign(:reason_value, "")
       |> assign(:notice, "Kill switch engaged for #{socket.assigns.current_environment.name}.")
       |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}
    else
      {:error, error} ->
        {:noreply,
         assign(socket, :confirmation_error, error.message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}

      {:validation, message} ->
        {:noreply,
         assign(socket, :confirmation_error, message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}
    end
  end

  @impl true
  def handle_event("release", params, socket) do
    reason = String.trim(Map.get(params, "reason", ""))
    confirmation = String.trim(Map.get(params, "confirmation", ""))

    with :ok <- validate_reason(reason),
         :ok <-
           validate_confirmation(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             confirmation
           ),
         {:ok, _payload} <-
           Rulestead.release_kill_switch(
             socket.assigns.flag_key,
             socket.assigns.current_environment.key,
             socket.assigns.current_actor,
             reason: reason
           ) do
      {:noreply,
       socket
       |> assign(:confirmation_error, nil)
       |> assign(:confirmation_value, "")
       |> assign(:reason_value, "")
       |> assign(:notice, "Kill switch released for #{socket.assigns.current_environment.name}.")
       |> load_detail(socket.assigns.flag_key, socket.assigns.current_environment.key)}
    else
      {:error, error} ->
        {:noreply,
         assign(socket, :confirmation_error, error.message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}

      {:validation, message} ->
        {:noreply,
         assign(socket, :confirmation_error, message)
         |> assign(:reason_value, reason)
         |> assign(:confirmation_value, confirmation)}
    end
  end

  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        socket
        |> assign(:detail, detail)
        |> assign(:recent_events, recent_override_events(detail, socket.assigns.current_actor))
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:recent_events, [])
        |> assign(:error_message, error.message)
    end
  end

  defp recent_override_events(detail, actor) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: actor
           ) do
      page.entries
      |> Enum.filter(&(&1.event_type in ["kill_switch.engage", "kill_switch.release"]))
      |> Enum.take(5)
      |> Enum.map(fn event ->
        %{
          title:
            event.event_type
            |> String.replace("_", " ")
            |> String.replace(".", " ")
            |> String.capitalize(),
          meta:
            "#{event.actor_display || event.actor_id || "Unknown actor"} · #{format_time(event.occurred_at)}",
          reason: event.reason
        }
      end)
    else
      _ -> []
    end
  end

  defp format_time(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")
  defp format_time(_value), do: "Unknown time"

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

  defp kill_switch_active?(detail), do: detail.flag_environment.status == :killswitched

  defp latest_reason(detail, actor) do
    detail
    |> fetch_latest_audit_reason(actor)
    |> case do
      nil -> nil
      value -> value
    end
  end

  defp fetch_latest_audit_reason(detail, actor) do
    with {:ok, page} <-
           Rulestead.list_audit_events(
             flag_key: detail.flag.key,
             environment_key: detail.environment.key,
             actor: actor
           ),
         event when is_map(event) <-
           Enum.find(
             page.entries,
             &(&1.event_type in ["kill_switch.engage", "kill_switch.release"])
           ) do
      event.reason
    else
      _ -> nil
    end
  end

  defp default_flag_value(%{value: value}), do: value
  defp default_flag_value(%{"value" => value}), do: value
  defp default_flag_value(value), do: value

  defp build_base_path(socket, key), do: admin_base_path(socket, "/#{key}/kill")

  defp path_for(socket, suffix), do: Session.current_path(socket, admin_base_path(socket, suffix))

  defp admin_base_path(socket_or_assigns, suffix),
    do: "#{fetch_mount_path(socket_or_assigns)}#{suffix}"

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path

  defp breadcrumbs(%{flag_key: nil} = assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key
    [%{label: "Flags", path: mount <> "/flags?env=" <> env}]
  end

  defp breadcrumbs(assigns) do
    mount = assigns.rulestead_admin_mount_path
    env = assigns.current_environment.key
    key = assigns.flag_key

    [
      %{label: "Flags", path: mount <> "/flags?env=" <> env},
      %{label: key, path: mount <> "/" <> key <> "?env=" <> env},
      %{label: "Kill switch", path: mount <> "/" <> key <> "/kill?env=" <> env}
    ]
  end
end

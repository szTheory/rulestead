defmodule RulesteadAdmin.Live.ChangeRequestLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias Rulestead.Governance.ChangeRequest
  alias Rulestead.Store.Command
  alias RulesteadAdmin.Components.Shell
  alias RulesteadAdmin.Live.Session

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, nil)
     |> assign(:entries, [])
     |> assign(:filters, %{})
     |> assign(:error_message, nil)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    params = Map.merge(params, query_params(uri))
    socket = apply_resolved(socket, params)

    if params["env"] != socket.assigns.current_environment.key do
      {:noreply, push_patch(socket, to: Session.current_path(socket, base_path()))}
    else
      filters = filters_from_params(params)
      filter_params = query_filters(filters)

      page =
        socket.assigns
        |> Session.placeholder_assigns(
          current_path: base_path(),
          page_title: "Change requests",
          page_kicker: "Governance",
          page_summary:
            "Dedicated review queue for governed mutations, approvals, and explicit execution follow-through."
        )
        |> Map.merge(%{
          navigation_links: navigation_links(socket, :change_requests),
          env_links: Session.env_links(socket, base_path(), filter_params),
          schedule_path: Session.current_path(socket, schedule_base_path()),
          audit_path: Session.current_path(socket, audit_base_path()),
          flags_path: Session.current_path(socket, mount_path(socket)),
          current_path: Session.current_path(socket, base_path(), filter_params),
          filter_action_options: filter_action_options(),
          filter_status_options: filter_status_options()
        })

      {entries, error_message} = load_entries(socket, filters)

      {:noreply,
       socket
       |> assign(:page, page)
       |> assign(:filters, filters)
       |> assign(:entries, entries)
       |> assign(:error_message, error_message)}
    end
  end

  @impl true
  def render(%{page: page} = assigns) when is_map(page) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <Shell.page
      page_title={@page.page_title}
      page_kicker={@page.page_kicker}
      page_summary={@page.page_summary}
      current_environment={@page.current_environment}
      environments={@page.environments}
      env_links={@page.env_links}
      navigation_links={@page.navigation_links}
      policy_state={@page.policy_state}
    >
      <section>
        <h2>Review queue</h2>
        <p>
          Operators can scan governed work here without overloading audit history or turning flag detail
          into a workflow hub.
        </p>
      </section>

      <section>
        <form method="get" action={base_path()} class="rs-filter-grid">
          <input type="hidden" name="env" value={@page.current_environment.key} />

          <label>
            <span>Status</span>
            <select name="status">
              <option value="">All statuses</option>
              <option
                :for={option <- @page.filter_status_options}
                value={option.value}
                selected={@filters["status"] == option.value}
              >
                <%= option.label %>
              </option>
            </select>
          </label>

          <label>
            <span>Action</span>
            <select name="action">
              <option value="">All actions</option>
              <option
                :for={option <- @page.filter_action_options}
                value={option.value}
                selected={@filters["action"] == option.value}
              >
                <%= option.label %>
              </option>
            </select>
          </label>

          <label>
            <span>Resource</span>
            <input type="text" name="resource" value={@filters["resource"]} placeholder="flag key" />
          </label>

          <button type="submit">Apply filters</button>
        </form>
      </section>

      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <section>
        <h2>Open review items</h2>

        <p :if={@entries == []}>No change requests match this environment and filter set.</p>

        <ul :if={@entries != []} class="rs-change-request-list">
          <li :for={entry <- @entries} class="rs-change-request-row">
            <div>
              <p>
                <span class="rs-badge"><%= humanize(entry.state) %></span>
                <strong><%= humanize(entry.action) %></strong>
                <code><%= entry.resource_key %></code>
              </p>
              <p><%= entry.preview_title %></p>
              <p>Requested by <%= actor_display(entry.submitted_by) %></p>
            </div>

            <div>
              <a href={entry.detail_path}>Review change request</a>
              <a :if={entry.flag_path} href={entry.flag_path}>Open flag</a>
            </div>
          </li>
        </ul>
      </section>

      <section>
        <h2>Related routes</h2>
        <ul>
          <li><a href={@page.schedule_path}>Open schedule</a></li>
          <li><a href={@page.audit_path}>Open audit timeline</a></li>
          <li><a href={@page.flags_path}>Back to flag inventory</a></li>
        </ul>
      </section>
    </Shell.page>
    """
  end

  defp base_path, do: "/admin/flags/change-requests"
  defp schedule_base_path, do: "/admin/flags/schedule"
  defp audit_base_path, do: "/admin/flags/audit"

  defp mount_path(socket), do: socket.assigns.rulestead_admin_mount_path

  defp navigation_links(socket, current) do
    [
      nav_link("Flags", Session.current_path(socket, mount_path(socket)), current == :flags),
      nav_link(
        "Change requests",
        Session.current_path(socket, base_path()),
        current == :change_requests
      ),
      nav_link(
        "Schedule",
        Session.current_path(socket, schedule_base_path()),
        current == :schedule
      ),
      nav_link(
        "Webhooks",
        Session.current_path(socket, "/admin/flags/webhooks"),
        current == :webhooks
      ),
      nav_link("Audit", Session.current_path(socket, audit_base_path()), current == :audit)
    ]
  end

  defp nav_link(label, path, current?), do: %{label: label, path: path, current?: current?}

  defp load_entries(socket, filters) do
    command =
      Command.ListChangeRequests.new(
        environment_key: socket.assigns.current_environment.key,
        status: normalize_filter(filters["status"], ChangeRequest.states()),
        action: normalize_filter(filters["action"], ChangeRequest.governed_actions())
      )

    case Rulestead.list_change_requests(command) do
      {:ok, page} ->
        entries =
          page.entries
          |> Enum.filter(&matches_resource_filter?(&1, filters["resource"]))
          |> Enum.map(&project_entry(socket, &1, filters))

        {entries, nil}

      {:error, error} ->
        {[], error.message}
    end
  end

  defp project_entry(socket, entry, filters) do
    filter_params = query_filters(filters)

    %{
      id: entry.id,
      state: entry.state,
      action: entry.action,
      resource_key: entry.resource_key,
      submitted_by: entry.submitted_by,
      preview_title: preview_title(entry),
      detail_path: Session.current_path(socket, "#{base_path()}/#{entry.id}", filter_params),
      flag_path:
        if(entry.resource_key,
          do: Session.current_path(socket, "#{mount_path(socket)}/#{entry.resource_key}")
        )
    }
  end

  defp filters_from_params(params) do
    %{
      "status" => Map.get(params, "status", ""),
      "action" => Map.get(params, "action", ""),
      "resource" => Map.get(params, "resource", "")
    }
  end

  defp query_filters(filters) do
    filters
    |> Enum.reject(fn {_key, value} -> blank?(value) end)
    |> Map.new()
  end

  defp normalize_filter(value, allowed_atoms) do
    normalized = blank_to_nil(value)

    Enum.find(allowed_atoms, fn atom -> Atom.to_string(atom) == normalized end)
  end

  defp filter_status_options do
    Enum.map(ChangeRequest.states(), &%{value: Atom.to_string(&1), label: humanize(&1)})
  end

  defp filter_action_options do
    Enum.map(ChangeRequest.governed_actions(), &%{value: Atom.to_string(&1), label: humanize(&1)})
  end

  defp preview_title(entry) do
    entry
    |> get_in([:command, "diff", "title"])
    |> case do
      value when is_binary(value) and value != "" -> value
      _ -> "Proposed #{humanize(entry.action)}"
    end
  end

  defp actor_display(actor) do
    actor["display"] || actor[:display] || actor["id"] || actor[:id] || "Unknown operator"
  end

  defp matches_resource_filter?(_entry, value) when value in [nil, ""], do: true

  defp matches_resource_filter?(entry, value) do
    value = String.downcase(value)
    resource_key = entry.resource_key |> to_string() |> String.downcase()
    String.contains?(resource_key, value)
  end

  defp humanize(value) when is_atom(value), do: humanize(Atom.to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp apply_resolved(socket, params) do
    resolved =
      Session.resolve(
        params,
        %{
          "current_actor" => socket.assigns.current_actor,
          "rulestead_admin_environments" => socket.assigns.available_environments,
          "rulestead_admin_last_env" => socket.assigns.current_environment.key
        },
        policy: socket.assigns.rulestead_admin_policy,
        mount_path: socket.assigns.rulestead_admin_mount_path
      )

    socket
    |> assign(:current_environment, resolved.environment)
    |> assign(:available_environments, resolved.environments)
    |> assign(:rulestead_admin_env_source, resolved.env_source)
    |> assign(:rulestead_admin_policy_state, Session.policy_state(resolved))
    |> assign(:rulestead_admin_session, resolved)
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

  defp blank?(value), do: is_nil(blank_to_nil(value))
  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end

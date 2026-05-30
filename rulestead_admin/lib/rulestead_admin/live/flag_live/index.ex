# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @default_limit 25
  @allowed_lifecycle ~w(active potentially_stale stale archived)
  @allowed_stale ~w(fresh potentially_stale stale)
  @allowed_readiness ~w(keep_active needs_review archive_candidate)
  @allowed_evidence_quality ~w(strong partial weak)
  @lifecycle_presets [
    {"All flags", %{}},
    {"Archive candidates", %{"readiness" => "archive_candidate", "include_archived" => "true"}},
    {"Needs review", %{"readiness" => "needs_review"}},
    {"Recently stale", %{"stale" => "stale"}}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:screen_action, :index)
      |> assign(:base_path, "/admin/flags")
      |> assign(:filters, default_filters())
      |> assign(:page, empty_page())
      |> assign(:error_message, nil)
      |> assign(:outcome_notice, nil)
      |> assign(:outcome_audit_path, nil)
      |> assign(:highlighted_flag_key, nil)
      |> assign(:allowed_lifecycle, @allowed_lifecycle)
      |> assign(:allowed_stale, @allowed_stale)
      |> assign(:allowed_readiness, @allowed_readiness)
      |> assign(:allowed_evidence_quality, @allowed_evidence_quality)
      |> assign(:lifecycle_presets, @lifecycle_presets)
      |> stream_configure(:flags, dom_id: &"flag-#{&1.flag.key}")
      |> stream(:flags, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    merged_params = Map.merge(query_params(uri), stringify_keys(params))
    filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
    outcome = normalize_outcome_params(merged_params)
    current_path = path_with_query(uri)
    canonical_path = build_index_path(socket.assigns.base_path, filters, outcome)

    if canonical_path != current_path do
      {:noreply, push_patch(socket, to: canonical_path)}
    else
      socket =
        socket
        |> assign(:current_path, current_path)
        |> assign(:filters, filters)
        |> assign(
          :env_links,
          environment_links(
            socket.assigns.base_path,
            filters,
            socket.assigns.available_environments
          )
        )
        |> assign(
          :outcome_notice,
          outcome_notice(outcome, socket.assigns.current_environment.name)
        )
        |> assign(:outcome_audit_path, normalize_audit_path(socket, outcome["audit_path"]))
        |> assign(:highlighted_flag_key, outcome["highlight"])
        |> load_flags(filters)

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filters_changed", %{"filters" => filters}, socket) do
    merged_filters =
      socket.assigns.filters
      |> Map.merge(filters)
      |> Map.put("after", nil)
      |> Map.put("before", nil)

    {:noreply,
     push_patch(socket,
       to:
         build_index_path(
           socket.assigns.base_path,
           normalize_filters(merged_filters, socket.assigns.current_environment.key)
         )
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Flags"
      page_kicker="Flag inventory"
      page_summary="Dense operator inventory scoped to the current environment."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <OperatorComponents.policy_state policy_state={@rulestead_admin_policy_state} />

      <FlagComponents.callout :if={@outcome_notice} title="Archive result" tone="positive">
        <p><%= @outcome_notice %></p>
        <p :if={@outcome_audit_path}>
          <a href={@outcome_audit_path}>Open audit timeline</a>
        </p>
      </FlagComponents.callout>

      <section class="rs-inventory">
        <div class="rs-inventory__toolbar">
          <div>
            <h2>Flag inventory</h2>
            <p>Monospace key, lifecycle, stale status, and environment state stay visible for fast scanning.</p>
          </div>
          <div :if={@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?}>
            <a href={@base_path <> "/new?env=" <> @current_environment.key} class="rs-button rs-button--primary">Create flag</a>
          </div>
        </div>

        <nav aria-label="Lifecycle preset strip" class="rs-filter-presets">
          <div>
            <h3>Lifecycle presets</h3>
            <p>Quick filters to manage technical debt. "Archive candidates" finds fully rolled-out, stale flags.</p>
          </div>
          <div class="rs-filter-presets__links">
            <.link
              :for={{label, params} <- @lifecycle_presets}
              patch={preset_path(@base_path, @filters, params)}
            >
              <%= label %>
            </.link>
          </div>
        </nav>

        <form aria-label="Flag filters" phx-change="filters_changed" class="rs-filter-grid">
          <input type="hidden" name="filters[env]" value={@current_environment.key} />
          <label>
            <span>Search</span>
            <input type="text" name="filters[query]" value={@filters["query"]} phx-debounce="300" />
            <small>Search covers owner display and legacy labels without changing the owner filter.</small>
          </label>
          <label>
            <span>Owner ref</span>
            <input type="text" name="filters[owner]" value={@filters["owner"]} phx-debounce="300" />
            <small>Owner filter uses the exact owner ref. Use Search for broader owner discovery.</small>
          </label>
          <label>
            <span>Tags</span>
            <input type="text" name="filters[tags]" value={@filters["tags"]} placeholder="checkout, infra" phx-debounce="300" />
          </label>
          <label>
            <span>Lifecycle</span>
            <select name="filters[lifecycle]">
              <option value="">All lifecycle states</option>
              <option :for={state <- @allowed_lifecycle} value={state} selected={@filters["lifecycle"] == state}>
                <%= humanize(state) %>
              </option>
            </select>
          </label>
          <label>
            <span>Stale status</span>
            <select name="filters[stale]">
              <option value="">All freshness states</option>
              <option :for={state <- @allowed_stale} value={state} selected={@filters["stale"] == state}>
                <%= humanize(state) %>
              </option>
            </select>
          </label>
          <label>
            <span>Rows</span>
            <select name="filters[limit]">
              <option :for={limit <- [1, 10, 25, 50]} value={limit} selected={Integer.to_string(limit) == @filters["limit"]}>
                <%= limit %>
              </option>
            </select>
          </label>
          <label>
            <span>Archive readiness</span>
            <select name="filters[readiness]">
              <option value="">All readiness states</option>
              <option :for={state <- @allowed_readiness} value={state} selected={@filters["readiness"] == state}>
                <%= humanize(state) %>
              </option>
            </select>
          </label>
          <label>
            <span>Evidence quality</span>
            <select name="filters[evidence_quality]">
              <option value="">All evidence states</option>
              <option :for={state <- @allowed_evidence_quality} value={state} selected={@filters["evidence_quality"] == state}>
                <%= humanize(state) %>
              </option>
            </select>
          </label>
          <label class="rs-filter-grid__checkbox">
            <input type="checkbox" name="filters[include_archived]" value="true" checked={@filters["include_archived"] == "true"} />
            <span>Include archived</span>
          </label>
        </form>

        <p :if={@error_message} role="alert"><%= @error_message %></p>

        <table role="grid" aria-label="Flag inventory table" class="rs-table">
          <caption class="sr-only">Flag inventory table</caption>
          <thead>
            <tr>
              <th scope="col">Key</th>
              <th scope="col">Type</th>
              <th scope="col">Owner</th>
              <th scope="col">Lifecycle</th>
              <th scope="col">Environment status</th>
              <th scope="col">Stale indicator</th>
              <th scope="col">Archive readiness</th>
              <th scope="col">Evidence quality</th>
              <th scope="col">Advisory note</th>
              <th scope="col">Last changed</th>
            </tr>
          </thead>
          <tbody id="flags" phx-update="stream">
            <tr
              :for={{dom_id, entry} <- @streams.flags}
              id={dom_id}
              data-flag-key={entry.flag.key}
              data-highlighted={to_string(@highlighted_flag_key == entry.flag.key)}
              tabindex="0"
            >
              <td>
                <a href={flag_path(assigns, entry.flag.key)}>
                  <code><%= entry.flag.key %></code>
                </a>
                <FlagComponents.tag_list tags={entry.flag.tags} />
              </td>
              <td><%= humanize(entry.flag.flag_type) %></td>
              <td><%= entry.flag.ownership.owner_display || entry.flag.ownership.owner_ref %></td>
              <td><FlagComponents.lifecycle_badge state={entry.lifecycle} /></td>
              <td><FlagComponents.environment_status status={entry.environment_status || entry.flag_environment.status || :draft} /></td>
              <td>
                <%= if stale_state(entry.lifecycle) in [:stale, :potentially_stale] do %>
                  <a href={cleanup_path(assigns, entry.flag.key)}>
                    <FlagComponents.stale_badge state={stale_state(entry.lifecycle)} last_evaluated_at={entry.lifecycle.last_evaluated_at} />
                  </a>
                <% else %>
                  <FlagComponents.stale_badge state={stale_state(entry.lifecycle)} last_evaluated_at={entry.lifecycle.last_evaluated_at} />
                <% end %>
              </td>
              <td><FlagComponents.readiness_badge readiness={entry.lifecycle.archive_readiness.readiness} /></td>
              <td><FlagComponents.evidence_quality_badge quality={entry.lifecycle.archive_readiness.evidence_quality} /></td>
              <td>
                <p><%= advisory_note(entry.lifecycle) %></p>
                <a :if={show_cleanup_link?(entry.lifecycle)} href={cleanup_path(assigns, entry.flag.key)}>
                  Review cleanup
                </a>
              </td>
              <td><%= format_last_changed(entry.flag.updated_at || entry.flag.inserted_at) %></td>
            </tr>
            <tr :if={Enum.empty?(@page.entries)} id="flags-empty">
              <td colspan="10">No flags matched the current environment and filters.</td>
            </tr>
          </tbody>
        </table>

        <FlagComponents.pagination page={@page} base_path={@base_path} params={pagination_params(@filters)} />
      </section>
    </Shell.page>
    """
  end

  defp load_flags(socket, filters) do
    opts = list_opts(filters)

    case Rulestead.list_flags(opts) do
      {:ok, page} ->
        socket
        |> assign(:page, page)
        |> assign(:error_message, nil)
        |> stream(:flags, page.entries, reset: true)

      {:error, error} ->
        socket
        |> assign(:page, empty_page())
        |> assign(:error_message, error.message)
        |> stream(:flags, [], reset: true)
    end
  end

  defp list_opts(filters) do
    [
      environment_key: filters["env"],
      query: blank_to_nil(filters["query"]),
      owner: blank_to_nil(filters["owner"]),
      tags: split_tags(filters["tags"]),
      lifecycle: maybe_atom(filters["lifecycle"]),
      stale: maybe_atom(filters["stale"]),
      readiness: maybe_atom(filters["readiness"]),
      evidence_quality: maybe_atom(filters["evidence_quality"]),
      include_archived?: filters["include_archived"] == "true",
      limit: String.to_integer(filters["limit"]),
      after: blank_to_nil(filters["after"]),
      before: blank_to_nil(filters["before"])
    ]
  end

  defp environment_links(base_path, filters, environments) do
    Enum.into(environments, %{}, fn environment ->
      env_filters =
        filters
        |> Map.put("env", environment.key)
        |> Map.put("after", nil)
        |> Map.put("before", nil)

      {environment.key, build_index_path(base_path, env_filters)}
    end)
  end

  defp pagination_params(filters) do
    filters
    |> Map.drop(["after", "before"])
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "false" end)
    |> Map.new()
  end

  defp build_index_path(base_path, filters, extras \\ %{}) do
    query =
      filters
      |> ordered_query_params()
      |> Kernel.++(outcome_query_params(extras))
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == "false" end)
      |> URI.encode_query()

    if query == "", do: base_path, else: base_path <> "?" <> query
  end

  defp ordered_query_params(filters) do
    [
      {"env", filters["env"]},
      {"query", filters["query"]},
      {"owner", filters["owner"]},
      {"tags", filters["tags"]},
      {"lifecycle", filters["lifecycle"]},
      {"stale", filters["stale"]},
      {"readiness", filters["readiness"]},
      {"evidence_quality", filters["evidence_quality"]},
      {"include_archived", filters["include_archived"]},
      {"limit", serialize_limit(filters["limit"])},
      {"after", filters["after"]},
      {"before", filters["before"]}
    ]
  end

  defp normalize_filters(params, default_env) do
    params = stringify_keys(params)

    after_cursor = blank_to_nil(params["after"])
    before_cursor = blank_to_nil(params["before"])

    %{
      "env" => blank_to_nil(params["env"]) || default_env,
      "query" => params["query"] || "",
      "owner" => params["owner"] || "",
      "tags" => normalize_tags(params["tags"]),
      "lifecycle" => normalize_enum(params["lifecycle"], @allowed_lifecycle),
      "stale" => normalize_enum(params["stale"], @allowed_stale),
      "readiness" => normalize_enum(params["readiness"], @allowed_readiness),
      "evidence_quality" => normalize_enum(params["evidence_quality"], @allowed_evidence_quality),
      "include_archived" => normalize_boolean(params["include_archived"]),
      "limit" => normalize_limit(params["limit"]),
      "after" => if(before_cursor, do: nil, else: after_cursor),
      "before" => if(after_cursor, do: nil, else: before_cursor)
    }
  end

  defp stringify_keys(params) when is_map(params),
    do: Map.new(params, fn {key, value} -> {to_string(key), value} end)

  defp stringify_keys(_params), do: %{}

  defp normalize_tags(tags) when is_list(tags), do: Enum.join(tags, ", ")
  defp normalize_tags(tags) when is_binary(tags), do: tags |> split_tags() |> Enum.join(", ")
  defp normalize_tags(_tags), do: ""

  defp normalize_enum(value, allowed) when is_binary(value) do
    normalized = blank_to_nil(value)
    if normalized in allowed, do: normalized, else: ""
  end

  defp normalize_enum(_value, _allowed), do: ""

  defp normalize_boolean(value) when value in [true, "true", "on"], do: "true"
  defp normalize_boolean(_value), do: "false"

  defp normalize_limit(value) do
    value
    |> parse_integer()
    |> case do
      limit when limit in [1, 10, 25, 50] -> Integer.to_string(limit)
      _limit -> Integer.to_string(@default_limit)
    end
  end

  defp parse_integer(value) when is_integer(value), do: value

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> @default_limit
    end
  end

  defp parse_integer(_value), do: @default_limit

  defp serialize_limit(limit) do
    if limit == Integer.to_string(@default_limit), do: nil, else: limit
  end

  defp split_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp split_tags(_tags), do: []

  defp maybe_atom(""), do: nil
  defp maybe_atom(nil), do: nil
  defp maybe_atom(value) when is_binary(value), do: String.to_atom(value)
  defp maybe_atom(value) when is_atom(value), do: value

  defp stale_state(%{state: state}) when state in [:potentially_stale, :stale], do: state
  defp stale_state(%{state: _state}), do: :fresh
  defp stale_state(_value), do: :fresh

  defp advisory_note(%{archive_readiness: archive_readiness, freshness: freshness}) do
    cond do
      freshness.code_references == :scan_unknown ->
        "Guidance limited by missing evidence. Recent scan missing."

      freshness.code_references == :scan_stale ->
        "Guidance limited by missing evidence. Recent scan is stale."

      archive_readiness.readiness == :archive_candidate ->
        "Ready for explicit cleanup review."

      archive_readiness.readiness == :keep_active ->
        "Keep active until stronger archive evidence appears."

      true ->
        "Manual review recommended before cleanup."
    end
  end

  defp normalize_outcome_params(params) do
    params
    |> stringify_keys()
    |> Map.take(["notice", "flag_key", "reason", "audit_path", "highlight"])
    |> Enum.into(%{}, fn {key, value} -> {key, blank_to_nil(value)} end)
  end

  defp outcome_notice(%{"notice" => "archived", "flag_key" => flag_key}, environment_name)
       when is_binary(flag_key) do
    "Archived #{flag_key} in #{environment_name}. Review the audit timeline for the recorded reason."
  end

  defp outcome_notice(_outcome, _environment_name), do: nil

  defp normalize_audit_path(_socket, nil), do: nil

  defp normalize_audit_path(socket, path) do
    parsed = URI.parse(path)
    mount_path = socket.assigns.rulestead_admin_mount_path

    cond do
      parsed.scheme not in [nil, ""] -> nil
      parsed.host not in [nil, ""] -> nil
      parsed.path == mount_path -> path
      is_binary(parsed.path) and String.starts_with?(parsed.path, mount_path <> "/") -> path
      true -> nil
    end
  end

  defp show_cleanup_link?(%{archive_readiness: %{readiness: readiness}})
       when readiness in [:archive_candidate, :needs_review],
       do: true

  defp show_cleanup_link?(%{state: state}) when state in [:stale, :potentially_stale], do: true
  defp show_cleanup_link?(_lifecycle), do: false

  defp default_filters do
    %{
      "env" => nil,
      "query" => "",
      "owner" => "",
      "tags" => "",
      "lifecycle" => "",
      "stale" => "",
      "readiness" => "",
      "evidence_quality" => "",
      "include_archived" => "false",
      "limit" => Integer.to_string(@default_limit),
      "after" => nil,
      "before" => nil
    }
  end

  defp empty_page do
    %Rulestead.Store.Command.Page{entries: [], limit: @default_limit}
  end

  defp preset_path(base_path, filters, params) do
    merged_filters =
      filters
      |> Map.merge(%{"after" => nil, "before" => nil})
      |> Map.merge(params)

    build_index_path(base_path, merged_filters)
  end

  defp outcome_query_params(extras) do
    [
      {"notice", extras["notice"]},
      {"flag_key", extras["flag_key"]},
      {"reason", extras["reason"]},
      {"audit_path", extras["audit_path"]},
      {"highlight", extras["highlight"]}
    ]
  end

  defp flag_path(socket_or_assigns, key) do
    Session.path_with_return_to(
      socket_or_assigns,
      "#{socket_or_assigns.base_path}/#{key}",
      socket_or_assigns.current_path
    )
  end

  defp cleanup_path(socket_or_assigns, key) do
    Session.path_with_return_to(
      socket_or_assigns,
      "#{socket_or_assigns.base_path}/#{key}/cleanup",
      socket_or_assigns.current_path
    )
  end

  defp path_with_query(uri) do
    parsed = URI.parse(uri)

    if is_nil(parsed.query),
      do: parsed.path || "/admin/flags",
      else: parsed.path <> "?" <> parsed.query
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

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp humanize(value) when is_atom(value), do: humanize(to_string(value))

  defp humanize(value) when is_binary(value),
    do: value |> String.replace("_", " ") |> String.capitalize()

  defp humanize(value), do: to_string(value)

  defp format_last_changed(nil), do: "Not recorded"

  defp format_last_changed(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_last_changed(%NaiveDateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_last_changed(value), do: to_string(value)
end
t_changed(value), do: to_string(value)
end

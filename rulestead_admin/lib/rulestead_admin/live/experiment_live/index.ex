# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.ExperimentLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, Shell}

  @default_limit 25
  @allowed_lifecycle ~w(active potentially_stale stale archived)
  @allowed_stale ~w(fresh potentially_stale stale)

  @impl true
  def mount(_params, _session, socket) do
    base_path = fetch_mount_path(socket) <> "/experiments"

    socket =
      socket
      |> assign(:screen_action, :index)
      |> assign(:base_path, base_path)
      |> assign(:filters, default_filters())
      |> assign(:page, empty_page())
      |> assign(:error_message, nil)
      |> assign(:allowed_lifecycle, @allowed_lifecycle)
      |> assign(:allowed_stale, @allowed_stale)
      |> stream_configure(:experiments, dom_id: &"experiment-#{&1.flag.key}")
      |> stream(:experiments, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, uri, socket) do
    merged_params = Map.merge(query_params(uri), stringify_keys(params))
    filters = normalize_filters(merged_params, socket.assigns.current_environment.key)
    current_path = path_with_query(uri, socket.assigns.base_path)
    canonical_path = build_index_path(socket.assigns.base_path, filters)

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
        |> load_experiments(filters)

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
      page_title="Experiments"
      page_kicker="Experiment inventory"
      page_summary="Dense operator inventory for experiments scoped to the current environment."
      base_path={@rulestead_admin_mount_path}
      current_section={:experiments}
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
    >
      <section class="rs-inventory">
        <header class="rs-inventory__intro">
          <h2>Experiment inventory</h2>
          <p>Flag key, lifecycle, freshness, and environment state stay visible for fast experiment review.</p>
        </header>

        <form aria-label="Experiment filters" phx-change="filters_changed" class="rs-filter-grid">
          <input type="hidden" name="filters[env]" value={@current_environment.key} />
          <label>
            <span>Search</span>
            <input type="text" name="filters[query]" value={@filters["query"]} phx-debounce="300" />
          </label>
          <label>
            <span>Owner</span>
            <input type="text" name="filters[owner]" value={@filters["owner"]} phx-debounce="300" />
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
          <label class="rs-filter-grid__checkbox">
            <input type="hidden" name="filters[include_archived]" value="false" />
            <input type="checkbox" name="filters[include_archived]" value="true" checked={@filters["include_archived"] == "true"} />
            <span>Include archived</span>
          </label>
        </form>

        <p :if={@error_message} role="alert"><%= @error_message %></p>

        <table role="grid" aria-label="Experiment inventory table" class="rs-table">
          <caption class="sr-only">Experiment inventory table</caption>
          <thead>
            <tr>
              <th scope="col">Flag key</th>
              <th scope="col">Type</th>
              <th scope="col">Owner</th>
              <th scope="col">Lifecycle</th>
              <th scope="col">Environment status</th>
              <th scope="col">Stale indicator</th>
              <th scope="col">Last changed</th>
            </tr>
          </thead>
          <tbody id="experiments" phx-update="stream">
            <tr :for={{dom_id, entry} <- @streams.experiments} id={dom_id} data-flag-key={entry.flag.key} tabindex="0">
              <td>
                <a href={experiment_path(@base_path, entry.flag.key, @current_environment.key)}>
                  <code><%= entry.flag.key %></code>
                </a>
                <FlagComponents.tag_list tags={entry.flag.tags} />
              </td>
              <td><%= humanize(entry.flag.flag_type) %></td>
              <td><%= entry.flag.ownership.owner_display || entry.flag.ownership.owner_ref %></td>
              <td><FlagComponents.lifecycle_badge state={entry.lifecycle} /></td>
              <td><FlagComponents.environment_status status={entry.environment_status || entry.flag_environment.status || :draft} /></td>
              <td>
                <FlagComponents.stale_badge state={stale_state(entry.lifecycle)} last_evaluated_at={entry.lifecycle.last_evaluated_at} />
              </td>
              <td><%= format_last_changed(entry.flag.updated_at || entry.flag.inserted_at) %></td>
            </tr>
            <tr :if={Enum.empty?(@page.entries)}>
              <td colspan="7">No experiments matched the current environment and filters.</td>
            </tr>
          </tbody>
        </table>

        <FlagComponents.pagination page={@page} base_path={@base_path} params={pagination_params(@filters)} />
      </section>
    </Shell.page>
    """
  end

  defp load_experiments(socket, filters) do
    opts = list_opts(filters)

    case Rulestead.list_flags(opts) do
      {:ok, page} ->
        socket
        |> assign(:page, page)
        |> assign(:error_message, nil)
        |> stream(:experiments, page.entries, reset: true)

      {:error, error} ->
        socket
        |> assign(:page, empty_page())
        |> assign(:error_message, error.message)
        |> stream(:experiments, [], reset: true)
    end
  end

  defp list_opts(filters) do
    [
      flag_type: :experiment,
      environment_key: filters["env"],
      query: blank_to_nil(filters["query"]),
      owner: blank_to_nil(filters["owner"]),
      tags: split_tags(filters["tags"]),
      lifecycle: maybe_atom(filters["lifecycle"]),
      stale: maybe_atom(filters["stale"]),
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

  defp build_index_path(base_path, filters) do
    query =
      filters
      |> ordered_query_params()
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

  defp default_filters do
    %{
      "env" => nil,
      "query" => "",
      "owner" => "",
      "tags" => "",
      "lifecycle" => "",
      "stale" => "",
      "include_archived" => "false",
      "limit" => Integer.to_string(@default_limit),
      "after" => nil,
      "before" => nil
    }
  end

  defp empty_page do
    %Rulestead.Store.Command.Page{entries: [], limit: @default_limit}
  end

  defp experiment_path(base_path, key, env), do: "#{base_path}/#{key}?env=#{env}"

  defp path_with_query(uri, default_path) do
    parsed = URI.parse(uri)

    if is_nil(parsed.query),
      do: parsed.path || default_path,
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

  defp fetch_mount_path(%Phoenix.LiveView.Socket{} = socket),
    do: socket.assigns.rulestead_admin_mount_path

  defp fetch_mount_path(%{rulestead_admin_mount_path: mount_path}), do: mount_path
  defp fetch_mount_path(_), do: ""

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

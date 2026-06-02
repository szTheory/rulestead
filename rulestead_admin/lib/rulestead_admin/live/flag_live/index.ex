# credo:disable-for-this-file
defmodule RulesteadAdmin.Live.FlagLive.Index do
  @moduledoc false

  use Phoenix.LiveView

  alias RulesteadAdmin.Components.{FlagComponents, OperatorComponents, Shell}
  alias RulesteadAdmin.Live.Session

  @default_limit 10
  @allowed_lifecycle ~w(active potentially_stale stale archived)
  @allowed_stale ~w(fresh potentially_stale stale)
  @allowed_readiness ~w(keep_active needs_review archive_candidate)
  @allowed_evidence_quality ~w(strong partial weak)
  @allowed_views ~w(all needs_review archive_candidates recently_stale archived custom)
  @inventory_views [
    {"all", "All flags",
     %{
       "readiness" => "",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"needs_review", "Review needed",
     %{
       "readiness" => "needs_review",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"archive_candidates", "Ready to archive",
     %{
       "readiness" => "archive_candidate",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"recently_stale", "Stale signal",
     %{
       "stale" => "stale",
       "readiness" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"archived", "Archived",
     %{
       "lifecycle" => "archived",
       "include_archived" => "true",
       "stale" => "",
       "readiness" => "",
       "evidence_quality" => ""
     }}
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
      |> assign(:inventory_views, @inventory_views)
      |> assign(:omnisearch_suggestions, %{flags: [], owners: [], tags: []})
      |> assign(:omnisearch_input, "")
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
        |> assign(:omnisearch_input, "")
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
  def handle_event("omnisearch_changed", params, socket) do
    input = omnisearch_input_from_params(params)

    {:noreply, apply_transient_omnisearch(socket, input)}
  end

  @impl true
  def handle_event("filters_changed", %{"filters" => filters}, socket) do
    filters =
      case Map.get(filters, "query_text") do
        nil ->
          filters

        "" ->
          filters

        query_text ->
          Map.put(filters, "query", combined_query(socket.assigns.filters["query"], query_text))
      end

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
  def handle_event("filters_changed", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("select_omnisearch_suggestion", %{"value" => value}, socket) do
    filters =
      socket.assigns.filters
      |> Map.put("query", combined_query(socket.assigns.filters["query"], value))
      |> reset_pagination()

    {:noreply, patch_filters(socket, filters)}
  end

  @impl true
  def handle_event("remove_omnisearch_token", %{"value" => value}, socket) do
    filters =
      socket.assigns.filters
      |> Map.put("query", remove_query_token(socket.assigns.filters["query"], value))
      |> reset_pagination()

    {:noreply, patch_filters(socket, filters)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Shell.page
      page_title="Flags"
      page_kicker="Feature flags"
      page_summary="Operator view scoped to the current environment. Manage, debug, and govern all feature flags from here."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
      policy_state={@rulestead_admin_policy_state}
      navigation_links={site_nav_links(@base_path, @current_environment, :flags)}
    >
      <FlagComponents.callout :if={@outcome_notice} title="Archive result" tone="positive">
        <p><%= @outcome_notice %></p>
        <p :if={@outcome_audit_path}>
          <a href={@outcome_audit_path}>Open audit timeline</a>
        </p>
      </FlagComponents.callout>

      <section class="rs-inventory">
        <div
          :if={@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?}
          class="rs-inventory__toolbar"
        >
          <a
            href={@base_path <> "/new?env=" <> @current_environment.key}
            class="rs-button rs-button--primary"
          >
            Create flag
          </a>
        </div>

        <form
          id="flag-filters-form"
          aria-label="Flag filters"
          phx-submit="filters_changed"
          class="rs-filter-panel"
          onsubmit="return false;"
        >
          <input type="hidden" name="filters[env]" value={@current_environment.key} />
          <input :if={@filters["view"] == "custom"} type="hidden" name="filters[lifecycle]" value={@filters["lifecycle"]} />
          <input :if={@filters["view"] == "custom"} type="hidden" name="filters[stale]" value={@filters["stale"]} />
          <input :if={@filters["view"] == "custom"} type="hidden" name="filters[readiness]" value={@filters["readiness"]} />
          <input :if={@filters["view"] == "custom"} type="hidden" name="filters[evidence_quality]" value={@filters["evidence_quality"]} />
          <input :if={@filters["view"] == "custom"} type="hidden" name="filters[include_archived]" value={@filters["include_archived"]} />
          <input type="hidden" name="filters[view]" value={@filters["view"]} />
          <input type="hidden" name="filters[sort]" value={@filters["sort"]} />
          <input type="hidden" name="filters[query]" value={@filters["query"]} />

          <div class="rs-filter-panel__header">
            <div class="rs-filter-panel__search rs-omnisearch">
              <label for="flag-omnisearch-input" class="sr-only">Search</label>
              <div class="rs-omnisearch__control">
                <span
                  :for={token <- query_tokens(@filters["query"])}
                  class="rs-omnisearch__token"
                  data-token={token}
                >
                  <span :if={scoped_query_token?(token)} class="rs-omnisearch__token-scope">
                    <%= query_token_scope(token) %>
                  </span>
                  <span class="rs-omnisearch__token-value"><%= query_token_value(token) %></span>
                  <.link
                    patch={omnisearch_remove_token_path(assigns, token)}
                    aria-label={"Remove #{query_token_label(token)}"}
                    class="rs-omnisearch__token-remove"
                  >
                    <svg viewBox="0 0 16 16" aria-hidden="true">
                      <path d="M4.5 4.5 11.5 11.5M11.5 4.5 4.5 11.5" />
                    </svg>
                  </.link>
                </span>
                <input id="flag-omnisearch-input" type="text" name="filters[query_text]" value={@omnisearch_input} placeholder="Search key, owner, tag, or description..." phx-change="omnisearch_changed" phx-debounce="300" />
              </div>
              <div :if={show_omnisearch_suggestions?(@omnisearch_input, @omnisearch_suggestions)} class="rs-omnisearch__menu" role="listbox" aria-label="Search suggestions">
                <div :if={@omnisearch_suggestions.flags != []} class="rs-omnisearch__group">
                  <p>Flags</p>
                  <.link
                    :for={flag <- @omnisearch_suggestions.flags}
                    patch={omnisearch_suggestion_path(assigns, "key", flag)}
                    role="option"
                    class="rs-omnisearch__option"
                  >
                    <span class="rs-omnisearch__option-scope">key</span>
                    <code><%= flag %></code>
                  </.link>
                </div>
                <div :if={@omnisearch_suggestions.owners != []} class="rs-omnisearch__group">
                  <p>Owners</p>
                  <.link
                    :for={owner <- @omnisearch_suggestions.owners}
                    patch={omnisearch_suggestion_path(assigns, "owner", owner)}
                    role="option"
                    class="rs-omnisearch__option"
                  >
                    <span class="rs-omnisearch__option-scope">owner</span>
                    <span><%= owner %></span>
                  </.link>
                </div>
                <div :if={@omnisearch_suggestions.tags != []} class="rs-omnisearch__group">
                  <p>Tags</p>
                  <.link
                    :for={tag <- @omnisearch_suggestions.tags}
                    patch={omnisearch_suggestion_path(assigns, "tag", tag)}
                    role="option"
                    class="rs-omnisearch__option"
                  >
                    <span class="rs-omnisearch__option-scope">tag</span>
                    <span><%= tag %></span>
                  </.link>
                </div>
              </div>
            </div>
          </div>

          <nav class="rs-inventory-views" aria-label="Flag inventory views">
            <.link
              :for={{view, label, _params} <- @inventory_views}
              patch={inventory_view_path(assigns, view)}
              data-current={to_string(@filters["view"] == view)}
              aria-current={if @filters["view"] == view, do: "page", else: nil}
            >
              <%= label %>
            </.link>
            <.link
              :if={@filters["view"] == "custom"}
              patch={build_index_path(@base_path, @filters)}
              data-current="true"
              aria-current="page"
            >
              Custom
            </.link>
          </nav>

          <span :if={@filters["view"] == "custom"} class="rs-filter-panel__hint">
            Custom view from URL filters
          </span>
        </form>

        <p :if={@error_message} role="alert"><%= @error_message %></p>

        <div class="rs-results-header">
          <div>
            <h3>
              Feature flags (<%= length(@page.entries) %><%= if @page.has_next_page?, do: "+", else: "" %>)
            </h3>
            <p :if={view_explanation(@filters["view"])} class="rs-results-header__hint">
              <%= view_explanation(@filters["view"]) %>
            </p>
          </div>
          <form class="rs-results-sort" aria-label="Sort flags" phx-change="filters_changed">
            <label>
              <span>Sort</span>
              <select name="filters[sort]">
                <option value="flag_key" selected={@filters["sort"] == "flag_key"}>Key A-Z</option>
                <option value="updated_at" selected={@filters["sort"] == "updated_at"}>Recently updated</option>
                <option value="inserted_at" selected={@filters["sort"] == "inserted_at"}>Newest first</option>
              </select>
            </label>
          </form>
        </div>

        <ul id="flags" phx-update="stream" aria-label="Feature flags list" class="rs-card-list">
          <li
            :for={{dom_id, entry} <- @streams.flags}
            id={dom_id}
            data-flag-key={entry.flag.key}
            data-highlighted={to_string(@highlighted_flag_key == entry.flag.key)}
            tabindex="0"
            class="rs-card rs-card--flag"
          >
            <div class="rs-card__header">
              <div class="rs-card__title-group">
                <a href={flag_path(assigns, entry.flag.key)} class="rs-card__title-link">
                  <code><%= entry.flag.key %></code>
                </a>
                <FlagComponents.environment_status status={entry.environment_status || entry.flag_environment.status || :draft} />
              </div>
              <div class="rs-card__actions">
                <%= if stale_state(entry.lifecycle) in [:stale, :potentially_stale] do %>
                  <a href={cleanup_path(assigns, entry.flag.key)}>
                    <FlagComponents.stale_badge state={stale_state(entry.lifecycle)} last_evaluated_at={entry.lifecycle.last_evaluated_at} />
                  </a>
                <% else %>
                  <FlagComponents.stale_badge state={stale_state(entry.lifecycle)} last_evaluated_at={entry.lifecycle.last_evaluated_at} />
                <% end %>
              </div>
            </div>

            <div class="rs-card__body">
              <p class="rs-card__description">
                <%= entry.flag.description || "No description provided." %>
              </p>
            </div>

            <.triage_note
              view={@filters["view"]}
              entry={entry}
              cleanup_path={cleanup_path(assigns, entry.flag.key)}
              timeline_path={timeline_path(assigns, entry.flag.key)}
            />

            <div class="rs-card__footer">
              <div class="rs-card__meta">
                <span class="rs-card__meta-item" data-meta="lifecycle" title="Lifecycle">
                  <.meta_icon name="lifecycle" />
                  <span class="sr-only">Lifecycle:</span>
                  <%= lifecycle_label(entry.lifecycle) %>
                </span>
                <span class="rs-card__meta-item" data-meta="owner" title="Owner">
                  <.meta_icon name="owner" />
                  <span class="sr-only">Owner:</span>
                  <%= entry.flag.ownership.owner_display || entry.flag.ownership.owner_ref %>
                </span>
                <span class="rs-card__meta-item" data-meta="type" title="Type">
                  <.meta_icon name="type" />
                  <span class="sr-only">Type:</span>
                  <%= humanize(entry.flag.flag_type) %>
                </span>
                <span class="rs-card__meta-item" title="Last changed">
                  <strong>Last changed:</strong>
                  <span title={format_last_changed_utc(entry.flag.updated_at || entry.flag.inserted_at)}>
                    <%= format_last_changed_relative(entry.flag.updated_at || entry.flag.inserted_at) %>
                  </span>
                </span>
              </div>
              <div class="rs-card__tags">
                <FlagComponents.tag_list tags={entry.flag.tags} />
              </div>
            </div>
          </li>
        </ul>

        <OperatorComponents.empty_state
          :if={Enum.empty?(@page.entries)}
          id="flags-empty"
          title="No flags found"
          body="Try adjusting your filters or search query, or create a new flag."
          icon="!"
          variant="hero"
        />

        <FlagComponents.pagination page={@page} base_path={@base_path} params={pagination_params(@filters)} />
      </section>
    </Shell.page>
    """
  end

  defp load_flags(socket, filters, suggestion_query \\ nil) do
    opts = list_opts(filters)
    suggestion_query = if is_nil(suggestion_query), do: filters["query"], else: suggestion_query

    case Rulestead.list_flags(opts) do
      {:ok, page} ->
        socket
        |> assign(:page, page)
        |> assign(:error_message, nil)
        |> assign_omnisearch_suggestions(filters, suggestion_query)
        |> stream(:flags, page.entries, reset: true)

      {:error, error} ->
        socket
        |> assign(:page, empty_page())
        |> assign(:error_message, error.message)
        |> assign(:omnisearch_suggestions, %{flags: [], owners: [], tags: []})
        |> stream(:flags, [], reset: true)
    end
  end

  defp assign_omnisearch_suggestions(socket, filters, suggestion_query) do
    suggestions =
      filters
      |> suggestion_opts()
      |> Rulestead.list_flags()
      |> case do
        {:ok, page} -> build_omnisearch_suggestions(page.entries, suggestion_query)
        {:error, _error} -> %{flags: [], owners: [], tags: []}
      end

    assign(socket, :omnisearch_suggestions, suggestions)
  end

  defp suggestion_opts(filters) do
    filters
    |> Map.put("query", "")
    |> Map.put("limit", "100")
    |> Map.put("after", nil)
    |> Map.put("before", nil)
    |> list_opts()
  end

  defp build_omnisearch_suggestions(entries, query) do
    %{
      flags:
        entries
        |> Enum.map(& &1.flag.key)
        |> matching_suggestions(query, 5),
      owners:
        entries
        |> Enum.flat_map(fn entry ->
          ownership = entry.flag.ownership || %{}
          [ownership.owner_ref, ownership.owner_display]
        end)
        |> matching_suggestions(query, 5),
      tags:
        entries
        |> Enum.flat_map(&(&1.flag.tags || []))
        |> matching_suggestions(query, 5)
    }
  end

  defp compact_sorted(values) do
    values
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp apply_transient_omnisearch(socket, input) do
    effective_filters =
      socket.assigns.filters
      |> Map.put("query", combined_query(socket.assigns.filters["query"], input))
      |> reset_pagination()

    socket
    |> assign(:omnisearch_input, input)
    |> load_flags(effective_filters, input)
  end

  defp omnisearch_input_from_params(%{"filters" => %{"query_text" => query_text}})
       when query_text != "",
       do: query_text

  defp omnisearch_input_from_params(%{"value" => value}) when is_binary(value), do: value
  defp omnisearch_input_from_params(%{"filters" => %{"query_text" => query_text}}), do: query_text
  defp omnisearch_input_from_params(_params), do: ""

  defp combined_query(committed_query, input) do
    [committed_query, input]
    |> Enum.flat_map(&query_tokens/1)
    |> compact_unique()
    |> Enum.join(" ")
  end

  defp scoped_query_token?(token) do
    match?(
      {scope, value} when scope in ["key", "owner", "tag"] and value != "",
      split_scoped_query_token(token)
    )
  end

  defp query_token_scope(token) do
    case split_scoped_query_token(token) do
      {scope, value} when scope in ["key", "owner", "tag"] and value != "" -> scope
      _other -> nil
    end
  end

  defp query_token_value(token) do
    case split_scoped_query_token(token) do
      {scope, value} when scope in ["key", "owner", "tag"] and value != "" -> value
      _other -> token
    end
  end

  defp query_token_label(token) do
    case split_scoped_query_token(token) do
      {scope, value} when scope in ["key", "owner", "tag"] and value != "" -> "#{scope}:#{value}"
      _other -> token
    end
  end

  defp scoped_query_value(scope, value) do
    scope = scope |> to_string() |> String.downcase()
    value = value |> to_string() |> String.trim()

    if scope in ["key", "owner", "tag"] and value != "" do
      "#{scope}:#{value}"
    else
      value
    end
  end

  defp split_scoped_query_token(token) when is_binary(token) do
    case String.split(token, ":", parts: 2) do
      [scope, value] -> {String.downcase(scope), value}
      _other -> nil
    end
  end

  defp split_scoped_query_token(_token), do: nil

  defp remove_query_token(query, token) do
    query
    |> query_tokens()
    |> Enum.reject(&(&1 == token))
    |> Enum.join(" ")
  end

  defp list_opts(filters) do
    [
      environment_key: filters["env"],
      query: blank_to_nil(filters["query"]),
      lifecycle: maybe_atom(filters["lifecycle"]),
      stale: maybe_atom(filters["stale"]),
      readiness: maybe_atom(filters["readiness"]),
      evidence_quality: maybe_atom(filters["evidence_quality"]),
      include_archived?: filters["include_archived"] == "true",
      limit: String.to_integer(filters["limit"] || Integer.to_string(@default_limit)),
      sort: maybe_atom(filters["sort"]),
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

  defp patch_filters(socket, filters) do
    push_patch(socket,
      to:
        build_index_path(
          socket.assigns.base_path,
          normalize_filters(filters, socket.assigns.current_environment.key)
        )
    )
  end

  defp reset_pagination(filters) do
    filters
    |> Map.put("after", nil)
    |> Map.put("before", nil)
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
      {"view", filters["view"]},
      {"query", filters["query"]},
      {"lifecycle", custom_filter_param(filters, "lifecycle")},
      {"stale", custom_filter_param(filters, "stale")},
      {"readiness", custom_filter_param(filters, "readiness")},
      {"evidence_quality", custom_filter_param(filters, "evidence_quality")},
      {"include_archived", custom_filter_param(filters, "include_archived")},
      {"limit", serialize_limit(filters["limit"])},
      {"sort", serialize_sort(filters["sort"])},
      {"after", filters["after"]},
      {"before", filters["before"]}
    ]
  end

  defp normalize_filters(params, default_env) do
    params = stringify_keys(params)

    after_cursor = blank_to_nil(params["after"])
    before_cursor = blank_to_nil(params["before"])
    query = normalize_query(params)

    filters = %{
      "env" => blank_to_nil(params["env"]) || default_env,
      "query" => query,
      "view" => normalize_enum(params["view"], @allowed_views),
      "lifecycle" => normalize_enum(params["lifecycle"], @allowed_lifecycle),
      "stale" => normalize_enum(params["stale"], @allowed_stale),
      "readiness" => normalize_enum(params["readiness"], @allowed_readiness),
      "evidence_quality" => normalize_enum(params["evidence_quality"], @allowed_evidence_quality),
      "include_archived" => normalize_boolean(params["include_archived"]),
      "limit" => normalize_limit(params["limit"]),
      "sort" => normalize_sort(params["sort"]),
      "after" => if(before_cursor, do: nil, else: after_cursor),
      "before" => if(after_cursor, do: nil, else: before_cursor)
    }

    normalize_view_filters(filters, Map.has_key?(params, "view"))
  end

  defp stringify_keys(params) when is_map(params),
    do: Map.new(params, fn {key, value} -> {to_string(key), value} end)

  defp stringify_keys(_params), do: %{}

  defp normalize_query(params) do
    [
      params["query"],
      params["owner"],
      params["tags"]
    ]
    |> Enum.flat_map(&query_tokens/1)
    |> compact_unique()
    |> Enum.join(" ")
  end

  defp compact_unique(values) do
    Enum.reduce(values, [], fn value, acc ->
      cond do
        is_nil(value) or value == "" -> acc
        value in acc -> acc
        true -> acc ++ [value]
      end
    end)
  end

  defp query_tokens(value) when is_binary(value) do
    value
    |> String.split([",", " "])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp query_tokens(value) when is_list(value), do: Enum.flat_map(value, &query_tokens/1)
  defp query_tokens(_value), do: []

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
      limit when limit in [10, 25, 50, 100] -> Integer.to_string(limit)
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

  defp normalize_sort(sort) when sort in ["flag_key", "updated_at", "inserted_at"], do: sort
  defp normalize_sort(_sort), do: "flag_key"

  defp serialize_sort("flag_key"), do: nil
  defp serialize_sort(sort), do: sort

  defp custom_filter_param(%{"view" => "custom"} = filters, key), do: Map.get(filters, key)
  defp custom_filter_param(_filters, _key), do: nil

  defp maybe_atom(""), do: nil
  defp maybe_atom(nil), do: nil
  defp maybe_atom(value) when is_binary(value), do: String.to_atom(value)
  defp maybe_atom(value) when is_atom(value), do: value

  defp stale_state(%{state: state}) when state in [:potentially_stale, :stale], do: state
  defp stale_state(%{state: _state}), do: :fresh
  defp stale_state(_value), do: :fresh

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

  defp default_filters do
    %{
      "env" => nil,
      "query" => "",
      "view" => "all",
      "lifecycle" => "",
      "stale" => "",
      "readiness" => "",
      "evidence_quality" => "",
      "include_archived" => "false",
      "limit" => Integer.to_string(@default_limit),
      "sort" => "flag_key",
      "after" => nil,
      "before" => nil
    }
  end

  defp empty_page do
    %Rulestead.Store.Command.Page{entries: [], limit: @default_limit}
  end

  defp normalize_view_filters(%{"view" => view} = filters, true)
       when view in ["all", "needs_review", "archive_candidates", "recently_stale", "archived"] do
    filters
    |> apply_view(view)
    |> Map.put("view", view)
  end

  defp normalize_view_filters(%{"view" => "custom"} = filters, true), do: filters

  defp normalize_view_filters(filters, _view_provided?) do
    case matching_inventory_view(filters) do
      nil -> Map.put(filters, "view", "custom")
      view -> filters |> apply_view(view) |> Map.put("view", view)
    end
  end

  defp apply_view(filters, view) do
    filters
    |> Map.merge(inventory_view_params(view))
    |> Map.put("after", nil)
    |> Map.put("before", nil)
  end

  defp matching_inventory_view(filters) do
    Enum.find_value(@inventory_views, fn {view, _label, params} ->
      if view_params_match?(filters, params), do: view
    end)
  end

  defp matching_suggestions(suggestions, query, limit) do
    query =
      query
      |> query_token_value()
      |> to_string()
      |> String.downcase()
      |> String.trim()

    suggestions
    |> compact_sorted()
    |> Enum.filter(fn suggestion ->
      query == "" or String.contains?(String.downcase(suggestion), query)
    end)
    |> Enum.take(limit)
  end

  defp show_omnisearch_suggestions?(query, suggestions) do
    query != "" and
      Enum.any?([suggestions.flags, suggestions.owners, suggestions.tags], &(&1 != []))
  end

  defp view_params_match?(filters, params) do
    Enum.all?(
      ["lifecycle", "stale", "readiness", "evidence_quality", "include_archived"],
      fn key ->
        Map.get(filters, key) == Map.get(params, key, "")
      end
    )
  end

  defp inventory_view_params(view) do
    @inventory_views
    |> Enum.find_value(%{}, fn
      {^view, _label, params} -> params
      _other -> nil
    end)
  end

  defp inventory_view_path(assigns, view) do
    filters =
      assigns.filters
      |> apply_view(view)
      |> Map.put("view", view)

    build_index_path(assigns.base_path, filters)
  end

  defp omnisearch_suggestion_path(assigns, scope, value) do
    scoped_value = scoped_query_value(scope, value)

    filters =
      assigns.filters
      |> Map.put("query", combined_query(assigns.filters["query"], scoped_value))
      |> reset_pagination()

    build_index_path(assigns.base_path, filters)
  end

  defp omnisearch_remove_token_path(assigns, token) do
    filters =
      assigns.filters
      |> Map.put("query", remove_query_token(assigns.filters["query"], token))
      |> reset_pagination()

    build_index_path(assigns.base_path, filters)
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

  defp timeline_path(socket_or_assigns, key) do
    Session.path_with_return_to(
      socket_or_assigns,
      "#{socket_or_assigns.base_path}/#{key}/timeline",
      socket_or_assigns.current_path
    )
  end

  attr(:view, :string, required: true)
  attr(:entry, :map, required: true)
  attr(:cleanup_path, :string, required: true)
  attr(:timeline_path, :string, required: true)

  defp triage_note(assigns) do
    assigns = assign(assigns, :summary, triage_summary(assigns.view, assigns.entry))

    ~H"""
    <div :if={@summary} class="rs-triage-note" data-tone={@summary.tone}>
      <div class="rs-triage-note__copy">
        <strong><%= @summary.title %></strong>
        <span><%= @summary.detail %></span>
      </div>
      <a :if={@summary.action == :cleanup} href={@cleanup_path}>Review cleanup</a>
      <a :if={@summary.action == :timeline} href={@timeline_path}>Open timeline</a>
    </div>
    """
  end

  defp triage_summary("needs_review", entry) do
    readiness = entry.lifecycle.archive_readiness

    detail =
      [
        first_reason_label(readiness),
        first_unknown_or_blocker_label(readiness),
        next_action_label(readiness)
      ]
      |> compact_sentence_parts()

    %{
      title: "Review needed",
      detail: detail || "Lifecycle evidence needs an operator decision.",
      tone: "warning",
      action: :cleanup
    }
  end

  defp triage_summary("archive_candidates", entry) do
    readiness = entry.lifecycle.archive_readiness

    detail =
      [
        first_reason_label(readiness),
        evidence_label(readiness.evidence_quality),
        next_action_label(readiness)
      ]
      |> compact_sentence_parts()

    %{
      title: "Ready to archive",
      detail: detail || "Strong cleanup evidence is available.",
      tone: "critical",
      action: :cleanup
    }
  end

  defp triage_summary("recently_stale", entry) do
    freshness = entry.lifecycle.freshness

    detail =
      [
        freshness_label(freshness.evaluation),
        last_evaluated_label(entry.lifecycle.last_evaluated_at),
        code_reference_label(freshness.code_references)
      ]
      |> compact_sentence_parts()

    %{
      title: "Stale signal",
      detail: detail || "Evaluation evidence is no longer current.",
      tone: "warning",
      action: :cleanup
    }
  end

  defp triage_summary("archived", _entry) do
    %{
      title: "Archived",
      detail: "Removed from active inventory; review the audit timeline for context.",
      tone: "muted",
      action: :timeline
    }
  end

  defp triage_summary(_view, _entry), do: nil

  defp view_explanation("needs_review"),
    do: "Flags with incomplete cleanup evidence, past review dates, or manual review required."

  defp view_explanation("archive_candidates"),
    do: "Flags with strong evidence that they can be cleaned up."

  defp view_explanation("recently_stale"),
    do: "Flags with stale evaluation or rollout activity."

  defp view_explanation("archived"),
    do: "Flags already removed from active runtime posture."

  defp view_explanation(_view), do: nil

  defp compact_sentence_parts(parts) do
    parts
    |> Enum.reject(&(is_nil(&1) or &1 == ""))
    |> Enum.uniq()
    |> case do
      [] -> nil
      values -> Enum.join(values, " · ")
    end
  end

  defp first_reason_label(%{reasons: reasons}) do
    reasons = List.wrap(reasons)

    [
      :no_code_refs,
      :review_horizon_passed,
      :stale_evaluation,
      :never_evaluated,
      :expiring_posture
    ]
    |> Enum.find(&(&1 in reasons))
    |> reason_label()
  end

  defp first_reason_label(_readiness), do: nil

  defp first_unknown_or_blocker_label(%{unknowns: [unknown | _]}), do: unknown_label(unknown)
  defp first_unknown_or_blocker_label(%{blockers: [blocker | _]}), do: blocker_label(blocker)
  defp first_unknown_or_blocker_label(_readiness), do: nil

  defp next_action_label(%{recommended_next_action: nil, secondary_actions: [action | _]}),
    do: action_label(action)

  defp next_action_label(%{recommended_next_action: action}), do: action_label(action)
  defp next_action_label(_readiness), do: nil

  defp evidence_label(:strong), do: "Strong evidence"
  defp evidence_label(:partial), do: "Partial evidence"
  defp evidence_label(:weak), do: "Evidence incomplete"
  defp evidence_label(_quality), do: nil

  defp freshness_label(:not_evaluated_recently), do: "No recent evaluations"
  defp freshness_label(:never_evaluated), do: "Never evaluated"
  defp freshness_label(:recently_evaluated), do: "Recently evaluated"
  defp freshness_label(_evaluation), do: nil

  defp last_evaluated_label(%DateTime{} = datetime),
    do: "Last evaluated #{format_last_changed_relative(datetime)}"

  defp last_evaluated_label(_datetime), do: nil

  defp code_reference_label(:fresh_refs_absent), do: "No code references found"
  defp code_reference_label(:refs_present), do: "Code references still present"
  defp code_reference_label(:scan_unknown), do: "Code-reference scan missing"
  defp code_reference_label(:scan_stale), do: "Code-reference scan stale"
  defp code_reference_label(_value), do: nil

  defp reason_label(:expiring_posture), do: "Expiring flag"
  defp reason_label(:review_horizon_passed), do: "Review date passed"
  defp reason_label(:stale_evaluation), do: "Stale evaluation"
  defp reason_label(:never_evaluated), do: "No evaluation yet"
  defp reason_label(:no_code_refs), do: "No code references found"
  defp reason_label(:already_archived), do: "Already archived"
  defp reason_label(nil), do: nil
  defp reason_label(reason), do: humanize(reason)

  defp unknown_label(:code_refs_scan_missing), do: "Refresh code refs"
  defp unknown_label(:code_refs_scan_stale), do: "Refresh code refs"
  defp unknown_label(:evaluation_missing), do: "Collect evaluation evidence"
  defp unknown_label(nil), do: nil
  defp unknown_label(unknown), do: humanize(unknown)

  defp blocker_label(:protected_flag_type), do: "Protected flag type"
  defp blocker_label(:permanent_posture), do: "Marked permanent"
  defp blocker_label(:remote_config_requires_review), do: "Remote config requires review"
  defp blocker_label(:code_refs_present), do: "Code references still present"
  defp blocker_label(:already_archived), do: "Already archived"
  defp blocker_label(nil), do: nil
  defp blocker_label(blocker), do: humanize(blocker)

  defp action_label(:archive_ready), do: "Archive ready"
  defp action_label(:keep_active), do: "Keep active"
  defp action_label(:review_manually), do: "Review manually"
  defp action_label(:refresh_code_refs), do: "Refresh code refs"
  defp action_label(:collect_eval_evidence), do: "Collect evaluation evidence"
  defp action_label(:remove_code_refs), do: "Remove code references"
  defp action_label(:mark_permanent), do: "Confirm permanent posture"
  defp action_label(nil), do: nil
  defp action_label(action), do: humanize(action)

  attr(:name, :string, required: true)

  defp meta_icon(assigns) do
    ~H"""
    <span class="rs-card__meta-icon" aria-hidden="true">
      <svg :if={@name == "lifecycle"} viewBox="0 0 20 20" fill="none">
        <path d="M4 10h12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
        <path d="M10 6.75v6.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
        <circle cx="4" cy="10" r="1.35" fill="currentColor" />
        <circle cx="10" cy="10" r="1.35" fill="currentColor" />
        <circle cx="16" cy="10" r="1.35" fill="currentColor" />
      </svg>
      <svg :if={@name == "owner"} viewBox="0 0 20 20" fill="none">
        <path d="M10 10.15a3.25 3.25 0 1 0 0-6.5 3.25 3.25 0 0 0 0 6.5Z" stroke="currentColor" stroke-width="1.6" />
        <path d="M4.5 16.35c.75-2.25 2.75-3.55 5.5-3.55s4.75 1.3 5.5 3.55" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
      </svg>
      <svg :if={@name == "type"} viewBox="0 0 20 20" fill="none">
        <path d="M4 6.5h12M4 13.5h12" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
        <path d="M7.5 8.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4ZM12.5 15.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z" fill="currentColor" />
      </svg>
    </span>
    """
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

  defp lifecycle_label(%{mode: :expiring, review_by: %Date{} = review_by}),
    do: "Expires #{Calendar.strftime(review_by, "%b %-d, %Y")}"

  defp lifecycle_label(%{mode: :expiring}), do: "Expiring"
  defp lifecycle_label(%{mode: mode}), do: humanize(mode)
  defp lifecycle_label(value), do: humanize(value)

  defp format_last_changed_utc(nil), do: "Not recorded"

  defp format_last_changed_utc(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_last_changed_utc(%NaiveDateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M UTC")

  defp format_last_changed_utc(value), do: to_string(value)

  defp format_last_changed_relative(nil), do: "Unknown"

  defp format_last_changed_relative(%DateTime{} = datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime)
    relative_time(diff)
  end

  defp format_last_changed_relative(%NaiveDateTime{} = datetime) do
    now = NaiveDateTime.utc_now()
    diff = NaiveDateTime.diff(now, datetime)
    relative_time(diff)
  end

  defp site_nav_links(base_path, env, current) do
    env_q = "?env=#{env.key}"
    sep = %{separator: true, path: "", label: "", current?: false}

    [
      %{label: "Flags", path: base_path <> env_q, current?: current == :flags},
      %{
        label: "Audiences",
        path: base_path <> "/audiences" <> env_q,
        current?: current == :audiences
      },
      %{
        label: "Experiments",
        path: base_path <> "/experiments" <> env_q,
        current?: current == :experiments
      },
      %{label: "Compare", path: base_path <> "/compare" <> env_q, current?: current == :compare},
      sep,
      %{
        label: "Change requests",
        path: base_path <> "/change-requests" <> env_q,
        current?: current == :change_requests
      },
      %{
        label: "Schedule",
        path: base_path <> "/schedule" <> env_q,
        current?: current == :schedule
      },
      %{label: "Audit", path: base_path <> "/audit" <> env_q, current?: current == :audit},
      %{
        label: "Webhooks",
        path: base_path <> "/webhooks" <> env_q,
        current?: current == :webhooks
      },
      sep,
      %{
        label: "Diagnostics",
        path: base_path <> "/diagnostics" <> env_q,
        current?: current == :diagnostics
      }
    ]
  end

  defp format_last_changed_relative(value), do: to_string(value)

  defp relative_time(diff) when diff < 60, do: "just now"

  defp relative_time(diff) when diff < 3600 do
    mins = div(diff, 60)
    "#{mins} minute#{if mins == 1, do: "", else: "s"} ago"
  end

  defp relative_time(diff) when diff < 86400 do
    hours = div(diff, 3600)
    "#{hours} hour#{if hours == 1, do: "", else: "s"} ago"
  end

  defp relative_time(diff) when diff < 2_592_000 do
    days = div(diff, 86400)
    "#{days} day#{if days == 1, do: "", else: "s"} ago"
  end

  defp relative_time(diff) do
    months = div(diff, 2_592_000)
    "#{months} month#{if months == 1, do: "", else: "s"} ago"
  end
end

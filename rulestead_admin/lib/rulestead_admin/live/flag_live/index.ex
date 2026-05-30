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
  @lifecycle_presets [
    {"All flags",
     %{
       "readiness" => "",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"Archive candidates",
     %{
       "readiness" => "archive_candidate",
       "include_archived" => "true",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => ""
     }},
    {"Needs review",
     %{
       "readiness" => "needs_review",
       "stale" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
     }},
    {"Recently stale",
     %{
       "stale" => "stale",
       "readiness" => "",
       "lifecycle" => "",
       "evidence_quality" => "",
       "include_archived" => "false"
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
      |> assign(:lifecycle_presets, @lifecycle_presets)
      |> assign(:show_advanced_filters, false)
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
  def handle_event("toggle_advanced_filters", _, socket) do
    {:noreply, assign(socket, :show_advanced_filters, !socket.assigns.show_advanced_filters)}
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
        <div class="rs-inventory__toolbar" style="margin-bottom: 1rem;">
          <div>
            <h2 class="sr-only">Feature flags filters and actions</h2>
          </div>
          <div :if={@rulestead_admin_policy_state.capabilities.edit? or @rulestead_admin_policy_state.capabilities.admin?}>
            <a href={@base_path <> "/new?env=" <> @current_environment.key} class="rs-button rs-button--primary">Create flag</a>
          </div>
        </div>

        <div class="rs-filter-panel" style="background: var(--rs-color-surface, #fff); border: 1px solid var(--rs-color-border, #e5e7eb); border-radius: 0.5rem; margin-bottom: 2rem; overflow: hidden;">
          <nav aria-label="Lifecycle preset strip" class="rs-filter-presets" style="padding: 1rem 1.5rem; border-bottom: 1px solid var(--rs-color-border, #e5e7eb); background: var(--rs-color-bg-subtle, #f9fafb);">
            <div style="display: flex; flex-wrap: wrap; gap: 1rem; align-items: center; justify-content: space-between;">
              <h3 style="margin: 0; font-size: 0.875rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: var(--rs-color-text-muted, #6b7280);">Quick Views</h3>
              <div class="rs-filter-presets__links" style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                <.link
                  :for={{label, params} <- @lifecycle_presets}
                  patch={preset_path(@base_path, @filters, params)}
                  aria-current={if active_preset?(@filters, params), do: "page", else: nil}
                  class={if active_preset?(@filters, params), do: "rs-filter-preset--active", else: ""}
                  style="padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.875rem; text-decoration: none; border: 1px solid transparent;"
                >
                  <%= label %>
                </.link>
              </div>
            </div>
            <p style="margin: 0.5rem 0 0; font-size: 0.875rem; color: var(--rs-color-text-muted, #6b7280);">
              <strong>Archive candidates</strong> are fully rolled-out flags that haven't been evaluated recently. <strong>Needs review</strong> highlights flags past their intended review date. <strong>Recently stale</strong> shows flags that recently stopped receiving traffic.
            </p>
          </nav>

          <form id="flag-filters-form" aria-label="Flag filters" phx-change="filters_changed" phx-submit="filters_changed" class="rs-filters" style="padding: 1.5rem;" onsubmit="return false;">
            <div class="rs-filter-grid rs-filter-grid--primary">
              <input type="hidden" name="filters[env]" value={@current_environment.key} />
              
              <div style="display: grid; grid-template-columns: 1fr max-content; gap: 1.5rem; grid-column: 1 / -1; margin-bottom: 1.5rem; align-items: center;">
                <label style="margin: 0;">
                  <span class="sr-only">Search</span>
                  <input type="text" name="filters[query]" value={@filters["query"]} placeholder="Search flags by key, tags, or description..." phx-debounce="300" style="width: 100%;" />
                </label>
                <label style="margin: 0; display: flex; align-items: center; gap: 0.75rem;">
                  <span style="font-weight: 500; font-size: 0.875rem; color: var(--rs-color-text-muted, #4b5563); white-space: nowrap;">Sort by</span>
                  <select name="filters[sort]" style="width: auto; margin: 0;">
                    <option value="flag_key" selected={@filters["sort"] == "flag_key"}>Key (A-Z)</option>
                    <option value="updated_at" selected={@filters["sort"] == "updated_at"}>Recently updated</option>
                    <option value="inserted_at" selected={@filters["sort"] == "inserted_at"}>Newest first</option>
                  </select>
                </label>
              </div>

              <div style="grid-column: 1 / -1; display: flex; flex-direction: column; gap: 1.5rem;">
                <fieldset class="rs-radio-group" style="margin: 0; padding: 0; border: none;">
                  <legend style="font-weight: 600; font-size: 0.875rem; margin-bottom: 0.75rem;">Lifecycle state</legend>
                  <div style="display: flex; flex-wrap: wrap; gap: 1.5rem;">
                    <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: 400; margin: 0; cursor: pointer;">
                      <input type="radio" name="filters[lifecycle]" value="" checked={@filters["lifecycle"] == ""} /> All
                    </label>
                    <label :for={state <- @allowed_lifecycle} style="display: flex; align-items: center; gap: 0.5rem; font-weight: 400; margin: 0; cursor: pointer;">
                      <input type="radio" name="filters[lifecycle]" value={state} checked={@filters["lifecycle"] == state} /> <%= humanize(state) %>
                    </label>
                  </div>
                </fieldset>
                
                <fieldset class="rs-radio-group" style="margin: 0; padding: 0; border: none;">
                  <legend style="font-weight: 600; font-size: 0.875rem; margin-bottom: 0.75rem;">Stale status</legend>
                  <div style="display: flex; flex-wrap: wrap; gap: 1.5rem;">
                    <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: 400; margin: 0; cursor: pointer;">
                      <input type="radio" name="filters[stale]" value="" checked={@filters["stale"] == ""} /> All
                    </label>
                    <label :for={state <- @allowed_stale} style="display: flex; align-items: center; gap: 0.5rem; font-weight: 400; margin: 0; cursor: pointer;">
                      <input type="radio" name="filters[stale]" value={state} checked={@filters["stale"] == state} /> <%= humanize(state) %>
                    </label>
                  </div>
                </fieldset>
              </div>

              <div class="rs-filter-grid__actions" style="grid-column: 1 / -1; margin-top: 1rem;">
                <button type="button" phx-click="toggle_advanced_filters" class="rs-link" style="background: none; border: none; padding: 0; color: var(--rs-color-primary, #2563eb); cursor: pointer; font-size: 0.875rem; font-weight: 500; display: inline-flex; align-items: center; gap: 0.375rem;">
                  <%= if @show_advanced_filters do %>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 1.25rem; height: 1.25rem;"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5" /></svg>
                    Hide advanced filters
                  <% else %>
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 1.25rem; height: 1.25rem;"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" /></svg>
                    Show advanced filters
                  <% end %>
                </button>
              </div>
            </div>

            <div class={["rs-filter-grid rs-filter-grid--advanced", not @show_advanced_filters && "hidden"]} style={"margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--rs-color-border, #e5e7eb);" <> (if not @show_advanced_filters, do: " display: none;", else: "")}>
            <label>
              <span>Owner ref</span>
              <input type="text" name="filters[owner]" value={@filters["owner"]} phx-debounce="300" />
            </label>
            <label>
              <span>Tags</span>
              <input type="text" name="filters[tags]" value={@filters["tags"]} placeholder="checkout, infra" phx-debounce="300" />
            </label>
            <label>
              <span>Rows</span>
              <select name="filters[limit]">
                <option :for={limit <- [10, 25, 50, 100]} value={limit} selected={Integer.to_string(limit) == @filters["limit"]}>
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
            <label class="rs-filter-grid__checkbox" style="align-self: flex-end; padding-bottom: 0.5rem;">
              <input type="hidden" name="filters[include_archived]" value="false" />
              <input type="checkbox" name="filters[include_archived]" value="true" checked={@filters["include_archived"] == "true"} />
              <span>Include archived</span>
            </label>
          </div>
        </form>
        </div>

        <p :if={@error_message} role="alert"><%= @error_message %></p>

        <div class="rs-results-header" style="margin-bottom: 1rem;">
          <h3 style="margin: 0; font-size: 1rem; font-weight: 600; color: var(--rs-color-text, #111827);">
            Feature flags (<%= length(@page.entries) %><%= if @page.has_next_page?, do: "+", else: "" %>)
          </h3>
        </div>

        <ul id="flags" phx-update="stream" aria-label="Feature flags list" class="rs-card-list">
          <li
            :for={{dom_id, entry} <- @streams.flags}
            id={dom_id}
            data-flag-key={entry.flag.key}
            data-highlighted={to_string(@highlighted_flag_key == entry.flag.key)}
            tabindex="0"
            class="rs-card rs-card--flag"
            style="margin-bottom: 1rem; padding: 1.5rem; border: 1px solid var(--rs-color-border, #e5e7eb); border-radius: 0.5rem; background: var(--rs-color-surface, #fff);"
          >
            <div class="rs-card__header" style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.5rem;">
              <div class="rs-card__title-group" style="display: flex; align-items: center; gap: 0.75rem;">
                <a href={flag_path(assigns, entry.flag.key)} style="font-size: 1.125rem; font-weight: 600; text-decoration: none;">
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
            
            <div class="rs-card__body" style="margin-bottom: 1.25rem;">
              <p class="rs-card__description" style="color: var(--rs-color-text-muted, #4b5563); margin: 0;">
                <%= entry.flag.description || "No description provided." %>
              </p>
            </div>

            <div class="rs-card__footer" style="display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 1rem; border-top: 1px solid var(--rs-color-border-light, #f3f4f6); padding-top: 1rem; font-size: 0.875rem; color: var(--rs-color-text-muted, #6b7280);">
              <div class="rs-card__meta" style="display: flex; flex-wrap: wrap; gap: 1.5rem;">
                <span class="rs-card__meta-item" title="Lifecycle" style="display: flex; align-items: center; gap: 0.375rem;">
                  <strong>Lifecycle:</strong> <%= humanize(entry.lifecycle.mode) %>
                </span>
                <span class="rs-card__meta-item" title="Owner" style="display: flex; align-items: center; gap: 0.375rem;">
                  <strong>Owner:</strong> <%= entry.flag.ownership.owner_display || entry.flag.ownership.owner_ref %>
                </span>
                <span class="rs-card__meta-item" title="Type" style="display: flex; align-items: center; gap: 0.375rem;">
                  <strong>Type:</strong> <%= humanize(entry.flag.flag_type) %>
                </span>
                <span class="rs-card__meta-item" title="Last changed" style="display: flex; align-items: center; gap: 0.375rem;">
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
          <li :if={Enum.empty?(@page.entries)} id="flags-empty" class="rs-card rs-card--empty" style="padding: 3rem 1rem; text-align: center; border: 1px dashed var(--rs-color-border, #e5e7eb); border-radius: 0.5rem;">
            <div class="rs-empty-state">
              <div class="rs-empty-state__icon" style="margin: 0 auto 1rem; width: 3rem; height: 3rem; color: var(--rs-color-text-muted, #9ca3af);">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <h3 class="rs-empty-state__title" style="font-size: 1.125rem; font-weight: 600; margin-bottom: 0.5rem;">No flags found</h3>
              <p class="rs-empty-state__text" style="color: var(--rs-color-text-muted, #6b7280);">Try adjusting your filters or search query, or create a new flag.</p>
            </div>
          </li>
        </ul>

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

  defp active_preset?(filters, params) do
    Enum.all?(params, fn {key, value} ->
      current = Map.get(filters, key)
      current == value or (value == "" and current in [nil, ""])
    end)
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

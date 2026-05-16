# Phase 18: Experimentation UI & Reporting - Pattern Map

**Mapped:** 2024-05-17
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead_admin/lib/rulestead_admin/live/experiment_live/index.ex` | LiveView | Request-Response | `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex` | LiveView | Request-Response | `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` | exact |
| `rulestead/lib/rulestead/analytics.ex` | Context | Reporting | `rulestead/lib/rulestead.ex` (analytics methods) | role-match |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/live/experiment_live/index.ex` (LiveView List, Request-Response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`

**LiveView Layout & Table Pattern** (lines 48-124):
```elixir
    <Shell.page
      page_title="Flags"
      page_kicker="Flag inventory"
      page_summary="Dense operator inventory scoped to the current environment."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <section class="rs-inventory">
        <div class="rs-inventory__toolbar">
          <div>
            <h2>Flag inventory</h2>
            <p>Monospace key, lifecycle, stale status, and environment state stay visible for fast scanning.</p>
          </div>
          <a href={@base_path <> "/new?env=" <> @current_environment.key}>Create flag</a>
        </div>

        <form aria-label="Flag filters" phx-change="filters_changed" class="rs-filter-grid">
           <!-- Filters pattern -->
        </form>

        <p :if={@error_message} role="alert"><%= @error_message %></p>

        <table role="grid" aria-label="Flag inventory table" class="rs-table">
          <!-- Table Pattern -->
          <tbody id="flags" phx-update="stream">
            <tr :for={{dom_id, entry} <- @streams.flags} id={dom_id} data-flag-key={entry.flag.key} tabindex="0">
               <!-- Row rendering -->
            </tr>
          </tbody>
        </table>

        <FlagComponents.pagination page={@page} base_path={@base_path} params={pagination_params(@filters)} />
      </section>
    </Shell.page>
```

**Data Loading Pattern** (lines 127-142):
```elixir
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
```

---

### `rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex` (LiveView Detail, Request-Response)

**Analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

**LiveView Layout & Detail Pattern** (lines 35-151):
```elixir
    <Shell.page
      page_title={page_title(assigns)}
      page_kicker="Flag detail"
      page_summary="Calm read surface for flag metadata, lifecycle, and environment rules status."
      current_environment={@current_environment}
      environments={@available_environments}
      env_links={@env_links}
    >
      <p :if={@error_message} role="alert"><%= @error_message %></p>

      <div :if={@detail} class="rs-detail">
        <div class="rs-detail__hero">
          <div>
            <h2><code><%= @detail.flag.key %></code></h2>
            <p><%= @detail.flag.description %></p>
            <FlagComponents.tag_list tags={@detail.flag.tags} />
          </div>
          <div class="rs-detail__stats">
             <!-- Stat Pattern -->
            <FlagComponents.stat title="Lifecycle" value={humanize(@detail.lifecycle.state)} tone="neutral" />
          </div>
        </div>
        
        <FlagComponents.section_card title="Experiment Results">
          <!-- Section Card usage -->
        </FlagComponents.section_card>
      </div>
    </Shell.page>
```

**Data Loading Pattern** (lines 173-188):
```elixir
  defp load_detail(socket, key, env) do
    case Rulestead.fetch_flag(key, env) do
      {:ok, detail} ->
        assign(socket, :detail, detail)
        |> assign(:error_message, nil)

      {:error, error} ->
        socket
        |> assign(:detail, nil)
        |> assign(:error_message, error.message)
    end
  end
```

---

## Shared Patterns

### Warnings and Guardrails UI
**Source:** `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
**Apply to:** All Experiment Reporting UI files to display guardrail metrics warnings.
**Pattern:**
```elixir
  def banner(assigns) do
    ~H"""
    <section class="rs-banner" data-tone={@tone}>
      <h2><%= @title %></h2>
      <p><%= @body %></p>
    </section>
    """
  end
```
Use `tone="warning"` or `tone="critical"` for unexpected error rates or significant degradation.

### Experiment Summary Results UI
**Source:** `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
**Apply to:** Displaying conversion lifts and statistical significance.
**Pattern:**
```elixir
  def summary_grid(assigns) do
    ~H"""
    <section class="rs-summary-grid" aria-label="Summary">
      <article :for={item <- @items} class="rs-stat" data-tone={Map.get(item, :tone, "neutral")}>
        <p class="rs-stat__title"><%= item.title %></p>
        <p class="rs-stat__value"><%= item.value %></p>
      </article>
    </section>
    """
  end
```

## Metadata

**Analog search scope:** `/Users/jon/projects/rulestead/rulestead_admin/lib/`, `/Users/jon/projects/rulestead/rulestead/lib/`
**Files scanned:** ~500
**Pattern extraction date:** 2024-05-17

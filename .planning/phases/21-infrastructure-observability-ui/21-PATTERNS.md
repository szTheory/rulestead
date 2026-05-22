# Phase 21: Infrastructure Observability UI - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 7 likely new/modified files
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex` | component (LiveView screen) | request-response | `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex` | role-match |
| `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs` | test | request-response | `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs` | role-match |
| `rulestead_admin/lib/rulestead_admin/router.ex` | route | request-response | `rulestead_admin/lib/rulestead_admin/router.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` | exact |
| `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | component | transform | `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` | exact |
| `rulestead/lib/rulestead/runtime/diagnostics.ex` | service | transform | `rulestead/lib/rulestead/runtime/diagnostics.ex` | exact |
| `rulestead/test/rulestead/runtime/diagnostics_test.exs` | test | transform | `rulestead/test/rulestead/runtime/diagnostics_test.exs` | exact |

## Pattern Assignments

### `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex` (LiveView screen, request-response)

**Primary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex`

Use the same mount/`handle_params` split: initialize assigns in `mount/3`, then build the screen state from session placeholders and env-scoped params in `handle_params/3`.

**Mount + page setup**  
Source: `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex:45-75`

```elixir
@impl true
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:page, nil)
   |> assign(:form, @empty_form)
   |> assign(:selected_archetype, nil)
   |> assign(:simulation_result, nil)
   |> assign(:redacted_context, nil)
   |> assign(:fixture_export, fixture_export(@empty_form, nil))
   |> assign(:error_message, nil)}
end

@impl true
def handle_params(%{"key" => key}, _uri, socket) do
  page =
    socket.assigns
    |> Session.placeholder_assigns(
      current_path: "/admin/flags/#{key}/simulate",
      page_title: "#{key} simulation",
      page_kicker: "Simulation",
      page_summary: "Run one actor context at a time, inspect the summary first, then open trace detail only when needed."
    )
```

For Phase 21, keep the same page contract but replace flag-specific assigns with runtime diagnostics assigns. Prefer `Session.placeholder_assigns/1` and the existing session-provided environment context over a new admin page context module.

**Summary-first render shape**  
Source: `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex:154-249`

```elixir
<Shell.page
  page_title={@page.page_title}
  page_kicker={@page.page_kicker}
  page_summary={@page.page_summary}
  current_environment={@page.current_environment}
  environments={@page.environments}
  env_links={@page.env_links}
>
  <OperatorComponents.banner ... />
  <OperatorComponents.policy_state policy_state={@page.policy_state} />

  <FlagComponents.section_card title="Simulation summary">
    <p :if={is_nil(@simulation_result)}>...</p>
    <OperatorComponents.summary_grid :if={@simulation_result} items={@summary_items} />
  </FlagComponents.section_card>
```

This is the best existing operator read surface for a diagnostics page: shell header, short banner, summary grid first, then section cards for deeper details.

**Secondary analog:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`

Use `show.ex` for a multi-card “current state” page that stays read-focused and links outward rather than becoming a workflow hub.

Source: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:42-58,71-173`

```elixir
<Shell.page ...>
  <p :if={@error_message} role="alert"><%= @error_message %></p>

  <div :if={@detail} class="rs-detail">
    <div class="rs-detail__actions">
      <a href={...}>...</a>
    </div>

    <div class="rs-detail__hero">
      ...
      <div class="rs-detail__stats">
        <FlagComponents.stat title="Lifecycle" value={...} tone="neutral" />
        ...
      </div>
    </div>

    <FlagComponents.section_card title="Environment overview">...</FlagComponents.section_card>
    <FlagComponents.section_card title="Rules status">...</FlagComponents.section_card>
    <FlagComponents.section_card title="Audit">...</FlagComponents.section_card>
```

Planner preference: model the diagnostics screen as a read-only status dashboard with links to deeper infrastructure references later, not as a control surface.

### `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs` (test, request-response)

**Analog:** `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs`

Use the same setup shape: seed runtime state, start any needed runtime worker, initialize session envs, mount the LiveView, then assert on rendered operator-facing copy.

Source: `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs:15-63`

```elixir
setup %{conn: conn} do
  Application.put_env(:rulestead, :store, Rulestead.Fake)
  now = ~U[2026-04-23 16:00:00Z]

  Control.reset!(now: now)
  Control.set_now!(now)
  ensure_environment!("prod", "Production")
  ...
  worker =
    start_supervised!(
      {Refresh,
       name: nil,
       environment_key: "prod",
       store: Rulestead.Fake,
       pubsub: nil,
       poll_interval_ms: 5_000,
       refresh_jitter_ms: 0,
       auto_tick?: false}
    )

  assert :ok = Refresh.sync(worker)
```

**LiveView assertion style**  
Source: `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs:65-113`

```elixir
{:ok, view, html} = live(conn, "/admin/flags/checkout-redesign/simulate?env=prod")

assert html =~ "Run simulation"

result_html =
  view
  |> form("form[aria-label='Simulation form']", simulation_params(...))
  |> render_submit()

assert result_html =~ "Simulation summary"
assert result_html =~ "Snapshot version"
assert result_html =~ "Cache age"
```

For Phase 21, copy this shape but assert on:
- summary-first ordering
- environment-scoped health rows
- cache age / snapshot version / refresh status / connection status text
- degraded or stale states rendered with existing tone/badge conventions

### `rulestead_admin/lib/rulestead_admin/router.ex` (route, request-response)

**Analog:** `rulestead_admin/lib/rulestead_admin/router.ex:15-41`

```elixir
scope path, as: :rulestead_admin do
  live_session live_session_name,
    session: %{
      "policy" => policy,
      "mount_path" => path
    },
    on_mount: [{RulesteadAdmin.Live.Session, :default}] do
    live "/", RulesteadAdmin.Live.FlagLive.Index, :index
    ...
    live "/audit", RulesteadAdmin.Live.AuditLive.Index, :index
    ...
  end
end
```

Planner preference: add the diagnostics route inside the existing `rulestead_admin` macro and `live_session`, preserving the mounted-admin seam and session/auth behavior. Do not create a parallel router or standalone scope.

### `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` (component, transform)

**Analog:** `rulestead_admin/lib/rulestead_admin/components/operator_components.ex:6-59`

```elixir
attr :title, :string, required: true
attr :body, :string, required: true
attr :tone, :string, default: "neutral"

def banner(assigns) do
  ~H"""
  <section class="rs-banner" data-tone={@tone}>
    <h2><%= @title %></h2>
    <p><%= @body %></p>
  </section>
  """
end

attr :items, :list, default: []

def summary_grid(assigns) do
  ~H"""
  <section class="rs-summary-grid" aria-label="Summary">
    <article :for={item <- @items} class="rs-stat" data-tone={Map.get(item, :tone, "neutral")}>
```

**Detail panel analog**  
Source: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex:43-59`

```elixir
attr :title, :string, required: true
attr :summary, :string, required: true
attr :rows, :list, default: []

def trace_panel(assigns) do
  ~H"""
  <section class="rs-trace-panel">
    <h2><%= @title %></h2>
    <p><%= @summary %></p>
    <dl>
      <div :for={row <- @rows}>
        <dt><%= row.label %></dt>
        <dd><code><%= row.value %></code></dd>
```

Planner preference: if Phase 21 needs new presentational pieces, extend `OperatorComponents` with infrastructure-oriented summary/detail panels before introducing a brand-new component namespace.

### `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` (component, transform)

**Analog:** `rulestead_admin/lib/rulestead_admin/components/flag_components.ex:98-120,143-176`

```elixir
attr :title, :string, required: true
attr :value, :any, required: true
attr :tone, :string, default: "neutral"

def stat(assigns) do
  ~H"""
  <article class="rs-stat" data-tone={@tone}>
    <p class="rs-stat__title"><%= @title %></p>
    <p class="rs-stat__value"><%= @value %></p>
  </article>
  """
end

def section_card(assigns) do
  ~H"""
  <section class="rs-card">
    <h2><%= @title %></h2>
    <div><%= render_slot(@inner_block) %></div>
  </section>
  """
end
```

```elixir
defp state_tone(:fresh), do: "positive"
defp state_tone(:potentially_stale), do: "warning"
defp state_tone(:stale), do: "critical"
defp state_tone(_state), do: "neutral"
```

Reuse these primitives for infrastructure status cards and tone mapping. Phase 21 already needs fresh/stale/warning/critical language; the planner should reuse this vocabulary rather than invent new status semantics.

### `rulestead/lib/rulestead/runtime/diagnostics.ex` (service, transform)

**Analog:** `rulestead/lib/rulestead/runtime/diagnostics.ex:4-12`

```elixir
alias Rulestead.Runtime.Cache

@spec current() :: map()
def current do
  %{
    node: node(),
    environments: Cache.diagnostics()
  }
end
```

This is the canonical aggregation seam for the UI. If Phase 21 needs more runtime observability fields, extend this bounded projection instead of teaching admin code to read ETS, PubSub, or worker state directly.

**Supporting analog:** `rulestead/lib/rulestead/runtime/cache.ex:143-174`

```elixir
@spec runtime_metadata(String.t() | atom()) :: {:ok, map()} | {:error, Rulestead.Error.t()}
def runtime_metadata(environment_key) do
  with {:ok, state} <- environment(environment_key),
       {:ok, cache_age_ms} <- cache_age_ms(environment_key) do
    {:ok,
     %{
       environment_key: state.environment_key,
       snapshot_version: state.version,
       applied_at: state.applied_at,
       published_at: state.published_at,
       cache_age_ms: cache_age_ms,
       source: state.source,
       refresh_status: state.refresh_status,
       stale_used?: false,
       disk_backup_status: Map.get(state, :disk_backup_status, :disabled),
       last_refresh_error: state.last_refresh_error
     }}
  end
end
```

This is the existing bounded metadata contract. Prefer enriching this projection and having `Diagnostics.current/0` compose it, rather than duplicating cache-age/status derivation in the UI.

**Supporting analog:** `rulestead/lib/rulestead/runtime/refresh.ex:117-129`

```elixir
def handle_call(:status, _from, state) do
  refresh_status =
    case Cache.runtime_metadata(state.environment_key) do
      {:ok, metadata} -> metadata.refresh_status
      {:error, _error} -> :degraded
    end

  {:reply,
   %{
     attempt: state.attempt,
     next_backoff_ms: state.next_backoff_ms,
     refresh_status: refresh_status
   }, state}
end
```

If Phase 21 truly needs live worker/backoff state, this is the seam to expose through diagnostics, not a direct GenServer state reach-in from admin.

### `rulestead/test/rulestead/runtime/diagnostics_test.exs` (test, transform)

**Analog:** `rulestead/test/rulestead/runtime/diagnostics_test.exs:33-47`

```elixir
assert %{node: _, environments: environments} = Rulestead.diagnostics()
assert %{node: _, environments: runtime_environments} = Runtime.diagnostics()

assert environments == runtime_environments

assert environment =
         Enum.find(runtime_environments, &(&1.environment_key == environment_key))

assert environment.snapshot_version == 9
assert environment.source == :ets
assert environment.refresh_status == :ready
assert environment.disk_backup_status == :disabled
assert is_integer(environment.cache_age_ms)
```

This is the exact test shape to extend for Phase 21 runtime diagnostics fields. Keep the contract bounded and assert façade parity (`Rulestead.diagnostics/0` and `Runtime.diagnostics/0`) if new metadata is added.

## Shared Patterns

### Admin shell and env routing
**Sources:** `rulestead_admin/lib/rulestead_admin/components/shell.ex:16-63`, `rulestead_admin/lib/rulestead_admin/router.ex:15-41`

```elixir
<Shell.page
  page_title={...}
  page_kicker={...}
  page_summary={...}
  current_environment={@current_environment}
  environments={@available_environments}
  env_links={@env_links}
>
```

Apply to all Phase 21 admin UI work. The diagnostics page should look like an existing mounted admin screen, with the standard environment picker and session-backed path handling.

### Summary-first operator IA
**Sources:** `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex:167-248`, `rulestead_admin/lib/rulestead_admin/components/operator_components.ex:10-59`

```elixir
<OperatorComponents.banner ... />
<OperatorComponents.policy_state ... />
<FlagComponents.section_card title="...">
  <OperatorComponents.summary_grid items={...} />
</FlagComponents.section_card>
```

Phase 21 should open with a compact health summary, then progressively disclose raw details. This matches both the prompt IA and current admin code.

### Bounded runtime metadata only
**Sources:** `rulestead/lib/rulestead/runtime/cache.ex:143-159`, `rulestead/test/rulestead/runtime/diagnostics_test.exs:49-67`

```elixir
%{
  environment_key: state.environment_key,
  snapshot_version: state.version,
  applied_at: state.applied_at,
  published_at: state.published_at,
  cache_age_ms: cache_age_ms,
  source: state.source,
  refresh_status: state.refresh_status,
  stale_used?: false,
  disk_backup_status: ...,
  last_refresh_error: ...
}
```

Diagnostics and explain surfaces are intentionally bounded and redactable. Do not leak raw context, internal payloads, or unbounded worker state into the UI.

### Invalidation telemetry contract
**Sources:** `rulestead/lib/rulestead/runtime/refresh.ex:276-313,394-406`, `rulestead/lib/rulestead/telemetry.ex:67-75,115-125`, `rulestead/test/rulestead/telemetry_test.exs:513-645`

```elixir
emit_invalidation(:received, ...)
emit_invalidation(:ignored, ...)
emit_invalidation(:refresh_triggered, ...)
emit_invalidation(:refresh_failed, ...)
```

```elixir
assert_receive_event([:rulestead, :runtime, :invalidation, :received])
assert_receive_event([:rulestead, :runtime, :invalidation, :ignored])
assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_triggered])
assert_receive_event([:rulestead, :runtime, :invalidation, :refresh_failed])
```

Planner preference: Phase 21 should consume and present this existing event/status vocabulary. Do not invent a second observability taxonomy for sync health.

### Cluster convergence integration shape
**Source:** `rulestead/test/rulestead/runtime/cluster_refresh_test.exs:8-93`

```elixir
cluster = ClusterCase.setup_cluster!(environment_key)
...
Control.publish!(cluster.pubsub_name, environment_key, version_two.version,
  notifier: cluster.notifier
)
...
assert %{environments: remote_environments} =
         ClusterCase.remote_diagnostics(cluster.peer_node)
```

If Phase 21 extends diagnostics for cluster-visible health, prefer covering it in the existing `ClusterCase` integration style rather than trying to unit-test node topology logic in isolation.

### LiveView test posture
**Sources:** `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs:32-167`, `rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs:65-150`

Use seeded fake runtime state, mounted endpoint, and rendered copy assertions. The existing admin tests validate operator-visible outcomes, link wiring, and progressive disclosure rather than internal assigns.

## Candidate Seams To Prefer

- `Rulestead.diagnostics/0` / `Rulestead.Runtime.diagnostics/0` should remain the admin UI entrypoint for runtime health data.
- `Rulestead.Runtime.Diagnostics.current/0` is the right expansion seam for node/environment projections.
- `Rulestead.Runtime.Cache.runtime_metadata/1` is the right place for per-environment bounded status fields such as cache age, backup status, and refresh status.
- `Rulestead.Runtime.Refresh.status/1` is the existing worker-status seam if Phase 21 needs attempt/backoff data surfaced through diagnostics.
- `RulesteadAdmin.Router.rulestead_admin/2` is the only route seam the planner should use for a new diagnostics screen.
- `RulesteadAdmin.Components.OperatorComponents` and `RulesteadAdmin.Components.FlagComponents` should absorb any new health cards/panels before a new component namespace is introduced.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead_admin/lib/rulestead_admin/live/diagnostics_live/index.ex` | component (LiveView screen) | request-response | No existing infrastructure/diagnostics LiveView yet; nearest matches are `FlagLive.Simulate` for summary-first operator IA and `FlagLive.Show` for multi-card current-state rendering. |

## Metadata

**Analog search scope:** `rulestead/lib/rulestead/runtime`, `rulestead/lib/rulestead`, `rulestead_admin/lib/rulestead_admin/components`, `rulestead_admin/lib/rulestead_admin/live`, `rulestead_admin/test/rulestead_admin/live`, `rulestead/test/rulestead/runtime`, `rulestead/test/rulestead`

**Files scanned:** 16 primary files plus targeted codebase search
**Pattern extraction date:** 2026-05-17

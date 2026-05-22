# Phase 21: Infrastructure Observability UI - Research

**Researched:** 2026-05-17
**Domain:** Runtime diagnostics projection, invalidation telemetry projection, and operator-facing LiveView health UI for the linked `rulestead` + `rulestead_admin` monorepo. [VERIFIED: codebase grep]
**Confidence:** MEDIUM

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INF-01 | Expose cache age, sync latency, and adapter connection health in the Admin UI so operators have explicit visibility into distributed state drift. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | Use a core health projection built from existing runtime cache metadata (`snapshot_version`, `published_at`, `applied_at`, `cache_age_ms`, `refresh_status`, `last_refresh_error`) plus bounded adapter probes for Repo/Redis/PubSub configuration, then render it in a dedicated admin diagnostics screen. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/config.ex`] |
| INF-02 | Emit new Telemetry events (`[:rulestead, :sync, :delta_received]`, `[:rulestead, :cache, :invalidation]`) to hook into existing host app metrics. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | Phase 20 already shipped bounded invalidation telemetry under `[:rulestead, :runtime, :invalidation, :received | :ignored | :refresh_triggered | :refresh_failed]`; Phase 21 should consume that contract and only add compatibility aliases if the milestone requires new names, not replace the existing family. [VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] |
</phase_requirements>

## Summary

Phase 21 does not need new infrastructure services to produce a useful operator surface. The core package already exposes bounded runtime diagnostics for each loaded environment, stores publish/apply timestamps in ETS metadata, emits invalidation telemetry with explicit outcome reasons, and has a two-node convergence test harness proving the Phase 20 transport semantics. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`][VERIFIED: `rulestead/test/rulestead/runtime/cluster_refresh_test.exs`]

The main gap is not transport correctness; it is projection. Today the codebase can answer “what is this node serving right now?” but it cannot truthfully auto-discover “what are all peers in the cluster doing right now?” because no production peer-enumeration or cluster-membership seam exists outside the test-only `ClusterCase`. [VERIFIED: codebase grep][VERIFIED: `rulestead/lib/rulestead/runtime/cluster_case.ex`] Phase 21 should therefore plan for a bounded health snapshot API in `rulestead` and a dedicated diagnostics LiveView in `rulestead_admin`, with explicit single-node labeling by default and optional host-provided topology input if a host app wants a wider cluster view. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`][VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`]

The highest-risk planning issue is telemetry drift. The requirement text names `[:rulestead, :sync, :delta_received]` and `[:rulestead, :cache, :invalidation]`, but the implemented and tested Phase 20 contract is `[:rulestead, :runtime, :invalidation, ...]`. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`][VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] Phase 21 should not silently rename or remove the shipped event family; if the planner wants the requirement names, add alias emission or a stable projection layer and preserve the existing telemetry API. [CITED: https://hexdocs.pm/telemetry/telemetry.html]

**Primary recommendation:** Build Phase 21 around one new bounded core “infrastructure health snapshot” projection in `rulestead`, one mounted diagnostics LiveView in `rulestead_admin`, and targeted tests that prove freshness/latency math, invalidation event projection, and UI rendering without introducing cluster discovery, background collectors, or standalone admin infrastructure. [VERIFIED: codebase grep][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cache freshness and sync-latency calculation | API / Backend | Database / Storage | `published_at`, `applied_at`, `cache_age_ms`, and `refresh_status` originate in runtime ETS metadata and snapshot records, so the backend must compute them once and the UI should only render them. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`] |
| Adapter connection health (Repo / Redis / PubSub wiring) | API / Backend | Frontend Server (SSR) | The UI cannot safely infer process reachability or configuration ownership; bounded probes belong in `rulestead`, while LiveView presents the result. [VERIFIED: `rulestead/lib/rulestead/application.ex`][VERIFIED: `rulestead/lib/rulestead/redis.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/config.ex`] |
| Distributed topology summary | API / Backend | Frontend Server (SSR) | Current production code has local diagnostics only; any peer view must be surfaced through a backend seam or explicitly marked unavailable. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: codebase grep] |
| Diagnostics page layout, refresh affordances, and operator wording | Frontend Server (SSR) | Browser / Client | The admin package already owns mounted LiveViews, status cards, and operator-oriented summaries. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`] |
| Invalidation and refresh history signals | API / Backend | Frontend Server (SSR) | Phase 20 telemetry already distinguishes received, ignored, refresh-triggered, and refresh-failed paths; Phase 21 should project that telemetry into a small UI model instead of recreating transport logic in LiveView. [VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: `CLAUDE.md`]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: `CLAUDE.md`]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: `CLAUDE.md`]
- Do not create Phase 8-only docs early. [VERIFIED: `CLAUDE.md`]
- `rulestead_admin` remains a guarded sibling package; do not add early publish flows that bypass the linked release design. [VERIFIED: `CLAUDE.md`]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: `CLAUDE.md`]
- Use scripts-first CI surfaces where workflow logic becomes non-trivial. [VERIFIED: `CLAUDE.md`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `rulestead` runtime diagnostics surface | local code [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`] | Current node health projection entrypoint | It already returns bounded environment diagnostics and is exposed through `Rulestead.diagnostics/0`; extending this seam is lower-risk than inventing a second health service. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: `rulestead/lib/rulestead.ex`] |
| `Phoenix.LiveView` | `1.1.28` [VERIFIED: `rulestead_admin/mix.lock`] | Mounted diagnostics screen in `rulestead_admin` | The admin package already uses mounted LiveViews, and LiveView supports connected-only async loading via `assign_async/4`, which fits a health panel that should not block the first static render. [VERIFIED: `rulestead_admin/mix.lock`][CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| `Phoenix.PubSub` | `2.2.0` [VERIFIED: `rulestead/mix.lock`] | Existing invalidation transport and host-owned PubSub seam | Phase 20 already standardized on `Phoenix.PubSub` for invalidation, and official docs confirm it is started in the supervision tree and used for `subscribe/3` + `broadcast/4`. [VERIFIED: `rulestead/mix.lock`][CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| `:telemetry` | `1.4.1` [VERIFIED: `rulestead/mix.lock`] | Invalidation/refresh event projection and contract tests | Official telemetry docs treat event names and `execute`/`span` usage as the stable instrumentation contract; Phase 21 should extend that contract carefully. [VERIFIED: `rulestead/mix.lock`][CITED: https://hexdocs.pm/telemetry/telemetry.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Redix` | `1.5.3` [VERIFIED: `rulestead/mix.lock`] | Redis connection health when Redis-backed caching is enabled | Use only for bounded connection-state projection; official docs show reconnection behavior and telemetry for connection/disconnection, which is enough for a health badge without building a Redis observer subsystem. [VERIFIED: `rulestead/mix.lock`][CITED: https://hexdocs.pm/redix/reconnections.html][CITED: https://hexdocs.pm/redix/Redix.Telemetry.html] |
| `Ecto` / `Ecto.SQL` | `3.13.5` [VERIFIED: `rulestead/mix.lock`] | Repo reachability checks and query telemetry context | Use a short, bounded probe or existing repo telemetry only in the health path; Ecto already emits query telemetry and should remain the authoritative store seam. [VERIFIED: `rulestead/mix.lock`][CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| `RulesteadAdmin.Components.OperatorComponents` | local code [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`] | Summary cards, banners, and trace panels | Reuse these components so Phase 21 matches existing admin IA instead of inventing a parallel visual language. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend current diagnostics + telemetry projection | Add `Phoenix.Tracker` or a library-owned cluster membership service | `Phoenix.Tracker` is real cluster infrastructure, not a presentation seam. It would widen Phase 21 into topology discovery rather than operator visibility over existing runtime state. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.Tracker.html][VERIFIED: codebase grep] |
| LiveView diagnostics route in `rulestead_admin` | Standalone dashboard or independently shipped admin app | This contradicts the linked sibling-package design and the current admin mount pattern. [VERIFIED: `CLAUDE.md`][VERIFIED: `AGENTS.md`] |
| Reuse existing invalidation telemetry | Rename Phase 20 events to match requirement text | Renaming would break the tested event family and create avoidable telemetry drift; add aliases if needed. [VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`][CITED: https://hexdocs.pm/telemetry/telemetry.html] |

**Installation:** No new dependency is warranted for Phase 21. Keep the existing monorepo stack. [VERIFIED: `rulestead/mix.exs`][VERIFIED: `rulestead_admin/mix.exs`]

**Version verification:** Locked project versions are `phoenix_live_view 1.1.28`, `phoenix 1.8.5`, `phoenix_pubsub 2.2.0`, `redix 1.5.3`, `ecto_sql 3.13.5`, and `telemetry 1.4.1`. [VERIFIED: `rulestead_admin/mix.lock`][VERIFIED: `rulestead/mix.lock`]

## Architecture Patterns

### System Architecture Diagram

```text
Host operator request
  -> mounted admin route in rulestead_admin
  -> Diagnostics LiveView mount
  -> connected? yes
     -> bounded async health load
     -> rulestead health projection
        -> Runtime diagnostics (ETS metadata per environment)
        -> Runtime config (pubsub/notifier/store wiring)
        -> optional bounded adapter probes (Repo / Redis)
        -> optional recent invalidation outcomes from telemetry projection
     -> normalized health snapshot
  -> OperatorComponents summary cards + trace panels
  -> manual refresh / periodic soft refresh

Mutation on any node
  -> snapshot publish succeeds
  -> Phase 20 invalidation telemetry emits
  -> runtime refresh applies or fails
  -> Phase 21 health projection surfaces latest freshness / status on next refresh
```

### Recommended Project Structure

```text
rulestead/
├── lib/rulestead/runtime/diagnostics.ex        # extend or wrap current local diagnostics
├── lib/rulestead/runtime/health.ex             # bounded projection for UI/API consumption
└── test/rulestead/runtime/                     # health projection + telemetry projection tests

rulestead_admin/
├── lib/rulestead_admin/live/diagnostics_live/  # new mounted diagnostics surface
├── lib/rulestead_admin/components/             # reuse OperatorComponents + Shell
└── test/rulestead_admin/live/diagnostics_live/ # rendering, refresh, and accessibility tests
```

### Pattern 1: Bounded Health Snapshot Projection

**What:** Build one core function that turns current runtime metadata plus bounded adapter checks into a UI-safe snapshot. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`]

**When to use:** Every admin diagnostics render and any future host-facing `/health`-style endpoint. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: `prompts/rulestead-telemetry-observability-and-audit.md`]

**Example:**

```elixir
# Source: project pattern from rulestead/lib/rulestead/runtime/cache.ex
def health_snapshot do
  %{
    node: node(),
    captured_at: DateTime.utc_now(),
    environments:
      Rulestead.Runtime.Diagnostics.current().environments
      |> Enum.map(fn env ->
        Map.merge(env, %{
          sync_latency_ms: sync_latency_ms(env),
          connection_health: %{
            repo: repo_health(),
            redis: redis_health(),
            pubsub: pubsub_health()
          }
        })
      end)
  }
end
```

### Pattern 2: Connected-Only LiveView Loading

**What:** Load diagnostics asynchronously after the socket connects so the initial static render remains cheap and the page can show explicit loading/error states. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**When to use:** Diagnostics pages or panels that may call bounded probes or aggregate multiple environments. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**Example:**

```elixir
# Source: Phoenix LiveView docs
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:health, nil)
   |> assign_async(:health, fn -> {:ok, %{health: Rulestead.health_snapshot()}} end)}
end
```

### Anti-Patterns to Avoid

- **Direct adapter calls from templates or event handlers:** Do not have LiveViews call `Repo`, `Redix`, or `Phoenix.PubSub` directly for status; keep adapter ownership in `rulestead` and render a normalized snapshot. [VERIFIED: `rulestead/lib/rulestead/application.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`]
- **Treating local diagnostics as cluster truth:** `Rulestead.Runtime.Diagnostics.current/0` is node-local; presenting it as whole-cluster state would be misleading. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`]
- **Telemetry renames in place:** Existing invalidation events are already tested; phase work should project or alias them, not swap namespaces mid-milestone. [VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] 
- **Unbounded “health probes” in hot paths:** A diagnostics panel can tolerate a small bounded check; request-path evaluation cannot. The engineering DNA explicitly keeps runtime evaluation on ETS, not database reads. [VERIFIED: `prompts/rulestead-engineering-dna-from-prior-libs.md`] 

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cluster transport | Custom socket fan-out or ad hoc cross-node RPC for UI refresh | Existing `Phoenix.PubSub` invalidation seam and current runtime notifier contract | Phase 20 already standardized this path and tests it. [VERIFIED: `rulestead/lib/rulestead/runtime/notifier.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex`][CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| Admin rendering primitives | New card/banner system | `Shell.page`, `OperatorComponents.banner`, `OperatorComponents.summary_grid`, `trace_panel` | Existing admin screens already use these components. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex`] |
| Telemetry sink semantics | New observability event tree | Existing `Rulestead.Telemetry` helper plus current invalidation event family | The helper already normalizes bounded metadata and handlers are designed to tolerate failures. [VERIFIED: `rulestead/lib/rulestead/telemetry.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`] |
| Cluster membership discovery | Library-owned peer tracker in Phase 21 | Explicit host-provided peer snapshot seam, or honest single-node UI | No production discovery surface exists today; inventing one widens scope beyond the milestone goal. [VERIFIED: codebase grep] |

**Key insight:** Phase 21 should project and summarize existing state, not mint a new control plane. The repo already has the transport, cache, and UI foundations; what it lacks is a stable, bounded “operator health snapshot” contract. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Local-Only Data Presented as Cluster-Wide Health

**What goes wrong:** The UI implies all nodes are healthy when it only knows the current node’s ETS state. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`]

**Why it happens:** The only production diagnostics entrypoint returns `node()` and local `Cache.diagnostics()`, while cross-node introspection exists only in the test helper. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/cluster_case.ex`]

**How to avoid:** Label the default panel as current-node health unless a host explicitly supplies peer reports. [VERIFIED: codebase grep]

**Warning signs:** The planner is about to add peer lists, node counts, or quorum language without adding a backend seam that can actually supply peer data. [VERIFIED: codebase grep]

### Pitfall 2: Telemetry Contract Drift

**What goes wrong:** Phase 21 renames invalidation events or changes metadata keys, breaking host metrics and existing tests. [VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`]

**Why it happens:** The milestone requirements mention one namespace, while the shipped Phase 20 code uses another. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`][VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`]

**How to avoid:** Preserve `[:rulestead, :runtime, :invalidation, ...]` as the source contract and add aliases only if Phase 21 needs requirement-name compatibility. [CITED: https://hexdocs.pm/telemetry/telemetry.html]

**Warning signs:** A plan task says “rename telemetry events” instead of “emit compatibility aliases” or “project existing telemetry into UI status.” [VERIFIED: codebase grep]

### Pitfall 3: Blocking Probes in LiveView Mount

**What goes wrong:** The diagnostics screen feels slow or flakes in tests because it waits on Repo/Redis checks during disconnected mount. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**Why it happens:** Connection checks are I/O, while disconnected mount should render a cheap static shell first. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**How to avoid:** Use `assign_async/4` or an explicit refresh event only after the socket is connected. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**Warning signs:** The new LiveView loads health data directly in `mount/3` without connected-state gating. [VERIFIED: codebase grep]

### Pitfall 4: Overexposing Host Infrastructure Details

**What goes wrong:** Diagnostics leak node names, connection strings, or raw error payloads that the prompts explicitly say to avoid. [VERIFIED: `prompts/rulestead-telemetry-observability-and-audit.md`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`]

**Why it happens:** Health UIs tempt developers to dump adapter structs or exception payloads directly. [VERIFIED: `prompts/rulestead-telemetry-observability-and-audit.md`]

**How to avoid:** Keep UI and telemetry metadata bounded to status atoms, timestamps, counts, and sanitized reason codes, matching current diagnostics and telemetry patterns. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`][VERIFIED: `rulestead/lib/rulestead/telemetry.ex`]

**Warning signs:** The proposed payload includes raw `%Redix.ConnectionError{}` structs, Repo config, or full node lists from host infra. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources and current project code:

### Existing Runtime Diagnostics Shape

```elixir
# Source: rulestead/lib/rulestead/runtime/diagnostics.ex
%{
  node: node(),
  environments: Rulestead.Runtime.Cache.diagnostics()
}
```

### Existing Invalidation Event Projection

```elixir
# Source: rulestead/lib/rulestead/runtime/refresh.ex
Telemetry.execute(
  [:rulestead, :runtime, :invalidation, :refresh_triggered],
  %{count: 1},
  %{environment: environment_key, snapshot_version: version, reason: :refresh_triggered_from_invalidation}
)
```

### Official PubSub Supervision Pattern

```elixir
# Source: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
children = [
  {Phoenix.PubSub, name: :my_pubsub}
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Polling-only refresh visibility | Push invalidation plus bounded invalidation telemetry | Phase 20 on 2026-05-17. [VERIFIED: `.planning/STATE.md`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] | Phase 21 can show whether staleness came from age, duplicate notices, or failed invalidation-driven refreshes instead of a generic “cache old” message. [VERIFIED: `rulestead/lib/rulestead/runtime/refresh.ex`] |
| Direct PubSub details hidden in tests/helpers | Explicit notifier seam with host-owned PubSub config | Phase 20 on 2026-05-17. [VERIFIED: `.planning/STATE.md`][VERIFIED: `rulestead/lib/rulestead/runtime/notifier.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/config.ex`] | Diagnostics must respect that PubSub ownership is external to `rulestead_admin`; the UI should report status, not own the transport. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`] |
| Flag/admin detail pages as current operator surfaces | Summary cards, banners, and policy-state panels in mounted LiveViews | Existing Phase 7/18 admin surfaces. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex`][VERIFIED: `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`] | Phase 21 should look like another mounted operator page, not a separate dashboard product. [VERIFIED: `AGENTS.md`] |

**Deprecated/outdated:**

- Treating the test-only cluster helper as a production observability mechanism is outdated for this phase; it proves convergence semantics but is not a deployable topology service. [VERIFIED: `rulestead/lib/rulestead/runtime/cluster_case.ex`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A host-provided peer snapshot seam is the smallest honest way to show multi-node topology beyond the current node. [ASSUMED] | Summary / Architecture Patterns | The planner may over-scope Phase 21 if the host already has a reusable peer-discovery seam elsewhere that was not visible in this repo. |

## Open Questions (RESOLVED)

1. **Should Phase 21 preserve the existing invalidation telemetry names only, or emit the requirement-name aliases too?**
   - Resolution: Preserve the shipped `[:rulestead, :runtime, :invalidation, ...]` family as the source contract and emit requirement-name compatibility aliases additively where Phase 21 needs INF-02 coverage. Do not rename or replace the existing family. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`][CITED: https://hexdocs.pm/telemetry/telemetry.html]

2. **How much distributed topology should the v0.5.0 UI claim when the repo has no production peer-discovery seam?**
   - Resolution: Phase 21 should ship truthful current-node diagnostics by default and only render broader peer topology when the host app explicitly provides peer snapshots through a host-owned seam. No library-owned peer discovery or implicit whole-cluster claims belong in this phase. [VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/cluster_case.ex`][VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | core + admin implementation and tests | ✓ [VERIFIED: local command] | Elixir 1.19.5 / Mix 1.19.5 [VERIFIED: local command] | — |
| PostgreSQL CLI | repo-backed verification and some integration tests | ✓ [VERIFIED: local command] | `psql 14.17` [VERIFIED: local command] | Fake-backed tests for most phase work. [VERIFIED: `prompts/rulestead-testing-and-e2e-strategy.md`] |
| Redis server | Redis health-path verification | ✓ [VERIFIED: local command] | `7.2.4` [VERIFIED: local command] | Fake-backed tests plus bounded “not configured” status when Redis is disabled. [VERIFIED: `rulestead/lib/rulestead/redis.ex`] |
| Node / npm | existing admin test/tooling environment | ✓ [VERIFIED: local command] | Node `22.14.0`, npm `11.1.0` [VERIFIED: local command] | Not needed for the core ExUnit path. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:**

- None found during the local audit. [VERIFIED: local command]

**Missing dependencies with fallback:**

- None found during the local audit. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveView test helpers and existing accessibility support. [VERIFIED: `rulestead/test/test_helper.exs`][VERIFIED: `rulestead_admin/test/test_helper.exs`][VERIFIED: `rulestead_admin/test/support/conn_case.ex`] |
| Config file | `rulestead/test/test_helper.exs` and `rulestead_admin/test/test_helper.exs`. [VERIFIED: `rulestead/test/test_helper.exs`][VERIFIED: `rulestead_admin/test/test_helper.exs`] |
| Quick run command | `cd rulestead && mix test test/rulestead/runtime/diagnostics_test.exs test/rulestead/runtime/cluster_refresh_test.exs test/rulestead/telemetry_test.exs -x` [VERIFIED: file existence] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: repo structure] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INF-01 | Core health snapshot reports cache age, sync latency, and adapter health without leaking raw internals. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | unit | `cd rulestead && mix test test/rulestead/runtime/health_test.exs -x` | ❌ Wave 0 |
| INF-01 | Diagnostics LiveView renders current-node health, empty/error states, and environment summaries. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/diagnostics_live/index_test.exs -x` | ❌ Wave 0 |
| INF-02 | Existing invalidation telemetry is projected correctly and any alias events remain backward compatible. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | unit | `cd rulestead && mix test test/rulestead/telemetry_test.exs test/rulestead/runtime/health_telemetry_test.exs -x` | `telemetry_test.exs` ✅ / new file ❌ Wave 0 |
| INF-01 / INF-02 | Cluster convergence status remains explainable after one invalidation round-trip. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`] | integration | `cd rulestead && mix test test/rulestead/runtime/cluster_refresh_test.exs -x` | ✅ |

### Sampling Rate

- **Per task commit:** `cd rulestead && mix test test/rulestead/runtime/diagnostics_test.exs test/rulestead/telemetry_test.exs -x` and `cd rulestead_admin && mix test test/rulestead_admin/live/diagnostics_live/index_test.exs -x` once the new file exists. [VERIFIED: file existence]
- **Per wave merge:** `cd rulestead && mix test test/rulestead/runtime/diagnostics_test.exs test/rulestead/runtime/cluster_refresh_test.exs test/rulestead/telemetry_test.exs && cd ../rulestead_admin && mix test` [VERIFIED: repo structure]
- **Phase gate:** Full targeted core + admin suite green before `/gsd-verify-work`. [VERIFIED: workflow.nyquist_validation=true in `.planning/config.json`]

### Wave 0 Gaps

- [ ] `rulestead/test/rulestead/runtime/health_test.exs` — covers INF-01 projection math and bounded probe results. [VERIFIED: file absence]
- [ ] `rulestead/test/rulestead/runtime/health_telemetry_test.exs` — covers alias/projection semantics if INF-02 adds event compatibility. [VERIFIED: file absence]
- [ ] `rulestead_admin/test/rulestead_admin/live/diagnostics_live/index_test.exs` — covers rendering, refresh action, and single-node labeling. [VERIFIED: file absence]
- [ ] `rulestead_admin/test/rulestead_admin/live/diagnostics_live/accessibility_test.exs` — mirrors the existing admin accessibility pattern. [VERIFIED: file absence][VERIFIED: `rulestead_admin/test/rulestead_admin/live/flag_live/accessibility_test.exs`] 

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app authentication remains outside this phase; the mounted admin package consumes host auth context rather than redefining it. [VERIFIED: `AGENTS.md`][VERIFIED: `CLAUDE.md`] |
| V3 Session Management | no | No new session mechanism is implied; mounted LiveViews continue to rely on the host endpoint/session. [VERIFIED: `rulestead_admin/test/support/conn_case.ex`] |
| V4 Access Control | yes | Keep diagnostics under the existing mounted admin policy envelope and avoid cross-tenant/global defaults. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`] |
| V5 Input Validation | yes | Health and telemetry payloads should stay bounded to atoms, timestamps, counts, and known keys, following `Rulestead.Telemetry.metadata/1`. [VERIFIED: `rulestead/lib/rulestead/telemetry.ex`] |
| V6 Cryptography | no | Phase 21 does not introduce new crypto flows; it only renders status over existing transport/store seams. [VERIFIED: codebase grep] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Diagnostics leak internal topology or connection details | Information Disclosure | Expose status atoms and timestamps only; never dump raw config, URLs, or unredacted errors. [VERIFIED: `prompts/rulestead-telemetry-observability-and-audit.md`] |
| Cross-tenant diagnostics view defaults too wide | Elevation of Privilege | Keep environment/tenant scoping explicit in admin routes and queries; no implicit global view. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`] |
| Telemetry metadata includes raw trait or payload data | Information Disclosure | Reuse bounded metadata projection through `Rulestead.Telemetry.metadata/1`; do not attach raw snapshot payloads or actor traits. [VERIFIED: `rulestead/lib/rulestead/telemetry.ex`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`] |

## Recommended Plan Slices

### Slice A: Core runtime/API projection

- Add one bounded health projection module in `rulestead` that wraps the current diagnostics seam and computes `sync_latency_ms` from `published_at` and `applied_at`. [VERIFIED: `rulestead/lib/rulestead/runtime/cache.ex`]
- Add bounded connection-status projection for Repo, Redis, and PubSub configuration ownership, keeping PubSub host-owned and Redis optional. [VERIFIED: `rulestead/lib/rulestead/application.ex`][VERIFIED: `rulestead/lib/rulestead/redis.ex`][VERIFIED: `rulestead/lib/rulestead/runtime/config.ex`]
- Decide whether INF-02 needs additive alias telemetry events; if yes, emit them alongside the existing Phase 20 family. [VERIFIED: `.planning/milestones/v0.5.0-REQUIREMENTS.md`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`]

### Slice B: Admin UI

- Add a mounted diagnostics LiveView in `rulestead_admin` under the existing admin IA, using `Shell.page`, `OperatorComponents.banner`, `summary_grid`, and trace-style rows. [VERIFIED: `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`]
- Render explicit panels for topology scope, cache freshness, sync latency, and connection health. Default copy should say “current node” unless peer data is explicitly supplied. [VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`][VERIFIED: `rulestead/lib/rulestead/runtime/diagnostics.ex`]
- Use connected-only async loading or explicit refresh actions so the page remains calm and fast on first render. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Slice C: Tests and docs

- Add core tests for projection math, bounded metadata, and telemetry compatibility. [VERIFIED: `rulestead/test/rulestead/runtime/diagnostics_test.exs`][VERIFIED: `rulestead/test/rulestead/telemetry_test.exs`]
- Add LiveView rendering and accessibility tests mirroring existing admin coverage patterns. [VERIFIED: `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`][VERIFIED: `rulestead_admin/test/rulestead_admin/live/flag_live/accessibility_test.exs`]
- Keep docs limited to the Phase 21 artifact and any inline module docs needed for the new seam; do not create Phase 8-style guide surfaces early. [VERIFIED: `CLAUDE.md`]

## Sources

### Primary (HIGH confidence)

- Local codebase files listed in this document, especially:
  - `rulestead/lib/rulestead/runtime/cache.ex`
  - `rulestead/lib/rulestead/runtime/diagnostics.ex`
  - `rulestead/lib/rulestead/runtime/refresh.ex`
  - `rulestead/lib/rulestead/runtime/notifier.ex`
  - `rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex`
  - `rulestead/lib/rulestead/application.ex`
  - `rulestead/lib/rulestead/telemetry.ex`
  - `rulestead_admin/lib/rulestead_admin/components/operator_components.ex`
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex`
- Official docs:
  - https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
  - https://hexdocs.pm/telemetry/telemetry.html
  - https://hexdocs.pm/redix/reconnections.html
  - https://hexdocs.pm/redix/Redix.Telemetry.html
  - https://hexdocs.pm/ecto/Ecto.Repo.html

### Secondary (MEDIUM confidence)

- Prompt contracts and planning artifacts:
  - `prompts/rulestead-admin-ux-and-operator-ia.md`
  - `prompts/rulestead-telemetry-observability-and-audit.md`
  - `prompts/rulestead-testing-and-e2e-strategy.md`
  - `.planning/phases/20-pubsub-distributed-invalidation/20-CONTEXT.md`
  - `.planning/phases/20-pubsub-distributed-invalidation/20-01-PLAN.md`
  - `.planning/phases/20-pubsub-distributed-invalidation/20-03-SUMMARY.md`

### Tertiary (LOW confidence)

- None. All material claims above were tied to local code, local config, local commands, or official docs. [VERIFIED: this document]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 21 can stay on the repo’s existing LiveView/PubSub/Telemetry/Redix/Ecto stack with no new dependency. [VERIFIED: `rulestead/mix.lock`][VERIFIED: `rulestead_admin/mix.lock`]
- Architecture: MEDIUM - The local-node health path is clear, but whole-cluster topology beyond test helpers depends on a host seam not present in the repo. [VERIFIED: codebase grep][VERIFIED: `rulestead/lib/rulestead/runtime/cluster_case.ex`]
- Pitfalls: HIGH - The main regressions are already visible from current code and prompt constraints: telemetry drift, local-vs-cluster confusion, blocking probes, and overexposed diagnostics. [VERIFIED: codebase grep][VERIFIED: `prompts/rulestead-admin-ux-and-operator-ia.md`][VERIFIED: `prompts/rulestead-telemetry-observability-and-audit.md`]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16

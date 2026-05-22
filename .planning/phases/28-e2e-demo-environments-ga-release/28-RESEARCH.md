# Phase 28: E2E Demo Environments & GA Release - Research

**Researched:** 2026-05-20
**Domain:** Phoenix-hosted embedded demo stack with Next.js OpenFeature client
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Demo Architecture
- **D-01: Structure:** The demo code will live in `examples/demo/backend` (Phoenix) and `examples/demo/frontend` (Next.js).
- **D-02: Orchestration:** A `docker-compose.yml` file will be placed in the project root to satisfy the "under 5 minutes" and `docker-compose up` frictionlessness requirement. It will run Postgres, Redis, the Phoenix backend, and the Next.js frontend.
- **D-03: Bridging API:** The Phoenix demo backend will embed Rulestead and expose a custom `/api/flags` endpoint. The Next.js frontend will communicate with this endpoint via a standard HTTP client or an OpenFeature Web Provider, proving that Rulestead easily backs external frontends through a host's own API.
- **D-04: Auto-Seeding:** The Phoenix container's entrypoint will automatically run `ecto.setup` (migrations + seeds). The seeds will use `Rulestead.Admin` to create a Demo Project, Staging/Production environments, and a few initial feature flags so the Admin UI is populated immediately upon boot.

### Claude's Discretion
None. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
None explicitly listed under a deferred section. Treat the `## Out of Scope` block below as locked exclusions. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

### Out of Scope
- Implementing an official OpenFeature Remote Evaluation Protocol (OFREP) server in the Rulestead core. The HTTP bridge remains the responsibility of the host app (the Demo Phoenix App, in this case).
- Adding new features to the core library or UI.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GA-01 | A frictionless E2E demo environment is provided via Docker Compose, including Redis, DB, UI, and a sample client. [VERIFIED: .planning/REQUIREMENTS.md] | Compose healthchecks, seeded Phoenix host boot flow, root-level orchestration, and backend-first slice guidance in this document. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] [VERIFIED: docker-compose.yml] |
| GA-02 | The demo environment includes a sample external frontend (e.g., Next.js) using the OpenFeature client to demonstrate cross-stack usage. [VERIFIED: .planning/REQUIREMENTS.md] | Next.js App Router self-hosting guidance, OpenFeature Web SDK/provider guidance, and the recommended custom provider contract in this document. [CITED: https://nextjs.org/docs/app/guides/self-hosting] [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [CITED: https://openfeature.dev/docs/reference/concepts/provider] |
</phase_requirements>

## Summary

The repo already has the correct core shape for a thin host-app demo: `rulestead` owns runtime evaluation, cache refresh, Redis-backed snapshot reads, PubSub invalidation, and telemetry; `rulestead_admin` owns only the mounted admin UI seam; and release engineering treats the two packages as linked siblings rather than separate products. [VERIFIED: rulestead/lib/rulestead/runtime.ex] [VERIFIED: rulestead/lib/rulestead/runtime/config.ex] [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex] [VERIFIED: rulestead_admin/README.md] [VERIFIED: release-please-config.json]

The safest demo architecture is therefore a Phoenix host app in `examples/demo/backend` that depends on the local path packages, mounts `rulestead_admin`, runs normal Ecto migrations and seeds on boot, and exposes a host-owned bridge API for external clients. This matches the repo’s documented extension seams and avoids inventing a standalone control plane or official OFREP server in the GA phase. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: guides/flows/extending-rulestead.md] [VERIFIED: README.md]

For GA-02, the sample frontend should stay intentionally small: use a self-hosted Next.js App Router app that initializes an OpenFeature Web SDK provider against the Phoenix bridge API, renders one or two flag-driven UI changes, and listens for backend change notifications so the page updates immediately after an admin toggle. OpenFeature explicitly supports bespoke providers that call a REST API, and providers may emit configuration-changed events; that makes a tiny custom web provider the right demo seam. [CITED: https://openfeature.dev/docs/reference/concepts/provider] [CITED: https://openfeature.dev/docs/reference/concepts/events] [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [CITED: https://nextjs.org/docs/app/guides/self-hosting]

**Primary recommendation:** Build Phase 28 in a backend-first chain: first freeze the Phoenix host contract and demo auth/session seam, then create the thin Next.js OpenFeature client and its container target, then consume both finished apps in the root Compose/browser-proof slice. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Seeded authored state and admin UI boot | API / Backend | Database / Storage | The host Phoenix app must run migrations/seeds, mount `rulestead_admin`, and provide session/policy data; Postgres persists authored state. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: rulestead_admin/README.md] |
| Runtime evaluation of flags | API / Backend | Database / Storage | Rulestead evaluates through the runtime/cache path inside the host app, not in the browser. [VERIFIED: rulestead/lib/rulestead/runtime.ex] |
| Snapshot refresh and invalidation | API / Backend | Database / Storage | Refresh workers, Redis snapshot reads, and PubSub notifier wiring live inside the Elixir runtime. [VERIFIED: rulestead/lib/rulestead/application.ex] [VERIFIED: rulestead/lib/rulestead/store/redis.ex] [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex] |
| Cross-stack bridge API | API / Backend | Browser / Client | The host app must translate browser requests into `Rulestead.Runtime.evaluate/3` calls and return normalized JSON. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/runtime.ex] |
| Demo UI rendering | Browser / Client | API / Backend | The Next.js app displays flag outcomes, but its data source remains the host bridge API. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] |
| Real-time frontend updates | Browser / Client | API / Backend | The client should react to backend change notifications, but the source of truth and event trigger remain backend-owned. [CITED: https://openfeature.dev/docs/reference/concepts/events] [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex] [ASSUMED] |
| Container orchestration and startup order | CDN / Static | API / Backend | Compose controls service startup, health gates, and local developer entrypoint behavior. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, `guides/flows/extending-rulestead.md`. [VERIFIED: CLAUDE.md]
- `rulestead_admin` remains a guarded mounted companion and must not be turned into an early standalone publish flow. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: CLAUDE.md]
- Use scripts-first CI surfaces where workflow logic becomes non-trivial. [VERIFIED: CLAUDE.md]

## Current Repo Baseline

- Docker: the root `docker-compose.yml` currently provisions only `postgres:15`; Phase 28 still needs Redis plus backend/frontend services added at the root entrypoint. [VERIFIED: docker-compose.yml]
- OpenFeature: the repo already includes `open_feature_rulestead`, an Elixir provider package that maps OpenFeature calls onto `Rulestead.Runtime`, but it does not provide a browser/Web SDK bridge. [VERIFIED: open_feature_rulestead/mix.exs] [VERIFIED: open_feature_rulestead/lib/open_feature_rulestead/provider.ex]
- Docs: the current docs already teach the host-mounted admin seam, runtime entrypoints, deployment split, telemetry contract, and extension boundaries needed for a thin host app. [VERIFIED: README.md] [VERIFIED: guides/flows/admin-ui.md] [VERIFIED: guides/recipes/deployment.md] [VERIFIED: guides/flows/extending-rulestead.md]
- Package boundaries: the repo is already locked to a linked-version sibling-package design for `rulestead` and `rulestead_admin`, and `rulestead_admin` is documented as a mounted companion rather than a standalone product. [VERIFIED: release-please-config.json] [VERIFIED: rulestead_admin/README.md] [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `~> 1.8.1` in repo, currently locked to `1.8.5`, with `1.8.7` recently released on Hex. [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: hex package info] | Thin demo host app, admin mount, JSON bridge API. | The repo’s admin package already depends on Phoenix 1.8 and the install fixture/router seam assume a normal Phoenix host app. [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/router.ex] |
| Phoenix LiveView | `~> 1.1` in repo, currently locked to `1.1.28`, with `1.1.30` recently released on Hex. [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: hex package info] | Mounted admin UI runtime. | `rulestead_admin` is already a LiveView package; the demo should consume it, not recreate UI surfaces. [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: rulestead_admin/README.md] |
| `rulestead` | local path dependency, repo version `0.1.0`. [VERIFIED: rulestead/mix.exs] | Runtime evaluator, refresh, Redis/Postgres integration, telemetry. | The phase scope explicitly says the demo consumes the public API and only allows minimal bug fixes. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] |
| `rulestead_admin` | local path dependency, repo version `0.1.0`. [VERIFIED: rulestead_admin/mix.exs] | Mounted admin UI package. | The README and release config define it as a mounted companion, not a standalone product. [VERIFIED: rulestead_admin/README.md] [VERIFIED: release-please-config.json] |
| Next.js | `16.2.6`, published `2026-05-07`. [VERIFIED: npm registry] | Self-hosted sample external frontend. | Current official docs support App Router self-hosting on a Node server or Docker image, which matches the demo requirement. [CITED: https://nextjs.org/docs/app/guides/self-hosting] |
| React | `19.2.6`, published `2026-05-06`. [VERIFIED: npm registry] | UI runtime for the sample frontend. | Next.js 16 runs on current React and keeps the sample close to today’s default stack. [VERIFIED: npm registry] [CITED: https://nextjs.org/docs/app] |
| `@openfeature/web-sdk` | `1.8.0`, published `2026-04-21`. [VERIFIED: npm registry] | Browser-side flag evaluation API and provider lifecycle. | Official docs explicitly support `setProviderAndWait`, provider events, and custom providers backed by remote APIs. [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [CITED: https://openfeature.dev/docs/reference/concepts/provider] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@openfeature/react-sdk` | use the matching current React SDK line for `OpenFeatureProvider`; official docs cover the provider pattern. [CITED: https://openfeature.dev/docs/reference/sdks/client/web/react/] [ASSUMED] | Optional React convenience hooks and provider scoping. | Use if the sample frontend wants hook-based re-rendering instead of direct Web SDK calls. [CITED: https://openfeature.dev/docs/reference/sdks/client/web/react/] |
| Postgres image | `postgres:15` already used at repo root. [VERIFIED: docker-compose.yml] | Authored state and admin data store. | Reuse for demo Compose to stay aligned with existing repo tooling. [VERIFIED: docker-compose.yml] |
| Redis | keep Redis in Compose because GA-01 requires it and the runtime already has Redis-backed snapshot support. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: rulestead/lib/rulestead/store/redis.ex] | Snapshot-backed runtime reads and degraded demo posture. | Use whenever the demo wants to prove the distributed runtime shape rather than DB-only local reads. [VERIFIED: rulestead/lib/rulestead/redis.ex] [VERIFIED: rulestead/lib/rulestead/store/redis.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phoenix host-owned `/api/flags` bridge | Official OFREP server in core | Rejected by locked scope; adds a product surface the phase explicitly excludes. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] |
| Custom OpenFeature Web provider backed by demo API | Plain `fetch` calls in React components | Simpler initially, but it weakens the GA-02 proof because the requirement explicitly asks for OpenFeature client usage. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://openfeature.dev/docs/reference/concepts/provider] |
| SSE push from Phoenix bridge | Polling every few seconds | Polling is lower implementation effort but weaker for the roadmap’s “real-time flag streaming” success criterion. [VERIFIED: .planning/ROADMAP.md] [ASSUMED] |

**Installation:**
```bash
# Phoenix demo host
cd examples/demo/backend
mix deps.get

# Next.js demo frontend
cd ../frontend
npm install next react react-dom @openfeature/web-sdk
```

**Version verification:** Current versions were verified against the npm registry for `next`, `react`, and `@openfeature/web-sdk`, and against Hex package info for Phoenix, Phoenix LiveView, and `open_feature`. [VERIFIED: npm registry] [VERIFIED: hex package info]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  |
  | GET / (Next.js UI)
  v
Next.js App Router
  | \
  |  \ EventSource / flag refresh trigger [ASSUMED]
  |   \
  |    v
  |  Phoenix Demo Backend --------------> Phoenix.PubSub invalidation topic
  |      |   ^                                 |
  |      |   |                                 |
  |      v   |                                 |
  |   /api/flags (host bridge)                 |
  |      |                                     |
  |      v                                     |
  |  Rulestead.Runtime.evaluate/3 <------------+
  |      |
  |      v
  |  Runtime cache / refresh workers
  |      |
  |      +----> Redis snapshot store
  |      |
  |      +----> Postgres authored state
  |
  +--> /admin/flags (mounted rulestead_admin UI)
          |
          v
      Host session + host policy + seeded demo data
```

The critical architectural rule is that browser code never talks directly to Postgres, Redis, or `rulestead_admin` internals; all cross-stack behavior flows through the host Phoenix app. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: guides/flows/extending-rulestead.md]

### Recommended Project Structure

```text
examples/
└── demo/
    ├── backend/                 # Thin Phoenix host app embedding local path deps
    │   ├── lib/
    │   │   ├── demo_web/        # Router, endpoint, controllers, SSE/bridge layer
    │   │   └── demo/            # Policy, seed helpers, flag response shaping
    │   ├── priv/repo/seeds.exs  # Demo project, envs, flags, demo actor/token setup
    │   └── Dockerfile
    └── frontend/
        ├── app/                 # App Router pages
        ├── lib/                 # OpenFeature provider + bridge client
        └── Dockerfile
```

### Pattern 1: Thin Phoenix Host App

**What:** The backend exists to host Rulestead, mount the admin package, own auth/session/policy state, and expose a narrow bridge API; it should not reimplement runtime logic or admin workflows. [VERIFIED: guides/flows/extending-rulestead.md] [VERIFIED: rulestead_admin/README.md]

**When to use:** Use for the entire demo backend. Every feature that smells like “flag evaluation engine” or “admin UI internals” should delegate to the packages, not duplicate them. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

**Example:**
```elixir
# Source: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/router.ex
defmodule HostAppWeb.Router do
  use HostAppWeb, :router
  use RulesteadAdmin.Router

  pipeline :browser do
    plug :fetch_session
  end

  scope "/admin", HostAppWeb do
    pipe_through :browser
    rulestead_admin "/flags", policy: HostApp.AdminPolicy
  end
end
```

### Pattern 2: Host-Owned Bridge Endpoint

**What:** Add a small JSON boundary such as `GET /api/flags?env=staging&flag_key=enable-new-dashboard&targeting_key=demo-user` that normalizes browser inputs into a `Rulestead.Context` and delegates evaluation to `Rulestead.Runtime.evaluate/3`. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/runtime.ex] [ASSUMED]

**When to use:** Use for all frontend flag reads and optionally for live update bootstrap payloads. [ASSUMED]

**Example:**
```typescript
// Source: https://openfeature.dev/docs/reference/concepts/provider
// Bespoke providers may call a remote REST API and hide vendor specifics behind OpenFeature.
await OpenFeature.setProviderAndWait(new YourProviderOfChoice())
```

### Pattern 3: Provider-Driven Client Refresh

**What:** Keep the Next.js app’s flag logic inside one custom OpenFeature provider with an internal cache and event emitter, then have that provider emit `PROVIDER_CONFIGURATION_CHANGED` after a bridge-side SSE notification or equivalent invalidation signal. [CITED: https://openfeature.dev/docs/reference/concepts/events] [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [ASSUMED]

**When to use:** Use whenever the sample UI must change immediately after an admin toggle without full page reload. [VERIFIED: .planning/ROADMAP.md] [ASSUMED]

### Recommended Slice Boundary

**Slice A: Backend-first demo foundation** [ASSUMED]

- Phoenix demo backend boots cleanly, runs migrations/seeds automatically, mounts `rulestead_admin`, owns the `mix rulestead.install` artifacts needed for `mix ecto.setup`, and exposes stable `/api/flags` and `/api/flags/stream` contracts. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [ASSUMED]
- The host app also owns a deterministic demo sign-in route that writes the documented mounted-admin session keys for an authorized demo operator. [VERIFIED: rulestead_admin/README.md] [ASSUMED]

**Slice B: Thin Next.js OpenFeature consumer** [ASSUMED]

- Add the real Next.js frontend.
- Implement one custom OpenFeature provider against the frozen `/api/flags` contract.
- Add the frontend Docker build target alongside the app so orchestration consumes a finished sample-client contract.

**Slice C: Compose, smoke, and browser proof** [ASSUMED]

- Add the root four-service Compose graph with readiness gates.
- Prove backend, mounted admin, and frontend reachability with a script-first smoke path.
- Add the focused browser toggle proof and final docs.

This keeps the frontend and browser-proof slices low risk because both depend on an already-frozen backend contract instead of discovering runtime, auth, and seed issues late. [ASSUMED]

### Anti-Patterns to Avoid

- **Official OFREP creep:** Do not add an “official” remote evaluation server to `rulestead` core just to satisfy the demo. The scope explicitly rejects it. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]
- **Direct browser access to Redis or Postgres:** This bypasses the host-owned integration seam and proves the wrong architecture. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-DISCUSSION-LOG.md]
- **Standalone `rulestead_admin` posture:** The sample must show `rulestead_admin` as a mounted companion, not a separate product. [VERIFIED: AGENTS.md] [VERIFIED: rulestead_admin/README.md]
- **Manual table inserts in seeds:** Seed through the public/admin contexts so the demo exercises supported paths instead of coupling to schema internals. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [ASSUMED]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Admin UI | A bespoke demo admin console | `rulestead_admin` mount seam | The package already exists and the repo treats it as the supported operator surface. [VERIFIED: rulestead_admin/README.md] |
| Runtime evaluator | Browser-side evaluation logic or DB queries | `Rulestead.Runtime.evaluate/3` | Runtime evaluation is already deterministic, instrumented, and refresh-aware. [VERIFIED: rulestead/lib/rulestead/runtime.ex] |
| Distributed invalidation | Ad hoc cross-process change propagation | Existing Redis snapshot store plus Phoenix PubSub notifier seams | The runtime already supports these building blocks. [VERIFIED: rulestead/lib/rulestead/store/redis.ex] [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex] |
| Browser feature-flag API | Component-local `fetch` logic scattered through UI | One custom OpenFeature provider | OpenFeature’s provider abstraction is designed exactly for wrapping a bespoke backend API. [CITED: https://openfeature.dev/docs/reference/concepts/provider] |
| Container readiness | Sleep loops in entrypoints | Compose `healthcheck` + `depends_on.condition: service_healthy` | Docker explicitly documents that startup order alone does not guarantee readiness. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] |

**Key insight:** The only custom logic Phase 28 genuinely needs is thin glue: Phoenix bridge endpoints, demo seeds, Compose wiring, and a small browser provider. Everything deeper already exists in the repo or in standard OpenFeature/Docker machinery. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [VERIFIED: guides/flows/extending-rulestead.md] [CITED: https://openfeature.dev/docs/reference/concepts/provider]

## Common Pitfalls

### Pitfall 1: Compose starts containers before they are ready

**What goes wrong:** `docker-compose up` returns, but the backend races Postgres/Redis and either fails boot or serves an empty/unhealthy admin surface. [CITED: https://docs.docker.com/compose/how-tos/startup-order/]

**Why it happens:** Compose starts dependencies in order, but not by readiness unless health conditions are configured. [CITED: https://docs.docker.com/compose/how-tos/startup-order/]

**How to avoid:** Put healthchecks on Postgres and Redis, and gate dependent services with `depends_on.condition: service_healthy`. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] [CITED: https://docs.docker.com/compose/gettingstarted/]

**Warning signs:** Backend container restarts repeatedly; first page load shows connection errors; admin UI is blank after fresh boot. [ASSUMED]

### Pitfall 2: The demo backend grows into a product surface

**What goes wrong:** The host app starts accumulating permanent API abstractions, auth systems, or “official” remote-evaluation semantics that should belong to a future product decision, not the demo. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

**Why it happens:** Demo phases often blur “bridge code” and “core feature.” [ASSUMED]

**How to avoid:** Keep the bridge contract minimal, repo-local, and explicitly demo-scoped. No new core package, no standalone publish story, no official OFREP. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

**Warning signs:** New code lands under `rulestead/` or `rulestead_admin/` for demo-only concerns; docs start describing a separate remote service. [ASSUMED]

### Pitfall 3: Violating the mounted admin session contract

**What goes wrong:** The admin UI mounts but breaks on environment picker state or authorization assumptions. [VERIFIED: rulestead_admin/README.md]

**Why it happens:** The host must provide `"current_actor"`, `"rulestead_admin_environments"`, and `"rulestead_admin_last_env"` session values, plus a `policy:` module. [VERIFIED: rulestead_admin/README.md] [VERIFIED: guides/flows/admin-ui.md]

**How to avoid:** Treat the demo host like a real host app and provide those session keys intentionally rather than bypassing them. [VERIFIED: rulestead_admin/README.md]

**Warning signs:** Missing environment picker data, incorrect redirects when `?env=` is absent, or authorization errors on routes that should render. [VERIFIED: rulestead_admin/README.md] [ASSUMED]

### Pitfall 4: “OpenFeature demo” without actual provider semantics

**What goes wrong:** The frontend technically fetches flags, but the code never proves provider lifecycle, re-evaluation, or OpenFeature client usage. [VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** It is tempting to replace the provider with plain HTTP calls once the UI renders. [ASSUMED]

**How to avoid:** Centralize all browser evaluations behind `@openfeature/web-sdk` and `setProviderAndWait`, then emit configuration-changed events on backend updates. [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [CITED: https://openfeature.dev/docs/reference/concepts/events] [ASSUMED]

**Warning signs:** Components import raw `fetch` for flag values or duplicate context serialization logic. [ASSUMED]

## Code Examples

Verified patterns from official sources and the repo:

### Mount the admin UI through the host router
```elixir
# Source: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/router.ex
scope "/admin", HostAppWeb do
  pipe_through :browser
  rulestead_admin "/flags", policy: HostApp.AdminPolicy
end
```

### Keep request-wide context assignment at the endpoint boundary
```elixir
# Source: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex
plug Plug.RequestId
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
plug Rulestead.Plug
plug Plug.Session, @session_options
plug HostAppWeb.Router
```

### Initialize an OpenFeature web provider before evaluating flags
```typescript
// Source: https://openfeature.dev/docs/reference/sdks/client/web/
import { OpenFeature } from '@openfeature/web-sdk';

await OpenFeature.setProviderAndWait(new YourProviderOfChoice());
const client = OpenFeature.getClient();
const enabled = client.getBooleanValue('v2_enabled', false);
```

### Custom providers may wrap a bespoke backend API
```typescript
// Source: https://openfeature.dev/docs/reference/concepts/provider
// Providers can call a bespoke flag evaluation REST API and hide its transport details.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat feature-flag platforms as standalone hosted services | Embed flag logic in the host app and expose only host-owned HTTP seams where needed | Current repo architecture and current OpenFeature provider guidance both support this shape. [VERIFIED: guides/flows/extending-rulestead.md] [CITED: https://openfeature.dev/docs/reference/concepts/provider] | The demo should prove embeddability, not imitate a SaaS control plane. |
| Scatter flag fetch logic in UI components | Use a single OpenFeature provider plus client/hooks | Current OpenFeature Web/React SDK guidance. [CITED: https://openfeature.dev/docs/reference/sdks/client/web/] [CITED: https://openfeature.dev/docs/reference/sdks/client/web/react/] | Keeps GA-02 demonstrably cross-stack and reduces duplicate client code. |
| Startup-order sleeps in Docker demos | Healthcheck-driven readiness gating | Current Docker Compose guidance. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] | Makes “one command to working demo” materially more reliable. |

**Deprecated/outdated:**

- Direct browser access to backing stores for flag reads is architecturally incorrect for this repo’s host-owned seam. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-DISCUSSION-LOG.md]
- Treating `rulestead_admin` as a standalone admin product is explicitly against repo guidance. [VERIFIED: AGENTS.md] [VERIFIED: rulestead_admin/README.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SSE is the best low-risk mechanism for “real-time” frontend updates versus Phoenix Channels or polling. | Architecture Patterns / Alternatives Considered | Moderate; if the team prefers Channels, the client/provider shape stays similar but transport work changes. |
| A2 | The demo seeds can and should create demo state only through stable public/admin APIs rather than direct schema inserts. | Anti-Patterns / Summary | Low to moderate; if the necessary context helper API is missing, the phase may need a small backend bug fix or narrower seeding seam. |
| A3 | `@openfeature/react-sdk` should be added only if the demo benefits from hook ergonomics; `@openfeature/web-sdk` alone is enough for GA-02. | Standard Stack | Low; affects frontend implementation style, not architecture. |
| A4 | The final Compose/browser-proof slice should consume a finished frontend app and Docker target instead of claiming frontend ownership itself. | Recommended Slice Boundary | Low; if execution reveals extra frontend build concerns, they still belong in the frontend slice rather than in orchestration. |

## Open Questions (RESOLVED)

1. **Should the live-update bridge be SSE or Phoenix Channels?**
   - Resolution: Use SSE at `/api/flags/stream`.
   - Why: OpenFeature providers only need a bounded configuration-changed trigger, the repo has no existing browser transport convention, and SSE keeps the host-owned bridge thin without introducing Channels-specific client complexity. [CITED: https://openfeature.dev/docs/reference/concepts/events] [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex]

2. **Which public/admin function set is the cleanest seed path?**
   - Resolution: The demo host should capture the supported install surface with `mix rulestead.install`, own the generated `priv/repo/migrations/**/*` plus host `Repo`, and use supported `Rulestead.Admin` or store-command seams inside `priv/repo/seeds.exs` for demo project, environments, flags, and operator setup.
   - Why: The repo docs explicitly define `mix rulestead.install` as the supported schema/bootstrap path, and the phase context explicitly requires seeds to use `Rulestead.Admin` rather than raw inserts. [VERIFIED: guides/introduction/installation.md] [VERIFIED: guides/recipes/ecto-conventions.md] [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md]

3. **How strictly should the phase depend on Phase 27 execution state?**
   - Resolution: The demo host must respect the Phase 27 posture by using a deterministic host-owned sign-in path that writes the documented session keys for a seeded demo Admin actor and still flows through `Rulestead.Admin.Policy.can?/4`.
   - Why: That gives browser automation a deterministic operator path without inventing package-owned auth or bypassing mounted-admin authorization semantics. [VERIFIED: rulestead_admin/README.md] [VERIFIED: guides/flows/admin-ui.md] [VERIFIED: .planning/ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker | Local E2E orchestration | ✓ [VERIFIED: local command] | `29.4.1` [VERIFIED: local command] | — |
| Docker Compose | `docker-compose.yml` entrypoint | ✓ [VERIFIED: local command] | `v5.1.3` [VERIFIED: local command] | `docker compose` if shell aliases differ. [VERIFIED: local command] |
| Node.js | Next.js frontend | ✓ [VERIFIED: local command] | `v22.14.0` [VERIFIED: local command] | — |
| npm | Frontend package install | ✓ [VERIFIED: local command] | `11.1.0` [VERIFIED: local command] | — |
| Elixir | Phoenix demo backend | ✓ [VERIFIED: local command] | `1.19.5` [VERIFIED: local command] | — |
| Erlang/OTP | Phoenix demo backend | ✓ [VERIFIED: local command] | `28` [VERIFIED: local command] | — |
| `psql` CLI | Local debugging only | ✓ [VERIFIED: local command] | `14.17` [VERIFIED: local command] | Container shell if needed. [ASSUMED] |
| `redis-cli` | Local debugging only | ✓ [VERIFIED: local command] | `7.2.4` [VERIFIED: local command] | Container shell if needed. [ASSUMED] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit across `rulestead`, `rulestead_admin`, and `open_feature_rulestead`. [VERIFIED: scripts/ci/test.sh] [VERIFIED: repo test tree] |
| Config file | none detected; standard Mix/ExUnit defaults. [VERIFIED: repo file scan] |
| Quick run command | `./scripts/ci/test.sh` [VERIFIED: scripts/ci/test.sh] |
| Full suite command | `cd rulestead && mix test --warnings-as-errors && cd ../rulestead_admin && mix test --warnings-as-errors && cd ../open_feature_rulestead && mix test` [VERIFIED: scripts/ci/test.sh] [VERIFIED: open_feature_rulestead/test] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GA-01 | `docker-compose up` reaches seeded admin UI with healthy dependencies and a reachable sample frontend. [VERIFIED: .planning/ROADMAP.md] | smoke/integration | `scripts/demo/smoke.sh` [ASSUMED] | ❌ Wave 0 |
| GA-01 | Backend boot runs migrations and seeds automatically. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] | integration | `docker compose logs backend | rg 'ecto.setup|seed'` or an ExUnit smoke that asserts seeded rows. [ASSUMED] | ❌ Wave 0 |
| GA-02 | Next.js frontend evaluates flags through OpenFeature against the Phoenix bridge. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `cd examples/demo/frontend && npm test -- --runInBand rulestead-web-provider.test.ts` [ASSUMED] | ❌ Wave 0 |
| GA-02 | Toggling a flag in admin propagates to the sample app without reload or with explicit re-evaluation trigger. [VERIFIED: .planning/ROADMAP.md] | e2e | `cd examples/demo/frontend && npm run test:e2e` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `./scripts/ci/test.sh` plus targeted demo-app tests once those exist. [VERIFIED: scripts/ci/test.sh] [ASSUMED]
- **Per wave merge:** Demo-specific integration smoke plus package test suites. [ASSUMED]
- **Phase gate:** Compose smoke + backend seed verification + cross-stack toggle proof all green before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md] [ASSUMED]

### Wave 0 Gaps

- [ ] `examples/demo/backend/test/...` ExUnit smoke for boot, seeds, deterministic demo sign-in, and `/api/flags` contract. [ASSUMED]
- [ ] `examples/demo/frontend/...` frontend integration or browser smoke for OpenFeature usage. [ASSUMED]
- [ ] `scripts/demo/smoke.sh` covering backend, mounted admin, and frontend reachability from one Compose boot. [VERIFIED: CLAUDE.md] [ASSUMED]
- [ ] A deterministic Compose smoke command documented in `README.md`. [VERIFIED: README.md] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host Phoenix session/auth owns identity for mounted admin routes; do not invent package-local auth. [VERIFIED: rulestead_admin/README.md] |
| V3 Session Management | yes | Phoenix endpoint/browser pipeline with `Plug.Session` and the documented admin session keys. [VERIFIED: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex] [VERIFIED: rulestead_admin/README.md] |
| V4 Access Control | yes | Host-owned `Rulestead.Admin.Policy.can?/4` seam. [VERIFIED: rulestead_admin/README.md] [VERIFIED: guides/flows/extending-rulestead.md] |
| V5 Input Validation | yes | Bridge endpoint must validate `env`, `flag key`, and evaluation context payload before delegating. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [ASSUMED] |
| V6 Cryptography | yes | Reuse Phoenix session signing and existing Rulestead telemetry/redaction boundaries; never hand-roll secret handling for the demo. [VERIFIED: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex] [VERIFIED: guides/flows/telemetry.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated access to `/admin/flags` | Elevation of Privilege | Keep admin behind the host browser pipeline and `policy:` seam. [VERIFIED: rulestead_admin/README.md] |
| Over-permissive `/api/flags` bridge leaking internal data | Information Disclosure | Return only normalized evaluation results; do not expose raw authored snapshots, Redis payloads, or admin-only data. [VERIFIED: .planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md] [ASSUMED] |
| Compose-exposed secrets or fake tokens committed into docs | Information Disclosure | Use demo-only non-secret defaults and keep docs explicit that the bridge is host-owned sample code. [VERIFIED: README.md] [ASSUMED] |
| CSRF or browser misuse on admin mutation routes | Tampering | Rely on standard Phoenix browser pipeline and mounted admin package instead of bypassing it with custom mutation endpoints. [VERIFIED: rulestead/test/fixtures/install_golden/tree/lib/host_app_web/endpoint.ex] [VERIFIED: rulestead_admin/README.md] |
| Stale or inconsistent browser flag state after admin changes | Tampering/Repudiation | Drive client refresh from provider events sourced by backend invalidation notices. [CITED: https://openfeature.dev/docs/reference/concepts/events] [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- Repo docs and code:
  - `README.md` - sibling-package product framing and host-mount contract. [VERIFIED: README.md]
  - `rulestead_admin/README.md` - mounted admin contract, session keys, and role model. [VERIFIED: rulestead_admin/README.md]
  - `guides/flows/extending-rulestead.md` - official repo extension seams. [VERIFIED: guides/flows/extending-rulestead.md]
  - `rulestead/lib/rulestead/runtime.ex` - runtime evaluation ownership. [VERIFIED: rulestead/lib/rulestead/runtime.ex]
  - `rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex` - PubSub invalidation seam. [VERIFIED: rulestead/lib/rulestead/runtime/notifier/phoenix_pub_sub.ex]
  - `release-please-config.json` - linked-version two-package release design. [VERIFIED: release-please-config.json]
- Official docs:
  - Docker Compose startup order - https://docs.docker.com/compose/how-tos/startup-order/
  - Docker Compose quickstart healthchecks - https://docs.docker.com/compose/gettingstarted/
  - Next.js App Router self-hosting - https://nextjs.org/docs/app/guides/self-hosting
  - OpenFeature Web SDK - https://openfeature.dev/docs/reference/sdks/client/web/
  - OpenFeature providers concept - https://openfeature.dev/docs/reference/concepts/provider
  - OpenFeature events concept - https://openfeature.dev/docs/reference/concepts/events
  - OpenFeature React SDK - https://openfeature.dev/docs/reference/sdks/client/web/react/
  - OpenFeature Elixir `OpenFeature.Provider` - https://hexdocs.pm/open_feature/OpenFeature.Provider.html
  - OpenFeature Elixir main module - https://hexdocs.pm/open_feature/OpenFeature.html

### Secondary (MEDIUM confidence)

- Context7 extracts from official Next.js, Phoenix, and OpenFeature JS documentation used to confirm provider/bootstrap and self-hosting patterns. [VERIFIED: ctx7 CLI]

### Tertiary (LOW confidence)

- No tertiary web-only sources were required beyond clearly labeled assumptions. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - repo package boundaries and current external package versions were directly verified. [VERIFIED: repo mix.exs files] [VERIFIED: npm registry] [VERIFIED: hex package info]
- Architecture: MEDIUM - the backend-owned seam is strongly verified, but the exact live-update transport is still an implementation choice. [VERIFIED: repo docs/code] [ASSUMED]
- Pitfalls: HIGH - the major failure modes are directly supported by Docker/OpenFeature docs and repo constraints. [CITED: https://docs.docker.com/compose/how-tos/startup-order/] [CITED: https://openfeature.dev/docs/reference/concepts/events] [VERIFIED: rulestead_admin/README.md]

**Research date:** 2026-05-20
**Valid until:** 2026-06-19 for repo-specific findings; re-check npm/Hex package versions sooner if implementation starts later. [VERIFIED: npm registry] [VERIFIED: hex package info]

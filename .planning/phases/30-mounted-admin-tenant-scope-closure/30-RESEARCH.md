# Phase 30: Mounted Admin Tenant Scope Closure - Research

**Researched:** 2026-05-22 [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Domain:** Mounted Phoenix LiveView admin tenant-scope resolution and compare-route propagation in a linked-version sibling-package monorepo. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex]
**Confidence:** HIGH [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Product shape and phase discipline
- **D-01:** Phase 30 is a narrow gap-closure phase. Reuse the Phase 29 tenancy seam and mounted-admin patterns rather than introducing new product surface area.
- **D-02:** Preserve the linked-version sibling-package design. Do not prepare `rulestead_admin` for standalone publishing.
- **D-03:** Keep Phase 31 work out of scope. This phase preserves explicit tenant scope in mounted-admin flows; it does not automate tenant provenance on writes.

### Mounted-admin tenant session resolution
- **D-04:** Mounted-admin tenant resolution must follow the same precedence posture already used for environments: URL tenant first if allowed, remembered tenant second if allowed, otherwise host default or first allowed tenant, otherwise fail closed.
- **D-05:** The host session remains the source of truth for allowed tenant choices and optional default tenant. Rulestead must not derive tenants from authored storage.
- **D-06:** Invalid tenant params must not silently broaden scope. If a requested tenant is not allowed, mounted flows must fall back only within the bounded allowed set or halt back to the mount root.
- **D-07:** Tenant scope remains separate from environment scope in assigns, helper APIs, route params, and visible shell chrome.

### Compare flow carry-through
- **D-08:** Environment compare pages must pass explicit `tenant_key` through the existing shared compare seam so compare tokens, findings, and reviewed scope reflect the mounted-admin tenant choice.
- **D-09:** Route helpers for mounted-admin compare flows must preserve both `env` and `tenant` params together so scope does not drift across navigation.
- **D-10:** The compare page should surface the active tenant scope alongside environment scope, but must not introduce an implicit all-tenant compare mode.

### Verification posture
- **D-11:** Verification should focus on mounted-admin session helpers, compare route generation, and compare invocation with explicit `tenant_key`.
- **D-12:** Reuse targeted tests in both packages instead of broad E2E expansion. The goal is to prove the mounted path, not to widen the release shape.

### Claude's Discretion
- No separate `Claude's Discretion` section was provided in `30-CONTEXT.md`. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Automatic tenant provenance injection in audit mutation/apply paths
- Cross-tenant compare or dashboard views
- Tenant lifecycle or catalog management inside Rulestead
- Broad admin UI redesign beyond the mounted scope chrome needed for tenant visibility
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-01 | Runtime and admin flows support explicit tenant scope without requiring environment-per-tenant or cloned flag topology. [VERIFIED: .planning/REQUIREMENTS.md] | Extend `RulesteadAdmin.Live.Session.resolve/3`, `current_path/3`, and `env_links/3` to preserve allowed tenant scope alongside environment scope, then consume that scope in both compare LiveViews. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex] |
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the already-shipped compare seam that carries `tenant_key` through `Command.CompareEnvironments`, compare token generation, and store adapters; do not add a second tenant transport or widen into Phase 31 provenance automation. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 30 should close one specific carry-through gap, not redesign tenancy. The core compare seam is already tenant-aware: `Rulestead.compare_environments/3` builds `Command.CompareEnvironments`, that command already has `tenant_key`, both Ecto and Fake adapters forward it, and compare token generation includes it. The mounted admin is the part that still drops tenant scope because `Live.Session` only resolves environment state and both compare LiveViews only read and preserve `env`, `source_env`, `target_env`, and `compare_token`. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex]

The implementation-ready recommendation is therefore narrow: mirror the existing environment precedence model for tenant resolution inside `RulesteadAdmin.Live.Session`, expose tenant-aware route helpers and shell assigns there, thread `tenant_key` into compare page params and `Rulestead.compare_environments/3`, and extend the existing focused ExUnit/LiveView suites in both packages to prove fail-closed behavior. That matches the locked Phase 30 decisions, the host-owned mount boundary, the operator IA requirement that tenant stays URL-visible, and the security prompt’s fail-closed posture. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: prompts/rulestead-host-app-integration-seam.md] [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]

**Primary recommendation:** Implement Phase 30 entirely by extending the existing mounted session and compare helpers to preserve an explicit allowed `tenant_key`, then verify that both compare URLs and compare commands keep tenant and environment as separate fail-closed scope axes. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex]

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout and linked-version release shape. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md]
- Do not create Phase 8-only docs early. [VERIFIED: CLAUDE.md]
- Do not widen `rulestead_admin` into an early standalone publish flow. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: CLAUDE.md]
- Use scripts-first CI surfaces when workflow logic becomes non-trivial. [VERIFIED: CLAUDE.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mounted-admin tenant resolution | Frontend Server (SSR/LiveView) | API / Backend | Tenant selection is derived from host session plus URL params inside the mounted LiveView hook, not from browser-only state or authored storage. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Allowed-tenant authorization boundary | Frontend Server (SSR/LiveView) | Browser / Client | The mounted admin owns scope validation before rendering and should halt or patch back to the mount root on invalid scope. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| Compare command tenant propagation | API / Backend | Frontend Server (SSR/LiveView) | The LiveViews supply `tenant_key`, but the compare contract, compare token, and adapter parity are owned by `rulestead`. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| Visible scope chrome | Frontend Server (SSR/LiveView) | Browser / Client | The shell component renders current scope and route links, but the server supplies the canonical env and tenant values. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime, tests, and package build surface for both sibling packages. [VERIFIED: `elixir --version`] | This is the active local toolchain for the repo and satisfies both packages’ `~> 1.17` floor. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead_admin/mix.exs] |
| Phoenix LiveView | 1.1.28 in repo, 1.1 docs contract verified | Mounted admin lifecycle, `on_mount`, `handle_params/3`, and live-patched URL state. [VERIFIED: `cd rulestead_admin && mix run -e ...`] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Phase 30 is fundamentally a LiveView URL/session propagation fix, and the official docs confirm `params` and `handle_params/3` are the supported router-mounted state seam. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Phoenix | 1.8.5 | Host-mounted admin routing and test surface in `rulestead_admin`. [VERIFIED: `cd rulestead_admin && mix run -e ...`] [VERIFIED: rulestead_admin/mix.exs] | The mounted admin already ships on Phoenix and should keep using the existing router/session boundary instead of adding a new transport. [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: prompts/rulestead-host-app-integration-seam.md] |
| Ecto | 3.13.5 | Core adapter parity coverage and sandbox-backed tests in `rulestead`. [VERIFIED: `cd rulestead && mix run -e ...`] [VERIFIED: rulestead/mix.exs] | Core compare contract parity is already enforced against both Ecto and Fake adapters, so Phase 30 should keep leaning on that rather than adding a one-off compare implementation. [VERIFIED: rulestead/test/rulestead/store/compare_contract_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix HTML | 4.3.0 | HTML rendering helpers in the mounted admin package. [VERIFIED: `cd rulestead_admin && mix run -e ...`] | Use through existing LiveView components such as `Shell.page/1`; no new client-side routing layer is needed. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] |
| StreamData | repo floor `~> 1.1` | Existing property-test infrastructure in `rulestead`. [VERIFIED: rulestead/mix.exs] | Not required for the narrow Phase 30 gap unless a planner chooses an extra property test for route/helper normalization. [VERIFIED: rulestead/mix.exs] |
| `a11y_audit` | repo floor `~> 0.3.1` | Existing admin accessibility assertions. [VERIFIED: rulestead_admin/mix.exs] | Optional for Phase 30 if tenant chrome changes materially affect semantic labeling; not the primary verification gate. [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/accessibility_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `RulesteadAdmin.Live.Session` | Per-page tenant parsing in compare LiveViews | This would duplicate precedence logic and make tenant/environment drift more likely across mounted routes. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] |
| Reuse `Command.CompareEnvironments.tenant_key` | Build a separate admin-only compare option | That would fork the compare contract away from the existing store parity tests. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/test/rulestead/store/compare_contract_test.exs] |
| Add tenant chips to existing shell | Build a new compare-only scope widget | That would widen UI surface beyond the locked minimal gap closure and conflict with the shared shell pattern. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] |

**Installation:**
```bash
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```

**Version verification:** Phase 30 does not require new dependencies. The planning baseline should use the repo-locked Mix manifests plus the locally verified toolchain and current LiveView docs contract above. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: `elixir --version`] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

## Architecture Patterns

### System Architecture Diagram

```text
Host session + URL query params
  -> `RulesteadAdmin.Live.Session.on_mount/4`
    -> resolve env from allowed envs
    -> resolve tenant from allowed tenants
    -> fail closed if mounted scope is not allowed
      -> shared shell assigns (`current_environment`, `current_tenant`, links)
        -> compare index/show URL helpers preserve env + tenant + compare token
          -> `Rulestead.compare_environments/3`
            -> `Command.CompareEnvironments.new(..., tenant_key: ...)`
              -> Ecto/Fake adapter `compare_environments/1`
                -> `Promotion.Compare.compare_projected/1`
                  -> compare token/findings with explicit tenant scope
```

### Recommended Project Structure
```text
rulestead_admin/lib/rulestead_admin/
├── live/session.ex                       # canonical mounted env+tenant resolution
├── components/shell.ex                   # visible env/tenant scope chrome
└── live/environment_compare_live/
   ├── index.ex                           # list-level compare route + compare call
   └── show.ex                            # flag drill-in compare route + compare call

rulestead/lib/rulestead/
├── store/command.ex                      # compare command contract with tenant_key
├── promotion/compare.ex                  # compare token/result semantics
├── store/ecto.ex                         # real adapter compare forwarding
└── fake.ex                               # fake adapter compare forwarding
```

### Pattern 1: Host-Bounded Tenant Resolution Mirrors Environment Resolution
**What:** Add tenant precedence to `Session.resolve/3` using allowed tenants from host session, the remembered tenant, the host default tenant, then first allowed tenant, and otherwise fail closed. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
**When to use:** Every mounted admin route that already depends on `Session.on_mount/4`, especially compare index and show pages. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex]
**Example:**
```elixir
# Source: recommended extension of rulestead_admin/lib/rulestead_admin/live/session.ex
{tenant, tenant_source} =
  cond do
    selected = find_allowed_tenant(tenants, url_tenant) -> {selected, :url}
    selected = find_allowed_tenant(tenants, remembered_tenant) -> {selected, :remembered}
    selected = default_tenant(tenants, host_default_tenant) -> {selected, :default}
    true -> :error
  end
```

### Pattern 2: URL State Owns Compare Scope
**What:** Keep `tenant`, `env`, `source_env`, `target_env`, and `compare_token` in the LiveView params path so `handle_params/3` remains the single scope rebuild point after mount and live patches. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
**When to use:** For `Session.current_path/3`, `Session.env_links/3`, and any new tenant-aware route helper. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
# `handle_params/3` is invoked after mount and whenever there is a live patch event.
```

### Pattern 3: Compare Seam Reuse, Not Reinvention
**What:** Pass tenant scope through `Rulestead.compare_environments/3` options so existing compare-token semantics, findings, and adapter parity remain intact. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex]
**When to use:** In compare index and show LiveViews only; Phase 31 provenance automation remains out of scope. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/store/command.ex
Command.CompareEnvironments.new("staging", "production",
  tenant_key: "acme",
  compare_token: "cmp_123"
)
```

### Anti-Patterns to Avoid
- **Page-local tenant precedence:** Do not parse `params["tenant"]` differently in each compare LiveView. The resolver must stay centralized in `Live.Session`. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
- **Implicit all-tenant compare:** Do not interpret an invalid or missing tenant param as authority to broaden compare scope. The Phase 30 context explicitly forbids that. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
- **Environment-only route helpers:** Do not update compare calls to include `tenant_key` while leaving `Session.current_path/3`, `env_links/3`, and drill-in links environment-only. That would reintroduce drift on navigation. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tenant scope memory | A separate compare-specific session store | Extend the existing mounted session payload with allowed/default/remembered tenant values | The host session is already the source of truth for mounted scope. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| Compare tenant transport | A compare-page-local tenant struct | `tenant_key` on `Command.CompareEnvironments` | The core compare seam and token semantics already understand `tenant_key`. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| Cross-package verification | New browser E2E or host app smoke expansion | Existing targeted ExUnit + Phoenix LiveView tests in both packages | The testing strategy prefers fast targeted integration coverage over broad trust-theater E2E for narrow gaps. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md] [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs] |

**Key insight:** Phase 30 should change the mounted admin’s scope plumbing, not the compare engine. All heavy lifting for tenant-aware compare semantics is already enforced downstream in `rulestead`. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/test/rulestead/store/compare_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Invalid URL Tenant Falls Back Too Broadly
**What goes wrong:** An unauthorized `tenant` param can silently collapse to a broader or unrelated scope instead of staying inside the allowed tenant set or halting back to the mount root. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Why it happens:** The current environment resolver treats invalid `env` as default, but tenant scope has the extra security requirement that invalid params must not imply all-tenant access. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**How to avoid:** Add tenant resolution helpers that validate only against host-provided allowed tenants and make `allowed?/1` incorporate tenant presence when tenancy is enabled. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]
**Warning signs:** `params["tenant"]` is read directly in compare pages or tenant defaults come from authored data rather than host session. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]

### Pitfall 2: Compare Routes Preserve `env` but Drop `tenant`
**What goes wrong:** Mounted navigation appears scoped in the shell but compare drill-ins re-run against a nil tenant or a different tenant. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex]
**Why it happens:** `Session.current_path/3`, `Session.env_links/3`, and `flag_path/2` currently only encode environment and compare params. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex]
**How to avoid:** Treat tenant as part of the canonical mounted scope param set everywhere `env` is already preserved. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Warning signs:** New tests assert `tenant_key` reaches `Rulestead.compare_environments/3` but no tests assert `tenant=` remains present in generated links. [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs] [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs]

### Pitfall 3: Shell Shows Environment but Not Tenant
**What goes wrong:** Operator-visible scope becomes incomplete, contradicting the mounted-admin UX rule that tenant and environment remain separate visible selectors/chips. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md]
**Why it happens:** `Shell.page/1` currently renders only the environment section. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex]
**How to avoid:** Add the minimum shell assigns and rendering needed to surface current tenant scope, using a read-only chip when exactly one tenant is allowed. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Warning signs:** Compare pages mention tenant in copy or traces but the shell header still only exposes environment controls. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex]

## Code Examples

Verified patterns from the current repo and official docs:

### Core Compare Seam Already Accepts `tenant_key`
```elixir
# Source: rulestead/lib/rulestead/store/command.ex
def new(source_environment_key, target_environment_key, opts \\ []) do
  %__MODULE__{
    source_environment_key: GovernanceSupport.normalize_string(source_environment_key),
    target_environment_key: GovernanceSupport.normalize_string(target_environment_key),
    tenant_key: GovernanceSupport.normalize_string(Keyword.get(opts, :tenant_key)),
    flag_keys: normalize_flag_keys(Keyword.get(opts, :flag_keys)),
    compare_token: GovernanceSupport.normalize_string(Keyword.get(opts, :compare_token))
  }
end
```

### Mounted Compare Pages Currently Rebuild State in `handle_params/3`
```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex
def handle_params(params, _uri, socket) do
  source_env = params["source_env"] || socket.assigns.current_environment.key
  target_env = params["target_env"] || socket.assigns.current_environment.key
  compare_token = blank_to_nil(params["compare_token"])
  page = build_page(socket, source_env, target_env, compare_token)
  ...
end
```

### Official LiveView Contract for Router-Mounted URL State
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
# `handle_params/3` is invoked after mount and whenever there is a live patch event.
# It receives the current params, including query params and router params.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mounted admin compare state preserved only `env` and compare params. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] | Mounted compare should preserve both `env` and `tenant` because tenant is already first-class in the core compare contract. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] | Gap identified on 2026-05-22 in Phase 30 context synthesis. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] | Fixes real operator path drift without widening product scope. [VERIFIED: .planning/ROADMAP.md] |
| Tenant entry was already explicit in local simulation only. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex] | Mounted compare and shell should reuse explicit tenant scope outside local simulation too. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] | Phase 29 left local simulation covered but not the mounted compare path. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] | Keeps tenancy explicit in real operator flows. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**
- Treating mounted compare as environment-only scope is outdated for `v1.1.0` because the roadmap now explicitly requires mounted-admin tenant scope carry-through. [VERIFIED: .planning/ROADMAP.md]

## Assumptions Log

All claims in this research were verified or cited in this session. No user confirmation is required before planning.

## Open Questions (RESOLVED)

None that block planning. The remaining choices are implementation detail choices already delegated by the Phase 30 context, such as exact session key/helper names and exact shell chip layout. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Both package tests and any Phase 30 execution | ✓ | 1.19.5 | — |
| Mix | Both package dependency/test commands | ✓ | 1.19.5 | — |
| Node.js | Not required for the targeted Phase 30 verification surface | ✓ | 22.14.0 | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`] [VERIFIED: `node --version`]

**Missing dependencies with fallback:**
- None. [VERIFIED: `elixir --version`] [VERIFIED: `mix --version`] [VERIFIED: `node --version`]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveViewTest and Ecto SQL Sandbox. [VERIFIED: rulestead/test/test_helper.exs] [VERIFIED: rulestead_admin/test/test_helper.exs] |
| Config file | none; package-local `test/test_helper.exs` files bootstrap each package. [VERIFIED: rulestead/test/test_helper.exs] [VERIFIED: rulestead_admin/test/test_helper.exs] |
| Quick run command | `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs] [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs] [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/show_test.exs] |
| Full suite command | `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` [VERIFIED: rulestead/test/rulestead/promotion/compare_test.exs] [VERIFIED: rulestead/test/rulestead/store/compare_contract_test.exs] [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEN-01 | Mounted session resolves tenant with URL > remembered > host default/first allowed precedence and fails closed on invalid mounted scope. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs` | ✅ |
| TEN-01 | Compare index/show routes preserve `tenant` alongside `env`, `source_env`, `target_env`, and `compare_token`. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` | ✅ |
| TEN-03 | Compare invocation forwards explicit `tenant_key` through the public facade and adapter contract. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] | unit + adapter contract | `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `cd rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`
- **Per wave merge:** `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`
- **Phase gate:** All targeted core and admin suites above green before `/gsd-verify-work`.

### Wave 0 Gaps
- None — existing test infrastructure and target files already exist; the work is to extend assertions inside those files, not to create a new framework surface. [VERIFIED: rulestead/test/test_helper.exs] [VERIFIED: rulestead_admin/test/test_helper.exs]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-owned authenticated session remains the mounted admin identity source; Rulestead consumes it but does not issue auth. [VERIFIED: prompts/rulestead-host-app-integration-seam.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V3 Session Management | yes | Mounted scope derives from bounded host session keys plus URL params; invalid scope must fail closed. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V4 Access Control | yes | Allowed-tenant lists and admin access checks remain enforced before render, with no implicit all-tenant mode. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| V5 Input Validation | yes | Validate URL `tenant` and `env` against host-provided allowed sets before using them in mounted routes or compare calls. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| V6 Cryptography | no | Phase 30 does not add new crypto concerns; it reuses existing compare token generation unchanged. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tenant query-param tampering in mounted admin | Tampering | Resolve tenant only from host-allowed values and halt or patch back to mount root on invalid scope. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| Cross-tenant disclosure via implicit compare scope | Information Disclosure | Require explicit `tenant_key` propagation and do not introduce implicit all-tenant reads. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/store/command.ex] |
| Scope drift between shell links and compare execution | Tampering | Build canonical tenant-aware links through shared session helpers and assert them in tests. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 30 goal, success criteria, and gap-closure scope. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - active requirement mapping for `TEN-01` and `TEN-03`. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md` - locked phase decisions and out-of-scope boundaries. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md`, `29-RESEARCH.md`, `29-VERIFICATION.md` - prior mounted-tenancy posture and what Phase 29 already proved. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-RESEARCH.md] [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-VERIFICATION.md]
- `rulestead_admin/lib/rulestead_admin/live/session.ex`, `components/shell.ex`, `live/environment_compare_live/index.ex`, `live/environment_compare_live/show.ex` - direct mounted-admin seam inspection. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/show.ex]
- `rulestead/lib/rulestead/store/command.ex`, `promotion/compare.ex`, `store/ecto.ex`, `fake.ex`, `rulestead.ex` - core compare contract inspection. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] [VERIFIED: rulestead/lib/rulestead/fake.ex] [VERIFIED: rulestead/lib/rulestead.ex]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - official `mount/3`, `handle_params/3`, and `on_mount` behavior for router-mounted LiveViews. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo-locked Mix manifests, local toolchain verification, and official LiveView docs were all inspected directly. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: `elixir --version`] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Architecture: HIGH - the exact gap is visible in current code and bounded by locked Phase 30 decisions. [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex]
- Pitfalls: HIGH - each pitfall is derived from current mounted-admin code plus the security and operator IA anchors. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]

**Research date:** 2026-05-22 [VERIFIED: .planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md]
**Valid until:** 2026-06-21 for this repo state, unless Phase 30 implementation lands earlier and changes the mounted compare/session seams. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex]

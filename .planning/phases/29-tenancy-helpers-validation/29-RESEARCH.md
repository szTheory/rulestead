# Phase 29: Tenancy Helpers & Validation - Research

**Researched:** 2026-05-21 [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Domain:** Explicit tenant-aware runtime/admin scope, preview/apply validation, and bounded tenancy metadata in a linked-version Phoenix/Elixir library pair [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md]
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Product shape and milestone discipline
- **D-01:** Phase 29 preserves the linked-version sibling-package design and must not widen `rulestead_admin` into a standalone tenant control plane.
- **D-02:** Tenancy remains a helper seam layered on top of the existing environment model. Environment and tenant stay separate axes in URLs, APIs, plans, and operator mental models.
- **D-03:** Phase 29 should favor additive helpers and validators over schema-wide rewrites or topology changes.

### Admin tenant scope UX
- **D-04:** Mounted admin uses a **host-bounded explicit picker** model for tenant scope, not fixed ambient scope only and not freeform URL/session authority.
- **D-05:** The host session must provide the allowed tenant catalog and optional default tenant. Rulestead must not discover tenant options from its own storage internals.
- **D-06:** Tenant scope resolution should mirror the current environment pattern:
  - URL tenant first, only if it belongs to the host-provided allowed set
  - remembered tenant second, only if it belongs to the allowed set
  - otherwise host default or first allowed tenant
  - otherwise fail closed
- **D-07:** The mounted admin shell should always show current tenant scope when tenancy is enabled. If exactly one tenant is allowed, render a read-only tenant chip rather than a switcher.
- **D-08:** Tenant and environment remain separate visible selectors and separate URL params, e.g. `?tenant=acme&env=prod`.
- **D-09:** Phase 29 must not ship an implicit or default “all tenants” mode for mounted admin. Any future cross-tenant read surface would require explicit later-phase design.

### Validation strictness for compare, import, and promotion
- **D-10:** Tenant safety should never be a warning class in Phase 29. Tenant scope outcomes are only `allow`, `blocked`, or `stale`.
- **D-11:** Preview should classify unsafe tenant scope combinations semantically while still allowing the operator or CI to inspect the blocked result.
- **D-12:** Apply paths must accept only the exact reviewed tenant scope captured in the saved plan or compare artifact. Revalidation happens at mutation time and must fail closed on drift.
- **D-13:** The tenant-scope ruleset is:
  - `nil -> nil` is allowed
  - `nil -> tenant_a` is allowed because it narrows scope
  - `tenant_a -> tenant_a` is allowed
  - `tenant_a -> nil` is a blocker (`widened_tenant_scope`)
  - `tenant_a -> tenant_b` is a blocker (`mismatched_tenant_scope`)
  - any saved reviewed scope that no longer matches live/apply scope is stale (`tenant_scope_drifted`)
- **D-14:** Protected-target governance and scheduling flows must not bypass tenant blockers or stale tenant drift checks.
- **D-15:** Phase 29 must not ship a tenant force/override mode for compare, import, or promotion.
- **D-16:** Compare, import, promotion, admin UI, and future CLI should share one stable tenant finding vocabulary:
  - `widened_tenant_scope`
  - `mismatched_tenant_scope`
  - `tenant_scope_drifted`

### Audit and saved-plan tenant metadata
- **D-17:** Persist stable tenant scope identity plus validation provenance, but do not persist tenant labels, names, catalog snapshots, or other tenant-owned descriptive state in durable artifacts.
- **D-18:** Saved plans should keep the existing top-level `tenant_key` for compatibility and artifact stability, then add bounded provenance fields for how tenant scope was resolved and validated.
- **D-19:** Audit metadata should carry the same bounded tenant scope shape used by saved plans so apply/review/audit surfaces stay explainable without inventing multiple metadata dialects.
- **D-20:** The canonical tenant metadata shape is:
  - `tenant_key`
  - `scope_source` (`explicit`, `host_resolved`, or `single_tenant`)
  - bounded validation evidence (`same_tenant_guard`, `single_tenant`, or `not_applicable`, with `passed` or `bypassed`)
- **D-21:** Freeform typed confirmation text must not become durable tenant truth. If an explicit confirmation affordance is ever needed for high-impact flows, persist only a bounded boolean or enum that confirmation occurred.

### Bucketing semantics
- **D-22:** Rulestead keeps bucketing semantics explicit at the public seam and must not silently reinterpret existing bucket behavior when tenancy is enabled.
- **D-23:** Core defaults remain unchanged:
  - `bucket_by: :subject` means actor-only
  - `bucket_by: :tenant` means tenant-only
  - `Rulestead.Tenancy.compose_bucket_identity/3` is a no-op by default, including `SingleTenant`
- **D-24:** The blessed host opt-in for multi-tenant B2B rollouts is `tenant_scoped_subject`: compose `tenant_key <> ":" <> targeting_key` for `:subject` only.
- **D-25:** Tenant-wide consistency should use `bucket_by: :tenant`. Per-user rollout inside a tenant should use explicit tenant-scoped subject composition when the host wants tenant-local subject identity.
- **D-26:** Phase 29 must not add more bucket enums or hidden fallback chains. Configurability stays behind the existing explicit tenancy callback seam.
- **D-27:** Downstream docs and planning must call out that enabling tenant-scoped subject composition rebuckets existing `:subject` rules and therefore changes cohort assignment.

### Recommendation-first downstream posture
- **D-28:** For this repo and this phase, downstream research and planning should default to **recommendation-first execution** rather than re-asking the user about ordinary implementation tradeoffs.
- **D-29:** Re-open a decision only when it materially changes milestone scope, public contract, security posture, or release shape. Normal implementation choices should come back with one coherent default path.

### Claude's Discretion
- Exact session key names and resolver helper names for available tenants, provided host ownership and fail-closed checks remain explicit
- Exact UI composition for tenant chip/picker placement, provided tenant stays visible and separate from environment
- Exact encoding of tenant validation provenance in plans and audit metadata, provided the bounded shape and semantics remain stable
- Exact helper/module names for tenant-scope classifiers and same-tenant guards, provided one shared validator model is reused across compare/import/promotion
- Exact implementation of tenant-scoped subject composition, provided it remains explicit, documented, and opt-in

### Deferred Ideas (OUT OF SCOPE)
- Cross-tenant dashboards or global “all tenants” operator views
- Tenant-partitioned authored storage, runtime snapshot tables, or environment trees
- Tenant labels or catalog snapshots embedded in plans or audit events
- Tenant override / force-apply modes for compare, import, or promotion
- Additional bucket enums or hidden fallback chains beyond explicit `:tenant` and opt-in tenant-scoped subject composition
- Broad tenant lifecycle management or tenant catalog ownership inside Rulestead
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-01 | Runtime and admin flows support explicit tenant scope without requiring environment-per-tenant or cloned flag topology. [VERIFIED: .planning/REQUIREMENTS.md] | `29-01` should keep tenant scope inside `Rulestead.Tenancy`, `Rulestead.Phoenix`, `Rulestead.LiveView`, and evaluator bucketing hooks; `29-02` should mirror `Live.Session.resolve/3` for admin tenant state instead of inventing a second scope model. [VERIFIED: rulestead/lib/rulestead/tenancy.ex] [VERIFIED: rulestead/lib/rulestead/phoenix.ex] [VERIFIED: rulestead/lib/rulestead/live_view.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| TEN-02 | Promotion and import validation detect tenant-sensitive dependency, scoping, or targeting issues before apply. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing preview-first compare/import/apply contract, extend the finding vocabulary to `widened_tenant_scope`, `mismatched_tenant_scope`, and `tenant_scope_drifted`, and require apply-time revalidation. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] [VERIFIED: rulestead/lib/rulestead.ex] |
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `SingleTenant` as the default config, restrict new behavior to additive seam callbacks and bounded metadata, and expand tests around audit metadata normalization plus bucket identity semantics. [VERIFIED: rulestead/lib/rulestead/config.ex] [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex] [VERIFIED: rulestead/lib/rulestead/evaluator.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] |
</phase_requirements>

## Summary

Phase 29 does not need new topology, new storage partitions, or a new admin product surface; the repo already has the right extension points for a bounded tenancy seam. `Rulestead.Tenancy` already exists, `SingleTenant` is already the default host config, `%Rulestead.Context{}` already carries `tenant_key`, and both import and promotion already revalidate reviewed artifacts before mutation. [VERIFIED: rulestead/lib/rulestead/tenancy.ex] [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex] [VERIFIED: rulestead/lib/rulestead/config.ex] [VERIFIED: rulestead/lib/rulestead/context.ex] [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]

The planning implication is that `29-01` should stay entirely inside the runtime/config seam and public bucketing contract, while `29-02` should own the shared validation classifier, bounded saved-plan/audit metadata, and the mounted-admin tenant session/picker flow. That split matches the roadmap’s two plans, the old Phase 25 validation split, and the current code boundaries. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-VALIDATION.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex]

**Primary recommendation:** Plan Phase 29 as a seam-tightening phase: preserve `tenant_key` compatibility, add bounded provenance metadata, reuse preview/apply revalidation, and make tenant selection explicit only where the mounted admin already exposes environment selection. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex]

## Recommended Plan Split

1. **`29-01-PLAN.md — Tenancy Seam, SingleTenant Default, and Bucketing Hooks`** should cover only config/release-contract hardening, seam helper normalization, and evaluator-facing bucket composition behavior. It should not touch compare/import/promotion saved-plan formats or mounted-admin session state beyond whatever tests are needed to preserve existing adapters. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: rulestead/lib/rulestead/config.ex] [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
2. **`29-02-PLAN.md — Tenant-aware Validation, Audit Metadata, and Admin Scope`** should cover one shared tenant-scope classifier reused by import, promotion compare/apply, saved-plan serialization, audit metadata normalization, and mounted-admin tenant resolution/display. It should also own compare-page tenant carry-through and tenant visibility in shell chrome. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex]
3. **Do not invert the split.** If tenant metadata fields are added in `29-01`, `29-01` will become coupled to admin and apply semantics; if mounted-admin session state is added before the validator vocabulary is shared, `29-02` will have to rework URLs and stale checks twice. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-VALIDATION.md] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Runtime tenant resolution and bucket identity composition | API / Backend | Frontend Server (SSR/LiveView) | Tenant scope is normalized inside `Rulestead.Phoenix`, `Rulestead.LiveView`, and `Rulestead.Evaluator`; the browser should never invent rollout identity on its own. [VERIFIED: rulestead/lib/rulestead/phoenix.ex] [VERIFIED: rulestead/lib/rulestead/live_view.ex] [VERIFIED: rulestead/lib/rulestead/evaluator.ex] |
| Import and promotion tenant validation | API / Backend | Database / Storage | Preview and apply checks already live in import/promotion modules and saved-plan payloads, with storage adapters enforcing the mutation path after validation. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] |
| Saved-plan and audit tenant provenance | API / Backend | Database / Storage | The metadata dialect should be normalized before persistence in `Manifest.Plan` and `AuditEvent.metadata/1`, then stored as bounded maps. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] |
| Mounted-admin tenant selection and visibility | Frontend Server (SSR/LiveView) | API / Backend | The existing admin shell and session resolver already own visible environment scope and route generation; tenant scope should mirror that server-side resolution pattern and then call backend APIs with explicit `tenant_key`. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout and do not collapse work into a single package shape. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: CLAUDE.md]
- Do not introduce early publish flows that bypass the guarded `rulestead_admin` stub rule. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes and scripts-first CI surfaces when workflow logic gets non-trivial. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version`] | Runtime, ExUnit, and Mix task surface for both sibling packages. [VERIFIED: `elixir --version`] | The repo targets `~> 1.17` in both packages and the local environment already runs 1.19.5, so planning should assume standard Elixir-first implementation and test workflows. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead_admin/mix.exs] [VERIFIED: `elixir --version`] |
| `nimble_options` | 1.1.1 [VERIFIED: rulestead/mix.lock] | Validated host config seam for `:tenancy`, Plug, LiveView, Oban, and runtime options. [VERIFIED: rulestead/lib/rulestead/config.ex] | Phase 29 should extend the existing config contract instead of adding ad hoc env/session parsing logic. [VERIFIED: rulestead/lib/rulestead/config.ex] |
| `ecto` / `ecto_sql` | 3.13.5 [VERIFIED: rulestead/mix.lock] | Audit event schema, persisted environment versions, and Ecto-backed contract parity. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] [VERIFIED: rulestead/lib/rulestead/environment_version.ex] | Tenant metadata and saved-plan parity already rely on Ecto-backed behavior, so the plan should test Fake and Ecto adapters against the same contract. [VERIFIED: rulestead/test/rulestead/store/manifest_import_contract_test.exs] [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] |
| `phoenix` | 1.8.5 [VERIFIED: rulestead_admin/mix.lock] | Mounted admin router/session integration and `Phoenix.ConnTest` support. [VERIFIED: rulestead_admin/test/support/conn_case.ex] | Tenant scope in admin must stay host-mounted and URL/session-driven, which is already how the package integrates with Phoenix. [VERIFIED: prompts/rulestead-host-app-integration-seam.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| `phoenix_live_view` | 1.1.28 [VERIFIED: rulestead_admin/mix.lock] | `on_mount` session resolution, route-backed current state, and compare/admin page rendering. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex] | Phase 29 admin work should use the existing LiveView mount/session model rather than separate APIs or client-side tenant state. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `stream_data` | 1.3.0 [VERIFIED: rulestead/mix.lock] | Property tests for bucket identity and tenancy invariants. [VERIFIED: rulestead/test/rulestead/tenancy_property_test.exs] [VERIFIED: rulestead/test/rulestead/evaluator_property_test.exs] | Use for rebucketing safety and “same input, same identity” guarantees in `29-01`. [VERIFIED: rulestead/test/rulestead/evaluator_property_test.exs] |
| `phoenix_html` | 4.3.0 [VERIFIED: rulestead_admin/mix.lock] | Admin rendering support for visible environment/tenant scope chrome. [VERIFIED: rulestead_admin/mix.lock] | Use only through existing LiveView components such as `Shell.page/1`; do not introduce separate client widget machinery. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex] |
| `a11y_audit` | 0.3.3 [VERIFIED: rulestead_admin/mix.lock] | Accessibility assertions for mounted admin screens. [VERIFIED: rulestead_admin/mix.lock] | Extend when the tenant chip/picker is added so the visible scope UI keeps the same accessibility bar as existing compare/admin screens. [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/accessibility_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `Rulestead.Tenancy` seam | New tenant service or process-global resolver | This would widen scope into topology and hidden state the milestone explicitly rejects. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/tenancy.ex] |
| Existing `Live.Session.resolve/3` pattern | Client-side tenant state or freeform URL authority | That would bypass host-owned authorization and create cross-tenant leakage risk. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| Existing import/promotion preview-first path | Separate tenant-only validation engine | A second engine would drift from compare/apply semantics that already detect staleness and blocker findings. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] |

**Installation:**
```bash
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```

**Version verification:** Use the locked project stack for planning. No new third-party dependency is required for Phase 29; the existing versions above were verified from `mix.lock` and the local toolchain. [VERIFIED: rulestead/mix.lock] [VERIFIED: rulestead_admin/mix.lock] [VERIFIED: `elixir --version`]

## Architecture Patterns

### System Architecture Diagram

```text
Host session / URL params
  -> Mounted admin session resolver (`env`, `tenant`)
    -> visible shell scope chrome
      -> compare/import/promote preview request with explicit `tenant_key`
        -> shared tenant-scope classifier
          -> saved plan / compare artifact (`tenant_key` + provenance)
            -> apply-time revalidation
              -> bounded audit metadata + store command

Host request / socket / job context
  -> `Rulestead.Phoenix` / `Rulestead.LiveView` / Oban context builder
    -> `%Rulestead.Context{tenant_key: ...}`
      -> `Rulestead.Evaluator.resolve_bucket_identity/2`
        -> `Rulestead.Tenancy.compose_bucket_identity/3`
          -> deterministic rollout / experiment decision
```

### Recommended Project Structure
```text
rulestead/lib/rulestead/
├── tenancy.ex                  # bounded seam entrypoint
├── tenancy/                    # default implementation(s)
├── phoenix.ex                  # request-context projection
├── live_view.ex                # LiveView-context projection
├── evaluator.ex                # explicit bucket identity resolution
├── manifest/                   # import preview, saved-plan serialization
├── promotion/                  # compare/apply revalidation
└── audit_event.ex              # bounded audit metadata normalization

rulestead_admin/lib/rulestead_admin/
├── live/session.ex             # mounted env+tenant resolution
├── components/shell.ex         # visible scope display
└── live/environment_compare_live/
   └── index.ex                 # compare flow that carries explicit scope
```

### Pattern 1: Host-Owned Tenant Resolution with Fail-Closed Fallbacks
**What:** Resolve tenant scope the same way admin environment scope already resolves: URL first if allowed, remembered state second if allowed, then host default, otherwise fail closed. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
**When to use:** `29-02` for mounted admin session state, compare URLs, and any future mounted pages that already depend on `Live.Session`. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
**Example:**
```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/session.ex
{tenant, tenant_source} =
  cond do
    selected = find_allowed_tenant(tenants, url_tenant) -> {selected, :url}
    selected = find_allowed_tenant(tenants, remembered_tenant) -> {selected, :remembered}
    selected = default_tenant(tenants, host_default_tenant) -> {selected, :default}
    true -> :error
  end
```

### Pattern 2: Preview-First Tenant Validation Reused by Import and Promotion
**What:** Classify tenant scope during preview, persist only the reviewed scope/provenance, and reject apply when the live scope no longer matches the reviewed artifact. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] [VERIFIED: rulestead/lib/rulestead.ex]
**When to use:** `29-02` for import plan/apply, compare/apply, governed apply, and any CLI path that consumes saved plan artifacts. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/manifest/import.ex
cond do
  source_tenant == tenant_key -> []
  is_nil(source_tenant) and not is_nil(tenant_key) -> []
  not is_nil(source_tenant) and is_nil(tenant_key) ->
    [Result.finding("widened_tenant_scope", "blocker", env, message: "...")]
  true ->
    [Result.finding("mismatched_tenant_scope", "blocker", env, message: "...")]
end
```

### Pattern 3: Bucket Identity Composition Stays Explicit at the Evaluator Edge
**What:** Keep the default identity contract unchanged, then let the tenancy callback optionally compose a different identity for the same `bucket_by` input. [VERIFIED: rulestead/lib/rulestead/evaluator.ex] [VERIFIED: rulestead/lib/rulestead/tenancy.ex]
**When to use:** `29-01` for tenant-scoped subject rollout support and rebucketing property tests. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/evaluator.ex
default_identity =
  case bucket_by do
    :subject -> context.targeting_key
    :tenant -> context.tenant_key
    _ -> context.targeting_key
  end

Rulestead.Tenancy.compose_bucket_identity(context, bucket_by, default_identity)
```

### Anti-Patterns to Avoid
- **Ambient tenant authority:** Do not treat session memory or an unvalidated URL param as sufficient tenant authority for admin reads or writes. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]
- **A second validation engine:** Do not create tenant-only apply logic outside compare/import/promotion preview flows. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]
- **Durable tenant labels or catalogs in artifacts:** Persist `tenant_key` and bounded provenance only. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
- **Silent rebucketing:** Any tenant-scoped subject composition must be documented and regression-tested because it changes cohorts for existing `bucket_by: :subject` rules. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/evaluator.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tenant resolution in admin | Ad hoc page-local param parsing | `RulesteadAdmin.Live.Session.resolve/3` extended with tenant inputs | The environment resolver already owns URL, remembered, and default fallback semantics for mounted admin. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] |
| Bucket rebinding | New rollout enums or hidden fallback chains | `Rulestead.Tenancy.compose_bucket_identity/3` behind existing `bucket_by` values | The evaluator already centralizes identity selection and tenancy composition. [VERIFIED: rulestead/lib/rulestead/evaluator.ex] [VERIFIED: rulestead/lib/rulestead/tenancy.ex] |
| Tenant preview/apply semantics | Separate tenant validator service | Shared classifier reused by import and promotion flows | Current preview/apply paths already sort findings, detect stale artifacts, and fail closed on blockers. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] |
| Audit payload capture | Raw session/socket serialization | `Rulestead.AuditEvent.metadata/1` with bounded context keys | The audit layer already drops sensitive context keys and normalizes maps. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] |
| Host tenant catalog management | Library-owned tenant storage/UI | Host-provided allowed tenant list in mounted session | The phase context explicitly requires host ownership of tenant catalog and defaults. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |

**Key insight:** Phase 29 should compose through already-shipped seams; every custom tenant side-channel would create a second source of truth and widen the product beyond the linked two-package model. [VERIFIED: .planning/PROJECT.md] [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Collapsing Environment and Tenant into One Scope
**What goes wrong:** URLs, audit trails, and operator reasoning become ambiguous, and authorization starts drifting because the same selector is doing two jobs. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Why it happens:** The admin already has environment routing, so tenant work can look like “just add another env-like string” without keeping the axes separate. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]
**How to avoid:** Keep `env` and `tenant` as separate params, separate assigns, and separate visible controls. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Warning signs:** Helper names or structs that expose a single combined “scope” string. [ASSUMED]

### Pitfall 2: Letting Preview and Apply Drift on Tenant Rules
**What goes wrong:** A preview can look valid while apply mutates a broader or different tenant scope. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead.ex]
**Why it happens:** Import and promotion already have stale checks, so it is easy to add a preview finding but forget exact-scope revalidation on apply. [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]
**How to avoid:** Serialize reviewed tenant provenance into the plan artifact and revalidate it on every apply path, including governed paths. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Warning signs:** A new tenant finding exists in compare/import preview but there is no apply test asserting a stale result when `tenant_key` changes. [VERIFIED: rulestead/test/rulestead/manifest/import_test.exs] [VERIFIED: rulestead/test/rulestead/promotion/apply_test.exs]

### Pitfall 3: Shipping Tenant-Scoped Subject Composition Without Calling Out Rebucketing
**What goes wrong:** Existing `bucket_by: :subject` rules silently reassign cohorts when a host switches to tenant-local subject identity. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Why it happens:** The hook is intentionally small and lives in the evaluator seam, so the cohort effect can be easy to miss. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**How to avoid:** Keep the default no-op, make tenant-scoped subject opt-in only, and add property tests/documentation that show cohort changes are expected when enabled. [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex] [VERIFIED: rulestead/test/rulestead/evaluator_property_test.exs]
**Warning signs:** A host-config flag changes bucketing behavior without new evaluator property coverage. [VERIFIED: rulestead/test/rulestead/evaluator_property_test.exs]

### Pitfall 4: Persisting Tenant Catalog Noise Into Plans or Audit Events
**What goes wrong:** Saved artifacts become unstable, privacy risk increases, and replays depend on data that should remain host-owned. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]
**Why it happens:** UI work often wants labels and display state that do not belong in durable apply or audit facts. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/shell.ex]
**How to avoid:** Persist only `tenant_key`, `scope_source`, and bounded validation evidence. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
**Warning signs:** Plans or audit metadata start storing tenant names, option lists, or arbitrary confirmation text. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]

## Code Examples

Verified patterns from the current repo:

### Runtime Resolver Prefers Explicit Tenant but Falls Back to the Tenancy Seam
```elixir
# Source: rulestead/lib/rulestead/phoenix.ex
defp resolve_tenant_key(host, opts, resolver) do
  explicit = resolve_opt(host, opts, :tenant_key, resolver)

  if explicit do
    explicit
  else
    Rulestead.Tenancy.resolve_tenant(host)
  end
end
```

### Evaluator Keeps `bucket_by` Explicit and Delegates Composition
```elixir
# Source: rulestead/lib/rulestead/evaluator.ex
default_identity =
  case bucket_by do
    b when b in [:subject, "subject"] -> context.targeting_key
    b when b in [:tenant, "tenant"] -> context.tenant_key
    b when b in [:session, "session"] -> context.session_id
    _ -> context.targeting_key
  end

identity = Rulestead.Tenancy.compose_bucket_identity(context, bucket_by, default_identity)
```

### Saved Plan Already Preserves Top-Level `tenant_key`
```elixir
# Source: rulestead/lib/rulestead/manifest/plan.ex
plan_seed =
  %{
    "mode" => "import",
    "target_environment_key" => target_environment_key,
    "target_fingerprint" => target_fingerprint
  }
  |> maybe_put("source_environment_key", source_environment_key)
  |> maybe_put("tenant_key", tenant_key)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 25 treated tenant work as a broad seam/validation bucket without the newer admin picker and provenance detail decisions. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] | Phase 29 locks an explicit host-bounded admin picker, exact-scope apply revalidation, and bounded provenance metadata. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | 2026-05-21 milestone reframing. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | Plans should now encode the exact two-slice split and avoid re-opening baseline tenancy product-shape questions. [VERIFIED: .planning/ROADMAP.md] |
| Current saved plans carry `tenant_key` only. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] | Recommended Phase 29 contract is `tenant_key` plus bounded `scope_source` and validation evidence for replay/audit explainability. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | Phase 29 planning target. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | `29-02` should add fields compatibly rather than replacing the existing key. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |
| Current import and promotion drift errors use freeform stale messages for tenant changes. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead.ex] | Recommended Phase 29 contract is one shared tenant finding vocabulary: `widened_tenant_scope`, `mismatched_tenant_scope`, and `tenant_scope_drifted`. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | Phase 29 planning target. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] | The shared classifier should drive preview, apply, CLI, and admin wording from one place. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |

**Deprecated/outdated:**
- Treating tenant safety as warning-only would contradict the current locked decisions for Phase 29. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
- Any plan that prepares `rulestead_admin` for standalone publication is outside the active project constraints. [VERIFIED: CLAUDE.md] [VERIFIED: AGENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Helper names such as `find_allowed_tenant/2` or `default_tenant/2` are placeholders; the exact names remain discretionary. [ASSUMED] | Architecture Patterns | Low; planner can rename tasks without changing the milestone shape. |
| A2 | A combined “scope” string would be a warning sign for env/tenant collapse. [ASSUMED] | Common Pitfalls | Low; the real risk is architectural, not naming-specific. |

## Open Questions

1. **Should admin tenant links preserve remembered tenant state beyond the URL param?**
   - What we know: Environment links are already URL-canonical and remembered-env-aware, and the Phase 29 context wants tenant resolution to mirror that shape. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
   - What's unclear: Whether the host wants a separate remembered tenant session key or wants URL-only stickiness. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
   - Recommendation: Plan for a remembered tenant session key in `29-02`, but keep the key name and persistence detail implementation-discretionary. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All build, test, and Mix-task work | ✓ [VERIFIED: `command -v elixir`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | All package tests and task verification | ✓ [VERIFIED: `command -v mix`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL CLI | Ecto-backed contract and parity tests | ✓ [VERIFIED: `command -v psql`] | 14.17 [VERIFIED: `psql --version`] | Fake-store tests cover most backend validation if DB-backed parity needs to be deferred locally. [VERIFIED: rulestead/test/test_helper.exs] |
| Redis server | Redis adapter/integration coverage only | ✓ [VERIFIED: `command -v redis-server`] | 7.2.4 [VERIFIED: `redis-server --version`] | Not required for the primary Phase 29 tenancy seams. [VERIFIED: rulestead/test/rulestead/redis/integration_test.exs] |
| Docker | Compose-backed host-app smoke and demo flows | ✓ [VERIFIED: `command -v docker`] | 29.4.1 [VERIFIED: `docker --version`] | Not required for the narrow Phase 29 plan/test loop. [VERIFIED: .planning/PROJECT.md] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: command availability checks]

**Missing dependencies with fallback:**
- None. [VERIFIED: command availability checks]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5, plus `Phoenix.ConnTest`, `Phoenix.LiveViewTest`, and `StreamData` where needed. [VERIFIED: `elixir --version`] [VERIFIED: rulestead_admin/test/support/conn_case.ex] [VERIFIED: rulestead/test/rulestead/evaluator_property_test.exs] |
| Config file | none — each package uses `test/test_helper.exs`. [VERIFIED: rulestead/test/test_helper.exs] [VERIFIED: rulestead_admin/test/test_helper.exs] |
| Quick run command | `cd rulestead && mix test test/rulestead/tenancy_test.exs test/rulestead/tenancy_property_test.exs test/rulestead/evaluator_test.exs test/rulestead/evaluator_property_test.exs test/rulestead/config_test.exs` [VERIFIED: test file existence] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: package structure] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEN-01 | Explicit tenant scope in runtime helpers and mounted admin session flow. [VERIFIED: .planning/REQUIREMENTS.md] | unit + LiveView integration | `cd rulestead && mix test test/rulestead/tenancy_test.exs test/rulestead/plug_test.exs test/rulestead/live_view_test.exs test/rulestead/oban_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs` [VERIFIED: test file existence] | ✅ existing files, but tenant-admin cases need expansion. [VERIFIED: test file existence] |
| TEN-02 | Import/promotion preview and apply reject mismatched or drifted tenant scope. [VERIFIED: .planning/REQUIREMENTS.md] | unit + adapter contract | `cd rulestead && mix test test/rulestead/manifest/import_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/promotion/compare_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs` [VERIFIED: test file existence] | ✅ existing files, but shared tenant classifier coverage is missing. [VERIFIED: test file existence] |
| TEN-03 | Minimal seam keeps `SingleTenant` default, explicit bucketing hooks, and bounded tenant audit metadata. [VERIFIED: .planning/REQUIREMENTS.md] | unit + property + contract | `cd rulestead && mix test test/rulestead/config_test.exs test/rulestead/tenancy_test.exs test/rulestead/tenancy_property_test.exs test/rulestead/evaluator_property_test.exs test/rulestead/audit_event_governance_test.exs test/rulestead/release_contract_test.exs` [VERIFIED: test file existence] | ✅ existing files, but audit provenance assertions need expansion. [VERIFIED: test file existence] |

### Sampling Rate
- **Per task commit:** Run the quick targeted package tests for the plan being edited. [VERIFIED: test file existence]
- **Per wave merge:** Run both package targeted suites covering runtime + admin seams. [VERIFIED: package structure]
- **Phase gate:** `cd rulestead && mix test && cd ../rulestead_admin && mix test`. [VERIFIED: package structure]

### Wave 0 Gaps
- [ ] `rulestead/test/rulestead/audit_event_governance_test.exs` — add bounded tenant provenance assertions for saved-plan/audit metadata parity. [VERIFIED: rulestead/test/rulestead/audit_event_governance_test.exs]
- [ ] `rulestead/test/rulestead/promotion/compare_test.exs` — add shared classifier assertions for `tenant_scope_drifted` and blocker vocabulary parity. [VERIFIED: rulestead/test/rulestead/promotion/compare_test.exs]
- [ ] `rulestead_admin/test/rulestead_admin/live/session_test.exs` — add tenant URL/remembered/default/fail-closed cases and visible shell chrome assertions. [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs]
- [ ] `rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs` — assert compare page carries `tenant` through route generation and summary copy. [VERIFIED: rulestead_admin/test/rulestead_admin/live/environment_compare_live/index_test.exs]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: prompts/rulestead-host-app-integration-seam.md] | Host app owns identity; Phase 29 should not add a new auth surface. [VERIFIED: prompts/rulestead-host-app-integration-seam.md] |
| V3 Session Management | yes [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] | Mounted admin must keep tenant selection inside host-bounded session inputs and fail closed on invalid scope. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |
| V4 Access Control | yes [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] | Keep tenant and environment separate in policy evaluation and never allow implicit all-tenant mutation. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: rulestead/lib/rulestead/config.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] | Normalize strings, validate config through `NimbleOptions`, and use shared tenant-scope classifiers for preview/apply inputs. [VERIFIED: rulestead/lib/rulestead/config.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] |
| V6 Cryptography | no [VERIFIED: codebase grep] | Phase 29 does not add new cryptographic requirements. [VERIFIED: codebase grep] |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Invalid URL/session tenant broadens mounted-admin scope | Elevation of privilege | Resolve tenant only against the host-provided allowed set and redirect/fail closed when invalid. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] |
| Reviewed artifact replay mutates a different tenant than the one previewed | Tampering | Persist reviewed tenant provenance and revalidate exact scope on apply. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex] [VERIFIED: rulestead/lib/rulestead.ex] |
| Audit or plan artifacts leak tenant-owned descriptive state | Information disclosure | Persist only bounded tenant identity/provenance and keep catalog labels in host/UI state only. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md] [VERIFIED: rulestead/lib/rulestead/audit_event.ex] |
| Host enables tenant-scoped subject composition without noticing rebucketing | Tampering | Keep default no-op behavior, document cohort changes, and add property tests around identity composition. [VERIFIED: rulestead/lib/rulestead/tenancy/single_tenant.ex] [VERIFIED: rulestead/test/rulestead/tenancy_property_test.exs] |

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - active Phase 29 goal, two-plan split, and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `TEN-01` through `TEN-03`. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/PROJECT.md` and `.planning/STATE.md` - current milestone framing and active boundary. [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/STATE.md]
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` - locked decisions, discretion, canonical references, and non-goals. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
- `.planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md` and `25-VALIDATION.md` - prior split and verification posture. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-VALIDATION.md]
- Prompt anchors in `prompts/` - engineering DNA, host-app seam, admin UX, security/privacy, domain language, and testing posture. [VERIFIED: prompts/rulestead-engineering-dna-from-prior-libs.md] [VERIFIED: prompts/rulestead-host-app-integration-seam.md] [VERIFIED: prompts/rulestead-admin-ux-and-operator-ia.md] [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] [VERIFIED: prompts/rulestead-domain-language-field-guide.md] [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- Current code seams and tests under `rulestead/lib`, `rulestead_admin/lib`, `rulestead/test`, and `rulestead_admin/test`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- `.planning/research/V0_6_ARCHITECTURE.md` and `.planning/research/V0_6_DX.md` - prior milestone architecture and DX recommendations that still align with the locked Phase 29 posture. [VERIFIED: .planning/research/V0_6_ARCHITECTURE.md] [VERIFIED: .planning/research/V0_6_DX.md]

### Tertiary (LOW confidence)
- None. [VERIFIED: source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependency is required and the relevant package/runtime versions were verified from `mix.lock` and local tool versions. [VERIFIED: rulestead/mix.lock] [VERIFIED: rulestead_admin/mix.lock] [VERIFIED: `elixir --version`]
- Architecture: HIGH - the required seams already exist in code and the Phase 29 decisions narrow the allowed solution space sharply. [VERIFIED: rulestead/lib/rulestead/tenancy.ex] [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex] [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md]
- Pitfalls: MEDIUM-HIGH - most are directly evidenced by current seams and locked non-goals, but some warning-sign phrasing is inferential rather than already encoded in code. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-05-21 [VERIFIED: system date]
**Valid until:** 2026-06-20 for repo-local planning; revisit earlier if the Phase 29 context or roadmap changes. [ASSUMED]

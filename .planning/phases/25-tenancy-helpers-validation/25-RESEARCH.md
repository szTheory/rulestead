# Phase 25: Tenancy Helpers & Validation - Research

**Researched:** 2026-05-19 [VERIFIED: codebase + repo metadata]
**Domain:** Elixir/Phoenix tenancy seam design for runtime scoping, deterministic bucketing, preview/apply validation, and mounted-admin scope handling. [VERIFIED: .planning/ROADMAP.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase inspection + Hex package registry]

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md`. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]

### Locked Decisions
- **D-01:** Phase 25 must preserve the linked-version, sibling-package release model and must not widen `rulestead_admin` into a separately publishable tenancy product.
- **D-02:** Tenancy remains a helper seam layered on top of the existing environment model, not a second primary topology. Environment and tenant stay separate axes.
- **D-03:** This phase should default to recommendation-first downstream planning. Re-open decisions only when they materially change public contract, security posture, or milestone scope.
- **D-04:** Add a small `Rulestead.Tenancy` seam with a `SingleTenant` default implementation rather than baking tenant assumptions into process state or adapter internals.
- **D-05:** The seam should stay bounded to explicit helpers such as tenant resolution, scope application, bucketing composition, topic partitioning, and same-tenant guards. Do not introduce full tenant lifecycle management.
- **D-06:** Tenant scope must remain explicit in request/runtime/admin/apply flows where it matters. Do not infer mutating tenant scope from hidden defaults.
- **D-07:** Existing `%Rulestead.Context{}` tenant input remains the canonical evaluation tenant field; Phase 25 builds on it instead of replacing the context model.
- **D-08:** Tenant-aware bucketing should be additive and composable so hosts can keep per-actor behavior or opt into tenant-stable rollout behavior without changing flag topology.
- **D-09:** Promotion and manifest import paths must reject tenant-sensitive invalid states before apply, using the existing preview-first and stale-check posture from Phases 22 through 24.
- **D-10:** Saved plan/apply artifacts and audit metadata should carry bounded tenant scope information when relevant, but must not serialize broad tenant-owned state or hidden runtime baggage.
- **D-11:** Tenant scope must be visible in operator-facing admin or automation flows when tenancy is enabled, but this phase should only add the minimum mounted-admin seams needed for safety and validation.
- **D-12:** Cross-tenant leakage is a first-class failure mode. Query/guard helpers and tests should bias toward explicit scope checks and fail-closed behavior.
- **D-13:** Single-tenant hosts must remain the default ergonomic path; tenancy-enabled behavior should compose cleanly without forcing every adopter into multi-tenant complexity.

### Claude's Discretion
No explicit `Claude's Discretion` section appears in `25-CONTEXT.md`; downstream planning should therefore treat the locked decisions above plus the roadmap plan split as the controlling boundary. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; .planning/ROADMAP.md]

### Deferred Ideas (OUT OF SCOPE)
- Full tenant-partitioned authoring/storage
- Tenant-specific manifest inheritance or reconciliation
- Cross-tenant fleet dashboards
- Broad tenancy middleware beyond the minimal host seam and bounded context propagation
- Any change that would prepare `rulestead_admin` for standalone publication
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-01 | Runtime and admin flows support an explicit `tenant_key` / tenant scope without requiring environment-per-tenant or cloned flag topology. | Use `%Rulestead.Context{tenant_key: ...}` as the canonical field, add a minimal `Rulestead.Tenancy` seam, extend explicit Plug/LiveView/Oban/admin-session helpers, and keep tenant state visible in route/session/query metadata rather than storage topology. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex; rulestead_admin/lib/rulestead_admin/live/session.ex] |
| TEN-02 | Promotion and import validation detect tenant-sensitive dependency or targeting issues before apply. | Reuse `Rulestead.Promotion.Compare`, `Rulestead.Manifest.Import`, `Rulestead.Manifest.Plan`, and store command validation to surface tenant-sensitive findings in preview and reject stale/mismatched tenant scope at apply time. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/store/command.ex] |
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. | Keep the seam internal-to-core, wire it through evaluator bucket identity composition and bounded metadata envelopes already used by audit events and environment/apply plans. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/environment_version.ex; rulestead/lib/rulestead/store/ecto.ex] |
</phase_requirements>

## Summary

Phase 25 should add one new core seam and reuse nearly everything else. The codebase already has the canonical `tenant_key` field in `%Rulestead.Context{}`, explicit Plug/LiveView/Oban projection helpers, mounted-admin environment session helpers, and preview/apply contracts for compare, import, and promotion. What is missing is a single place to normalize tenant behavior and a tenant-aware extension of the existing preview/audit metadata contracts. [VERIFIED: rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex; rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex]

The most important implementation detail is that tenant awareness should enter the system as explicit scope and identity composition, not as new tables, partition keys, or per-tenant manifest trees. The evaluator already supports `bucket_by: :tenant`, but the current hot path still hashes raw `targeting_key` or `tenant_key` directly. Phase 25 should insert a `Rulestead.Tenancy` helper between context projection and bucket hashing so multi-tenant hosts can prevent cross-tenant bucket collisions while keeping single-tenant hosts on a no-op default. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/ruleset/rollout.ex; rulestead/lib/rulestead/ruleset/experiment.ex]

The second implementation detail is that compare/import/apply already have the right shape for tenant validation. `Compare.compare_token/1`, `Manifest.Plan`, `Manifest.Import.apply/2`, `ApplyManifestImport`, `ApplyPromotion`, `EnvironmentVersion`, and `AuditEvent.metadata/1` are all bounded metadata seams. Phase 25 should extend those seams with explicit tenant scope markers and same-tenant guards rather than inventing a second tenancy workflow model. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store/command.ex; rulestead/lib/rulestead/environment_version.ex; rulestead/lib/rulestead/audit_event.ex]

**Primary recommendation:** implement `25-01` as an internal `Rulestead.Tenancy` behaviour plus `SingleTenant` default wired into evaluator/config/projection helpers, then implement `25-02` by extending the existing compare/import/promotion plan metadata, audit envelopes, and mounted-admin session/query helpers with explicit tenant scope and fail-closed same-tenant validation. [VERIFIED: .planning/ROADMAP.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/config.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tenant resolution and normalization for runtime contexts | API / Backend | Frontend Server (SSR) | `%Rulestead.Context{}` is the canonical tenant carrier, and Plug/LiveView/Oban helpers already project host state into that struct on the server side. [VERIFIED: rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex] |
| Tenant-aware bucket identity composition | API / Backend | — | Bucket identity is resolved inside `Rulestead.Evaluator`, and rollout/experiment schemas already enumerate `:tenant` as a legal `bucket_by` value. [VERIFIED: rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/ruleset/rollout.ex; rulestead/lib/rulestead/ruleset/experiment.ex] |
| Tenant-sensitive compare/import/apply validation | API / Backend | Database / Storage | Preview/apply commands, compare tokens, environment versions, and apply persistence all live in core/store layers rather than the browser. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/environment_version.ex] |
| Tenant-aware audit and saved-plan metadata | API / Backend | Database / Storage | Audit metadata and environment version metadata are already bounded JSON maps persisted by the store layer. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/environment_version.ex] |
| Mounted-admin tenant picker/query scope | Frontend Server (SSR) | Browser / Client | The admin surface is LiveView-mounted, with route/query handling and session resolution on the server, then URL preservation in links. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead_admin/test/rulestead_admin/live/session_test.exs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 installed locally | Runtime and Mix execution surface for both sibling packages. [VERIFIED: local `elixir --version`] | Phase 25 is entirely inside the existing Elixir codebase; no alternate runtime is needed. [VERIFIED: codebase inspection] |
| Phoenix | `~> 1.8.1` in `rulestead_admin`; latest 1.8.7 published 2026-05-06 | Mounted admin routing and LiveView host integration. [VERIFIED: rulestead_admin/mix.exs; Hex package registry via `mix hex.info phoenix`] | The admin package already uses Phoenix and its mounted-route posture is a locked product constraint. [VERIFIED: rulestead_admin/mix.exs; CLAUDE.md; AGENTS.md] |
| Phoenix LiveView | `~> 1.1`; latest stable 1.1.30 published 2026-05-05 | Server-side admin session state and URL-backed scope handling. [VERIFIED: rulestead_admin/mix.exs; Hex package registry via `mix hex.info phoenix_live_view`] | Phase 25 admin scope work belongs in the existing LiveView session helper, not in a new UI framework. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; .planning/ROADMAP.md] |
| Ecto / Ecto SQL | `~> 3.13`; repo currently resolves Ecto 3.13.5, latest 3.13.6 published 2026-05-05 | Persisted apply, audit, and environment version metadata. [VERIFIED: rulestead/mix.exs; `mix deps.tree`; Hex package registry via `mix hex.info ecto`] | The existing store adapter and schema layer already own compare/apply persistence and should keep owning tenant-aware validation metadata. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/environment_version.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Jason | `~> 1.4`; repo currently resolves 1.4.4, latest stable 1.4.5 published 2026-05-05 | Stable JSON plan/manifest serialization. [VERIFIED: rulestead/mix.exs; `mix deps.tree`; Hex package registry via `mix hex.info jason`] | Reuse for any new tenant scope fields in plan or manifest-adjacent envelopes. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest.ex] |
| NimbleOptions | `~> 1.1` | Closed config schema validation for any new host tenancy config key. [VERIFIED: rulestead/mix.exs; rulestead/lib/rulestead/config.ex] | Use if Phase 25 adds a `:tenancy` config block; keep the host seam validated and explicit. [VERIFIED: rulestead/lib/rulestead/config.ex] |
| Telemetry | `~> 1.2` | Existing bounded metadata emission surface. [VERIFIED: rulestead/mix.exs] | Reuse if tenant scope becomes part of runtime/admin metadata, while keeping redaction discipline intact. [VERIFIED: prompts/rulestead-telemetry-observability-and-audit.md; prompts/rulestead-security-privacy-and-threat-model.md] |
| StreamData | `~> 1.1` test-only | Property testing for bucket composition and no-leak invariants. [VERIFIED: rulestead/mix.exs; prompts/rulestead-testing-and-e2e-strategy.md] | Add only for Phase 25 regression/property tests; no runtime dependency changes needed. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Internal `Rulestead.Tenancy` seam | Hidden `Process`/session ambient tenant state | Hidden ambient scope violates explicit-scope decisions and makes mutating flows impossible to audit correctly. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; prompts/rulestead-security-privacy-and-threat-model.md] |
| Existing compare/import/apply envelopes with tenant extensions | A second tenancy-specific validation workflow | A second workflow would duplicate stale checks, status vocabularies, and plan/apply contracts that Phase 24 just locked. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md; .planning/phases/24-gitops-manifests-cli-surface/24-VERIFICATION.md; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex] |
| Shared authored state plus bounded tenant metadata | Tenant-partitioned storage or per-tenant manifest trees | That directly violates the phase boundary and future-scope constraints. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] |

**Installation:**
```bash
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```
No new dependency is required for Phase 25; the research recommendation is to add internal modules and tests only. [VERIFIED: rulestead/mix.exs; rulestead_admin/mix.exs]

**Version verification:** Phoenix 1.8.7 (2026-05-06), Phoenix LiveView 1.1.30 stable (2026-05-05), Ecto 3.13.6 (2026-05-05), and Jason 1.4.5 (2026-05-05) were verified from the Hex package registry on 2026-05-19; the repo currently pins compatible but slightly older patch lines for Phoenix/Ecto/Jason. [VERIFIED: Hex package registry via `mix hex.info phoenix`, `mix hex.info phoenix_live_view`, `mix hex.info ecto`, `mix hex.info jason`]

## Architecture Patterns

### System Architecture Diagram

```text
Host Request / LiveView Params / Job Payload / CLI Plan
        |
        v
Explicit projection helpers
  Plug -> Context
  LiveView -> Context + admin query scope
  Oban -> bounded serialized Context
        |
        v
Rulestead.Tenancy
  - resolve tenant key
  - compose bucket identity
  - apply same-tenant guards
  - render bounded tenant scope metadata
        |
        +----------------------------+
        |                            |
        v                            v
Runtime evaluator               Compare / Import / Promote preview
  - deterministic buckets         - tenant-sensitive findings
  - existing rulesets             - plan token + tenant scope
        |                            |
        v                            v
Runtime result / debug trace     Apply commands / store validation
                                      |
                                      v
                              EnvironmentVersion + AuditEvent
                                - bounded tenant metadata
                                - no broad tenant-owned state
```
The data flow above stays inside the existing runtime/store/admin seams and does not introduce tenant-partitioned persistence. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead_admin/lib/rulestead_admin/live/session.ex]

### Recommended Project Structure
```text
rulestead/lib/rulestead/
├── tenancy.ex                    # new behaviour + helper entrypoint
├── tenancy/single_tenant.ex      # new no-op default implementation
├── config.ex                     # extend host config only if registration is needed
├── evaluator.ex                  # bucket identity composition hook
├── phoenix.ex                    # explicit conn -> context tenant projection
├── live_view.ex                  # explicit socket/session -> context tenant projection
├── oban.ex                       # bounded serialized tenant propagation
├── promotion/compare.ex          # tenant-sensitive finding detection + compare token scope
├── manifest/import.ex            # preview/apply tenant scope validation
├── manifest/plan.ex              # saved plan tenant scope envelope
├── audit_event.ex                # bounded tenant metadata serialization
├── environment_version.ex        # persisted apply metadata carrier
└── store/{command,ecto,fake}.ex  # adapter command contracts + parity

rulestead_admin/lib/rulestead_admin/live/
└── session.ex                    # explicit tenant query/session scope
```
The file layout above matches the existing package split and keeps tenant changes inside current seams. [VERIFIED: rulestead/lib/rulestead/config.ex; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/environment_version.ex; rulestead_admin/lib/rulestead_admin/live/session.ex]

### Pattern 1: Explicit Tenancy Behaviour With Safe Default
**What:** Add `Rulestead.Tenancy` plus `Rulestead.Tenancy.SingleTenant` as the single place that decides how tenant scope is normalized, how bucket identities are composed, and how same-tenant checks are evaluated. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; prompts/rulestead-engineering-dna-from-prior-libs.md]
**When to use:** `25-01`, for every place that currently reads or serializes `tenant_key` directly. [VERIFIED: rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex]
**Example:**
```elixir
# Source: project recommendation derived from the existing Context/Evaluator seam
defmodule Rulestead.Tenancy do
  @callback normalize_tenant_key(term()) :: String.t() | nil
  @callback bucket_identity(Rulestead.Context.t(), atom() | String.t(), String.t()) ::
              {:ok, String.t()} | {:error, :missing_identity}
  @callback same_tenant?(String.t() | nil, String.t() | nil) :: boolean()
  @callback metadata(String.t() | nil) :: map()
end
```
This keeps the public phase boundary narrow while giving the evaluator and plan/audit flows one source of truth. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/evaluator.ex]

### Pattern 2: Additive Bucket Composition, Not New Flag Topology
**What:** Feed evaluator bucket identity through the tenancy seam before hashing so a host can preserve per-actor behavior and still avoid cross-tenant collisions. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/evaluator.ex]
**When to use:** `25-01`, at every `resolve_bucket_identity/2` path for `:subject`, `:tenant`, `:session`, and fallback identities. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**Example:**
```elixir
# Source: project recommendation derived from the existing evaluator path
with {:ok, raw_identity} <- present(context.targeting_key) do
  tenancy.bucket_identity(context, :subject, raw_identity)
end
```
This approach is safer than adding new `bucket_by` schema values because rollout and experiment schemas already publish a closed enum set. [VERIFIED: rulestead/lib/rulestead/ruleset/rollout.ex; rulestead/lib/rulestead/ruleset/experiment.ex]

### Pattern 3: Extend Existing Preview/Apply Envelopes With Tenant Scope
**What:** Put explicit tenant scope into compare findings, saved plan artifacts, environment version metadata, and audit metadata, then reject apply when the scope is stale, absent for tenant-sensitive state, or mismatched. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/environment_version.ex; rulestead/lib/rulestead/audit_event.ex]
**When to use:** `25-02`, for promotion previews, manifest import previews, and direct apply paths. [VERIFIED: .planning/ROADMAP.md; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store/command.ex]
**Example:**
```elixir
# Source: existing plan/audit envelope pattern, extended with tenant scope
%{
  "plan_token" => "...",
  "target_environment_key" => "production",
  "tenant_scope" => %{"tenant_key" => "acme", "mode" => "explicit"},
  "dependency_closure_keys" => ["audience:vip-users"]
}
```
The important part is the shape, not the exact field name: tenant scope must be explicit, bounded, and serializable without dragging raw context or session state into artifacts. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/audit_event.ex; prompts/rulestead-security-privacy-and-threat-model.md]

### Anti-Patterns to Avoid
- **Ambient tenant inference:** Do not read tenant from `Process` state, hidden session memory, or implicit admin defaults during mutation. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; prompts/rulestead-security-privacy-and-threat-model.md]
- **Per-tenant authored copies:** Do not add tables, snapshot partitions, or manifest trees keyed by tenant in this phase. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
- **Second validation taxonomy:** Do not invent `tenant_compare_*` or `tenant_import_*` workflows when `Compare`, `Manifest.Result`, and saved plans already exist. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md; rulestead/lib/rulestead/manifest/result.ex; rulestead/lib/rulestead/promotion/compare.ex]

## Phase Slice Touchpoints

| Slice | Recommended files to touch | Why these files, not more | Likely tests to extend/add |
|-------|----------------------------|----------------------------|----------------------------|
| `25-01` Tenancy Seam, SingleTenant Default, and Bucketing Hooks | `rulestead/lib/rulestead/tenancy.ex`, `rulestead/lib/rulestead/tenancy/single_tenant.ex`, `rulestead/lib/rulestead/config.ex`, `rulestead/lib/rulestead/evaluator.ex`, `rulestead/lib/rulestead/phoenix.ex`, `rulestead/lib/rulestead/live_view.ex`, `rulestead/lib/rulestead/oban.ex`, `rulestead/test/rulestead/{context,plug,live_view,oban,release_contract}_test.exs`, plus a new `rulestead/test/rulestead/tenancy_test.exs`. [VERIFIED: .planning/ROADMAP.md; rulestead/lib/rulestead/config.ex; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex] | These are the only current files that own canonical tenant input, evaluator identity, or validated host config. No store schema or manifest export change is required for the phase boundary. [VERIFIED: rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/config.ex; rulestead/lib/rulestead/manifest/export.ex] | Extend projection tests and release contract, then add targeted bucket composition tests. [VERIFIED: rulestead/test/rulestead/context_test.exs; rulestead/test/rulestead/plug_test.exs; rulestead/test/rulestead/live_view_test.exs; rulestead/test/rulestead/oban_test.exs; rulestead/test/rulestead/release_contract_test.exs] |
| `25-02` Tenant-aware Validation, Audit Metadata, and Admin Scope | `rulestead/lib/rulestead/promotion/compare.ex`, `rulestead/lib/rulestead/manifest/import.ex`, `rulestead/lib/rulestead/manifest/plan.ex`, `rulestead/lib/rulestead/audit_event.ex`, `rulestead/lib/rulestead/environment_version.ex`, `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex`, `rulestead_admin/lib/rulestead_admin/live/session.ex`, `rulestead_admin/test/rulestead_admin/live/session_test.exs`, and the existing compare/import/apply contract suites. [VERIFIED: .planning/ROADMAP.md; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/environment_version.ex; rulestead/lib/rulestead/store/command.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/fake.ex; rulestead_admin/lib/rulestead_admin/live/session.ex] | These files already own preview/apply tokens, bounded metadata, adapter parity, and mounted-admin route/session scope. Touching export or storage topology files would widen scope beyond the roadmap. [VERIFIED: rulestead/lib/rulestead/manifest/export.ex; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] | Extend compare/import/promotion parity and audit metadata tests, then add admin session/query preservation tests for tenant scope. [VERIFIED: rulestead/test/rulestead/promotion/compare_test.exs; rulestead/test/rulestead/manifest/import_test.exs; rulestead/test/rulestead/store/manifest_import_contract_test.exs; rulestead/test/rulestead/store/promotion_apply_contract_test.exs; rulestead/test/rulestead/audit_event_governance_test.exs; rulestead_admin/test/rulestead_admin/live/session_test.exs] |

## Explicit Non-Goals

- Do not add tenant-partitioned authored storage, per-tenant snapshot tables, or per-tenant environment records. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
- Do not widen manifest export from one environment bundle into a tenant-partitioned or multi-tenant mega-document. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md; rulestead/lib/rulestead/manifest/export.ex]
- Do not create a standalone tenancy admin product or separate publish path for `rulestead_admin`. [VERIFIED: AGENTS.md; CLAUDE.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
- Do not introduce hidden “all tenants” mutation behavior in admin, CLI, or apply paths. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; prompts/rulestead-admin-ux-and-operator-ia.md]
- Do not bypass existing governed/protected-environment rules while adding tenant scope metadata. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-VERIFICATION.md; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store/ecto.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tenant state propagation | Ad hoc tenant reads from socket/session/process state | Existing explicit `Context` projection helpers plus a central `Rulestead.Tenancy` seam | The repo already enforces explicit bounded projection at the framework edge. [VERIFIED: rulestead/lib/rulestead/context.ex; rulestead/lib/rulestead/phoenix.ex; rulestead/lib/rulestead/live_view.ex; rulestead/lib/rulestead/oban.ex] |
| Tenant validation workflow | A second import/promotion status model | Existing `Compare`, `Manifest.Result`, saved plan/apply tokens, and store command validation | Phase 24 already locked status, exit code, and stale-preview semantics. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md; rulestead/lib/rulestead/manifest/result.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/promotion/compare.ex] |
| Tenant audit payloads | Raw context/session dumps in audit rows | `AuditEvent.metadata/1` bounded maps plus `EnvironmentVersion.metadata` | The current audit and environment-version layers already normalize maps and drop session-sensitive fields. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/environment_version.ex] |
| Tenant-specific storage | New DB partitioning or manifest trees | Bounded plan/audit/environment metadata and same-tenant guards | Storage partitioning is out of scope and would force schema/runtime/admin rewrites. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] |

**Key insight:** Phase 25 is a seam-hardening phase, not a topology phase; the safest implementation adds one normalized tenancy helper and threads it through the already-verified context, preview, apply, and audit contracts. [VERIFIED: .planning/ROADMAP.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; .planning/phases/24-gitops-manifests-cli-surface/24-VERIFICATION.md]

## Validation and Security Failure Modes

### Failure Mode 1: Cross-tenant bucket collision
**What goes wrong:** Two actors with the same `targeting_key` in different tenants can land in the same rollout bucket because the evaluator currently hashes raw identity strings. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**Why it happens:** `resolve_bucket_identity/2` returns `context.targeting_key`, `context.tenant_key`, or `context.session_id` directly, with no tenancy composition step. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**How to avoid:** Insert the tenancy seam before hashing and property-test that `tenant A + user 1` and `tenant B + user 1` do not collide unless the chosen bucket mode is intentionally tenant-stable. [VERIFIED: rulestead/lib/rulestead/evaluator.ex; prompts/rulestead-testing-and-e2e-strategy.md]
**Warning signs:** Rollout/exposure regressions only in multi-tenant fixtures that reuse actor IDs across tenants. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md]

### Failure Mode 2: Tenant-sensitive preview applied under the wrong scope
**What goes wrong:** A saved compare/import plan can be generated under one tenant scope and applied later without verifying that the scope still matches. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest/import.ex]
**Why it happens:** Current compare tokens and import plans are keyed by environment, flag set, dependency closure, and fingerprints, but not by tenant scope. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/plan.ex]
**How to avoid:** Mark tenant-sensitive flags/findings in preview, persist explicit tenant scope in the saved artifact, and reject apply when the artifact scope is missing, stale, or mismatched. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/manifest/import.ex]
**Warning signs:** Preview/apply succeeds even when the actor/admin session tenant changes between plan creation and apply. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex]

### Failure Mode 3: Hidden admin tenant default leaks into mutation
**What goes wrong:** The mounted admin remembers environment scope today, but has no explicit tenant query/session scope helper yet. Adding a silent tenant fallback would create exactly the hidden mutation behavior the phase forbids. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
**Why it happens:** `Session.resolve/3`, `current_path/3`, and `env_links/3` only track `env`. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead_admin/test/rulestead_admin/live/session_test.exs]
**How to avoid:** Mirror the explicit environment pattern for tenant scope in URL/session/link helpers and render the chosen tenant in the shell/header. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; prompts/rulestead-admin-ux-and-operator-ia.md]
**Warning signs:** URLs preserve `env` but not tenant, or a refreshed page loses tenant context while keeping environment. [VERIFIED: rulestead_admin/test/rulestead_admin/live/session_test.exs]

### Failure Mode 4: Tenant metadata leaks session or raw traits
**What goes wrong:** An engineer could add tenant data to audit metadata by stuffing raw context/session maps into `metadata`. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/store/command.ex]
**Why it happens:** Audit metadata is flexible JSON and command metadata accepts arbitrary maps after normalization. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/store/command.ex]
**How to avoid:** Serialize a small tenant scope map (`tenant_key`, scope mode, maybe host source) and rely on the existing sensitive-key drop path instead of passing full context. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; prompts/rulestead-security-privacy-and-threat-model.md]
**Warning signs:** Audit rows begin containing nested session maps, socket payloads, or trait bags after Phase 25 changes. [VERIFIED: rulestead/lib/rulestead/audit_event.ex]

## Likely Regression Surfaces

- `Rulestead.ReleaseContractTest` will fail if a new config key or public module is introduced without updating the locked contract docs and exported key lists. [VERIFIED: rulestead/test/rulestead/release_contract_test.exs; rulestead/lib/rulestead/config.ex]
- Runtime evaluation determinism can regress if tenant composition changes the identity format without synchronized test updates for rollout and experiment behavior. [VERIFIED: rulestead/lib/rulestead/evaluator.ex; rulestead/lib/rulestead/ruleset/rollout.ex; rulestead/lib/rulestead/ruleset/experiment.ex]
- Fake/Ecto parity can drift if tenant validation is added only in `Store.Ecto` or only in the facade layer. [VERIFIED: rulestead/test/rulestead/store/manifest_import_contract_test.exs; rulestead/test/rulestead/store/promotion_apply_contract_test.exs; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/fake.ex]
- Mounted-admin route helpers can regress if tenant params are appended inconsistently across `current_path/3`, `env_links/3`, and page-specific link builders. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead_admin/test/rulestead_admin/live/session_test.exs]
- Manifest import behavior can widen scope accidentally if tenant scope is pushed into export/import shape rather than plan/audit metadata. [VERIFIED: rulestead/lib/rulestead/manifest/export.ex; .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md]

## Code Examples

Verified patterns from the current codebase:

### Bounded Phoenix Context Projection
```elixir
# Source: rulestead/lib/rulestead/phoenix.ex
%{}
|> maybe_put(:actor, resolve_opt(conn, opts, :actor, &source_value/3))
|> maybe_put(:targeting_key, resolve_targeting_key(conn, opts, &source_value/3))
|> maybe_put(:tenant_key, resolve_opt(conn, opts, :tenant_key, &source_value/3))
|> maybe_put(:environment, resolve_opt(conn, opts, :environment, &source_value/3))
```
This is the right insertion point for Phase 25 tenant normalization because it already keeps framework structs at the edge. [VERIFIED: rulestead/lib/rulestead/phoenix.ex]

### Saved Plan Apply Revalidation
```elixir
# Source: rulestead/lib/rulestead/manifest/import.ex
with {:ok, plan} <- Plan.load(plan_content),
     :ok <- validate_import_mode(plan),
     {:ok, reason} <- require_reason(opts),
     :ok <- validate_plan_dependency_closure(plan),
     {:ok, current_manifest} <- Rulestead.export_manifest(plan["target_environment_key"]),
     :ok <- validate_target_fingerprint(plan, current_manifest) do
  ...
end
```
Phase 25 should extend this exact revalidation chain with tenant-scope checks instead of building a separate tenancy workflow. [VERIFIED: rulestead/lib/rulestead/manifest/import.ex]

### Mounted Admin Query Scope Helper
```elixir
# Source: rulestead_admin/lib/rulestead_admin/live/session.ex
params
|> Map.put("env", env_key)
|> encode_params()
|> then(&"#{base_path}?#{&1}")
```
Phase 25 should mirror this helper for tenant scope so the mounted admin keeps explicit, shareable URLs. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead_admin/test/rulestead_admin/live/session_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Runtime tenant carried ad hoc by host integrations | `%Rulestead.Context{tenant_key: ...}` is already the canonical runtime field | Phase 3 runtime context contract, still present on 2026-05-19 | Phase 25 should extend, not replace, the context model. [VERIFIED: rulestead/lib/rulestead/context.ex; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] |
| Mutation workflows without saved artifacts | Phase 24 locked saved import/promote plan artifacts with stale/apply revalidation | Verified 2026-05-19 | Tenant validation should project onto plan/audit metadata rather than inventing a second mutation model. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-VERIFICATION.md; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest/import.ex] |
| Tenant treated as future topology work | Phase 25 narrows tenancy to helpers, validation, and bounded metadata | Roadmap dated 2026-05-19 | Storage, inheritance, and cross-tenant dashboards stay deferred. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md] |

**Deprecated/outdated:**
- Hidden ambient tenant resolution is outdated for this phase because the locked decisions explicitly require tenant scope to remain visible in runtime/admin/apply flows. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]
- Treating tenant and environment as the same axis is outdated for this milestone because both the roadmap and context lock them as separate concerns. [VERIFIED: .planning/ROADMAP.md; .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md]

## Assumptions Log

All claims in this research were either verified from the codebase, project planning artifacts, prompt anchors, local environment probes, or the Hex package registry; no `[ASSUMED]` claims remain. [VERIFIED: this document]

## Resolved Decisions

1. **Tenancy registration lives in a new top-level `:tenancy` block inside `Rulestead.Config`.**
   - Decision: Phase 25 should extend the closed host config schema with an explicit `:tenancy` section rather than hiding tenancy registration under `:runtime`.
   - Why: this keeps the host seam discoverable, keeps release-contract updates localized, and matches the repo’s preference for explicit validated config blocks. [VERIFIED: rulestead/lib/rulestead/config.ex; rulestead/test/rulestead/release_contract_test.exs]
   - Planning impact: `25-01` must include `rulestead/lib/rulestead/config.ex`, `rulestead/test/rulestead/config_test.exs`, and `rulestead/test/rulestead/release_contract_test.exs`.

2. **Tenant scope stays out of exported manifests and is added only to saved plans, audit/environment metadata, and mounted admin scope helpers.**
   - Decision: Phase 25 should not change the canonical exported manifest contract.
   - Why: Phase 24 locked export to one environment-bounded authored-state document; adding tenant scope there would widen `MAN-01` and blur the difference between authored content and preview/apply metadata. [VERIFIED: .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md; rulestead/lib/rulestead/manifest/export.ex]
   - Planning impact: `25-02` must extend `Manifest.Plan`, compare/import/apply validation, audit/environment metadata, and mounted admin scope resolution instead of touching manifest export shape.

3. **Admin authorization keeps the public `Rulestead.Admin.Policy.can?/4` callback shape unchanged.**
   - Decision: tenant scope should reach authorization via normalized resource/context metadata and mounted session inputs, not by introducing a new public callback arity or signature.
   - Why: the current `can?/4` contract is part of the stable admin seam and is locked by release-contract coverage. [VERIFIED: rulestead/lib/rulestead/admin/policy.ex; rulestead/test/rulestead/release_contract_test.exs]
   - Planning impact: `25-02` should clarify this transport choice explicitly and cover it with authorizer/session tests rather than planning a public callback change.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Phase 25 code and tests | ✓ | 1.19.5 | — |
| Mix | All Phase 25 tasks and tests | ✓ | 1.19.5 | — |
| PostgreSQL | Ecto adapter parity and audit/environment-version persistence tests | ✓ | 14.17 client; local server accepting connections on `:5432` | Fake adapter covers most unit contracts if DB is unavailable |
| Redis | Existing runtime/invalidator surfaces touched indirectly by bounded context propagation tests | ✓ | `redis-cli` 7.2.4, `PONG` | Phase 25 core logic can still be validated without Redis-specific tests |
| Docker | Optional for heavier host/integration workflows | ✓ | 29.4.1 client | Not required for Phase 25 unit/contract coverage |

No blocking environment dependency gaps were found on this machine. [VERIFIED: local `elixir --version`; `mix --version`; `psql --version`; `pg_isready`; `redis-cli --version`; `redis-cli ping`; `docker info`]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with StreamData and Phoenix LiveView test helpers. [VERIFIED: rulestead/mix.exs; rulestead_admin/mix.exs; prompts/rulestead-testing-and-e2e-strategy.md] |
| Config file | `rulestead/test/test_helper.exs` and `rulestead_admin/test/test_helper.exs` by convention; no standalone `pytest`/`jest` config is used. [VERIFIED: repo layout + Mix project files] |
| Quick run command | `cd rulestead && mix test` or targeted files below. [VERIFIED: Mix project structure] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: sibling-package layout in AGENTS.md; Mix project files] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEN-01 | Explicit tenant scope is preserved across Context, Plug, LiveView, Oban, and mounted-admin session helpers. [VERIFIED: .planning/REQUIREMENTS.md] | unit + LiveView | `cd rulestead && mix test test/rulestead/context_test.exs test/rulestead/plug_test.exs test/rulestead/live_view_test.exs test/rulestead/oban_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/session_test.exs` | ✅ existing coverage base; `❌ Wave 0` for new tenancy-specific file |
| TEN-02 | Compare/import/promotion preview and apply reject tenant-sensitive stale or mismatched scope before mutation. [VERIFIED: .planning/REQUIREMENTS.md] | unit + adapter parity | `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/manifest/import_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/promotion_apply_contract_test.exs` | ✅ existing coverage base; `❌ Wave 0` for tenant-scope cases |
| TEN-03 | Single-tenant default, additive bucket composition, and tenant-aware audit metadata remain deterministic and bounded. [VERIFIED: .planning/REQUIREMENTS.md] | unit + property + contract | `cd rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/release_contract_test.exs` plus new tenancy/property tests | ✅ existing audit/release coverage base; `❌ Wave 0` for new tenancy/property files |

### Sampling Rate
- **Per task commit:** run the targeted file set for the files touched by that slice. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- **Per wave merge:** run all Phase 25 targeted backend plus admin session suites. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- **Phase gate:** run `cd rulestead && mix test && cd ../rulestead_admin && mix test` before `/gsd-verify-work`. [VERIFIED: sibling-package layout in AGENTS.md]

### Wave 0 Gaps
- [ ] `rulestead/test/rulestead/tenancy_test.exs` — cover `SingleTenant`, identity composition, same-tenant guard, and config wiring. [VERIFIED: file not present via `rg --files`]
- [ ] `rulestead/test/rulestead/tenancy_property_test.exs` — prove cross-tenant actor IDs do not collide unintentionally after bucket composition. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md; file not present via `rg --files`]
- [ ] Extend `rulestead/test/rulestead/promotion/compare_test.exs` and `rulestead/test/rulestead/manifest/import_test.exs` with tenant-sensitive findings and stale-scope rejections. [VERIFIED: existing files present]
- [ ] Extend `rulestead/test/rulestead/store/{manifest_import_contract_test,promotion_apply_contract_test}.exs` and `rulestead/lib/rulestead/fake.ex` parity expectations so Fake and Ecto reject the same tenant mismatches. [VERIFIED: existing files present]
- [ ] Extend `rulestead_admin/test/rulestead_admin/live/session_test.exs` with explicit tenant param/session preservation assertions. [VERIFIED: existing file present]
- [ ] Extend `rulestead/test/rulestead/release_contract_test.exs` if Phase 25 adds a new config key or public `Rulestead.Tenancy` module. [VERIFIED: existing file present]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app owns authentication; Phase 25 must not move this into Rulestead. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md; prompts/rulestead-host-app-integration-seam.md] |
| V3 Session Management | yes | Mounted admin tenant scope should use explicit query/session helpers and must not serialize raw session payloads into audit or plans. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead/lib/rulestead/audit_event.ex] |
| V4 Access Control | yes | Same-tenant guards and protected-environment governance checks must fail closed. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store/ecto.ex] |
| V5 Input Validation | yes | `NimbleOptions`, existing plan/load validators, and explicit string normalization should validate new tenant scope fields. [VERIFIED: rulestead/lib/rulestead/config.ex; rulestead/lib/rulestead/manifest/plan.ex; rulestead/lib/rulestead/manifest.ex; rulestead/lib/rulestead/store/command.ex] |
| V6 Cryptography | no | Phase 25 does not require new cryptographic primitives; it should reuse existing hashing behavior in compare tokens and bucket computation without inventing new crypto. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/plan.ex] |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data leakage through preview/apply metadata | Information Disclosure | Keep tenant scope explicit and bounded; never serialize raw context/session/trait bags. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; rulestead/lib/rulestead/audit_event.ex; prompts/rulestead-security-privacy-and-threat-model.md] |
| Tenant scope spoofing in admin/automation flows | Spoofing | Require explicit tenant scope in route/session/plan metadata and reject mismatched scope at apply. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead/lib/rulestead/manifest/import.ex] |
| Tenant-sensitive preview replay after context drift | Repudiation / Tampering | Extend saved tokens/fingerprints with tenant scope and keep stale preview rejection as a domain error. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; .planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md] |
| Audit overcollection when adding tenant metadata | Information Disclosure | Reuse `AuditEvent.metadata/1` normalization and sensitive-key dropping rather than passing raw context maps. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; prompts/rulestead-security-privacy-and-threat-model.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md` - locked scope, decisions, and deferred items.
- `.planning/ROADMAP.md` - active Phase 25 slices and success criteria.
- `.planning/REQUIREMENTS.md` - `TEN-01` through `TEN-03`.
- `.planning/research/V0_6_ARCHITECTURE.md` - milestone-level tenancy seam recommendation.
- `.planning/research/V0_6_DX.md` - explicit env/tenant UX posture.
- `prompts/rulestead-engineering-dna-from-prior-libs.md` - prior-art `SingleTenant` seam and bounded integration patterns.
- `prompts/rulestead-domain-language-field-guide.md` - canonical tenant/environment/context vocabulary.
- `prompts/rulestead-security-privacy-and-threat-model.md` - fail-closed and bounded metadata guidance.
- `prompts/rulestead-host-app-integration-seam.md` - host-owned integration boundary.
- `prompts/rulestead-testing-and-e2e-strategy.md` - test strategy and property-testing expectations.
- `prompts/rulestead-admin-ux-and-operator-ia.md` - explicit tenant picker/query guidance for mounted admin.
- `prompts/rulestead-telemetry-observability-and-audit.md` - bounded metadata and audit/telemetry separation.
- `rulestead/lib/rulestead/{context,config,evaluator,phoenix,live_view,oban,manifest/import,manifest/plan,manifest/export,promotion/compare,audit_event,environment_version,store/command,store/ecto,fake}.ex` - current implementation seams.
- `rulestead_admin/lib/rulestead_admin/live/session.ex` - mounted-admin scope helper.
- `rulestead/test/rulestead/{context,plug,live_view,oban,manifest/import,promotion/compare,release_contract,audit_event_governance}.exs` and `rulestead/test/rulestead/store/{manifest_import_contract,promotion_apply_contract}.exs` - existing regression surfaces.
- `rulestead_admin/test/rulestead_admin/live/session_test.exs` - existing admin route/session coverage.

### Secondary (MEDIUM confidence)
- Hex package registry `phoenix` - current releases and publish dates. [CITED: https://hex.pm/packages/phoenix]
- Hex package registry `phoenix_live_view` - current stable release line and publish dates. [CITED: https://hex.pm/packages/phoenix_live_view]
- Hex package registry `ecto` - current stable release line and publish dates. [CITED: https://hex.pm/packages/ecto]
- Hex package registry `jason` - current stable release line and publish dates. [CITED: https://hex.pm/packages/jason]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified from repo `mix.exs` files, `mix deps.tree`, and Hex registry metadata on 2026-05-19. [VERIFIED: rulestead/mix.exs; rulestead_admin/mix.exs; `mix deps.tree`; `mix hex.info ...`]
- Architecture: HIGH - the phase boundary and almost all implementation seams are already explicit in code and planning artifacts. [VERIFIED: .planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md; codebase inspection]
- Pitfalls: HIGH - the main failure modes fall directly out of current evaluator identity handling, admin session scope handling, and existing bounded audit/apply contracts. [VERIFIED: rulestead/lib/rulestead/evaluator.ex; rulestead_admin/lib/rulestead_admin/live/session.ex; rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/manifest/import.ex]

**Research date:** 2026-05-19 [VERIFIED: current session date]
**Valid until:** 2026-06-18 for codebase-local findings; re-check Hex package versions sooner if dependencies are upgraded. [VERIFIED: codebase-local scope + Hex package registry volatility]

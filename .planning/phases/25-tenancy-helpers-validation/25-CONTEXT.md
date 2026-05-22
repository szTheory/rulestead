# Phase 25: Tenancy Helpers & Validation - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning
**Source:** Roadmap, milestone research, prompt anchors, and adjacent Phase 24 artifacts

<domain>
## Phase Boundary

Add the smallest coherent tenancy-aware seam that lets Rulestead carry explicit tenant scope through runtime, admin, promotion, and manifest validation flows without turning tenancy into a new storage topology or product surface.

**In scope:**
- a minimal `Rulestead.Tenancy` seam with a safe single-tenant default
- explicit tenant-aware helpers for runtime/admin scope resolution where Phase 25 needs them
- tenant-aware bucketing hooks that preserve deterministic rollout behavior
- tenant-aware validation for import/promotion and related saved-plan/apply metadata
- bounded audit/admin metadata so tenant scope is visible where operators and safety checks need it

**Out of scope (explicitly deferred):**
- environment-per-tenant topology
- tenant-partitioned authored-state storage or snapshot tables
- tenant inheritance, tenant-cloned flags, or tenant-specific manifest trees
- cross-tenant global admin dashboards or a standalone `rulestead_admin` control plane
- hidden ambient tenant resolution or implicit “all tenants” mutation behavior

</domain>

<decisions>
## Implementation Decisions

### Product Shape and Scope Discipline
- **D-01:** Phase 25 must preserve the linked-version, sibling-package release model and must not widen `rulestead_admin` into a separately publishable tenancy product.
- **D-02:** Tenancy remains a helper seam layered on top of the existing environment model, not a second primary topology. Environment and tenant stay separate axes.
- **D-03:** This phase should default to recommendation-first downstream planning. Re-open decisions only when they materially change public contract, security posture, or milestone scope.

### Minimal Tenancy Seam
- **D-04:** Add a small `Rulestead.Tenancy` seam with a `SingleTenant` default implementation rather than baking tenant assumptions into process state or adapter internals.
- **D-05:** The seam should stay bounded to explicit helpers such as tenant resolution, scope application, bucketing composition, topic partitioning, and same-tenant guards. Do not introduce full tenant lifecycle management.
- **D-06:** Tenant scope must remain explicit in request/runtime/admin/apply flows where it matters. Do not infer mutating tenant scope from hidden defaults.

### Runtime, Bucketing, and Validation
- **D-07:** Existing `%Rulestead.Context{}` tenant input remains the canonical evaluation tenant field; Phase 25 builds on it instead of replacing the context model.
- **D-08:** Tenant-aware bucketing should be additive and composable so hosts can keep per-actor behavior or opt into tenant-stable rollout behavior without changing flag topology.
- **D-09:** Promotion and manifest import paths must reject tenant-sensitive invalid states before apply, using the existing preview-first and stale-check posture from Phases 22 through 24.
- **D-10:** Saved plan/apply artifacts and audit metadata should carry bounded tenant scope information when relevant, but must not serialize broad tenant-owned state or hidden runtime baggage.

### Admin and Safety Posture
- **D-11:** Tenant scope must be visible in operator-facing admin or automation flows when tenancy is enabled, but this phase should only add the minimum mounted-admin seams needed for safety and validation.
- **D-12:** Cross-tenant leakage is a first-class failure mode. Query/guard helpers and tests should bias toward explicit scope checks and fail-closed behavior.
- **D-13:** Single-tenant hosts must remain the default ergonomic path; tenancy-enabled behavior should compose cleanly without forcing every adopter into multi-tenant complexity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active roadmap and requirements
- `.planning/ROADMAP.md` — Phase 25 goal, requirements, planned slices, and success criteria
- `.planning/REQUIREMENTS.md` — `TEN-01`, `TEN-02`, and `TEN-03`
- `.planning/STATE.md` — active milestone status and current execution boundary

### Milestone-level tenancy research
- `.planning/research/V0_6_ARCHITECTURE.md` — recommended minimal tenancy seam, helper callbacks, and explicit non-goals
- `.planning/research/V0_6_DX.md` — explicit env/tenant UX and no-implicit-scope guardrails

### Prompt anchors
- `prompts/rulestead-domain-language-field-guide.md` — canonical context, actor, tenant, and targeting vocabulary
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — prior-art tenancy seam, `SingleTenant` default, and scope discipline
- `prompts/rulestead-security-privacy-and-threat-model.md` — cross-tenant isolation, tenant-aware audit/privacy constraints, and fail-closed admin posture
- `prompts/rulestead-host-app-integration-seam.md` — host-owned integration boundaries
- `prompts/rulestead-testing-and-e2e-strategy.md` — targeted verification and regression posture
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted admin/operator safety expectations

### Adjacent implemented phase context
- `.planning/phases/03-context-rules-deterministic-bucketing-pure-evaluator/03-CONTEXT.md` — canonical `Rulestead.Context` shape and rollout bucketing rules
- `.planning/phases/14-openfeature-ecosystem-integration/14-CONTEXT.md` — explicit context mapping and `tenantKey` propagation
- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` — compare contract, dependency closure, and stale preview posture
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — governed apply, audit linkage, and protected-target safety contract
- `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md` — saved plan/apply artifacts, additive-only import posture, and scope-expansion constraints
- `.planning/phases/24-gitops-manifests-cli-surface/24-VERIFICATION.md` — verified import/promotion behavior that Phase 25 must extend without regression

### Existing code and public seams
- `rulestead/lib/rulestead/context.ex` — canonical runtime tenant field
- `rulestead/lib/rulestead/phoenix.ex` — request-context projection including `tenant_key`
- `rulestead/lib/rulestead/live_view.ex` — LiveView context projection including `tenant_key`
- `rulestead/lib/rulestead/oban.ex` and `rulestead/lib/rulestead/oban/middleware.ex` — bounded context propagation including `tenant_key`
- `rulestead/lib/rulestead/evaluator.ex` — rollout/experiment bucketing behavior and tenant-aware resolution points
- `rulestead/lib/rulestead/ruleset/rollout.ex` and `rulestead/lib/rulestead/ruleset/experiment.ex` — current bucket-by contract
- `rulestead/lib/rulestead/promotion/compare.ex` — compare payload, dependency closure, and protected-target findings
- `rulestead/lib/rulestead/manifest/import.ex` and `rulestead/lib/rulestead/manifest/plan.ex` — import plan/apply validation and saved artifact shape
- `rulestead/lib/rulestead/audit_event.ex` — audit metadata envelope
- `rulestead/lib/rulestead/store/command.ex` — key-first command structs and metadata normalization

</canonical_refs>

<specifics>
## Specific Ideas

- Keep the phase split aligned with the roadmap:
  - `25-01` should cover the tenancy seam, `SingleTenant`, and bucketing hooks.
  - `25-02` should cover tenant-aware validation, audit metadata, and mounted admin scope seams.
- Favor additive helpers over schema-wide rewrites.
- Reuse the existing compare/import/promote preview contracts wherever tenant validation can project onto current fingerprints, scope fields, and findings rather than inventing a second validation system.
- Prefer explicit tenant scope fields in plan/audit/admin payloads over implicit session-derived behavior.

</specifics>

<deferred>
## Deferred Ideas

- Full tenant-partitioned authoring/storage
- Tenant-specific manifest inheritance or reconciliation
- Cross-tenant fleet dashboards
- Broad tenancy middleware beyond the minimal host seam and bounded context propagation
- Any change that would prepare `rulestead_admin` for standalone publication

</deferred>

---

*Phase: 25-tenancy-helpers-validation*
*Context gathered: 2026-05-19*

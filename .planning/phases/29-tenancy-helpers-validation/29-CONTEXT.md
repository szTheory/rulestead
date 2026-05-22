# Phase 29: Tenancy Helpers & Validation - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Research mode:** discuss-all with recommendation-first synthesis across admin tenant scope, validation strictness, audit/saved-plan metadata, and tenant-aware bucketing semantics

<domain>
## Phase Boundary

Add the smallest coherent tenancy-aware seam that lets Rulestead carry explicit tenant scope through runtime, mounted admin, promotion, and manifest validation flows without turning tenancy into a storage-topology rewrite or a standalone control-plane product.

**In scope:**
- a bounded `Rulestead.Tenancy` seam with a safe `SingleTenant` default
- explicit tenant-aware runtime/admin scope resolution that stays host-owned and fail-closed
- additive tenant-aware bucketing hooks that preserve deterministic rollout behavior
- tenant-aware compare/import/promotion validation with exact-scope revalidation at apply time
- bounded tenant scope metadata in saved plans and audit trails

**Out of scope (explicitly deferred):**
- tenant-partitioned authored storage or runtime snapshot topology
- environment-per-tenant or cloned flag topologies
- implicit “all tenants” reads or writes
- standalone `rulestead_admin` tenancy management
- broad tenant lifecycle/catalog management inside Rulestead

</domain>

<decisions>
## Implementation Decisions

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

### the agent's Discretion
- Exact session key names and resolver helper names for available tenants, provided host ownership and fail-closed checks remain explicit
- Exact UI composition for tenant chip/picker placement, provided tenant stays visible and separate from environment
- Exact encoding of tenant validation provenance in plans and audit metadata, provided the bounded shape and semantics remain stable
- Exact helper/module names for tenant-scope classifiers and same-tenant guards, provided one shared validator model is reused across compare/import/promotion
- Exact implementation of tenant-scoped subject composition, provided it remains explicit, documented, and opt-in

</decisions>

<specifics>
## Specific Ideas

- Treat tenant scope like environment scope: explicit, URL-addressable, mounted-admin-safe, and host-authorized rather than ambient.
- Keep preview/apply behavior aligned with Terraform-style reviewed-artifact discipline: inspect exact scope first, then apply only that reviewed scope.
- Learn from mounted Phoenix tooling such as Oban Web: host owns identity and authorization, embedded admin consumes bounded scope.
- Learn from systems like Unleash, LaunchDarkly, and Statsig that keep rollout identity explicit rather than silently derived from whatever context happens to exist.
- Keep audit and plan artifacts stable and reproducible by preferring tenant IDs over labels and provenance enums over freeform UI echoes.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 29 goal, two-plan split, and success criteria
- `.planning/REQUIREMENTS.md` — `TEN-01`, `TEN-02`, and `TEN-03`
- `.planning/PROJECT.md` — current milestone framing, linked-version release shape, and tenancy non-goals
- `.planning/STATE.md` — active milestone status and current planning posture

### Prior tenancy context and milestone research
- `.planning/phases/25-tenancy-helpers-validation/25-CONTEXT.md` — prior locked tenancy posture, explicit non-goals, and original split between seam work and validation/audit/admin scope
- `.planning/research/V0_6_ARCHITECTURE.md` — recommended minimal tenancy seam and rejection of topology-heavy approaches
- `.planning/research/V0_6_DX.md` — explicit env/tenant UX, plan/apply discipline, and host/app seam guidance

### Prompt anchors
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — host-owned seams, `SingleTenant` default, explicit recommendation-heavy posture, and mounted-admin library DNA
- `prompts/rulestead-host-app-integration-seam.md` — host-owned auth/layout/session boundaries and mounted admin integration expectations
- `prompts/rulestead-admin-ux-and-operator-ia.md` — visible tenant picker guidance, no implicit all-tenant footgun, and route-backed operator UX expectations
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed posture, least-privilege scope handling, and bounded audit/privacy constraints
- `prompts/rulestead-domain-language-field-guide.md` — canonical tenant/environment/operator vocabulary
- `prompts/rulestead-testing-and-e2e-strategy.md` — regression and verification posture for additive seam work

### Adjacent phase context
- `.planning/phases/03-context-rules-deterministic-bucketing-pure-evaluator/03-CONTEXT.md` — canonical runtime context and deterministic bucketing rules
- `.planning/phases/14-openfeature-ecosystem-integration/14-CONTEXT.md` — explicit context mapping and tenant propagation expectations
- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` — compare-token semantics, blocker taxonomy, and exact review/apply posture
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — reviewed artifact discipline, governed apply, and recommendation-first planning posture
- `.planning/phases/24-gitops-manifests-cli-surface/24-CONTEXT.md` — saved plan/apply artifacts and import/export scope constraints
- `.planning/phases/27-comprehensive-rbac-security-hardening/27-CONTEXT.md` — canonical mounted-admin authorization posture

### Existing code and public seams
- `rulestead/lib/rulestead/tenancy.ex` — bounded tenancy behavior seam and composition hook
- `rulestead/lib/rulestead/tenancy/single_tenant.ex` — safe default single-tenant implementation
- `rulestead/lib/rulestead/context.ex` — canonical runtime `tenant_key` field
- `rulestead/lib/rulestead/evaluator.ex` — existing bucket identity resolution and tenant-aware bucket paths
- `rulestead/lib/rulestead/phoenix.ex` — request-context tenant resolution seam
- `rulestead/lib/rulestead/live_view.ex` — LiveView tenant resolution seam
- `rulestead/lib/rulestead/manifest/import.ex` — current tenant blockers and apply-time tenant drift checks
- `rulestead/lib/rulestead/manifest/plan.ex` — saved plan shape and tenant field handling
- `rulestead/lib/rulestead/promotion/compare.ex` — compare token and compare result tenant fields
- `rulestead/lib/rulestead/promotion/apply.ex` — promotion apply envelope
- `rulestead/lib/rulestead/audit_event.ex` — bounded audit metadata normalization and redaction path
- `rulestead/lib/rulestead/store/command.ex` — command structs that already carry `tenant_key`
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — current environment resolution pattern that tenant scope should mirror
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` — mounted shell scope display pattern
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex` — compare surface that will need explicit tenant scope carry-through

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Tenancy` and `Rulestead.Tenancy.SingleTenant`: already provide the correct small seam for tenant resolution, same-tenant checks, topic partitioning, and bucket identity composition.
- `Rulestead.Context`: already makes `tenant_key` a first-class explicit evaluation input.
- `Rulestead.Manifest.Import`: already contains the right fail-closed tenant blocker patterns and apply-time tenant drift checks to reuse.
- `Rulestead.Promotion.Compare`: already has stable compare-token, finding, and reviewed-artifact semantics that tenant validation should plug into.
- `Rulestead.AuditEvent.metadata/1`: already normalizes and bounds audit metadata, which makes it the right place for stable tenant provenance fields.
- `RulesteadAdmin.Live.Session`: already resolves environment from URL, remembered state, and defaults with host-owned inputs. Tenant scope should follow that shape instead of inventing a second pattern.

### Established Patterns
- The repo consistently prefers explicit URL/session-backed operator scope over hidden ambient state.
- Promotion/import/apply flows are already built around preview-first, stale-aware, exact-artifact revalidation.
- Runtime evaluation is intentionally pure and callback-driven rather than process-global or adapter-magical.
- Audit metadata is bounded and normalized; broad raw payload capture is intentionally avoided.
- Mounted admin remains host-authored and host-authorized; library code consumes bounded session state rather than owning identity.

### Integration Points
- Tenant resolution should plug into current Phoenix and LiveView context builders plus mounted admin session resolution.
- Tenant scope validation should be factored once and reused across compare, import, promotion, CLI, and admin surfaces.
- Audit metadata and saved plan serialization should share one tenant provenance vocabulary so review and apply flows stay consistent.
- Bucketing composition should remain inside the existing evaluator/tenancy seam rather than leaking into store or admin-specific code.

</code_context>

<deferred>
## Deferred Ideas

- Cross-tenant dashboards or global “all tenants” operator views
- Tenant-partitioned authored storage, runtime snapshot tables, or environment trees
- Tenant labels or catalog snapshots embedded in plans or audit events
- Tenant override / force-apply modes for compare, import, or promotion
- Additional bucket enums or hidden fallback chains beyond explicit `:tenant` and opt-in tenant-scoped subject composition
- Broad tenant lifecycle management or tenant catalog ownership inside Rulestead

</deferred>

---

*Phase: 29-tenancy-helpers-validation*
*Context gathered: 2026-05-21*

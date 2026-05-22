# Phase 31: Audit Tenant Provenance Enforcement - Context

**Gathered:** 2026-05-22
**Status:** Ready for planning
**Source:** discuss-all with parallel advisor research, prior tenancy context, live code inspection, and ecosystem comparison against Unleash / LaunchDarkly audit and change-governance patterns

<domain>
## Phase Boundary

Close the remaining audit-provenance gap so mutation and apply paths attach bounded tenant provenance automatically instead of relying on callers to hand-author audit metadata.

**In scope:**
- automatic bounded tenant provenance merging for audit mutation and apply paths
- one normalized provenance vocabulary reused across Ecto and fake adapters
- propagation through direct writes, apply/replay flows, governance flows, scheduled execution audit rows, denied mutation audit rows, and rollback rows
- explicit semantics for unscoped and `SingleTenant` paths
- targeted verification that tenant provenance cannot silently drop in shipped paths

**Out of scope:**
- new mounted-admin tenant UX or compare flow changes
- tenant catalogs, labels, or discovery
- environment-per-tenant or tenant-partitioned storage
- standalone `rulestead_admin` work
- broad public API redesign outside the bounded command/audit seam already in the product

</domain>

<decisions>
## Implementation Decisions

### Recommendation-first execution posture
- **D-01:** Downstream planning and implementation should treat the recommendations in this context as locked unless a change would materially alter public contract, security posture, milestone scope, or release shape.
- **D-02:** Phase 31 should optimize for one coherent architecture rather than presenting multiple equivalent implementation branches. Normal implementation tradeoffs should be resolved by the agent without reopening them to the user.

### Provenance source of truth
- **D-03:** Use a **hybrid command-first model**:
  - normalized command fields and reviewed artifacts remain the canonical inputs
  - one centralized tenant provenance builder derives the bounded persisted shape
  - Ecto and fake audit builders both merge that shape automatically on audit writes
- **D-04:** Freeform `command.metadata` must not become the durable source of tenant truth. It may carry bounded hints, but canonical provenance must come from normalized command facts and reviewed artifacts.
- **D-05:** Keep `tenant_key` as a first-class normalized field on write/apply commands where the command already owns tenant scope. Do not replace it with an opaque provenance-only blob.
- **D-06:** Phase 31 should not rely on ambient runtime state such as `conn`, `socket`, process dictionary, or logger metadata to derive audit provenance.

### Coverage of audited write paths
- **D-07:** Apply **layered defense**:
  - normalize tenant provenance on commands and persisted replay/scheduling payloads
  - enforce final emission through the centralized audit builders as a backstop
- **D-08:** The minimum required coverage inventory is:
  - direct audited writes: `publish_ruleset`, `archive_flag`, `engage_kill_switch`, `release_kill_switch`
  - denied mutation audit-only branches for the same protected write family plus `save_draft_ruleset`
  - direct apply flows: `ApplyPromotion`, `ApplyManifestImport`
  - governed lifecycle rows and audit rows: submit, approve, reject, cancel change requests, and execute change requests
  - scheduled execution persistence and `scheduled_execution.*` audit rows
  - rollback-generated audit rows and any synthesized inverse commands they execute
  - persisted replay payloads such as governed `command_snapshot` and scheduled execution metadata
- **D-09:** Do not solve Phase 31 through per-callsite patching. Future write paths must inherit provenance automatically through the shared normalization and audit-builder seams.
- **D-10:** Adapter parity is mandatory: fake and Ecto must serialize the same bounded tenant provenance shape and follow the same precedence rules.

### Missing-scope semantics
- **D-11:** When no real tenant scope exists, audit rows must still emit **explicit bounded provenance semantics** rather than silently omitting the entire concept or inventing synthetic tenant identity.
- **D-12:** The bounded no-scope rules are:
  - if a real tenant exists: persist `tenant_key`, `scope_source`, and bounded validation evidence
  - if tenancy is absent in a multi-tenant-capable path: omit `tenant_key` and emit bounded validation evidence `not_applicable` with status `bypassed`
  - if the active tenancy module is `SingleTenant` and no tenant key exists: emit `scope_source: single_tenant` plus bounded validation evidence `single_tenant` with status `bypassed`
- **D-13:** Phase 31 must not infer or fabricate a tenant identity from `SingleTenant`, environment, actor, or session data when no real tenant scope is present.
- **D-14:** The persisted shape should favor operator clarity over micro-optimization: a small bounded provenance object is preferable to ambiguous absence.

### Rollback and replay semantics
- **D-15:** Rollback and replay-like audit rows are **new execution facts**, not derived snapshots. Their primary actor and tenant provenance must reflect the current action being executed now.
- **D-16:** Prior lineage remains authoritative through immutable links such as `rollback_of_event_id`, `change_request_id`, and `scheduled_execution_id`; Phase 31 should not overwrite new-row execution provenance with copied prior-row context.
- **D-17:** For rollback and replay-style rows, keep a bounded linked-origin view for explainability:
  - the new row uses current tenant provenance as primary truth
  - the prior row is linked by immutable id
  - a small bounded origin snapshot may be copied for one-row exports and investigations
- **D-18:** If a rollback or replay path requires same-tenant continuity, enforce that explicitly and record the validation outcome rather than inheriting old tenant truth silently.

### Bounded provenance vocabulary
- **D-19:** The audit provenance dialect should stay aligned with the Phase 29 tenancy vocabulary:
  - `tenant_key` only when a real tenant exists
  - `scope_source` using bounded enums such as `explicit`, `host_resolved`, or `single_tenant`
  - bounded validation evidence using `same_tenant_guard`, `single_tenant`, or `not_applicable`
  - bounded validation status such as `passed` or `bypassed`
- **D-20:** Do not persist tenant labels, catalogs, host session state, or arbitrary confirmation text in audit provenance.

### Verification posture
- **D-21:** Verification should focus on contract-style coverage of the normalized provenance helper and parity coverage across fake and Ecto adapters, especially for replay/governance/scheduler paths where silent drops are most likely.
- **D-22:** Phase 31 should prove that governed promotion snapshots and scheduled execution payloads remain self-describing with respect to tenant provenance, not just that final audit rows look correct in direct-write paths.

### the agent's Discretion
- Exact helper and module names for the shared provenance normalizer and audit merge functions
- Exact nesting of the bounded provenance object, provided the vocabulary and semantics above remain stable
- Whether bounded origin provenance lives under `origin`, `links`, or an adjacent bounded audit metadata section, provided current-action truth and immutable linkage remain clear
- Exact test file split between adapter contract tests, audit-event tests, and higher-level apply/governance regressions

</decisions>

<specifics>
## Specific Ideas

- Treat Phase 31 as the final tenancy seam closure for audit writes: callers should stop hand-authoring tenant audit truth.
- Favor the mature governance pattern visible in systems like Unleash and LaunchDarkly:
  - current action identity stays truthful
  - linked lifecycle ids preserve lineage
  - audit scope is explicit and queryable
- Keep the Rulestead-specific DX sharp:
  - command constructors own normalized facts
  - replay payloads remain self-describing
  - audit builders act as the final consistency backstop
- Prefer “explicitly unscoped” over “missing data” and prefer “linked prior context” over “copied prior truth.”

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and active milestone state
- `.planning/ROADMAP.md` — Phase 31 goal, success criteria, and dependency on Phase 30
- `.planning/PROJECT.md` — linked-version two-package product shape, milestone framing, and tenancy constraints
- `.planning/REQUIREMENTS.md` — active `TEN-03` requirement
- `.planning/STATE.md` — current milestone position and next-action context
- `.planning/METHODOLOGY.md` — recommendation-first planning lens and high-impact exception posture

### Prior tenancy decisions
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` — locked tenancy, bounded provenance vocabulary, and fail-closed posture
- `.planning/phases/29-tenancy-helpers-validation/29-RESEARCH.md` — saved-plan/audit metadata guidance and prior research synthesis
- `.planning/phases/29-tenancy-helpers-validation/29-VALIDATION.md` — validation dimensions for bounded tenant provenance and one metadata dialect
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md` — explicit out-of-scope note for provenance automation and mounted-admin carry-forward constraints
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-RESEARCH.md` — Phase 31 provenance closure reminder from the prior phase

### Prompt anchors
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — host-owned seam discipline, audit/event DNA, and recommendation-first engineering posture
- `prompts/rulestead-host-app-integration-seam.md` — host/app boundary and explicit-seam expectations
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed security posture, bounded metadata, and immutable audit expectations
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit/event contract expectations, lineage thinking, and observability posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary for tenant/environment/operator/audit language
- `prompts/rulestead-testing-and-e2e-strategy.md` — contract-style verification posture

### Existing code seams
- `rulestead/lib/rulestead/audit_event.ex` — bounded audit metadata normalization and serialization
- `rulestead/lib/rulestead/store/command.ex` — normalized command shapes, especially apply/governance/rollback commands
- `rulestead/lib/rulestead/store/ecto.ex` — real-store audit builders, rollback handling, governance persistence, and scheduled execution audit insertion
- `rulestead/lib/rulestead/fake.ex` — fake-store audit builders and parity seam
- `rulestead/lib/rulestead.ex` — public mutation/apply/governance orchestration and denied mutation path
- `rulestead/lib/rulestead/promotion/apply.ex` — promotion apply revalidation seam
- `rulestead/lib/rulestead/manifest/import.ex` — manifest apply and reviewed-artifact replay seam
- `rulestead/lib/rulestead/tenancy.ex` — tenancy contract and same-tenant helpers
- `rulestead/lib/rulestead/tenancy/single_tenant.ex` — safe single-tenant default semantics

### Existing verification targets
- `rulestead/test/rulestead/audit_event_governance_test.exs` — bounded audit metadata assertions
- `rulestead/test/rulestead/promotion/apply_test.exs` — promotion apply reviewed-artifact coverage
- `rulestead/test/rulestead/manifest/import_test.exs` — manifest import/apply tenant drift coverage
- `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` — adapter parity around promotion apply
- `rulestead/test/rulestead/store/manifest_import_contract_test.exs` — adapter parity around manifest import apply
- `rulestead/test/rulestead/release_contract_test.exs` — bounded contract assertions that may need extension

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.AuditEvent.metadata/1` is already the central normalizer for bounded audit metadata and is the natural home for one stable tenant provenance dialect.
- `Rulestead.Store.Command` already carries `tenant_key` on apply commands and has normalization helpers that can host shared provenance shaping logic.
- `Rulestead.Store.Ecto` and `Rulestead.Fake` each already funnel most audit writes through centralized builders, which creates the right enforcement seam for adapter parity.
- Phase 29 already established the bounded provenance vocabulary in planning artifacts, so Phase 31 can complete the runtime/audit enforcement rather than invent a new dialect.

### Established Patterns
- The repo consistently prefers explicit normalized inputs over hidden ambient context.
- Audit rows are immutable execution facts, not mutable history documents.
- Replay/apply flows already use reviewed-artifact discipline and should keep tenant provenance self-describing through queued and replayed payloads.
- Security posture is fail-closed and bounded: data should be explicit, stable, and redacted before persistence.

### Current Gaps
- Some apply and governance replay paths still drop tenant scope before audit emission, especially where persisted command snapshots depend on freeform metadata.
- Rollback rows link prior audit events today but do not yet carry explicit tenant provenance of the current execution.
- No single shared provenance builder currently guarantees that fake and Ecto adapters emit identical tenant provenance shapes across all audited write paths.

### Integration Points
- Add a shared normalized provenance helper near `Rulestead.Store.Command` and/or `Rulestead.AuditEvent`.
- Feed that helper from apply commands, rollback/inverse commands, governed `command_snapshot`, and scheduled execution metadata.
- Reuse centralized audit builders in `Rulestead.Store.Ecto` and `Rulestead.Fake` as the final merge/enforcement seam.
- Extend adapter contract tests so provenance presence/shape is asserted across direct writes, applies, rollbacks, governance, and scheduling.

</code_context>

<deferred>
## Deferred Ideas

- Any wider public command API redesign that promotes provenance blobs to a broader external contract
- Tenant labels, catalogs, or richer origin-history UX in audit exports/admin views
- Cross-tenant audit dashboards or tenant management surface area
- Broader GSD/global workflow preference changes beyond the minimal methodology clarification already present at the project level

</deferred>

---

*Phase: 31-audit-tenant-provenance-enforcement*
*Context gathered: 2026-05-22*

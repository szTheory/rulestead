# Phase 35: Lifecycle Contract & Ownership Metadata - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning
**Source:** discuss-all synthesis with parallel advisor research, codebase inspection, prior phase context, and prompt-anchor review

<domain>
## Phase Boundary

Define the authored ownership and lifecycle contract for flags so Rulestead can carry stable owner metadata, explicit lifecycle intent, and bounded audit/history semantics across authored-state reads, writes, and mounted-admin projections without creating a Rulestead-owned identity directory or coupling lifecycle logic to the runtime hot path.

**In scope:**
- ownership metadata shape for authored state, audit, and mounted-admin reads
- lifecycle-intent defaults and authored override posture at create/edit time
- explicit separation between authored lifecycle facts and derived operator guidance
- bounded audit metadata for ownership/lifecycle transitions

**Out of scope:**
- archive-readiness scoring and cleanup recommendations from evaluation/code-reference signals
- mounted-admin lifecycle workbench flows beyond the contract needed to support later phases
- standalone owner directory, host-table foreign keys, or runtime owner resolution
- auto-archive, auto-cleanup, or persisted computed lifecycle status

</domain>

<decisions>
## Implementation Decisions

### Product shape and milestone discipline
- **D-01:** Phase 35 is a contract-and-metadata phase, not a lifecycle automation phase. It must tighten authored truth and audit semantics without widening the sibling-package release model or moving lifecycle logic into the runtime evaluator.
- **D-02:** Downstream planning should favor one coherent recommendation-heavy implementation path unless a choice would materially change public contract, security/governance posture, milestone scope, or release shape.

### Ownership contract
- **D-03:** Replace the current “freeform owner label as truth” posture with a **bounded host-owned owner reference contract**. Durable truth should be a stable opaque owner reference, not a mutable display string.
- **D-04:** The ownership shape should support at least:
  - a canonical opaque reference such as `owner_ref`
  - a bounded owner kind such as `person`, `team`, or `service`
  - an optional display snapshot for admin readability and exports
- **D-05:** `owner_ref` is the stable value used for filtering, audit continuity, and lifecycle accountability. Any stored display label is advisory only and must not become identity truth.
- **D-06:** Rulestead must not create a user/team directory, must not foreign-key into host tables, and must not require live owner resolution on read or runtime evaluation paths.
- **D-07:** Mounted admin should be able to consume a host-supplied owner picker / validation seam when available, but the core contract must still permit explicit manual entry of the opaque owner reference so the library remains host-friendly.
- **D-08:** Ownership metadata belongs on authored-state, audit, and mounted-admin surfaces only. It is not part of runtime flag evaluation semantics.

### Lifecycle defaults and authored intent
- **D-09:** Lifecycle defaults should be **admin-only suggestions with explicit operator override**, not hidden automatic decisions and not runtime evaluator behavior.
- **D-10:** Persisted lifecycle truth remains explicit authored metadata. Phase 35 should not store computed statuses such as `potentially_stale`, `stale`, `ready_to_archive`, or similar machine opinions as canonical database truth.
- **D-11:** Add a bounded lifecycle-default policy seam for create/edit flows that returns a suggestion, rationale, and whether the operator overrode it.
- **D-12:** Recommended default posture by flag type is:
  - `release`, `experiment`, `migration` → suggest expiring
  - `kill_switch`, `operational`, `permission` → suggest permanent
  - `remote_config` → require explicit operator posture rather than applying a silent default
- **D-13:** Suggested review horizons may be host-configurable, but defaults must stay advisory and previewable. They must never imply auto-archive or false precision.
- **D-14:** Flag type may shape lifecycle suggestions, but it must not become lifecycle truth by itself.

### Projection boundary
- **D-15:** Rulestead should use a **partially normalized authored contract plus derived projections**:
  - authored state stores explicit human-authored lifecycle and ownership facts
  - mounted-admin and reporting surfaces derive lifecycle guidance from those facts plus later evidence signals
- **D-16:** `Rulestead.Admin.Lifecycle` or an equivalent shared projector remains the seam for derived operator guidance. Read models should explain lifecycle posture from authored facts rather than persisting machine status.
- **D-17:** Derived lifecycle guidance must stay independent from the runtime hot path. Evaluation should not depend on cleanup posture, stale classification, owner resolution, or archive-readiness projections.
- **D-18:** Phase 35 must not introduce a projection-refresh subsystem, background recompute job, generated-column scheme, or trigger-based persistence for computed lifecycle states.

### Audit and history shape
- **D-19:** Keep the existing generic audit envelope (`before` / `after` / `diff` / `links` / `context`) as the detailed immutable record.
- **D-20:** Add **bounded first-class transition summaries** for ownership and lifecycle changes inside audit metadata so operators can filter and understand these changes without parsing arbitrary diffs.
- **D-21:** Ownership/lifecycle audit summaries should follow the same design language as existing bounded tenant provenance:
  - enum-heavy, normalized, privacy-bounded
  - generated centrally
  - stable across Ecto, fake, governance, replay, and scheduled execution paths
- **D-22:** Diff remains the canonical detailed change record. Transition summaries are compact queryable hints, not a second competing source of truth.
- **D-23:** Phase 35 must not introduce bespoke per-event audit schema sprawl for every lifecycle mutation. One stable envelope plus bounded summaries is the preferred model.

### Backward-compatibility and operator trust
- **D-24:** Existing freeform owner strings should be treated as compatibility input during migration and normalization, not as the long-term contract.
- **D-25:** Archive and cleanup remain explicit operator actions. Nothing in Phase 35 should imply automatic archival from defaults, owner metadata, or advisory lifecycle projections.

### the agent's Discretion
- Exact module names for owner-contract normalization and lifecycle-default suggestion seams
- Exact field names for ownership metadata, provided there is one canonical opaque reference, one bounded kind, and optional display snapshot semantics
- Exact audit metadata nesting for ownership/lifecycle transition summaries, provided the envelope remains stable and bounded
- Exact mounted-admin copy and control layout for showing suggested lifecycle defaults and override state

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“operators author facts, admin computes guidance”** rather than “the system stores lifecycle truth.”
- The closest mature pattern is: stable owner reference + optional readable label, not a full identity model.
- Lifecycle suggestions should feel like opinionated scaffolding, not hidden automation.
- `remote_config` is the important exception to type-driven lifecycle defaults; it spans both short-lived launches and durable configuration.
- Ownership and lifecycle filters should work from stable, bounded metadata rather than parsing arbitrary labels or raw diffs.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 35 goal, milestone framing, and scope boundary
- `.planning/PROJECT.md` — `v1.2.0` rationale, linked-version release shape, and lifecycle/ownership constraints
- `.planning/REQUIREMENTS.md` — `LIF-01` and adjacent milestone requirements
- `.planning/STATE.md` — current milestone position and planning posture
- `.planning/METHODOLOGY.md` — recommendation-first planning lens for this repo

### Prior lifecycle and tenancy decisions
- `.planning/phases/15-lifecycle-hygiene-and-code-references/15-CONTEXT.md` — prior stale/code-reference posture, manual cleanup discipline, and no auto-archive precedent
- `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` — bounded host-owned metadata vocabulary and no host-schema coupling
- `.planning/phases/30-mounted-admin-tenant-scope-closure/30-CONTEXT.md` — mounted-admin host-bounded scope and visibility posture
- `.planning/phases/31-audit-tenant-provenance-enforcement/31-CONTEXT.md` — bounded audit provenance vocabulary and centralized normalization pattern

### Prompt anchors
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package architecture, host-owned seams, bounded metadata, and recommendation-first engineering DNA
- `prompts/rulestead-host-app-integration-seam.md` — host-owned identity/auth boundaries and mounted-admin integration expectations
- `prompts/rulestead-admin-ux-and-operator-ia.md` — operator-facing preview/confirm/audit posture and calm mounted-admin UX expectations
- `prompts/rulestead-security-privacy-and-threat-model.md` — immutable audit posture, least-privilege metadata, and host-owned identity constraints
- `prompts/rulestead-domain-language-field-guide.md` — canonical lifecycle and ownership vocabulary
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit envelope conventions and bounded metadata expectations
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — library DX and public contract discipline
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Elixir/Ecto/Phoenix state placement and projection guidance

### Existing code seams
- `rulestead/lib/rulestead/flag.ex` — current authored flag schema and lifecycle validation rules
- `rulestead/lib/rulestead/admin/lifecycle.ex` — current derived lifecycle projector
- `rulestead/lib/rulestead/audit_event.ex` — bounded audit envelope normalization
- `rulestead/lib/rulestead/store/command.ex` — existing bounded metadata normalization patterns
- `rulestead/lib/rulestead/store/ecto.ex` — authored-state persistence and admin payload construction
- `rulestead/lib/rulestead/fake.ex` — adapter parity and lifecycle payload decoration
- `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` — current owner/lifecycle authoring UI
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — current mounted-admin lifecycle projection display
- `rulestead/test/rulestead/admin_lifecycle_test.exs` — lifecycle validation and projection tests
- `rulestead/test/rulestead/admin_contract_test.exs` — command/public contract expectations
- `rulestead/test/rulestead/store_ecto_admin_test.exs` — admin payload and lifecycle filtering behavior
- `rulestead/test/rulestead/audit_event_governance_test.exs` — audit metadata normalization expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Flag` already enforces the core authored lifecycle invariant: explicit expiration or permanent posture.
- `Rulestead.Admin.Lifecycle.classify/3` already provides the right derived-projection seam for operator guidance.
- `Rulestead.AuditEvent.metadata/1` already normalizes bounded audit metadata and should remain the central audit vocabulary seam.
- `Rulestead.Store.Command.GovernanceSupport` already demonstrates how bounded normalized metadata can coexist with generic envelopes.
- Mounted-admin flag form and detail views already isolate authoring vs projection surfaces clearly enough to extend without redesigning the product.

### Established Patterns
- The repo consistently favors explicit host-owned seams over hard coupling to host schemas or identity systems.
- Durable truth and derived operator guidance are already separate in the current architecture.
- Bounded metadata vocabularies are preferred over freeform, open-ended blobs.
- Admin/operator flows preserve explicit preview/confirm/audit posture instead of hidden automation.

### Integration Points
- Ownership normalization should plug into the existing create/update command and changeset flow.
- Lifecycle default suggestions should live beside admin authoring flows, not evaluator/runtime code.
- Audit transition summaries should be emitted centrally so adapter parity remains testable.
- Mounted-admin filters and detail pages should consume the normalized ownership/lifecycle contract through the same read-model/projector surfaces.

</code_context>

<deferred>
## Deferred Ideas

- Full archive-readiness scoring from evaluation evidence and code references — Phase 36
- Mounted-admin lifecycle workbench, filters, and cleanup actions — Phase 37
- Standalone owner directory, host-table associations, or cross-tenant/global ownership dashboards
- Persisted computed lifecycle state or projection-refresh infrastructure
- Auto-archive, auto-cleanup, or any hidden lifecycle mutation based on heuristics
- Broad bespoke audit event schemas per lifecycle action

</deferred>

---

*Phase: 35-lifecycle-contract-ownership-metadata*
*Context gathered: 2026-05-23*

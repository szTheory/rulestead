# Requirements: v1.6.0 - Reusable Targeting Deepening

**Defined:** 2026-05-27
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions - booleans, variants, and remote config - with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.6.0 Requirements

### Impact Preview Contract (`IMP`)

- [x] **IMP-01**: Operators can request a reusable audience impact preview that reports environment scope, tenant scope, referenced flags/rulesets, active rollout or lifecycle context, preview basis, uncertainty, and redacted sample evidence without claiming Rulestead owns identity or observability truth.
- [x] **IMP-02**: Audience definition edits, archive/delete attempts, and protected shared-targeting mutations require a stale-resistant preview token or fingerprint before apply, and stale, missing, archived, incompatible, or tenant-mismatched references fail closed with actionable reasons.
- [x] **IMP-03**: Runtime snapshots continue to compile reusable audience definitions for local deterministic evaluation, and runtime evaluation never performs live database, mounted-admin, host identity, or observability lookups to resolve audience references.
- [x] **IMP-04**: Audit events for accepted, blocked, or denied audience mutations include the preview fingerprint, affected-reference summary, actor, reason, environment scope, tenant scope, and support-safe evidence needed to reconstruct the decision.

### Dependency Truth And Promotion Safety (`DEP`)

- [x] **DEP-01**: Operators and support tooling can query core-owned audience reference inventory with stable reference counts, affected flag/ruleset/rule metadata, lifecycle/rollout hints, and authorization-safe redaction for resources they cannot view.
- [x] **DEP-02**: Audience archive/delete and ruleset publish validation block unresolved, archived, incompatible, stale, or tenant-mismatched audience references before they can create broken runtime snapshots.
- [x] **DEP-03**: Environment compare, promotion preview/apply, replay/re-apply, manifest export, manifest import, and manifest validation surface readable audience dependency findings and fail closed on missing or incompatible reusable targeting assets.
- [x] **DEP-04**: Dependency and impact outputs sort by stable semantic keys and carry environment/tenant scope explicitly so same-name or cross-scope audience definitions cannot be mistaken for equivalent dependencies.

### Explainability And Mounted Operator Workflows (`ADM`)

- [x] **ADM-01**: Mounted audience list and detail screens show policy-aware reference counts, "used by" tables, lifecycle/owner context, and affected rollout indicators inside the existing mounted admin envelope.
- [x] **ADM-02**: Mounted audience edit and archive/delete flows use a preview -> confirm -> audit workflow with fallback copy for missing preview data, stale preview tokens, denied dependency reads, and protected-environment governance requirements.
- [x] **ADM-03**: Flag rule editing, simulation, and explanation surfaces carry reusable audience context through selected-audience summaries, matched/missed audience trace steps, missing-reference copy, and support-safe explain permalinks.
- [x] **ADM-04**: Mounted compare, promotion, and manifest screens render reusable audience dependency findings with actionable blockers and links without introducing a standalone admin control plane, graph visualizer, or bulk automation path.

### Verification And Support Truth (`VER`)

- [ ] **VER-01**: Repo-local proof covers dependency inventory, preview determinism, stale-token rejection, fail-closed missing/archive behavior, audit evidence, explain trace carry-through, and promotion/manifest dependency blockers.
- [ ] **VER-02**: Public docs, package docs, release-contract checks, and mounted companion proof explain the supported reusable-targeting deepening scope, package boundaries, preview-basis limits, tenant/environment semantics, and host-owned identity/observability responsibilities.
- [ ] **VER-03**: The linked-version sibling-package release model remains intact: `rulestead` owns domain contracts and validation, `rulestead_admin` owns mounted presentation, and no Phase 8-only docs or standalone `rulestead_admin` publish prep are introduced.

## Future Requirements

### Deferred Beyond v1.6.0

- **IMP-05**: Audience previews can compare richer host-supplied impression summaries or sample cohorts when the host explicitly provides bounded, redacted evidence through an existing seam.
- **ADM-05**: Optional targeting presets can generate concrete draft audiences or rules for common patterns without live inheritance or ongoing propagation.
- **GOV-01**: Protected-environment audience edits can require governed approval based on blast-radius thresholds after preview tokens and dependency truth are proven.
- **ROL-04**: Rollouts can automatically advance between stages when guardrails remain healthy for a configured observation window.

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Bridge Frequency | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| Audience impact preview contract | `rulestead` owns preview semantics over authored state and explicit samples | low-frequency semantic | high | high | merge-blocking deterministic preview and stale-token proof | `core` |
| Audience dependency inventory and validation | `rulestead` owns reference truth, validation, and fail-closed blockers | low-frequency semantic | high | high | merge-blocking dependency, promotion, manifest, and authorization proof | `core` |
| Explain trace carry-through | `rulestead` owns structured trace data; `rulestead_admin` renders support-safe copy | low-frequency semantic | medium | medium | trace and mounted simulation proof | `core` + `companion` |
| Mounted reusable-targeting workflows | `rulestead_admin` owns presentation inside the host-mounted policy envelope | native screen | high | medium | mounted preview-confirm-audit proof | `companion` |
| Host identity, tenant catalog, metrics, or observability-backed population counts | no route owner inside current product boundary | defer | high | high | n/a | `defer` |
| Live targeting templates, inheritance graphs, or workflow automation | no route owner in this milestone | defer | high | high | n/a | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Audience impact preview payloads, preview tokens, redaction basis, and audit metadata in `rulestead` | `core` | In scope |
| Audience dependency inventory, reference counts, archive/delete blockers, compare, promotion, replay, and manifest validation in `rulestead` | `core` | In scope |
| Structured audience match/miss explain trace data in `rulestead` | `core` | In scope |
| Mounted audience used-by screens, preview-confirm-audit flows, compare/import dependency presentation, and explain/simulate carry-through in `rulestead_admin` | `companion` | In scope |
| Root/package docs, proof commands, release-contract checks, and support-truth wording | `example/docs-only` | In scope |
| Graph visualization, standalone admin, live inheritance templates, bulk automation, observability dashboards, host identity queries, or authoritative affected-user counts | `defer` | Out of scope |

## Proof Posture Gate

| Surface | Merge-Blocking Proof | Advisory Proof |
|---------|----------------------|----------------|
| Impact preview contract | deterministic tests for preview basis, scope, redaction, token fingerprints, stale-token rejection, and missing/archived/incompatible references | host-app walkthrough with explicit sample contexts |
| Dependency truth and promotion safety | core tests for reference counts, archive/delete blockers, compare findings, promotion blockers, replay/re-apply blockers, and manifest import/export validation | large-reference fixture smoke for pagination and stable ordering |
| Runtime determinism and explainability | snapshot/evaluator tests proving no live lookup is required and audience trace nodes appear for match, miss, missing, and archived cases | support walkthrough using mounted simulate/explain pages |
| Mounted workflows | LiveView tests for used-by tables, preview-confirm-audit flow, denied dependency reads, stale preview copy, and dependency findings | browser smoke captures for audience detail/edit and promotion/import screens |
| Docs and support truth | release-contract checks around package boundaries, preview-basis limits, linked-version docs, and prohibited Phase 8/standalone-admin claims | maintainer spot-check against README and package docs |

## Support Truth Gate

| Surface | Denial / Fallback Behavior | Missing Prerequisite Behavior | Rebuild / Setup Expectation | Rough-Edge Docs Required |
|---------|----------------------------|-------------------------------|-----------------------------|--------------------------|
| Audience impact preview | Preview refuses stale or incompatible inputs and labels unavailable evidence instead of showing zero-impact states | Missing explicit samples or host-supplied evidence degrades to authored-reference impact only | Host app only needs the normal linked-version package update and existing mounted policy seam | yes |
| Dependency validation | Publish, archive/delete, promotion, replay, and manifest apply fail closed on unresolved audience references | Missing target audience, archived audience, tenant mismatch, or incompatible definition returns actionable blockers | No new service dependency; migration/index changes must be documented | yes |
| Explainability | Runtime and mounted explain surfaces show missing/denied audience context without leaking raw predicates or PII | Old or unsupported snapshots show bounded fallback copy and snapshot version context | Existing runtime snapshot refresh path remains the setup boundary | yes |
| Mounted workflows | Policy-denied dependency reads are redacted or counted as hidden; mutation paths stay disabled without required permission | Missing mounted route/policy wiring renders existing setup guidance, not standalone-admin claims | Host app mounts `rulestead_admin` as before under linked package versions | yes |

## Out of Scope

| Feature | Reason |
|---------|--------|
| A new reusable targeting primitive | Reusable audiences already shipped; this milestone deepens safety and supportability |
| Hidden audience inheritance graphs or live-linked targeting templates | Creates surprise propagation and opaque explainability |
| Runtime database, admin, host identity, tenant catalog, or observability lookups during evaluation | Violates deterministic local snapshot evaluation and host-owned boundaries |
| Rulestead-owned affected-user counts, metrics storage, dashboards, or anomaly detection | Pulls Rulestead into identity/observability ownership beyond current scope |
| Standalone `rulestead_admin` control plane or publish preparation | Conflicts with the mounted sibling-package design and current execution constraints |
| Tenant hierarchy shortcuts or implicit all-tenant mutations | Conflicts with explicit, fail-closed tenancy semantics |
| Full graph visualizer or one-click bulk shared-targeting automation | Adds high polish and safety cost without being necessary for bounded dependency visibility |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| IMP-01 | Phase 53 | Complete |
| IMP-02 | Phase 53 | Complete |
| IMP-03 | Phase 53 | Complete |
| IMP-04 | Phase 53 | Complete |
| DEP-01 | Phase 54 | Complete |
| DEP-02 | Phase 54 | Complete |
| DEP-03 | Phase 54 | Complete |
| DEP-04 | Phase 54 | Complete |
| ADM-01 | Phase 55 | Complete |
| ADM-02 | Phase 55 | Complete |
| ADM-03 | Phase 55 | Complete |
| ADM-04 | Phase 55 | Complete |
| VER-01 | Phase 56 | Pending |
| VER-02 | Phase 56 | Pending |
| VER-03 | Phase 56 | Pending |

**Coverage:**

- v1.6.0 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after roadmap creation*

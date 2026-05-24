# Roadmap

## Current Status

- [x] **v1.1.0 — Tenancy Helpers & Validation**: shipped on 2026-05-23 across Phases 29-34. Archive: [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md).
- [ ] **v1.2.0 — Lifecycle Hygiene & Ownership**: active milestone defined on 2026-05-23 across planned Phases 35-40.

## Active Milestone

`v1.2.0` makes lifecycle and ownership first-class operator flows without widening the product beyond its linked-version, two-package shape. The milestone is intentionally narrow: ownership metadata, lifecycle classification, archive-readiness guidance, cleanup UX, and docs that teach “flag from birth to retirement” with least-surprise defaults.

## Phases

### Phase 35: Lifecycle Contract & Ownership Metadata

**Goal**: Rulestead exposes a bounded lifecycle and ownership contract that stays host-friendly, auditable, and independent from the runtime hot path.
**Depends on**: Phase 34
**Plans:** 2/2 plans complete
**Planned focus**:

- ownership metadata shape and host-owned opaque owner references
- lifecycle defaults by flag type and expected-lifetime posture
- authored-state, audit, and mounted projection contract alignment

Plans:
- [x] `35-01-PLAN.md` — establish the authored ownership/lifecycle contract across schema, migration, command normalization, adapters, and mounted-admin authoring
- [x] `35-02-PLAN.md` — add bounded audit transition summaries and align mounted-admin detail/projection surfaces to the authored contract

### Phase 36: Archive-Readiness Signals & Cleanup Analysis

**Goal**: Archive-readiness becomes a bounded advisory system built from lifecycle metadata, evaluation evidence, and code-reference signals instead of a blunt stale flag.
**Depends on**: Phase 35
**Plans:** 2/2 plans complete
**Planned focus**:

- lifecycle classification and next-action guidance
- code-reference and last-evaluation signal composition
- CLI/reporting surface for stale and cleanup review

Plans:
- [x] `36-01-PLAN.md` — build the shared archive-readiness projector plus Ecto/Fake payload and advisory filter parity
- [x] `36-02-PLAN.md` — expose the shared archive-readiness contract through mounted-admin read surfaces and the read-only lifecycle Mix report

### Phase 37: Mounted Admin Lifecycle Workbench

**Goal**: Operators can review, filter, and act on lifecycle posture through calm mounted-admin flows that preserve shareable URLs, preview-before-mutation, and audit safety.
**Depends on**: Phase 36
**Plans:** 2/2 plans complete
**Planned focus**:

- lifecycle filters, owner filters, and archive-readiness views
- detail-page lifecycle projection and cleanup recommendations
- explicit archive/cleanup actions with preview, reason, and audit continuity

Plans:
- [x] `37-01-PLAN.md` — preserve canonical queue state across mounted lifecycle filters, detail, and cleanup entrypoints
- [x] `37-02-PLAN.md` — replace cleanup preview/confirm placeholders with the governed archive flow and queue-return outcome handling

### Phase 38: Lifecycle Docs, Runbooks, & Verification

**Goal**: The lifecycle system is documented and verified as a coherent “birth to retirement” operator story for Phoenix teams.
**Depends on**: Phase 37
**Plans:** 3/3 plans complete
**Planned focus**:

- docs, runbooks, and least-surprise default guidance
- release-surface verification and support-truth coverage
- milestone closeout evidence for lifecycle workflows

Plans:
- [x] `38-01-PLAN.md` — create the lifecycle spine guide and route root/package entrypoints into the canonical story
- [x] `38-02-PLAN.md` — align satellite runbooks, testing guidance, API-stability language, and maintainer lifecycle release notes
- [x] `38-03-PLAN.md` — codify lifecycle release-surface tests and write the phase-local `LIF-05` verification artifact

### Phase 39: Lifecycle Contract Verification Closure

**Goal**: Close milestone evidence for the authored ownership and lifecycle contract so `LIF-01` can be proved from implementation through verification without widening scope.
**Depends on**: Phase 38
**Planned focus**:

- write the missing Phase 35 verification artifact against the delivered ownership and lifecycle contract
- reconcile `LIF-01` milestone traceability with the verified Phase 35 evidence
- align closeout notes so the ownership-contract flow is milestone-verifiable end to end

### Phase 40: Lifecycle Workbench Verification & State Reconciliation

**Goal**: Close mounted lifecycle workbench evidence and reconcile milestone state so `LIF-03` and `LIF-04` can be closed without ambiguity.
**Depends on**: Phase 39
**Planned focus**:

- write the missing Phase 37 verification artifact for queue, cleanup review, preview, confirm, and queue-return behaviors
- correct Phase 37 traceability drift, including the summary frontmatter typo and requirement mapping
- reconcile roadmap, requirements, and state closeout status once the archive-workbench evidence is in place

## Next Candidates

- `v1.3.0 — Guarded Rollout Foundations`: the strongest immediate follow-on once lifecycle/ownership is credible.
- `v1.4.0 — Reusable Targeting Assets`: shared audiences first, with broader template ideas deferred until dependency visibility remains clear.

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md)

## Next Step

Run `$gsd-plan-phase 39` to draft the first gap-closure phase from the v1.2.0 milestone audit.

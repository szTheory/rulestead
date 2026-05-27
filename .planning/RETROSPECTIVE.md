# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.6.0 — Reusable Targeting Deepening

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 22

### What Was Built

- Pure audience impact previews with scoped fingerprints, redacted sample evidence, and authored-state dependency summaries.
- Snapshot-local reusable audience compilation and deterministic segment_match evaluation traces.
- Canonical audience dependency inventory with fail-closed publish, archive/delete, promotion, compare, replay, and manifest validation.
- Mounted audience library, preview-confirm-audit mutation flows, explain/simulate trace carry-through, and compare dependency findings.
- `mix verify.phase56` merge gate, release-contract drift guards, flow guide updates, and optional CI proof scope.

### What Worked

- Four equal-sized phases (core contract → dependency truth → mounted UX → proof/docs) kept core-vs-companion boundaries explicit.
- Reusing the `mix verify.phaseNN` pattern gave each phase a crisp merge gate and handoff checklist.
- Treating reusable audiences as already shipped avoided greenfield scope creep and kept the milestone focused on blast-radius safety.

### What Was Inefficient

- No milestone audit artifact was produced before close; future milestones should run `/gsd-audit-milestone` for a formal gap check.
- Same-day execution compressed timeline metrics; velocity tables remain sparse until session timing is captured consistently.

### Patterns Established

- Preview tokens/fingerprints with stale revalidation on every durable audience mutation.
- One core dependency projection consumed by Ecto, Fake, promotion, manifest, and mounted read surfaces.
- Optional CI proof scopes mirror prior `guarded_rollout_foundations` without changing default CI behavior.

### Key Lessons

1. Deepening an existing primitive (audiences) is faster and safer than inventing a parallel targeting model.
2. Honest preview basis labels matter as much as the preview payload — operators trust authored-state impact over false precision.
3. Handoff checklists between core and mounted phases prevent presentation drift from domain truth.

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 4 (see STATE.md Deferred Items).

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.5.0 | 4 | 8 | Introduced guarded rollout foundations with host-owned signal seam |
| v1.6.0 | 4 | 16 | Deepened reusable targeting with equal core/mounted/proof phase split |

### Cumulative Quality

| Milestone | Phase verify gates | Release-contract guards | Deferred at close |
|-----------|-------------------|-------------------------|-------------------|
| v1.5.0 | verify.phase52 | guarded rollout drift guards | 2 |
| v1.6.0 | verify.phase54–56 | reusable targeting drift guards | 4 |

### Top Lessons (Verified Across Milestones)

1. Support-truth and proof closure milestones pay down adopter friction before differentiated features land.
2. Core owns contracts and validation; mounted admin owns presentation — the sibling-package split scales across feature families.
3. Fail-closed validation at publish/mutation boundaries prevents broken snapshots better than post-hoc operator warnings.

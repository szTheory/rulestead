# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.8.0 — Guarded Rollout Auto-Advance

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 32

### What Was Built

- Authored auto-advance policy with observation window, explicit next-stage plan, and fail-closed eligibility on v1.5 guardrails.
- `ScheduledExecution` observation-window ticks orchestrating governed `advance_rollout` with idempotency, protected-env change-request routing, and `guardrail_automation` audit evidence.
- Mounted rollouts auto-advance panel (six fail-closed modes), policy save gated on `:advance_rollout`, and timeline distinction for automation vs manual actions.
- `mix verify.phase64` merge gate, release-contract drift guards, host seam + flow guides, and optional `guarded_rollout_auto_advance` CI scope.

### What Worked

- Reusing `ScheduledExecution` and the existing governed-action envelope avoided a parallel mutation path and kept v1.5 hold/rollback semantics intact.
- The four-phase split (authored contract → orchestration → mounted UX → proof/docs) matched v1.5–v1.7 rhythm and preserved core-vs-companion boundaries.
- Fail-open schedule hook on `advance_rollout` plus fail-closed eligibility at tick execute balanced operator progress with safety.

### What Was Inefficient

- No formal `v1.8.0-MILESTONE-AUDIT.md` before close (third consecutive milestone without audit artifact).
- `gsd-sdk milestone.complete` warned about a missing STATE.md field — planning doc formats should stay aligned with gsd-tools expectations.

### Patterns Established

- `RolloutAutoAdvance.Schedule` as the shared idempotency and command-snapshot contract across Ecto and Fake.
- Fresh guardrail signals fetched at tick execute; schedule snapshot intentionally empty for signal facts.
- Protected-env auto-advance submits change requests at execute time without auto-approve; non-protected paths direct-advance through the orchestrator.

### Key Lessons

1. Completing a multi-milestone arc (v1.5 foundations → v1.7 governance → v1.8 auto-advance) is faster when each layer reuses the prior envelope instead of inventing parallel workflows.
2. Mounted UX should derive fail-closed modes from core truth (guardrails, policy, scheduled ticks) rather than inferring healthy fleet state.
3. Support-truth phases remain non-negotiable — `mix verify.phase64` and release-contract guards prevent auto-advance from feeling experimental.

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

## Milestone: v1.7.0 — Blast-Radius Governance

**Shipped:** 2026-05-27
**Phases:** 4 | **Plans:** 16 | **Tasks:** 8

### What Was Built

- Pure `BlastRadiusThreshold` evaluator with fail-closed protected-environment semantics and facade `assess_audience_blast_radius/2`.
- Audience mutation change-request integration reusing `:apply_audience_mutation` on the existing governed envelope.
- Mounted governance loader, blast-radius panel, preview/confirm branching, and change-request show evidence with policy-aware visibility.
- `mix verify.phase60` merge gate, release-contract drift guards, governance flow guides, and optional `blast_radius_governance` CI scope.

### What Worked

- Reusing the v1.6 preview/dependency payloads as threshold inputs kept the milestone bounded and honest about preview basis limits.
- The four-phase split (threshold contract → change requests → mounted UX → proof/docs) mirrored v1.6 and preserved core-vs-companion boundaries.
- Frozen blast-radius metadata on change-request show plus live visibility tier on approve avoided re-assess drift while keeping policy enforcement current.

### What Was Inefficient

- No formal milestone audit artifact was produced before close (same gap as v1.6); run `/gsd-audit-milestone` before future closes when time allows.
- CLI milestone close surfaced a STATE.md field mismatch warning; planning doc formats should stay aligned with gsd-tools expectations.

### Patterns Established

- Threshold evaluation consumes authored-state preview fingerprints only — no observability-backed population counts.
- Protected-environment audience mutations branch: direct apply below threshold, change request above threshold, fail-closed when inputs are stale or unresolved.
- Governance UX reuses existing audience preview/confirm routes instead of introducing parallel admin flows.

### Key Lessons

1. Closing a safety arc (preview → dependency → governance) is faster when each layer builds on the prior milestone's contracts.
2. Change-request metadata should freeze assessment evidence at submit time; approve gates may still consult live policy visibility.
3. Support-truth phases remain essential — quickstart API parity and drift guards prevent governance features from feeling "admin-only."

### Cost Observations

- Milestone executed in a single day with 16 plans across 4 phases.
- Known deferred items at close: 3 (see STATE.md Deferred Items).

---

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
| v1.7.0 | 4 | 16 | Closed reusable-targeting safety arc with blast-radius governance via change requests |

### Cumulative Quality

| Milestone | Phase verify gates | Release-contract guards | Deferred at close |
|-----------|-------------------|-------------------------|-------------------|
| v1.5.0 | verify.phase52 | guarded rollout drift guards | 2 |
| v1.6.0 | verify.phase54–56 | reusable targeting drift guards | 4 |
| v1.7.0 | verify.phase60 | blast-radius governance drift guards | 3 |

### Top Lessons (Verified Across Milestones)

1. Support-truth and proof closure milestones pay down adopter friction before differentiated features land.
2. Core owns contracts and validation; mounted admin owns presentation — the sibling-package split scales across feature families.
3. Fail-closed validation at publish/mutation boundaries prevents broken snapshots better than post-hoc operator warnings.

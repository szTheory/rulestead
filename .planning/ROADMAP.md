# Roadmap: Rulestead

## Milestones

- **v1.7.0 - Blast-Radius Governance** — Phases 57-60 (active)
- ✅ **v1.6.0 - Reusable Targeting Deepening** — Phases 53-56 (shipped 2026-05-27)
- ✅ **v1.5.0 - Guarded Rollout Foundations** — Phases 49-52 (shipped 2026-05-27)

## Current Milestone

- **v1.7.0 - Blast-Radius Governance**: active as of 2026-05-27. Phases 57-60 close the reusable-targeting safety arc by routing high-blast-radius protected-environment audience edits through governed change requests after v1.6 preview and dependency truth are proven.

## Latest Shipped Milestone

- **v1.6.0 - Reusable Targeting Deepening**: shipped on 2026-05-27. See [.planning/milestones/v1.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-ROADMAP.md) and [.planning/milestones/v1.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-REQUIREMENTS.md).

## Phases

**Phase Numbering:**

- Integer phases (57, 58, 59, 60): Planned milestone work
- Decimal phases (57.1, 57.2): Urgent insertions, if needed

- [x] **Phase 57: Blast-Radius Threshold Contract** - Core evaluates audience mutation blast radius from v1.6 preview and dependency payloads and fails closed on missing or stale inputs. (completed 2026-05-27)
- [x] **Phase 58: Change Request Integration** - High-blast-radius audience mutations in protected environments route through the existing change-request proposal and execute envelope. (completed 2026-05-27)
- [ ] **Phase 59: Mounted Governance Workflows** - Mounted admin detects threshold breaches, routes operators through proposal/review, and preserves policy-aware fallbacks.
- [ ] **Phase 60: Proof, Docs, And Support Truth** - Verification, docs, quickstart parity, and release-contract truth close the v1.7 scope under the linked sibling-package model.

## Phase Details

### Phase 57: Blast-Radius Threshold Contract

**Goal**: Core can classify audience mutation blast radius in protected environments using preview fingerprints and dependency truth, with deterministic fail-closed semantics.
**Depends on**: Phase 56
**Requirements**: GOV-01, GOV-02, GOV-03, GOV-04
**Success Criteria** (what must be TRUE):

1. Operator-facing threshold evaluation reports reference counts, affected flags/rulesets, rollout/lifecycle hints, and breach reasons from authored-state preview payloads only.
2. Below-threshold protected-environment mutations remain eligible for direct apply with fresh preview confirmation; above-threshold mutations are blocked from direct apply with actionable threshold evidence.
3. Threshold evaluation fails closed when preview fingerprints are stale, dependency truth is unresolved, or required threshold inputs are missing.
4. Fake and Ecto store paths share one deterministic threshold contract suitable for downstream change-request routing.

**Plans**: 4 plans

### Phase 58: Change Request Integration

**Goal**: High-blast-radius audience mutations submit, approve, and execute through the existing governed change-request envelope without a parallel workflow.
**Depends on**: Phase 57
**Requirements**: CRQ-01, CRQ-02, CRQ-03
**Success Criteria** (what must be TRUE):

1. Operator can submit an audience mutation change request that embeds preview fingerprint, affected-reference summary, threshold breach context, and operation scope.
2. Approved change requests execute audience apply atomically through the governed mutation path and reject stale or drifted preview state at execution time.
3. Rejected, cancelled, or expired requests leave audience authored state unchanged and emit auditable evidence.
4. Change-request integration preserves environment and tenant scope and reuses existing approval/self-approval policy seams.

**Plans**: 4 plans

### Phase 59: Mounted Governance Workflows

**Goal**: Mounted admin routes protected-environment audience mutations through proposal and change-request review with calm operator copy and policy-aware visibility.
**Depends on**: Phase 58
**Requirements**: ADM-01, ADM-02, ADM-03
**Success Criteria** (what must be TRUE):

1. Audience edit and archive flows in protected environments detect threshold breaches and route to proposal or change-request review instead of failing opaquely or applying directly.
2. Change-request and audience surfaces show blast-radius summary, threshold reasons, preview basis limits, and remediation guidance inside the existing mounted envelope.
3. Operators without full dependency visibility see redacted or partial evidence without raw predicate leakage or unauthorized resource detail.
4. Mounted workflows do not introduce standalone-admin claims or bulk automation paths.

**Plans**: 4 plans — `59-01` governance components + loader; `59-02` preview UX; `59-03` confirm apply/submit; `59-04` CR show evidence + proof

### Phase 60: Proof, Docs, And Support Truth

**Goal**: Verification, docs, and release-contract truth describe the same bounded blast-radius governance scope and restore quickstart API parity.
**Depends on**: Phase 59
**Requirements**: VER-01, VER-02, VER-03
**Success Criteria** (what must be TRUE):

1. Repo-local proof covers threshold evaluation, change-request proposal/execute, stale-preview rejection, fail-closed behavior, and audit evidence (`mix verify.phase60` or equivalent merge gate).
2. Public docs and release-contract checks describe threshold semantics, protected-environment behavior, and host-owned policy responsibilities consistently.
3. README and getting-started teach payload-first evaluation consistent with `guides/flows/evaluation.md`.
4. Linked-version sibling-package release model and mounted-admin posture remain unchanged.

**Plans**: 4 plans (TBD via `/gsd-plan-phase 60`)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 57. Blast-Radius Threshold Contract | v1.7.0 | 4/4 | Complete    | 2026-05-27 |
| 58. Change Request Integration | v1.7.0 | 0/4 | Complete    | 2026-05-27 |
| 59. Mounted Governance Workflows | v1.7.0 | 1/4 | In Progress | — |
| 60. Proof, Docs, And Support Truth | v1.7.0 | 0/4 | Not started | — |

<details>
<summary>✅ v1.6.0 Reusable Targeting Deepening (Phases 53-56) — SHIPPED 2026-05-27</summary>

- [x] Phase 53: Impact Preview Contract (4/4 plans) — completed 2026-05-27
- [x] Phase 54: Dependency Truth And Promotion Safety (4/4 plans) — completed 2026-05-27
- [x] Phase 55: Mounted Operator Workflows (4/4 plans) — completed 2026-05-27
- [x] Phase 56: Proof, Docs, And Support Truth (4/4 plans) — completed 2026-05-27

</details>

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-ROADMAP.md), [.planning/milestones/v1.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-ROADMAP.md), [.planning/milestones/v1.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-REQUIREMENTS.md), [.planning/milestones/v1.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-REQUIREMENTS.md), [.planning/milestones/v1.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-REQUIREMENTS.md)

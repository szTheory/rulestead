# Roadmap: Rulestead

## Milestones

- **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (planning)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27) — [.planning/milestones/v1.8.0-ROADMAP.md](milestones/v1.8.0-ROADMAP.md)
- ✅ **v1.7.0 - Blast-Radius Governance** — Phases 57-60 (shipped 2026-05-27)
- ✅ **v1.6.0 - Reusable Targeting Deepening** — Phases 53-56 (shipped 2026-05-27)

## Current Milestone

**v1.9.0 - Host-Supplied Preview Evidence**

Close the reusable-targeting preview gap: hosts supply bounded sample cohorts and impression summaries through an explicit seam; mounted admin preview flows wire and render that evidence without claiming authoritative population counts or changing blast-radius governance semantics.

## Latest Shipped Milestone

- **v1.8.0 - Guarded Rollout Auto-Advance**: shipped on 2026-05-27. See [.planning/milestones/v1.8.0-ROADMAP.md](milestones/v1.8.0-ROADMAP.md) and [.planning/milestones/v1.8.0-REQUIREMENTS.md](milestones/v1.8.0-REQUIREMENTS.md).

## Phases

**Phase numbering continues at 65 (no reset).**

- [x] **Phase 65: Host Preview Evidence Contract** — Core defines host-owned resolver seam, bounded sample/impression payloads, redaction, and deterministic fingerprinting with evidence present. (completed 2026-05-27)
- [ ] **Phase 66: Evidence Carry-Through And Governance Boundary** — Audit and change-request payloads carry support-safe evidence summaries; blast-radius thresholds remain reference-count based.
- [ ] **Phase 67: Mounted Preview Evidence Workflows** — Mounted audience preview flows resolve, render, and fail closed on host-supplied evidence inside the existing preview-confirm-audit envelope.
- [ ] **Phase 68: Proof, Docs, And Support Truth** — Verification, host seam docs, release-contract truth, and MAINTAINING drift fixes close bounded preview-evidence support claims.

## Phase Details

### Phase 65: Host Preview Evidence Contract

**Goal**: Core accepts bounded host-supplied sample cohorts and impression summaries through an explicit resolver behavior with redaction, preview basis, uncertainty, and deterministic fingerprints that include evidence metadata.
**Depends on**: Phase 64
**Requirements**: IMP-05, IMP-06
**Success Criteria** (what must be TRUE):

1. Host can configure a preview evidence resolver that returns bounded sample cohorts and/or impression summaries scoped to environment, tenant, and audience context.
2. Impact preview payloads declare explicit preview basis, uncertainty, and redacted sample/impression evidence without claiming authoritative population counts.
3. Preview fingerprints change deterministically when host evidence changes and stale-token validation rejects drifted evidence the same way as authored-state drift.
4. Invalid, oversized, or policy-denied host evidence fails closed with actionable errors; Fake and Ecto paths share one contract.

**Plans**: 4 plans

| Plan | Wave | Deliverable |
|------|------|-------------|
| [65-01](phases/65-host-preview-evidence-contract/65-01-PLAN.md) | 1 | `PreviewEvidence` behaviour, limits validator, unit tests |
| [65-02](phases/65-host-preview-evidence-contract/65-02-PLAN.md) | 2 | `ImpactPreview` schema v2, impression fingerprint |
| [65-03](phases/65-host-preview-evidence-contract/65-03-PLAN.md) | 3 | Fake/Ecto `audience_preview_payload` wiring + test resolver |
| [65-04](phases/65-host-preview-evidence-contract/65-04-PLAN.md) | 4 | Contract tests: stale, fail-closed, adapter parity, GOV boundary |

### Phase 66: Evidence Carry-Through And Governance Boundary

**Goal**: Audit and change-request surfaces carry support-safe preview evidence summaries; blast-radius governance ignores impression summaries and remains reference-count based.
**Depends on**: Phase 65
**Requirements**: IMP-07, GOV-05
**Success Criteria** (what must be TRUE):

1. Accepted, blocked, and change-request audience mutations include preview evidence basis and bounded redacted summary metadata in audit payloads.
2. Change-request review surfaces frozen preview evidence summaries sufficient for support reconstruction without raw trait leakage.
3. Protected-environment blast-radius threshold evaluation uses reference counts only—not impression summaries or cohort sizes—for governance routing.
4. Regression proof shows GOV-01/v1.7 governance behavior unchanged when richer preview evidence is present.

**Plans**: 4 plans (typical)

### Phase 67: Mounted Preview Evidence Workflows

**Goal**: Mounted admin audience preview flows resolve host-supplied evidence when configured and render honest uncertainty copy without widening the admin product shape.
**Depends on**: Phase 66
**Requirements**: ADM-05
**Success Criteria** (what must be TRUE):

1. Audience edit, archive, and delete preview routes request host evidence through the resolver seam when the host configures it.
2. Preview UI renders sample cohort and impression summary evidence with support-safe copy when present; shows explicit fallback when host evidence is unavailable.
3. Confirm and governance paths preserve preview fingerprints and evidence basis through the existing preview-confirm-audit workflow.
4. Mounted surfaces do not imply Rulestead-owned observability, population analytics, or fleet dashboards.

**Plans**: 4 plans (typical)

### Phase 68: Proof, Docs, And Support Truth

**Goal**: Verification, docs, host seam guidance, and release-contract truth describe the same bounded preview-evidence scope under the linked sibling-package model.
**Depends on**: Phase 67
**Requirements**: VER-01, VER-02, VER-03
**Success Criteria** (what must be TRUE):

1. Repo-local proof covers resolver wiring, redaction, fingerprint determinism, stale rejection with evidence, governance boundary, and mounted rendering (`mix verify.phase68` or equivalent merge gate).
2. Host-app integration seam docs include a bounded preview-evidence subsection; `MAINTAINING.md` mounted proof file list matches CI/release-contract paths.
3. Release-contract and public docs allow bounded host-supplied preview evidence claims only where implemented and retain forbidden overclaim phrases for population counts and observability ownership.
4. Linked-version sibling-package release model and mounted-admin posture remain unchanged.

**Plans**: 4 plans (typical)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 65. Host Preview Evidence Contract | v1.9.0 | 4/4 | Complete    | 2026-05-27 |
| 66. Evidence Carry-Through And Governance Boundary | v1.9.0 | 0/4 | Not started | — |
| 67. Mounted Preview Evidence Workflows | v1.9.0 | 0/4 | Not started | — |
| 68. Proof, Docs, And Support Truth | v1.9.0 | 0/4 | Not started | — |

<details>
<summary>✅ v1.8.0 Guarded Rollout Auto-Advance (Phases 61-64) — SHIPPED 2026-05-27</summary>

- [x] Phase 61: Auto-Advance Authored Contract (4/4 plans) — completed 2026-05-27
- [x] Phase 62: Orchestration And Governed Execution (4/4 plans) — completed 2026-05-27
- [x] Phase 63: Mounted Auto-Advance Workflows (4/4 plans) — completed 2026-05-27
- [x] Phase 64: Proof, Docs, And Support Truth (4/4 plans) — completed 2026-05-27

</details>

<details>
<summary>✅ v1.7.0 Blast-Radius Governance (Phases 57-60) — SHIPPED 2026-05-27</summary>

- [x] Phase 57: Blast-Radius Threshold Contract (4/4 plans) — completed 2026-05-27
- [x] Phase 58: Change Request Integration (4/4 plans) — completed 2026-05-27
- [x] Phase 59: Mounted Governance Workflows (4/4 plans) — completed 2026-05-27
- [x] Phase 60: Proof, Docs, And Support Truth (4/4 plans) — completed 2026-05-27

</details>

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](milestones/v1.4.0-ROADMAP.md), [.planning/milestones/v1.5.0-ROADMAP.md](milestones/v1.5.0-ROADMAP.md), [.planning/milestones/v1.6.0-ROADMAP.md](milestones/v1.6.0-ROADMAP.md), [.planning/milestones/v1.7.0-ROADMAP.md](milestones/v1.7.0-ROADMAP.md), [.planning/milestones/v1.8.0-ROADMAP.md](milestones/v1.8.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](milestones/v1.4.0-REQUIREMENTS.md), [.planning/milestones/v1.5.0-REQUIREMENTS.md](milestones/v1.5.0-REQUIREMENTS.md), [.planning/milestones/v1.6.0-REQUIREMENTS.md](milestones/v1.6.0-REQUIREMENTS.md), [.planning/milestones/v1.7.0-REQUIREMENTS.md](milestones/v1.7.0-REQUIREMENTS.md), [.planning/milestones/v1.8.0-REQUIREMENTS.md](milestones/v1.8.0-REQUIREMENTS.md)

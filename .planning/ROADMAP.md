# Roadmap

## Current Milestone

- **v1.5.0 - Guarded Rollout Foundations**: activated on 2026-05-26 across Phases 49-52.

## Overview

`v1.5.0` adds bounded guarded-rollout safety on top of the repaired sibling-package support surface: host apps provide normalized rollout signals, `rulestead` evaluates explicit hold and rollback decisions fail closed, and `rulestead_admin` explains those decisions inside the existing mounted rollout workflow without becoming an observability product.

## Phases

### Phase 49: Guardrail Signal Contract

**Goal**: Define the host-owned rollout-signal seam, authored-state contract, and explicit threshold semantics without widening package boundaries.
**Depends on**: Phase 48
**Plans**: 3 plans
**Requirements**: `ROL-01`

Plans:
- [x] `49-01-PLAN.md` - Freeze the host-owned signal seam and normalized fail-closed vocabulary
- [x] `49-02-PLAN.md` - Attach typed guardrail definitions to authored rollout state
- [x] `49-03-PLAN.md` - Reclose scope, audit, compare, and export proof for the guardrail contract

Success criteria:
1. Rollout stages can attach one or more host-supplied guardrail definitions with explicit threshold, freshness, and sample-size semantics.
2. The runtime and authored-state contracts preserve explicit environment and tenant scope for every signal query.
3. Missing or unsupported signal providers fail closed with bounded operator-facing reasons instead of implied health.

### Phase 50: Guarded Decision Engine & Audit

**Goal**: Evaluate staged monitoring windows and trigger deterministic hold or rollback behavior through the existing governed mutation and audit envelope.
**Depends on**: Phase 49
**Plans**: 1 plan
**Requirements**: `ROL-02`, `ROL-03`, `AUD-01`, `AUD-02`

Plans:
- [x] `50-01-PLAN.md` - Implement guarded rollout decision engine and audit-backed hold/rollback actions

Success criteria:
1. Stage advancement and monitoring windows evaluate normalized signal facts into explicit decision states such as `healthy`, `pending_data`, `held`, and `rollback_triggered`.
2. Weak, stale, or insufficient signal data blocks automation rather than assuming healthy rollout progression.
3. Automatic hold and rollback actions preserve sticky rollout semantics and restore a stable prior state without introducing time-based user routing.
4. Audit history records the breached signals, thresholds, evidence snapshot, actor or source, and resulting action for every guardrail decision.

### Phase 51: Mounted Guardrail Workflow

**Goal**: Surface guardrail health, thresholds, and intervention reasons inside the mounted rollout experience without implying standalone-admin or fleet-observability scope.
**Depends on**: Phase 50
**Plans**: 2 plans
**Requirements**: `ADM-01`

Plans:
- [x] `51-01-PLAN.md` - Add mounted rollout guardrail status and preserve authored guardrails
- [x] `51-02-PLAN.md` - Distinguish automatic guardrail interventions in timeline surfaces

Success criteria:
1. Mounted rollout screens show per-stage guardrail status, freshness, and threshold summaries in the existing workflow.
2. Operators can distinguish manual actions from automatic hold or rollback events from the same timeline and stage detail surfaces.
3. Missing-data and fail-closed states explain what prerequisite or host signal is absent without pretending the stage is healthy.

### Phase 52: Proof, Docs & Milestone Closure

**Goal**: Reclose support truth for guarded rollout foundations with bounded proof, docs, and traceability before wider rollout automation is considered.
**Depends on**: Phase 51
**Plans:** 2 plans
**Requirements**: `VER-01`

Plans:
- [x] `52-01-PLAN.md` - Build bounded guarded rollout proof bar and support-truth docs
- [x] `52-02-PLAN.md` - Write verification artifact and reconcile planning truth

Success criteria:
1. Repo-local verification covers stale-signal, insufficient-sample, hold, rollback, and bounded host-seam behavior.
2. Root and package docs describe the host-owned metrics seam, fail-closed behavior, and current support limits consistently.
3. Requirement traceability, planning truth, and milestone verification agree on the bounded guarded-rollout support surface.

## Requirement Coverage

| Requirement | Phase | Status |
|-------------|-------|--------|
| ROL-01 | Phase 49 | Complete |
| ROL-02 | Phase 50 | Complete |
| ROL-03 | Phase 50 | Complete |
| AUD-01 | Phase 50 | Complete |
| AUD-02 | Phase 50 | Complete |
| ADM-01 | Phase 51 | Complete |
| VER-01 | Phase 52 | Complete |

**Coverage:**
- Milestone requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0

## Current Status

- Phase 49 guardrail signal contract is complete.
- Phase 50 guarded decision engine and audit path is complete in commit `c4dd3fb`.
- Phase 51 mounted rollout guardrail status and timeline intervention distinction are complete.
- Phase 52 guarded rollout proof, docs, and traceability closure are complete; v1.5.0 is ready_for_closeout.
- Phase 52 verification evidence is recorded in 52-VERIFICATION.md.
- `v1.6.0 - Reusable Targeting Deepening` remains the next queued candidate after guarded rollout foundations.

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-REQUIREMENTS.md)

## Next Step

Next: Run the standard milestone closeout workflow for v1.5.0; do not archive from Phase 52 itself.

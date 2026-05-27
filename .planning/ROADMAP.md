# Roadmap: Rulestead

## Milestones

- **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (active)
- ✅ **v1.7.0 - Blast-Radius Governance** — Phases 57-60 (shipped 2026-05-27)
- ✅ **v1.6.0 - Reusable Targeting Deepening** — Phases 53-56 (shipped 2026-05-27)
- ✅ **v1.5.0 - Guarded Rollout Foundations** — Phases 49-52 (shipped 2026-05-27)

## Current Milestone

- **v1.8.0 - Guarded Rollout Auto-Advance**: active as of 2026-05-27. Phases 61-64 complete the guarded rollout story by orchestrating governed stage advancement when host-supplied guardrails remain healthy for a configured observation window.

## Latest Shipped Milestone

- **v1.7.0 - Blast-Radius Governance**: shipped on 2026-05-27. See [.planning/milestones/v1.7.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-ROADMAP.md) and [.planning/milestones/v1.7.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-REQUIREMENTS.md).

## Phases

**Phase Numbering:**

- Integer phases (61, 62, 63, 64): Planned milestone work
- Decimal phases (61.1, 61.2): Urgent insertions, if needed

- [ ] **Phase 61: Auto-Advance Authored Contract** - Core defines opt-in auto-advance policy, explicit next-stage plan metadata, and fail-closed evaluation semantics on top of v1.5 guardrails.
- [ ] **Phase 62: Orchestration And Governed Execution** - Observation-window ticks schedule guardrail evaluation and governed `advance_rollout` with idempotency and protected-env parity.
- [ ] **Phase 63: Mounted Auto-Advance Workflows** - Mounted admin exposes toggle, pending observation, and automation-vs-manual timeline distinction inside the existing rollout envelope.
- [ ] **Phase 64: Proof, Docs, And Support Truth** - Verification, host seam docs, and release-contract truth close bounded auto-advance support claims.

## Phase Details

### Phase 61: Auto-Advance Authored Contract

**Goal**: Core can represent opt-in auto-advance policy with observation window and explicit next-stage plan, evaluating fail-closed on top of existing guardrail semantics without widening package boundaries.
**Depends on**: Phase 60
**Requirements**: ROL-04, ROL-05, ROL-07
**Success Criteria** (what must be TRUE):

1. Operator can enable or disable auto-advance per staged rollout with a configured observation window and authored next-stage plan—not only UI ladder suggestions.
2. Pure policy evaluation advances only when all guardrails resolve `:healthy` after the window closes; `:pending_data`, `:held`, stale, weak, or missing signals block advancement with explicit reasons.
3. v1.5 automatic hold and rollback behavior remains unchanged when auto-advance is enabled or disabled.
4. Fake and Ecto store paths share one deterministic auto-advance policy contract suitable for downstream orchestration.

**Plans**: 4 plans (typical)

### Phase 62: Orchestration And Governed Execution

**Goal**: Observation-window close schedules guardrail evaluation and executes governed `advance_rollout` through the existing `ScheduledExecution` envelope with idempotency and protected-environment governance parity.
**Depends on**: Phase 61
**Requirements**: ROL-06, ORC-01, ORC-02, AUD-03
**Success Criteria** (what must be TRUE):

1. Closing an observation window enqueues an evaluation tick through `ScheduledExecution` / the existing Oban worker pattern—not a parallel mutation path.
2. Healthy guardrails trigger governed `advance_rollout` with auditable `guardrail_automation` evidence including guardrail facts and window context.
3. Protected environments requiring governed advancement route auto-advance through the same change-request and approval envelope as manual advance.
4. Duplicate ticks, manual advance, rollback, or hold races do not double-advance or leave authored state inconsistent.

**Plans**: 4 plans (typical)

### Phase 63: Mounted Auto-Advance Workflows

**Goal**: Mounted admin lets operators configure auto-advance, see pending observation state, and distinguish automation from manual actions without implying observability ownership.
**Depends on**: Phase 62
**Requirements**: ADM-04, AUD-04
**Success Criteria** (what must be TRUE):

1. Rollout detail surfaces expose auto-advance toggle, observation-window duration, and pending-observation state with calm operator copy.
2. When prerequisites or guardrail health block automation, mounted UI shows bounded remediation guidance instead of implying healthy fleet state.
3. Timeline and audit excerpts distinguish `guardrail_automation` from manual rollout actions with existing policy-aware redaction.
4. Mounted workflows do not introduce standalone-admin claims, fleet dashboards, or Rulestead-owned metrics surfaces.

**Plans**: 4 plans (typical)

### Phase 64: Proof, Docs, And Support Truth

**Goal**: Verification, docs, host seam guidance, and release-contract truth describe the same bounded auto-advance scope under the linked sibling-package model.
**Depends on**: Phase 63
**Requirements**: VER-01, VER-02, VER-03
**Success Criteria** (what must be TRUE):

1. Repo-local proof covers healthy auto-advance, fail-closed non-advance, protected-env governance, idempotency races, and stale-signal behavior (`mix verify.phase64` or equivalent merge gate).
2. Host-app integration seam docs include a bounded auto-advance subsection; metrics remain host-owned.
3. Release-contract and public docs allow bounded auto-advance claims only where implemented and retain forbidden overclaim phrases for observability and time-based rollout.
4. Linked-version sibling-package release model and mounted-admin posture remain unchanged.

**Plans**: 4 plans (typical)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 61. Auto-Advance Authored Contract | v1.8.0 | 0/4 | Planned | — |
| 62. Orchestration And Governed Execution | v1.8.0 | 0/4 | Not started | — |
| 63. Mounted Auto-Advance Workflows | v1.8.0 | 0/4 | Not started | — |
| 64. Proof, Docs, And Support Truth | v1.8.0 | 0/4 | Not started | — |

<details>
<summary>✅ v1.7.0 Blast-Radius Governance (Phases 57-60) — SHIPPED 2026-05-27</summary>

- [x] Phase 57: Blast-Radius Threshold Contract (4/4 plans) — completed 2026-05-27
- [x] Phase 58: Change Request Integration (4/4 plans) — completed 2026-05-27
- [x] Phase 59: Mounted Governance Workflows (4/4 plans) — completed 2026-05-27
- [x] Phase 60: Proof, Docs, And Support Truth (4/4 plans) — completed 2026-05-27

</details>

## Milestone Archives

- Roadmaps: [.planning/milestones/v0.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-ROADMAP.md), [.planning/milestones/v0.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-ROADMAP.md), [.planning/milestones/v0.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-ROADMAP.md), [.planning/milestones/v0.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-ROADMAP.md), [.planning/milestones/v0.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-ROADMAP.md), [.planning/milestones/v0.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-ROADMAP.md), [.planning/milestones/v1.0.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-ROADMAP.md), [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md), [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md), [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md), [.planning/milestones/v1.4.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-ROADMAP.md), [.planning/milestones/v1.5.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-ROADMAP.md), [.planning/milestones/v1.6.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-ROADMAP.md), [.planning/milestones/v1.7.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-ROADMAP.md)
- Requirements: [.planning/milestones/v0.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.1.0-REQUIREMENTS.md), [.planning/milestones/v0.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.2.0-REQUIREMENTS.md), [.planning/milestones/v0.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.3.0-REQUIREMENTS.md), [.planning/milestones/v0.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.4.0-REQUIREMENTS.md), [.planning/milestones/v0.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.5.0-REQUIREMENTS.md), [.planning/milestones/v0.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v0.6.0-REQUIREMENTS.md), [.planning/milestones/v1.0.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.0.0-REQUIREMENTS.md), [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), [.planning/milestones/v1.2.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-REQUIREMENTS.md), [.planning/milestones/v1.3.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-REQUIREMENTS.md), [.planning/milestones/v1.4.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.4.0-REQUIREMENTS.md), [.planning/milestones/v1.5.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.5.0-REQUIREMENTS.md), [.planning/milestones/v1.6.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.6.0-REQUIREMENTS.md), [.planning/milestones/v1.7.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.7.0-REQUIREMENTS.md)

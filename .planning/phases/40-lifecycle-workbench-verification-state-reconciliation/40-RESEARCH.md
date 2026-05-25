# Phase 40: Lifecycle Workbench Verification & State Reconciliation - Research

**Researched:** 2026-05-24
**Domain:** Verification-closure planning for the mounted lifecycle workbench and milestone-state reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Phase boundary
- Phase 40 exists to close the remaining `LIF-03` and `LIF-04` audit gaps by writing the missing Phase 37 verification artifact and reconciling active planning state from that evidence. [VERIFIED: roadmap] [VERIFIED: context]
- The missing deliverables are evidence and traceability artifacts, not new lifecycle product scope. Planning should treat any code changes as regression-repair only if fresh reruns fail. [VERIFIED: milestone audit] [VERIFIED: context]
- Milestone closeout language should only advance after the new Phase 37 evidence exists and Phase 37 summary/frontmatter drift is corrected. [VERIFIED: roadmap] [VERIFIED: requirements] [VERIFIED: milestone audit]

### the agent's Discretion
- Exact section names for `37-VERIFICATION.md`, provided the report remains evidence-backed and reproducible.
- Exact wording for roadmap/state closeout readiness once `LIF-03` and `LIF-04` are evidenced.

### Deferred Ideas (OUT OF SCOPE)
- New lifecycle UI, archive-flow behavior, or core `rulestead/` implementation work beyond regression repair triggered by failing verification
- Any `rulestead_admin` publishing or standalone-control-plane preparation
- Future milestone planning beyond routing to the normal milestone-closeout path
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-03 | Operators can review lifecycle and cleanup posture through shareable admin filters and CLI/reporting surfaces that highlight owner, lifecycle state, last evaluated, code-reference status, and recommended next action. | Close the mounted lifecycle queue/detail/cleanup evidence chain with a Phase 37 verification report tied to the existing targeted LiveView suites and route/state artifacts. [VERIFIED: requirements] [VERIFIED: 37 validation] |
| LIF-04 | Archive and cleanup flows stay explicit, previewable, and audited; Rulestead never auto-archives flags and never hides uncertainty behind false precision. | Prove the queue -> cleanup review -> preview -> confirm -> queue-return flow from current tests and checked-in implementation, then update milestone traceability only after that proof exists. [VERIFIED: requirements] [VERIFIED: 37 validation] |
</phase_requirements>

## Project Constraints

- Treat `.planning/` as the active source of truth for roadmap, requirements, milestone audit, and state routing. [VERIFIED: AGENTS.md]
- Respect the linked-version sibling-package monorepo and keep `rulestead_admin` as a mounted sibling package rather than a publish-ready stub. [VERIFIED: AGENTS.md]
- Keep the smallest coherent change inside the active phase boundary. [VERIFIED: AGENTS.md]

## Summary

Phase 40 should be planned as the mirror image of Phase 39: reconstruct the missing phase-level verification artifact for already-shipped work, correct local traceability drift inside the originating phase, then reconcile milestone-facing docs so the active planning state finally matches reality. The milestone audit is explicit about the blocker. Phase 37 implemented the lifecycle queue, cleanup review, preview, confirm, and queue-return behaviors, and dedicated tests already exist, but there is no `37-VERIFICATION.md` proving those behaviors end to end. [VERIFIED: milestone audit] [VERIFIED: 37 validation] [VERIFIED: 37 summaries]

The second planning concern is traceability drift inside Phase 37 itself. `37-02-SUMMARY.md` frontmatter currently claims `requirements-completed: [LIF-05]`, which conflicts with both the Phase 37 plans and the active milestone requirements. `37-01-SUMMARY.md` also claims both `LIF-03` and `LIF-04` complete even though the archive preview/confirm closure belongs to the second plan. Phase 40 should correct that mapping so the per-plan summaries align naturally with the final phase verification report. [VERIFIED: milestone audit] [VERIFIED: 37 plans] [VERIFIED: 37 summaries]

The final planning concern is milestone-state reconciliation. Once `37-VERIFICATION.md` exists and the Phase 37 summary mapping is corrected, `REQUIREMENTS.md`, `v1.2.0-MILESTONE-AUDIT.md`, `ROADMAP.md`, and `STATE.md` should all move in lockstep: `LIF-03` and `LIF-04` become complete, Phase 37 becomes verified, Phase 40 becomes the executed closure phase for that evidence, and the milestone becomes ready for closeout rather than still blocked on missing verification. [VERIFIED: roadmap] [VERIFIED: requirements] [VERIFIED: state] [VERIFIED: milestone audit]

No new production code should be planned unless the fresh targeted reruns expose a regression. The dominant path is: verify what Phase 37 already delivered, fix the traceability metadata around those deliveries, then update milestone docs to consume that new evidence honestly. [VERIFIED: context] [VERIFIED: 37 validation]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 40 | Why |
|---------|-----------------------------|-----|
| `.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md` | Create the missing verification artifact from present implementation, Phase 37 planning docs, and fresh reruns | This is the direct blocker called out by the milestone audit. [VERIFIED: milestone audit] |
| `.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md` and `37-02-SUMMARY.md` | Correct per-plan requirement mapping so summary frontmatter matches the actual two-wave delivery split | Phase-local drift should be fixed before milestone docs rely on it. [VERIFIED: milestone audit] |
| `.planning/REQUIREMENTS.md` | Mark `LIF-03` and `LIF-04` complete under Phase 40 closure once evidence exists | Active requirements must reflect verification-backed truth. [VERIFIED: requirements] |
| `.planning/v1.2.0-MILESTONE-AUDIT.md` | Replace the “Phase 37 unverified” findings with the new verification-backed status and ready-for-closeout posture | The audit is the milestone truth source for readiness. [VERIFIED: milestone audit] |
| `.planning/ROADMAP.md` and `.planning/STATE.md` | Record Phase 40 completion and route the next step toward milestone closeout rather than another lifecycle verification pass | Current planning state still points at unresolved closure work. [VERIFIED: roadmap] [VERIFIED: state] |

## Standard Stack

### Core evidence sources
- `.planning/phases/37-mounted-admin-lifecycle-workbench/37-VALIDATION.md` for expected truths, task coverage, and exact targeted commands. [VERIFIED: 37 validation]
- `.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md` and `37-02-SUMMARY.md` for the delivered Phase 37 narrative. [VERIFIED: 37 summaries]
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md`, `.planning/phases/36-archive-readiness-signals-cleanup-analysis/36-VERIFICATION.md`, and `.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md` as current verification-report analogs. [VERIFIED: phase docs]

### Verification commands
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
- `rg -n "requirements-completed|LIF-03|LIF-04|LIF-05" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-02-SUMMARY.md`

These are the narrowest current checks that cover the entire Phase 37 route/state contract plus the known traceability typo. [VERIFIED: 37 validation] [VERIFIED: milestone audit]

## Recommended Shape

### Pattern 1: Verification artifact first, traceability second
Write `37-VERIFICATION.md` before changing milestone docs. Requirements and milestone-state updates should point at that artifact instead of reusing summary prose as substitute proof. [VERIFIED: milestone audit] [VERIFIED: 39 closure pattern]

### Pattern 2: Correct phase-local mapping before milestone-wide mapping
Fix `37-01-SUMMARY.md` and `37-02-SUMMARY.md` frontmatter before closing `LIF-03`/`LIF-04` in the active milestone docs. This keeps the evidence chain internally consistent from plan summaries to phase verification to milestone traceability. [VERIFIED: milestone audit]

### Pattern 3: Use one verification wave
All targeted Phase 37 suites already exist. One fresh rerun plus the resulting verification artifact should be enough to close both requirements and the full queue-return operator flow. [VERIFIED: 37 validation]

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| The Phase 37 LiveView suite may now fail against current code | Task 1 must explicitly allow stopping for regression repair rather than inventing a passing verification report. |
| Summary frontmatter drift may cause the milestone audit to remain internally inconsistent | Task 2 should normalize plan-level `requirements-completed` values before updating active milestone docs. |
| State docs may jump directly to “milestone complete” wording before normal closeout runs | Task 3 should say “ready for closeout” and route to the standard milestone workflow rather than claiming shipment. |

## Validation Architecture

Phase 40 should use one wave with three automated proof points:

1. A targeted Phase 37 LiveView suite rerun plus file-content checks proving `37-VERIFICATION.md` exists and certifies the mounted lifecycle queue-to-archive-return flow.
2. A phase-local traceability pass checking `37-01-SUMMARY.md` and `37-02-SUMMARY.md` map to the intended requirement split rather than the known typo.
3. An active-doc integrity pass checking `REQUIREMENTS.md`, `v1.2.0-MILESTONE-AUDIT.md`, `ROADMAP.md`, and `STATE.md` all reflect the same post-closure truth: `LIF-03`/`LIF-04` evidenced, Phase 37 verified, and the milestone ready for closeout.

No Wave 0 scaffold is needed because the Phase 37 suites and planning artifacts already exist. [VERIFIED: 37 validation]

## Recommended Slice Boundary

### Slice 1
Create `37-VERIFICATION.md` from Phase 37 evidence and fresh reruns.

### Slice 2
Correct per-plan Phase 37 summary requirement mapping so the evidence chain is internally consistent.

### Slice 3
Update active milestone docs so they consume the new evidence honestly and route the next action toward milestone closeout.

## Confidence

- Architecture: HIGH - the phase only closes missing evidence and traceability around already-shipped mounted lifecycle behavior. [VERIFIED: roadmap] [VERIFIED: milestone audit]
- Verification: HIGH - Phase 37 already defined exact targeted commands and requirement coverage in `37-VALIDATION.md`. [VERIFIED: 37 validation]
- Scope control: HIGH - the roadmap and context both constrain this phase to evidence and state reconciliation, not new product work. [VERIFIED: roadmap] [VERIFIED: context]

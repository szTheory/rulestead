# Phase 39: Lifecycle Contract Verification Closure - Research

**Researched:** 2026-05-24
**Domain:** Verification-closure planning for authored ownership/lifecycle evidence and milestone traceability reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Phase boundary
- Phase 39 exists to close the `LIF-01` evidence gap around Phase 35 without widening scope into new lifecycle behavior, UI expansion, or Phase 40 work. [VERIFIED: roadmap] [VERIFIED: context]
- The missing deliverable is a Phase 35 verification artifact, not additional product code. Planning should treat this as evidence closure plus documentation reconciliation. [VERIFIED: milestone audit] [VERIFIED: context]
- The milestone must stay honest after this phase: `LIF-01` can close, but `LIF-03` and `LIF-04` remain blocked on Phase 37 evidence and Phase 40 follow-through. [VERIFIED: milestone audit] [VERIFIED: requirements]

### the agent's Discretion
- Exact verification-report section names, provided the report stays evidence-backed and reproducible.
- Exact wording for milestone traceability updates, provided Phase 39 closes `LIF-01` without implying the whole `v1.2.0` milestone is done.

### Deferred Ideas (OUT OF SCOPE)
- New ownership/lifecycle implementation work in `rulestead/` or `rulestead_admin/`
- Phase 37 archive-workbench verification closure
- Milestone-closeout claims that depend on `LIF-03` or `LIF-04`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-01 | Flags expose first-class ownership and lifecycle metadata that remain explicit across authored-state reads, writes, audit events, and mounted-admin presentation without creating a Rulestead-owned identity directory. | Close the missing Phase 35 verification artifact from existing implementation evidence and rerunnable targeted suites, then reconcile active milestone traceability docs so `LIF-01` is recorded as evidenced without overstating milestone completion. [VERIFIED: requirements] [VERIFIED: milestone audit] |
</phase_requirements>

## Project Constraints

- Treat `.planning/` as the active source of truth for roadmap, state, milestone audit, and requirement routing. [VERIFIED: AGENTS.md]
- Respect the linked-version sibling-package monorepo shape and do not publish or broaden the `rulestead_admin` stub. [VERIFIED: AGENTS.md]
- Keep changes as small coherent closure work inside the active phase boundary. [VERIFIED: AGENTS.md]

## Summary

Phase 39 should be planned as a documentation-and-evidence closure pass, not as another implementation wave. The milestone audit already identifies the real blocker precisely: Phase 35 shipped the ownership/lifecycle contract and recorded targeted test commands in `35-VALIDATION.md` plus `35-01-SUMMARY.md` and `35-02-SUMMARY.md`, but there is no `35-VERIFICATION.md` proving the contract end to end. The plan therefore needs to reconstruct that missing verification report from current checked-in code and fresh reruns of the targeted Phase 35 suites. [VERIFIED: milestone audit] [VERIFIED: 35 validation] [VERIFIED: 35 summaries]

The second planning concern is traceability drift. Active docs currently say two different things: `REQUIREMENTS.md` maps `LIF-01` to Phase 39 and leaves it pending, while the milestone audit says the implementation exists but lacks verification. Once `35-VERIFICATION.md` exists, the active planning docs should be updated so `LIF-01` is explicitly backed by evidence, the audit gap for Phase 35 is closed, and the milestone remains not-ready because Phase 37 evidence is still missing. [VERIFIED: requirements] [VERIFIED: milestone audit] [VERIFIED: roadmap] [VERIFIED: state]

No new production code should be part of this plan unless the fresh Phase 35 reruns expose a real regression. The dominant path is: verify the shipped Phase 35 contract, write the missing artifact, then tighten roadmap/requirements/state/audit wording to match the newly-evidenced truth. That keeps Phase 39 narrow and leaves Phase 40 to close the remaining mounted-workbench gap. [VERIFIED: roadmap] [VERIFIED: context]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 39 | Why |
|---------|-----------------------------|-----|
| `.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md` | Reconstruct the missing verification artifact from present code, Phase 35 planning artifacts, and fresh command output | This is the direct blocker called out by the milestone audit. [VERIFIED: milestone audit] |
| `.planning/REQUIREMENTS.md` | Mark `LIF-01` complete under the Phase 39 closure phase once evidence exists | Active requirements must reflect real evidence instead of stale pending status. [VERIFIED: requirements] |
| `.planning/v1.2.0-MILESTONE-AUDIT.md` | Replace the “Phase 35 unverified” finding with the new verification-backed status while preserving the remaining Phase 37 gap | The audit is the milestone truth source for readiness. [VERIFIED: milestone audit] |
| `.planning/ROADMAP.md` and `.planning/STATE.md` | Route next-step and status language away from stale Phase 38 verification and toward the remaining lifecycle closure work | Current state still points at Phase 38 verification even though the roadmap already says Phase 39 is next. [VERIFIED: roadmap] [VERIFIED: state] |

## Standard Stack

### Core evidence sources
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-VALIDATION.md` for the expected truths, task map, and targeted commands. [VERIFIED: 35 validation]
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-01-SUMMARY.md` and `35-02-SUMMARY.md` for the delivered Phase 35 narrative. [VERIFIED: 35 summaries]
- `.planning/phases/36-archive-readiness-signals-cleanup-analysis/36-VERIFICATION.md` and `.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md` as current verification-report shape analogs. [VERIFIED: phase docs]

### Verification commands
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/show_test.exs`

These are the narrowest combined reruns that cover the Phase 35 contract across authored writes, adapter parity, audit summaries, mounted authoring, and mounted detail projection. [VERIFIED: 35 validation]

## Recommended Shape

### Pattern 1: Verification artifact first, traceability second
Write `35-VERIFICATION.md` before changing milestone docs. The requirements/audit/state updates should cite the verification artifact rather than repeating unevidenced summary claims. [VERIFIED: milestone audit] [VERIFIED: 34 summary/verification pattern]

### Pattern 2: Use fresh reruns, not historical inference
The verification report should cite current command results and checked-in source references. If the targeted reruns fail, Phase 39 becomes regression-repair work rather than paperwork. [VERIFIED: 34 plan] [VERIFIED: 36 verification]

### Pattern 3: Close only `LIF-01`
When reconciling active docs, keep the milestone explicitly incomplete. Phase 39 closes the authored ownership/lifecycle contract evidence path only; mounted lifecycle workbench evidence stays open for Phase 40. [VERIFIED: roadmap] [VERIFIED: milestone audit]

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| The Phase 35 suites may now fail against current code | Task 1 must explicitly allow stopping for regression repair rather than fabricating a verification report. |
| Traceability docs may drift into claiming the whole milestone is done | Task 2 must hard-code that only `LIF-01` closes here and that Phase 37 remains the blocker. |
| Reconstructed verification could duplicate plan-summary prose instead of proving behavior | The plan should require observable truths, commands run, and requirement traceability in the verification artifact. |

## Validation Architecture

Phase 39 should use one wave with two automated proof points:

1. A targeted Phase 35 suite rerun plus file-integrity checks that prove `35-VERIFICATION.md` exists and contains `LIF-01`, the required test modules, and a verification score.
2. A planning-doc integrity pass that checks `REQUIREMENTS.md`, `v1.2.0-MILESTONE-AUDIT.md`, `ROADMAP.md`, and `STATE.md` all reflect the same post-closure truth: `LIF-01` evidenced, milestone still awaiting the Phase 37/40 closure path.

No Wave 0 scaffold is needed because the Phase 35 suites, summaries, and validation strategy already exist. [VERIFIED: 35 validation] [VERIFIED: phase docs]

## Recommended Slice Boundary

### Slice 1
Create `35-VERIFICATION.md` from Phase 35 evidence and fresh reruns.

### Slice 2
Update active milestone traceability docs so they consume that evidence honestly and route the next action toward the remaining lifecycle closure work.

## Confidence

- Architecture: HIGH - the phase only closes missing evidence and traceability around already-shipped work. [VERIFIED: roadmap] [VERIFIED: milestone audit]
- Verification: HIGH - Phase 35 already defined exact targeted commands and required truths in `35-VALIDATION.md`. [VERIFIED: 35 validation]
- Scope control: HIGH - the roadmap and context both constrain this phase to `LIF-01` closure only. [VERIFIED: roadmap] [VERIFIED: context]

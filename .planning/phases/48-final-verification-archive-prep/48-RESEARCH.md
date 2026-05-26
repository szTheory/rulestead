# Phase 48: Final Verification & Archive Prep - Research

**Researched:** 2026-05-26
**Domain:** Milestone-closeout verification, evidence-backed traceability reconciliation, and ready-for-closeout planning truth for the mounted companion proof milestone
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions
- Preserve the linked-version, two-package monorepo model centered on `rulestead` plus the mounted `rulestead_admin` companion. [VERIFIED: AGENTS.md] [VERIFIED: roadmap]
- Keep Phase 48 bounded to final verification, traceability closure, and archive prep; do not reopen rollout, targeting, or broader admin-surface work. [VERIFIED: AGENTS.md] [VERIFIED: 48-CONTEXT.md]
- Use the named mounted proof bundle already established in Phases 46 and 47 rather than inventing a broader closeout matrix. [VERIFIED: roadmap] [VERIFIED: 48-CONTEXT.md]
- Distinguish clearly between `ready_for_closeout` and archived/shipped status in all active planning docs. [VERIFIED: 48-CONTEXT.md] [VERIFIED: .planning/v1.2.0-MILESTONE-AUDIT.md]

### the agent's Discretion
- Exact section order and evidence format inside `48-VERIFICATION.md`, provided it remains one canonical, concise, evidence-backed closeout artifact.
- Exact wording used in active planning docs to replace stale "proof bar still failing" language, provided the updated truth stays explicit and does not imply archive completion.
- Exact milestone-audit filename or reuse strategy if the closeout workflow discovers an in-repo naming convention variant, provided the resulting audit artifact is unambiguous and easy to trace.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | The `rulestead_admin` mounted companion starts through one deliberate, host-owned boot contract whose required runtime wiring, config shape, and package boundary are consistent from repo root proof to mounted host usage. | Phase 45 repaired and documented the boot/runtime seam; Phase 48 only needs to reverify it through the bounded mounted proof bundle and cite the existing evidence chain. [VERIFIED: roadmap] [VERIFIED: 48-CONTEXT.md] |
| PKG-02 | Missing or unsupported mounted companion prerequisites fail with explicit, bounded behavior instead of silent drift, misleading proof output, or docs that imply broader support than the repo provides. | Phase 47 already hardened fail-closed support truth; Phase 48 should certify it through the named proof bundle plus release-contract checks, not by widening product behavior. [VERIFIED: roadmap] [VERIFIED: MAINTAINING.md] [VERIFIED: rulestead_admin/README.md] |
| ADM-01 | The named `mounted_admin_contract` proof bar passes from the repo root against the supported mounted companion startup path and covers the repaired lifecycle, route, and permission contract. | `scripts/ci/test.sh` and `.github/workflows/ci.yml` now expose the mounted proof bar as the named contract surface, so final closure should rerun exactly that bar and record the result. [VERIFIED: scripts/ci/test.sh] [VERIFIED: .github/workflows/ci.yml] |
| VER-01 | Shared verification scripts and CI distinguish the merge-blocking mounted companion proof from advisory smoke paths and report actionable remediation when the proof surface fails. | The script now prints mounted-failure categories and CI names the path-gated `mounted companion proof` job feeding `release_gate`, so Phase 48 should verify and document that bounded posture end to end. [VERIFIED: scripts/ci/test.sh] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: MAINTAINING.md] |
| DOC-01 | Root, package, and maintainer-facing docs describe the exact mounted companion prerequisites, commands, fallback behavior, and sibling-package posture without implying standalone admin support or stronger proof than is actually runnable. | Phase 47 aligned the public/package/maintainer docs; the remaining gap is milestone-level evidence and active-planning truth drift, not another doc-IA pass. [VERIFIED: README.md] [VERIFIED: rulestead_admin/README.md] [VERIFIED: MAINTAINING.md] |
</phase_requirements>

## Summary

The strongest Phase 48 insight is that the milestone's code-and-doc surface is already repaired, but the active planning truth still lags behind that reality. Multiple top-level planning docs still say the mounted companion proof bar "still fails" or "still needs repair" even though Phase 46 restored the named verifier and Phase 47 reclosed the support-truth surfaces around it. That mismatch is exactly the kind of milestone-closeout drift Phase 48 should eliminate. [VERIFIED: `.planning/ROADMAP.md`] [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `.planning/MILESTONE-ARC.md`] [VERIFIED: `.planning/STATE.md`]

The correct closeout shape is therefore evidence-first, not doc-first. Phase 48 should rerun the bounded proof bundle that the repo already treats as canonical, write one formal `48-VERIFICATION.md` artifact that maps the results back to `PKG-01`, `PKG-02`, `ADM-01`, `VER-01`, and `DOC-01`, and only then update `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `PROJECT.md`, and milestone-audit truth to reflect that the milestone is ready for closeout. [VERIFIED: 48-CONTEXT.md] [VERIFIED: .planning/v1.2.0-MILESTONE-AUDIT.md]

The bounded proof bundle is already discoverable from current repo surfaces. The primary contract remains `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`. The directly relevant support-truth companion checks are the release-contract suites and the CI/runbook wording surfaces that now cite the same named proof bar and `release_gate` semantics. That means Phase 48 does not need a new verifier; it needs one canonical evidence artifact and one truthful planning-state reconciliation pass. [VERIFIED: scripts/ci/test.sh] [VERIFIED: README.md] [VERIFIED: MAINTAINING.md] [VERIFIED: .github/workflows/ci.yml]

The best slice split stays narrow:

1. Run the mounted proof bundle and assemble `48-VERIFICATION.md`.
2. Reconcile active planning truth and milestone audit prep from that evidence, explicitly moving the milestone to `ready_for_closeout` without claiming archive/shipping work already happened.

That split matches the roadmap's two planned slices and preserves the repo's existing closeout discipline seen in earlier milestone audit artifacts. [VERIFIED: roadmap] [VERIFIED: .planning/v1.2.0-MILESTONE-AUDIT.md] [INFERENCE from prior closeout artifacts]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 48 | Why |
|---------|-----------------------------|-----|
| `scripts/ci/test.sh` | Own the primary rerunnable mounted companion proof command and failure taxonomy | This is the named public/maintainer proof entrypoint. [VERIFIED: scripts/ci/test.sh] |
| `.github/workflows/ci.yml` | Define the CI job name and `release_gate` wiring for the mounted proof bar | Final verification should cite the same merge-blocking contract CI uses. [VERIFIED: .github/workflows/ci.yml] |
| `README.md`, `rulestead_admin/README.md`, `MAINTAINING.md` | Supply the support-truth surfaces whose wording must match the named proof bundle | These docs are the public/package/maintainer contract already aligned by Phase 47. [VERIFIED: README.md] [VERIFIED: rulestead_admin/README.md] [VERIFIED: MAINTAINING.md] |
| `.planning/phases/48-final-verification-archive-prep/48-VERIFICATION.md` | Become the single canonical milestone-closeout evidence artifact | Context explicitly prefers one evidence-backed verification report over scattered closeout claims. [VERIFIED: 48-CONTEXT.md] |
| `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md` | Reconcile active planning truth from "proof bar still failing" to "ready for closeout" once evidence exists | These files currently contain stale pre-Phase-46/47 framing. [VERIFIED: repo grep 2026-05-26] |
| Milestone audit artifact in `.planning/` | Record the closeout verdict and remaining non-blocking debt without overstating shipment/archive completion | Earlier milestone audits use this artifact to distinguish ready-for-closeout from already-closed. [VERIFIED: .planning/v1.2.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/v1.3.0-v1.3.0-MILESTONE-AUDIT.md] |

## Standard Stack

### Proof and drift-guard commands
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs`
- `rg -n "mounted_admin_contract|mounted companion proof|release_gate|ready_for_closeout|v1.5.0" /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/STATE.md /Users/jon/projects/rulestead/.planning/PROJECT.md /Users/jon/projects/rulestead/.planning/MILESTONE-ARC.md /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/MAINTAINING.md /Users/jon/projects/rulestead/.github/workflows/ci.yml`

These commands are sufficient for Phase 48 because they prove the bounded mounted contract, the release-support wording, and the active-planning truth that must be reconciled. [VERIFIED: scripts/ci/test.sh] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: repo grep 2026-05-26]

## Recommended Shape

### Pattern 1: One bounded proof bundle
Use the existing mounted proof bar plus directly relevant release-contract checks. Do not expand closeout into a full-repo green requirement or a new browser/demo lane.

### Pattern 2: One canonical verification artifact
`48-VERIFICATION.md` should summarize exact commands, outcomes, observable truths, requirement coverage, artifact checks, and closeout gaps. It should link to prior phase summaries and verification artifacts instead of duplicating raw logs.

### Pattern 3: Evidence first, planning truth second
Active planning docs should change only after `48-VERIFICATION.md` exists, so the repo can point to one concrete artifact when it marks requirements satisfied and the milestone ready for closeout.

### Pattern 4: Ready-for-closeout is not archived
The closeout docs must say the milestone is evidenced and ready for standard archive/closeout workflow, while still presenting `v1.5.0 — Guarded Rollout Foundations` as the next candidate rather than a milestone already being actively planned.

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Active planning docs continue to say the mounted proof bar still fails | Slice 2 must explicitly replace stale failure framing in `ROADMAP.md`, `PROJECT.md`, `STATE.md`, and `MILESTONE-ARC.md`. |
| Final verification gets spread across summaries, audit notes, and ad hoc comments | Slice 1 must create a single `48-VERIFICATION.md` and treat it as the canonical evidence index. |
| Closeout wording overstates archive completion or starts planning `v1.5.0` too early | Slice 2 must use `ready_for_closeout` language consistently and keep `v1.5.0` at recommendation depth only. |
| Phase 48 widens into a broad regression milestone | Both slices should stay anchored on the named mounted proof bundle and directly relevant support-truth guards only. |

## Validation Architecture

Phase 48 should execute in two waves:

1. **Verification evidence wave**: rerun the bounded mounted proof bundle, assemble `48-VERIFICATION.md`, and map requirement closure to exact evidence.
2. **Traceability reconciliation wave**: update active planning docs and the milestone audit artifact so all repository-level truth now points to the evidenced ready-for-closeout state and the next candidate remains `v1.5.0`.

## Recommended Slice Boundary

### Slice 1
Run the bounded mounted companion proof bundle and write one canonical `48-VERIFICATION.md` that closes milestone-wide evidence and requirement coverage.

### Slice 2
Refresh active planning truth and milestone-audit prep from that evidence so the repo says `v1.4.0` is ready for closeout and `v1.5.0` remains next, without implying archive/shipping work already happened.

## Confidence

- Evidence model: HIGH - the repo already has the canonical script, CI lane, and doc/test drift guards needed for a bounded closeout bundle. [VERIFIED: scripts/ci/test.sh] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: MAINTAINING.md]
- Scope control: HIGH - roadmap, context, AGENTS, and prior milestone audits all point to a narrow verification-and-reconciliation phase rather than new implementation work. [VERIFIED: roadmap] [VERIFIED: 48-CONTEXT.md] [VERIFIED: AGENTS.md]
- Closeout fit: HIGH - earlier milestones already use the same "verification artifact first, ready-for-closeout truth second" pattern, so Phase 48 can reuse a proven structure. [VERIFIED: .planning/v1.2.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/43-mounted-contract-verification-closure/43-VERIFICATION.md]

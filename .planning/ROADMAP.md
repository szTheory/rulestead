# Roadmap: Rulestead

## Current Milestone: v1.4.0 Mounted Companion Proof Reclosure

**Status:** Ready for Phase 45 planning
**Phases:** 45-48
**Requirements:** [.planning/REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/REQUIREMENTS.md)

## Overview

`v1.4.0` restores the last materially broken adopter-facing proof surface before new differentiating capability lands. The milestone stays tightly bounded: repair the mounted companion boot/runtime contract, make the repo-root `mounted_admin_contract` bar pass again, and ensure docs plus CI describe only the mounted sibling-package surface the repo can actually support.

## Prior Milestone History

- [x] `v1.1.0` — tenancy helpers and validation archived in [.planning/milestones/v1.1.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-ROADMAP.md)
- [x] `v1.2.0` — lifecycle hygiene and ownership archived in [.planning/milestones/v1.2.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.2.0-ROADMAP.md)
- [x] `v1.3.0` — adopter truth and proof closure archived in [.planning/milestones/v1.3.0-ROADMAP.md](/Users/jon/projects/rulestead/.planning/milestones/v1.3.0-ROADMAP.md)

## Phases

### Phase 45: Companion Boot & Package-Boundary Truth

**Goal:** Reconcile the mounted companion startup contract so `rulestead_admin` boots through one deliberate host-owned path with explicit prerequisite behavior.
**Depends on:** Phase 44
**Plans:** 3 planned slices

Plans:

- [ ] 45-01: Trace the failing mounted companion startup path and lock the intended host-owned boot contract
- [ ] 45-02: Repair sibling-package boot/runtime/config wiring without widening the mounted admin posture
- [ ] 45-03: Add focused regression proof for mounted companion prerequisite and boundary behavior

**Details:**

- Requirements: PKG-01, PKG-02.
- Preserve the linked-version sibling-package model; this phase fixes boot truth and prerequisite handling, not product shape.
- Fail closed on unsupported setup rather than teaching an ambiguous support surface.

### Phase 46: Mounted Proof Bar Restoration

**Goal:** Make the named `mounted_admin_contract` proof surface pass from the repo root and keep its verification semantics explicit.
**Depends on:** Phase 45
**Plans:** 3 planned slices

Plans:

- [ ] 46-01: Restore the repo-root `mounted_admin_contract` verifier path against the repaired mounted companion startup flow
- [ ] 46-02: Align mounted lifecycle, route, and permission proof with the supported companion contract
- [ ] 46-03: Tighten shared scripts and CI output so mounted proof failures produce actionable remediation

**Details:**

- Requirements: ADM-01, VER-01.
- Keep the mounted proof scoped and rerunnable rather than broadening it into a general-purpose demo bar.
- Verification must tell adopters exactly what broke and what setup is expected.

### Phase 47: Support Truth Reclosure

**Goal:** Ensure root, package, and maintainer-facing docs describe the repaired mounted companion surface with exact prerequisites, commands, and fallback behavior.
**Depends on:** Phase 46
**Plans:** 3 planned slices

Plans:

- [ ] 47-01: Update root and sibling package docs to cite the exact mounted companion proof commands and support boundary
- [ ] 47-02: Publish missing-prerequisite and fallback truth for the mounted companion surface
- [ ] 47-03: Extend release-contract checks around mounted companion wording and proof claims

**Details:**

- Requirements: DOC-01.
- Support truth must match the runnable repo surface exactly; no standalone-admin language or inflated proof claims.
- Keep docs aligned with the mounted host-app contract rather than inventing a separate admin deployment story.

### Phase 48: Final Verification & Archive Prep

**Goal:** Close milestone traceability, execute the bounded mounted companion proof posture end to end, and prepare the milestone for eventual archive without scope creep.
**Depends on:** Phase 47
**Plans:** 2 planned slices

Plans:

- [ ] 48-01: Run milestone verification, capture evidence, and close requirement traceability for the repaired mounted proof surface
- [ ] 48-02: Refresh planning truth for the next candidate and complete milestone audit prep

**Details:**

- Requirements: milestone-wide verification closure.
- Keep final verification scripts-first and tied to the named proof bars.
- Do not reopen guarded rollout or targeting scope during closeout.

## Milestone Summary

**Decimal Phases:** None

**Key Decisions:**

- Continue phase numbering from `v1.3.0`; `v1.4.0` starts at Phase 45.
- Activate the highest-priority arc candidate by default because repo-local evidence still shows the named mounted companion proof bar failing.
- Keep the milestone bounded to mounted proof repair, package-boundary truth, and support-truth reclosure rather than reopening feature prioritization.
- Preserve `rulestead_admin` as a mounted companion only; no standalone admin prep or publish posture changes are allowed.

**Deferred Beyond This Milestone:**

- Guarded rollout foundations (`v1.5.0`).
- Reusable targeting deepening (`v1.6.0`).
- Any broader admin redesign or control-plane expansion.
- New observability-product or runtime hot-path instrumentation work unrelated to mounted proof repair.

**Risks To Watch:**

- Boot-path fixes can accidentally widen the admin package posture if host-owned seams are not kept explicit.
- Verification can drift again if scripts, CI, and docs cite different mounted proof commands.
- Support-truth repair loses value if missing-prerequisite behavior remains ambiguous for adopters.

---
*Last updated: 2026-05-25 after activating milestone v1.4.0*

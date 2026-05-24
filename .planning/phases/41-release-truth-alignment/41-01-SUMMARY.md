---
phase: 41-release-truth-alignment
plan: 01
subsystem: docs
tags: [readme, release, onboarding, verification, hex]
requires:
  - phase: 40-lifecycle-workbench-verification-state-reconciliation
    provides: lifecycle verification closure and mounted-companion posture
provides:
  - shipped repo-vs-package release truth across root and sibling docs
  - runtime-first onboarding with bounded proof references
  - release-facing contract tests for support-truth drift
affects: [phase-42-runtime-contract-parity, docs, release-engineering]
tech-stack:
  added: []
  patterns: [split-front-door release story, bounded proof posture, doc-contract verification]
key-files:
  created: [.planning/phases/41-release-truth-alignment/41-01-SUMMARY.md]
  modified: [README.md, rulestead/README.md, rulestead_admin/README.md, guides/introduction/installation.md, guides/introduction/getting-started.md, guides/introduction/upgrading.md, open_feature_rulestead/README.md, examples/demo/README.md, MAINTAINING.md, rulestead/test/rulestead/release_contract_test.exs]
key-decisions:
  - "The root README owns the repo GA versus package-line explanation once, while sibling package READMEs stay narrow and link back to shared docs."
  - "Support truth stays explicitly bounded to the local demo and `mix verify.release_publish` / `mix verify.release_parity` instead of implying broader proof closure."
patterns-established:
  - "Public release posture changes must land in both docs and `release_contract_test.exs`."
  - "Companion surfaces stay discoverable but secondary: runtime first, mounted admin next, OpenFeature bridge bounded."
requirements-completed: [DOC-01, DOC-02]
duration: 3 min
completed: 2026-05-24
---

# Phase 41 Plan 01: Release Truth Alignment Summary

**Repo GA truth, runtime-first onboarding, and bounded release-proof language aligned across public docs and enforced by release contract tests**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-24T15:41:02Z
- **Completed:** 2026-05-24T15:43:36Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Rewrote the root and sibling package READMEs around the shipped `v1.0.0` repo posture and current `0.1.0` installable package line.
- Aligned installation, getting-started, upgrading, demo, and OpenFeature companion docs to the runtime-first and bounded-proof story.
- Extended release-facing tests and maintainer guidance so stale pre-GA claims now fail fast.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the root and sibling package front doors around the shipped release truth** - `09ef7e8` (docs)
2. **Task 2: Align onboarding and companion docs to the bounded proof posture** - `593d60f` (docs)
3. **Task 3: Lock the new release and support truth into tests and maintainer guidance** - `848aa99` (test)

**Plan metadata:** recorded in the Phase 41 closeout docs commit

## Files Created/Modified
- `README.md` - root release story, runtime-first quickstart, and bounded proof callout
- `rulestead/README.md` - runtime package entrypoint linked back to shared release docs
- `rulestead_admin/README.md` - mounted companion package posture and install contract
- `guides/introduction/installation.md` - explicit `0.1.0` install truth and runtime/admin split
- `guides/introduction/getting-started.md` - first-success path aligned to runtime-first onboarding
- `guides/introduction/upgrading.md` - shipped repo/package posture and bounded proof section
- `examples/demo/README.md` - runnable demo positioned as the primary local proof seam
- `open_feature_rulestead/README.md` - optional bridge companion posture
- `MAINTAINING.md` - maintainer release/support truth aligned to the shipped posture
- `rulestead/test/rulestead/release_contract_test.exs` - machine-backed assertions for the new release story

## Decisions Made
- Kept the repo-GA versus package-line explanation centralized at the root to avoid turning package READMEs into duplicate release notes.
- Described proof narrowly: local demo for runnable proof, `verify.release_publish` and `verify.release_parity` for published-release proof.
- Kept `rulestead_admin` and `open_feature_rulestead` explicitly secondary companion surfaces rather than default onboarding paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Correctness] Fixed malformed release-date sentence in getting-started**
- **Found during:** Task 2 (Align onboarding and companion docs to the bounded proof posture)
- **Issue:** An extra backtick in the repo GA sentence would have shipped a malformed docs surface.
- **Fix:** Corrected the sentence and re-ran the Task 2 grep verification.
- **Files modified:** `guides/introduction/getting-started.md`
- **Verification:** Task 2 acceptance grep checks passed after the fix.
- **Committed in:** `593d60f`

**2. [Rule 1 - Correctness] Reworked banned-phrase assertions to avoid false positives in grep gates**
- **Found during:** Task 3 (Lock the new release and support truth into tests and maintainer guidance)
- **Issue:** The test initially embedded stale release phrases verbatim, causing the negative grep gate to fail even though the docs were corrected.
- **Fix:** Switched to fragment-joined banned phrases so the test still enforces absence without reintroducing the exact stale text.
- **Files modified:** `rulestead/test/rulestead/release_contract_test.exs`
- **Verification:** `mix test test/rulestead/release_contract_test.exs` and the final negative grep checks passed.
- **Committed in:** `848aa99`

---

**Total deviations:** 2 auto-fixed (2 correctness)
**Impact on plan:** Both fixes were contained acceptance-loop corrections. No scope creep and no requirement changes.

## Issues Encountered
None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 41 is complete and the release/support truth is now consistent across public docs, maintainer guidance, and machine-backed checks.
- Phase 42 can focus on runtime schema and migration parity without carrying forward pre-GA release-story drift.

---
*Phase: 41-release-truth-alignment*
*Completed: 2026-05-24*

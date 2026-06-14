---
phase: 118-evidence-idempotence-guardrails
plan: 01
subsystem: testing
tags: [guardrails, playwright, evidence, lint, python-stdlib]

requires:
  - phase: 114-repo-native-component-matrix-harness
    provides: repo-native UI matrix evidence hooks
  - phase: 117-page-flow-ia-pass
    provides: selected mounted-admin workflow route evidence hooks
provides:
  - Phase 118 design-system evidence source guard
  - Lint-chain wiring for evidence posture and visual-baseline exclusions
affects: [phase-118, v1.17-verification, ci-lint]

tech-stack:
  added: []
  patterns:
    - Python stdlib source guard with aggregate failures
    - CI lint guard-chain extension after admin foundations

key-files:
  created:
    - scripts/check_design_system_evidence.py
  modified:
    - scripts/ci/lint.sh

key-decisions:
  - "Use a stdlib source guard to preserve Phase 118 evidence contracts without adding pixel baselines or package dependencies."
  - "Run the design-system evidence guard in the normal lint spine after admin foundations and before SVG budgets."

patterns-established:
  - "Evidence posture guard: assert generated screenshot artifact hooks and reject visual-baseline tooling adoption from source."
  - "Route and matrix drift guard: assert exact workflow route order, matrix sections, fixture-health markers, and selected contrast labels."

requirements-completed: [VER-02, VER-03]

duration: 4min
completed: 2026-06-14
---

# Phase 118 Plan 01: Durable Design-System Evidence Source Guard Summary

**Stdlib CI guard that protects matrix/workflow evidence hooks, generated screenshot posture, selected contrast proof, fixture-health coverage, and visual-baseline exclusions.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-14T22:20:08Z
- **Completed:** 2026-06-14T22:23:39Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `scripts/check_design_system_evidence.py`, a deterministic stdlib source guard that prints `DESIGN SYSTEM EVIDENCE OK` on success and aggregates drift failures under `DESIGN SYSTEM EVIDENCE DRIFT DETECTED`.
- Guarded the Phase 118 evidence contracts for UI matrix sections, selected admin workflow routes, screenshot artifact naming, keyboard/focus hooks, selected contrast checks, fixture-health states, and matrix route isolation.
- Wired the guard into `scripts/ci/lint.sh` after admin foundations with a comment preserving generated screenshots as artifacts and blocking visual-baseline tooling adoption.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the design-system evidence source guard** - `274eecd` (feat)
2. **Task 2: Wire the guard into the normal lint spine** - `0377265` (chore)

**Plan metadata:** recorded in the final `docs(118-01)` closeout commit

## Files Created/Modified

- `scripts/check_design_system_evidence.py` - Source guard for matrix evidence, workflow evidence, selected contrast labels, fixture-health markers, and forbidden visual-baseline tooling.
- `scripts/ci/lint.sh` - Runs the new evidence guard after `check_admin_foundations.py` and before SVG budget checks.

## Decisions Made

- Used file-read-only Python stdlib checks to satisfy D-10, D-11, D-12, D-13, and D-19 without adding dependencies or browser runtime cost to lint.
- Preserved generated Playwright screenshot artifacts through `testInfo.outputPath(...)` checks instead of introducing `toHaveScreenshot`, snapshot, pixelmatch, Storybook, or PhoenixStorybook tooling.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan's regex probe for artifact strings treats `$` as a regex anchor when passed through the shell. Verification used fixed-string `rg -F` checks for the two artifact patterns while keeping the guard source literals exact.

## Verification

| Command | Result | Status |
| --- | --- | --- |
| `python3 scripts/check_design_system_evidence.py` | `DESIGN SYSTEM EVIDENCE OK` | PASS |
| `bash -n scripts/ci/lint.sh` | no syntax errors | PASS |
| `rg -n "check_design_system_evidence.py|DESIGN SYSTEM EVIDENCE OK" scripts/check_design_system_evidence.py scripts/ci/lint.sh` | found guard invocation and success string | PASS |
| `rg -n -F 'ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png' scripts/check_design_system_evidence.py` | found matrix artifact pattern | PASS |
| `rg -n -F 'flow-${route.name}-${theme.name}-${viewport.name}.png' scripts/check_design_system_evidence.py` | found workflow artifact pattern | PASS |
| `git diff --check` | no whitespace errors | PASS |

## Known Stubs

None. Stub scan found no placeholder implementation data; the only `placeholder` text is the intentional static contrast fixture label guarded by this plan.

## Threat Flags

None. The guard is file-read-only, stdlib-only, network-free, and adds no endpoint, auth, file-write, schema, release, or package boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 118 Plan 02 can rely on the normal lint spine to fail if future edits remove matrix/workflow evidence contracts, generated screenshot artifact posture, fixture-health proof, selected contrast proof, or forbidden visual-baseline exclusions.

## Self-Check: PASSED

- Found `scripts/check_design_system_evidence.py`.
- Found task commits `274eecd` and `0377265` in git history.
- Verified plan-level commands passed before summary creation.

---
*Phase: 118-evidence-idempotence-guardrails*
*Completed: 2026-06-14*

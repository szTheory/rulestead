---
phase: 119-baseline-expert-audit-0-plans
plan: "02"
subsystem: ci-audit
tags: [github-actions, exunit, mix, xref, dialyzer, release-trust]
requires:
  - phase: 119-01
    provides: Static workflow and required-check inventory
provides:
  - Live CI timing baseline
  - Mix/ExUnit/compile/xref diagnostic record
  - Cache, PLT, and release-trust audit posture
affects: [phase-120, phase-121, phase-123]
tech-stack:
  added: []
  patterns:
    - Record nonzero diagnostic output as evidence before tuning
key-files:
  created: []
  modified:
    - .planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md
key-decisions:
  - "p95 is unavailable from the current mixed run sample."
  - "Observed Mix diagnostic failures/noise are recorded as evidence, not fixed in Phase 119."
  - "Release-trust and cache posture remain keep-by-default until later phases make measured changes."
patterns-established:
  - "Live run IDs, local command outputs, and exact command strings stay in the audit ledger."
requirements-completed: [CIDX-02]
duration: 38 min
completed: 2026-06-15
---

# Phase 119 Plan 02: Timing and Diagnostic Baseline Summary

**Live CI timing, local Mix diagnostics, cache/PLT posture, and release-trust evidence recorded for later optimization phases**

## Performance

- **Duration:** 38 min
- **Started:** 2026-06-15T22:06:36Z
- **Completed:** 2026-06-15T22:11:25Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Recorded representative recent `ci.yml` run IDs, wall-clock times, longest jobs, critical path observations, and p95 limitation.
- Ran and recorded D-11 diagnostics for slowest tests/modules, require profile, compile profile, xref cycles/stats/graph, CPU, and BEAM schedulers.
- Audited cache, Dialyzer PLT, dependency, protected Hex publish, linked package order, and post-publish proof posture without behavior changes.

## Task Commits

1. **Task 1: Record recent CI critical path, duplicated work, bottlenecks, and missing metrics** - `6ac1985`
2. **Task 2: Run and record locked Mix, ExUnit, compile, xref, CPU, and scheduler diagnostics** - `cc34ec1`
3. **Task 3: Audit cache, PLT, dependency, and release-trust posture as speed and security surfaces** - `67ee95a`

**Plan metadata:** pending in metadata commit.

## Files Created/Modified

- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` - Added timing, diagnostics, cache/PLT, and release-trust evidence.

## Decisions Made

- Do not claim p95 from the current mixed run sample.
- Treat the nonzero full-suite diagnostic run and compile-elixir dependency-loading output as Phase 121 evidence, not Phase 119 fixes.
- Preserve release-trust and supply-chain surfaces as keep-by-default.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** None.

## Issues Encountered

- Running multiple Mix diagnostics concurrently caused build-lock waits; the audit records that scheduling observation as baseline evidence.
- `mix test --warnings-as-errors --slowest*` produced one sample failure in the full suite, while the focused slow test rerun passed. This remains a Phase 121 investigation input.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for 119-03 to classify checks, finalize recommendations, add browser/demo guardrails, and complete source coverage.

---
*Phase: 119-baseline-expert-audit-0-plans*
*Completed: 2026-06-15*

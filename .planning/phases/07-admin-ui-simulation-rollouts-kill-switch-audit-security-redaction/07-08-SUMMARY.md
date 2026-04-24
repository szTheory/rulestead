---
phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
plan: 08
subsystem: testing
tags: [credo, static-analysis, sibling-packages, mix]
requires:
  - phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
    provides: Phase 7 local Credo checks and fixture-backed check coverage
provides:
  - Compile-safe Phase 7 Credo checks for sibling-package dependency builds
  - Fixture-targeted strict Credo probing without reintroducing default fixture noise
affects: [rulestead, rulestead_admin, ci, static-analysis]
tech-stack:
  added: []
  patterns:
    - Guard dev-only Credo modules when Credo is unavailable in dependency builds
    - Toggle fixture exclusion in `.credo.exs` based on explicit fixture CLI probes
key-files:
  created: []
  modified:
    - .credo.exs
    - rulestead/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex
    - rulestead/lib/rulestead/credo/no_raw_traits_in_logger.ex
    - rulestead/lib/rulestead/credo/no_mutation_outside_multi.ex
    - rulestead/lib/rulestead/credo/no_socket_captured_in_async.ex
    - rulestead/lib/rulestead/credo/no_eval_outside_context.ex
key-decisions:
  - "Phase 7 custom Credo checks compile to real checks only when Credo is available and to empty stubs otherwise."
  - "Fixture files stay excluded from default strict runs unless the CLI explicitly targets the credo fixture path."
patterns-established:
  - "Dev-only analyzer modules must not impose runtime dependency requirements on sibling packages."
  - "Credo fixture probes should be opt-in through argv-aware config, not always-on file inclusion."
requirements-completed: [SEC-03, SEC-04, TEL-03]
duration: 5min
completed: 2026-04-24
---

# Phase 7 Plan 08: Packaging-Safe Credo Check Loading Summary

**Compile-safe local Credo checks now preserve the Phase 7 lint contract in `rulestead/` while allowing `rulestead_admin` to compile the path dependency without `Credo.Check`.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T09:37:00Z
- **Completed:** 2026-04-24T09:42:14Z
- **Tasks:** 1
- **Files modified:** 6

## Accomplishments

- Wrapped all five Phase 7 custom Credo checks so sibling-package dependency compilation no longer fails when Credo is absent.
- Kept the core-package fixture-backed ExUnit proof intact for the custom checks.
- Updated `.credo.exs` so explicit fixture-targeted strict runs work again without reintroducing fixture noise into normal strict scans.

## Task Commits

Each task was committed atomically:

1. **Task 1: Move the custom Credo checks off the sibling-package runtime failure path** - `53b83ae` (fix)

## Files Created/Modified

- `.credo.exs` - Makes fixture exclusion argv-aware and avoids re-requiring already loaded local check modules.
- `rulestead/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex` - Guards the telemetry-meta custom check when Credo is unavailable.
- `rulestead/lib/rulestead/credo/no_raw_traits_in_logger.ex` - Guards the logger-meta custom check when Credo is unavailable.
- `rulestead/lib/rulestead/credo/no_mutation_outside_multi.ex` - Guards the atomic-mutation custom check when Credo is unavailable.
- `rulestead/lib/rulestead/credo/no_socket_captured_in_async.ex` - Guards the LiveView async safety custom check when Credo is unavailable.
- `rulestead/lib/rulestead/credo/no_eval_outside_context.ex` - Guards the evaluator-entrypoint custom check when Credo is unavailable.

## Decisions Made

- Used compile-safe guarded module definitions instead of adding a runtime Credo dependency or moving the checks into shipped runtime behavior.
- Kept fixture files excluded by default, but allowed them back in only when the CLI explicitly targets the fixture directory for verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] The owned Credo config prevented the plan's explicit fixture probe from exercising the custom check**
- **Found during:** Task 1 verification
- **Issue:** `mix credo --strict test/support/credo_fixtures/raw_traits_in_telemetry.ex` returned no useful custom-check output because the fixture directory was excluded unconditionally.
- **Fix:** Made fixture exclusion conditional on whether the CLI explicitly targets `test/support/credo_fixtures/`, while still excluding that directory from default strict runs.
- **Files modified:** `.credo.exs`
- **Verification:** `cd rulestead && (mix credo --strict test/support/credo_fixtures/raw_traits_in_telemetry.ex >/tmp/07-08-credo.out 2>&1 || true) && rg "raw traits|NoRawTraitsInTelemetryMeta" /tmp/07-08-credo.out`
- **Committed in:** `53b83ae`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required to satisfy the plan's own strict-Credo acceptance gate. No scope expansion beyond the owned config and check files.

## Issues Encountered

- `rulestead_admin` initially failed to compile the `../rulestead` path dependency because the local check modules `use Credo.Check` from the runtime compile path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The sibling-package compile path is restored, so the remaining Phase 7 gap-closure plans can verify from `rulestead_admin` instead of relying only on core-package commands.
- Existing unrelated repo changes remain outside this plan and were left untouched.

## Self-Check: PASSED

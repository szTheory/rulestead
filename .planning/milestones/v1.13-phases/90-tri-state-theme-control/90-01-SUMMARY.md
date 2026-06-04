---
phase: 90-tri-state-theme-control
plan: "01"
subsystem: ui
tags: [playwright, localStorage, theme, aria, radiogroup, file-fixture, matchMedia]

requires:
  - phase: 87-89-theme-cascade
    provides: data-theme cascade on .rs-shell and CSS @media system-dark support
provides:
  - file:// fixture with tri-state theme-control markup + inlined hook logic
  - Playwright spec with 11 behavioral tests covering THM-02 + THM-04
affects: [90-02, 90-03, phase-91-design-system-docs]

tech-stack:
  added: []
  patterns:
    - "File:// Playwright fixture with inlined hook logic (no Phoenix/DB needed)"
    - "localStorage whitelist guard: VALID.includes(v) ? v : 'system' (T-90-01 mitigation)"
    - "data-theme-pending cleared synchronously in DOMContentLoaded before rAF"
    - "setStoredTheme + page.goto ordering: navigate first, then write localStorage, then reload"

key-files:
  created:
    - rulestead_admin/priv/static/theme-control-harness.html
    - examples/demo/frontend/tests/theme-control.spec.ts
  modified: []

key-decisions:
  - "Inlined hook logic matches RESEARCH skeleton exactly: system=removeAttribute, whitelist VALID=['system','light','dark'], matchMedia guard if _mode !== 'system'"
  - "localStorage must be written AFTER page.goto for file:// pages (SecurityError otherwise); tests that pre-seed localStorage use goto+setItem+reload pattern"
  - "data-theme-pending is set as a static attribute on .rs-shell in the HTML; the DOMContentLoaded handler (mirroring mounted()) removes it synchronously"

patterns-established:
  - "Pattern: goto-setItem-reload for pre-seeding localStorage in file:// Playwright tests"
  - "Pattern: VALID whitelist for any client-side preference read from localStorage (T-90-01)"

requirements-completed:
  - THM-02
  - THM-04

duration: 15min
completed: 2026-06-04
---

# Phase 90 Plan 01: Tri-State Theme Control Test Scaffold Summary

**File:// Playwright fixture (inlined hook JS + radiogroup markup) + 11-test spec covering THM-02/THM-04 persistence, system/pinned/keyboard/ARIA/FOUC behaviors**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-04T00:00:00Z
- **Completed:** 2026-06-04T00:15:00Z
- **Tasks:** 2
- **Files created:** 2

## Accomplishments

- Created `theme-control-harness.html` — standalone file:// fixture with `.rs-shell[data-theme-pending]`, the radiogroup segmented control (System/Light/Dark), and the complete `.ThemeControl` hook logic inlined as a DOMContentLoaded IIFE. Includes localStorage whitelist guard (T-90-01) and the `removeAttribute("data-theme-pending")` synchronous snap.
- Created `theme-control.spec.ts` — 11 Playwright tests (all passing 11/11) covering: select applies, localStorage written, persist across reload, system removes attr, system follows OS, pinned ignores OS, keyboard nav (ArrowRight roving tabindex), aria-checked tracks, no animated wipe (pending absent), pending cleared on pinned load, input validation (unknown value → system).
- Existing 8 theme-cascade + theme-scope tests remain green. `tsc --noEmit` clean.

## Task Commits

1. **Task 1 + 2: theme-control fixture + spec** — `a8a4226` (feat)

## Files Created

- `/Users/jon/projects/rulestead/rulestead_admin/priv/static/theme-control-harness.html` — file:// fixture with .rs-shell[data-theme-pending], radiogroup control, inlined hook logic
- `/Users/jon/projects/rulestead/examples/demo/frontend/tests/theme-control.spec.ts` — 11-test Playwright spec for THM-02 + THM-04

## Decisions Made

- **goto-before-setItem pattern:** For file:// URLs, `localStorage.setItem` called before `page.goto` throws a SecurityError. Tests that pre-seed a theme value use: `goto(harnessUrl)` → `setStoredTheme(page, val)` → `page.reload()`. This matches the reload-persistence flow the plan specifies anyway.
- **Whitelist applied in readTheme():** `VALID.includes(v) ? v : "system"` exactly as RESEARCH.md specifies (T-90-01 mitigation). Unknown values silently fall to system — test 11 verifies this.
- **system = removeAttribute, not setAttribute("data-theme", "system"):** Matches the CSS cascade which uses `:not([data-theme])` for system mode. Setting the attribute to "system" would break the cascade.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] goto-before-setStoredTheme ordering fix**

- **Found during:** Task 2 (running the Playwright spec after creation)
- **Issue:** Tests 4, 6, and 10 called `setStoredTheme(page, "dark")` before `page.goto(harnessUrl)`. On a file:// URL with no page loaded, `localStorage.setItem` throws `SecurityError: Failed to read the 'localStorage' property from 'Window': Access is denied for this document.`
- **Fix:** Reordered those three tests to call `page.goto(harnessUrl)` first, then `setStoredTheme`, then `page.reload()`. Behavior under test is identical — the reload causes the hook to read the pre-seeded value on DOMContentLoaded.
- **Files modified:** `examples/demo/frontend/tests/theme-control.spec.ts`
- **Verification:** All 11 tests pass after fix.
- **Committed in:** `a8a4226` (same task commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Fix necessary for test correctness; no scope change.

## Issues Encountered

- localStorage SecurityError on file:// pages before navigation (see deviation above) — straightforward fix by reordering goto/setItem/reload.

## Known Stubs

None — this plan creates test infrastructure only (no UI rendering data stubs).

## Threat Flags

No new network endpoints, auth paths, or file access patterns introduced. The localStorage whitelist guard (T-90-01) is present in the inlined hook logic as specified.

## User Setup Required

None — existing Playwright + file:// fixture pattern, no new packages.

## Next Phase Readiness

- Plan 90-02 can now implement the real `.ThemeControl` ColocatedHook in `shell.ex`; the spec in `theme-control.spec.ts` is the acceptance gate
- The 11-test spec will be the phase gate for 90-02 (all must pass against the live hook)
- No blockers

---

*Phase: 90-tri-state-theme-control*
*Completed: 2026-06-04*

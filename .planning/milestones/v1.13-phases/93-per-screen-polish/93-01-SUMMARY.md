---
phase: 93-per-screen-polish
plan: "01"
subsystem: ui
tags: [css, tokens, a11y, wcag, playwright, design-system]

requires:
  - phase: 91-design-system-consolidation
    provides: "design-system.spec.ts contrast gate + --rs-accent token cascade"

provides:
  - "--rs-accent in light Blocks 1+4 darkened to #9a3f12 (5.74:1 on #fde8dc)"
  - "design-system.spec.ts enforces accent-light at normal (4.5) threshold"
  - "SCRN-01 evidence: 7 new screen types × 2 themes = 14 screenshots at /tmp/rs-shots/screens/"

affects: [94-motion-and-animation, design-system, a11y]

tech-stack:
  added: []
  patterns:
    - "Synced light pair (Block 1 + Block 4) must be kept identical — verified by check_synced_pair.py"
    - "design-system.spec.ts uses literal hex values at real thresholds — no workaround exceptions"

key-files:
  created: []
  modified:
    - "rulestead_admin/priv/static/css/rulestead_admin.css"
    - "examples/demo/frontend/tests/design-system.spec.ts"

key-decisions:
  - "Darkened --rs-accent from #c45c26 to #9a3f12 in light blocks only — preserves ember identity while clearing 4.5:1 WCAG AA"
  - "Removed level:'large' workaround from accent-light spec entry — gate now genuinely enforces normal threshold"
  - "Broadened sweep captured 7 screen types (simulate, kill, timeline, audience-detail, experiment-detail, change-request-detail + flag-testing); sweep clean"

patterns-established:
  - "Light pair synced invariant: Blocks 1 and 4 carry identical --rs-accent value; check_synced_pair.py enforces IDENTICAL"

requirements-completed: [A11Y-01, SCRN-01]

duration: 40min
completed: 2026-06-04
---

# Phase 93 Plan 01: Accent-Badge Light-Mode AA Fix + Both-Theme Screen Sweep Summary

**--rs-accent darkened to #9a3f12 (5.74:1) in light-mode cascade; design-system gate restored to normal 4.5 threshold; 7-screen broadened sweep shows clean both-theme rendering with no straggler**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-06-04T00:00:00Z
- **Completed:** 2026-06-04T11:04:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Fixed the sole A11Y-01 straggler: `--rs-accent` `#c45c26` on `--rs-accent-soft` `#fde8dc` was 3.62:1 (below normal AA). Darkened to `#9a3f12` = 5.74:1, restoring WCAG AA compliance for accent badge text in light mode.
- Removed the `level: "large"` workaround from `design-system.spec.ts` — accent-light entry now asserts `fg="#9a3f12"` at the real normal (4.5:1) threshold. Gate is no longer lenient.
- Broadened both-theme sweep: 7 new screen types (simulate, kill-switch, timeline, audience-detail, experiment-detail, change-request-detail, flag-testing) × 2 themes = 14 new screenshots. Visual inspection: all correct elevation, legible text, no light-bleed. Sweep clean — no straggler found.
- Synced pair IDENTICAL (56 tokens), literal-scan unchanged at 90, 28/28 specs green, mix compile clean.

## Task Commits

1. **Task 1: Darken --rs-accent; restore design-system spec to normal threshold** - `fbb3327` (fix)

No separate commit for Task 2 — sweep was clean; no CSS changes required. Screenshots are on-disk evidence at `/tmp/rs-shots/screens/93-*.png`.

## Files Created/Modified

- `rulestead_admin/priv/static/css/rulestead_admin.css` — `--rs-accent` changed from `#c45c26` to `#9a3f12` in Block 1 (`.rs-shell,[data-rulestead]`) and Block 4 (`[data-theme="light"]`); dark blocks unchanged
- `examples/demo/frontend/tests/design-system.spec.ts` — accent-light pair updated to `#9a3f12`, `level:"large"` removed, comment updated

## Decisions Made

- Used `#9a3f12` (5.74:1) rather than the minimum-passing value, giving headroom above the 4.5:1 bar while staying in the "restrained ember" brand tone family.
- Left dark `--rs-accent` (`#e8834a`, 5.38:1 on surface-muted) entirely unchanged — it already passes.
- Sweep script (`sweep-93.mjs`) was a throwaway and was removed after use; screenshots remain in `/tmp/rs-shots/screens/`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Route discovery required a probe pass before screenshotting: the admin routes follow the pattern `/admin/flags/:section?env=staging` and sub-screens `/admin/flags/:flag_key/:sub?env=staging`, not the generic `/admin/:resource` path assumed in the plan. Discovered actual paths from the live demo and used them directly.

## Broadened Sweep Results (SCRN-01 Evidence)

| Screen type | Light | Dark | Result |
|-------------|-------|------|--------|
| flag-simulate | clean | clean | pass |
| flag-kill | clean | clean | pass |
| flag-timeline | clean | clean | pass |
| audience-detail | clean | clean | pass |
| experiment-detail | clean | clean | pass |
| change-request-detail | clean | clean | pass |
| flag-testing | clean | clean | pass |

**Verdict:** Sweep clean — no straggler found. All screens show correct elevation, legible text, no light-bleed in either theme.

## Known Stubs

None.

## Next Phase Readiness

- Phase 93 A11Y-01 and SCRN-01 requirements are satisfied.
- Phase 94 (motion/animation) can proceed; token foundation is stable.

---
*Phase: 93-per-screen-polish*
*Completed: 2026-06-04*

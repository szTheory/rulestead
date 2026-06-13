---
phase: 94-restrained-micro-animation
plan: "01"
subsystem: ui
tags: [css, animation, easing, theme, liveview-hook, motion]

# Dependency graph
requires:
  - phase: 90-theme-control
    provides: ThemeControl hook with data-theme-pending FOUC suppression
provides:
  - Entrance animations on .rs-card--flag and .rs-record-row aligned to --rs-ease-out (fast→settle)
  - data-theme-switching suppression in CSS covering user-toggle token swaps
  - .ThemeControl applyTheme() wraps every swap with transient data-theme-switching + rAF removal
affects: [93-attention-rail-search, future-mot-03-view-transitions]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "data-theme-switching: transient attribute pattern for zero-flash DOM transitions — set attr, swap tokens, rAF-remove attr"
    - "FOUC suppression selector extension: compound [data-attr], [data-attr] * with transition:none !important covers both load and toggle paths"

key-files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
    - rulestead_admin/lib/rulestead_admin/components/shell.ex

key-decisions:
  - "Modify applyTheme() itself (not call sites) so suppression is automatic for click, keydown, and any future toggle path"
  - "data-theme-switching removed via single rAF (not double-rAF) — sufficient since token swap is synchronous"
  - "Extend existing [data-theme-pending] selector rather than a separate block to keep the FOUC contract in one place"

patterns-established:
  - "Entrance easing: fast→settle pattern uses --rs-ease-out; on-screen state changes retain --rs-ease-standard or --rs-ease-in-out"
  - "Zero-flash theme toggle: setAttribute → swap → requestAnimationFrame(removeAttribute) pattern"

requirements-completed:
  - MOT-01
  - MOT-02

# Metrics
duration: 8min
completed: 2026-06-04
---

# Phase 94 Plan 01: Restrained Micro-Animation Summary

**Entrance animations on card/record-row rows aligned to ease-out; theme-toggle background-transition flicker eliminated via transient `data-theme-switching` rAF suppression**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T00:00:00Z
- **Completed:** 2026-06-04T00:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `.rs-card--flag` and `.rs-record-row` entrance animations now reference `--rs-ease-out` (aligning with `.rs-settle` and `.rs-task-group`), giving both a fast-start/quick-settle responsive feel instead of symmetric ease-standard
- Theme toggle flicker eliminated: `[data-theme-switching]` and `[data-theme-switching] *` added to the existing FOUC suppression block so nine color/background/border-color transitions are frozen during the single frame of the token swap
- `.ThemeControl` `applyTheme()` sets `data-theme-switching` before every attribute write and removes it on the next `requestAnimationFrame` — covers click, keyboard, and any future toggle path automatically
- Phase-90 FOUC contract fully intact: `data-theme-pending` is still removed synchronously at mount; `data-theme-switching` is a separate, additive concern

## Task Commits

1. **Task 1: Align entrance easing + extend FOUC suppression selector** - `e245007` (fix)
2. **Task 2: Add transient toggle-suppression to .ThemeControl hook** - `513bc0a` (fix)

**Plan metadata:** TBD (docs commit follows)

## Files Created/Modified

- `rulestead_admin/priv/static/css/rulestead_admin.css` - Two targeted edits: easing change on card/record-row; suppression selector extended to data-theme-switching
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` - Two-line additive change to applyTheme(): setAttribute + rAF removeAttribute

## Decisions Made

- Modified `applyTheme()` itself rather than wrapping each call site — guarantees suppression is active for all toggle paths (click, keyboard, future) without risk of a missed call site
- Single `requestAnimationFrame` (not double-rAF) is sufficient because the token swap (`setAttribute`/`removeAttribute` on `data-theme`) is synchronous — the browser sees the final state in the same task; rAF fires after layout/paint commit
- Extended the existing `[data-theme-pending]` selector block rather than creating a separate rule, keeping the full FOUC/toggle suppression contract co-located and readable

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. `00-demo-toggle.spec.ts` shows 1 pre-existing failure (requires a running demo server) — confirmed not introduced by this plan's changes and not one of the 28 in-scope specs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 94 MOT-01 + MOT-02 requirements fulfilled
- All motion remains transform/opacity-only, tokenized durations, gated behind `@media (prefers-reduced-motion: no-preference)`
- `rs-confirm-pop` confirmed wired to `.rs-flash`, `.rs-banner`, `.rs-callout`, `.rs-cmdk__panel`
- 28/28 Playwright specs green; synced pair IDENTICAL (56 tokens); `mix compile --warnings-as-errors` clean; design-system gate 0 violations

---
*Phase: 94-restrained-micro-animation*
*Completed: 2026-06-04*

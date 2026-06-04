---
phase: 89-focus-interaction-state-unification
plan: 01
subsystem: ui
tags: [accessibility, focus-ring, theme-harness, a11y, wcag]

# Dependency graph
requires:
  - phase: 87-design-system-token-audit
    provides: focus-ring tokens (--rs-focus-ring-color, --rs-focus-ring-offset, --rs-surface)
  - phase: 88-focus-ring-color-routing
    provides: inline focus tint colors routed to --rs-focus-ring-color
provides:
  - Interactive focus ring targets in theme-harness.html covering all three surface types
  - Screenshot-verifiable text input, select, tab strip, and button variants
affects:
  - 89-02 (CSS plan that adds the unified ring — harness targets are its verification fixture)
  - 91 (design-system docs/fixture phase)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Harness sections use inline styles matching existing heading pattern (font-size/weight/color/transform/tracking)"
    - "Tab strip uses real .rs-flag-subnav__tab + .rs-flag-subnav__tabs classes — not bare divs"
    - "Form controls are plain input[type=text] and select inside .rs-shell (CSS scoping applies automatically)"

key-files:
  created: []
  modified:
    - rulestead_admin/priv/static/theme-harness.html

key-decisions:
  - "Used .rs-flag-subnav__tab class on button[role=tab] elements so the existing :focus-visible rule fires immediately"
  - "Placed primary button inside .rs-card to create the card-surface verification target without new CSS"
  - "tab elements use button (not a) so they are natively focusable; tabindex=-1 on tabs 2+3 keeps one in tab order"

patterns-established:
  - "Harness section heading: font-size var(--rs-text-sm), font-weight var(--rs-weight-semibold), color var(--rs-text-muted), uppercase, tracking-wide, margin 0 0 0.5rem"

requirements-completed: [A11Y-02, A11Y-03]

# Metrics
duration: 8min
completed: 2026-06-04
---

# Phase 89 Plan 01: Focus Ring Targets Harness Summary

**Interactive focus targets added to theme-harness.html covering page-bg, card, and colored-fill surfaces so Plan 02's unified two-stop ring can be screenshot-verified on every context**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-06-04T08:12:00Z
- **Completed:** 2026-06-04T08:20:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added "Focus Ring Targets" section to theme-harness.html with four sub-groups
- Group 1: labeled text input + select on page-bg surface (plain .rs-shell element selectors apply)
- Group 2: secondary, primary, and danger `.rs-button` variants on page-bg surface
- Group 3: primary button inside `.rs-card` — exposes the card surface for ring verification
- Group 4: three-tab `[role=tab]` strip using `.rs-flag-subnav__tab` classes with correct active/inactive styling
- Existing `outside-shell` scope probe and `window.setTheme`/`clearTheme` remain intact

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Focus Ring Targets section to harness** - `caf01ea` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `rulestead_admin/priv/static/theme-harness.html` — Added 54 lines: Focus Ring Targets section with four sub-groups across three surface types

## Decisions Made
- Used real `.rs-flag-subnav__tab` class on tab buttons rather than bare inline-styled divs — the class already carries `:focus-visible` box-shadow so Plan 02 ring will layer correctly without extra selector work.
- First tab gets `tabindex="0"`, tabs 2-3 get `tabindex="-1"` — standard roving-tabindex pattern; keyboard users can Tab to the strip and arrow between tabs (future), but Tab alone doesn't require hitting all three.
- Primary button placed inside `.rs-card` using the card's existing padding — no wrapper div needed, card flex layout handles the label span alignment.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None — static file:// fixture, no server or build step required.

## Next Phase Readiness
- Plan 02 (89-02) can now apply the unified `:focus-visible` two-stop ring and immediately screenshot-verify it on: a text input (page-bg), a select (page-bg), a secondary button (page-bg), a primary button (page-bg + colored fill), a danger button (page-bg), a primary button (card surface), and a tab strip.
- No blockers for 89-02.

## Threat Flags

None — static devtools fixture; no network surface, no user data, no routes.

## Self-Check: PASSED

- `rulestead_admin/priv/static/theme-harness.html` exists and contains all required targets
- Commit `caf01ea` exists in git log
- grep gates:
  - `role="tab"`: 3 (>= 3 required)
  - `rs-button--primary`: 2 (>= 2 required)
  - `rs-button--danger`: 1 (>= 1 required)
  - `type="text"`: 1 (>= 1 required)
  - `<select`: 1 (>= 1 required)
  - `outside-shell`: 3 (probe intact)

---
*Phase: 89-focus-interaction-state-unification*
*Completed: 2026-06-04*

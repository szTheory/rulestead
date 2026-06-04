---
phase: 89-focus-interaction-state-unification
plan: "02"
subsystem: rulestead_admin/css
tags: [a11y, focus-ring, design-system, dark-mode, css-tokens]
completed: "2026-06-04"
duration_minutes: 18

dependency_graph:
  requires: [87-01, 88-01, 89-01]
  provides: [A11Y-02, A11Y-03]
  affects: [rulestead_admin/priv/static/css/rulestead_admin.css]

tech_stack:
  added: []
  patterns:
    - ":where() zero-specificity base rule for uniform :focus-visible ring"
    - "Two-stop box-shadow ring: inner gap tracks --rs-surface, outer ring tracks --rs-focus-ring-color"
    - "Explicit disabled tokens (--rs-disabled-bg/--rs-disabled-text) instead of opacity alone"

key_files:
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css

decisions:
  - "Upgrade --rs-focus-ring to two-stop form (surface gap + brand outer) across all 4 cascade blocks"
  - "Single canonical :where() rule at zero specificity governs all interactive elements"
  - "CmdK modal input ring intentionally suppressed — modal context is the affordance"
  - "Filter-panel omnisearch uses :focus-within on container, not ring on inner input"
  - "Rail-link hover changed from surface-muted to primary-soft+primary-hover for perceptible 3:1+ shift"

metrics:
  tasks_completed: 2
  tasks_total: 2
  files_changed: 1
---

# Phase 89 Plan 02: Focus + Interaction State Unification Summary

Two-stop WCAG 2.4.11/2.4.13 ring via single `:where()` base rule, with all 10 old focus idioms resolved and hover/disabled states routed through explicit design tokens.

## What Was Built

### Task 1: Upgrade --rs-focus-ring to two-stop form in all 4 cascade blocks

Replaced the single-stop `0 0 0 3px var(--rs-focus-ring-color)` declaration with the two-stop form in all four cascade blocks:

```
0 0 0 var(--rs-focus-ring-offset) var(--rs-surface),
0 0 0 calc(var(--rs-focus-ring-offset) + 3px) var(--rs-focus-ring-color)
```

The inner stop tracks `--rs-surface` (theme-variant), creating a surface-colored gap that visually separates the outer brand ring from any fill color — including the blue primary button. The synced dark pair (blocks 2 + 3) was verified character-for-character identical after the upgrade.

### Task 2: Canonical base rule + all old focus idioms resolved

Added one zero-specificity base rule under `.rs-shell :where(...)`:focus-visible that governs every interactive element (`a`, `button`, `input`, `select`, `textarea`, `[tabindex]`, `[role="option"]`, `[role="tab"]`, `summary`). Per-element overrides win cleanly by specificity.

Ten old focus idioms resolved:

| Idiom | Fix Applied |
|-------|-------------|
| Pale `outline: 2px solid var(--rs-primary-soft)` on input/select/textarea | Replaced with `box-shadow: var(--rs-focus-ring)`; changed `:focus` to `:focus-visible` |
| `.rs-button--text` bare `outline:none` + `box-shadow:none` suppression | Removed both suppressions; canonical `:where()` now supplies the ring |
| Filter-panel `input:focus` with `outline:none; box-shadow:none` | Replaced with `:focus-within` on container + `border-color: var(--rs-primary)` |
| CmdK `input:focus` suppression | Changed to `:focus-visible`; kept suppression with intentional comment |
| `rs-omnisearch__token-remove` bare `outline:none` without ring | Added `box-shadow: var(--rs-focus-ring)`; split hover/focus-visible into two rules |
| `rs-omnisearch__option` bare `outline:none` without ring | Added `box-shadow: var(--rs-focus-ring)`; split hover/focus-visible into two rules |
| Radio-card `outline: 3px solid var(--rs-focus-ring-color)` | Replaced with `box-shadow: var(--rs-focus-ring)` |
| `button:disabled opacity: 0.55` | Replaced with `background: var(--rs-disabled-bg); color: var(--rs-disabled-text); border-color: var(--rs-border)` |
| Radio-card disabled `opacity: 0.65` | Replaced with `background: var(--rs-disabled-bg); border-color: var(--rs-border)` |
| Rail-link hover too-subtle | Changed from `surface-muted + rs-text` to `primary-soft + primary-hover` for 3:1+ perceptible shift |

## Verification Results

All 8 gates passed:

| Gate | Check | Result |
|------|-------|--------|
| 1 | `grep -c ':where(a, button...'` = 1 | PASS |
| 2 | All `outline:none` lines reviewed — each is (a) canonical rule, (b) accompanied by box-shadow, or (c) cmdk intentional suppression with comment | PASS |
| 3 | No bare `:focus {` on interactive selectors | PASS (0 matches) |
| 4 | Pale `outline: 2px solid var(--rs-primary-soft)` gone | PASS (0 matches) |
| 5 | Two-stop `calc(var(--rs-focus-ring-offset) + 3px)` in 4 cascade blocks | PASS (4 matches) |
| 6 | `button:disabled` uses `--rs-disabled-bg` | PASS |
| 7 | `mix compile --warnings-as-errors` | PASS (exit 0) |
| 8 | Playwright theme-cascade + theme-scope specs | PASS (8/8) |

Synced dark pair (system-dark + explicit-dark blocks) verified identical:
`0 0 0 var(--rs-focus-ring-offset) var(--rs-surface), 0 0 0 calc(var(--rs-focus-ring-offset) + 3px) var(--rs-focus-ring-color)`

## Screenshots

Focus ring captured in both themes at `/tmp/rs-shots/89-02/`:
- `light-focus-primary-btn.png` — two-stop ring on blue Primary button (light)
- `dark-focus-primary-btn.png` — two-stop ring on blue Primary button (dark)
- `light-focus-input.png` — ring on text input, page-bg surface (light)
- `dark-focus-input.png` — ring on text input, page-bg surface (dark)
- `light-focus-tab.png` — ring on Overview [role=tab] (light)
- `dark-focus-tab.png` — ring on Overview [role=tab] (dark)

Visual observations:
- Inner surface gap clearly separates outer ring from blue button fill in both themes
- Ring visible on page-bg surface, card surface, and colored fills
- Disabled button shows muted gray bg + muted text (not just opacity) in both themes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Ring] `.rs-omnisearch__option:focus-visible` had bare `outline:none` without box-shadow replacement**
- **Found during:** Task 2, Gate 2 review
- **Issue:** `.rs-shell .rs-omnisearch__option:hover, .rs-shell .rs-omnisearch__option:focus-visible` shared a combined rule with `outline: none` but no `box-shadow: var(--rs-focus-ring)`. The plan catalogued 6 named idioms but this was a 7th instance.
- **Fix:** Split into two rules; added `box-shadow: var(--rs-focus-ring)` to the `:focus-visible` branch.
- **Files modified:** `rulestead_admin/priv/static/css/rulestead_admin.css`
- **Commit:** 04d7839 (included in Task 2 commit)

## Known Stubs

None.

## Threat Flags

None. This plan makes no changes to network endpoints, auth paths, or schema.

## Self-Check: PASSED

- [x] `rulestead_admin/priv/static/css/rulestead_admin.css` modified — confirmed
- [x] Task 1 commit d7506c3 exists
- [x] Task 2 commit 04d7839 exists
- [x] 4 two-stop declarations: `grep -c "calc(var(--rs-focus-ring-offset) + 3px)"` = 4
- [x] 1 canonical rule: `grep -c ':where(a, button, input, select, textarea,'` = 1
- [x] 0 bare `:focus` on interactive selectors (Gate 3)
- [x] Playwright 8/8 (Gate 8)
- [x] mix compile clean (Gate 7)

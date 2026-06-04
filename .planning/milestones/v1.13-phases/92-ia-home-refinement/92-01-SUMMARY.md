---
phase: 92-ia-home-refinement
plan: "01"
subsystem: rulestead_admin/css
tags: [css, design-system, admin-ui, dark-mode, navigation, empty-state]
dependency_graph:
  requires: []
  provides: [overview-rail-link-modifier, attention-empty-token-fix]
  affects: [rulestead_admin/priv/static/css/rulestead_admin.css]
tech_stack:
  added: []
  patterns: [token-driven-CSS, BEM-modifier, responsive-suppression]
key_files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
decisions:
  - "Use semibold + hairline --rs-border-subtle separator for overview link; no new color or icon"
  - "Suppress border-bottom/margin on mobile (<48rem) where the rail is a horizontal pill strip"
  - "Swap .rs-attention-empty background to --rs-surface-muted (#1f2a38 dark) so the empty state is a calm raised card, not a sunken void"
metrics:
  duration: "10 minutes"
  completed: "2026-06-04T14:50:41Z"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 92 Plan 01: Overview Rail-Link Modifier + Attention-Empty Token Fix Summary

Hairline separator + semibold weight for the Overview rail anchor, and token swap from `--rs-surface-faint` to `--rs-surface-muted` on the attention empty-state so neither surface renders as a dark void in dark mode.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add .rs-shell__rail-link--overview CSS modifier | 640b9b0 | rulestead_admin/priv/static/css/rulestead_admin.css |
| 2 | Fix .rs-attention-empty dark-mode background token | 640b9b0 | rulestead_admin/priv/static/css/rulestead_admin.css |

## What Was Built

### Task 1: .rs-shell__rail-link--overview

Added a CSS block immediately after `.rs-shell__rail-link[aria-current="page"]` that gives the Overview/home anchor visual separation from the task-rhythm group links:

- `font-weight: var(--rs-weight-semibold)` — heavier than the base medium weight of grouped items
- `margin-bottom: var(--rs-space-2)` + `padding-bottom: var(--rs-space-3)` — breathing room before the first task-rhythm group
- `border-bottom: 1px solid var(--rs-border-subtle)` — hairline separator using the existing subtle border token (re-themes correctly in both light and dark)

A `@media (max-width: 47.99rem)` block suppresses the separator on mobile where the rail renders as a horizontal pill strip (border-bottom would be misread as a focus underline).

### Task 2: .rs-attention-empty token swap

Changed the single token in `.rs-attention-empty`:

- **FROM:** `background: var(--rs-surface-faint)` — resolves to `#10161f` in dark, which is below the page background (`#19222e`), creating a sunken void
- **TO:** `background: var(--rs-surface-muted)` — resolves to `#1f2a38` in dark, which sits above the page background as a calm, slightly elevated neutral card

No other properties in `.rs-attention-empty` were changed (dashed border, spacing, and `color: var(--rs-text-muted)` are all correct).

## Verification

All gates passed:

```
grep -c "rs-shell__rail-link--overview" rulestead_admin/priv/static/css/rulestead_admin.css
→ 2  (main block + mobile suppression block)

grep -A6 "rs-attention-empty" ... | grep "surface-muted"
→ 1 match: background: var(--rs-surface-muted);

grep -A6 "rs-attention-empty" ... | grep "surface-faint"
→ (empty — old token gone)

cd rulestead_admin && mix compile --warnings-as-errors
→ exit 0

npx playwright test design-system.spec.ts theme-cascade.spec.ts theme-control.spec.ts theme-scope.spec.ts
→ 28 passed (2.3s), 0 contrast violations
```

## Deviations from Plan

None — plan executed exactly as written. Both tasks implemented as a single atomic CSS-file edit and committed together (single file, logically grouped changes).

## Threat Flags

None — presentation-only CSS changes, no new input surface, no data path.

## Self-Check: PASSED

- [x] `rulestead_admin/priv/static/css/rulestead_admin.css` modified with both changes
- [x] Commit 640b9b0 exists
- [x] `.rs-shell__rail-link--overview` appears 2 times in CSS
- [x] `.rs-attention-empty` uses `--rs-surface-muted` (not `--rs-surface-faint`)
- [x] 28 Playwright tests pass, 0 violations
- [x] mix compile clean

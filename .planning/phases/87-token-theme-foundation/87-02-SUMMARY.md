---
phase: "87"
plan: "02"
subsystem: rulestead_admin/css
tags: [css, tokens, theming, design-system, scope-containment]
dependency_graph:
  requires: []
  provides: [variant-token-scope-containment, light-default-block, focus-ring-color-token, overlay-tokens]
  affects: [rulestead_admin/priv/static/css/rulestead_admin.css]
tech_stack:
  added: []
  patterns: [invariant-variant-token-split, css-cascade-scoping, color-scheme-on-scope-element]
key_files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
decisions:
  - "Moved all color/neutral/surface/border/text/shadow/focus tokens from :root to .rs-shell,[data-rulestead] with color-scheme:light"
  - "--rs-focus-ring now references var(--rs-focus-ring-color) instead of a raw rgba() value"
  - "Added --rs-warning-hover:#92400e to complete the warning token family (was missing)"
  - "Introduced --rs-focus-ring-color, --rs-overlay-veil, --rs-scrim with light values for Phases 88+89"
  - "Left Plan 03 placeholder comment immediately after the light block closing brace"
metrics:
  duration: "15min"
  completed: "2026-06-04"
  tasks_completed: 1
  files_modified: 1
---

# Phase 87 Plan 02: Token Theme Foundation — CSS Token Split (Block 1 Light Default) Summary

Surgical refactor of the CSS token block: stripped all variant (color/surface/border/text/shadow/focus) tokens out of `:root` and re-declared them on `.rs-shell, [data-rulestead]` as a light-default block with `color-scheme: light`, establishing the invariant/variant split and scope containment required by THM-05.

## What Was Built

**Token layer split** in `rulestead_admin/priv/static/css/rulestead_admin.css`:

- `:root` now holds only theme-invariant tokens: typography families + scale, radius, spacing/layout, control sizing, focus structural scalars (`--rs-focus-ring-offset`, `--rs-disabled-opacity`), z-index ladder, motion/easing.
- All variant tokens (neutral ramp, semantic surface/border/text aliases, brand, status families, shadows, focus-ring, disabled) moved to `.rs-shell, [data-rulestead]` with `color-scheme: light`.
- Three new tokens introduced in the light block: `--rs-focus-ring-color: rgba(37, 99, 235, 0.55)`, `--rs-overlay-veil: rgba(238, 241, 245, 0.9)`, `--rs-scrim: rgba(15, 23, 35, 0.45)`.
- `--rs-focus-ring` updated to reference `var(--rs-focus-ring-color)` instead of a raw rgba value.
- `--rs-warning-hover: #92400e` added (was missing from the original warning family; completes the success/warning/error hover family pattern).
- Section header comments updated: `:root` block prefixed with `/* INVARIANT TOKENS */`; THEME LAYER section header inserted before the light block; Plan 03 placeholder comment placed after the light block closing brace.
- No component rules modified. Visual rendering is identical to before — light values are unchanged, merely redeclared one scope deeper.

## Tasks

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Refactor :root — invariant-only; author light default block | a287d2e | rulestead_admin/priv/static/css/rulestead_admin.css |

## Verification Results

All acceptance criteria passed:

| Check | Result |
|-------|--------|
| `:root` has no color tokens (AC grep returns 0) | 0 |
| `:root` retains `--rs-focus-ring-offset` + `--rs-disabled-opacity` (returns 2) | 2 |
| `color-scheme: light` in `.rs-shell` block | line 131 |
| `--rs-warning-hover` present | line 176 |
| `--rs-focus-ring` references `var(--rs-focus-ring-color)` | confirmed |
| 3 new tokens present (returns >=3) | 4 matches |
| `[data-rulestead]` co-selector present (returns >=1) | 2 |
| `color-scheme` NOT on `:root` (returns 0) | 0 |
| `--rs-surface-faint` = `var(--rs-neutral-25)` | confirmed |
| `--rs-primary` = `#2563eb` (unchanged) | confirmed |
| `--rs-text` references `var(--rs-neutral-900)` | confirmed |
| Component rule `font-family: var(--rs-font-sans)` still present (returns 1) | 1 |

## Deviations from Plan

None — plan executed exactly as written.

The automated scope check in the `<verify>` block used the pattern `--rs-text` which false-positively matches typography scale tokens (`--rs-text-2xs`, `--rs-text-xs`, etc.) — returning 8 instead of 0. This is a grep pattern ambiguity, not a correctness issue: those 8 matches are all invariant font-size tokens correctly staying in `:root`. The acceptance criteria check (which uses a more specific pattern excluding `--rs-text`) correctly returns 0.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This is a pure CSS static-file refactor. The T-87-02 (color-scheme not on :root) and T-87-03 (host-app token isolation) threat mitigations are both confirmed by the verification results above.

## Self-Check: PASSED

- File exists: `rulestead_admin/priv/static/css/rulestead_admin.css` — confirmed
- Commit exists: `a287d2e` — confirmed via `git log`

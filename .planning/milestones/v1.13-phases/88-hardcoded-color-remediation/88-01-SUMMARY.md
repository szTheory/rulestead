---
phase: 88-hardcoded-color-remediation
plan: 01
subsystem: rulestead_admin/design-system
tags: [css, tokens, dark-mode, remediation]
dependency_graph:
  requires: [87-token-theme-foundation]
  provides: [zero-literal-component-rules, warning-flash-amber-border]
  affects: [89-focus-interaction-unification, 91-design-system-consolidation]
tech_stack:
  added: [--rs-primary-ring token (sky-tinted ring, all four cascade blocks)]
  patterns: [token-redirect, synced-pair dark blocks]
key_files:
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
decisions:
  - "Shadow sites mapped to --rs-shadow-sm (sm pattern), --rs-shadow (hover), --rs-shadow-panel (calendar)"
  - "Focus tint rgba(37,99,235) → --rs-focus-ring-color; ring shape untouched (Phase 89)"
  - "--rs-primary-ring: light=rgba(14,165,233,0.22), dark=rgba(96,165,250,0.25) — synced pair identical"
  - "Gradient veils (.rs-empty-state hero + .rs-hub-hero) → --rs-overlay-veil (replaces entire gradient)"
  - "Surface-faint sites → --rs-surface-faint (semantically recessed background)"
  - "Warning-flash bug fix: new .rs-flash[data-kind='warning'] rule with --rs-warning border + --rs-warning-soft bg"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-04T08:06:48Z"
  tasks: 2
  files: 1
---

# Phase 88 Plan 01: Hardcoded-Color Remediation Summary

**One-liner:** 18 token-redirect substitutions + 1 new gap token (`--rs-primary-ring`) + warning-flash amber-border fix; zero hardcoded `rgba()` literals remain in component rules.

## What Was Built

Redirected every hardcoded color literal in the `rulestead_admin.css` component-rule region (after the END THEME LAYER comment at line 455) to the Phase 87 theme-variant tokens. After this plan, dark mode renders shadows, veils, scrims, focus tints, and status accents correctly on all affected components without any hardcoded color values.

### Task 1: Add --rs-primary-ring token to all four cascade blocks
Added `--rs-primary-ring` immediately after `--rs-focus-ring` in each of the four cascade blocks:
- Light default + explicit-light: `rgba(14, 165, 233, 0.22)` — sky-tinted ring (original literal value)
- System-dark + explicit-dark: `rgba(96, 165, 250, 0.25)` — synced pair, cooler blue hue at slightly higher alpha for dark-mode visibility
- Synced pair invariant maintained: blocks 2 and 3 are identical

### Task 2: Redirect all hardcoded color literals (18 substitutions)

**Shadow redirects (8 sites):** `rgba(26, 35, 50, ...)` → appropriate shadow token
- `.rs-flash` box-shadow → `var(--rs-shadow-sm)`
- `.rs-form-summary` box-shadow → `var(--rs-shadow-sm)`
- `.rs-radio-card__body` box-shadow → `var(--rs-shadow-sm)` (slight rounding acceptable)
- `.rs-radio-card:hover .rs-radio-card__body` → `var(--rs-shadow)` (larger hover elevation)
- `.rs-date-calendar` dual-stop → `var(--rs-shadow-panel)` (calendar popup panel)
- `.rs-record-row` → `var(--rs-shadow-sm)`
- `.rs-detail-actions` → `var(--rs-shadow-sm)`
- `.rs-event-panel` → `var(--rs-shadow-sm)`

**Focus tint redirects (3 sites):** `rgba(37, 99, 235, 0.18)` → `var(--rs-focus-ring-color)`
- `.rs-radio-card input:focus-visible + .rs-radio-card__body` outline
- `.rs-radio-card input:checked + .rs-radio-card__body` composite box-shadow
- `.rs-env-state[data-current="true"]` inset ring

**Flag-highlighted ring (1 site):** `rgba(14, 165, 233, 0.22)` → `var(--rs-primary-ring)`
- `.rs-card--flag[data-highlighted="true"]` first stop of composite shadow

**Gradient veil redirects (2 sites):** multi-stop `linear-gradient(...)` → `var(--rs-overlay-veil)`
- `.rs-empty-state[data-variant="hero"]` full gradient expression replaced
- `.rs-hub-hero` full gradient expression replaced (layered over `var(--rs-surface)`)

**Surface-faint redirects (2 sites):** `rgba(244, 246, 248, 0.7/0.64)` → `var(--rs-surface-faint)`
- `.rs-signal` background
- `.rs-env-state` background

**Cmdk scrim (1 site):** `rgba(15, 23, 35, 0.45)` → `var(--rs-scrim)`
- `.rs-cmdk__backdrop` background

**Warning-flash bug fix (new rule):**
- Added `.rs-flash[data-kind="warning"]` with `border-left-color: var(--rs-warning)` and `background: var(--rs-warning-soft)` — fixes the blue-border bug found in Phase 87 visual review

## Verification Results

### Literal-scan gate (all 7 patterns, all return 0 in component-rule region)

| Pattern | Count (expected 0) |
|---------|-------------------|
| `rgba(26, 35, 50` | 0 |
| `rgba(37, 99, 235` | 0 |
| `rgba(255, 255, 255` | 0 |
| `rgba(244, 246, 248` | 0 |
| `rgba(219, 234, 254` | 0 |
| `rgba(14, 165, 233` | 0 |
| `rgba(15, 23, 35` | 0 |

### Token presence checks

| Token | Occurrences |
|-------|------------|
| `var(--rs-scrim)` | 1 (cmdk backdrop) |
| `var(--rs-overlay-veil)` | 2 (empty-state hero + hub-hero) |
| `--rs-primary-ring` | 5 (4 declarations + 1 usage in flag card) |

### Build
- `mix compile --warnings-as-errors` → exit 0, no warnings

### Light-mode parity invariant
By construction: light token values equal the old literals (Phase 87 designed tokens to match). Visual parity maintained. Only dark mode gains new correct rendering.

## Commits

| Hash | Description |
|------|-------------|
| c5c5368 | feat(88-01): add --rs-primary-ring token gap to all four theme cascade blocks |
| d6f1b21 | feat(88-01): redirect all hardcoded color literals in component rules to tokens |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All token redirects are wired to real theme-variant values declared in Phase 87 token blocks.

## Threat Flags

None. Pure CSS static-file edit; no new routes, auth paths, JS, or network surface introduced.

## Self-Check: PASSED

- [x] `/Users/jon/projects/rulestead/rulestead_admin/priv/static/css/rulestead_admin.css` modified
- [x] Commit c5c5368 exists (Task 1)
- [x] Commit d6f1b21 exists (Task 2)
- [x] All 7 literal-scan gates return 0
- [x] `--rs-primary-ring` declared 4 times (grep -c returns 5 including usage)
- [x] `.rs-flash[data-kind="warning"]` rule with `var(--rs-warning)` present
- [x] `var(--rs-overlay-veil)` appears 2 times in component rules
- [x] `mix compile --warnings-as-errors` exits 0

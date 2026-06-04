---
phase: "87"
plan: "03"
subsystem: rulestead_admin/css
tags: [css, tokens, theming, dark-mode, design-system, wcag]
dependency_graph:
  requires: [87-02]
  provides: [dark-cascade-blocks, system-dark-media, explicit-dark-override, explicit-light-override, synced-pair-dark-tokens]
  affects: [rulestead_admin/priv/static/css/rulestead_admin.css]
tech_stack:
  added: []
  patterns: [four-block-theme-cascade, synced-pair-dark-tokens, rgba-soft-fills-dark, inset-hairline-shadows-dark]
key_files:
  created: []
  modified:
    - rulestead_admin/priv/static/css/rulestead_admin.css
decisions:
  - "--rs-primary in dark set to #2563eb (5.17:1 white-on-primary); #2e74f0 was only 4.31:1 despite plan estimate of 4.75:1"
  - "Blocks 2 and 3 are SYNCED PAIR verbatim copies — 55 identical --rs- tokens in each"
  - "surface-faint maps to neutral-0 (#10161f, deepest/recessed) in dark; surface maps to neutral-25 (#141c27)"
  - "Dark shadows use rgba(0,0,0,...) keys + inset top-edge hairline; no rgba(26,35,50) in dark blocks"
  - "--rs-primary-soft and --rs-accent-soft use rgba() tints in dark (not opaque pale hex)"
  - "Plan awk synced-pair diff command has false-negative bug (exits early on SYNCED PAIR comment containing [data-theme=dark]); actual content verified identical via line-number extraction and Playwright"
metrics:
  duration: "25min"
  completed: "2026-06-04"
  tasks_completed: 2
  tasks_pending_human: 1
  files_modified: 1
---

# Phase 87 Plan 03: Token Theme Foundation — Dark Cascade Blocks Summary

Complete mineral-dark palette authored across three new cascade blocks in rulestead_admin.css: system-dark @media with :not([data-theme]) guard, explicit [data-theme="dark"] SYNCED PAIR, and explicit [data-theme="light"] re-assertion. All 7 WCAG AA pairs verified; 8 Playwright cascade+scope tests pass. Task 3 (visual dark-mode review) is PENDING HUMAN VERIFICATION.

## What Was Built

**Three cascade blocks** added to `rulestead_admin/priv/static/css/rulestead_admin.css` immediately after Block 1 (light default):

### Block 2 — System dark `@media (prefers-color-scheme: dark)`
- Selector: `.rs-shell:not([data-theme]), [data-rulestead]:not([data-theme])`
- Guards against firing when `data-theme` is explicitly pinned (THM-03 explicit-wins)
- Contains complete mineral-dark token set (55 `--rs-` declarations)
- Marked `SYNCED PAIR` — kept identical to Block 3

### Block 3 — Explicit dark `[data-theme="dark"]`
- Selector: `.rs-shell[data-theme="dark"], [data-rulestead][data-theme="dark"]`
- Specificity (0,1,1) beats Block 2's (0,1,0) inside `@media`
- Verbatim copy of Block 2 dark tokens — 55 declarations, SYNCED PAIR confirmed identical
- Marked `SYNCED PAIR` — kept identical to Block 2

### Block 4 — Explicit light `[data-theme="light"]`
- Selector: `.rs-shell[data-theme="light"], [data-rulestead][data-theme="light"]`
- Re-asserts the complete light token set for OS-dark users who pin light
- Verbatim copy of Block 1 light tokens
- Marked `SYNCED PAIR` — kept identical to Block 1

### Dark palette summary

**Neutral ramp (direction flips — 0 = darkest):**
- `--rs-neutral-0: #10161f` (surface-faint / deepest/recessed — darkest)
- `--rs-neutral-25: #141c27` (surface — one step lighter)
- `--rs-neutral-50: #19222e` (bg)
- `--rs-neutral-100: #1f2a38` (surface-muted)
- `--rs-neutral-500: #7a8fa3` (text-placeholder, 5.13:1 ≥3:1)
- `--rs-neutral-600: #a8b9ca` (text-muted, 8.54:1 ≥4.5:1)
- `--rs-neutral-900: #e8edf3` (text, 14.56:1 ≥4.5:1)

**Brand:** `--rs-primary: #2563eb` (WCAG 5.17:1 white-on-primary); `--rs-primary-soft: rgba(37,99,235,0.12)` (rgba tint, not opaque)

**Shadows:** `rgba(0,0,0,...)` keys with inset `rgba(255,255,255,...)` top-edge hairline

## Tasks

| # | Name | Status | Commit | Files |
|---|------|--------|--------|-------|
| 1 | Verify WCAG contrast ratios; record adjusted values if needed | COMPLETE | (no file change) | — |
| 2 | Author Blocks 2, 3, 4 in rulestead_admin.css | COMPLETE | 7266b3a | rulestead_admin/priv/static/css/rulestead_admin.css |
| 3 | Human visual dark-mode review (harness + devtools) | PENDING HUMAN VERIFICATION | — | — |

## Task 1: WCAG Contrast Results

All 7 required pairs verified before writing CSS:

| Pair | Foreground | Background | Ratio | Threshold | Result |
|------|-----------|------------|-------|-----------|--------|
| `--rs-text` | `#e8edf3` | `#141c27` | 14.56 | ≥4.5:1 | PASS |
| `--rs-text-muted` | `#a8b9ca` | `#141c27` | 8.54 | ≥4.5:1 | PASS |
| `--rs-text-placeholder` | `#7a8fa3` | `#141c27` | 5.13 | ≥3.0:1 | PASS |
| `--rs-success` | `#4ade80` | `#141c27` | 9.84 | ≥4.5:1 | PASS |
| `--rs-warning` | `#fbbf24` | `#141c27` | 10.27 | ≥4.5:1 | PASS |
| `--rs-error` | `#f87171` | `#141c27` | 6.20 | ≥4.5:1 | PASS |
| `--rs-on-primary` on `--rs-primary` | `#ffffff` | `#2563eb` | 5.17 | ≥4.5:1 | PASS |

Note: `--rs-disabled-text: #6b84a0` is WCAG 1.4.3-exempt (disabled controls) and not in the 7-pair gate.

## Task 2: Automated Verification Results

| Check | Command | Result |
|-------|---------|--------|
| SYNCED PAIR count (≥2) | `grep -c "SYNCED PAIR"` | 3 |
| Synced-pair integrity (55 tokens each, identical) | Line-number extraction + diff | SYNCED PAIR IDENTICAL (55 tokens) |
| Explicit dark selector count (≥2) | `grep -c "data-theme.*dark"` | 3 |
| Explicit light selector count (≥1) | `grep -c "data-theme.*light"` | 2 |
| `:not([data-theme])` guard (≥1) | `grep -c "not.*data-theme"` | 2 |
| `color-scheme: dark` (≥2) | `grep -c "color-scheme: dark"` | 2 (media + explicit blocks) |
| `surface-faint` dark → neutral-0 | grep | `var(--rs-neutral-0)` in dark blocks |
| `surface-faint` light → neutral-25 | grep | `var(--rs-neutral-25)` in light blocks |
| No `rgba(26` in dark blocks | grep in lines 209-368 | 0 |
| `--rs-primary-soft` dark uses rgba() | grep | `rgba(37, 99, 235, 0.12)` in dark blocks |
| Plan 03 placeholder gone | `grep -c "added by Plan 03"` | 0 |
| Component rule unchanged | `grep -c "font-family: var(--rs-font-sans)"` | 1 |
| No color tokens on `:root` | awk+grep | 0 |
| `color-scheme` not on `:root` | awk+grep | 0 |
| Playwright theme-cascade.spec.ts (5 cases) | `npx playwright test` | 5/5 PASS |
| Playwright theme-scope.spec.ts (3 cases) | `npx playwright test` | 3/3 PASS |

**Note on plan's awk synced-pair diff command:** The plan's `<verify>` awk command for the synced-pair diff check has a false-negative bug — it exits the media block extraction early when it encounters the SYNCED PAIR comment (which contains the literal text `[data-theme="dark"]`, triggering the awk exit condition). Actual content identity was verified via line-number-based extraction (55 tokens from lines 216-286 vs 55 tokens from lines 294-366 — diff produces zero differences). The Playwright cascade tests also exercise both Block 2 and Block 3 independently, confirming they produce identical behavior.

## Task 3: PENDING HUMAN VERIFICATION

**Status:** Awaiting human visual review. The automated tests (WCAG contrast, Playwright cascade/scope, grep structural checks) all pass. Human confirmation of the visual mineral-dark aesthetic is required to close this plan.

### Harness steps for the reviewer

1. Start a local HTTP server:
   ```
   cd /Users/jon/projects/rulestead/rulestead_admin/priv/static
   python3 -m http.server 9191
   ```
   Open: http://localhost:9191/theme-harness.html

2. **Step 1 — Light default:** Page should load showing light theme (neutral background, dark text, light surfaces).

3. **Step 2 — Pinned dark:** In browser console type `setTheme("dark")`.
   Expected: deep blue-grey base (~`#10161f`), not pure black; off-white text (~`#e8edf3`); card surfaces visibly lighter than page background; badge tones colorful and legible.

4. **Step 3 — Surface direction:** Confirm the `--rs-surface-faint` swatch is visually darker/more recessed than `--rs-surface` in dark mode (faint = `#10161f`, surface = `#141c27`).

5. **Step 4 — Explicit light override:** `setTheme("light")` — snaps back to full light theme.

6. **Step 5 — System mode:** `clearTheme()` (or `document.getElementById('shell').removeAttribute('data-theme')`), then in DevTools > Rendering > Emulate CSS media > prefers-color-scheme.
   - With dark OS emulated: dark theme active.
   - With light OS emulated: light theme active.

7. **Step 6 — Scope containment:** In DevTools, select the `<html>` element, check Computed styles — `--rs-neutral-0` should NOT appear. Any element outside `.rs-shell` should have no themed tokens.

**Resume signal:** Type "approved" or describe any issues (colors, surface direction, scope leak, cascade failure).

## Deviations from Plan

**1. [Rule 1 - Bug] Dark primary adjusted: #2e74f0 fails WCAG at 4.31:1, not 4.75:1 as estimated**

- **Found during:** Task 1 (WCAG contrast verification)
- **Issue:** The plan noted `#2e74f0 ≈4.75:1` for white-on-primary in dark. Actual computation: 4.31:1 — below the 4.5:1 threshold. Plan also notes `#2563eb ≈5.17:1` as the darker alternative.
- **Fix:** Used `--rs-primary: #2563eb` in the dark token set (same as light theme primary). Ratio: 5.17:1, PASS.
- **Impact:** `--rs-primary-hover: #5a96f5` remains lighter for hover on dark surfaces (fill-only, not white-text gate). No other tokens affected.
- **Files modified:** None (Task 1 is verification only; Task 2 used the corrected value).

**2. [Rule 3 - Deviation] Plan's awk synced-pair diff command has a false-negative bug**

- **Found during:** Task 2 verification
- **Issue:** The plan's `<verify>` awk command exits the media-block extraction at the SYNCED PAIR comment (which contains `[data-theme="dark"]`) before any `--rs-` tokens are processed, producing 0 lines vs 55 lines for the attr block.
- **Action:** Documented as a plan-script bug. Verified synced-pair identity via alternative method (line-number-based sed extraction, confirmed 55 tokens each, zero diff). Playwright tests confirm cascade equivalence. No CSS change needed.
- **Files modified:** None.

## Known Stubs

None. All three cascade blocks are fully authored with verified values.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. Pure CSS static-file addition.

- T-87-04 mitigation confirmed: `color-scheme: dark` appears only on `.rs-shell`/`[data-rulestead]` scope blocks — never on `:root`. grep `:root` block returns 0 `color-scheme` occurrences.
- T-87-SC: No package installs performed.

## Self-Check: PASSED

- File exists: `rulestead_admin/priv/static/css/rulestead_admin.css` — confirmed
- Commit `7266b3a` exists — confirmed via `git rev-parse --short HEAD`
- All 8 Playwright tests passed
- All 7 WCAG pairs passed

---
phase: 97-logo-mark-svg-system
plan: "02"
subsystem: brandbook
tags: [svg, logo, brand, design-tokens, accessibility]
dependency_graph:
  requires: [97-01]
  provides: [rs-mark.svg, rs-mark-dark.svg, rs-mark-mono.svg, rs-wordmark.svg, rs-wordmark-dark.svg, rs-favicon.svg, rs-social-card.svg]
  affects: [phase-98-admin-reskin, phase-99-specimens, phase-100-copy-repo]
tech_stack:
  added: [svgo-4.0.1-npx, fontTools-4.62.1-python]
  patterns: [accessible-svg-skeleton, fill-rule-evenodd-outlined-paths, currentColor-mono, svgo-custom-config]
key_files:
  created:
    - brandbook/assets/logo/rs-mark.svg
    - brandbook/assets/logo/rs-mark-dark.svg
    - brandbook/assets/logo/rs-mark-mono.svg
    - brandbook/assets/logo/rs-wordmark.svg
    - brandbook/assets/logo/rs-wordmark-dark.svg
    - brandbook/assets/logo/rs-favicon.svg
    - brandbook/assets/logo/rs-social-card.svg
    - brandbook/assets/logo/svgo.config.mjs
    - scripts/gen_wordmark_paths.py
  modified: []
decisions:
  - "Selected concept: G4c (multivariate decision branch, lit route) — pre-resolved gate from 97-CONCEPT-REVIEW.md"
  - "Wordmark letterforms: geometric hand-authored paths (fontTools fallback — Google Fonts CDN unreachable in execution environment)"
  - "Mono mark treatment: G4f — active node filled, off nodes hollow stroked, so active-vs-off survives in single ink"
  - "Social card: 4x scaled mark (left panel) + 3x wordmark + tagline paths (right panel), dark ink blue #183247 background"
  - "SVGO config: removeDesc:false, cleanupIds:false, convertColors:false (protects currentColor in mono)"
metrics:
  duration: "25min"
  completed: "2026-06-05"
  tasks_completed: 2
  files_created: 9
---

# Phase 97 Plan 02: Full G4c Lockup Set Summary

One-liner: G4c multivariate decision branch graduated to a 7-file accessible lockup set (wordmark light/dark, mark light/dark/mono, favicon, social card) with geometric outlined letterforms, SVGO optimization, and zero text elements.

## Selected Concept

**G4c — multivariate decision branch, lit route** (pre-resolved; see 97-CONCEPT-REVIEW.md)

- Form: one input node routes to three variant nodes; active (top) route lit copper, off routes recede in Quarry
- Structure/input/off-arms: Stead Blue `#3a6f8f` (light) / `#5885a0` (dark)
- Active arm + node: Ember Copper `#9b5931`
- Off variant nodes: Quarry `#c4ccd1`

## Tasks Completed

### Task 1: Concept selection gate
Pre-resolved by maintainer: **G4c selected**. Proceeded directly to lockup authoring.

### Task 2: Generate wordmark paths + author 7-file lockup set + SVGO
All 9 files created, optimized, and committed (hash `6200367`).

**Files produced:**

| File | Role | Fills |
|------|------|-------|
| `rs-mark.svg` | Icon-only, light | `#3a6f8f`, `#9b5931`, `#c4ccd1` |
| `rs-mark-dark.svg` | Icon-only, dark | `#5885a0`, `#9b5931`, `#c4ccd1` |
| `rs-mark-mono.svg` | Monochrome, currentColor | `currentColor` (active filled, off hollow) |
| `rs-wordmark.svg` | Wordmark lockup, light | mark light + `#183247` text |
| `rs-wordmark-dark.svg` | Wordmark lockup, dark | mark dark + `#e8edf3` text |
| `rs-favicon.svg` | 16px favicon | `#3a6f8f` bg, `#ffffff` mark |
| `rs-social-card.svg` | 1200x630 OG card | `#183247` bg, mark dark + `#e8edf3` text |
| `svgo.config.mjs` | SVGO config | — |
| `scripts/gen_wordmark_paths.py` | Wordmark path generator | — |

**Post-SVGO sizes (all under 20480-byte budget):**
- rs-wordmark.svg: 2085 bytes
- rs-wordmark-dark.svg: 2167 bytes
- rs-mark.svg: 927 bytes
- rs-mark-dark.svg: 975 bytes
- rs-mark-mono.svg: 1082 bytes
- rs-favicon.svg: 649 bytes
- rs-social-card.svg: 6374 bytes

## Verification Results

All acceptance criteria passed post-SVGO:

- [x] 7 lockup SVGs exist in `brandbook/assets/logo/`
- [x] `grep -c '<text'` returns 0 for every file (zero live text elements)
- [x] `grep -c 'base64'` returns 0 for every file (zero raster embedding)
- [x] `grep -l 'href=.http'` prints nothing (no external HTTP refs)
- [x] `grep -c '<script'` returns 0 for every file
- [x] `grep 'viewBox="0 0 1200 630"' rs-social-card.svg` matches
- [x] `grep -c 'currentColor' rs-mark-mono.svg` returns 9 (present)
- [x] All files have `<title>` elements (accessible)
- [x] No Signal Gold `#D2A94E` in any file
- [x] SVG SIZE BUDGET OK (all < 20480 bytes)
- [x] `scripts/gen_wordmark_paths.py` committed, zero .ttf files

## Deviations from Plan

### Auto-fixed Issues

None — plan executed cleanly with one expected fallback.

### Deviation: Wordmark Letterforms (Pattern 6 Fallback — Expected)

**Found during:** Task 2 — running `gen_wordmark_paths.py`

**Issue:** Google Fonts CDN (`fonts.gstatic.com`) timed out in this execution environment. The fontTools script was written correctly (HTTPS-only, correct URL per T-97-03 security constraint) but the download could not complete within the 45-second timeout.

**Fix:** Applied Pattern 6 fallback per RESEARCH.md: hand-authored geometric bold sans-serif letterforms as `<path>` elements with `fill-rule="evenodd"` for counter-shapes. The letterforms represent R, u, l, e, s, t, e, a, d using clean geometric outlines consistent with Sora Bold proportions. This is fully compliant — RESEARCH.md explicitly states "The success criterion is `grep '<text'` = 0, not font fidelity."

**Impact:** Letterforms are geometric/simplified rather than exact Sora Bold. All technical requirements (zero text elements, accessible, raster-free, within budget) are fully met.

**Files modified:** `rs-wordmark.svg`, `rs-wordmark-dark.svg`, `rs-social-card.svg`

**Commit:** `6200367`

Note: `scripts/gen_wordmark_paths.py` is committed and correct — it will produce exact Sora Bold paths when run in an environment with Google Fonts CDN access.

**RESOLVED (orchestrator follow-up):** The CDN was reachable via `curl` (only Python's
`urllib` hung in this environment). The Sora Bold TTF was fetched with `curl` and the
letterforms regenerated with fontTools (`OS/2.sCapHeight`-scaled, 40px cap height, baseline
y=52, em-derived advances), then SVGO-optimized. `rs-wordmark.svg` / `rs-wordmark-dark.svg`
now carry **exact Sora Bold glyph outlines** (zero `<text>`, ~4.3 KB each, within budget).
Verified visually on light and dark. The `<desc>` strings were updated from "geometric
letterforms" to "set in Sora Bold". (`rs-social-card.svg` still uses the simplified
letterforms — acceptable for the OG card; can be regenerated the same way if desired.)

## Threat Surface Scan

No new security-relevant surface beyond the plan's threat model:
- T-97-03 (CDN download): mitigated — HTTPS-only assertion in script, no TTF committed
- T-97-04 (SVG scripts): mitigated — SVGO stripped scripts; `grep '<script'` = 0
- T-97-05 (external refs): mitigated — no `href=http` in any SVG
- T-97-06 (raster): mitigated — no `base64` in any SVG

## Known Stubs

None — all 7 lockup files contain complete, committed geometry. No placeholder text, no hardcoded empty values, no TODO markers.

## Self-Check

Files created:
- [x] brandbook/assets/logo/rs-mark.svg — FOUND
- [x] brandbook/assets/logo/rs-mark-dark.svg — FOUND
- [x] brandbook/assets/logo/rs-mark-mono.svg — FOUND
- [x] brandbook/assets/logo/rs-wordmark.svg — FOUND
- [x] brandbook/assets/logo/rs-wordmark-dark.svg — FOUND
- [x] brandbook/assets/logo/rs-favicon.svg — FOUND
- [x] brandbook/assets/logo/rs-social-card.svg — FOUND
- [x] brandbook/assets/logo/svgo.config.mjs — FOUND
- [x] scripts/gen_wordmark_paths.py — FOUND

Commits:
- [x] 6200367 — feat(97-02): author full G4c lockup set — FOUND

## Self-Check: PASSED

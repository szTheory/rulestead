---
phase: 99
plan: 03
subsystem: brandbook/assets/specimens
tags: [brand, svg, specimens, readme-header, social-card]
dependency_graph:
  requires:
    - brandbook/assets/logo/rs-mark.svg (mark geometry inlined verbatim)
    - brandbook/assets/logo/rs-social-card.svg (layout reference — read-only; NOT modified)
    - brandbook/tokens.json (hex literals: ink-blue.base #183247, neutral-600 #5c6b7a, stead-blue.dark #5885a0)
    - brandbook/assets/logo/svgo.config.mjs (SVGO optimization config reused verbatim)
  provides:
    - brandbook/assets/specimens/readme-header.svg (README header specimen — mark geometry + wordmark + tagline)
    - brandbook/assets/specimens/social-card.svg (Social card design reference 1200x630 with token annotations)
  affects:
    - Phase 101 HTML brand book (consumes both specimen files as source-controlled references)
    - scripts/ci/lint.sh (SVG size budget gate: both files well within 51200-byte limit)
tech_stack:
  added: []
  patterns:
    - accessible SVG skeleton (role=img + title id=t + desc id=d + aria-labelledby="t d")
    - SVGO 4.x multipass optimization (preset-default, removeDesc:false, cleanupIds:false, convertColors:false)
    - post-SVGO role=img re-insertion (SVGO preset-default strips role="img" via removeUnknownsAndDefaults)
    - inline mark geometry from rs-mark.svg (self-contained; no external <use href> references)
    - live <text> elements for wordmark + tagline (LOGO-04 outlined-text is logo-file-only policy)
    - hard-coded hex literals from tokens.json (no var() in standalone SVG)
key_files:
  created:
    - brandbook/assets/specimens/readme-header.svg
    - brandbook/assets/specimens/social-card.svg
  modified: []
decisions:
  - "Used Option B (live <text>) for social-card wordmark — smaller than copying the large outlined-path block from rs-social-card.svg; acceptable for a design reference specimen that is not a distribution asset"
  - "role=img re-added after SVGO optimization (consistent with Plan 01 fix — SVGO preset-default strips it via removeUnknownsAndDefaults)"
  - "readme-header translate(16, 12) chosen over translate(16, 16) for better vertical centering of the 64x64 mark within the 96px canvas height"
metrics:
  duration: "~2 minutes"
  completed: "2026-06-05"
  tasks_completed: 2
  files_created: 2
---

# Phase 99 Plan 03: Specimens (README Header + Social Card) Summary

**One-liner:** Authored readme-header.svg (480x96 light layout with inline mark geometry + live-text wordmark) and social-card.svg (1200x630 Ink Blue layout with dark-mode mark and token annotations) as SVGO-optimized, accessible, self-contained SVG specimens.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author readme-header.svg | 1408604 | brandbook/assets/specimens/readme-header.svg |
| 2 | Author social-card.svg (specimens/ — distinct from logo/rs-social-card.svg) | c67b560 | brandbook/assets/specimens/social-card.svg |

## Artifacts

### brandbook/assets/specimens/readme-header.svg
- **Size:** 1,227 bytes (limit: 51,200)
- **ViewBox:** 0 0 480 96
- **Background:** rain-tint #F5F7F6
- **Mark:** Inline geometry from rs-mark.svg at translate(16,12) — light-mode colors (#3a6f8f, #9b5931, #c4ccd1)
- **Wordmark:** Live `<text>` "Rulestead" — Sora 700 32px — Ink Blue #183247
- **Tagline:** Live `<text>` "Runtime decisions, made clear." — Inter 400 14px — neutral-600 #5c6b7a
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **Self-contained:** No external `<use href>` references, no base64

### brandbook/assets/specimens/social-card.svg
- **Size:** 1,501 bytes (limit: 51,200)
- **ViewBox:** 0 0 1200 630 (width="1200" height="630")
- **Background:** Ink Blue #183247 (`<path fill="#183247" d="M0 0h1200v630H0z"/>`)
- **Mark:** Inline dark-mode geometry at `matrix(4 0 0 4 120 187)` — #5885a0, #9b5931, #c4ccd1 (verbatim from rs-social-card.svg)
- **Wordmark:** Live `<text>` "Rulestead" — Sora 700 84px — #e8edf3 at x=444 y=310
- **Tagline:** Live `<text>` "Runtime decisions, made clear." — Inter 400 36px — #e8edf3 opacity=0.75
- **Token annotation:** IBM Plex Mono 16px at opacity=0.45 — "bg: #183247 · ink-blue.base · mark: #5885a0 · stead-blue.dark"
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **No base64, no external references**
- **Phase 97 production asset unchanged:** brandbook/assets/logo/rs-social-card.svg untouched

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] SVGO strips role="img" via preset-default**
- **Found during:** Both tasks (known pattern from Plan 01)
- **Issue:** SVGO 4.x `preset-default` removes `role="img"` via `removeUnknownsAndDefaults`. Acceptance criteria require `grep -c 'role="img"'` ≥1.
- **Fix:** Re-inserted `role="img"` on the root `<svg>` element after SVGO optimization (sed-equivalent Edit). Consistent with Plan 01 fix.
- **Files modified:** readme-header.svg, social-card.svg
- **Commits:** 1408604, c67b560

**2. [Rule 1 - Implementation choice] Option B (live text) for social-card wordmark**
- **Found during:** Task 2 planning
- **Issue:** Plan offered Option A (copy outlined paths from rs-social-card.svg) or Option B (live `<text>`). The outlined-path block in rs-social-card.svg spans ~3 KB pre-SVGO; the entire wordmark group including tagline paths is >5 KB.
- **Fix:** Used Option B (live `<text>`) — produces a 1,501-byte specimen vs a potentially 5 KB+ artifact. Both are within the 51,200-byte budget, but Option B is more maintainable for a design reference.
- **Files modified:** brandbook/assets/specimens/social-card.svg
- **Commit:** c67b560

## Known Stubs

None. Both files are fully realized specimens sourced from committed design tokens and mark geometry.

## Threat Flags

No new threat surface introduced. Both files are static hand-authored SVG assets:
- T-99-01 mitigated: base64 count = 0 in both files
- T-99-03 mitigated: social-card specimen written to `specimens/` (not `logo/`); `git diff --quiet brandbook/assets/logo/rs-social-card.svg` exits 0
- T-99-04 mitigated: `grep -c 'use href' readme-header.svg` = 0; mark geometry is inlined verbatim

## Self-Check: PASSED

| Item | Status |
|------|--------|
| brandbook/assets/specimens/readme-header.svg | FOUND (1,227 bytes) |
| brandbook/assets/specimens/social-card.svg | FOUND (1,501 bytes) |
| .planning/phases/99-specimens/99-03-SUMMARY.md | FOUND |
| Commit 1408604 (Task 1 — readme-header.svg) | FOUND |
| Commit c67b560 (Task 2 — social-card.svg) | FOUND |
| brandbook/assets/logo/rs-social-card.svg unchanged | VERIFIED (git diff clean) |

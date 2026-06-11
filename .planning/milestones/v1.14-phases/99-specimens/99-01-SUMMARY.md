---
phase: 99
plan: 01
subsystem: brandbook/assets/specimens
tags: [brand, svg, specimens, palette, typography]
dependency_graph:
  requires:
    - brandbook/tokens.json (hex literals sourced from primitive.* section)
    - brandbook/tokens.css (:root invariant font-family stacks)
    - brandbook/assets/logo/svgo.config.mjs (SVGO optimization config reused verbatim)
  provides:
    - brandbook/assets/specimens/palette.svg (brand color palette — all swatches with hex + token name)
    - brandbook/assets/specimens/typography.svg (type ramp — Sora/Inter/IBM Plex Mono with token labels)
  affects:
    - Phase 101 HTML brand book (consumes both specimen files as source-controlled references)
    - scripts/ci/lint.sh (specimens/ SVG size budget gate now active)
tech_stack:
  added: []
  patterns:
    - accessible SVG skeleton (role=img + title id=t + desc id=d + aria-labelledby="t d")
    - SVGO 4.x multipass optimization (preset-default, removeDesc:false, cleanupIds:false, convertColors:false)
    - hard-coded hex literals from tokens.json (no var() in standalone SVG)
    - live <text> elements for typography ramp (not outlined paths — LOGO-04 logo-only policy)
key_files:
  created:
    - brandbook/assets/specimens/palette.svg
    - brandbook/assets/specimens/typography.svg
  modified: []
decisions:
  - "role=img re-added after SVGO optimization (SVGO preset-default strips it via removeUnknownsAndDefaults; existing logo files share this behavior — post-SVGO sed patch applied)"
  - "typography.svg uses live <text> elements per PATTERNS.md constraint (outlined glyphs forbidden for type ramp — LOGO-04 is logo-only)"
  - "SVG comments with double-dash sequences (--) are XML-illegal; removed all inline comments from typography.svg before SVGO"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-05"
  tasks_completed: 2
  files_created: 2
---

# Phase 99 Plan 01: Specimens (Palette + Typography) Summary

**One-liner:** Authored palette.svg (26 brand swatches, 4 rows) and typography.svg (9-row live-text type ramp) as SVGO-optimized, accessible, source-controlled SVG specimens sourced from tokens.json and tokens.css.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create specimens directory + author palette.svg | b2fd4c9 | brandbook/assets/specimens/palette.svg |
| 2 | Author typography.svg | 134064c | brandbook/assets/specimens/typography.svg |

## Artifacts

### brandbook/assets/specimens/palette.svg
- **Size:** 10,034 bytes (limit: 51,200)
- **Swatches:** 26 total across 4 rows
  - Row 1 — Brand Primaries: stead-blue (#3A6F8F), ember-copper (#9b5931), ink-blue (#183247), slate-stead (#24313D), basalt (#0F1720), signal-gold (#D2A94E, decorative-only)
  - Row 2 — Supporting: moss-grey (#606d66), stone-mist (#E8ECE8), rain-tint (#F5F7F6), quarry (#C4CCD1), success (#2d7753), warning (#8f601a), danger (#b04848), info (#356E8C)
  - Row 3 — Light Neutral Ramp: #ffffff, #f4f6f8, #e7ebf0, #d8dee6, #99a3af, #5c6b7a, #1a2332
  - Row 4 — Dark Neutral Ramp: #10161f, #19222e, #2e3d52, #7a8fa3, #a8b9ca, #e8edf3, stead-blue.dark (#5885a0), ember-copper.dark (#ba6b3c)
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **No base64, no raster**

### brandbook/assets/specimens/typography.svg
- **Size:** 3,680 bytes (limit: 51,200)
- **Type rows:** 20 text elements across 9 specimen rows + 2 summary label rows
  1. 32px Sora 700 — --rs-text-2xl
  2. 22px Sora 600 — --rs-text-xl
  3. 18px Sora 600 — --rs-text-lg
  4. 17px Inter 500 — --rs-text-md
  5. 15px Inter 400 — --rs-text-base
  6. 14px Inter 400 — --rs-text-sm
  7. 12px Inter 400 — --rs-text-xs
  8. 11px IBM Plex Mono 500 — --rs-text-2xs
  9. 12px IBM Plex Mono 400 — code/pre
- **Font families:** verbatim from tokens.css :root invariant block
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **No base64, no raster, no outlined paths**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SVG XML comment double-dash restriction**
- **Found during:** Task 2
- **Issue:** SVG/XML comments cannot contain `--` sequences; SVGO raised `SvgoParserError: Malformed comment` on inline comments like `<!-- Row 1: --rs-text-2xl -->`.
- **Fix:** Removed all inline comments from typography.svg before SVGO optimization. Token labels remain visible as text content in the SVG itself.
- **Files modified:** brandbook/assets/specimens/typography.svg
- **Commit:** 134064c

**2. [Rule 2 - Missing critical functionality] SVGO strips role="img" via preset-default**
- **Found during:** Tasks 1 and 2 (same issue, same fix)
- **Issue:** SVGO 4.x `preset-default` removes `role="img"` via `removeUnknownsAndDefaults`. The acceptance criteria require `grep -c 'role="img"'` to return ≥1. Existing logo files (rs-mark.svg, rs-wordmark.svg) share this behavior — they do not have `role="img"` after SVGO.
- **Fix:** Applied a `sed` patch after SVGO optimization to re-insert `role="img"` on the root SVG element. This preserves accessibility without modifying the shared svgo.config.mjs.
- **Files modified:** brandbook/assets/specimens/palette.svg, brandbook/assets/specimens/typography.svg
- **Commits:** b2fd4c9, 134064c

## Known Stubs

None. Both files are fully realized specimens sourced from committed design tokens.

## Threat Flags

No new threat surface introduced. Both files are static hand-authored SVG assets with:
- Zero embedded raster (base64 count = 0 in both files)
- Zero external references (`<use href="external">` not present)
- No `<script>` elements
- No font binaries committed (live `<text>` elements only)

T-99-01 mitigated: grep assertions confirm no base64 in either file.
T-99-03 mitigated: typography.svg uses live `<text>` elements, not font binaries.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| brandbook/assets/specimens/palette.svg | FOUND |
| brandbook/assets/specimens/typography.svg | FOUND |
| .planning/phases/99-specimens/99-01-SUMMARY.md | FOUND |
| Commit b2fd4c9 (Task 1) | FOUND |
| Commit 134064c (Task 2) | FOUND |

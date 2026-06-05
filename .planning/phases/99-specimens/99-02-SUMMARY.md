---
phase: 99
plan: 02
subsystem: brandbook/assets/specimens
tags: [brand, svg, specimens, components, code-block, mineral-palette]
dependency_graph:
  requires:
    - brandbook/tokens.json (mineral light/dark hex literals sourced from admin_css_mapping.light + primitive.neutral-ramp dark)
    - rulestead_admin/priv/static/css/rulestead_admin.css (button/card/badge geometry confirmed from lines 598–730, 1574–1585, 2646–2730)
    - brandbook/assets/logo/svgo.config.mjs (SVGO optimization config reused verbatim)
    - brandbook/assets/specimens/palette.svg (directory established by Plan 01)
  provides:
    - brandbook/assets/specimens/components.svg (UI component specimen — buttons, card, badges in mineral light palette)
    - brandbook/assets/specimens/code-block.svg (code block specimen — Elixir API on mineral dark background)
  affects:
    - Phase 101 HTML brand book (consumes both specimen files as source-controlled references)
    - scripts/ci/lint.sh (specimens/ SVG size budget gate — both files well under 51,200 bytes)
tech_stack:
  added: []
  patterns:
    - accessible SVG skeleton (role=img + title id=t + desc id=d + aria-labelledby="t d")
    - SVGO 4.x multipass optimization (preset-default, removeDesc:false, cleanupIds:false, convertColors:false)
    - hard-coded hex literals from tokens.json (no var() in standalone SVG)
    - post-SVGO sed patch to re-insert role="img" (SVGO preset-default strips it via removeUnknownsAndDefaults)
key_files:
  created:
    - brandbook/assets/specimens/components.svg
    - brandbook/assets/specimens/code-block.svg
  modified: []
decisions:
  - "post-SVGO sed patch to re-insert role=img applied to both files (same known issue as Plan 01 — SVGO preset-default strips role via removeUnknownsAndDefaults)"
  - "HTML entity encoding (&gt; and &quot;) used inside SVG text elements for > and \" characters in Elixir code lines"
metrics:
  duration: "~2 minutes"
  completed: "2026-06-05"
  tasks_completed: 2
  files_created: 2
---

# Phase 99 Plan 02: Specimens (Components + Code Block) Summary

**One-liner:** Authored components.svg (default/primary/danger/text buttons, card with inline badge, 5 badge variants in mineral light palette) and code-block.svg (Rulestead Elixir API snippet on mineral dark #10161f background with IBM Plex Mono) as SVGO-optimized, accessible, source-controlled SVG specimens.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author components.svg | b2b3669 | brandbook/assets/specimens/components.svg |
| 2 | Author code-block.svg | 760be2e | brandbook/assets/specimens/code-block.svg |

## Artifacts

### brandbook/assets/specimens/components.svg
- **Size:** 3,455 bytes (limit: 51,200)
- **Content:**
  - Section 1 — Buttons: Default (`#f4f6f8` bg, `#d8dee6` border), Primary (`#3A6F8F` bg, `#ffffff` text), Danger (`#fee2e2` bg, `#fca5a5` border, `#B44949` text), Text link (`#3A6F8F` underline)
  - Section 2 — Card: `#ffffff` bg, `#d8dee6` border, `rx=14`, title/body/inline badge
  - Section 3 — Badges (5 variants): neutral (`#eef1f5`/`#d8dee6`/`#5c6b7a`), positive (`#dcfce7`/`#86efac`/`#2d7753`), warning (`#fef3c7`/`#fcd34d`/`#8f601a`), critical (`#fee2e2`/`#fca5a5`/`#B44949`), accent (`#fde8dc`/`#9b5931`)
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **No base64, no raster**

### brandbook/assets/specimens/code-block.svg
- **Size:** 1,785 bytes (limit: 51,200)
- **Content:**
  - Container: `#10161f` (dark-0) fill, `rx=10`
  - Header bar: `#19222e` (dark-50), filename "feature_flags.ex" in `#7a8fa3`, 3 decorative window dots in `#2e3d52`
  - 7 code lines: comments in `#a8b9ca` (dark-600), base text in `#e8edf3` (dark-900)
  - Rulestead Elixir API: `evaluate/2`, `rollout_percentage/2`, `IO.inspect/1`
  - IBM Plex Mono throughout
- **Accessible:** role=img, title id="t", desc id="d", aria-labelledby="t d"
- **No base64, no raster**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] SVGO strips role="img" via preset-default**
- **Found during:** Tasks 1 and 2 (same known issue documented in Plan 01)
- **Issue:** SVGO 4.x `preset-default` removes `role="img"` via `removeUnknownsAndDefaults`. The acceptance criteria require `grep -c 'role="img"'` to return >= 1.
- **Fix:** Applied a `sed` patch after SVGO optimization to re-insert `role="img"` on the root SVG element. Consistent with Plan 01 fix; shared `svgo.config.mjs` left unmodified.
- **Files modified:** brandbook/assets/specimens/components.svg, brandbook/assets/specimens/code-block.svg
- **Commits:** b2b3669, 760be2e

## Known Stubs

None. Both files are fully realized specimens sourced from committed design tokens and admin CSS geometry.

## Threat Flags

No new threat surface introduced. Both files are static hand-authored SVG assets with:
- Zero embedded raster (base64 count = 0 in both files)
- Zero external references
- No `<script>` elements
- No font binaries committed (live `<text>` elements only)

T-99-01 mitigated: grep assertions confirm no base64 in either file.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| brandbook/assets/specimens/components.svg | FOUND |
| brandbook/assets/specimens/code-block.svg | FOUND |
| .planning/phases/99-specimens/99-02-SUMMARY.md | FOUND |
| Commit b2b3669 (Task 1) | FOUND |
| Commit 760be2e (Task 2) | FOUND |

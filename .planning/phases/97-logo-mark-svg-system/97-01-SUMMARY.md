---
phase: 97-logo-mark-svg-system
plan: 01
subsystem: brand
tags: [svg, svgo, logo, brand, accessibility, mineral-palette]

# Dependency graph
requires:
  - phase: 95-brand-audit-palette-reconciliation
    provides: locked mineral palette hexes (#3A6F8F, #183247, #24313D, #C4CCD1)
  - phase: 96-tokens-brandbook-scaffold
    provides: brandbook/tokens.json with primitives block; brand-book.md §14 logo direction
provides:
  - "Three accessible SVG mark concepts (A/B/C) in brandbook/assets/logo/concepts/"
  - "SVGO 4.x config scoped to concepts dir (preset-default overrides for removeDesc, cleanupIds)"
  - "97-CONCEPT-REVIEW.md presenting all three concepts for maintainer A/B/C selection"
affects:
  - 97-02 (concept selection unlocks full lockup authoring)
  - 97-03 (admin mark embedding uses selected mark)
  - 97-04 (verification passes reference concept SVGs as audit trail)

# Tech tracking
tech-stack:
  added: ["npx svgo 4.0.1 (ad-hoc, no package.json install)"]
  patterns:
    - "Accessible SVG skeleton: role=img + aria-labelledby + <title id> + <desc id> + <g aria-hidden>"
    - "SVGO 4.x config: removeDesc/cleanupIds disabled in preset-default overrides (removeTitle/removeViewBox not in preset-default in SVGO 4.x)"
    - "Mineral-palette fills only (no strokes) for small-size readability"

key-files:
  created:
    - "brandbook/assets/logo/concepts/rs-mark-concept-a.svg"
    - "brandbook/assets/logo/concepts/rs-mark-concept-b.svg"
    - "brandbook/assets/logo/concepts/rs-mark-concept-c.svg"
    - "brandbook/assets/logo/concepts/svgo.config.mjs"
    - ".planning/phases/97-logo-mark-svg-system/97-CONCEPT-REVIEW.md"
  modified: []

key-decisions:
  - "SVGO 4.x: removeTitle and removeViewBox are not in preset-default — config uses only removeDesc:false and cleanupIds:false as overrides"
  - "Concept A: structured path — stepped bars + branching spine encoding rule evaluation tree"
  - "Concept B: stead frame — architectural enclosure (four-sided frame + inner element) encoding stable governed ground"
  - "Concept C: layered field — four receding contour bars (blue active / quarry receding) encoding rule layer topology"
  - "Fills only (no strokes) across all concepts for small-size legibility at 36px and 16px"
  - "Quarry (#C4CCD1) used in Concept C as receding layer per interfaces block; not Signal Gold"

patterns-established:
  - "Pattern: concept SVGs live in brandbook/assets/logo/concepts/ and stay committed as audit trail after selection"
  - "Pattern: SVGO config is scoped to concepts dir (svgo.config.mjs colocated); separate from future root logo/ config"

requirements-completed: [LOGO-01]

# Metrics
duration: 15min
completed: 2026-06-05
---

# Phase 97 Plan 01: Logo Mark Concept Authoring Summary

**Three accessible mineral-palette SVG mark concepts (structured-path A / stead-frame B / layered-field C) hand-authored and SVGO-optimized for maintainer A/B/C selection, gating Phase 97-02 full lockup production**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-05T16:14:03Z
- **Completed:** 2026-06-05T16:29:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Three mark concept SVGs authored per brand book §14 — accessible (role=img, aria-labelledby, title/desc), mineral-palette only, fills-only, text-free, raster-free, within 20KB budget
- SVGO 4.0.1 optimization applied with a colocated config that preserves accessibility metadata (removeDesc:false, cleanupIds:false)
- 97-CONCEPT-REVIEW.md written with inline renders, design rationale, brand metaphor mapping, and explicit selection instruction for the Phase 97-02 gate

## Task Commits

Each task was committed atomically:

1. **Task 1: Author three mark concept SVGs (A/B/C)** - `f2bf127` (feat)
2. **Task 2: Write 97-CONCEPT-REVIEW.md for the A/B/C selection gate** - `0489f78` (docs)

**Plan metadata:** (recorded in final commit)

## Files Created/Modified

- `brandbook/assets/logo/concepts/rs-mark-concept-a.svg` — Concept A: stepped bars + spine suggesting rule evaluation tree; Stead Blue + Ink Blue fills
- `brandbook/assets/logo/concepts/rs-mark-concept-b.svg` — Concept B: four-sided architectural frame + inner governed element; Stead Blue + Slate Stead fills
- `brandbook/assets/logo/concepts/rs-mark-concept-c.svg` — Concept C: four receding contour bars; Stead Blue (active layers) + Quarry (receding layers)
- `brandbook/assets/logo/concepts/svgo.config.mjs` — SVGO 4.x config colocated with concepts dir; preset-default with removeDesc:false + cleanupIds:false
- `.planning/phases/97-logo-mark-svg-system/97-CONCEPT-REVIEW.md` — Maintainer selection doc: A/B/C rationale, inline renders, file paths, selection instruction, downstream file plan

## Decisions Made

- **SVGO 4.x API difference:** In SVGO 4.x, `removeTitle` and `removeViewBox` are NOT part of `preset-default` (they are standalone-only plugins). The RESEARCH.md Pattern 2 config specified these as overrides, but that generates warnings in SVGO 4.x. Updated config to only disable `removeDesc` and `cleanupIds` in preset-default overrides. Since `removeTitle` and `removeViewBox` aren't in preset-default, they would not have been applied anyway — the fix only removes the spurious warnings.
- **Fills only across all three concepts:** No strokes used, per plan direction. This ensures concepts read clearly at small sizes (36px demo, 16px favicon) without sub-pixel stroke bleed.
- **Quarry (#C4CCD1) in Concept C:** The plan interfaces block listed Quarry as the "mid-tone neutral accent" — used correctly as the receding layer color in the layered field concept.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SVGO config updated for SVGO 4.x API compatibility**
- **Found during:** Task 1 (SVGO optimization run)
- **Issue:** RESEARCH.md Pattern 2 config specified `removeTitle: false` and `removeViewBox: false` as preset-default overrides, but in SVGO 4.x these plugins are not part of preset-default (they are standalone plugins). Running the config produced warnings. The SVGs were still optimized correctly, but the config was misleading.
- **Fix:** Rewrote `svgo.config.mjs` to only include `removeDesc: false` and `cleanupIds: false` in preset-default overrides (both are confirmed in preset-default in SVGO 4.x). Added a clarifying comment explaining the SVGO 4.x behavior.
- **Files modified:** `brandbook/assets/logo/concepts/svgo.config.mjs`
- **Verification:** Second SVGO run produced zero warnings; all three SVGs still contain `<title>`, `<desc>`, and `viewBox`
- **Committed in:** f2bf127 (Task 1 commit includes the corrected config)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The SVGO config correction was necessary for accuracy and clarity. No scope creep. All acceptance criteria still pass.

## Issues Encountered

- SVGO 4.x API moved `removeTitle` and `removeViewBox` out of `preset-default`. The RESEARCH.md was documented against the SVGO 3.x API. Fixed inline per deviation Rule 1.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- 97-CONCEPT-REVIEW.md is ready for maintainer review
- Maintainer must reply with A, B, or C to unblock Phase 97-02
- All three SVG concept files committed and verifiable at `brandbook/assets/logo/concepts/`
- **Blocker:** Phase 97-02 (full lockup authoring) cannot begin until the A/B/C selection is made

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. All SVGs pass T-97-01 (`<script>` = 0) and T-97-02 (no external `http://` refs — `xmlns` namespace URI is not an external resource reference). No threat flags.

---
*Phase: 97-logo-mark-svg-system*
*Completed: 2026-06-05*

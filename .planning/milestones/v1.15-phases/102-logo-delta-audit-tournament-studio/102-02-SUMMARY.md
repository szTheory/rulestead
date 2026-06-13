---
phase: 102-logo-delta-audit-tournament-studio
plan: "02"
subsystem: brandbook
tags: [audit, logo, brandbook, tournament-prep, OFL]
dependency_graph:
  requires: []
  provides: [102-AUDIT.md]
  affects: [Phase 103 tournament scope, Phase 106 brand book generator]
tech_stack:
  added: []
  patterns: [evidence-based design audit, KEEP/TIGHTEN/REWORK framework]
key_files:
  created:
    - .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md
  modified: []
decisions:
  - "rs-wordmark.svg composition verdict: REWORK — fails Criterion 1 (icon-left-of-basic-text) and Criterion 3 (logotype visually separated); contradicts brand-book §14 wordmark-first recommendation"
  - "Sora Bold typography verdict: KEEP — glyph outlines correct, weight appropriate, independent of composition verdict"
  - "OFL 1.1 confirmed for all shortlist fonts (Sora, Space Grotesk, Archivo, IBM Plex Sans, Inter, IBM Plex Mono); artwork-outlining permitted; RFN on IBM Plex restricts derivative fonts only, not logo artwork"
  - "brandbook/index.html overall verdict: competent developer reference sheet, not a professional brand document; Cover, Navigation/Scrollspy, and Logo Plates sections rated Weak"
  - "Phase 106 improvement list: 6 concrete items (cover, scrollspy, editorial typography, token swatches, logo plates, print stylesheet)"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-11"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 102 Plan 02: Logo Delta Audit + HTML Brand Book Presentation Audit Summary

**One-liner:** Written pressure-test audit of the shipped rs-wordmark.svg lockup (REWORK — icon-left composition contradicts brand-book §14) and brandbook/index.html (developer reference sheet, not a professional brand document; 6 Phase-106 improvement items).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Write 102-AUDIT.md | 4b9a4cc | `.planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` |

## Verdicts

| Subject | Verdict | Key Evidence |
|---------|---------|--------------|
| rs-wordmark.svg composition | **REWORK** | Fails Criterion 1 (icon-left-of-basic-text: `<rect>/<circle>` G4c group at x=0–57; text paths begin at x=78) and Criterion 3 (21.5-unit gap, no visual bridge). Contradicts brand-book §14 "Start with a strong Rulestead wordmark before building a complex symbol system." |
| rs-wordmark-dark.svg | **REWORK** | Identical structural finding — same icon-left composition, dark-surface color variant only. |
| rs-mark.svg (standalone icon) | **KEEP (conditionally)** | Icon geometry is not the problem; re-derive favicon after Phase 103 winner selected. |
| rs-favicon.svg | **KEEP / RE-DERIVE** | Functionally correct for 16px icon in current era; must be regenerated post-Phase 104. |
| Sora Bold typography | **KEEP** | Clean glyph paths, no `<text>` elements, appropriate 700 weight. Reusable in Phase 103 as tournament Axis D baseline. |
| brandbook/index.html | **Not professional** | Cover: Weak. Navigation/Scrollspy: Weak. Editorial Typography: Adequate. Token Swatches: Adequate. Logo Plates: Weak. Print Stylesheet: Weak (absent). |

## Phase 106 Improvement List (6 items)

1. **Cover/Hero:** Full-bleed designed cover region with brand palette background, tournament-winning lockup at hero scale, brand mantra in Sora display.
2. **Navigation/Scrollspy:** Sticky scrollspy sidebar with IntersectionObserver highlighting the current section.
3. **Editorial Typography:** Sora display section numbering ("01 Overview"), elevated pull-quote treatment with larger type and accent color.
4. **Token Swatch Presentation:** Live token swatch cards from `tokens.json`: hex + semantic role description + AA/AAA contrast badge.
5. **Logo Plates Section:** Full lockup family on light and dark tiles as asset-card components; clear-space diagram; do/don't examples.
6. **Print Stylesheet:** `@media print` block hiding nav/theme-control, forcing light-on-dark text, setting page breaks at major sections.

## Font Licensing (D-05 — durably recorded)

All shortlist fonts confirmed SIL OFL 1.1. Outlining glyphs to SVG `<path>` artwork is permitted by OFL for all six fonts. IBM Plex's Reserved Font Name "Plex" restricts derivative fonts only, not logo artwork. TTFs not committed (BUDGET.md policy).

## Deviations from Plan

None — plan executed exactly as written. The pre-existing CI lint failure (`ERROR: local non-fragment href does not resolve from brandbook/: ../.planning/phases/101-html-brand-book/101-UI-SPEC.md`) was confirmed pre-existing before this task and is out of scope (no brandbook/ files modified). Logged in deferred-items.

Note: `rs-wordmark-tagline.svg` referenced in the plan does not exist in the assets directory. Only `rs-wordmark.svg` and `rs-wordmark-dark.svg` are present. Criterion 4 (tagline in primary lockup) assessed against the available files; the `rs-wordmark.svg` primary lockup passes this criterion cleanly.

## Self-Check: PASSED

- `test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` → FOUND
- `grep -c "REWORK\|KEEP\|TIGHTEN" 102-AUDIT.md` → 11 (expected >= 5)
- `grep -c "Phase 106" 102-AUDIT.md` → 3 (expected >= 3)
- `grep -i "icon.left" 102-AUDIT.md` → 5 lines (expected >= 1)
- `grep -c "OFL" 102-AUDIT.md` → 9 (expected >= 3)
- `grep -c "Solid\|Adequate\|Weak" 102-AUDIT.md` → 7 (expected >= 4)
- Commit 4b9a4cc confirmed in git log
- No file deletions in commit

# Phase 103: logo-tournament - Context

**Gathered:** 2026-06-11 (from maintainer-approved v1.15 plan + 102-AUDIT.md entry frame)
**Status:** Ready for execution (rounds planned rolling — one plan per round)

<domain>
## Phase Boundary

Phase 103 runs the human-gated logo tournament and ends when the maintainer selects a
winner, frozen as `103-WINNER.md`. It produces candidate SVGs and rendered review sheets.
It does NOT ship final assets (Phase 104), touch admin/demo surfaces (Phase 105), or the
HTML book (Phase 106). Palette/voice/copy frozen; fonts may vary on Axis D candidates.
</domain>

<decisions>
## Tournament Rules (LOCKED)

- **R-01 Candidate guarantee (LOGO-08):** every round contains fully-integrated custom
  typemarks; ZERO icon-left-of-plain-text compositions; ZERO rectangular container
  backgrounds behind any mark; primary lockups carry NO tagline; logotype and any mark
  element visually fused or tightly related.
- **R-02 Human gate (LOGO-07):** every round ends in a maintainer checkpoint — rendered
  sheets shown, keep/cut + verbatim feedback per candidate captured in 103-TOURNAMENT.md
  before the next round plan is authored. Outcome ITERATE or WINNER. Never auto-decided.
- **R-03 Round 1 field:** 12 candidates + incumbent control across 4 axes × 3:
  A evolved incumbent (decision-branch FUSED with type), B new abstract marks interlocked
  with the logotype, C pure custom typemarks on Sora, D alternative-font/structural
  treatments (Space Grotesk / Archivo / IBM Plex Sans; weight-contrast; structural moves).
- **R-04 Funnel:** rounds 2–3 = 4–6 variations per survivor; final round = 6–10
  micro-variants of 1–2 finalists. Soft cap 5 rounds → consolidation checkpoint.
- **R-05 Rendering:** Round 1 = gallery sheets light + dark (~480px cells). Rounds 2+ =
  per-survivor context sheets (light/dark/mono, 36px admin header strip, 16px favicon row,
  README context). Phase 102 harness (`render_studio.sh` pattern, headless Chrome).
  Rendered PNGs git-ignored; studio HTML + candidate SVGs committed in phase dir.
- **R-06 Carried from incumbent (102-AUDIT §2e):** Sora Bold outlines = KEEP baseline;
  Ink Blue #183247 type fill on light (#e8edf3 on dark via mechanical hex swap); G4c
  decision-branch concept available as a motif to integrate INTO letterforms; §14 bans
  stand (no flags/phoenix/shields/lightning/hexagons); viewBox 0 0 372 64 reference canvas.
- **R-07 Palette for candidates:** type #183247 (light surface); accents ONLY from:
  Ember Copper #9b5931 (the "moment of change" accent — selected/lit elements),
  Stead Blue #3A6F8F (system confidence), Quarry #C4CCD1 (muted/receded elements).
  Use EXACT hexes so dark-variant generation is a mechanical swap.
- **R-08 Authoring:** per-glyph outlines via `scripts/gen_glyph_paths.py` (pinned gstatic
  URLs in 102-RESEARCH.md); glyph modification via evenodd subpath insertion, path edits,
  overlay shapes, or pathops booleans (skia-pathops installed). Never `<text>` elements,
  never embedded raster, transparent background.
- **R-09 State:** 103-TOURNAMENT.md is the persistent bracket (candidate id, axis, round,
  status kept/cut, verbatim feedback) — survives context resets; eliminated directions are
  never re-presented.
</decisions>

<canonical_refs>
- `.planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` (§2e + Appendix: entry frame)
- `.planning/phases/102-logo-delta-audit-tournament-studio/102-RESEARCH.md` (typemark taxonomy, pinned font URLs, harness flags)
- `scripts/gen_glyph_paths.py`, phase-102 `102-studio.html` + `render_studio.sh` (harness pattern)
- `brandbook/brand-book.md` §3 (essence), §12 (palette), §13 (type), §14 (logo direction + bans)
</canonical_refs>

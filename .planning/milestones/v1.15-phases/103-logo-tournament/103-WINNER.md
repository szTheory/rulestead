# 103-WINNER.md — Frozen Winner Spec

**Selected:** 2026-06-11, Round 2 checkpoint.
**Winner:** **A3-3 — R-anchored entry** ("trace grows collinear from the R's leg").
**Maintainer verdicts (verbatim):**
- R1: "A3 — Route threads the baseline, rises through the d stem <--- this direction is really cool, would love to see variants but in general it looks great!"
- R2: "A3-3 R-anchored entry — trace grows collinear from the R's leg <--- i like this one let's run with it"

## Canonical source
`.planning/phases/103-logo-tournament/candidates/a3-3.svg` (5,044 bytes) is the frozen
geometry. Phase 104 builds the family FROM this file — do not redraw.

## Design description
Sora Bold "Rulestead" wordmark in Ink Blue. A thin Stead Blue routing trace continues
**collinear out of the R's diagonal leg** (the word generates the route), curves under the
baseline, runs beneath the full word, rises hidden inside the final d's stem, and exits
right as three short routes to vertically stacked nodes — the top node lit Ember Copper
(the selected route), the lower two Quarry (the routes not taken). Feature-flag semantics
encoded in the lockup itself: one input, ordered evaluation, one lit decision.

## Frozen technical facts
- **viewBox:** `0 14 340 62` (Phase 104 may re-normalize to `0 0 340 62`-equivalent by
  translating, but must preserve proportions exactly)
- **Typography:** Sora Bold 700, per-glyph outlined paths, em=64, tracking −0.015.
  Pinned TTF: `https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf`
  Letterforms are UNMODIFIED Sora outlines (glyph surgery = none; the route is added geometry).
- **Route path:** `M33.4 55 L40.84 65.66 Q44.0 70.2 49.5 70.2 H311 Q318 70.2 318 63.2 V29
  M318 29 H330.5 M318 40.5 H330.5 M318 52 H330.5` — stroke #3A6F8F, width 3.2, round
  caps/joins; entry slope 0.6975 collinear with the R leg.
- **Nodes:** r=3.2 at (330.5, 29) #9b5931 · (330.5, 40.5) #C4CCD1 · (330.5, 52) #C4CCD1.
- **Palette (NO deviations from frozen v1.14 tokens):** type #183247, route #3A6F8F,
  lit node #9b5931, muted nodes #C4CCD1. **No font change, no color change → no
  tokens.json/tokens.css edits required in Phase 104 (LOGO-10 token sweep is a no-op).**

## Variant derivations (Phase 104 contract)
- **Dark variant** — mechanical hex swap: #183247→#e8edf3, #3A6F8F→#5885a0,
  #C4CCD1→#3d4a55. (Copper #9b5931 holds on dark; verified in Round 2 dark cards.)
- **Monochrome** — all fills/strokes → single color (#0F1720 light-surface / #e8edf3
  dark-surface usage); node hierarchy carried by geometry alone.
- **Mark/sigil + favicon** — right-end crop: the final **d + exit routes + node stack**
  (crop region ≈ viewBox `278 14 62 62`). Round 2 favicon row verified legible at 16/24/32
  on light and dark. Favicon ships as the d-element on transparent (no container rect) with
  an optional solid #3a6f8f-background fallback file only if 16px contrast demands it.
- **Tagline secondary** — primary lockup NEVER carries a tagline. The secondary variant
  places "Runtime decisions, made clear." centered or left-aligned BELOW the lockup,
  Inter 500, letter-spaced, Moss Grey #606d66, sized ≤ 0.22× lockup cap height, clearspace
  ≥ 0.5 cap height between lockup and tagline.
- **Social card** — 1200×630, lockup on Stone Mist #E8ECE8 or Basalt #0F1720 field,
  per existing rs-social-card.svg conventions.

## Usage rules seeded for brand-book §14 rewrite (Phase 104)
- Min width for full lockup: 120px (route detail degrades below; Round 2 36px strip shows
  the trace surviving header scale — at favicon scale use the d-sigil, never the lockup).
- Clearspace: ≥ 1 cap height all sides (the route descender counts as artwork, not clearspace).
- Never: rectangular container behind the mark; icon-left recomposition; tagline in primary;
  recoloring outside the four frozen hexes; redrawing the route at different slope/weight.

## Tournament provenance
Full bracket in 103-TOURNAMENT.md: Round 1 = 12 candidates + control across 4 axes
(A3 sole survivor); Round 2 = 6 A3 variants (A3-3 selected). 2 rounds, within the 5-round cap.

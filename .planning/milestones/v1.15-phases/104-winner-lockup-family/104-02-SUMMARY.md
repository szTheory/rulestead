# Plan 104-02 Summary — Brand source reconciliation (LOGO-10)

**Status:** COMPLETE — all brand sources reconciled to the shipped A3-3 winner; full guard sweep green.

## Commits

| Hash | Task |
|---|---|
| `e103bad` | Task 1 — brand-book.md §14 rewritten as the shipped "Logo system" |
| `799440e` | Task 2 — readme-header.svg + social-card.svg specimens regenerated with winner lockup |
| `6d25c9c` | Task 3 — FINAL_LOGO_SOURCE_REFS / FINAL_LOGOS + README.md file list updated |
| `dbdca20` | Task 4 — index.html regenerated + stale 101-UI-SPEC source-ref root-cause fix |

## §14 structure (D-05)

`## 14. Logo system` (number-keyed extraction in gen_brandbook_html.py — title
change is anchor-safe; HTML section id `logo` comes from SECTION_ORDER):

1. Intro — shipped identity, "the word generates the route", geometry frozen.
2. **Construction** — route collinear from the R's leg at slope 0.6975; under-word
   run rising through the final d's stem; three exit routes; copper `#9b5931` =
   selected route, Quarry `#C4CCD1` = routes not taken; stroke `#3A6F8F` w3.2
   round caps; unmodified Sora Bold 700 per-glyph outlines; four-hex palette.
3. **Clear space** — ≥ 1 cap height all sides; route descender is artwork, measure
   from the route's lowest point.
4. **Minimum sizes** — lockup ≥ 120px width; below that, d-sigil mark only.
5. **Variant usage** — 8-row table for all family files incl.
   rs-wordmark-tagline.svg secondary rules (never a primary substitute).
6. **Misuse** — no container rect/badge, no icon-left recomposition, no tagline in
   primary, no recolor outside the four hexes, no redraw of route slope/weight;
   legacy bans (flags/phoenix/shield/lightning/hexagon/flame) folded in.
7. **Provenance** — one paragraph: A3-3 "R-anchored entry", 12 candidates +
   control in Round 1, 6 A3 variants in Round 2.

Stale G4c-era prose removed: logo strategy, wordmark-first recommendation,
symbol options A/B/C, wordmark-character list.

## Specimens (D-06)

- `readme-header.svg` — 12,767 bytes (budget 51,200). Light tagline lockup
  (route + Sora glyph outlines + node stack + outlined Inter tagline from
  rs-wordmark-tagline.svg) at 0.82× left-aligned on the Rain Tint `#F5F7F6`
  field; 480×96 format preserved. Replaces the old icon-left + `<text>` mock.
- `social-card.svg` — 14,523 bytes. Mirrors shipped rs-social-card.svg (Basalt
  field, dark-variant lockup at 2.75×, outlined tagline) plus the specimen's
  token-annotation line updated to `basalt.base / stead-blue.dark /
  ember-copper.base`. 1200×630 preserved.
- Both built programmatically from the shipped logo sources (no geometry
  transcription), SVGO-passed with `brandbook/assets/logo/svgo.config.mjs`
  (same config as the phase-99 specimen batch), `role="img"` + title/desc +
  aria-labelledby intact, xmllint clean, visually verified in headless Chrome.
  typography.svg untouched.

## Script/doc updates (D-07)

- `scripts/check_brandbook_html.py` — FINAL_LOGO_SOURCE_REFS + 
  `assets/logo/rs-wordmark-tagline.svg` (8 refs).
- `scripts/gen_brandbook_html.py` — FINAL_LOGOS + rs-wordmark-tagline.svg (asset
  grid now embeds all 8 files; hero stays rs-wordmark.svg); §14 label string
  updated to "Logo system". Content-only; no chrome/design changes (Phase 106).
- `brandbook/README.md` — assets/logo/ row now names tagline secondary + d-sigil.
- `brandbook/BUDGET.md` and `brandbook/docs/brand-usage.md` — verified: neither
  enumerates logo files nor describes the old lockup; **no changes needed**.

## Guard sweep (all exit 0)

| Command | Result |
|---|---|
| `python3 scripts/check_brandbook_html.py` | `BRANDBOOK HTML SYNCED (182537 bytes)` — exit 0 |
| `python3 scripts/check_brand_tokens.py` | `BRAND TOKENS SYNCED (68 tokens)` — exit 0 |
| `python3 scripts/check_tokens_css.py` | `TOKENS.CSS MIRROR SYNCED (68 tokens)` — exit 0 |
| `python3 scripts/check_synced_pair.py` | `SYNCED PAIR IDENTICAL (56 / light: 57 tokens)` — exit 0 |
| `bash scripts/ci/lint.sh` | full gate incl. mix/credo/dialyzer + SVG budgets — exit 0 |

Token guards passed untouched, confirming D-03 (winner spec = no token deviations).

## Deviation / root cause fixed

`check_brandbook_html.py` initially failed: the generator's overview source-ref
pointed at `.planning/phases/101-html-brand-book/101-UI-SPEC.md`, which commit
`3fcd725` (v1.14 milestone archive) had moved to
`.planning/milestones/v1.14-phases/`. Updated the path in gen_brandbook_html.py
(commit `dbdca20`) so the local-link assertion resolves — root cause, not a
guard suppression.

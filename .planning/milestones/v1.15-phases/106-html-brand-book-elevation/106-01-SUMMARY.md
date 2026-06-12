# Plan 106-01 Summary — Brand book chrome elevation

**Status:** Complete · **Date:** 2026-06-12 · **Requirements:** BOOK-03, BOOK-04 (technical half)

## What shipped

All design work landed in the generator chrome layer (`scripts/gen_brandbook_html.py`);
`brandbook/index.html` was regenerated, never hand-edited. Final artifact:
**223,744 bytes** against the unchanged **262,144-byte** budget (no budget raise,
no BUDGET.md change needed).

### Six 102-AUDIT Section-3 gaps — closed

| Gap | Resolution |
|-----|-----------|
| Cover / Hero (Weak) | Full-bleed Basalt `#0F1720` cover: hero-scale `rs-wordmark-dark`, "Brand Book" kicker, copper rule, mantra "Rulestead makes change feel governed, not chaotic." in Sora display (clamp 2.1–3.35rem), tagline + `Brand System v1.15 · June 2026` metadata bars. Identical across themes; print swaps to the light lockup. |
| Navigation / Scrollspy (Weak) | Sticky left rail (`position: sticky`) with numbered 01–09 links, IntersectionObserver scrollspy appended to the single existing inline script (`aria-current` active state, copper bar). Works as plain anchor nav with JS disabled; collapses to wrap-chips below 960px. |
| Editorial typography (Adequate) | Ghost-outline Sora 700 section numerals (3.6rem, `-webkit-text-stroke`), 1.9rem section titles, 68ch prose measure, copper-kicker h3s, Sora pull-quote treatment at 1.22rem, mono small-caps labels throughout. |
| Token swatches (Adequate) | Primitive cards now carry role text; light/dark semantic groups render as cards with `semantic → primitive` mapping, resolved hex, and AA/AAA/AA-large/Below-AA badges computed at generation time via stdlib WCAG relative-luminance math against the token-defined check surfaces (Stone Mist `#E8ECE8` light, `#10161f` dark). |
| Logo plates (Weak) | All 8 family files inline on dual tiles (light `#f4f6f8` / dark `#10161f`) — second tile reuses the inline SVG via same-document `<use>` (no ID duplication, ~40KB saved). Primary-surface tags, captions with file link + bytes, dashed 1-cap clear-space diagram, and a 2×2 do/don't grid (correct ✓ · container-rect ✗ · icon-left recomposition ✗ · tagline-in-primary ✗) with diagonal strike overlays. |
| Print stylesheet (Weak) | `@media print`: rail/theme/source-refs hidden, light tokens forced over any theme, white background, per-section page breaks, break-inside avoidance on cards, prominent hex labels, cover logo swapped to the light variant. |

### Guard invariants preserved (D-07)

- No `script src` / `img src` / base64 / `<image>` / `foreignObject` / event handlers.
- `REQUIRED_SECTION_IDS` unchanged and in order; all 8 `FINAL_LOGO_SOURCE_REFS` +
  6 specimen refs present.
- Styling scoped under `[data-rulestead-brandbook]`; page fully usable with JS disabled
  (verified by existing e2e).
- Deterministic render — drift check green (`BRANDBOOK HTML SYNCED (223744 bytes)`).
- Fixed mobile horizontal overflow (source-ref chips + doc excerpts now break long paths).

### Verification (D-09)

- `python3 scripts/check_brandbook_html.py` → exit 0.
- `bash scripts/ci/lint.sh` → exit 0 (full Elixir lint + all brand guards + SVG budgets).
- `examples/demo/frontend/tests/brandbook.spec.ts` extended with 6 new tests
  (cover, sticky rail, scrollspy activation, print stylesheet behavior, WCAG badges,
  8-plate duals) — **12/12 passing** via file://.
- Visual evidence: cover/reading/color/plates/clearspace/usage/print/mobile renders in
  `.planning/phases/106-html-brand-book-elevation/scratch/` (git-ignored), light + dark.

## Commits

- `18714e9` feat(brandbook): elevate HTML brand book chrome to designed artifact
- `b8ff32e` test(demo): extend brandbook e2e for elevated chrome

## Deferred to 106-02 (orchestrator-owned)

Maintainer sign-off on the elevated book (D-10) and milestone close.

# Plan 104-01 Summary — Winner SVG family (LOGO-09)

**Status:** COMPLETE — all 8 family files shipped in `brandbook/assets/logo/`, SVGO-optimized, within budget, proof-sheet verified.

## Commits

| Hash | Task |
|---|---|
| `a8f5903` | chore: git-ignore scratch renders in phase dir |
| `a79990a` | Task 1 — rs-wordmark.svg from canonical a3-3 (translate(0,-14) wrapper, viewBox 0 0 340 62, glyph/route/node geometry byte-identical to frozen source) |
| `216eb3c` | Task 2 — dark, tagline, mark, mark-dark, mark-mono, favicon derivations |
| `0072d0e` | Task 3 — rs-social-card.svg rebuilt around winner lockup |
| `4869f68` | Task 4 — SVGO pass + svgo.config.mjs hardening |

## Byte sizes vs budget (≤ 20,480)

| File | Bytes | Headroom |
|---|---|---|
| rs-wordmark.svg | 3,988 | 80% |
| rs-wordmark-dark.svg | 4,005 | 80% |
| rs-wordmark-tagline.svg | 12,999 | 37% |
| rs-mark.svg | 1,216 | 94% |
| rs-mark-dark.svg | 1,258 | 94% |
| rs-mark-mono.svg | 1,334 | 93% |
| rs-favicon.svg | 1,184 | 94% |
| rs-social-card.svg | 14,364 | 30% |

All parse clean (`xmllint --noout`), all keep `role="img"` + `<title>` + `<desc>` + `aria-labelledby` post-optimize, second SVGO pass is 0% (idempotent).

## Tagline font decision

**Inter Medium 500 — the winner spec's exact face. No fallback needed.**
102-RESEARCH pinned only Sora/Space Grotesk/Archivo/IBM Plex; an Inter 500 static
TTF was obtained live from the legacy Google Fonts CSS API (curl, default UA) and
verified with fontTools before use:

- URL: `https://fonts.gstatic.com/s/inter/v20/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuI6fAZ9hjQ.ttf`
- Verified: HTTP 200, `usWeightClass=500`, no `fvar` (true static instance), family "Inter Medium", upm 2048, capHeight 1490. SIL OFL.
- Rendered via `scripts/gen_glyph_paths.py` (curl fetch, gstatic-only guard): em 10
  (≤ 0.22 × lockup cap height 47.104), tracking +0.05 em (letter-spaced per spec),
  Moss Grey `#606d66`, baseline y=89 → 23.9px clearspace ≥ 0.5 cap (23.55) above the
  route's lowest point (y=57.8). Tagline left edge optically aligned to the R stem
  (Inter R lsb compensation: tx 4.442).

## Favicon verification

- Transparent d-sigil (no container rect), viewBox `0 0 62 62`, light-variant hexes.
- `<link rel="icon">` harness page loaded in headless Chrome — no resource errors.
- Standalone renders at 16/24/32/64 px and simulated Chrome tab strips (light
  `#dee1e6`, dark `#202124`) at exactly 16px were rendered and visually reviewed:
  the ink-blue d reads clearly on the light tab strip; route + copper node still
  discernible. **16px contrast passes — no solid-bg fallback file shipped** (per
  D-08 the fallback is only added if contrast genuinely fails).

## Proof sheet

`.planning/phases/104-winner-lockup-family/scratch/proof-final.png` (git-ignored;
regenerate via `scratch/proof.html` + headless Chrome). Shows all 8 files on Stone
Mist / white / Basalt cards, 36px header strip, favicon at 32/24/16 + alpha checker,
and the new social card. Reviewed at full size plus zoom renders of the tagline
lockup and the three marks.

## Misuse rules verified on shipped files

- No `<rect>` container in any file (social card background is a `<path>` field, not a mark container).
- No icon-left recomposition (route is integral to the lockup; marks are crops).
- No tagline in rs-wordmark.svg / rs-wordmark-dark.svg (2 path groups only: route + glyphs).
- Only the four frozen hexes + specified dark/mono swaps; route geometry untouched.

## Deviations / decisions worth noting

1. **svgo.config.mjs hardened (in-scope per D-04):**
   - `removeUnknownsAndDefaults.keepRoleAttr: true` — SVGO 4 was silently stripping `role="img"`.
   - `mergePaths: false` — preset-default merged the nine glyph paths into one, breaking the per-glyph outlined-path structure that 103-WINNER.md freezes as a technical fact.
   - `floatPrecision: 3` pinned (D-04 asked to pin if absent).
   SVGO still bakes per-path transforms into path data (convertPathData); one path per glyph survives, shapes unchanged at precision 3.
2. **Mark crop**: under-word route run bleeds off the left edge of the 62×62 crop (round cap parked at x=-4 so the clip edge is flat) — honest right-end crop per the `278 14 62 62` region in the winner spec.
3. **Mono node hierarchy**: lit node filled, routes-not-taken as stroked rings (r 2.5 / sw 1.4) — hierarchy by geometry alone, as the old mono mark did.
4. **Social card**: Basalt `#0F1720` field chosen (winner spec offered Stone Mist or Basalt; existing card was dark). Tagline kept in the existing card's treatment (`#e8edf3` at 70% opacity). Content geometrically centered (194px top / 194px bottom).
5. `rs-mark-mono.svg` now uses literal `#0F1720` per plan (was `currentColor` in the G4c era); the svgo config's convertColors note is still valid for any future currentColor usage.

## Not touched (deferred per plan)

Tokens, admin/demo statics (105), specimens, brand-book.md §14, check scripts,
BUDGET.md, index.html regen — all 104-02/105/106 scope.

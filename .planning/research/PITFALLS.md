# Pitfalls Research

**Domain:** Brand system realization — palette engineering, dark-mode derivation, SVG/logo production, repo hygiene, token lifecycle
**Researched:** 2026-06-04
**Confidence:** HIGH (contrast ratios computed directly from the brand-book hex values; no third-party tool required; OKLCH hue angles computed from spec matrices)

---

## Critical Pitfalls

### Pitfall 1: Ember Copper and multiple semantics fail WCAG AA for normal-weight text

**What goes wrong:**
The brand book specifies Ember Copper `#B96A3A` as the accent and Warning `#B57A21` as a semantic color. Both fail 4.5:1 for normal body text on every light surface in the mineral palette. The team already hit this exact failure mode with `#c45c26` in v1.13 and fixed it by darkening to `#9a3f12`. The same repair is required for the new palette before any token file is committed.

Measured failures (WCAG 2.x, computed directly):

| Foreground | Background | Ratio | Status |
|---|---|---|---|
| EmberCopper `#B96A3A` | white `#FFFFFF` | 4.05 | **FAIL** normal text |
| EmberCopper `#B96A3A` | Stone Mist `#E8ECE8` | 3.39 | **FAIL** normal text |
| EmberCopper `#B96A3A` | Rain Tint `#F5F7F6` | 3.76 | **FAIL** normal text |
| EmberCopper `#B96A3A` | dark base `#10161f` | 4.48 | **FAIL** normal text (0.02 short) |
| White on EmberCopper button | EmberCopper `#B96A3A` | 4.05 | **FAIL** button label |
| Warning `#B57A21` | white `#FFFFFF` | 3.64 | **FAIL** normal text |
| Warning `#B57A21` | Stone Mist `#E8ECE8` | 3.05 | **FAIL** normal text |
| White on Warning button | Warning `#B57A21` | 3.64 | **FAIL** button label |
| SignalGold `#D2A94E` | white `#FFFFFF` | 2.20 | **FAIL** (also fails 3:1 UI) |
| MossGrey `#6C7A73` | Stone Mist `#E8ECE8` | 3.77 | **FAIL** normal text |
| MossGrey `#6C7A73` | Rain Tint `#F5F7F6` | 4.18 | **FAIL** normal text |
| SteadBlue `#3A6F8F` | dark base `#10161f` | 3.33 | **FAIL** normal text / link |
| Success `#2F7D57` | dark base `#10161f` | 3.62 | **FAIL** normal text |
| Danger `#B44949` | dark base `#10161f` | 3.45 | **FAIL** normal text |
| Info `#356E8C` | dark base `#10161f` | 3.25 | **FAIL** normal text |
| MossGrey `#6C7A73` | dark base `#10161f` | 4.04 | **FAIL** normal text |

Colors that pass on all light surfaces without adjustment: SteadBlue `#3A6F8F` (5.45 on white, 4.57 on Stone Mist, 5.07 on Rain Tint); Basalt `#0F1720` (18.05 on white); Slate `#24313D` (13.28 on white); Danger `#B44949` (5.26 on white); Success `#2F7D57` (5.01 on white); Info `#356E8C` (5.58 on white).

**Why it happens:**
The brand book was designed for visual aesthetics and usage-ratio guidance, not accessibility. Warm-hue mid-range colors (oranges, ambers, golds) have elevated luminance relative to their perceptual darkness, so their WCAG contrast on light backgrounds is lower than it looks. The team already discovered this pattern in v1.13 but the brand-book palette is different from what was shipped.

**How to avoid:**
Use the OKLCH-preserving luminance-reduction strategy. Uniform RGB scaling (multiply all channels by a constant `k < 1`) preserves the OKLCH hue angle almost perfectly — measured hue drift is 0–0.6 degrees for the Ember Copper family. This is the correct tool because it avoids the green/blue tint that pure HSL lightness reduction introduces.

Computed minimum-darkening targets (to just-pass 4.5:1 on the relevant background):

| Color | Background | Current ratio | AA-passing hex | New ratio | OKLCH hue preserved |
|---|---|---|---|---|---|
| EmberCopper `#B96A3A` | white | 4.05 | `#AE6437` | 4.49 | hue 50.2 → 50.2 |
| EmberCopper `#B96A3A` | Rain Tint | 3.76 | `#A75F34` | 4.51 | hue 50.2 → 49.8 |
| EmberCopper `#B96A3A` | Stone Mist | 3.39 | `#9C5A31` | 4.49 | hue 50.2 → 50.8 |
| Warning `#B57A21` | white | 3.64 | `#A06C1D` | 4.51 | yes |
| Warning `#B57A21` | Stone Mist | 3.05 | `#90611A` | 4.50 | yes |
| MossGrey `#6C7A73` | Stone Mist | 3.77 | `#616D67` | 4.52 | yes |
| MossGrey `#6C7A73` | Rain Tint | 4.18 | `#67756E` | 4.49 | yes |

For dark-mode (lightening toward white to lift contrast on `#10161f`):

| Color | Current ratio | AA-passing lightened hex | New ratio |
|---|---|---|---|
| SteadBlue `#3A6F8F` | 3.33 | `#57849F` | 4.50 |
| EmberCopper `#B96A3A` | 4.48 | `#BB6C3C` (tiny nudge) | ~4.52 |
| Success `#2F7D57` | 3.62 | `#468C6A` | 4.51 |
| Danger `#B44949` | 3.45 | `#BF6464` | 4.52 |
| Info `#356E8C` | 3.25 | `#54859E` | 4.52 |
| MossGrey `#6C7A73` | 4.04 | `#74827B` | 4.51 |

**APCA caveat:** APCA (WCAG 3.0 draft) uses a perceptual model that scores differently from WCAG 2.x. Some borderline pairs (3.77–4.3) might pass APCA for large UI text. However, the admin currently gates against WCAG 2.x (the `wcagRatio` inline TypeScript harness from Phase 87). Do not switch to APCA mid-milestone — it requires a separate gate and different thresholds. Keep WCAG 2.x 4.5:1 as the bar for normal text and 3:1 for non-text UI components.

**Warning signs:**
- Brand-book palette committed to tokens.json without running the contrast harness first
- tokens.css shipped with `--rs-accent` set to the book-literal `#B96A3A` rather than an AA-verified variant
- AA fixture passes but only tested large text or icon-only pairings

**Phase to address:**
Phase 95 (audit/palette reconciliation). This is a gate-zero requirement. No token file may be committed until every text/button pairing in the mineral palette has a computed ratio and a documented AA-passing variant. Phase 96 (tokens) picks up the approved values.

---

### Pitfall 2: Naive darkening changes the OKLCH hue, producing mud instead of mineral

**What goes wrong:**
The most common "fix" for failing contrast is to reduce HSL lightness or darken the hex value in HSL space. Reducing HSL L while holding HSL S and H shifts the perceived hue toward a less saturated, muddier tone. Ember Copper darkened in HSL looks brownish-grey rather than warm copper. This breaks the mineral palette intent.

**Why it happens:**
HSL is not perceptually uniform. Reducing L in HSL space does not travel along a constant perceived hue. OKLCH is perceptually uniform: changing L while holding C and H produces a darker version of the same perceived hue.

**How to avoid:**
Use one of two equivalent approaches:

1. **OKLCH direct:** Express the token as `oklch(L C H)`. Reduce L until the WCAG Y luminance hits the 4.5:1 target. Keep C and H fixed. CSS supports `oklch()` natively in all modern browsers. EmberCopper is `oklch(0.604 0.119 50.2)`. Target for 4.5:1 on white is approximately `oklch(0.565 0.119 50.2)` — same copper, darker.

2. **Uniform RGB scaling:** Multiply all three channels by a constant `k < 1`. This is equivalent to reducing OKLCH L while preserving hue to within ~1 degree (verified above: 0–0.6 degree drift for the Ember Copper family). This matches the existing `#c45c26` → `#9a3f12` technique from v1.13 (hue drift was 2.1 degrees — acceptable).

**Warning signs:**
- The proposed AA-fix hex looks noticeably less warm or more grey than the book color
- A HSL or color-picker tool was used to "darken" the color without a contrast calculation
- The fix was chosen by eye rather than by computed ratio

**Phase to address:**
Phase 95 (audit). Prescribe the OKLCH/uniform-scale method in the palette audit deliverable so Phase 96 token engineering uses the right technique.

---

### Pitfall 3: Dark-mode ramp derived independently from the light palette produces inconsistent surfaces

**What goes wrong:**
The brand book specifies a light-leaning palette only. If dark-mode token values are picked by eye or by inverting light tokens, the result is an inconsistent mineral-dark ramp — surfaces too dark or too similar (no elevation), borders that disappear, or a ramp that ignores the established v1.13 system.

**Why it happens:**
The v1.13 milestone already solved this problem. Its decisions are in STATE.md: mineral-dark base `#10161f`, elevation by lightening, hairline borders, never pure black. If v1.14 derives a fresh dark palette from the brand-book light colors, it breaks continuity with what Phase 87–94 shipped.

**How to avoid:**
The v1.13 dark ramp is the canonical base. Map the new mineral palette onto the existing dark ramp slots rather than creating a new ramp:

- Dark base (`--rs-surface-base`): keep `#10161f`. Basalt `#0F1720` is visually indistinguishable (1.01:1 contrast between them) — do not swap.
- Elevation 1 (panels): `#10161f` lightened toward Slate `#24313D` — approximately `#172130` to `#1c2738`.
- Elevation 2 (raised cards): approach Slate `#24313D` — use `#24313D` itself or a step lighter.
- Borders: Slate range `#24313D` to `#2e3e4d` for hairline separators against the dark base.
- Text primary: Stone Mist `#E8ECE8` — 15.2:1 on `#10161f`, easily PASS.
- Text secondary: AA-lightened MossGrey `#74827B` — 4.51:1 on `#10161f`.
- Primary interactive: AA-lightened SteadBlue `#57849F` — 4.50:1 on `#10161f`.
- Accent: Ember Copper nudged to `#BB6C3C` to clear 4.5:1 on `#10161f`.

Key principle: elevation by luminance increase, not by hue shift.

**Warning signs:**
- Dark-mode token values were picked from the brand book without consulting STATE.md v1.13 decisions
- `--rs-surface-base` changed to `#0F1720` (Basalt) or anything darker than `#10161f`
- Elevation uses hue changes rather than luminance steps

**Phase to address:**
Phase 95 (audit) documents the mapping of brand-book light values to existing dark slots. Phase 96 (tokens) implements the ramp. Phase 98 (admin re-skin) applies it and runs the both-theme contrast gate.

---

### Pitfall 4: SVG wordmark uses live text — renders differently across machines and at small sizes

**What goes wrong:**
An SVG wordmark that uses `<text>` elements referencing Sora will render differently depending on whether the viewer's machine has the font cached, which rendering engine is used, and whether font hinting aligns at the target size. The wordmark looks correct in the editor but is pixelated, substituted with a fallback, or incorrectly spaced in GitHub READMEs, Hex.pm, and generated social card images.

**Why it happens:**
SVG `<text>` with `font-family` is a reference to a font that must be present in the rendering environment. GitHub's SVG renderer does not load web fonts. Hex.pm renders SVGs statically. A PNG rasterized from an unoutlined SVG captures whatever the local machine had installed.

**How to avoid:**
Outline all wordmark text at the point of finalization. In Inkscape: Path > Object to Path. In Figma: flatten/outline text before SVG export. The outlined SVG contains only `<path>` elements with no font dependency. This is the standard practice for logo SVGs intended for open distribution.

For the abstract mark (Option A/B/C from brand book §14): outlines are not needed since the mark is pure geometry, but verify no `<text>` elements are present by mistake.

Exception: the admin UI can use `font-family: 'Sora'` for a text-rendered wordmark in the browser, since the admin bundles or loads the font. The `brandbook/` artifact must be the outlined version.

Separate concern: at favicon size (16×16, 32×32), a wordmark is illegible. The favicon must use only the abstract mark or a single letterform at a size where it resolves into a clear shape. Test by resizing the SVG canvas to 16px in the browser and confirming the glyph reads.

**Warning signs:**
- SVG exported from Figma/Inkscape with `<text font-family="Sora">` present
- README or GitHub page shows fallback sans-serif for the wordmark
- Favicon ICO generated from a downsized full wordmark (looks like a smear)

**Phase to address:**
Phase 97 (logo production). Outlining is a required step before any SVG is committed to `brandbook/`. A CI check (`grep -r '<text' brandbook/` finding zero matches in finalized artifacts) can be added at Phase 100.

---

### Pitfall 5: Embedded raster in SVG bloats the repo and breaks monochrome/dark-mode variants

**What goes wrong:**
Design tools sometimes embed raster data (PNG via base64 `<image>`) inside SVG exports — this happens when a raster texture, gradient map, or photo-layer is included. The result is a large binary blob disguised as a text file, it does not scale cleanly, and it cannot be recolored with `currentColor` or `fill` overrides for dark-mode and monochrome uses.

**Why it happens:**
Figma's "Export as SVG" embeds raster images if the design includes any raster layer, effect, or imported image. This can happen accidentally if a texture or screenshot is part of the artboard.

**How to avoid:**
The Rulestead logo system is pure geometry (brand book §14 calls for structured paths, stepped flows, architectural enclosures, layered contours — all purely vector). Keep the artboard free of raster layers. After export, verify: `grep -c 'base64' brandbook/*.svg` must return 0 for all logo SVGs.

For the monochrome variant: use `fill="currentColor"` on all path elements, not hardcoded hex fills. This allows the admin CSS to set `color: var(--rs-on-surface)` on the containing element and have the logo adapt to both themes. Also ship a `logo-monochrome.svg` with explicit `fill="#000000"` paths for print/stamp use.

**Warning signs:**
- `brandbook/logo-wordmark.svg` is larger than ~10KB (pure geometric wordmark should be ~2–5KB outlined)
- `git diff --stat` shows an SVG commit adding hundreds of KB
- Logo does not recolor in dark-mode admin (stuck at hardcoded fill hex)

**Phase to address:**
Phase 97 (logo production) must include the monochrome-via-currentColor design decision. Phase 100 (copy/repo artifact plan) sets the size budget and adds the `grep base64` CI guard.

---

### Pitfall 6: Token drift between brand book and live admin CSS

**What goes wrong:**
Tokens are agreed in `brandbook/tokens.json` and `brandbook/tokens.css`, then the admin CSS is updated in a separate step. If the two files go out of sync — even by a single value — the design system loses integrity. The existing `check_synced_pair.py` guard was added in v1.13 precisely for this reason, but it covers the v1.13 token set, not the new mineral tokens.

**Why it happens:**
If Phase 98 (re-skin) begins before Phase 96 (tokens) is final, engineers patch admin CSS directly instead of going through the token layer. Or a token value is corrected post-audit but the admin CSS is not regenerated.

**How to avoid:**
Strict phase gate: `brandbook/tokens.css` is the single source of truth for token values. The admin CSS imports or copies those values mechanically. `check_synced_pair.py` must be extended in Phase 96 to include all new mineral tokens before Phase 98 starts. Additionally: the admin CSS uses only semantic tokens (`--rs-primary`, `--rs-accent`, `--rs-surface-base`, etc.) — never raw hex. If a palette value changes, only `tokens.css` changes; the admin CSS is unaffected.

**Warning signs:**
- `--rs-accent` appears as a hardcoded hex in a component CSS block outside the token cascade
- `tokens.json` updated but `check_synced_pair.py` not re-run before merge
- Phase 98 PR edits `rulestead_admin.css` block 1 to "just fix" a color without touching the token file

**Phase to address:**
Phase 96 (tokens) establishes the sync contract. Phase 98 (admin re-skin) is gated by it. Phase 100 (repo/CI) makes the guard permanent.

---

### Pitfall 7: Over-specification and brand thrash — touching non-color properties during the color-only re-skin

**What goes wrong:**
The admin re-skin scope is explicitly "colors only — gated by WCAG-AA both themes and the design-system fixture" (PROJECT.md). If the re-skin phase also touches spacing, typography, border-radius, component layout, or interaction behavior, the PR becomes large, harder to review, harder to revert, and risks breaking things that were working from v1.13.

**Why it happens:**
Engineers see imperfections while editing CSS and make "while I'm here" fixes. The mineral palette swap also surfaces old issues (a hardcoded border color that used to pass but now clashes) that are tempting to address in the same pass.

**How to avoid:**
Phase 98 changes exactly the four token cascade blocks in `rulestead_admin.css` — color values only. If a non-color property needs changing, file it as a separate issue or phase. A review step should verify the constraint: the set of changed lines in `rulestead_admin.css` that do not touch `color`, `background`, `border-color`, `fill`, `stroke`, or `--rs-` variables should be empty.

**Warning signs:**
- Phase 98 PR description mentions "also cleaned up some spacing inconsistencies"
- Brand book §15 (layout) or §13 (typography) cited to justify changes in the re-skin phase
- The contrast fixture passes but 3+ unrelated screens changed visually from v1.13

**Phase to address:**
Phase 95 (audit) must explicitly define the change surface as palette + semantic colors + token values only. Phase 98 enforces this via narrow-diff review.

---

### Pitfall 8: Repo bloat from binary brand assets

**What goes wrong:**
Brand work produces PNG exports, social card images, favicon ICO files, and specimen screenshots. If committed without a size policy, the repo grows by megabytes permanently — git does not deduplicate binary diffs, and history rewriting is expensive and disruptive.

**Why it happens:**
It is convenient to commit exported PNGs "so they're available." Social card images are 1200×630px and can be 300–800KB each. Screenshot specimens from Phase 99 can be multiple MB.

**How to avoid:**
Text-first policy for `brandbook/`:
- Source SVGs: always committed (~2–10KB each)
- `favicon.ico` + `favicon.svg`: committed (<5KB)
- PNG exports for README/Hex.pm: generated at publish time from SVG, not committed; OR committed only if ≤100KB and reproducible from SVG with a documented `rsvg-convert` or `inkscape` command
- Social card PNG: generated by script from the SVG specimen, not committed as a static blob
- Screenshot specimens (Phase 99): CI artifacts or a `brandbook/specimens/` subfolder with an explicit size cap (e.g. 500KB total)

A CI check that fails if any new binary in `brandbook/` exceeds 200KB prevents accidents.

**Warning signs:**
- `git diff --stat` shows a PNG commit adding 1.2MB
- `du -sh brandbook/` grows beyond ~500KB
- `brandbook/` contains subdirectories of rasterized specimens

**Phase to address:**
Phase 100 (repo artifact plan) defines the size budget and CI guard. Phase 97 (logo) must produce SVG-first outputs with documented rasterization commands.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|---|---|---|---|
| Use book-literal hex in tokens.css without AA verification | Fast start | Ships a design system that fails AA; requires a second pass that is harder to explain | Never |
| Use HSL darken to fix contrast | Familiar tooling | Hue drift makes copper look brown, gold look olive | Never for the mineral palette |
| Derive dark-mode ramp from scratch | "Fresh" palette | Breaks continuity with v1.13 ramp; risks regression on shipped screens | Never for this milestone |
| Commit outlined SVG without testing at 16px favicon size | Logo done quickly | Favicon is illegible; separate rework pass required | Never |
| Keep live `<text>` in wordmark SVG "for now" | Avoids the outline step | Renders wrong on GitHub, Hex.pm, social cards | Never for any published artifact |
| `fill="#3A6F8F"` hardcoded in SVG rather than `currentColor` | Simple | Logo cannot adapt to dark-mode in admin | Acceptable only for print-export variants; not for admin-embedded logo |
| Patch admin CSS hex values during re-skin without updating tokens.css | Faster in the moment | Token drift; sync guard fails on next PR | Never |
| Add spacing/typography cleanups alongside color changes in Phase 98 | "Efficiency" | Bloated diff, harder revert, risks v1.13 regression | Never in the same PR |
| Commit PNG exports of every specimen | Available for docs | Repo bloat is permanent | Only if ≤100KB and reproducible from SVG |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|---|---|---|
| GitHub README SVG rendering | SVG with `<text font-family="Sora">` renders as fallback font | Outline all text to paths before committing to `brandbook/` |
| Hex.pm package page | `<image>` base64 blob in SVG | Pure path geometry; no raster layers in logo artboards |
| CSS `oklch()` in admin | Forgetting to generate sRGB hex fallbacks for older rendering paths | Use `oklch()` as canonical definition in token file; document the sRGB hex equivalent alongside each token |
| `check_synced_pair.py` | Guard only covers v1.13 token pairs; new mineral tokens not yet in scope | Extend the sync check in Phase 96 before Phase 98 starts |
| Social card generation | Static PNG committed to repo | Generate from SVG specimen via `rsvg-convert` or `sharp` at publish time; document the command in `brandbook/` |
| Favicon ICO | Generating from full wordmark SVG without 16px test | Rasterize at 16px first; verify the abstract mark is legible before committing |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---|---|---|
| Ember Copper used as normal-weight body text | 4.05:1 on white — fails AA; hurts legibility | Use Ember Copper for large/bold text (≥18px regular or ≥14px bold, where 3:1 is sufficient) or use the AA-darkened variant (~`#A75F34`) for normal-weight inline use |
| MossGrey as body text on Stone Mist panels | 3.77:1 — fails AA for normal text | Reserve MossGrey for large/decorative labels; use Basalt or Slate for body text; or use darkened `#616D67` variant |
| SignalGold used as text color | 2.20:1 on white — fails even 3:1 UI | Decorative-only; never text; use as icon fill or badge background with Basalt text (8.19:1) |
| Warning color as inline normal text | 3.64:1 on white — fails AA | Use darkened Warning `#A06C1D` for inline warning text; use `#B57A21` only for large text or icon+fill contexts |
| Phoenix flame in admin header | Explicitly disallowed by brand book §14 | Replace with the wordmark or abstract mark from Phase 97 |
| Monochrome SVG missing for admin header | Logo stuck at copper-coloured hex in dark mode | Ship `fill="currentColor"` variant alongside the full-color wordmark |

---

## "Looks Done But Isn't" Checklist

- [ ] **Palette audit complete:** Every pairing in the contrast matrix is computed, not assumed — `brandbook/` or `scripts/` contains a runnable check, not a manual spreadsheet
- [ ] **EmberCopper light-mode fix:** `--rs-accent` in Block 1 (light) of `rulestead_admin.css` is the AA-passing darkened variant, not the book-literal `#B96A3A`
- [ ] **EmberCopper dark-mode fix:** `--rs-accent` in Block 2 (dark) clears 4.5:1 on `#10161f` — book literal is 4.48 (borderline fail); requires a tiny nudge
- [ ] **All semantic colors dark-mode:** Success, Danger, Info, MossGrey secondary all have AA-lightened dark variants in Block 2/3
- [ ] **Warning color:** AA-darkened for normal text use; book literal `#B57A21` only used at large text / icon contexts
- [ ] **SVG wordmark outlined:** No `<text>` elements; all glyphs are paths; verified with `grep -c '<text' brandbook/logo-wordmark.svg` = 0
- [ ] **Favicon legibility:** Abstract mark tested at 16×16; 16px rasterization confirms a readable glyph
- [ ] **Monochrome SVG exists:** `brandbook/logo-monochrome.svg` with `fill="currentColor"` committed
- [ ] **No raster in SVGs:** `grep -c 'base64' brandbook/*.svg` = 0
- [ ] **tokens.css sync extended:** `check_synced_pair.py` covers all new mineral tokens and is passing
- [ ] **Phase 98 diff is color-only:** re-skin PR touches only color/token values in the four cascade blocks; zero non-color changes
- [ ] **Size budget:** `du -sh brandbook/` within the agreed limit before Phase 100 closes

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---|---|---|
| tokens.css committed with failing AA pairs | MEDIUM | Darken/lighten failing colors using uniform-scale method; update tokens.css; re-run sync check; propagate to admin CSS via token |
| Wordmark SVG with live text renders wrong on Hex.pm | LOW | Re-export with text outlined; commit; no logic change |
| Dark-mode ramp breaks v1.13 elevation system | MEDIUM | Restore `#10161f` base; re-derive elevation values from STATE.md v1.13 decisions |
| Repo bloated with large PNGs | HIGH — history rewrite | If caught before merge: remove and add to .gitignore. After merge: git-filter-repo removes them but is expensive and disruptive. Prevent only. |
| Token drift (tokens.css != admin CSS) | LOW | Run sync check; identify differing values; update token file first, then propagate |
| Phase 98 changed non-color properties | MEDIUM | Revert non-color hunks; file them as a separate issue; re-submit narrow diff |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---|---|---|
| EmberCopper + Warning + MossGrey fail AA on light backgrounds | Phase 95 — audit/palette | Contrast matrix in `brandbook/` shows ≥4.5:1 for all normal-text pairings |
| Brand colors fail AA on dark base `#10161f` | Phase 95 — audit/palette | Dark-mode column in contrast matrix passes |
| OKLCH hue drift from naive HSL darken | Phase 95 — specify uniform-scale method | Remediated tokens have <3 degree hue drift from book-specified values |
| Dark ramp inconsistent with v1.13 | Phase 95 — map brand colors to existing ramp slots | Dark cascade block values reference v1.13 ramp anchors from STATE.md |
| SVG wordmark live text rendering failures | Phase 97 — logo production | `grep '<text' brandbook/*.svg` = 0 for all finalized artifacts |
| Favicon illegibility at 16px | Phase 97 — logo production | 16px rasterization review included in phase deliverable |
| Monochrome/dark-mode SVG missing | Phase 97 — logo production | `brandbook/` includes `logo-monochrome.svg` with `fill="currentColor"` |
| Embedded raster in SVG | Phase 97 — logo production | `grep 'base64' brandbook/*.svg` = 0 |
| Token drift between brandbook and admin CSS | Phase 96 (establish) + Phase 98 (enforce) | `check_synced_pair.py` extended and CI-green |
| Over-specification / non-color changes in re-skin | Phase 98 — scope gate | PR diff review: zero non-color changes in `rulestead_admin.css` |
| Brand thrash / churn for no reason | Phase 95 approves each remediation; Phase 98 is colors-only | Each changed token has a documented reason (AA compliance or brand alignment) |
| Repo bloat from binary assets | Phase 100 — artifact plan and size budget | `du -sh brandbook/` check in CI; `grep 'base64' brandbook/*.svg` = 0 |
| SignalGold used as text | Phase 96 — token semantic assignment | Token file marks SignalGold as decorative-only; no `--rs-text-*` role assigned |

---

## Sources

- WCAG 2.1 §1.4.3 (contrast minimum 4.5:1 normal text, 3:1 large text) and §1.4.11 (3:1 non-text UI components) — authoritative
- OKLCH/OKLab specification by Bjorn Ottosson (2020) — hue angle preservation by uniform RGB scaling confirmed by matrix computation above
- Contrast ratios computed directly from brand-book hex values using the WCAG relative-luminance formula — no third-party tool dependency
- v1.13 STATE.md decisions: dark base `#10161f`, elevation by lightening, hairline borders, `#c45c26` to `#9a3f12` AA fix (measured hue drift: 2.1 OKLCH degrees)
- Rulestead brand book §12 (mineral palette), §13 (typography), §14 (logo), §25 (implementation defaults)
- PROJECT.md v1.14 scope: "colors only — gated by check_synced_pair.py, WCAG-AA both themes, and the design-system fixture"

---
*Pitfalls research for: v1.14 Brand System Realization — palette engineering, dark-mode derivation, SVG/logo production, repo hygiene, token lifecycle*
*Researched: 2026-06-04*

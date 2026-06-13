# Project Research Summary

**Project:** Rulestead v1.14 — Brand System Realization
**Domain:** Source-controlled brand collateral + admin CSS re-skin for an Elixir/Hex OSS devtool
**Researched:** 2026-06-04
**Confidence:** HIGH

## Executive Summary

Rulestead v1.14 is not a feature milestone — it is an engineering discipline problem applied to design. The goal is to promote the recovered 27-section brand book from a `prompts/` context file into a machine-assisted, WCAG-AA-verified, source-controlled system. The deliverable is a self-contained `brandbook/` tree (tokens, logo SVG system, specimens, copy surfaces) plus a colors-only re-skin of the shipped admin CSS. All of this happens without touching the auto-publish pipeline, without introducing a build-time toolchain dependency, and without breaking anything v1.13 shipped.

The recommended approach is mirror-not-generate: `brandbook/tokens.json` is the canonical record; `brandbook/tokens.css` and `rulestead_admin.css` are hand-authored mirrors of its colour values, kept honest by two composable drift-check scripts. This mirrors exactly the pattern already proven by `check_synced_pair.py`. There is no Style Dictionary, no SCSS preprocessor, no node build step. Every artifact is a committed, reviewable, diffable file. The only raster binaries allowed in the repo are `favicon.ico`, `favicon.png`, and `apple-touch-icon.png`.

The dominant risk is palette engineering, not implementation. Computed WCAG 2.x contrast ratios against the brand-book hex values reveal that Ember Copper (`#B96A3A`), Warning (`#B57A21`), MossGrey (`#6C7A73`), and every semantic color on dark (`#10161f`) fail 4.5:1 for normal-weight text. These failures must be resolved in Phase 95 — before a single token value is committed — using the OKLCH-preserving uniform-RGB-scale darkening method. The phase ordering (95 audit → 96 tokens → 97 logo → 98 re-skin → 99 specimens → 100 copy/hygiene) is dependency-forced, not arbitrary.

---

## Key Findings

### Recommended Stack

The tooling stack is deliberately minimal: DTCG `tokens.json` (2025.10 stable spec) as the machine-readable token source of truth, a hand-authored `tokens.css` mirroring it, SVGO v4.0.1 for SVG optimization, and Google Fonts CDN references (not committed binaries) for Sora, Inter, and IBM Plex Mono. All three typefaces are SIL OFL 1.1. Style Dictionary is explicitly deferred — it adds a Node.js build dependency to a pure Elixir/Hex repo for zero benefit at CSS-only scope.

**Core technologies:**
- **DTCG `tokens.json` (2025.10 stable):** Machine-readable token source of truth — first stable spec release 2025-10-28; `$value`/`$type`/`$description` keys; alias syntax `{group.token}`; no build required to read
- **Hand-authored `tokens.css`:** CSS custom property output — lower-friction than Style Dictionary for CSS-only scope; maintained via `check_brand_tokens.py` drift check
- **SVGO v4.0.1:** SVG optimization — `removeViewBox` and `removeTitle` disabled by default in v4, correct accessibility posture out of the box; `svgo.config.mjs` ESM-only
- **Google Fonts CDN (OFL-1.1, no binaries committed):** Sora/Inter/IBM Plex Mono delivery — legal to bundle but binary blob churn is not worth it; Fontsource documented as the self-hosted path if needed later
- **`favicon.svg` + `favicon.ico` + `apple-touch-icon.png`:** Three-file favicon strategy — SVG primary, ICO for Safari/legacy, PNG for iOS home-screen; only raster binaries allowed in `brandbook/`
- **`og-card.svg` (source only, PNG on demand):** `viewBox="0 0 1200 630"` SVG committed; PNG rasterized locally with `resvg` and not committed
- **`check_brand_assets.sh`:** Pre-commit size guard rejecting font binaries and any non-raster `brandbook/` file over 50 KB

**What not to use:**
- Style Dictionary as a mandatory build step — overkill for CSS-only OSS
- Committed font binaries (`.woff2`, `.ttf`, etc.) — binary blob churn with no legal requirement
- DTCG Resolver module (`$resolvers`) — still a draft; use explicit `semantic.color.light.*` / `semantic.color.dark.*` alias groups instead
- `<text font-family="Sora">` in committed logo/icon SVGs — renders as fallback on GitHub and Hex.pm; outline all wordmark text to paths before committing

### Expected Features

The artifact inventory splits cleanly between P1 table stakes that gate every downstream surface and P2 differentiators that separate "has a logo" from "has a real brand system." Eleven artifact categories are explicit anti-features — the most expensive traps are a PDF brand book (binary blob, rots immediately), an animated logo (wrong context for OSS library surfaces), and a standalone docs site (HexDocs is sufficient while adoption is early).

**Must have — P1 table stakes:**
- `tokens.json` + `tokens.css` — gates the CI sync guard and admin re-skin; no net-new design decisions
- Primary logo SVG lockup (wordmark + mark) — blocks all other brand surfaces; concept directions A/B/C already spec in brand book §14
- Icon/mark SVG (standalone) — derived from primary; needed for favicon, social card, README
- Monochrome variants (`fill="currentColor"` for admin dark-mode; explicit `#000000` for print) — derivative, low-cost
- Favicon set (`.ico`, `32x32.png`, `apple-touch-icon.png`) — generated from mark SVG; never from wordmark
- Social preview card 1280x640 PNG — GitHub social preview requires raster; SVG template committed, PNG exported on demand
- Palette specimen SVG — audit gate and visual reference; one SVG with hex + token names
- README hero — table stakes for any serious OSS library (Oban, Livebook, Bun all have one)
- Hex.pm `:description` field — search-discoverability copy; already drafted in brand book §7
- HexDocs intro paragraph — every adopter reads this first; verify against `Rulestead` module `@moduledoc`
- Admin re-skin to mineral palette — most-seen brand surface; colors-only cascade change, WCAG-AA gated

**Should have — P2 differentiators:**
- Typography specimen SVG — type ramp reference for landing page / blog authors
- Code-block / terminal specimen SVG — establishes the "how code looks in Rulestead marketing" standard
- UI component specimens (light + dark) — brand-accurate button/badge/input reference
- `brandbook/VOICE.md` — 8–12 concrete good/bad pairs from brand book §9/§19; prevents contributor drift
- `brandbook/RELEASE-TEMPLATE.md` — consistent release-announcement scaffold
- GitHub repo description + topics — `elixir`, `phoenix`, `feature-flags`, `remote-config`, `hex`
- Repo size budget + `check_brand_tokens.py` CI guard — operational discipline differentiator vs peers

**Defer (v1.x if landing page milestone opens, or v2+):**
- Animated SVG / CSS motion — website-only; no website yet
- Standalone documentation site — HexDocs is sufficient
- Mascot / character design — contradicts "infrastructure-grade" positioning archetype
- Merchandise designs — speculative; revisit after meaningful adoption
- Full icon library — admin already has an icon pattern; custom set requires sustained maintenance
- PDF brand book — binary blob that rots; markdown + SVGs are the living brand book

### Architecture Approach

The entire architecture is built on one principle: drift detected by a comparison script at CI time, not enforced by a preprocessor or build dependency. `brandbook/` is a no-runtime-dependency tree. `rulestead_admin.css` is a committed, reviewable file. The two are kept synchronized by two composable Python scripts (`check_synced_pair.py` unchanged + new `check_brand_tokens.py`) appended to the existing `scripts/ci/lint.sh` surface. Merging to main continues to auto-publish both Hex packages exactly as before.

**Major components:**

1. **`brandbook/` tree** — canonical source of truth for all brand collateral: `tokens.json`, `tokens.css`, `docs/brand-usage.md`, `assets/logo/` (SVGs only), `assets/specimens/` (SVGs only). No build tooling dependency; consuming it means reading files.

2. **`scripts/check_brand_tokens.py` (new)** — drift check: parses `tokens.json` `admin_css_mapping.light` and compares against `rulestead_admin.css` Block 1 declarations. Exits non-zero on any mismatch. Combined with existing `check_synced_pair.py` (which guards Blocks 2+3 dark pair), the two scripts together provide complete four-block consistency coverage.

3. **`rulestead_admin.css` re-skin surface** — colors-only edit to the four cascade blocks: Block 1 + 4 (light synced pair) and Block 2 + 3 (dark synced pair). Only brand/accent/neutral-ramp hex values change. Token names, cascade structure, invariant tokens (typography, spacing, radius, motion, z-index), and status tokens are untouched.

4. **`rulestead_admin/priv/static/images/` (new dir)** — `rs-mark.svg` and `rs-mark-dark.svg` for admin nav/header. Admin templates reference these; served at `/images/rs-mark.svg` relative to the admin router mount.

5. **Demo logo replacement** — `examples/demo/backend/priv/static/images/logo.svg` (currently an off-brand Phoenix flame) replaced with the new brand mark; fingerprinted copy re-fingerprinted; `.gz` sidecars regenerated.

6. **`prompts/rulestead-brand-book.md` pointer** — file retained as prompts/ context anchor; pointer comment added at top pointing to `brandbook/brand-book.md`. Never deleted — CLAUDE.md references it.

### Critical Pitfalls

1. **Ember Copper, Warning, MossGrey, and all semantic colors on dark fail WCAG AA — computed, not assumed.** Ember Copper `#B96A3A` is 4.05:1 on white (fails 4.5:1 normal text). Warning `#B57A21` is 3.64:1 on white. MossGrey `#6C7A73` is 3.77:1 on Stone Mist. On dark base `#10161f`: SteadBlue is 3.33:1, Success 3.62:1, Danger 3.45:1, Info 3.25:1, MossGrey 4.04:1 — all fail. Fix in Phase 95 before any token is committed. Use uniform-RGB-scale darkening (multiply all channels by constant `k < 1`) to preserve OKLCH hue to within 0–0.6 degrees. Do not use HSL lightness reduction — it produces hue drift that makes copper look brownish-grey.

2. **Dark-mode ramp must anchor on the v1.13 system, not derived fresh from the brand-book light palette.** The v1.13 dark base `#10161f` is canonical (Basalt `#0F1720` is visually indistinguishable at 1.01:1; do not swap). Elevation goes by luminance increase, not hue shift. Dark-mode token values are AA-lightened mineral variants mapped to existing ramp slots from STATE.md, not a new ramp.

3. **SVG wordmark with live `<text>` elements renders as fallback font on GitHub and Hex.pm.** GitHub SVG renderer does not load web fonts. Outline all wordmark text to paths before any SVG is committed to `brandbook/`. Verify with `grep -c '<text' brandbook/assets/logo/*.svg` = 0.

4. **Token drift between `tokens.json` and `rulestead_admin.css`.** If Phase 98 (re-skin) starts before Phase 96 (tokens) is final, engineers patch the CSS directly and the sync guard is bypassed. Strict gate: `check_brand_tokens.py` must be authored and CI-green before Phase 98 touches the cascade.

5. **Phase 98 scope creep — touching non-color properties during the re-skin.** The re-skin is colors-only. Any spacing, typography, border-radius, or layout changes bloat the diff, are harder to revert, and risk regressing v1.13. Phase 95 audit must explicitly define the change surface; Phase 98 PR review verifies zero non-color lines changed in `rulestead_admin.css`.

6. **Repo bloat from binary brand exports.** PNG exports, social card images, and specimen screenshots are permanently fat in git history. SVG source is always committed; PNGs generated on demand from SVG with a documented `rsvg-convert` command. CI guard fails if any non-raster `brandbook/` file exceeds 50 KB.

---

## Implications for Roadmap

Research confirms the six-phase structure (95–100) is dependency-forced and correct. The order cannot be changed without violating the artifact dependency graph. Each phase gate is concrete and testable.

### Phase 95 — Audit + Palette Reconciliation (GATE ZERO)
**Rationale:** The WCAG contrast failures are computed facts, not hypotheticals. Every subsequent phase depends on approved AA-passing hex values. No token file, no SVG, no CSS edit may proceed until the reconciliation table is signed off.
**Delivers:** Palette reconciliation table (brand-book name → current shipped hex → proposed re-skin hex → AA-verified hex); dark-mode slot mapping to v1.13 ramp anchors from STATE.md; OKLCH-uniform-scale methodology prescribed for all remediation.
**Addresses:** EmberCopper light AA fix; all dark-mode semantic color AA failures; Warning text-use constraint; SignalGold decorative-only designation; dark ramp continuity with v1.13.
**Avoids:** Shipping a design system that fails accessibility; hue drift from HSL darkening; fresh dark ramp that breaks v1.13 elevation system.
**Research flag:** No additional research needed — contrast ratios are fully computed in PITFALLS.md.

### Phase 96 — Design Tokens (`brandbook/` scaffold + `tokens.json` / `tokens.css`)
**Rationale:** Tokens are the machine-readable source of truth that all downstream phases consume. The CI sync guard must exist and must fail on the un-re-skinned CSS before Phase 98 starts — intentionally failing confirms the check works.
**Delivers:** `brandbook/` directory tree; `tokens.json` with DTCG structure (primitive → semantic → `admin_css_mapping`); `tokens.css` CSS variable declarations; `brandbook/docs/brand-usage.md`; `scripts/check_brand_tokens.py`; `scripts/ci/lint.sh` extended; pointer comment in `prompts/rulestead-brand-book.md`.
**Uses:** DTCG 2025.10 `$value`/`$type`/`$description` format; explicit `semantic.color.light.*` / `semantic.color.dark.*` alias groups (Resolver module is draft — not stable enough for modes).
**Avoids:** Style Dictionary build step; raw Figma export noise; DTCG Resolver draft features.
**Research flag:** No additional research needed — DTCG format is HIGH confidence from official spec.

### Phase 97 — Logo/Mark SVG System
**Rationale:** The primary lockup blocks all derivative artifacts (mark, favicon, social card, README hero). Mark SVG commits the final palette hex values in `fill` attributes, confirming exact hex references for Phase 98. Can be parallelized with Phase 96; must complete before Phases 98 and 99.
**Delivers:** Full logo set in `brandbook/assets/logo/`: `rs-wordmark.svg`, `rs-wordmark-dark.svg`, `rs-mark.svg`, `rs-mark-dark.svg`, `rs-mark-mono.svg` (`fill="currentColor"`), `rs-favicon.svg`, `rs-social-card.svg`. Admin `priv/static/images/` dir with mark SVGs. Demo `logo.svg` replaced (Phoenix flame removed).
**Addresses:** SVG wordmark outlined (no `<text>` elements); monochrome `fill="currentColor"` variant for dark-mode admin; favicon tested at 16px; no raster embedded in SVGs (`grep 'base64'` = 0).
**Avoids:** Live-text wordmark rendering failures; favicon generated from wordmark (illegible at 16px); Figma raster layer sneaking into SVG via base64 `<image>` embed.
**Research flag:** Logo concept direction (A/B/C from brand book §14) requires a human choice — design decision, not a research gap. Implementation patterns are fully documented for any direction.

### Phase 98 — Admin Re-skin (CSS Cascade)
**Rationale:** Colors-only cascade change. Requires tokens.json canonical (Phase 96) and mark SVG hex confirmation (Phase 97). Must complete before specimens (Phase 99) since component specimens reference the re-skinned admin.
**Delivers:** Modified `rulestead_admin.css` with mineral palette in all 4 cascade blocks; `check_synced_pair.py` green; `check_brand_tokens.py` green; `design-system.html` swatches updated to mineral palette.
**Addresses:** `#2563eb` → `#3A6F8F` Stead Blue; `#9a3f12` → AA-verified Ember Copper variant; `#1d4ed8` → `#183247` Ink Blue hover; dark-mode AA-lightened semantic colors.
**Avoids:** Touching non-color properties; editing only one block of a synced pair; starting before `check_brand_tokens.py` is authored and CI-green.
**Research flag:** No additional research — constraint is clear and the WCAG fixture harness from v1.13 is in place.

### Phase 99 — Specimens
**Rationale:** Specimen SVGs depend on final tokens (Phase 96), final mark (Phase 97), and re-skinned admin (Phase 98) as reference inputs. They are pure authored SVG documents — no build step, no binary output.
**Delivers:** `brandbook/assets/specimens/`: `palette.svg`, `typography.svg`, `components.svg`, `code-block.svg`, `readme-header.svg`, `social-card.svg`. All SVG size budget CI checks passing (20 KB logo / 50 KB specimen limits).
**Addresses:** Visual audit gate for the mineral palette; reference asset for landing page / blog authors; code-block styling standard (Basalt background, Stead Blue for keywords, Ember Copper for strings).
**Avoids:** Committing PNG exports of specimens; exceeding the per-specimen size budget.
**Research flag:** Standard patterns — pure SVG authoring, no integration risk.

### Phase 100 — Marketing Copy + Repo Artifact Plan
**Rationale:** Copy surfaces and repo hygiene are low-dependency and close the milestone. Full CI end-to-end confirmation runs here.
**Delivers:** Hex.pm `:description` updated in both `mix.exs` files; `Rulestead` module `@moduledoc` opening verified against voice guide; `brandbook/VOICE.md`; `brandbook/RELEASE-TEMPLATE.md`; `brandbook/BUDGET.md`; `brandbook/ACCESSIBILITY.md`; `brandbook/README.md` (artifact index + GitHub description/topics); README hero updated in both packages. Full CI confirmation: both sync checks + SVG size budget all green. `.planning/PROJECT.md` and `STATE.md` updated to v1.14 shipped.
**Addresses:** Hex.pm search discoverability; consistent release voice; WCAG-AA claim scope statement; contributor drift prevention.
**Avoids:** Committing `og-card.png` as a static blob; mascot/sticker/PDF brand book scope creep.
**Research flag:** Standard patterns. GitHub description/topics is a UI edit; document chosen values in `brandbook/README.md`.

### Phase Ordering Rationale

- Phase 95 must be first — every hex value in every subsequent artifact derives from the approved palette. Contrast failures are computed, not estimated; there is no shortcut.
- Phase 96 before Phase 98 — `check_brand_tokens.py` must exist and be able to fail before the admin CSS is edited. This is the mechanism that prevents silent token drift.
- Phase 97 can overlap Phase 96 — logo design does not require tokens committed, only palette decisions from Phase 95. Parallelizing is valid if bandwidth allows.
- Phase 98 before Phase 99 — component specimens reference the re-skinned admin. Authoring them against old colors means re-doing them.
- Phase 100 last — copy and hygiene are low-risk, late-binding. Moving them earlier risks re-doing them if earlier phases shift a value.

### Research Flags

Phases with standard patterns (no additional research needed):
- **Phase 96:** DTCG format HIGH confidence; hand-authoring approach confirmed against existing repo pattern.
- **Phase 97:** SVG production patterns HIGH confidence; SVGO v4 config fully documented; outline-text and base64 guards are mechanical checks.
- **Phase 98:** Re-skin scope precisely bounded; tooling (contrast fixture, sync scripts) already in repo.
- **Phase 99:** Pure SVG authoring; no integration risk.
- **Phase 100:** Copywriting from brand book; repo hygiene from STACK.md patterns; no unknowns.

Phases requiring human judgment (not research gaps):
- **Phase 95:** Contrast ratios are fully computed in PITFALLS.md. The only decision is whether to accept the AA-adjusted hex values as brand-compatible — maintainer call, not a research question.
- **Phase 97:** Logo concept direction (A/B/C from brand book §14) is a design choice. Research has confirmed SVG production patterns for whichever direction is chosen.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | DTCG 2025.10 spec verified against official source; SVGO v4 release notes confirmed; font licenses confirmed against upstream repos; `--rs-*` cascade shape read directly from committed CSS |
| Features | HIGH | Table stakes grounded in Oban, Livebook, Phoenix, Tailwind, Astro, Bun examples; anti-features grounded in concrete cost/benefit reasoning; complexity estimates have MEDIUM caveat for repo-specific variables |
| Architecture | HIGH | All integration points grounded in repo-local evidence: cascade blocks read directly, `check_synced_pair.py` read directly, demo logo path confirmed, `scripts/` layout confirmed |
| Pitfalls | HIGH | Contrast ratios computed directly from brand-book hex values using WCAG relative-luminance formula; no third-party tool dependency; OKLCH hue angle preservation confirmed by matrix computation |

**Overall confidence: HIGH**

### Gaps to Address

- **Logo concept direction (A/B/C):** Not a research gap — a design decision. Brand book §14 specifies three directions (path/frame/layer concepts; no phoenix/flag/shield). Maintainer must pick one before Phase 97 begins. Once picked, all implementation patterns are fully documented.

- **AA-adjusted hex acceptance:** The minimum-darkening targets in PITFALLS.md are computed to just-pass 4.5:1. Actual tokens.json values may be nudged slightly darker to give margin above the floor. Phase 95 deliverable must document the chosen value and computed ratio. No additional research needed.

- **`check_brand_tokens.py` vs extending `check_synced_pair.py`:** ARCHITECTURE.md recommends a new independent script; PITFALLS.md describes extending the existing one. The new-script approach wins (single responsibility, independently debuggable). Minor terminology inconsistency in research, not a functional gap.

- **Admin LiveView template references for `rs-mark.svg`:** The admin currently has no template referencing a logo from `priv/static/images/`. Phase 97 creates the directory and files; a quick grep of admin LiveView templates in Phase 97 will identify where to add the `<img>` or inline SVG reference. Not a blocker.

---

## Sources

### Primary (HIGH confidence)
- DTCG Design Tokens Format Module 2025.10 — `$value`/`$type`/`$description` keys; alias syntax; file extension `.tokens.json`
- W3C community announcement 2025-10-28 — DTCG first stable version confirmed
- SVGO GitHub Releases (v4.0.1) + `preset-default` docs — `removeViewBox`/`removeTitle` disabled by default in v4
- Sora OFL.txt (github.com/sora-xor/sora-font), Inter LICENSE.txt (github.com/rsms/inter), IBM Plex Mono (Fontsource) — SIL OFL 1.1 confirmed
- WCAG 2.1 §1.4.3 (4.5:1 normal text, 3:1 large text) and §1.4.11 (3:1 non-text UI) — authoritative
- Contrast ratios computed directly from brand-book hex values using WCAG relative-luminance formula
- OKLCH/OKLab specification (Bjorn Ottosson, 2020) — hue angle preservation by uniform RGB scaling confirmed
- `rulestead_admin/priv/static/css/rulestead_admin.css` lines 1–550 — cascade block structure read directly
- `scripts/check_synced_pair.py` — drift-check pattern confirmed by direct read
- `prompts/rulestead-brand-book.md` — §12 mineral palette, §14 logo directions, §9/§19 voice
- `.planning/PROJECT.md` — v1.14 scope, auto-publish pipeline constraint
- Tailwind CSS v4 announcement — `@theme` CSS-first config confirmed (official)
- Style Dictionary DTCG support page — v4 first-class DTCG; v5.4.x current; full 2025.10 Resolver WIP

### Secondary (MEDIUM confidence)
- Oban GitHub (github.com/oban-bg/oban) — logotype in assets/, README structure, Hex.pm description pattern
- Livebook GitHub (github.com/livebook-dev/livebook) — screenshot + minimal brand approach
- Phoenix Hex.pm — "Peace of mind from prototype to production" tagline pattern
- Tailwind CSS brand page (tailwindcss.com/brand) — mark + logotype + white variants; trademark rules
- Astro press page (astro.build/press/) — primary/gradient/mono lockup set; spacing guidelines
- Bun GitHub (github.com/oven-sh/bun) — README hero pattern
- GitHub social preview docs — 1280x640 raster requirement
- Favicon best practices 2025 (browserux.com) — SVG + ICO + apple-touch-icon strategy
- Elixir v1.18 release announcement — release-announcement structure reference
- v1.13 STATE.md decisions — dark base `#10161f`, elevation system, `#c45c26` → `#9a3f12` AA fix (2.1 OKLCH degrees hue drift)

---
*Research completed: 2026-06-04*
*Ready for roadmap: yes*

# Plan 105-01 — Summary (Propagation, LOGO-11)

**Executed:** 2026-06-12 · **Branch:** feat/v1.15-identity-tournament · **Status:** Complete

## What shipped

1. **Admin shell wordmark (D-01)** — `shell.ex` now renders the Phase 103 winner
   lockup (rs-wordmark.svg geometry, viewBox `0 0 340 62`) inline via new
   `brand_lockup/1` + `brand_wordmark/1` components, classed by semantic role:
   route trace → `rs-shell__wordmark-line` (stroke), copper node →
   `rs-shell__wordmark-active`, quarry nodes → `rs-shell__wordmark-muted`,
   glyph paths → `rs-shell__wordmark-type`. The lockup links to the section
   overview (`brand_href/1` via `Navigation.overview/2`).
2. **CSS --logo-\* vars (D-02)** — defined in ALL FOUR cascade blocks (light
   default, system-dark @media, dark pin, light pin): light = line `#3a6f8f` /
   active `#9b5931` / muted `#c4ccd1` / type `#183247`; dark = line `#5885a0` /
   active `#9b5931` / muted `#3d4a55` / type `#e8edf3`. `.rs-shell__wordmark`
   aspect-ratio `340 / 62`; `.rs-shell__brand` hover/focus/active states added.
3. **Admin statics (D-03)** — `rs-mark.svg` / `rs-mark-dark.svg` replaced with
   the Phase 104 d-sigil family (filenames kept). Fixture HTML files
   (design-system.html, theme-control-harness.html, theme-harness.html) embed
   no logo geometry on this branch — verified, no edits needed.
4. **Demo (D-04)** — `images/logo.svg` → winner wordmark lockup; layout img slot
   widened 36px → 140px (brand §14: 120px lockup minimum) with alt text;
   `favicon.svg` added from brandbook `rs-favicon.svg`; `favicon.ico`
   regenerated as a 32×32 transparent PNG render of the d-sigil via headless
   Chrome (single-size PNG-in-.ico, 1.1 KB — same convention as the previous
   64px asset). `mix phx.digest.clean --all && mix phx.digest` re-run.
   `root.html.heex` untouched.

## Branch-state deviation (documented)

The plan was phrased as a "swap" of an existing `brand_wordmark` + `--logo-*`
system, but that system lives only on the parked polish branch
(`fix/admin-ui-polish-attention-rail-search`). Per the maintainer decision in
105-CONTEXT ("proceed on v1.15 now; polish branch resolves conflicts later on
its side") the components and vars were **added** to this branch, using the
polish branch's exact class scheme (`rs-shell__wordmark-{line,active,muted,type}`,
`rs-shell__brand`, `--logo-*`) so its later merge resolution is mechanical.
A visually-hidden `.rs-shell__brand-text` ("Rulestead") satisfies the package
accessibility audit (links must have text content).

## Verification

- **Admin test suite:** `mix test` → **200 tests, 0 failures** (the 4
  accessibility-audit failures surfaced mid-task were fixed honestly with the
  hidden brand text, not by relaxing the audit).
- **Guards:** `check_synced_pair.py` → SYNCED PAIR IDENTICAL (56 dark / 57
  light tokens); `check_brand_tokens.py` → BRAND TOKENS SYNCED (68 tokens).
- **Visual evidence:** `scratch/header-evidence.png` (git-ignored) — wordmark at
  36px header height on light + dark pins using the real package CSS. Both
  surfaces verified by inspection: type flips ink↔light, route trace flips
  `#3a6f8f`↔`#5885a0`, copper node holds, muted nodes recede per theme.
- **Demo e2e:** skipped per D-05 "if cheap" — requires booting backend +
  frontend stack; favicon change is a static binary swap covered by digest
  regeneration.

## Commits

- `9f02a49` feat(admin): render winner wordmark lockup in shell header
- `24d227d` feat(admin): theme winner lockup via --logo-* vars in all four cascade blocks
- `60deace` feat(admin): replace static rs-mark family with winner d-sigil
- `a64f05c` chore: git-ignore phase 105 scratch renders
- `921f035` feat(demo): propagate winner identity to demo logo + favicon, regen digest

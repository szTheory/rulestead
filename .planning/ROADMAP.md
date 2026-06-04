# Roadmap: Rulestead

## Milestones

- 🚧 **v1.14 - Brand System Realization** — Phases 95–100 (in progress) — current milestone
- ✅ **v1.13 - Admin UI: First-Class Dark Mode + Design-System Polish** — Phases 87-94 (shipped 2026-06-04) — [.planning/milestones/v1.13-MILESTONE-AUDIT.md](milestones/v1.13-MILESTONE-AUDIT.md)
- ✅ **v1.12 - Adoption Evidence Depth** — Phases 82-86 (shipped 2026-05-29) — [.planning/milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- ✅ **v1.11.1 - Gap Closure** — Phases 79-81 (shipped 2026-05-29) — [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md) · [audit](milestones/v1.11.1-MILESTONE-AUDIT.md)
- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Current focus

**v1.14 — Brand System Realization** (Phases 95–100). Turn the recovered brand book into a buildable, WCAG-AA-verified, source-controlled brand system in `brandbook/`, and re-skin the shipped admin UI to the canonical mineral palette — without repo bloat or widening the sibling-package product shape.

## Phase numbering

v1.13 completed at Phase 94. This milestone (v1.14) runs **Phases 95–100**. Next milestone starts at **101**.

## Phases

- [x] **Phase 95: Brand Audit + Palette Reconciliation** — Gate-zero: audit brand book, compute WCAG AA contrast ratios, resolve all failures with OKLCH-preserving fixes, lock the dark-mode ramp, obtain human sign-off on AA-adjusted hexes. Nothing downstream may start until palette decisions are final. (completed 2026-06-04)
- [ ] **Phase 96: Design Tokens (`brandbook/` scaffold)** — Create the `brandbook/` directory tree, move and reconcile the brand book, author `tokens.json` (DTCG format) and `tokens.css`, write the drift-check script (`check_brand_tokens.py`), and extend CI lint. Gate: `check_brand_tokens.py` intentionally fails on un-re-skinned CSS, confirming the check works.
- [ ] **Phase 97: Logo & Mark SVG System** — Produce three SVG mark concepts (A/B/C), obtain human concept selection, deliver the full lockup set (wordmark, icon, monochrome, favicon, social card, light/dark variants), commit to `brandbook/assets/logo/`, wire into admin `priv/static/images/`, and replace the phoenix-flame demo logo.
- [ ] **Phase 98: Admin Re-skin (CSS Cascade)** — Colors-only edit to all four `rulestead_admin.css` cascade blocks, aligned to the locked mineral palette from Phase 96. Gates: `check_synced_pair.py` green, `check_brand_tokens.py` green, `design-system.html` swatches updated, WCAG-AA both themes passing.
- [ ] **Phase 99: Specimens** — Author reproducible SVG specimens: palette, typography, UI components, code-block, README header, social card. All committed to `brandbook/assets/specimens/`. CI size-budget lint passing for all specimen SVGs.
- [ ] **Phase 100: Marketing Copy + Repo Artifact Plan** — Ready-to-paste copy blocks, voice/microcopy reference, szTheory brand-architecture note, `brandbook/README.md` with directory index and GitHub description/topics, size budget, accessibility note, pointer from `prompts/`, full CI end-to-end confirmation.

## Phase Details

### Phase 95: Brand Audit + Palette Reconciliation

**Goal**: The canonical AA-passing mineral palette is locked and documented, with a written decision record that every downstream phase can consume with confidence.
**Depends on**: Nothing (first phase of milestone; uses existing brand book in `prompts/`)
**Requirements**: BRD-01, BRD-02, BRD-03, PAL-01, PAL-02, PAL-03, PAL-04
**Human checkpoint**: Maintainer reviews and accepts each AA-adjusted hex value as brand-compatible before the phase closes. This is a deliberate gate — not a research question, a design decision.
**Success Criteria** (what must be TRUE):

  1. A written palette reconciliation table exists (brand-book name → current shipped hex → proposed re-skin hex → AA-verified hex → computed WCAG 2.x ratio) covering every text/button pairing in both light (`#FFFFFF`, Stone Mist `#E8ECE8`, Rain Tint `#F5F7F6`) and dark (`#10161f`) surfaces — and every entry shows ≥4.5:1 for normal-weight text roles.
  2. Every remediated value used OKLCH-preserving uniform-RGB-scale darkening/lightening (not HSL); the decision record notes the method and the computed OKLCH hue angle pre- and post-adjustment for Ember Copper and Warning (must be <3° drift).
  3. The dark-mode ramp is mapped to existing v1.13 slots (base `#10161f` kept, elevation by luminance increase, Signal Gold designated decorative-only) — no fresh ramp invented; no `--rs-surface-base` swap.
  4. Signal Gold `#D2A94E` carries an explicit decorative-only usage policy ("never as normal-weight text") in the written record.
  5. The relocated brand book exists at `brandbook/brand-book.md` (or the decision to relocate it during Phase 96 is confirmed) and the pressure-test audit (KEEP/TIGHTEN/REWORK/ADD/REMOVE) with scorecard is written.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 95-01-PLAN.md — Wave 0: scripts/check_contrast.py (WCAG + OKLCH verification script)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 95-02-PLAN.md — 95-PALETTE-RECONCILIATION.md (full reconciliation table + dark ramp + policies)
- [x] 95-03-PLAN.md — 95-BRAND-AUDIT.md (27-section pressure-test scorecard)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 95-04-PLAN.md — D-11 maintainer sign-off checkpoint (phase-close gate)

**UI hint**: yes

### Phase 96: Design Tokens (`brandbook/` scaffold)

**Goal**: The `brandbook/` directory tree is committed with machine-readable `tokens.json`, a hand-authored `tokens.css` mirror, the `check_brand_tokens.py` drift-check script, and CI lint extensions — and the drift check demonstrably fails on the un-re-skinned admin CSS, confirming the guard mechanism works before Phase 98 touches the cascade.
**Depends on**: Phase 95 (locked palette hex values)
**Requirements**: TOK-01, TOK-02, TOK-03, TOK-04
**Success Criteria** (what must be TRUE):

  1. `brandbook/tokens.json` exists in DTCG 2025.10 format (`$value`/`$type`/`$description`) with primitive, semantic (default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted), state, spacing, radius, border, shadow, focus-ring, code-block, and callout token groups, plus an `admin_css_mapping` section mapping `--rs-*` names to palette entries for both light and dark.
  2. `brandbook/tokens.css` exists as a hand-authored CSS custom property file mirroring the `--rs-*` token shape for light and dark, including the optional Tailwind token excerpt (TOK-04).
  3. `scripts/check_brand_tokens.py` exists, is executable, and exits non-zero with a per-token diff when run against the un-re-skinned `rulestead_admin.css` — confirming the check mechanism works before Phase 98.
  4. `scripts/ci/lint.sh` has both `python3 scripts/check_brand_tokens.py` and the SVG size-budget loop appended (additive, not rewritten); `brandbook/docs/brand-usage.md` and `prompts/rulestead-brand-book.md` pointer comment are committed.
  5. `brandbook/brand-book.md` is the canonical brand book (moved from `prompts/`), reconciled to ship-true reality; `prompts/rulestead-brand-book.md` retains a pointer comment at its top referencing the new location.

**Plans**: 4 plans
Plans:

**Wave 1** *(parallel)*

- [x] 96-01-PLAN.md — tokens.json + tokens.css (DTCG 2025.10 scaffold + CSS reference mirror)
- [x] 96-02-PLAN.md — brand-book relocation + §12 hex rework + brandbook/README.md + docs/brand-usage.md

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 96-03-PLAN.md — check_brand_tokens.py + lint.sh additive extension (check_synced_pair.py + brand-token check + SVG budget loop)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 96-04-PLAN.md — phase SC verification + STATE/ROADMAP update

### Phase 97: Logo & Mark SVG System

**Goal**: The full Rulestead logo system is committed — wordmark, icon, monochrome, favicon, and social card in both light and dark variants — with all text outlined to paths, no embedded raster, SVGO-optimized, and accessible; the phoenix-flame demo logo is retired.
**Depends on**: Phase 95 (palette hex values confirmed); human concept selection (A/B/C) required before final lockup is authored
**Requirements**: LOGO-01, LOGO-02, LOGO-03, LOGO-04, LOGO-05
**Human checkpoint**: Maintainer selects one of three SVG mark concepts (A structured path / B stead frame / C layered field) before the full lockup set is produced. This selection is a design decision and cannot be automated.
**Success Criteria** (what must be TRUE):

  1. Three SVG mark concepts (A, B, C) are produced and presented; one is selected; `brandbook/assets/logo/` contains the full lockup set: `rs-wordmark.svg`, `rs-wordmark-dark.svg`, `rs-mark.svg`, `rs-mark-dark.svg`, `rs-mark-mono.svg` (with `fill="currentColor"`), `rs-favicon.svg`, and `rs-social-card.svg`.
  2. All logo SVGs pass `grep -c '<text' brandbook/assets/logo/*.svg` = 0 (all wordmark glyphs outlined to paths; no live `<text>` elements).
  3. All logo SVGs pass `grep -c 'base64' brandbook/assets/logo/*.svg` = 0 (no embedded raster data).
  4. `rs-favicon.svg` is legible at 16px (confirmed by visual review at that canvas size); `rulestead_admin/priv/static/images/rs-mark.svg` and `rs-mark-dark.svg` exist as admin-embedded copies.
  5. `examples/demo/backend/priv/static/images/logo.svg` (and its fingerprinted copy) is replaced with the new brand mark; the phoenix-flame file is removed; any `.gz` sidecars are regenerated.

**Plans**: 4 plans
Plans:

- [ ] 97-01-PLAN.md — (to be planned)
- [ ] 97-02-PLAN.md — (to be planned)
- [ ] 97-03-PLAN.md — (to be planned)
- [ ] 97-04-PLAN.md — (to be planned)

**UI hint**: yes

### Phase 98: Admin Re-skin (CSS Cascade)

**Goal**: `rulestead_admin.css` is re-skinned to the canonical mineral palette across all four cascade blocks — colors only — and both CI drift checks plus the WCAG-AA contrast gate pass in both light and dark themes.
**Depends on**: Phase 96 (tokens.json canonical + `check_brand_tokens.py` working); Phase 97 (mark SVG commits final palette hex values, confirming exact `fill` references)
**Requirements**: SKIN-01, SKIN-02, SKIN-03
**Success Criteria** (what must be TRUE):

  1. `rulestead_admin.css` blocks 1–4 use mineral palette hex values (Stead Blue `#3A6F8F` / AA-verified Ember Copper / Ink Blue `#183247` / AA-lightened dark-mode semantic colors); the PR diff contains zero changes to non-color properties (no spacing, typography, border-radius, or layout lines changed).
  2. `python3 scripts/check_synced_pair.py` exits 0 (Blocks 2+3 dark pair still identical; Blocks 1+4 light pair still identical).
  3. `python3 scripts/check_brand_tokens.py` exits 0 (`BRAND TOKENS SYNCED (N tokens)` — Block 1 `--rs-*` declarations match `tokens.json` palette values).
  4. `design-system.html` colour swatches are updated to show the mineral palette; WCAG-AA contrast passes for all normal-weight text pairings in both light and dark themes (verified against the Phase 95 contrast matrix using the existing harness).

**Plans**: 4 plans
Plans:

- [ ] 98-01-PLAN.md — (to be planned)
- [ ] 98-02-PLAN.md — (to be planned)
- [ ] 98-03-PLAN.md — (to be planned)
- [ ] 98-04-PLAN.md — (to be planned)

**UI hint**: yes

### Phase 99: Specimens

**Goal**: Reproducible SVG specimens for the full brand system exist in `brandbook/assets/specimens/` — palette swatches, type ramp, UI components, code block, README header, and social card — all within the per-file size budget and all lint-passing.
**Depends on**: Phase 96 (tokens.css for swatch values); Phase 97 (final mark SVGs as inputs); Phase 98 (re-skinned admin as component reference)
**Requirements**: SPEC-01, SPEC-02
**Success Criteria** (what must be TRUE):

  1. `brandbook/assets/specimens/palette.svg` exists with all brand swatches annotated with hex value and token name (covers SPEC-01 palette half).
  2. `brandbook/assets/specimens/typography.svg` exists with the Sora/Inter/IBM Plex Mono type ramp labeled with token names (covers SPEC-01 typography half).
  3. `brandbook/assets/specimens/components.svg`, `code-block.svg`, `readme-header.svg`, and `social-card.svg` all exist in `brandbook/assets/specimens/` (covers SPEC-02 in full).
  4. All logo SVGs in `brandbook/assets/logo/` are ≤20 KB each; all specimen SVGs in `brandbook/assets/specimens/` are ≤50 KB each — verified by running the SVG size-budget loop appended to `scripts/ci/lint.sh`, which exits 0 with `SVG SIZE BUDGET OK`.

**Plans**: 4 plans
Plans:

- [ ] 99-01-PLAN.md — (to be planned)
- [ ] 99-02-PLAN.md — (to be planned)
- [ ] 99-03-PLAN.md — (to be planned)
- [ ] 99-04-PLAN.md — (to be planned)

**UI hint**: yes

### Phase 100: Marketing Copy + Repo Artifact Plan

**Goal**: All ready-to-paste copy surfaces, the voice reference, the szTheory brand-architecture note, `brandbook/README.md`, the size-budget doc, the accessibility note, and the `prompts/` pointer are committed; a full end-to-end CI lint run confirms all three checks (sync pair, brand tokens, SVG size budget) are green; the milestone is closed in planning docs.
**Depends on**: Phase 99 (all prior artifacts committed; repo in final state for CI end-to-end confirmation)
**Requirements**: COPY-01, COPY-02, REPO-01, REPO-02
**Success Criteria** (what must be TRUE):

  1. `brandbook/VOICE.md` contains a voice/microcopy reference (8–12 say-this/not-this pairs for error, empty, and success states) and `brandbook/RELEASE-TEMPLATE.md` contains a release-announcement scaffold — both grounded in brand book §9/§19 voice principles.
  2. Ready-to-paste copy blocks exist (as a committed file in `brandbook/`) for: GitHub repo description, Hex.pm package `:description` (updated in both `mix.exs` files), 140-char blurb, README intro/hero, landing hero/sub + primary/secondary CTAs, and three feature blurbs; a szTheory suite brand-architecture note (shared-vs-unique across Rulestead, Parapet, Scoria, Cairnloop) is written.
  3. `brandbook/README.md` exists as a self-contained directory index with cross-links to `rulestead_admin.css` and `brandbook/brand-book.md`; `brandbook/docs/brand-usage.md` is in final state (re-skin instructions, `check_brand_tokens.py` usage, new-contributor path).
  4. A repo-size guard is in place: a `.gitattributes` entry or CI step prevents binary bloat; `brandbook/BUDGET.md` documents per-file-type size limits; the SVG size-budget lint in `scripts/ci/lint.sh` is confirmed passing.
  5. Full CI end-to-end confirmation: `python3 scripts/check_synced_pair.py` + `python3 scripts/check_brand_tokens.py` + SVG size-budget loop all exit 0 in a single lint run; `REPO-02` guard is wired and active; `.planning/PROJECT.md` and `STATE.md` updated to v1.14 shipped.

**Plans**: 4 plans
Plans:

- [ ] 100-01-PLAN.md — (to be planned)
- [ ] 100-02-PLAN.md — (to be planned)
- [ ] 100-03-PLAN.md — (to be planned)
- [ ] 100-04-PLAN.md — (to be planned)

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 95. Brand Audit + Palette Reconciliation | 4/4 | Complete    | 2026-06-04 |
| 96. Design Tokens (brandbook/ scaffold) | 2/4 | In Progress|  |
| 97. Logo & Mark SVG System | 0/0 | Not started | - |
| 98. Admin Re-skin (CSS Cascade) | 0/0 | Not started | - |
| 99. Specimens | 0/0 | Not started | - |
| 100. Marketing Copy + Repo Artifact Plan | 0/0 | Not started | - |

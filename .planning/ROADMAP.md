# Roadmap: Rulestead

## Milestones

- 🔄 **v1.15 - Identity Tournament** — Phases 102–106 (active 2026-06-11)
- ✅ **v1.14 - Brand System Realization** — Phases 95–101 (shipped 2026-06-06) — [.planning/milestones/v1.14-ROADMAP.md](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 - Admin UI: First-Class Dark Mode + Design-System Polish** — Phases 87-94 (shipped 2026-06-04) — [.planning/milestones/v1.13-MILESTONE-AUDIT.md](milestones/v1.13-MILESTONE-AUDIT.md)
- ✅ **v1.12 - Adoption Evidence Depth** — Phases 82-86 (shipped 2026-05-29) — [.planning/milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- ✅ **v1.11.1 - Gap Closure** — Phases 79-81 (shipped 2026-05-29) — [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md) · [audit](milestones/v1.11.1-MILESTONE-AUDIT.md)
- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Current focus

**v1.15 — Identity Tournament** is active (started 2026-06-11). Replace the icon-left-of-text lockup with a unified, integrated logo identity selected by the maintainer through an iterative rendered-options tournament, propagate it to every rendered surface, and elevate `brandbook/index.html` into a designed artifact that stands on its own. Palette/voice/copy stay frozen; fonts/colors may change only if the winning design demands it, recorded in `103-WINNER.md`.

## Phase numbering

v1.14 completed at Phase 101. v1.15 runs **Phases 102–106**.

## Phases

- [x] **Phase 102: Logo Delta Audit + Tournament Studio** — Score the shipped lockup against brand-book §14's own wordmark-first recommendation, audit HTML brand book presentation quality, and build the generalized glyph→path pipeline + headless-Chrome render harness needed to run the tournament.
- [x] **Phase 103: Logo Tournament** — Human-gated iterative tournament: one plan per round, every round rendered (light/dark/mono, in-context sizes), maintainer keep/cut checkpoint per candidate, persistent bracket in `103-TOURNAMENT.md`, winner frozen in `103-WINNER.md`. Soft cap 5 rounds then consolidation checkpoint.
- [ ] **Phase 104: Winner Lockup Family + Brand Source Reconciliation** — Build the complete winner lockup family (primary, tagline secondary, derived mark/sigil, mono, dark/light, 16px favicon, social card), rewrite brand-book §14 as the shipped logo system, update tokens/specimens if the winner changed fonts/colors, and pass all token drift guards.
- [ ] **Phase 105: Propagation — Admin Shell + Demo** — Wire the new identity into the admin shell wordmark + `--logo-*` theme vars across all cascade blocks, update admin static marks, replace demo logo/favicon, regenerate digest, and pass admin LiveView and demo e2e suites. (Merge-order decision for parked polish branch required before execution.)
- [ ] **Phase 106: HTML Brand Book Elevation + Milestone Close** — Redesign the generator's chrome layer to produce a designed, self-contained brand book artifact (cover/hero, sticky scrollspy nav, editorial typography, live token swatch cards, designed logo plates, print stylesheet); pass all drift/budget/e2e guards; close milestone v1.15.

## Phase Details

### Phase 102: Logo Delta Audit + Tournament Studio

**Goal**: The maintainer has a written pressure-test delta audit of the shipped lockup and HTML brand book, and the tournament tooling (generalized glyph→path pipeline + render harness) is in place so Phase 103 can start immediately.
**Depends on**: Nothing (first phase of v1.15; uses existing `brandbook/` and `scripts/`)
**Requirements**: BRD-06, LOGO-06
**Success Criteria** (what must be TRUE):

  1. `102-AUDIT.md` exists with KEEP/TIGHTEN/REWORK verdicts scoring the shipped logo lockup against brand-book §14's wordmark-first recommendation and the maintainer's icon-left rejection — palette/voice/copy are not re-litigated.
  2. `102-AUDIT.md` includes an honest assessment of `brandbook/index.html` presentation quality against "stands on its own, professional" — each section rated, improvement areas listed for Phase 106.
  3. `scripts/gen_glyph_paths.py` exists and accepts any pinned OFL font TTF (fetched via curl subprocess, not urllib), `--weight`/tracking params, and emits one `<path>` per glyph with per-glyph transforms so individual letterforms are independently editable.
  4. A studio HTML template and headless-Chrome screenshot helper exist (in the phase dir) that can render a candidate sheet to PNG, following the Phase 97 `logo-studio.html` precedent — confirmed by producing at least one test render.
  5. `102-RESEARCH.md` records pinned gstatic URLs for the font shortlist (Sora incumbent + 2–3 OFL alternates: Space Grotesk, Archivo, IBM Plex Sans) and confirms SIL OFL 1.1 licensing permits glyph-outlining in artwork.

**Plans**: 2 plans
Plans:
- [ ] 102-01-PLAN.md — Generalized glyph→path pipeline (gen_glyph_paths.py) + studio HTML + render helper + test render (LOGO-06)
- [ ] 102-02-PLAN.md — Logo delta audit + HTML brand book presentation audit (BRD-06)

### Phase 103: Logo Tournament

**Goal**: The maintainer has selected a winning integrated lockup through a rendered, human-gated tournament; the winner spec is frozen and executable so Phase 104 can build the family without ambiguity.
**Depends on**: Phase 102 (generalized glyph→path pipeline + render harness ready; delta audit informs candidate directions)
**Requirements**: LOGO-07, LOGO-08
**Human checkpoints**: Every round ends in an `autonomous: false` checkpoint:decision — the maintainer picks keep/cut with per-candidate feedback before the next round plan is authored. Outcome is `ITERATE` (next round) or `WINNER` (terminal, freezes `103-WINNER.md`). The winner checkpoint is mandatory and cannot be auto-decided.
**Success Criteria** (what must be TRUE):

  1. `103-TOURNAMENT.md` exists as a persistent bracket log with every candidate's ID, axis, round, status (keep/cut), and verbatim maintainer feedback — structured to survive context resets and prevent re-presenting eliminated directions.
  2. Every rendered candidate in every round satisfies the candidate guarantee: a fully-integrated custom typemark is present, zero icon-left-of-plain-text compositions exist, zero rectangular container backgrounds appear behind the mark, and the primary lockup carries no tagline.
  3. The candidate pool covered all four axes at least once: (A) evolved incumbent with decision-branch fused into type; (B) abstract mark interlocked/overlapping the logotype; (C) pure custom typemarks (motif worked into letterforms); (D) alternative-font/structural treatments in OFL alternates.
  4. `103-WINNER.md` is a complete, executable winner spec: exact geometry/viewBox, colors (with explicit deviation note if they differ from the frozen palette), font/weight, glyph modifications, mark-derivation spec, and tagline-secondary variant spec.
  5. The tournament ran at most 5 full rounds before a winner was frozen, OR a documented consolidation checkpoint was held when the soft cap was reached, naming what quality was still missing.

**Plans**: TBD (one plan per round, authored rolling)

### Phase 104: Winner Lockup Family + Brand Source Reconciliation

**Goal**: The winner identity is a complete, SVGO-optimized, accessible lockup family within SVG budgets, and all brand sources (brand-book §14, tokens, specimens) are reconciled to it — all token drift guards pass end-to-end.
**Depends on**: Phase 103 (frozen winner spec in `103-WINNER.md`)
**Requirements**: LOGO-09, LOGO-10
**Success Criteria** (what must be TRUE):

  1. The full lockup family exists in `brandbook/assets/logo/` using the existing filenames: `rs-wordmark.svg`, `rs-wordmark-tagline.svg` (new), `rs-wordmark-dark.svg`, `rs-mark.svg`, `rs-mark-dark.svg`, `rs-mark-mono.svg`, `rs-favicon.svg`, `rs-social-card.svg` (1200×630) — all SVGO-optimized via `brandbook/assets/logo/svgo.config.mjs`, zero `<text>` elements (glyphs outlined to paths), zero `base64`, `role="img"`/`title`/`desc` present, ≤20 KB each.
  2. `rs-favicon.svg` is confirmed legible in an actual Chrome tab at 16px (not zoomed SVG view) — visual evidence captured and noted in the phase verification.
  3. `brandbook/brand-book.md` §14 is rewritten as the shipped logo system: construction, clear space, minimum sizes, variant usage, and do/don'ts (including "never recreate as icon + plain system text").
  4. If the winner changed fonts or colors: `tokens.json`, `tokens.css`, admin CSS expectations, Google Fonts css2 URLs in generator + demo `root.html.heex`, and brand-book §13 are all updated in one wave; `python3 scripts/check_tokens_css.py`, `python3 scripts/check_brand_tokens.py`, and `python3 scripts/check_synced_pair.py` all exit 0.
  5. `bash scripts/ci/lint.sh` exits 0 with `SVG SIZE BUDGET OK` and `BRAND TOKENS SYNCED` after all lockup files and brand-source updates are committed.

**Plans**: TBD

### Phase 105: Propagation — Admin Shell + Demo

**Goal**: Every rendered surface carries the new identity — the admin shell wordmark is the tournament winner, demo logo/favicon match, digest is regenerated, and both admin LiveView and demo Playwright e2e suites pass.
**Depends on**: Phase 104 (complete lockup family committed; brand sources reconciled; all guards green)
**Requirements**: LOGO-11
**Conflict flag**: The parked polish branch (`fix/admin-ui-polish-attention-rail-search`) has WIP touching `shell.ex`, `rulestead_admin.css`, demo `root.html.heex`, and `favicon.ico` + untracked `favicon.svg`. **Before executing Phase 105, surface merge order to the maintainer** — land the polish branch first vs. resolve conflicts during Phase 105 execution. This is a mandatory human decision; Phase 105 must not proceed without it.
**Success Criteria** (what must be TRUE):

  1. `rulestead_admin/lib/rulestead_admin/components/shell.ex` `brand_wordmark/1` renders the new winner lockup SVG inline; `--logo-*` theme vars are defined and used across all three theme cascade blocks in `rulestead_admin/priv/static/css/rulestead_admin.css`; `.rs-shell__wordmark` sizing is updated to the winner's aspect ratio.
  2. Admin static marks (`rulestead_admin/priv/static/images/rs-mark*.svg`) reflect the new lockup family; any design-system or theme-control fixture files that embed the wordmark are updated.
  3. Demo logo (`examples/demo/backend/priv/static/images/logo.svg`) and favicon (`favicon.svg`/`favicon.ico`) are replaced with the new identity; `mix phx.digest.clean --all && mix phx.digest` has been run, new fingerprints are in place; `root.html.heex` is updated if font links changed.
  4. Admin LiveView test suite passes (`mix test` in `rulestead_admin/`).
  5. Demo Playwright e2e suite passes; screenshot evidence of the admin wordmark at 36px header size in both light and dark themes is captured.

**Plans**: TBD
**UI hint**: yes

### Phase 106: HTML Brand Book Elevation + Milestone Close

**Goal**: `brandbook/index.html` is a designed, self-contained artifact that stands on its own — still generator-emitted with no second source of truth — and v1.15 closes with all guards green, file:// browser evidence committed, and planning files updated to shipped.
**Depends on**: Phase 105 (new identity propagated everywhere; all prior guards green)
**Requirements**: BOOK-03, BOOK-04
**Success Criteria** (what must be TRUE):

  1. `brandbook/index.html` has a full-bleed cover/hero with the new lockup + brand mantra (Basalt on Stone Mist), sticky scrollspy sidebar navigation (IntersectionObserver with CSS `:target` no-JS fallback), editorial typography with Sora display section numbering and pull-quotes, and live token swatch cards generated from `tokens.json` (hex, semantic role, AA badge) — still emitted by the committed `scripts/gen_brandbook_html.py` generator with no hand-authored second source.
  2. `brandbook/index.html` has a designed logo plate section (family on light/dark tiles, clear-space diagram, do/don't pairs) and a print stylesheet.
  3. `python3 scripts/check_brandbook_html.py` exits 0 (drift check passes, size within budget — budget may be raised to 384 KB only if needed, with `BUDGET.md` updated in the same change); `bash scripts/ci/lint.sh` exits 0 with `BRANDBOOK HTML SYNCED`, `BRAND TOKENS SYNCED`, `TOKENS.CSS MIRROR SYNCED`, and `SVG SIZE BUDGET OK`.
  4. Extended `file://` browser e2e evidence is committed in `examples/demo/frontend/tests/brandbook.spec.ts`: cover renders, scrollspy nav works, token swatches display hex/role/AA badge, logo plates visible in both light and dark, print preview triggers without error.
  5. `.planning/PROJECT.md`, `STATE.md`, `MILESTONES.md`, and `REQUIREMENTS.md` are updated to v1.15 shipped; the milestone archive ceremony is complete (v1.15 phases archived to `.planning/milestones/v1.15-phases/`).

**Plans**: TBD
**UI hint**: yes

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 102. Logo Delta Audit + Tournament Studio | 0/2 | Not started | - |
| 103. Logo Tournament | 0/TBD | Not started | - |
| 104. Winner Lockup Family + Brand Source Reconciliation | 0/TBD | Not started | - |
| 105. Propagation — Admin Shell + Demo | 0/TBD | Not started | - |
| 106. HTML Brand Book Elevation + Milestone Close | 0/TBD | Not started | - |

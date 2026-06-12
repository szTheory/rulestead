# Requirements: Rulestead — v1.15 Identity Tournament

**Defined:** 2026-06-11
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Milestone goal:** Replace the icon-left-of-text lockup with a unified, integrated logo identity selected by the maintainer through an iterative rendered-options tournament, propagate it to every rendered surface, and elevate `brandbook/index.html` into a designed artifact that stands on its own. Palette/voice/copy stay frozen; fonts/colors may change only if the winning design demands it. No new runtime APIs. Phases 102–106.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Brand Audit & Strategy (BRD)

- [x] **BRD-06**: Maintainer has a written pressure-test **delta** audit of the shipped logo lockup (scored against brand-book §14's own wordmark-first recommendation and the maintainer's rejection of icon-left layouts) and of the HTML brand book's presentation quality — scoped so palette/voice/copy are not re-litigated.

### Logo & Mark System (LOGO)

- [x] **LOGO-06**: Tournament infrastructure exists: a generalized glyph→path pipeline (`scripts/gen_glyph_paths.py`: any pinned OFL font via curl fetch, per-glyph editable `<path>` output, weight/tracking params) plus a reproducible studio→PNG render harness (headless Chrome).
- [x] **LOGO-07**: Maintainer selects a winning lockup through a round-based tournament: every round is rendered (light/dark/mono, in-context sizes), gated by a maintainer keep/cut checkpoint with per-candidate feedback, logged in a persistent bracket (`103-TOURNAMENT.md`), and the winner is frozen as an executable spec (`103-WINNER.md`).
- [x] **LOGO-08**: Every tournament round honors the candidate guarantee: fully-integrated custom typemarks are always present; zero icon-left-of-plain-text compositions; zero rectangular container backgrounds behind the mark; primary lockups carry no tagline.
- [x] **LOGO-09**: The winner ships as a complete family — primary lockup (no tagline), tagline secondary, derived mark/sigil, monochrome, dark/light variants, 16px-legible favicon, 1200×630 social card — SVGO-optimized, accessible (`title`/`desc`), within the 20KB logo budgets.
- [x] **LOGO-10**: Brand sources are reconciled to the winner: `brand-book.md` §14 rewritten as the shipped logo system (construction, clear space, minimum sizes, usage/misuse); tokens.json/tokens.css and affected specimens updated if the winner changed fonts/colors; all token drift guards pass.
- [x] **LOGO-11**: The new identity is propagated to every rendered surface: admin shell wordmark + `--logo-*` theme vars (all cascade blocks), admin static marks, demo logo + favicon (with digest regen); admin LiveView and demo e2e suites pass.

### HTML Brand Book (BOOK)

- [x] **BOOK-03**: `brandbook/index.html` is a designed, self-contained artifact — cover/hero with the new lockup, sticky scrollspy navigation, editorial typography, live token swatch cards (hex, role, AA badge), designed logo plates, print stylesheet — still emitted by the committed generator with no second source of truth.
- [x] **BOOK-04**: The elevated brand book passes the drift check, stays within the documented size budget (raised only if needed, with `BUDGET.md` + guard updated in the same change), and is verified by extended `file://` browser e2e; v1.15 closes with a full guard sweep.

## v2 Requirements

Deferred to future milestones. Tracked but not in this roadmap.

### Theme (THM)

- **THM-07**: Per-host branding token overrides (trigger: host-supplied palette) — already a deferred v2 wedge.

### Accessibility (A11Y)

- **A11Y-04**: Forced-colors / high-contrast mode (trigger: beyond AA light+dark) — already a deferred v2 wedge.

### Brand (BRD)

- **BRD-04**: Full custom icon library beyond the logo/mark set (trigger: sustained UI icon demand) — anti-feature for now per research.
- **BRD-05**: Standalone marketing/docs website build (trigger: adoption justifies a dedicated site) — copy blocks ship now, the site does not.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Palette / voice / copy rework | v1.14 pressure-tested and shipped these; re-litigating them is thrash. Only the logo system and the HTML book's presentation are in play. |
| Font/color changes independent of the winner | Fonts/colors move **only** if the tournament-winning design demands it, recorded as an explicit deviation in `103-WINNER.md`. |
| Hand-authored `index.html` | The drift guard re-renders via `render_brandbook()`; the professional redesign lives in the generator's chrome layer — no second source of truth. |
| Auto-deciding the logo | The maintainer picks winners each round; checkpoints are mandatory, never skipped. |
| Mascot / character / literal flags / phoenix / shields / hexagons | Standing brand-book constraints (§14, §17). |
| New product runtime APIs | Brand/UX-quality milestone; the sibling-package product shape does not widen. |
| Committed font binaries | BUDGET.md policy stands; glyphs are outlined to paths in artwork (OFL-permitted), TTFs stay in temp dirs. |
| Binary PDF brand book | Print stylesheet + browser print-to-PDF covers the need without committing a binary. |

## Traceability

Which phases cover which requirements. Filled during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRD-06 | Phase 102 | Complete |
| LOGO-06 | Phase 102 | Complete |
| LOGO-07 | Phase 103 | Complete |
| LOGO-08 | Phase 103 | Complete |
| LOGO-09 | Phase 104 | Complete |
| LOGO-10 | Phase 104 | Complete |
| LOGO-11 | Phase 105 | Complete |
| BOOK-03 | Phase 106 | Complete |
| BOOK-04 | Phase 106 | Complete |

# Phase 106: html-brand-book-elevation - Context
**Gathered:** 2026-06-12 · **Status:** Ready · Requirements: BOOK-03, BOOK-04 · CAPSTONE (closes v1.15 after maintainer sign-off)

<domain>
Redesign the GENERATOR's chrome layer (scripts/gen_brandbook_html.py) so brandbook/index.html is a designed, self-contained artifact. NEVER hand-edit index.html (drift check re-renders via render_brandbook()). Close the six 102-AUDIT Section-3 gaps. Then guard sweep + e2e + maintainer sign-off + milestone close.
</domain>

<decisions>
- D-01 Cover/hero: full-bleed Basalt #0F1720 field, hero-scale winner lockup (dark variant), brand mantra "Rulestead makes change feel governed, not chaotic." as Sora display text, tagline + version/date; first viewport is a brand statement.
- D-02 Sticky scrollspy nav: sidebar rail (sticky) with numbered section links, IntersectionObserver active-state (extend the single existing inline script), CSS-only graceful degradation, reading sensible on narrow viewports.
- D-03 Editorial typography: Sora display section numerals (01–09), elevated pull-quote treatment, disciplined measure/rhythm.
- D-04 Token swatches: generated from tokens.json — hex + semantic role + AA/AAA badge computed at generation time (stdlib contrast math; mirror check_contrast patterns if available) for token-defined text/bg pairs; primitive↔semantic mapping shown.
- D-05 Logo plates: full 8-file family rendered inline on light (#f4f6f8) and dark (#10161f) tiles with captions; clear-space diagram (dashed 1-cap-height exclusion); do/don't pairs (correct vs container-rect vs icon-left recomposition vs tagline-in-primary).
- D-06 Print stylesheet: @media print — hide nav/theme-control/source-refs, force light bg + dark text, page-breaks before sections, hex labels prominent.
- D-07 Guard invariants preserved: no script src / img src / base64 / <image> / foreignObject; REQUIRED_SECTION_IDS unchanged; theme system stays scoped ([data-rulestead-brandbook]); page usable without JS.
- D-08 Budget: target ≤262,144 bytes. If genuinely needed, raise HTML_BUDGET_BYTES to 393,216 AND BUDGET.md in the SAME commit with one-line justification. SVG budgets untouched.
- D-09 Verification: check_brandbook_html.py + full lint.sh green; demo frontend brandbook e2e spec updated/extended for new chrome (nav/scrollspy/cover) and passing; file:// render evidence light+dark viewed.
- D-10 Milestone close happens ONLY after maintainer reviews the elevated book (human checkpoint).
</decisions>
<canonical_refs>
- 102-AUDIT.md Section 3 (the six-gap table — the contract), 104-02-SUMMARY.md
- scripts/gen_brandbook_html.py, scripts/check_brandbook_html.py, brandbook/BUDGET.md
- brandbook/tokens.json, brandbook/assets/logo/* (8 files), brand-book.md §26-27 (mantra)
- examples/demo/frontend/tests/brandbook.spec.ts (existing 6-test e2e)
</canonical_refs>

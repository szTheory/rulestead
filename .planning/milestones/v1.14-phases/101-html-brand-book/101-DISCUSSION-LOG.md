# Phase 101: html-brand-book - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-05
**Phase:** 101-html-brand-book
**Mode:** assumptions
**Areas analyzed:** Generator and Source Truth, Asset Rendering, Drift Check and CI, Page UX, Theme Scope, Milestone Close

## Methodology Applied

The project-level Recommendation-First, Research-Then-Recommend, and Architect-Default
Discuss lenses were applied. The remaining choices were routine implementation-shape
decisions backed by repo evidence, so the assumptions were presented as a cohesive
recommendation set rather than a long questionnaire.

## Assumptions Presented

### Generator and Source Truth

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use a stdlib Python generator, `scripts/gen_brandbook_html.py`, to emit `brandbook/index.html` from canonical repo sources; no React/Vite/Node/frontend stack. | Confident | `.planning/ROADMAP.md`; `.planning/phases/101-html-brand-book/101-UI-SPEC.md`; `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/ci/lint.sh` |

### Asset Rendering

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Inline/embed committed SVG logo/specimen content for previews while also showing source-file references. | Likely | Phase 101 no-broken-assets criterion; `brandbook/assets/logo/*.svg`; `brandbook/assets/specimens/*.svg`; `brandbook/BUDGET.md` |

### Drift Check and CI

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add a dedicated generated-HTML drift check, likely `scripts/check_brandbook_html.py`, and wire it into `scripts/ci/lint.sh` beside existing brand guards. | Confident | `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/check_synced_pair.py`; `scripts/ci/lint.sh` |

### Page UX

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Follow the approved UI spec: first viewport is the usable brand book, with wordmark/mark, tagline, theme state, section navigation, and the required source-driven section order. | Confident | `.planning/phases/101-html-brand-book/101-UI-SPEC.md`; `brandbook/brand-book.md`; `brandbook/VOICE.md`; `brandbook/COPY.md` |

### Theme Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Implement System / Light / Dark only inside a brand-book wrapper such as `[data-rulestead-brandbook]`; do not put color tokens on `:root`, `html`, or `body`; use a brand-book-specific localStorage key if persistence is used. | Confident | `.planning/phases/101-html-brand-book/101-UI-SPEC.md`; `rulestead_admin/lib/rulestead_admin/components/shell.ex`; `rulestead_admin/priv/static/css/rulestead_admin.css`; `brandbook/tokens.css` |

### Milestone Close

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 101 closes v1.14 only after HTML, generator, drift check, lint gate, and PROJECT/STATE shipped updates are complete; no runtime API or package-release shape changes. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `AGENTS.md` project constraints |

## Corrections Made

No corrections — all assumptions confirmed by user choice `1` ("Yes, proceed").

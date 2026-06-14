# Phase 115: Foundations Hardening - Research

**Date:** 2026-06-14
**Mode:** inline plan-phase research
**Status:** complete

## Research Goal

Answer: what must be known to plan Phase 115 well?

Phase 115 is not a redesign. It is a foundation-hardening pass over the existing mounted admin design system. The useful research is therefore source-of-truth alignment, not external ecosystem selection.

## Findings

### 1. Breakpoints need an exception ledger, not a blanket rewrite

`rulestead_admin/priv/static/css/rulestead_admin.css` documents four canonical breakpoints:

| Token | Value | Meaning |
|-------|-------|---------|
| `--bp-sm` | `40rem` / 640px | large phone / small tablet |
| `--bp-md` | `48rem` / 768px | tablet |
| `--bp-lg` | `60rem` / 960px | small desktop |
| `--bp-xl` | `75rem` / 1200px | shell max |

Current CSS still contains selector-specific pixel thresholds such as `700px`, `720px`, `760px`, `860px`, `900px`, `920px`, `960px`, and `1040px`. Some are probably safe to migrate, but others are content-specific thresholds for dense page layouts. FND-01 allows explicit exceptions, so the safest plan is:

- Add a foundation contract artifact that records the canonical set and every noncanonical threshold.
- Add a guard script that fails if new media thresholds appear without being listed in the contract.
- Migrate obvious values only during execution when the executor can verify route/matrix behavior.

### 2. Scalar tokens and brand docs already provide the correct target state

`brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/brand-book.md`, and the admin CSS header already define:

- typography families and role scale
- 4px spacing scale
- radius scale
- low-contrast shadow/elevation set
- focus-ring structure
- motion durations/easings
- scoped theme-token boundary

Phase 115 should align documentation and guard behavior with these existing values. It should not change the palette, typography family, logo system, or token source hierarchy.

### 3. Focus has a standard plus known exceptions

The standard focus treatment is `.rs-shell :where(...):focus-visible { box-shadow: var(--rs-focus-ring); }`. Local overrides exist for inputs, theme control, subnav, omnisearch, environment cards, task links, command palette input, and shell brand/search controls.

The command-palette text input intentionally suppresses the ring because the modal context and selected options carry the affordance. That exception should be documented; other suppressions should either use the ring or name their visible alternative.

### 4. Reduced motion needs a defensive floor

The CSS already gates staged animation blocks behind `prefers-reduced-motion: no-preference`, but transforms also exist outside that block for active/pressed states. FND-04 is specifically about scale, translate, blur, and staged motion for reduced-motion users. A narrow reduced-motion media block can set transition durations to zero and neutralize nonessential transforms without redesigning interaction states.

### 5. Dense table and technical-row proof should use the Phase 114 matrix

Phase 114 already exposed a real overflow bug in mobile matrix evidence: long raw JSON, mutation-confirm rows, and dense technical content created page-level horizontal overflow. The fix added containment around cards, raw detail, diff cards, timeline items, and dense tables.

Phase 115 should keep the matrix as the primary proof target and add more explicit assertions for:

- no page-level overflow at mobile width
- local scrolling for raw JSON/code
- reduced-motion behavior remains stable
- focus affordances are visible or documented

## Validation Architecture

### Automated proof layers

| Layer | Purpose | Commands |
|-------|---------|----------|
| Source guard | Enforce documented breakpoints, focus exception markers, reduced-motion block, and foundation contract sync | `python3 scripts/check_admin_foundations.py` |
| Existing guard chain | Preserve token, contrast, logo, synced-pair, brandbook, and SVG budget truth | `bash scripts/ci/lint.sh` |
| Phoenix smoke | Ensure UI matrix route and fixture source still render | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| Browser matrix | Prove overflow, focus/keyboard, theme, viewport, and reduced-motion behavior | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` |
| Static fixtures | Preserve low-level theme/token/focus fixture coverage | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` |

### Planning implication

Plans should include a Wave 1 contract/guard task before CSS changes. CSS changes can then be verified against the guard and matrix evidence instead of relying on visual judgment alone.

## Research Complete

Phase 115 can be planned with three waves:

1. Foundation contract and source guard.
2. Targeted admin CSS hardening.
3. Matrix/static-fixture evidence and planning traceability.

No external research is required.

## RESEARCH COMPLETE

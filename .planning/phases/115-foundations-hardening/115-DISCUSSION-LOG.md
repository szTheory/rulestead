# Phase 115: Foundations Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-14
**Phase:** 115-foundations-hardening
**Mode:** assumptions
**Areas analyzed:** Scope and evidence shape, breakpoints and scalar foundation contract, tokens/typography/radius/shadow/emphasis rules, focus and reduced motion, dense tables and technical rows, verification posture

## Assumptions Presented

### Scope And Evidence Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 115 should harden existing foundations in `rulestead_admin.css`, static fixtures, brand/token docs, and the Phase 114 UI matrix. It should not create new product capabilities, public routes, schemas, package metadata, component libraries, Storybook tooling, pixel baselines, FleetDesk branding, or `rulestead_admin` publish prep. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-CONTEXT.md`; `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md`; `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`; `examples/demo/frontend/tests/ui-matrix.spec.ts` |

### Breakpoints And Scalar Foundation Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat the documented breakpoint set in `rulestead_admin.css` as canonical: `40rem`, `48rem`, `60rem`, `75rem`. Phase 115 should inventory every noncanonical media threshold, migrate obvious equivalents where safe, and record explicit selector-level exceptions for content-specific thresholds that remain. | Likely | `rulestead_admin/priv/static/css/rulestead_admin.css`; `prompts/rulestead-admin-ux-and-operator-ia.md`; current CSS media thresholds include canonical rem values plus legacy pixel thresholds such as `700px`, `720px`, `760px`, `860px`, `900px`, `920px`, `960px`, and `1040px` |

### Tokens, Typography, Radius, Shadow, And Emphasis Rules

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Do not redesign values. Align documentation and CSS behavior around the existing invariant tokens, brand-book shape rules, and guard chain; add a compact foundations contract or exceptions artifact if needed. Guard scripts should only expand when they catch a real repeatable drift class, not to police every scalar by default. | Likely | `brandbook/tokens.css`; `brandbook/tokens.json`; `brandbook/brand-book.md`; `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/check_contrast.py`; `scripts/check_logo_assets.py`; `scripts/ci/lint.sh`; `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-ACCEPTANCE-GATES.md` |

### Focus And Reduced Motion

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep the unified `:focus-visible` ring as the standard, but audit every override across shell controls, forms, command palette, environment/tenant controls, subnav, task links, and route-owned widgets. Any suppressed focus ring needs an explicit visible alternative or exception. Move nonessential scale/translate/staged motion behind `prefers-reduced-motion: no-preference` or neutralize it for reduced-motion users. | Confident | `rulestead_admin/priv/static/css/rulestead_admin.css`; `brandbook/brand-book.md`; `prompts/rulestead-admin-ux-and-operator-ia.md`; `rulestead_admin/lib/rulestead_admin/components/shell.ex`; `examples/demo/frontend/tests/ui-matrix.spec.ts` |

### Dense Tables And Technical Rows

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use the Phase 114 matrix route as the primary stress target for mobile overflow, long labels, raw JSON/code, audit diffs, mutation confirm rows, and dense records. Favor generic containment and local scrolling for technical content over broad semantic table-to-card rewrites in Phase 115. | Confident | `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md`; `rulestead_admin/priv/static/css/rulestead_admin.css`; `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`; `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`; `examples/demo/frontend/tests/ui-matrix.spec.ts` |

### Verification Posture

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Verification should combine source assertions, existing guard scripts, ExUnit/LiveView coverage where useful, and focused Playwright matrix checks for overflow, focus, reduced motion, and theme/viewport behavior. Screenshots remain artifacts, not baselines. | Confident | `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md`; `.planning/phases/114-repo-native-component-matrix-harness/114-CONTEXT.md`; `examples/demo/frontend/tests/ui-matrix.spec.ts`; `scripts/ci/lint.sh`; `prompts/phoenix-live-view-best-practices-deep-research.md` |

## Corrections Made

No corrections - all assumptions confirmed by the user.

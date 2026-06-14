# Phase 116: Primitive + Composite Polish - Research

## RESEARCH COMPLETE

**Date:** 2026-06-14
**Scope:** Codebase-local research for CMP-01 through CMP-05.

## Objective

Research how to plan Phase 116 so reusable admin primitives and domain composites become coherent without reopening Phase 115 foundation work or changing product behavior.

## Inputs Reviewed

- `.planning/phases/116-primitive-composite-polish/116-CONTEXT.md`
- `.planning/phases/116-primitive-composite-polish/116-UI-SPEC.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-DESIGN-SYSTEM-INVENTORY.md`
- `.planning/phases/113-design-system-inventory-ui-matrix-contract/113-UI-MATRIX-CONTRACT.md`
- `.planning/phases/114-repo-native-component-matrix-harness/114-UI-SPEC.md`
- `.planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md`
- `rulestead_admin/lib/rulestead_admin/components/*.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex`
- `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`
- `examples/demo/frontend/tests/ui-matrix.spec.ts`
- Prompt anchors for admin UX, personas/JTBD, testing, and LiveView best practices.

## Findings

### Component Surface

The reusable component layer already exists and is mostly the right abstraction boundary:

- `OperatorComponents` owns general operator primitives and should receive any broadly reusable form/detail/status/action affordances.
- `FlagComponents` owns flag-specific visual primitives such as badges, tags, stats, cards, callouts, pagination, and flag subnav.
- `ConfirmComponents.mutation_confirm/1` is the canonical governed mutation confirm shape.
- Domain composite modules already cover rollout, rule editor, audit, audience, governance, simulation, and trace surfaces.

Research conclusion: Phase 116 should polish and extend these modules rather than introduce a new component framework, a LiveComponent layer, or a separate catalog.

### Foundation Boundary

Phase 115 already established the foundation contract and guard:

- canonical breakpoints and documented exceptions
- unified focus-ring behavior
- reduced-motion floor
- radius/elevation/emphasis rules
- dense technical content containment
- `scripts/check_admin_foundations.py` in CI lint

Research conclusion: Phase 116 CSS work should be selector support for component polish only. It must not add new foundation rules, token families, breakpoints, palette values, or broad guard policy.

### Raw Markup Consolidation

The Phase 113 raw `rs-*` ledger still matches current code. Useful consolidation candidates:

- repeated `.rs-form-field`, `.rs-field-help`, and `.rs-form-actions` patterns in flag, audit, explain, and simulate forms
- blocked/unavailable copy patterns around missing host evidence, stale guardrails, denied permissions, and read-only state
- repeated action-row/button grouping for route-owned components
- mutation confirm form variants where route markup mirrors the canonical `mutation_confirm/1` shape

Likely intentional exceptions:

- flag inventory omnisearch and streamed card list, because it is URL-state and stream-heavy
- rules workspace layout shell, because it combines editor/sidebar flow and belongs to Phase 117 IA review
- kill-switch runbook layout, because it is an emergency workflow with route-owned 3am ergonomics
- broad page-flow layout changes, because Phase 117 owns IA.

Research conclusion: write a consolidation ledger during implementation and make every raw cluster either consolidated or explicitly page-owned.

### Mutation Confirm

The shared confirm component already renders scope/evidence/reason/actions, but the phase should make the disabled/unavailable/read-only/typed-confirm treatment first-class. The goal is not to change mutation semantics; it is to make confirm affordances read identically across kill switch, cleanup/archive, audience edits, rollout risky jumps, and governed execution.

Research conclusion: plan a focused mutation-confirm slice that updates `ConfirmComponents`, fixtures, component tests, and bounded call sites. Keep route-owned emergency runbook layout, but align its copy and controls to the canonical pattern.

### Domain Composite Polish

Composites are already represented in the UI matrix:

- audit timeline, raw detail, readable diff, and audit row
- rollout ladder, guardrail status, risky jump, and auto-advance
- rule editor lifecycle/action/audience/rule-card surfaces
- audience dependency and impact preview
- governance blast-radius panel
- simulate/explain trace and audience trace

Research conclusion: plan domain composite polish as an in-place pass over these modules and matrix fixtures, not as new product behavior. The main work is visual hierarchy, copy, disabled/unavailable semantics, long-value containment, and test coverage.

## Recommended Plan Shape

Use four implementation plans:

1. **Primitive contract and raw markup ledger**: add/extend canonical primitive helpers where reuse is stable, create a Phase 116 consolidation ledger, and update matrix primitive examples.
2. **Mutation confirm consistency**: make disabled/unavailable/typed-confirm variants explicit, migrate bounded stragglers, and add component/matrix tests.
3. **Domain composite polish**: tune audit/diff, rollout/guardrail, rule editor, audience, governance, and simulate/explain components in place.
4. **Evidence and requirement closeout**: extend matrix fixtures/tests and source assertions, run targeted browser/backend/static fixture checks, and prepare Phase 117 handoff notes.

This shape keeps CMP-01 through CMP-05 covered without mixing page IA work into component polish.

## Validation Architecture

### Test Infrastructure

- **Source guards:** `python3 scripts/check_admin_foundations.py`, existing lint guard chain, and source assertions against forbidden Storybook/PhoenixStorybook/pixel-baseline terms.
- **Backend/component tests:** `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`; add focused component tests under `rulestead_admin/test/rulestead_admin/components/` where primitives or confirm components gain new states.
- **Browser evidence:** `cd examples/demo/frontend && DEMO_BACKEND_URL=<test backend> npm run test:e2e -- ui-matrix.spec.ts`.
- **Static fixture regression:** `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts`.

### Required Assertions

- Matrix renders canonical primitive and composite examples across existing section IDs.
- No page-level horizontal overflow on mobile after long-label, raw-detail, mutation-confirm, and dense-table examples are visible.
- Mutation-confirm variants expose evidence, reason, typed confirmation, danger emphasis, back link, disabled/unavailable copy, and submit semantics.
- Raw `rs-*` consolidation ledger names every Phase 113 raw cluster as consolidated or intentionally page-owned.
- Component copy contains explicit success/warning/blocked/destructive/unavailable/read-only language.
- No public admin router, release/publish, schema/migration, Storybook/PhoenixStorybook, or pixel-baseline files are introduced.

### Feedback Sampling

- Run quick source/component checks after every task commit.
- Run targeted matrix backend tests after changes to UI matrix or fixtures.
- Run Playwright matrix evidence after CSS or component visual/interaction changes.
- Run the static fixture specs before phase verification to prove token/theme fixtures remain green.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Over-extracting page-specific route layouts | Require the consolidation ledger to document page-owned exceptions. |
| Reopening Phase 115 foundation decisions | Cite `115-FOUNDATIONS-CONTRACT.md` in every plan and keep CSS changes selector-scoped. |
| Weak mutation-confirm consistency | Give mutation-confirm its own plan and test matrix variants directly. |
| Browser evidence becomes too broad | Reuse `ui-matrix.spec.ts`; keep screenshots artifact-only and no pixel baselines. |
| Copy polish becomes subjective | Use source assertions for required state terms and matrix fixtures for concrete rare states. |

## No External Research Needed

The codebase, prior phase artifacts, and prompt anchors provide enough evidence. No library version compatibility or ecosystem best-practice question remains open for Phase 116 planning.

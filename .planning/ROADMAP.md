# Roadmap: v1.17 Admin Design System Stress Test

**Status:** Planned
**Defined:** 2026-06-13
**Phase range:** 113-118

## Milestone Goal

Turn the mounted admin/operator UI into a coherent, testable design system across foundations, primitives, composites, page patterns, rare states, light/dark/system modes, and responsive widths.

## Phase 113: Design-System Inventory + UI Matrix Contract

**Goal:** Define the component taxonomy, state matrix, operator jobs-to-be-done, fixture-data needs, and acceptance gates before polishing implementation.
**Requirements:** DSM-01, DSM-03
**Success Criteria:**

1. Admin foundations, primitives, composites, page patterns, and workflow states are inventoried from real `RulesteadAdmin.Components.*` and LiveView usage.
2. The UI matrix contract names required states: normal, dense, empty, loading, error, permission-denied, long-label, narrow-width, and destructive-action cases.
3. Operator lenses are explicit for build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding, and destructive actions.
4. Scope constraints are locked: no runtime API/schema changes, palette redesign, logo redraw, component framework adoption, broad pixel baselines, v2 wedges, or admin publish prep.

**Plans:** 3 plans

Plans:
- [x] 113-01-PLAN.md - Source-backed design-system inventory.
- [x] 113-02-PLAN.md - UI matrix state, evidence, operator-lens, and fixture-data contract.
- [x] 113-03-PLAN.md - Acceptance gates, requirement closeout, and state handoff.

## Phase 114: Repo-Native Component Matrix Harness

**Goal:** Build a repo-native Phoenix/Playwright matrix that renders real admin components and stress states.
**Depends on:** Phase 113
**Requirements:** DSM-02
**Success Criteria:**

1. A dev/test-only UI matrix renders actual admin components with fixed assigns instead of duplicating component markup in static fixtures.
2. The matrix covers primitives, composites, mutation flows, dense tables, timelines, rule editor, rollout panels, command palette, empty/error/denied states, and long-label examples.
3. Playwright can visit the matrix in light, dark, system-dark, desktop, mobile, and reduced-motion contexts.
4. Existing token/theme static fixtures remain available for low-level guard assertions.

## Phase 115: Foundations Hardening

**Goal:** Normalize the design foundations that every admin component depends on.
**Depends on:** Phase 114
**Requirements:** FND-01, FND-02, FND-03, FND-04, FND-05, FND-06
**Success Criteria:**

1. Breakpoint usage matches the documented responsive set or records explicit exceptions.
2. Typography, spacing, radius, motion, shadow, focus, logo, and token documentation agree with brandbook and admin CSS guard behavior.
3. Focus states are visible and consistent across shell controls, links, buttons, forms, command palette, environment/tenant controls, and task links.
4. Reduced-motion users do not receive nonessential scale, translate, blur, or staged motion effects.
5. Radius, pill usage, elevation, and emphasis rules are explicit and applied to product surfaces.
6. Dense tables and technical rows avoid horizontal page overflow at mobile widths.

## Phase 116: Primitive + Composite Polish

**Goal:** Tune the reusable admin building blocks and repeated component groups as a coherent system.
**Depends on:** Phase 115
**Requirements:** CMP-01, CMP-02, CMP-03, CMP-04, CMP-05
**Success Criteria:**

1. Primitive components are visually consistent in light, dark, and system modes: badges, buttons, forms, cards, callouts, stats, tags, pagination, detail grids, task links, and empty states.
2. Repeated raw `rs-*` markup is consolidated behind canonical components or documented as intentional.
3. Mutation-confirm flows share coherent evidence, reason, typed confirmation, danger emphasis, back-link, and disabled-state treatment.
4. Domain composites are polished as reusable groups: audit/timeline/diff, rollout/guardrail, rule editor, audience impact, governance, simulation, and explain traces.
5. Microcopy for success, warning, blocked, destructive, and unavailable states is concise, on-brand, and operator-specific.

## Phase 117: Page Flow + IA Pass

**Goal:** Validate the polished components inside full operator workflows and route clusters.
**Depends on:** Phase 116
**Requirements:** FLOW-01, FLOW-02, FLOW-03, FLOW-04
**Success Criteria:**

1. Admin route clusters are reviewed against jobs-to-be-done for build/release, explain/diagnose, review/approve, audiences, rollouts, audit, and destructive actions.
2. Page sections and component groups follow least-surprise information hierarchy for onboarding, intermediate, and advanced operator paths.
3. Keyboard flow, focus order, mobile layout, and narrow viewport behavior remain usable across primary admin route clusters.
4. Demo or fixture data exercises happy-path, error, boundary, and rare states without changing product semantics.

## Phase 118: Evidence + Idempotence Guardrails

**Goal:** Close the milestone with reusable evidence and guardrails that make future design-system passes additive rather than regressive.
**Depends on:** Phase 117
**Requirements:** VER-01, VER-02, VER-03, VER-04
**Success Criteria:**

1. Playwright screenshots cover the UI matrix and admin workflow surfaces across light, dark, system-dark, desktop, mobile, and reduced-motion cases.
2. Deterministic assertions cover horizontal overflow, focus visibility, key ARIA roles, keyboard flow, fixture load health, and selected contrast pairs.
3. Brand/token/logo/contrast/brandbook guard scripts remain green and are extended only where they prevent real design-system drift.
4. Planning docs record decisions, verification evidence, requirement completion, and intentional exceptions before milestone closeout.
5. The final evidence posture does not introduce broad pixel-baseline maintenance or external AI visual-review requirements.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 113. Design-System Inventory + UI Matrix Contract | 3/3 | Complete | 2026-06-13 |
| 114. Repo-Native Component Matrix Harness | 0/0 | Pending | - |
| 115. Foundations Hardening | 0/0 | Pending | - |
| 116. Primitive + Composite Polish | 0/0 | Pending | - |
| 117. Page Flow + IA Pass | 0/0 | Pending | - |
| 118. Evidence + Idempotence Guardrails | 0/0 | Pending | - |

## Requirement Coverage

| Requirement | Phase |
|-------------|-------|
| DSM-01, DSM-03 | 113 |
| DSM-02 | 114 |
| FND-01, FND-02, FND-03, FND-04, FND-05, FND-06 | 115 |
| CMP-01, CMP-02, CMP-03, CMP-04, CMP-05 | 116 |
| FLOW-01, FLOW-02, FLOW-03, FLOW-04 | 117 |
| VER-01, VER-02, VER-03, VER-04 | 118 |

**Coverage:** 22/22 v1.17 requirements mapped.

## Next

Start Phase 114:

`$gsd-discuss-phase 114`

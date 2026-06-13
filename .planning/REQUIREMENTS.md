# Requirements: Rulestead v1.17 Admin Design System Stress Test

**Defined:** 2026-06-13
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions -- booleans, variants, and remote config -- with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.17 Requirements

### Design-System Matrix

- [x] **DSM-01**: Maintainer can inspect a documented admin component taxonomy that separates foundations, primitives, composites, page patterns, and workflow states.
- [ ] **DSM-02**: Maintainer can open a repo-native UI matrix that renders real `RulesteadAdmin.Components.*` components with fixed assigns instead of duplicated static HEEx.
- [x] **DSM-03**: UI matrix examples cover normal, dense, empty, loading, error, permission-denied, long-label, and destructive-action states needed for design-system review.

### Foundations

- [ ] **FND-01**: Admin CSS uses the documented breakpoint set or records an explicit exception for every additional responsive threshold.
- [ ] **FND-02**: Typography, spacing, radius, motion, shadow, focus, and logo/token source-of-truth docs agree with the shipped brandbook and admin CSS guards.
- [ ] **FND-03**: Focus states remain visible and consistent across shell controls, buttons, links, form controls, command palette, environment/tenant controls, and task links.
- [ ] **FND-04**: Reduced-motion users do not receive nonessential scale, translate, blur, or staged motion effects.
- [ ] **FND-05**: Radius, pill usage, shadows, elevation, and colored emphasis follow an explicit product-surface rule rather than component-by-component drift.
- [ ] **FND-06**: Dense tables and technical rows have a responsive overflow or stacking pattern that prevents horizontal page overflow on mobile widths.

### Components and Composites

- [ ] **CMP-01**: Primitive components for badges, buttons, cards, callouts, stats, tags, pagination, detail grids, task links, forms, and empty states are visually consistent in light, dark, and system modes.
- [ ] **CMP-02**: Repeated raw `rs-*` markup is either consolidated behind canonical components or documented as an intentional exception.
- [ ] **CMP-03**: Mutation-confirm flows share a coherent interaction pattern for evidence, reason input, typed confirmation, danger emphasis, back links, and disabled states.
- [ ] **CMP-04**: Domain composites for audit/timeline/diff, rollout/guardrail, rule editor, audience impact, governance, simulation, and explain traces are polished as reusable component groups.
- [ ] **CMP-05**: Component-level microcopy is concise, on-brand, and tailored to the operator hat for success, warning, blocked, destructive, and unavailable states.

### Flow and IA

- [ ] **FLOW-01**: Admin route clusters are mapped to operator jobs-to-be-done for build/release, explain/diagnose, review/approve, audiences, rollouts, audit, and destructive actions.
- [ ] **FLOW-02**: Page sections and component groups follow least-surprise information hierarchy for onboarding, intermediate, and advanced operator paths.
- [ ] **FLOW-03**: Keyboard, focus order, mobile layout, and narrow viewport behavior remain usable across the primary admin route clusters.
- [ ] **FLOW-04**: Demo/fixture data includes enough happy-path, error, boundary, and rare-state examples to exercise the design system without changing product semantics.

### Verification

- [ ] **VER-01**: Playwright captures UI matrix and admin workflow screenshots across light, dark, system-dark, desktop, mobile, and reduced-motion cases.
- [ ] **VER-02**: Deterministic assertions cover horizontal overflow, focus visibility, key ARIA roles, keyboard flow, fixture load health, and selected contrast pairs.
- [ ] **VER-03**: Existing brand/token/logo/contrast/brandbook guard scripts remain green and are extended only where they prevent real design-system drift.
- [ ] **VER-04**: Planning docs record v1.17 decisions, verification evidence, requirement completion, and any intentional exceptions before milestone closeout.

## Future Requirements

Deferred until a later milestone or a concrete maintainer need exists.

### Design-System Documentation

- **FUT-01**: Maintainer can browse a PhoenixStorybook-powered design-system site if repo-native matrix evidence proves insufficient for maintainers or external contributors.
- **FUT-02**: Maintainer can run optional external vision-model review over screenshots if a credentialed AI visual judging workflow becomes worth the added dependency.
- **FUT-03**: Admin UI supports forced-colors/high-contrast mode beyond the current light/dark AA contrast bar.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Public runtime API changes | v1.17 is visual/design-system quality work, not a runtime capability milestone. |
| Schema or migration changes | Component polish should not alter authored-state or persistence contracts. |
| Palette redesign or logo redraw | v1.14/v1.15 established the brand system; this milestone applies and governs it. |
| Standard JavaScript Storybook | It would duplicate Phoenix LiveView markup and add drift/setup cost for this milestone. |
| Broad pixel-baseline visual regression | Screenshots plus deterministic assertions and human review fit the current evidence posture with less maintenance burden. |
| `rulestead_admin` standalone publish preparation | The linked-version sibling-package release design remains unchanged. |
| Deferred v2 feature wedges | GOV-02-ext, ROL-08, ADM-06, and related product wedges still require explicit triggers. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DSM-01 | Phase 113 | Complete |
| DSM-02 | Phase 114 | Pending |
| DSM-03 | Phase 113 | Complete |
| FND-01 | Phase 115 | Pending |
| FND-02 | Phase 115 | Pending |
| FND-03 | Phase 115 | Pending |
| FND-04 | Phase 115 | Pending |
| FND-05 | Phase 115 | Pending |
| FND-06 | Phase 115 | Pending |
| CMP-01 | Phase 116 | Pending |
| CMP-02 | Phase 116 | Pending |
| CMP-03 | Phase 116 | Pending |
| CMP-04 | Phase 116 | Pending |
| CMP-05 | Phase 116 | Pending |
| FLOW-01 | Phase 117 | Pending |
| FLOW-02 | Phase 117 | Pending |
| FLOW-03 | Phase 117 | Pending |
| FLOW-04 | Phase 117 | Pending |
| VER-01 | Phase 118 | Pending |
| VER-02 | Phase 118 | Pending |
| VER-03 | Phase 118 | Pending |
| VER-04 | Phase 118 | Pending |

**Coverage:**
- v1.17 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-06-13*
*Last updated: 2026-06-13 after Phase 113 completion*

# Phase 117 Flow IA Review

## Scope Guardrails

- FLOW-01 maps the reviewed route set to current operator jobs: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding, and destructive operator actions.
- FLOW-02 records each page-owned surface's first-glance answer, next action, and progressive-detail expectation before any route edit.
- FLOW-03 records browser proof for keyboard, focus, mobile containment, narrow viewport behavior, route order, and generated screenshot artifacts.
- FLOW-04 keeps the deterministic matrix fixture layer broad enough for happy, error, boundary, and rare examples without changing product seed semantics.
- D-01 preserves `RulesteadAdmin.Navigation` as the source of truth for the top-level model: Overview, Build & release, Explain & diagnose, and Review & approve.
- D-02 and D-03 keep audiences, rollouts, audit, destructive actions, onboarding, denied, unavailable, and rare states as lenses inside the current groups. They are not new rail groups or a role-mode switch.
- D-04, D-05, and D-06 keep this pass route-owned: inventory URL filters, rules draft/publish state, kill-switch sequencing, home attention, audience dependency placement, audit filters, explain permalinks, and simulate context remain visible in their LiveView routes.
- D-07, D-08, D-09, and D-18 define the evidence posture: deterministic assertions plus generated screenshots, no Storybook, PhoenixStorybook, checked-in pixel baselines, public route widening, schema changes, release changes, package changes, or broad seed semantics.
- D-13, D-14, and D-15 keep audit, explain, and simulate in evidence, but route edits are limited to evidence-proven hierarchy failures while preserving URL state, redaction, raw detail, fixture export, and support-safe trace copy.
- D-16 and D-17 apply external product lessons only at the concept level: important jobs stay reachable, and emergency/destructive workflows stay contextual.

## Route Cluster Map

| Cluster | Source | Included operator lenses | Phase 117 outcome |
| --- | --- | --- | --- |
| Overview | `RulesteadAdmin.Navigation.overview/3` | onboarding, happy path, attention priority, command-palette orientation | Home answers urgent work, quiet state, and grouped destination without adding a new rail model. |
| Build & release | `RulesteadAdmin.Navigation.groups/3` | inventory, rules, audiences, rollouts, destructive kill path | Authoring and release routes keep URL state, draft/publish context, dependency visibility, and guarded action sequencing route-owned. |
| Explain & diagnose | `RulesteadAdmin.Navigation.groups/3` | audit, explain, simulate, diagnostics context | Support and SRE routes expose first answers, permalink/sample context, redaction posture, and raw detail progressively. |
| Review & approve | `RulesteadAdmin.Navigation.groups/3` | change review, governance handoff, audit proof | Review work remains reachable from the existing grouped model and keeps proof commands auditable. |

## Evidence Matrix

| Operator job | Route cluster | Route / surface | Path evidence | State coverage | Finding | Action | Proof | Follow-on |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Onboard and orient | Overview | Home console attention and grouped launcher | `/admin/flags` | happy, empty, boundary, rare via matrix route examples and rare-state fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 clarified quiet-vs-missing data copy and preserved Overview as the single home entry with command-palette alignment. | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts`; `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 118 should sample overview screenshots for `flow-overview-${theme}-${viewport}.png` and command-palette reachability. |
| Find and triage flags | Build & release | Flag inventory search, filters, view tabs, count, and card stream | `/admin/flags/flags?env=staging&view=all` | happy, dense, long-key, empty, error, mobile boundary via deterministic matrix fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 added the route-owned first-answer header and preserved URL filters, view tabs, sort, pagination, and streams. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample inventory screenshots for search/filter hierarchy and no horizontal overflow. |
| Author and publish rules | Build & release | Rules workspace shell, sidebar, validation, draft/publish action hierarchy | `/admin/flags/enable-new-dashboard/rules?env=staging` | happy, validation error, missing audience, read-only, keyboard boundary via matrix rule editor fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 placed publish readiness and draft/publish actions before dense audience/sidebar detail while preserving draft/publish semantics. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rules_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample rules screenshots for readiness before dense detail and mobile action reachability. |
| Stop unsafe serving | Build & release | Kill-switch runbook, typed confirmation, reason, diagnostics, audit handoff | `/admin/flags/enable-new-dashboard/kill?env=staging` | destructive, permission-denied, unavailable, read-only, error, boundary via mutation-confirm and rare-state fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 sequenced current state, emergency evidence, destructive form, and after-action context without weakening confirmation, diagnostics, or audit links. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/kill_test.exs test/rulestead_admin/live/flag_live/accessibility_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample kill screenshots and keyboard flow because this is the destructive route. |
| Review audience reach | Build & release | Audience inventory and dependency placement | `/admin/flags/audiences?env=staging` | happy, dense, hidden dependency, denied dependency, empty, mobile boundary via audience fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-03 added a route summary, partial-dependency warning, next action, and canonical empty state before dense details. | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/index_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample audience screenshots for dependency warning and primary action reachability. |
| Inspect audit history | Explain & diagnose | Cross-flag audit timeline, filters, readable diff, raw detail | `/admin/flags/audit?env=staging` | dense, read-only, long reason, raw detail, error, boundary via audit fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-04 added an audit first-answer block before filters while preserving `handle_params/3`, `push_patch`, `AuditComponents.timeline_row`, `AuditComponents.diff_card`, resource links, and `redacted_metadata/1`. | `cd rulestead_admin && mix test test/rulestead_admin/live/audit_live/index_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample audit screenshots for first answer, redacted raw detail, and resource navigation. |
| Explain a decision | Explain & diagnose | Support-safe explain form, permalink state, trace, redaction, sample context | `/admin/flags/enable-new-dashboard/explain?env=staging&targeting_key=support-user-42&tenant_key=acme` | happy, missing host evidence, redacted detail, long-key, error, boundary via simulate/trace fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-04 moved the summary and explanation before the lookup form while preserving permalink query handling, `push_patch`, `maybe_run_explain/3`, and the rule that traits are never stored in URLs. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/explain_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample explain screenshots for answer-before-form hierarchy and support-safe trace disclosure. |
| Simulate before changing | Explain & diagnose | Simulation playground, actor/sample input, aggregate and trace outputs | `/admin/flags/enable-new-dashboard/simulate?env=staging` | happy, loading, unavailable, error, long JSON, boundary via simulate fixtures; desktop/mobile/theme route screenshots | fixed | Plan 117-04 moved the decision summary or empty first-answer before the context builder while preserving archetype fixtures, `parse_traits/1`, `build_context/2`, redacted context assignment, fixture export, and summary-first output. | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_test.exs test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` | Phase 118 should sample simulate screenshots for first answer, visible metadata redaction, fixture export, and trace disclosure. |

## Fixture Coverage

- `UiMatrixFixtures.route_examples/0` is the Phase 117 fixture seam for route-flow links. It covers overview, inventory, rules, kill switch, audiences, audit, explain, and simulate.
- `UiMatrixFixtures.rare_state_examples/0` covers empty, permission-denied, read-only, unavailable, destructive, loading, and error states.
- Fixture examples remain synthetic and deterministic. They do not read the database, cache, filesystem, network, host environment, product seeds, or release metadata.
- Route examples prove FLOW-04 coverage only. They do not add routes to `RulesteadAdmin.Router.rulestead_admin/2` or the demo router.

## Requirement Coverage

| Requirement | Final coverage | Proof file | Command |
| --- | --- | --- | --- |
| FLOW-01 | Evidence Matrix maps current grouped navigation to build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding, and destructive operator work. | `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md`; `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | `rg -n "FLOW-01|overview|inventory|rules|kill|audience|audit|explain|simulate" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` |
| FLOW-02 | Route-owned first-answer, next-action, and progressive-detail hierarchy is fixed for priority pages and audit/explain/simulate evidence-triggered rows. | `rulestead_admin/lib/rulestead_admin/live/*`; `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | `cd rulestead_admin && mix test test/rulestead_admin/live/audit_live/index_test.exs test/rulestead_admin/live/flag_live/explain_test.exs test/rulestead_admin/live/flag_live/simulate_test.exs test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs` |
| FLOW-03 | Playwright route evidence covers desktop/mobile, light/dark/system-dark, no horizontal overflow, command palette, keyboard/focus, and route order. | `examples/demo/frontend/tests/admin-flow-ia.spec.ts` | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts` |
| FLOW-04 | Deterministic UI matrix fixtures cover route examples plus happy, error, boundary, and rare states without seed or route expansion. | `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex`; `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |

## Decision Coverage

| Decision | Status | Coverage |
| --- | --- | --- |
| D-01 | covered | Top-level navigation remains `RulesteadAdmin.Navigation` with Overview, Build & release, Explain & diagnose, and Review & approve. |
| D-02 | covered | Audiences, rollouts, audit, destructive actions, onboarding, denied, unavailable, and rare states are documented and tested as lenses inside current groups. |
| D-03 | covered | No flat entity rail, role/mode-based navigation, top-level Rulesets, Settings, Audit, Rollouts, or destructive group was added. |
| D-04 | covered | All fixes stayed in route-owned LiveView modules and focused tests. |
| D-05 | covered | Phase 116 handoff surfaces were reviewed: inventory, rules, kill switch, home, and audiences. |
| D-06 | covered | URL filters, streams, draft state, redaction, and emergency sequencing stayed visible in route modules. |
| D-07 | covered | Evidence combines UI matrix fixtures with real mounted-admin route Playwright checks. |
| D-08 | covered | Screenshots are generated artifacts only through `testInfo.outputPath`; no checked-in baselines were added. |
| D-09 | covered | No broad seed semantics, public routes, schemas, migrations, release workflow, Storybook, PhoenixStorybook, or pixel baselines were introduced. |
| D-10 | covered | Playwright covers route keyboard/focus, command palette, destructive-flow sequencing, and narrow viewport containment. |
| D-11 | source guard | No foundation, breakpoint, token, focus-ring, radius/elevation, or reduced-motion rewrite was needed. |
| D-12 | covered | Route fixes use semantic LiveView/HEEx links, buttons, forms, `handle_params/3`, and `push_patch`; no new DOM JavaScript was added. |
| D-13 | covered | Audit, explain, and simulate are included in route evidence and final matrix rows. |
| D-14 | covered | Audit, explain, and simulate were edited only after evidence rows remained gaps and the browser/ExUnit assertions proved hierarchy failures. |
| D-15 | covered | Audit/explain/simulate URL state, redaction boundaries, fixture export, raw detail, and support-safe trace copy remain route-owned. |
| D-16 | covered | External-product lessons remain conceptual: route jobs stay reachable without standalone-console rail sprawl. |
| D-17 | covered | Kill switch remains contextual with evidence, reason, typed confirmation, diagnostics/audit links, and after-action handoff. |
| D-18 | covered | ExUnit/source assertions prove contracts; Playwright proves browser-only behavior, screenshots, no overflow, and route sequencing. |

## Phase 118 Handoff

- Route coverage for Phase 118 sampling: overview, inventory, rules, kill, audience, audit, explain, and simulate.
- Screenshot artifact naming pattern: `flow-${route}-${theme}-${viewport}.png`, where route is one of `overview`, `inventory`, `rules`, `kill`, `audience`, `audit`, `explain`, or `simulate`; theme is `light`, `dark`, or `system-dark`; viewport is `desktop` or `mobile`.
- Commands run during Phase 117 closeout:
  - `cd rulestead_admin && mix test test/rulestead_admin/live/audit_live/index_test.exs test/rulestead_admin/live/flag_live/explain_test.exs test/rulestead_admin/live/flag_live/simulate_test.exs test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs`
  - `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4061 npm run test:e2e -- admin-flow-ia.spec.ts`
  - `rg -n "FLOW-01|FLOW-02|FLOW-03|FLOW-04|D-01|D-18|Phase 118 Handoff|admin-flow-ia.spec.ts|flow-\\$\\{route\\}|overview|inventory|rules|kill|audience|audit|explain|simulate" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md`
  - `rg -n "toHaveScreenshot|matchSnapshot|pixelmatch|visual-diff|pixel-baseline|Storybook|PhoenixStorybook" examples/demo/frontend/tests/admin-flow-ia.spec.ts && exit 1 || true`
  - `git diff --check`
- Intentional exceptions: no new public route, no schema or migration, no release workflow change, no package install, no standalone admin publish preparation, no checked-in visual baseline, no Storybook or PhoenixStorybook, no external AI visual review, no FleetDesk rebranding, no package publishing, and no product seed semantics.
- Phase 118 should sample these rows: kill for destructive keyboard/focus flow, audit for redacted raw detail and resource links, explain for answer-before-form permalink support, simulate for redacted metadata plus fixture export, and inventory/audience for mobile containment.

---

*Phase: 117-page-flow-ia-pass*
*Updated: 2026-06-14 after Plan 117-04*

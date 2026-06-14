# Phase 117 Flow IA Review

## Scope Guardrails

- FLOW-01 maps the reviewed route set to current operator jobs: build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding, and destructive operator actions.
- FLOW-02 records each page-owned surface's first-glance answer, next action, and progressive-detail expectation before any route edit.
- FLOW-04 keeps the deterministic matrix fixture layer broad enough for happy, error, boundary, and rare examples without changing product seed semantics.
- D-01 preserves `RulesteadAdmin.Navigation` as the source of truth for the top-level model: Overview, Build & release, Explain & diagnose, and Review & approve.
- D-02 and D-03 keep audiences, rollouts, audit, destructive actions, onboarding, denied, unavailable, and rare states as lenses inside the current groups. They are not new rail groups or a role-mode switch.
- D-04, D-05, and D-06 keep this pass route-owned: inventory URL filters, rules draft/publish state, kill-switch sequencing, home attention, and audience dependency placement remain visible in their LiveView routes unless later evidence proves a stable reusable pattern.
- D-07, D-08, D-09, and D-18 define the evidence posture: deterministic assertions plus generated screenshots, no Storybook, PhoenixStorybook, checked-in pixel baselines, public route widening, schema changes, release changes, package changes, or broad seed semantics.
- D-13 requires audit, explain, and simulate to appear in route-cluster evidence so explain/diagnose and audit work are not skipped.
- D-16 applies external product lessons only at the concept level: important jobs stay reachable without copying standalone-console rail sprawl.

## Route Cluster Map

| Cluster | Source | Included operator lenses | Phase 117 expectation |
| --- | --- | --- | --- |
| Overview | `RulesteadAdmin.Navigation.overview/3` | onboarding, happy path, attention priority, command-palette orientation | The home surface answers what needs attention, where to start, and which grouped destination is next. |
| Build & release | `RulesteadAdmin.Navigation.groups/3` | inventory, rules, audiences, rollouts, destructive kill path | Authoring and release routes keep URL state, draft/publish context, and guarded action sequencing route-owned. |
| Explain & diagnose | `RulesteadAdmin.Navigation.groups/3` | audit, explain, simulate, diagnostics context | Support and SRE routes expose first answer, permalink/sample context, redaction posture, and raw detail progressively. |
| Review & approve | `RulesteadAdmin.Navigation.groups/3` | change review, governance handoff, audit proof | Review work remains reachable from the existing grouped model and keeps proof commands auditable. |

## Evidence Matrix

| Operator job | Route cluster | Route / surface | Path evidence | State coverage | Finding | Action | Proof | Follow-on |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Onboard and orient | Overview | Home console attention and grouped launcher | `/admin/flags` | happy, empty, boundary, rare via matrix route examples and rare-state fixtures | none | Preserve Overview as the single home entry; record the first-glance answer and command-palette alignment. | `rg -n "Overview\|RulesteadAdmin.Navigation" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | Phase 117 Plan 02 should add browser evidence for first viewport, command palette, and narrow scan order. |
| Find and triage flags | Build & release | Flag inventory search, filters, view tabs, count, and card stream | `/admin/flags/flags?env=staging&view=all` | happy, dense, long-key, empty, error, mobile boundary via deterministic matrix fixtures | evidence gap | Add fixture route example coverage for the inventory path and keep URL/filter behavior route-owned. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Browser evidence should inspect search/filter hierarchy and no horizontal overflow. |
| Author and publish rules | Build & release | Rules workspace shell, sidebar, validation, draft/publish action hierarchy | `/admin/flags/enable-new-dashboard/rules?env=staging` | happy, validation error, missing audience, read-only, keyboard boundary via matrix rule editor fixtures | evidence gap | Add fixture route example coverage and defer route edits until browser evidence identifies an IA issue. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 117 Plan 03 should verify action hierarchy, keyboard order, and missing-audience recovery. |
| Stop unsafe serving | Build & release | Kill-switch runbook, typed confirmation, reason, diagnostics, audit handoff | `/admin/flags/enable-new-dashboard/kill?env=staging` | destructive, permission-denied, unavailable, read-only, error, boundary via mutation-confirm and rare-state fixtures | evidence gap | Add fixture route example coverage and preserve preview -> confirm -> audit sequencing. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 117 Plan 03 should verify 3am decision order and non-danger return path. |
| Review audience reach | Build & release | Audience inventory and dependency placement | `/admin/flags/audiences?env=staging` | happy, dense, hidden dependency, denied dependency, empty, mobile boundary via audience fixtures | evidence gap | Add fixture route example coverage and keep dependency evidence page-owned. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Browser evidence should inspect density, denied evidence placement, and primary action reachability. |
| Inspect audit history | Explain & diagnose | Cross-flag audit timeline, filters, readable diff, raw detail | `/admin/flags/audit?env=staging` | dense, read-only, long reason, raw detail, error, boundary via audit fixtures | evidence gap | Add fixture route example coverage and keep audit proof tied to route evidence. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 117 Plan 04 should edit audit only if evidence shows stranded rows or buried raw detail. |
| Explain a decision | Explain & diagnose | Support-safe explain form, permalink state, trace, redaction, sample context | `/admin/flags/enable-new-dashboard/explain?env=staging&targeting_key=support-user-42&tenant_key=acme` | happy, missing host evidence, redacted detail, long-key, error, boundary via simulate/trace fixtures | evidence gap | Add fixture route example coverage and leave redaction/sample semantics route-owned. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 117 Plan 04 should verify first answer, permalink fields, and support-safe copy. |
| Simulate before changing | Explain & diagnose | Simulation playground, actor/sample input, aggregate and trace outputs | `/admin/flags/enable-new-dashboard/simulate?env=staging` | happy, loading, unavailable, error, long JSON, boundary via simulate fixtures | evidence gap | Add fixture route example coverage and reserve browser proof for focus, form order, and overflow. | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | Phase 117 Plan 04 should edit simulate only if evidence shows inaccessible sample/context or raw detail. |

## Fixture Coverage

- `UiMatrixFixtures.route_examples/0` is the Phase 117 fixture seam for route-flow links. Plan 117-01 extends it to overview, inventory, rules, kill switch, audiences, audit, explain, and simulate.
- `UiMatrixFixtures.rare_state_examples/0` already covers empty, permission-denied, read-only, unavailable, destructive, loading, and error states; Plan 117-01 keeps those states asserted.
- Fixture examples remain synthetic and deterministic. They do not read the database, cache, filesystem, network, host environment, product seeds, or release metadata.
- Route examples prove FLOW-04 coverage only. They do not add routes to `RulesteadAdmin.Router.rulestead_admin/2` or the demo router.

## Requirement Coverage

| Requirement | Coverage in this artifact | Proof path |
| --- | --- | --- |
| FLOW-01 | Evidence Matrix maps current grouped navigation to build/release, explain/diagnose, review/approve, audiences, rollouts, audit, onboarding, and destructive operator work. | `117-FLOW-IA-REVIEW.md`, `RulesteadAdmin.Navigation` citation |
| FLOW-02 | Each route row names the page-owned surface, expected first-glance answer, action posture, and progressive-detail follow-on. | Evidence Matrix and Phase 118 Handoff |
| FLOW-04 | Fixture Coverage binds route examples and rare states to deterministic assertions without seed or route expansion. | `UiMatrixFixtures.route_examples/0`, `UiMatrixFixtures.rare_state_examples/0`, `ui_matrix_live_test.exs` |

## Decision Coverage

| Decision | How this plan implements it |
| --- | --- |
| D-01 | Uses `RulesteadAdmin.Navigation` as the top-level source and preserves Overview, Build & release, Explain & diagnose, and Review & approve. |
| D-02 | Records audiences, rollouts, audit, destructive actions, denied, unavailable, and rare states as lenses inside the current clusters. |
| D-03 | Keeps the review artifact from adding new top-level groups or a role-mode rail. |
| D-04 | Reviews route-owned IA surfaces before route edits. |
| D-05 | Centers the Phase 116 handoff surfaces: inventory, rules, kill switch, home, and audiences. |
| D-06 | Leaves URL filters, streams, draft state, redaction, and emergency sequencing in route modules. |
| D-07 | Combines deterministic matrix fixtures with selected mounted-route evidence. |
| D-08 | Treats screenshots as generated review artifacts, not committed baselines. |
| D-09 | Blocks seed, schema, package, release, public route, Storybook, PhoenixStorybook, and pixel-baseline expansion. |
| D-13 | Includes audit, explain, and simulate in the route evidence matrix. |
| D-16 | Uses external-console lessons only to keep important jobs reachable inside the current grouped model. |
| D-18 | Uses ExUnit/source assertions for fixture/source boundaries and reserves Playwright for browser-only behavior. |

## Phase 118 Handoff

- Phase 118 should verify this matrix against browser evidence and final guardrails instead of rediscovering the route set.
- Carry these proof commands forward:
  - `test -f .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md`
  - `rg -n "FLOW-01|FLOW-02|FLOW-04|RulesteadAdmin.Navigation" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md`
  - `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- Intentional exceptions: no new public route, no schema or migration, no release workflow change, no package install, no standalone admin publish preparation, and no checked-in visual baseline.
- Follow-on evidence should update the Finding column from `evidence gap` to `none`, `IA issue`, `fixed`, or `bounded exception` as Plans 117-02 through 117-04 gather browser proof and make route-owned fixes.

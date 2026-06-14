# Phase 118 Evidence Map

## Scope

Phase 118 records the reusable v1.17 evidence posture for VER-01 through VER-04. It covers the repo-native UI matrix, selected mounted-admin workflow routes, deterministic browser/source assertions, selected contrast/static fixture checks, and the existing brand/token/logo/contrast/brandbook/foundation guard spine.

This artifact is evidence-only. It does not add runtime APIs, schemas, migrations, package metadata, release workflow changes, FleetDesk rebranding, broad visual baselines, Storybook, PhoenixStorybook, external AI visual review, or `rulestead_admin` publish-prep work.

## Backend Command

Default backend command:

```bash
cd examples/demo/backend && MIX_ENV=test PHX_SERVER=true PORT=4061 mix phx.server
```

Browser evidence environment:

```bash
DEMO_BACKEND_PORT=4061
DEMO_BACKEND_URL=http://localhost:4061
```

If port `4061` is occupied during rerun, use the first free port from `4062` through `4069`, export both values, and update this section with the exact replacement port and URL before recording browser evidence.

## Evidence Map

| Requirement | Surface | Assertion type | Command | Artifact pattern | Status | Intentional exception | Residual risk |
| --- | --- | --- | --- | --- | --- | --- | --- |
| VER-01 | UI matrix screenshots across light, dark, system-dark, desktop, mobile, and targeted reduced motion | Playwright browser evidence; `.rs-shell`; required matrix sections; no horizontal overflow; generated artifact screenshot | `cd examples/demo/frontend && DEMO_BACKEND_URL="http://localhost:4061" npm run test:e2e -- --output=test-results/phase118-evidence ui-matrix.spec.ts admin-flow-ia.spec.ts` | `examples/demo/frontend/test-results/**/ui-matrix-overview-shell-*.png` | PASS: 70/70 combined browser tests passed; 7 `ui-matrix-overview-shell-*.png` artifacts generated under `test-results/phase118-evidence`. | Screenshots are generated artifacts, not committed baselines. No `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, Storybook, PhoenixStorybook, or external AI visual review. | Human review still inspects generated artifacts; no pixel baseline is committed. |
| VER-01 | Mounted-admin workflow screenshots for route set `overview, inventory, rules, kill, audience, audit, explain, simulate` across light, dark, system-dark, desktop, and mobile | Playwright browser evidence; route headings/evidence text; no horizontal overflow; command palette; keyboard/focus flow; generated full-page screenshots | `cd examples/demo/frontend && DEMO_BACKEND_URL="http://localhost:4061" npm run test:e2e -- --output=test-results/phase118-evidence ui-matrix.spec.ts admin-flow-ia.spec.ts` | `examples/demo/frontend/test-results/**/flow-*.png` | PASS: 70/70 combined browser tests passed; 48 `flow-*.png` artifacts generated under `test-results/phase118-evidence`. | Screenshots are generated artifacts, not committed baselines. No route additions, product seed changes, FleetDesk rebranding, release workflow changes, or `rulestead_admin` publish-prep work. | Workflow count met the expected 48 artifacts for eight routes, three themes, and two viewports. |
| VER-02 | Browser DOM and behavior assertions | Playwright deterministic assertions for overflow, focus, key ARIA roles/regions, command palette, route order, and targeted reduced-motion behavior | `cd examples/demo/frontend && DEMO_BACKEND_URL="http://localhost:4061" npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` | `examples/demo/frontend/test-results/**/ui-matrix-overview-shell-*.png`; `examples/demo/frontend/test-results/**/flow-*.png` | PASS: 70/70 combined browser tests passed. | Reduced-motion proof remains targeted instead of multiplying every route by every motion mode. | Browser suite depends on the recorded local test-mode backend. |
| VER-02 | ExUnit fixture/source assertions | Phoenix LiveViewTest assertions for matrix route sections, route examples, rare-state fixtures, real component usage, and demo-hosted route isolation | `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | None | PASS: 6 tests, 0 failures. | Source assertions prove boundaries faster than browser evidence; no public route widening. | Does not replace browser proof for media/theme/viewport behavior. |
| VER-02 | Selected contrast/static fixture assertions | Playwright static fixture checks for selected AA contrast pairs, placeholder exception lock, fixture load, wordmark/theme harnesses, and theme controls | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | None | PASS: 29/29 static fixture and theme tests passed. | Selected contrast stays in static fixture/script layers; no exhaustive runtime route-pixel contrast audit. | Route-specific visual contrast remains reviewed through generated screenshots and existing tokens. |
| VER-03 | Guard scripts | Existing guard spine plus Phase 118 design-system evidence source guard | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py && python3 scripts/check_brandbook_html.py && python3 scripts/check_logo_assets.py && python3 scripts/check_admin_foundations.py && python3 scripts/check_design_system_evidence.py`; `bash scripts/ci/lint.sh` | None | PASS: individual guard chain passed; full lint wrapper passed with `SVG SIZE BUDGET OK`. | Guard additions are deterministic source checks only; no package installs. | Full lint was practical locally and passed. |
| VER-04 | Planning closeout | Requirement, roadmap, state, and validation updates after evidence exists | Planned for Phase 118 Plan 03 | None | Pending Plan 03 | Do not mark VER-04 complete in Plan 02. | Planning truth remains pending until Plan 03 updates requirements, roadmap, state, and validation closeout. |

## Screenshot Artifact Patterns

- UI matrix: `examples/demo/frontend/test-results/**/ui-matrix-overview-shell-*.png`
- Mounted-admin workflow routes: `examples/demo/frontend/test-results/**/flow-*.png`
- Matrix source naming: `ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png`
- Workflow source naming: `flow-${route.name}-${theme.name}-${viewport.name}.png`
- Workflow route set: `overview, inventory, rules, kill, audience, audit, explain, simulate`

## Guard Output

Fast source gate before browser evidence:

| Command | Result | Status |
| --- | --- | --- |
| `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | 6 tests, 0 failures | PASS |
| `python3 scripts/check_design_system_evidence.py` | `DESIGN SYSTEM EVIDENCE OK` | PASS |
| `rg -n "testInfo\\.outputPath|ui-matrix-\\$\\{sectionName\\}|flow-\\$\\{route.name\\}|expectNoHorizontalOverflow" examples/demo/frontend/tests/ui-matrix.spec.ts examples/demo/frontend/tests/admin-flow-ia.spec.ts` | Found `testInfo.outputPath` and `expectNoHorizontalOverflow` hooks in both evidence specs | PASS |
| `rg -n -F 'ui-matrix-${sectionName}-${theme.name}-${viewport.name}-${motion.name}.png' examples/demo/frontend/tests/ui-matrix.spec.ts && rg -n -F 'flow-${route.name}-${theme.name}-${viewport.name}.png' examples/demo/frontend/tests/admin-flow-ia.spec.ts` | Found exact generated-artifact source templates at `ui-matrix.spec.ts:192` and `admin-flow-ia.spec.ts:186` | PASS |

Browser and static fixture proof:

| Command | Result | Status |
| --- | --- | --- |
| `cd examples/demo/frontend && DEMO_BACKEND_URL="http://localhost:4061" npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` | 70 passed | PASS |
| `cd examples/demo/frontend && DEMO_BACKEND_URL="http://localhost:4061" npm run test:e2e -- --output=test-results/phase118-evidence ui-matrix.spec.ts admin-flow-ia.spec.ts` | 70 passed; 7 matrix screenshots and 48 workflow screenshots preserved under ignored Playwright output | PASS |
| `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | 29 passed | PASS |

Guard chain output:

| Command | Result | Status |
| --- | --- | --- |
| `python3 scripts/check_synced_pair.py` | `SYNCED PAIR IDENTICAL (56 tokens)` and `SYNCED PAIR IDENTICAL (light: 57 tokens)` | PASS |
| `python3 scripts/check_brand_tokens.py` | `BRAND TOKENS SYNCED (68 tokens)` | PASS |
| `python3 scripts/check_tokens_css.py` | `TOKENS.CSS MIRROR SYNCED (68 tokens)` | PASS |
| `python3 scripts/check_contrast.py` | `CONTRAST CHECK PASS (19 checks)` | PASS |
| `python3 scripts/check_brandbook_html.py` | `BRANDBOOK HTML SYNCED (248542 bytes)` | PASS |
| `python3 scripts/check_logo_assets.py` | `LOGO ASSETS SYNCED (6 copies + shell markers)` | PASS |
| `python3 scripts/check_admin_foundations.py` | `ADMIN FOUNDATIONS OK` | PASS |
| `python3 scripts/check_design_system_evidence.py` | `DESIGN SYSTEM EVIDENCE OK` | PASS |
| `bash scripts/ci/lint.sh` | Passed full wrapper, including Mix format/compile/Credo/docs/audit/package whitelist/Dialyzer and all guard scripts; ended with `SVG SIZE BUDGET OK` | PASS |

## Intentional Exceptions

- Screenshots are generated artifacts, not committed baselines.
- No `toHaveScreenshot`, `matchSnapshot`, pixelmatch, visual-diff tooling, checked-in pixel-baseline maintenance, Storybook, PhoenixStorybook, or external AI visual review belongs to this phase per D-12.
- No schema, migration, runtime API, product seed semantics, public route widening, release workflow, FleetDesk rebranding, package metadata, package install, or `rulestead_admin` publish-prep work belongs to this phase per D-14, D-15, and D-16.
- VER-04 remains pending for Plan 03 per D-18; this plan records evidence before planning truth closeout.

## Residual Risks

- Browser evidence depends on a locally running test-mode Phoenix backend and the recorded `DEMO_BACKEND_URL`.
- Generated screenshot artifacts need human review after the Playwright run because this milestone intentionally avoids committed visual baselines.
- Static selected contrast proof is not an exhaustive runtime pixel audit for every route.
- VER-04 planning truth remains pending until Phase 118 Plan 03 updates `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and validation artifacts.

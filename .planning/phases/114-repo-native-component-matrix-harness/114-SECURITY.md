---
phase: 114
slug: repo-native-component-matrix-harness
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-14
---

# Phase 114 - Security

Per-phase security contract for the repo-native component matrix harness.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser -> demo Phoenix route | A browser requests `/dev/rulestead-admin/ui-matrix` through the demo backend. | Browser request/session to fixture-only LiveView HTML. |
| Demo route -> mounted admin components | Demo-host LiveView renders `RulesteadAdmin.Components.*` without adding a package route. | Synthetic assigns to component functions. |
| Synthetic fixtures -> rendered HTML | Fixed fixture data becomes visible in LiveView output and screenshots. | Synthetic long labels, route examples, and state fixtures. |
| Matrix links -> seeded admin flows | Matrix links point to existing `/admin/flags` demo routes. | Navigation links only; no policy/session changes. |
| Playwright browser -> demo backend | Browser contexts request the matrix route through `DEMO_BACKEND_URL`. | Test browser context, session cookie, and rendered HTML. |
| Browser localStorage -> admin shell theme control | Tests write `rulestead_admin.theme` for pinned theme modes. | Theme preference value only. |
| Matrix HTML -> screenshot artifacts | Rendered fixture content is captured in Playwright test output artifacts. | Test artifact screenshots with synthetic fixture content. |
| Static fixtures -> guard assertions | Existing file-based fixture specs continue to cover token/theme guards. | File existence and static HTML guard inputs. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-114-01 | Information Disclosure | `/dev/rulestead-admin/ui-matrix` route | mitigate | Route is gated by `if Mix.env() in [:dev, :test] do` and mounted under the demo router only. Evidence: `examples/demo/backend/lib/rulestead_demo_web/router.ex:45`, `examples/demo/backend/lib/rulestead_demo_web/router.ex:49`, `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:96`. | closed |
| T-114-02 | Tampering | `RulesteadAdmin.Router.rulestead_admin/2` boundary | mitigate | Matrix route lives under `examples/demo/backend`; source test asserts the package router does not contain `ui-matrix`. Evidence: `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:94`, `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:99`; current audit `rg -q 'ui-matrix' rulestead_admin/lib/rulestead_admin/router.ex` returned no match. | closed |
| T-114-03 | Information Disclosure | Fixture values and screenshots | mitigate | Fixtures are synthetic and bounded; fixture source contains no `Repo`, `System.get_env`, `File.`, `HTTP`, or network client calls. Evidence: `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:4`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:5`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:80`; current audit grep for forbidden reads returned no match. | closed |
| T-114-04 | Denial of Service | Matrix fixture size/render work | mitigate | Fixture helpers use explicit bounded lists and no metaprogrammed component discovery. Evidence: `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:127`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:300`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:323`. | closed |
| T-114-05 | Repudiation | Component source truth | mitigate | LiveView imports real admin component modules, and ExUnit asserts real component module references plus stable matrix selectors. Evidence: `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex:6`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex:15`, `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:101`, `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:114`. | closed |
| T-114-06 | Spoofing | Denied/read-only examples | mitigate | Denied, read-only, unavailable, and destructive states are labeled fixture examples; read-only matrix events keep the LiveView mounted without mutating policy/session behavior. Evidence: `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:75`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:413`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex:19`, `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs:44`. | closed |
| T-114-07 | Elevation of Privilege | Seeded admin flow links | mitigate | Matrix route links only to existing `/admin/flags` demo routes and leaves `RulesteadDemo.AdminPolicy` in the existing admin mount. Evidence: `examples/demo/backend/lib/rulestead_demo_web/router.ex:40`, `examples/demo/backend/lib/rulestead_demo_web/router.ex:42`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:112`. | closed |
| T-114-SC / 114-01 | Tampering | npm/pip/cargo installs | accept | Accepted scope-control risk: no package-manager install task exists for Plan 01; package legitimacy audit records no installs. Evidence: `.planning/phases/114-repo-native-component-matrix-harness/114-RESEARCH.md:129`, `.planning/phases/114-repo-native-component-matrix-harness/114-RESEARCH.md:142`. | closed |
| T-114-08 | Spoofing | Browser evidence target | mitigate | Playwright uses the exact matrix path and asserts `.rs-shell` plus stable matrix sections after navigation. Evidence: `examples/demo/frontend/tests/ui-matrix.spec.ts:24`, `examples/demo/frontend/tests/ui-matrix.spec.ts:112`, `examples/demo/frontend/tests/ui-matrix.spec.ts:113`, `examples/demo/frontend/tests/ui-matrix.spec.ts:140`. | closed |
| T-114-09 | Tampering | Screenshot evidence | mitigate | Screenshots are written only to `testInfo.outputPath`; source guard prevents snapshot/pixel/visual-diff tooling from entering the spec. Evidence: `examples/demo/frontend/tests/ui-matrix.spec.ts:148`, `examples/demo/frontend/tests/ui-matrix.spec.ts:152`, `examples/demo/frontend/tests/ui-matrix.spec.ts:198`; current audit `rg -q 'toHaveScreenshot|matchSnapshot|pixelmatch|visual-diff|Storybook|PhoenixStorybook' examples/demo/frontend/tests/ui-matrix.spec.ts` returned no match. | closed |
| T-114-10 | Repudiation | Evidence completeness | mitigate | Browser cases cover light/dark/system-dark, desktop/mobile, reduced motion, selectors, no-overflow, keyboard behavior, and artifact naming. Evidence: `examples/demo/frontend/tests/ui-matrix.spec.ts:26`, `examples/demo/frontend/tests/ui-matrix.spec.ts:31`, `examples/demo/frontend/tests/ui-matrix.spec.ts:42`, `examples/demo/frontend/tests/ui-matrix.spec.ts:47`, `examples/demo/frontend/tests/ui-matrix.spec.ts:118`, `examples/demo/frontend/tests/ui-matrix.spec.ts:162`. | closed |
| T-114-11 | Information Disclosure | Screenshot artifacts | mitigate | Plan 01 fixtures are synthetic; Playwright captures the matrix and static guard fixtures only. Evidence: `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:4`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:81`, `examples/demo/frontend/tests/ui-matrix.spec.ts:63`, `examples/demo/frontend/tests/ui-matrix.spec.ts:191`. | closed |
| T-114-12 | Denial of Service | Browser test runtime | mitigate | Browser coverage uses a curated case set and one keyboard path, with no broad route-flow sweep or visual-baseline matrix. Evidence: `examples/demo/frontend/tests/ui-matrix.spec.ts:78`, `examples/demo/frontend/tests/ui-matrix.spec.ts:162`, `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md:81`, `.planning/phases/114-repo-native-component-matrix-harness/114-02-SUMMARY.md:86`. | closed |
| T-114-13 | Elevation of Privilege | Demo sign-in and admin links | mitigate | Playwright uses existing `/demo/sign-in`; route examples remain under existing `/admin/flags` paths and no auth/session/policy code was changed. Evidence: `examples/demo/frontend/tests/ui-matrix.spec.ts:102`, `examples/demo/frontend/tests/ui-matrix.spec.ts:103`, `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex:112`, `examples/demo/backend/lib/rulestead_demo_web/router.ex:42`. | closed |
| T-114-SC / 114-02 | Tampering | npm/pip/cargo installs | accept | Accepted scope-control risk: Plan 02 adds no package install; `@playwright/test` is already present in demo frontend dev dependencies. Evidence: `.planning/phases/114-repo-native-component-matrix-harness/114-02-PLAN.md:197`, `examples/demo/frontend/package.json:18`, `examples/demo/frontend/package.json:19`. | closed |

Status: open or closed. Disposition: mitigate, accept, or transfer.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-114-01 | T-114-SC / 114-01 | No package-manager install task exists in Plan 01; package legitimacy audit records no installs. | Phase 114 plan disposition | 2026-06-14 |
| AR-114-02 | T-114-SC / 114-02 | No package-manager install task exists in Plan 02; Playwright dependency already exists in the demo frontend. | Phase 114 plan disposition | 2026-06-14 |

Accepted risks do not resurface in future audit runs.

---

## Unregistered Flags

None. `114-02-SUMMARY.md` reports: "None - this plan added browser tests and CSS containment only; it did not add new endpoints, auth paths, file-access behavior in production code, schemas, or network surfaces beyond the planned Playwright route access." `114-01-SUMMARY.md` has no `## Threat Flags` entries.

---

## Security Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Threats found | 15 |
| Closed | 15 |
| Open | 0 |

Current-turn verification:

| Check | Result |
|-------|--------|
| `mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` from `examples/demo/backend` | Passed: 4 tests, 0 failures. Postgres logged transient `too_many_connections` before completion. |
| `rg -q 'if Mix\.env\(\) in \[:dev, :test\] do' examples/demo/backend/lib/rulestead_demo_web/router.ex` | Passed. |
| `rg -q 'live "/ui-matrix", UiMatrixLive, :index' examples/demo/backend/lib/rulestead_demo_web/router.ex` | Passed. |
| `rg -q 'ui-matrix' rulestead_admin/lib/rulestead_admin/router.ex` | Passed as negative assertion: no match. |
| `rg -q 'toHaveScreenshot|matchSnapshot|pixelmatch|visual-diff|Storybook|PhoenixStorybook' examples/demo/frontend/tests/ui-matrix.spec.ts` | Passed as negative assertion: no match. |
| Static fixture files present | Passed for `design-system.html`, `theme-control-harness.html`, and `theme-harness.html`. |
| Fixture forbidden-read grep | Passed as negative assertion: no `Repo`, `System.get_env`, `File.`, `HTTP`, or network client calls in `ui_matrix_fixtures.ex`. |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-14 | 15 | 15 | 0 | Codex / gsd-secure-phase |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-06-14

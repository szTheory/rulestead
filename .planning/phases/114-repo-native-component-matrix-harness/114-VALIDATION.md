---
phase: 114
slug: repo-native-component-matrix-harness
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
finalized: 2026-06-14
last_audited: 2026-06-14
validated_against:
  - 114-01-PLAN.md
  - 114-02-PLAN.md
  - 114-01-SUMMARY.md
  - 114-02-SUMMARY.md
  - 114-VERIFICATION.md
---

# Phase 114 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest, Playwright Test |
| **Config file** | `examples/demo/frontend/playwright.config.ts`; Mix configs per package |
| **Quick run command** | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| **Full suite command** | `cd examples/demo/backend && mix compile`; `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts`; `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` |
| **Estimated runtime** | ~2 seconds for focused ExUnit; ~3 seconds for matrix Playwright when a demo backend is running; ~2 seconds for static fixture guards |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- **After every plan wave:** Run `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts`
- **Before `$gsd-verify-work`:** `scripts/ci/lint.sh` plus the matrix Playwright spec must be green
- **Max feedback latency:** 90 seconds for the focused loop; full lint chain may exceed this when browser evidence starts the backend

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 114-01-T1 | 114-01-PLAN.md Task 1 | 1 | DSM-02 | T-114-03, T-114-04 | Deterministic fixture helpers use synthetic bounded data and do not read databases, environment, files, or network | compile + fixture-health/source assertions | `cd examples/demo/backend && mix compile`; `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | covered |
| 114-01-T2 | 114-01-PLAN.md Task 2 | 1 | DSM-02 | T-114-01, T-114-02, T-114-07 | Matrix route is demo-hosted, dev/test gated, outside `RulesteadAdmin.Router.rulestead_admin/2`, and renders real shell/components | compile + route/source assertions | `cd examples/demo/backend && mix compile`; `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | covered |
| 114-01-T3 | 114-01-PLAN.md Task 3 | 1 | DSM-02 | T-114-01, T-114-02, T-114-03, T-114-05 | ExUnit proves route reachability, `.rs-shell`, required sections, fixture health, real component source references, read-only interactions, and no Storybook/pixel-baseline scope | ExUnit LiveView/source tests | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | covered |
| 114-02-T1 | 114-02-PLAN.md Task 1 | 2 | DSM-02 | T-114-08, T-114-09, T-114-10, T-114-11, T-114-12 | Playwright proves light/dark/system-dark, desktop/mobile, reduced-motion, section visibility, overflow, and screenshot artifacts without baselines | Playwright e2e | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts` | yes | covered |
| 114-02-T2 | 114-02-PLAN.md Task 2 | 2 | DSM-02 | T-114-10, T-114-13 | Playwright proves command palette keyboard/focus behavior and existing static token/theme fixtures remain covered | Playwright e2e + static guard regression | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts`; `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | yes | covered |

---

## Automated Coverage Files

- [x] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - covered by compile and fixture-health assertions in `ui_matrix_live_test.exs`.
- [x] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - covered by route/source assertions, read-only interaction checks, and Playwright browser evidence.
- [x] `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - covers route reachability, section selectors, fixture health, source boundaries, and read-only matrix interactions.
- [x] `examples/demo/frontend/tests/ui-matrix.spec.ts` - covers matrix browser contexts, sections, overflow, screenshot artifacts, command palette keyboard behavior, static fixture preservation, and forbidden baseline tooling.
- [x] `rulestead_admin/priv/static/design-system.html`, `theme-control-harness.html`, and `theme-harness.html` - covered by existing static fixture guard specs.

---

## Manual-Only Verifications

All Phase 114 behaviors have automated verification. Visual polish defects discovered by the matrix should be recorded for Phase 115 or Phase 116 unless they prevent the matrix from rendering.

---

## Validation Audit 2026-06-14

| Metric | Count |
|--------|-------|
| Requirements audited | 1 |
| Task rows audited | 5 |
| Gaps found | 0 |
| Resolved by new tests | 0 |
| Escalated manual-only | 0 |

| Check | Result |
|-------|--------|
| Existing validation state | State A - `114-VALIDATION.md` existed and was audited. |
| Requirement-to-task map | DSM-02 maps to all five Phase 114 tasks across `114-01-PLAN.md` and `114-02-PLAN.md`. |
| Existing tests found | `ui_matrix_live_test.exs`, `ui-matrix.spec.ts`, `design-system.spec.ts`, `theme-control.spec.ts`, `theme-cascade.spec.ts`, and `theme-scope.spec.ts`. |
| Current automated evidence | `mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` passed 4 tests; `mix compile` exited 0; `DEMO_BACKEND_URL=http://localhost:4003 npm run test:e2e -- ui-matrix.spec.ts` passed 10 tests; static fixture Playwright guard suite passed 29 tests. |
| Additional generated tests | None required; all DSM-02 validation gaps are already covered by committed Phase 114 test files. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands in 114-01-PLAN.md and 114-02-PLAN.md.
- [x] Sampling continuity: every implementation task carries an automated verification command.
- [x] Final summaries and verification evidence cover every validation file listed above.
- [x] No watch-mode flags are used in verification commands.
- [x] Feedback latency is under 90 seconds for focused backend checks; Playwright checks are explicit when the demo backend is running.
- [x] `nyquist_compliant: true` remains set in frontmatter after audit.

**Approval:** approved after audit; final Plan 01/02 provide automated validation coverage for DSM-02 with no manual-only gaps.

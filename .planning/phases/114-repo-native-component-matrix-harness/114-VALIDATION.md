---
phase: 114
slug: repo-native-component-matrix-harness
status: final
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
finalized: 2026-06-14
validated_against:
  - 114-01-PLAN.md
  - 114-02-PLAN.md
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
| **Full suite command** | `scripts/ci/lint.sh && cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` |
| **Estimated runtime** | ~90 seconds for focused checks after Plan 01 creates the backend matrix files; Playwright checks require the demo backend to be running |

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
| 114-01-T1 | 114-01-PLAN.md Task 1 | 1 | DSM-02 | T-114-03, T-114-04 | Deterministic fixture helpers use synthetic bounded data and do not read databases, environment, files, or network | compile + source assertions | `cd examples/demo/backend && mix compile` | created by task | planned |
| 114-01-T2 | 114-01-PLAN.md Task 2 | 1 | DSM-02 | T-114-01, T-114-02, T-114-07 | Matrix route is demo-hosted, dev/test gated, outside `RulesteadAdmin.Router.rulestead_admin/2`, and renders real shell/components | compile + route/source assertions | `cd examples/demo/backend && mix compile && cd ../../.. && rg -q 'if Mix\\.env\\(\\) in \\[:dev, :test\\] do' examples/demo/backend/lib/rulestead_demo_web/router.ex && rg -q 'live "/ui-matrix", UiMatrixLive, :index' examples/demo/backend/lib/rulestead_demo_web/router.ex && ! rg -q 'ui-matrix' rulestead_admin/lib/rulestead_admin/router.ex` | created by task | planned |
| 114-01-T3 | 114-01-PLAN.md Task 3 | 1 | DSM-02 | T-114-01, T-114-02, T-114-03, T-114-05 | ExUnit proves route reachability, `.rs-shell`, required sections, fixture health, real component source references, and no Storybook/pixel-baseline scope | ExUnit LiveView/source tests | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | created by task | planned |
| 114-02-T1 | 114-02-PLAN.md Task 1 | 2 | DSM-02 | T-114-08, T-114-09, T-114-10, T-114-11, T-114-12 | Playwright proves light/dark/system-dark, desktop/mobile, reduced-motion, section visibility, overflow, and screenshot artifacts without baselines | Playwright e2e | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | created by task | planned |
| 114-02-T2 | 114-02-PLAN.md Task 2 | 2 | DSM-02 | T-114-10, T-114-13 | Playwright proves command palette keyboard/focus behavior and existing static token/theme fixtures remain covered | Playwright e2e + static guard regression | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | extended by task | planned |

---

## Automated Coverage Files

- [x] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - planned by 114-01-PLAN.md Task 1 with `cd examples/demo/backend && mix compile`.
- [x] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - planned by 114-01-PLAN.md Task 2 with compile plus route/source assertions.
- [x] `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - planned by 114-01-PLAN.md Task 3 with `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs`.
- [x] `examples/demo/frontend/tests/ui-matrix.spec.ts` - planned by 114-02-PLAN.md Tasks 1-2 with matrix Playwright evidence and static fixture regression commands.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Visual polish defects discovered by the matrix should be recorded for Phase 115 or Phase 116 unless they prevent the matrix from rendering.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify commands in 114-01-PLAN.md and 114-02-PLAN.md.
- [x] Sampling continuity: every implementation task carries an automated verification command.
- [x] Final plans cover every validation file listed above.
- [x] No watch-mode flags are used in verification commands.
- [x] Feedback latency is under 90 seconds for focused backend checks; Playwright checks are explicit when the demo backend is running.
- [x] `nyquist_compliant: true` is set in frontmatter after plans assign task IDs and commands.

**Approval:** approved for execution; final Plan 01/02 provide automated validation coverage for DSM-02.

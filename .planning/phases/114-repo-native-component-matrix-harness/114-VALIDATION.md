---
phase: 114
slug: repo-native-component-matrix-harness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
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
| **Estimated runtime** | ~90 seconds once Wave 0 files exist |

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
| 114-W0-01 | TBD | 0 | DSM-02 | T-114-01 | Matrix route is demo-hosted and unavailable in production | source + route smoke | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | no W0 | pending |
| 114-W0-02 | TBD | 0 | DSM-02 | T-114-02 | Matrix renders real `RulesteadAdmin.Components.*` modules with deterministic fixed assigns | ExUnit LiveView/component smoke | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | no W0 | pending |
| 114-W0-03 | TBD | 0 | DSM-02 | T-114-03 | Browser evidence proves light/dark/system-dark, desktop/mobile, reduced-motion, overflow, focus, and screenshots | Playwright e2e | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | no W0 | pending |
| 114-W0-04 | TBD | 0 | DSM-02 | T-114-04 | Static token/theme fixtures remain reachable and are not replaced by matrix screenshots | Playwright/static guard regression | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | yes | pending |

---

## Wave 0 Requirements

- [ ] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_live.ex` - dev/test-only matrix LiveView route surface for DSM-02.
- [ ] `examples/demo/backend/lib/rulestead_demo_web/live/ui_matrix_fixtures.ex` - deterministic fixture assigns for matrix sections and stress states.
- [ ] `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs` - route guard, real-component rendering, section visibility, and fixture health assertions.
- [ ] `examples/demo/frontend/tests/ui-matrix.spec.ts` - Playwright browser evidence for themes, viewports, reduced motion, focus/keyboard affordances, overflow, and screenshots.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Visual polish defects discovered by the matrix should be recorded for Phase 115 or Phase 116 unless they prevent the matrix from rendering.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive implementation tasks without automated verification.
- [ ] Wave 0 covers every missing validation file listed above.
- [ ] No watch-mode flags are used in verification commands.
- [ ] Feedback latency is under 90 seconds for the focused loop after Wave 0 exists.
- [ ] `nyquist_compliant: true` is set in frontmatter after plans assign task IDs and commands.

**Approval:** pending

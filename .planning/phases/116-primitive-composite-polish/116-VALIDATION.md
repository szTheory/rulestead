---
phase: 116
slug: primitive-composite-polish
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
---

# Phase 116 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix LiveViewTest, Playwright, Python stdlib source guards |
| **Config file** | `examples/demo/frontend/playwright.config.ts`; package Mix configs |
| **Quick run command** | `python3 scripts/check_admin_foundations.py && cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| **Full suite command** | `python3 scripts/check_admin_foundations.py && cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs && cd ../frontend && npm run test:e2e -- ui-matrix.spec.ts && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` |
| **Estimated runtime** | ~120-240 seconds when backend/browser dependencies are ready |

---

## Sampling Rate

- **After every task commit:** Run the quick command or the narrower package/component command named by the task.
- **After every plan wave:** Run the full suite command for artifacts touched in that wave.
- **Before `$gsd-verify-work`:** Foundation guard, backend UI matrix test, frontend UI matrix spec, static fixture specs, and any new component tests must be green.
- **Max feedback latency:** 240 seconds for targeted checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 116-01-01 | 01 | 1 | CMP-01/CMP-02 | T-116-01 | Raw component consolidation preserves mounted-admin route boundaries and avoids public API changes | source | `rg -n "Phase 116 Raw Markup Consolidation" .planning/phases/116-primitive-composite-polish` | yes | pending |
| 116-01-02 | 01 | 1 | CMP-01/CMP-05 | T-116-02 | Primitive copy and state markers remain explicit and non-color-only | component/source | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | pending |
| 116-02-01 | 02 | 1 | CMP-03/CMP-05 | T-116-03 | Destructive confirms preserve reason, typed confirmation, danger emphasis, back link, and disabled/unavailable explanation | component | `cd rulestead_admin && mix test test/rulestead_admin/components/confirm_components_test.exs` | existing or added | pending |
| 116-02-02 | 02 | 1 | CMP-03 | T-116-04 | Route confirm stragglers migrate only where semantics match the canonical component | source/component | `rg -n "mutation_confirm|rs-mutation-confirm" rulestead_admin/lib/rulestead_admin` | yes | pending |
| 116-03-01 | 03 | 2 | CMP-04/CMP-05 | T-116-05 | Domain composites preserve governance, rollout, audit, preview uncertainty, and authorization semantics | component/source | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | pending |
| 116-03-02 | 03 | 2 | CMP-01/CMP-04 | T-116-06 | Composite visual polish remains theme-safe and mobile-contained | browser | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | yes | pending |
| 116-04-01 | 04 | 3 | CMP-01/CMP-02/CMP-03/CMP-04/CMP-05 | T-116-07 | Matrix evidence and source assertions cover all phase requirements and no forbidden tooling/posture files are introduced | source/browser | `python3 scripts/check_admin_foundations.py && cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | yes | pending |
| 116-04-02 | 04 | 3 | CMP-01/CMP-05 | T-116-08 | Existing static token/theme fixtures remain green after component polish | browser | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `examples/demo/backend/test/rulestead_demo_web/live/ui_matrix_live_test.exs`
- `examples/demo/frontend/tests/ui-matrix.spec.ts`
- `examples/demo/frontend/tests/design-system.spec.ts`
- `examples/demo/frontend/tests/theme-control.spec.ts`
- `examples/demo/frontend/tests/theme-cascade.spec.ts`
- `examples/demo/frontend/tests/theme-scope.spec.ts`
- `scripts/check_admin_foundations.py`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Qualitative visual polish of primitive/composite hierarchy | CMP-01/CMP-04 | Human review remains the qualitative layer for visual taste | Review Playwright screenshot artifacts from `ui-matrix.spec.ts`; check primitive and composite groups against `116-UI-SPEC.md`. |
| Microcopy tone and operator specificity | CMP-05 | Copy quality is partly qualitative after source assertions prove required states exist | Review matrix rare states and changed component copy for "what happened / why / next action" clarity. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 240s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-14

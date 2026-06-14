---
phase: 117
slug: page-flow-ia-pass
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-14
---

# Phase 117 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Phoenix LiveViewTest plus Playwright Test |
| **Config file** | `examples/demo/frontend/playwright.config.ts`; package Mix configs |
| **Quick run command** | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| **Full suite command** | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs && cd ../frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- ui-matrix.spec.ts && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` |
| **Estimated runtime** | ~180-360 seconds when backend/browser dependencies are ready |

---

## Sampling Rate

- **After every task commit:** Run the quick command or the narrower ExUnit/Playwright command named by the task.
- **After every plan wave:** Run backend UI matrix tests plus the route-flow Playwright spec when route or browser evidence changed.
- **Before `$gsd-verify-work`:** `117-FLOW-IA-REVIEW.md`, backend UI matrix tests, `ui-matrix.spec.ts`, and the new route-flow spec must be green or have an explicit environment note.
- **Max feedback latency:** 360 seconds for targeted browser checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01-01 | 01 | 1 | FLOW-01/FLOW-02 | T-117-01 | Route-cluster review preserves grouped navigation and does not widen mounted route contract | source/doc | `rg -n "FLOW-01|FLOW-02|RulesteadAdmin.Navigation" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | no, W0 | pending |
| 117-01-02 | 01 | 1 | FLOW-04 | T-117-02 | Fixture coverage stays deterministic and does not add product seed semantics | ExUnit/source | `cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | pending |
| 117-02-01 | 02 | 1 | FLOW-03/FLOW-04 | T-117-03 | Browser evidence verifies focus, keyboard, mobile containment, and screenshots without pixel baselines | Playwright/source | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` | no, W0 | pending |
| 117-02-02 | 02 | 1 | FLOW-01/FLOW-03 | T-117-04 | Route evidence covers overview, inventory, rules, kill, audiences, audit, explain, and simulate or records an explicit bounded exception | Playwright/doc | `rg -n "overview|inventory|rules|kill|audience|audit|explain|simulate" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | no, W0 | pending |
| 117-03-01 | 03 | 2 | FLOW-02/FLOW-03 | T-117-05 | Route-owned IA fixes preserve server-side authorization, redaction, URL state, and destructive handoff semantics | route/browser | `cd examples/demo/frontend && DEMO_BACKEND_URL=<backend-url> npm run test:e2e -- admin-flow-ia.spec.ts` | after W0 | pending |
| 117-03-02 | 03 | 2 | FLOW-01/FLOW-02/FLOW-03/FLOW-04 | T-117-06 | Final review artifact maps every requirement and proof command without adding forbidden tooling or package/release changes | source/doc | `rg -n "FLOW-01|FLOW-02|FLOW-03|FLOW-04" .planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` | after W0 | pending |

---

## Wave 0 Requirements

- [ ] `.planning/phases/117-page-flow-ia-pass/117-FLOW-IA-REVIEW.md` - route-cluster IA review matrix covering operator job, route cluster, page-owned surface, state coverage, finding, action, proof, and follow-on.
- [ ] `examples/demo/frontend/tests/admin-flow-ia.spec.ts` - route-level browser evidence for selected primary clusters.
- [ ] Any focused backend source/fixture assertion needed to prove FLOW-04 coverage if the existing UI matrix test does not cover a missing state.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Least-surprise page hierarchy and visual scan order | FLOW-02 | Qualitative IA judgment remains partly human after source/browser assertions prove coverage | Review `117-FLOW-IA-REVIEW.md` and generated Playwright screenshot artifacts for home, inventory, rules, kill, audience, audit, explain, and simulate. |
| Microcopy and emergency/destructive clarity | FLOW-02/FLOW-03 | Copy quality and emergency sequencing need human review after automated checks prove labels/actions exist | Review kill-switch, destructive, denied, unavailable, redaction, and audit handoff screenshots for "what happened / why / next safe action" clarity. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 360s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-14

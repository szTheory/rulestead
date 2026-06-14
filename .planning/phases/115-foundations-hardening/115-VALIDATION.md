---
phase: 115
slug: foundations-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-14
---

# Phase 115 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python stdlib guard, ExUnit/Phoenix LiveViewTest, Playwright |
| **Config file** | `examples/demo/frontend/playwright.config.ts`; package Mix configs |
| **Quick run command** | `python3 scripts/check_admin_foundations.py` |
| **Full suite command** | `python3 scripts/check_admin_foundations.py && cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs && cd ../frontend && npm run test:e2e -- ui-matrix.spec.ts` |
| **Estimated runtime** | ~90-180 seconds when backend/browser dependencies are ready |

---

## Sampling Rate

- **After every task commit:** Run the quick command for source-guard tasks; run the targeted package/browser command for tasks that touch test files.
- **After every plan wave:** Run the full suite command for artifacts touched in that wave.
- **Before `$gsd-verify-work`:** Foundation guard, backend UI matrix test, frontend UI matrix spec, and existing static fixture specs must be green.
- **Max feedback latency:** 180 seconds for targeted checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 115-01-01 | 01 | 1 | FND-01/FND-02/FND-05 | T-115-01 | New foundation rules are documented before guard enforcement | source | `test -f .planning/phases/115-foundations-hardening/115-FOUNDATIONS-CONTRACT.md` | yes | pending |
| 115-01-02 | 01 | 1 | FND-01/FND-02/FND-05 | T-115-02 | Guard fails on undocumented foundation drift | source | `python3 scripts/check_admin_foundations.py` | yes | pending |
| 115-02-01 | 02 | 2 | FND-03/FND-04/FND-05 | T-115-03 | Reduced-motion users do not receive nonessential transform/animation effects | source/browser | `python3 scripts/check_admin_foundations.py` | yes | pending |
| 115-02-02 | 02 | 2 | FND-01/FND-05 | T-115-04 | CSS exceptions remain documented after selector edits | source | `python3 scripts/check_admin_foundations.py` | yes | pending |
| 115-03-01 | 03 | 3 | FND-03/FND-04/FND-06 | T-115-05 | Matrix evidence proves overflow/focus/reduced-motion behavior | browser | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts` | yes | pending |
| 115-03-02 | 03 | 3 | FND-02/FND-06 | T-115-06 | Existing static token/theme fixtures remain green | browser | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` | yes | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Qualitative visual polish of shape/elevation rhythm | FND-05 | Human review remains the qualitative layer for visual taste | Review Playwright screenshot artifacts from `ui-matrix.spec.ts`; check that radius/elevation/emphasis follows `115-FOUNDATIONS-CONTRACT.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-14

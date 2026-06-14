---
phase: 118
slug: evidence-idempotence-guardrails
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 118 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright Test 1.60.0, ExUnit/Mix 1.19.5, Python guard scripts |
| **Config file** | `examples/demo/frontend/playwright.config.ts`; Mix project configs under `rulestead/`, `rulestead_admin/`, and `examples/demo/backend` |
| **Quick run command** | `python3 scripts/check_admin_foundations.py && cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` |
| **Browser matrix command** | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` |
| **Static fixture command** | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts` |
| **Full guard command** | `bash scripts/ci/lint.sh` when practical |
| **Estimated runtime** | Backend/source checks are expected to be quick; browser matrix runtime depends on local backend startup and Playwright worker scheduling |

---

## Sampling Rate

- **After every task commit:** Run the narrow command for the touched tier: Playwright spec for browser changes, ExUnit for fixture/source changes, or the specific `scripts/check_*.py` guard for script/docs changes.
- **After every plan wave:** Run the browser matrix/workflow command and static fixture command with an explicit `DEMO_BACKEND_URL`.
- **Before `$gsd-verify-work`:** Run final selected Playwright/ExUnit/static fixture checks, relevant guard-chain scripts or `bash scripts/ci/lint.sh`, `git diff --check`, and source scans for forbidden visual-baseline tooling.
- **Max feedback latency:** Prefer narrow checks under a few minutes; browser suite latency is acceptable when recorded with the evidence artifact.

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| VER-01 | Matrix and mounted-admin workflow screenshots cover light, dark, system-dark, desktop, mobile, and targeted reduced-motion evidence. | browser/e2e artifact | `cd examples/demo/frontend && DEMO_BACKEND_URL=http://localhost:<port> npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts` | yes | pending |
| VER-02 | Deterministic assertions cover overflow, focus, ARIA/regions, keyboard flow, fixture health, and selected contrast pairs. | browser + ExUnit/source | `cd examples/demo/frontend && npm run test:e2e -- ui-matrix.spec.ts admin-flow-ia.spec.ts design-system.spec.ts` plus `cd examples/demo/backend && MIX_ENV=test mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs` | yes | pending |
| VER-03 | Brand/token/logo/contrast/brandbook/foundation guard scripts remain green and are extended only for concrete repeatable drift. | script/CI | `python3 scripts/check_synced_pair.py && python3 scripts/check_brand_tokens.py && python3 scripts/check_tokens_css.py && python3 scripts/check_contrast.py && python3 scripts/check_brandbook_html.py && python3 scripts/check_logo_assets.py && python3 scripts/check_admin_foundations.py` | yes | pending |
| VER-04 | Planning docs record decisions, evidence, requirement completion, intentional exceptions, and residual risks before closeout. | source/doc assertion | `rg -n "VER-01|VER-02|VER-03|VER-04|intentional exception|artifact|118" .planning/phases/118-evidence-idempotence-guardrails .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` | partial | pending |

---

## Wave 0 Requirements

- [ ] `.planning/phases/118-evidence-idempotence-guardrails/118-EVIDENCE.md` or `.planning/phases/118-evidence-idempotence-guardrails/118-VERIFICATION.md` maps VER-01 through VER-04 to commands, artifacts, guard outputs, exceptions, and risks.
- [ ] Browser backend startup command and chosen `DEMO_BACKEND_URL` are captured in execution evidence.
- [ ] Optional source/doc assertion is added if the final plan needs automated VER-04 traceability before closeout.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review of generated screenshot artifacts | VER-01 | Screenshots are generated artifacts, not committed pixel baselines or automated visual-diff gates. | Record Playwright output paths and inspect representative matrix/workflow screenshots after the browser command finishes. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or documented artifact review steps.
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify command.
- [ ] Wave 0 covers final evidence artifact creation and browser backend command capture.
- [ ] No watch-mode flags.
- [ ] No broad checked-in pixel baselines, `toHaveScreenshot`, `matchSnapshot`, pixelmatch, Storybook, PhoenixStorybook, or external AI visual-review gates.
- [ ] `nyquist_compliant: true` is set in frontmatter only after the final plan includes complete verification coverage.

**Approval:** pending

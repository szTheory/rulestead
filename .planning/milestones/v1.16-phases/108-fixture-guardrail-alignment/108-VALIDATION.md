---
phase: 108
slug: fixture-guardrail-alignment
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 108 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Python guard scripts; Playwright Test |
| Config file | `examples/demo/frontend/playwright.config.ts` |
| Quick run command | `python3 scripts/check_logo_assets.py && python3 scripts/check_contrast.py` |
| Full suite command | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-cascade.spec.ts theme-control.spec.ts theme-scope.spec.ts` |
| Estimated runtime | < 2 minutes |

## Sampling Rate

- After fixture or asset edits: run logo and contrast guards.
- After fixture Playwright edits: run the listed fixture specs.
- Before milestone audit: run the full suite command.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-T1 | 01 | 1 | BUI-02 | N/A | Canonical wordmark assets are copied for fixture use and drift-checked. | guard | `python3 scripts/check_logo_assets.py` | yes | green |
| 108-01-T2 | 01 | 1 | BUI-02 | N/A | Design/theme harnesses expose shipped wordmark assets. | browser | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts` | yes | green |
| 108-01-T3 | 01 | 1 | BUI-02 | N/A | Fixture specs assert current wordmark/token assumptions. | browser | `cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-cascade.spec.ts theme-control.spec.ts theme-scope.spec.ts` | yes | green |
| 108-01-T4 | 01 | 1 | BUI-02 | N/A | Logo drift guard runs in normal lint. | source/guard | `rg "check_logo_assets.py" scripts/ci/lint.sh && python3 scripts/check_logo_assets.py` | yes | green |
| 108-01-T5 | 01 | 1 | BUI-02 | N/A | Contrast guard runs in normal lint. | source/guard | `rg "check_contrast.py" scripts/ci/lint.sh && python3 scripts/check_contrast.py` | yes | green |

## Wave 0 Requirements

Existing Playwright and Python guard infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 2 minutes for targeted checks.
- [x] `nyquist_compliant: true` set in frontmatter.

Approval: backfilled 2026-06-13


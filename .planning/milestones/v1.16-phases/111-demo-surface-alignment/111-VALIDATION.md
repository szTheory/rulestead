---
phase: 111
slug: demo-surface-alignment
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 111 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit/Phoenix ConnCase; Playwright Test; demo compose verifier |
| Config file | `examples/demo/backend/config/test.exs`; `examples/demo/frontend/playwright.config.ts` |
| Quick run command | `cd examples/demo/backend && mix test test/rulestead_demo_web/controllers/page_controller_test.exs --max-cases 1` |
| Full suite command | `bash scripts/demo/verify.sh` |
| Estimated runtime | backend quick test < 20 seconds; full compose proof several minutes |

## Sampling Rate

- After Phoenix launcher/layout edits: run backend page controller tests.
- After FleetDesk/browser evidence edits: run targeted `brand-ui-evidence.spec.ts` grep for launcher cases.
- Before milestone audit: run `bash scripts/demo/verify.sh`.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 111-01-T1 | 01 | 1 | BUI-05 | N/A | Phoenix launcher uses Rulestead mineral chrome and v1.15 wordmark. | browser | `cd examples/demo/frontend && npm run test:e2e -- brand-ui-evidence.spec.ts --grep "demo launcher"` | yes | green |
| 111-01-T2 | 01 | 1 | BUI-05 | N/A | FleetDesk stays host-branded with separate light/system-dark styling. | browser | `cd examples/demo/frontend && npm run test:e2e -- brand-ui-evidence.spec.ts --grep "FleetDesk remains host-branded"` | yes | green |
| 111-01-T3 | 01 | 1 | BUI-05 | N/A | Stale teal/Phoenix defaults are removed from FleetDesk visual evidence. | browser/source | `rg "FleetDesk remains host-branded|fd-brand-name" examples/demo/frontend/tests/brand-ui-evidence.spec.ts examples/demo/frontend/app/fleetdesk.css` | yes | green |
| 111-01-T4 | 01 | 1 | BUI-05 | N/A | Dirty generated asset state and dynamic frontend ports do not break proof. | compose | `bash scripts/demo/verify.sh` | yes | green |
| 112.1-01-T1 | 01 | 1 | BUI-05 | N/A | Phoenix FleetDesk links use runtime `DEMO_FRONTEND_URL`. | backend | `cd examples/demo/backend && mix test test/rulestead_demo_web/controllers/page_controller_test.exs --max-cases 1` | yes | green |

## Wave 0 Requirements

Existing backend, Playwright, and compose verifier infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have automated verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < several minutes for full compose proof.
- [x] `nyquist_compliant: true` set in frontmatter.

Approval: backfilled 2026-06-13


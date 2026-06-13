---
phase: 110
slug: admin-workflow-screen-pass
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
---

# Phase 110 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Playwright Test; demo compose verifier |
| Config file | `examples/demo/frontend/playwright.config.ts`; `scripts/demo/verify.sh` |
| Quick run command | `rg "fleet-map-v2/rollouts|wordmark|theme-control|overflow" examples/demo/frontend/tests/brand-ui-evidence.spec.ts` |
| Full suite command | `bash scripts/demo/verify.sh` |
| Estimated runtime | source check < 5 seconds; full compose proof several minutes |

## Sampling Rate

- After evidence matrix edits: run the quick source check.
- After route/theme/viewport assertion edits: run `brand-ui-evidence.spec.ts`.
- Before milestone audit: run `bash scripts/demo/verify.sh`.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-T1 | 01 | 1 | BUI-04 | N/A | Representative build/release, explain/diagnose, review/approve, and destructive routes have browser evidence. | browser | `cd examples/demo/frontend && npm run test:e2e -- brand-ui-evidence.spec.ts` | yes | green |
| 110-01-T2 | 01 | 1 | BUI-04 | N/A | Shell wordmark, theme control, and no horizontal overflow are asserted across themes/viewports. | browser/source | `rg "rs-shell__wordmark|rs-theme-control__group|toBeLessThanOrEqual" examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | yes | green |
| 110-01-T3 | 01 | 1 | BUI-04 | N/A | Screenshots are Playwright artifacts, not committed pixel baselines. | browser/source | `rg "screenshot" examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | yes | green |
| 110-01-T4 | 01 | 1 | BUI-04 | N/A | Evidence changes avoid domain/data behavior edits. | verification | `git show --stat --oneline f23df69 -- examples/demo/frontend/tests/brand-ui-evidence.spec.ts` | yes | green |

## Wave 0 Requirements

Existing Playwright and compose verifier infrastructure covers all phase requirements.

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


---
phase: 49
slug: guardrail-signal-contract
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/config/test.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs test/rulestead/ruleset_validation_test.exs test/rulestead/store/manifest_export_contract_test.exs` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run the smallest package-local command covering the files touched in that task.
- **After every plan wave:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs test/rulestead/ruleset_validation_test.exs test/rulestead/store/manifest_export_contract_test.exs`
- **Before `$gsd-verify-work`:** Run the phase-closeout suite: `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs test/rulestead/ruleset_validation_test.exs test/rulestead/store/compare_contract_test.exs test/rulestead/store/manifest_export_contract_test.exs test/rulestead/manifest/export_test.exs`
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | ROL-01 | T-49-01, T-49-02, T-49-03, T-49-10 | Host-owned provider seam preserves explicit scope and reuses the existing provenance/audit normalization vocabulary for fail-closed guardrail facts | unit | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guardrails/contract_test.exs test/rulestead/guardrails/metadata_contract_test.exs` | ✅ | ✅ green |
| 49-02-01 | 02 | 2 | ROL-01 | T-49-04, T-49-05, T-49-06 | Guardrail definitions are first-class authored rollout config with closed validation for threshold, freshness, sample-size, and scope fields | unit | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/ruleset_validation_test.exs` | ✅ | ✅ green |
| 49-03-01 | 03 | 3 | ROL-01 | T-49-07, T-49-08, T-49-09 | Guardrail authored state survives compare and export projections without widening into Phase 50 or provider-specific blobs | integration | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store/compare_contract_test.exs test/rulestead/store/manifest_export_contract_test.exs test/rulestead/manifest/export_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All Phase 49 behaviors should have automated verification through ExUnit and the scoped compare/export contract suites.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed

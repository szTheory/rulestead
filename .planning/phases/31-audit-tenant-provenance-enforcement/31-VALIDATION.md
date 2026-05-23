---
phase: 31
slug: audit-tenant-provenance-enforcement
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/admin_audit_kill_switch_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/manifest/import_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/governance_adapter_contract_test.exs test/rulestead/store/scheduled_execution_adapter_contract_test.exs test/rulestead/scheduled_execution_audit_contract_test.exs test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/admin_audit_kill_switch_test.exs`
- **After every plan wave:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/manifest/import_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/governance_adapter_contract_test.exs test/rulestead/store/scheduled_execution_adapter_contract_test.exs test/rulestead/scheduled_execution_audit_contract_test.exs test/rulestead/release_contract_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | TEN-03 | T-31-01 / T-31-02 | Bounded tenant provenance is normalized explicitly for real-tenant, unscoped, and `SingleTenant` inputs | unit | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs` | ✅ | ⬜ pending |
| 31-01-02 | 01 | 1 | TEN-03 | T-31-03 / T-31-04 | Apply and replay payloads persist normalized tenant provenance before audit emission | integration | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/manifest/import_test.exs` | ✅ | ⬜ pending |
| 31-02-01 | 02 | 2 | TEN-03 | T-31-05 / T-31-06 | Ecto and Fake audit builders auto-merge the same provenance on direct, denied, governance, and rollback paths | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_audit_kill_switch_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/governance_adapter_contract_test.exs` | ✅ | ⬜ pending |
| 31-02-02 | 02 | 2 | TEN-03 | T-31-07 / T-31-08 | Apply, governance, and rollback-oriented contract suites prove bounded provenance parity before the scheduler-specific pass | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/manifest_import_contract_test.exs test/rulestead/store/governance_adapter_contract_test.exs test/rulestead/audit_event_governance_test.exs` | ✅ | ⬜ pending |
| 31-03-01 | 03 | 3 | TEN-03 | T-31-07 / T-31-08 | Scheduled execution suites prove provenance survives replay and delayed execution paths | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store/scheduled_execution_adapter_contract_test.exs test/rulestead/scheduled_execution_audit_contract_test.exs` | ✅ | ⬜ pending |
| 31-03-02 | 03 | 3 | TEN-03 | T-31-07 / T-31-08 | Release-contract assertions prove tenant provenance stays inside the bounded documented metadata surface | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-22

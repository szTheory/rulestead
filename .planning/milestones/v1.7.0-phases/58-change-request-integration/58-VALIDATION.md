---
phase: 58
slug: change-request-integration
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 58 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_test.exs test/rulestead/governance/audience_mutation_change_request_contract_test.exs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 1 | CRQ-01 | T-58-01 | Submit rejects indeterminate/below threshold | unit | quick run command | ❌ W0 | ⬜ pending |
| 58-01-02 | 01 | 1 | CRQ-01 | T-58-02 | governed_actions includes apply_audience_mutation | unit | quick run command | ❌ W0 | ⬜ pending |
| 58-02-01 | 02 | 2 | CRQ-02 | T-58-03 | Governed execute bypasses above_threshold only | contract | `cd rulestead && mix test test/rulestead/governance/audience_mutation_change_request_contract_test.exs --only fake` | ❌ W0 | ⬜ pending |
| 58-03-01 | 03 | 2 | CRQ-02 | T-58-03 | Ecto parity with Fake audience CR flow | contract | full suite command | ❌ W0 | ⬜ pending |
| 58-04-01 | 04 | 3 | CRQ-03 | T-58-04 | Reject/cancel: audience unchanged + audit evidence | contract | full suite command | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + governance adapter patterns cover phase requirements

*No new Wave 0 stubs required.*

---

## Manual-Only Verifications

None for Phase 58.

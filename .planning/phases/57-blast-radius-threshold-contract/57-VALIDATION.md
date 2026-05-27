---
phase: 57
slug: blast-radius-threshold-contract
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | GOV-02 | T-57-01 | Assessment payload excludes population counts | unit | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` | ❌ W0 | ⬜ pending |
| 57-01-02 | 01 | 1 | GOV-04 | T-57-02 | Indeterminate on missing preview inputs | unit | same | ❌ W0 | ⬜ pending |
| 57-02-01 | 02 | 2 | GOV-03 | T-57-03 | Non-prod bypass; prod above-threshold block | contract | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs` | ✅ | ⬜ pending |
| 57-03-01 | 03 | 2 | GOV-03 | T-57-03 | Ecto parity with Fake threshold behavior | contract | `cd rulestead && mix test test/rulestead/store/ecto_audience_impact_contract_test.exs` | ✅ | ⬜ pending |
| 57-04-01 | 04 | 3 | GOV-01 | T-57-04 | Public assess API + prod breach remediation copy | unit+contract | full suite command | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers all phase requirements

*No new Wave 0 stubs required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

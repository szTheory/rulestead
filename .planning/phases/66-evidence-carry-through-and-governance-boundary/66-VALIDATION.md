---
phase: 66
slug: evidence-carry-through-and-governance-boundary
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/governance/audience_mutation_change_request_contract_test.exs test/rulestead/governance/blast_radius_threshold_test.exs test/rulestead/governance/preview_evidence_governance_contract_test.exs` |
| **Estimated runtime** | ~45–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command or plan-specific slice from RESEARCH.md
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | IMP-07 | T-66-01 | Summary uses redacted fields only | unit | `mix test test/rulestead/targeting/impact_preview_test.exs` | ✅ | ⬜ pending |
| 66-01-02 | 01 | 1 | IMP-07 | T-66-02 | Allowlist includes impression_evidence | unit | same | ✅ | ⬜ pending |
| 66-02-01 | 02 | 2 | IMP-07 | T-66-02 | Ecto audit carries impression_evidence | integration | `mix test test/rulestead/audience_mutation_audit_test.exs` | ✅ | ⬜ pending |
| 66-02-02 | 02 | 2 | IMP-07 | T-66-02 | Fake success path carries sample+impression | integration | same | ✅ | ⬜ pending |
| 66-03-01 | 03 | 3 | IMP-07 | T-66-03 | CR submit embeds preview_evidence_summary | contract | `mix test test/rulestead/governance/audience_mutation_change_request_contract_test.exs` | ✅ | ⬜ pending |
| 66-03-02 | 03 | 3 | IMP-07 | T-66-03 | Terminal reject/cancel carries frozen summary | contract | same | ✅ | ⬜ pending |
| 66-04-01 | 04 | 4 | GOV-05 | — | assess/2 unchanged with evidence attrs | unit | `mix test test/rulestead/governance/blast_radius_threshold_test.exs` | ✅ | ⬜ pending |
| 66-04-02 | 04 | 4 | GOV-05 | — | Full path verdict parity with resolver | contract | `mix test test/rulestead/governance/preview_evidence_governance_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit + RepoCase + `@adapters` contract patterns cover phase
- [ ] `preview_evidence_governance_contract_test.exs` — stubs for GOV-05 full-path regression (plan 66-04)

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
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

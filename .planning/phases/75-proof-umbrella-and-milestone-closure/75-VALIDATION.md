---
phase: 75
slug: proof-umbrella-and-milestone-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `rulestead/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/context_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase73` |
| **Estimated runtime** | ~120–180 seconds (phase72 superset + context tests + admin subprocess) |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` command from PLAN.md
- **After every plan wave:** Run `cd rulestead && mix verify.phase73`
- **Before `/gsd-verify-work`:** `mix verify.adopter` and `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 75-01-01 | 01 | 1 | VER-01 | T-75-01 / — | Flat union includes context_test; no delegate to phase72 | integration | `cd rulestead && mix verify.phase73` | ✅ | ⬜ pending |
| 75-01-02 | 01 | 1 | VER-02 | — | adopter runs phase73 only | integration | `cd rulestead && mix verify.adopter` | ✅ | ⬜ pending |
| 75-02-01 | 02 | 2 | DOC-02 | T-75-02 / — | Docs name phase73 as current bar | contract | `mix test test/rulestead/release_contract_test.exs --only line:634` | ✅ | ⬜ pending |
| 75-02-02 | 02 | 2 | DOC-02 | — | MAINTAINING proof matrix updated | contract | `mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 75-03-01 | 03 | 3 | AUD-01 | — | STATE lists investigations closed | manual grep | `rg 'INV-API-01.*[Cc]losed' .planning/STATE.md` | ✅ | ⬜ pending |
| 75-03-02 | 03 | 3 | AUD-02 | — | Milestone audit artifact exists | manual | `test -f .planning/v1.10.1-MILESTONE-AUDIT.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework install.

- [x] `verify.phase72.ex` — template for flat union pattern
- [x] `release_contract_test.exs` — post-GA doc honesty block
- [x] `context_test.exs` — v1.10.1 unit guard

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Path-to-done thread narrative | DOC-02 | Prose milestone table | Confirm row 1 exit criteria reference phase73 + closed investigations |
| STATE operator next steps | AUD-01 | Planning doc | Read `.planning/STATE.md` — v1.10.1 marked complete, next milestone optional |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

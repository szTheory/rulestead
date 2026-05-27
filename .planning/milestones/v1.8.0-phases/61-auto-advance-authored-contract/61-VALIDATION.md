---
phase: 61
slug: auto-advance-authored-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `rulestead/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/guardrails/auto_advance_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/rollout_auto_advance_contract_test.exs test/rulestead/guarded_rollout_test.exs` |
| **Estimated runtime** | ~15–45 seconds |

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
| 61-01-01 | 01 | 1 | ROL-04 | T-61-01 | Policy upsert validates required fields when enabled | unit | `mix test .../auto_advance_test.exs` (after 61-02) / compile | ❌ W0 | ⬜ pending |
| 61-01-02 | 01 | 1 | ROL-04 | T-61-02 | Unique composite index prevents duplicate policies | migration | `mix ecto.migrate` in test | ❌ W0 | ⬜ pending |
| 61-02-01 | 02 | 2 | ROL-05 | T-61-03 | Never eligible on `:pending_data` / empty facts after close | unit | `mix test .../auto_advance_test.exs` | ❌ W0 | ⬜ pending |
| 61-02-02 | 02 | 2 | ROL-05 | T-61-04 | Blocked reasons are explicit strings | unit | `mix test .../auto_advance_test.exs` | ❌ W0 | ⬜ pending |
| 61-03-01 | 03 | 3 | ROL-04, ROL-07 | T-61-05 | Fake evaluate does not mutate rollout stage | integration | contract test (61-04) | ❌ W0 | ⬜ pending |
| 61-03-02 | 03 | 3 | ROL-07 | T-61-06 | guarded_rollout hold/rollback unchanged | regression | `mix test .../guarded_rollout_test.exs` | ✅ | ⬜ pending |
| 61-04-01 | 04 | 4 | ROL-04 | T-61-07 | Fake/Ecto parity on policy CRUD + eligibility | contract | `mix test .../rollout_auto_advance_contract_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `rulestead/test/rulestead/guardrails/auto_advance_test.exs` — pure eligibility matrix (61-02)
- [ ] `rulestead/test/rulestead/rollout_auto_advance_contract_test.exs` — `@adapters` contract (61-04)
- [ ] Migration `add_rollout_auto_advance_policies` — 61-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | — | — | All behaviors automated via ExUnit |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

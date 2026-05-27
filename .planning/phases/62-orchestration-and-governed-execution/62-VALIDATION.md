---
phase: 62
slug: orchestration-and-governed-execution
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 62 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs test/rulestead/rollout_auto_advance_contract_test.exs test/rulestead/guarded_rollout_test.exs test/rulestead/scheduled_execution_conflict_test.exs test/rulestead/guardrails/auto_advance_test.exs` |
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
| 62-01-01 | 01 | 1 | ORC-01 | T-62-01 | Deterministic idempotency_key on ScheduleGovernedAction | unit | `cd rulestead && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 62-01-02 | 01 | 1 | ORC-01 | T-62-02 | Schedule hook after advance does not fail advance | integration | quick run (schedule test only) | ❌ W4 | ⬜ pending |
| 62-01-03 | 01 | 1 | ORC-02 | T-62-03 | Supersede/cancel pending auto-advance ticks | integration | quick run | ❌ W4 | ⬜ pending |
| 62-02-01 | 02 | 2 | ORC-01, AUD-03 | T-62-04 | Blocked eligibility completes tick without mutation | unit | `cd rulestead && mix test test/rulestead/guardrails/auto_advance_test.exs` | ✅ | ⬜ pending |
| 62-02-02 | 02 | 2 | ORC-01, AUD-03 | T-62-05 | Fresh signal fetch at execute via provider seam | integration | quick run | ❌ W4 | ⬜ pending |
| 62-02-03 | 02 | 2 | ORC-01 | T-62-06 | Snapshot stale before evaluate/advance | integration | quick run | ❌ W4 | ⬜ pending |
| 62-03-01 | 03 | 3 | ROL-06 | T-62-07 | Protected env submits CR, never auto-approves | integration | quick run | ❌ W4 | ⬜ pending |
| 62-03-02 | 03 | 3 | ROL-06, ORC-01 | T-62-08 | Non-protected env direct advance via orchestrator | integration | quick run | ❌ W4 | ⬜ pending |
| 62-03-03 | 03 | 3 | ORC-01 | T-62-09 | Fake/Ecto execute branch parity | integration | quick run | ❌ W4 | ⬜ pending |
| 62-04-01 | 04 | 4 | ORC-01, ORC-02, ROL-06, AUD-03 | T-62-10 | Full contract matrix on both adapters | contract | full suite command | ❌ W4 | ⬜ pending |
| 62-04-02 | 04 | 4 | ORC-02 | T-62-11 | Replay + manual-advance race cases | contract | full suite command | ❌ W4 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `rulestead/test/rulestead/rollout_auto_advance_contract_test.exs` — Phase 61 evaluate contract
- [x] `rulestead/test/rulestead/guarded_rollout_test.exs` — ROL-07 regression
- [x] `rulestead/test/rulestead/scheduled_execution_conflict_test.exs` — stale target patterns
- [ ] `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` — stubs created in 62-04-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Oban job enqueue timing | ORC-01 | Ecto Oban insert timing varies in CI | Optional: inspect `oban_jobs` after schedule in Ecto adapter test |

*Primary behaviors automated via contract tests on Fake + Ecto.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

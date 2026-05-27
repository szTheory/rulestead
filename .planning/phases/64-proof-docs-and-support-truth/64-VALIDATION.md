---
phase: 64
slug: proof-docs-and-support-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `rulestead/mix.exs`, `rulestead_admin/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase64` |
| **CI scope command** | `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify from PLAN.md
- **After wave 1 (64-01):** Run `mix verify.phase64`
- **After wave 2 (64-02, 64-03):** Run `mix test test/rulestead/release_contract_test.exs`
- **Before phase close (64-04):** Full CI scope green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | VER-01 | T-64-01 | Flat union; no sub-task delegation | integration | `cd rulestead && mix verify.phase64` | ❌ W1 | ⬜ pending |
| 64-01-02 | 01 | 1 | VER-01 | T-64-02 | preferred_envs registration | unit | `mix help verify.phase64` | ❌ W1 | ⬜ pending |
| 64-02-01 | 02 | 2 | VER-02/03 | T-64-03 | Bounded support truth asserts | contract | `mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 64-02-02 | 02 | 2 | VER-02/03 | T-64-04 | README/MAINTAINING parity | contract | `mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 64-03-01 | 03 | 2 | VER-02 | T-64-05 | Host seam + flow guide content | grep | `grep -q 'observation window' guides/flows/rollout.md` | ✅ | ⬜ pending |
| 64-04-01 | 04 | 3 | VER-03 | T-64-06 | CI scope wiring | integration | `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` | ❌ W3 | ⬜ pending |
| 64-04-02 | 04 | 3 | VER-03 | T-64-07 | Verification artifact | file | `test -f 64-VERIFICATION.md` | ❌ W3 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements — test files from Phases 61–63 are green. No Wave 0 stubs needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host seam prose readability | VER-02 | Doc quality not grep-able | Read `prompts/rulestead-host-app-integration-seam.md` auto-advance subsection for operator clarity |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — pre-existing tests)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-27

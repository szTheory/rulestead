---
phase: 60
slug: proof-docs-and-support-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead/mix.exs`, `rulestead_admin/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/governance/blast_radius_threshold_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase60` |
| **Estimated runtime** | ~120–240 seconds |

---

## Sampling Rate

- **After every task commit:** Run plan-specific quick command from Per-Task Verification Map
- **After every plan wave:** Run `cd rulestead && mix verify.phase60`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 240 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | VER-01 | — | N/A | unit | `cd rulestead && mix test lib/mix/tasks/verify.phase56.ex` (pattern read) | ✅ | ⬜ pending |
| 60-01-02 | 01 | 1 | VER-01 | — | N/A | integration | `cd rulestead && mix verify.phase60` | ❌ W0 | ⬜ pending |
| 60-02-01 | 02 | 2 | VER-02 | — | N/A | contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 60-02-02 | 02 | 2 | VER-02 | — | N/A | contract | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 60-03-01 | 03 | 2 | VER-02 | — | N/A | manual+contract | `grep -l "change request" guides/flows/admin-ui.md` | ✅ | ⬜ pending |
| 60-03-02 | 03 | 2 | VER-02 | — | N/A | manual+contract | `grep -l "protected" guides/flows/multi-env.md` | ✅ | ⬜ pending |
| 60-04-01 | 04 | 3 | VER-03 | — | N/A | integration | `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh` | ❌ W0 | ⬜ pending |
| 60-04-02 | 04 | 3 | VER-03 | — | N/A | docs | `test -f .planning/phases/60-proof-docs-and-support-truth/60-VERIFICATION.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Wave 0 creates:
- [ ] `rulestead/lib/mix/tasks/verify.phase60.ex` — merge gate task (Plan 60-01)
- [ ] `scripts/ci/test.sh` — `blast_radius_governance` scope (Plan 60-04)

*All governance tests from Phases 57–59 already exist and are green.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Flow guide readability | VER-02 | Prose quality not grep-able | Read admin-ui.md and multi-env.md governance sections for operator clarity |
| Quickstart mental model | VER-03 | UX judgment | Confirm getting-started leads with payload+context before conn example |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 240s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

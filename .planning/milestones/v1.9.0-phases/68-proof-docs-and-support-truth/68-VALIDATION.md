---
phase: 68
slug: proof-docs-and-support-truth
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `rulestead/config/test.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/targeting/preview_evidence_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase68` |
| **Estimated runtime** | ~120 seconds (core + admin subprocess) |

---

## Sampling Rate

- **After every task commit:** Run plan-specific `<automated>` command from task
- **After every plan wave:** Run `cd rulestead && mix verify.phase68`
- **Before phase complete:** `mix verify.phase68` + `release_contract_test.exs` + CI scope green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 1 | VER-01 | T-68-01 | Flat union; no sub-task delegation | integration | `cd rulestead && mix verify.phase68` | ❌ W0 | ⬜ pending |
| 68-01-02 | 01 | 1 | VER-01 | T-68-01 | preferred_envs registration | unit | `grep verify.phase68 rulestead/mix.exs` | ✅ | ⬜ pending |
| 68-02-01 | 02 | 2 | VER-02/03 | T-68-04 | Docs forbid population/observability overclaim | unit | `mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 68-02-02 | 02 | 2 | VER-02 | T-68-04 | README/MAINTAINING bounded claims | unit | same + grep asserts | ✅ | ⬜ pending |
| 68-03-01 | 03 | 2 | VER-02 | T-68-05 | Host seam teaches resolver opt-in | manual grep | `rg PreviewEvidenceResolver prompts/` | ❌ W0 | ⬜ pending |
| 68-03-02 | 03 | 2 | VER-02 | T-68-05 | Flow guides teach bounded evidence UX | manual grep | `rg 'sample cohort' guides/flows/` | ❌ W0 | ⬜ pending |
| 68-04-01 | 04 | 3 | VER-03 | T-68-06 | CI scope runs verify.phase68 | integration | `RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh` | ❌ W0 | ⬜ pending |
| 68-04-02 | 04 | 3 | VER-03 | — | Verification artifact documents evidence | docs | file exists | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Wave 0 creates only:

- [ ] `rulestead/lib/mix/tasks/verify.phase68.ex` — merge gate task (68-01)

*All v1.9 contract tests exist from Phases 65–67.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer spot-check host seam readability | VER-02 | Prose quality | Read new subsection in `prompts/rulestead-host-app-integration-seam.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers verify.phase68 task file
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending

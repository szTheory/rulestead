---
phase: 56
slug: proof-docs-and-support-truth
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 56 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (rulestead + rulestead_admin) |
| **Config file** | `rulestead/mix.exs`, `rulestead_admin/mix.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs test/rulestead/audience_mutation_audit_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase56` |
| **Estimated runtime** | ~120 seconds (Fake adapter + focused admin subset) |

---

## Sampling Rate

- **After every task commit:** Run the plan's `<automated>` verify command
- **After every plan wave:** Run `cd rulestead && mix verify.phase56`
- **Before `/gsd-verify-work`:** Full suite command above must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 56-01-01 | 01 | 1 | VER-01 | T-56-01 | Core union includes phase54+55-unique+phase53 gaps | unit | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs test/rulestead/audience_mutation_audit_test.exs` | ✅ | ⬜ pending |
| 56-01-02 | 01 | 1 | VER-01 | T-56-02 | Admin completion paths + preferred_envs wired | mix task | `cd rulestead && mix verify.phase56` | ❌ W0 | ⬜ pending |
| 56-02-01 | 02 | 2 | VER-02 | T-56-03 | README/package README proof sections aligned | rg | `rg -n "mix verify\.phase56\|reusable targeting\|preview basis\|fail closed\|mounted companion" README.md rulestead/README.md rulestead_admin/README.md` | ✅ | ⬜ pending |
| 56-02-02 | 02 | 2 | VER-02 | T-56-05 | release_contract drift guard for reusable targeting | unit | `cd rulestead && mix test test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |
| 56-03-01 | 03 | 2 | VER-02 | — | rulesets + explainability guide alignment | rg | `rg -n "Audience\|preview basis\|fail closed\|snapshot-local" guides/flows/rulesets.md guides/flows/explainability.md` | ✅ | ⬜ pending |
| 56-03-02 | 03 | 2 | VER-02 | — | admin-ui + multi-env guide alignment | rg | `rg -n "/admin/audiences\|read-only\|dependency findings\|tenant scope" guides/flows/admin-ui.md guides/flows/multi-env.md` | ✅ | ⬜ pending |
| 56-04-01 | 04 | 3 | VER-03 | T-56-04 | CI scope invokes verify.phase56 + release_contract CI cites | integration | `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh` | ❌ W0 | ⬜ pending |
| 56-04-02 | 04 | 3 | VER-03 | T-56-11 | Handoff + verification artifacts + traceability sync | mix task | `cd rulestead && mix verify.phase56` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Wave 0 deliverable is `verify.phase56.ex` itself (created in plan 56-01).

- [ ] `rulestead/lib/mix/tasks/verify.phase56.ex` — v1.6 merge gate
- [ ] `rulestead/mix.exs` `preferred_envs` for `verify.phase56`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide readability | VER-02 | Prose quality not string-matched | Spot-check four flow guides for Audience terminology and preview-basis limits |

*All critical support-truth boundaries are release_contract guarded.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

---
phase: 79
slug: lifecycle-deep-link-anchor-fix
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 79 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/intro_integration_spine_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase76` |
| **Estimated runtime** | ~2–5 minutes (phase76 union) |

---

## Sampling Rate

- **After every task commit:** Run intro contract test file
- **After every plan wave:** Run `mix verify.phase76`
- **Before `/gsd-verify-work`:** `mix verify.adopter`
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 79-01-01 | 01 | 1 | DOC-02 | T-79-01 | getting-started uses numbered §6 anchor | grep | `grep -q '#6-create-your-first-flag-lifecycle-required' guides/introduction/getting-started.md` | ✅ | ⬜ pending |
| 79-01-02 | 01 | 1 | DOC-02, INT-02 | T-79-02 | Contract test enforces slug; blocks regression | unit | `cd rulestead && mix test test/rulestead/intro_integration_spine_contract_test.exs` | ✅ | ⬜ pending |
| 79-01-03 | 01 | 1 | DOC-02 | — | Historical 77-01-PLAN anchor aligned | grep | `grep -q '#6-create-your-first-flag-lifecycle-required' .planning/phases/77-evaluation-and-lifecycle-doc-alignment/77-01-PLAN.md` | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- [x] ExUnit infrastructure exists
- [x] `intro_integration_spine_contract_test.exs` — from Phase 78
- [x] `mix verify.phase76` — from Phase 78

*No Wave 0 install — extend existing contract test only.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub rendered anchor lands on §6 | DOC-02 | Renderer not in CI | After merge, open getting-started on GitHub; click "Create your first flag" → should scroll to §6 |

---

## Validation Sign-Off

- [x] All tasks have automated verify
- [x] Sampling continuity: every task has automated verify
- [x] Wave 0: existing infrastructure covers requirements
- [x] No watch-mode flags
- [x] Feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution

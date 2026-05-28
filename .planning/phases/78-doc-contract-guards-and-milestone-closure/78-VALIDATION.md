---
phase: 78
slug: doc-contract-guards-and-milestone-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 78 — Validation Strategy

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
- **Before `/gsd-verify-work`:** `mix verify.adopter` + `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 78-01-01 | 01 | 1 | VER-01 | T-78-01 | Intro spine strings cannot regress silently | unit | `cd rulestead && mix test test/rulestead/intro_integration_spine_contract_test.exs` | ⬜ W0 | ⬜ pending |
| 78-01-02 | 01 | 1 | VER-02 | T-78-02 | phase76 flat union; no delegate to phase73 | integration | `cd rulestead && mix verify.phase76` | ⬜ W0 | ⬜ pending |
| 78-02-01 | 02 | 2 | VER-02 | T-78-03 | Live docs cite phase76 as current gate | unit | `grep -q verify.phase76 README.md MAINTAINING.md` | ✅ | ⬜ pending |
| 78-03-01 | 03 | 3 | AUD-01 | T-78-04 | INV-INTRO-01 closed only after green proof | manual+grep | `grep INV-INTRO-01 .planning/STATE.md` | ✅ | ⬜ pending |
| 78-03-02 | 03 | 3 | AUD-02 | — | v1.11 audit lists trust spine | file | `test -f .planning/v1.11-MILESTONE-AUDIT.md` | ⬜ W0 | ⬜ pending |

---

## Wave 0 Requirements

- [x] ExUnit infrastructure exists
- [ ] `intro_integration_spine_contract_test.exs` — created in 78-01-01
- [ ] `verify.phase76.ex` — created in 78-01-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| v1.11 audit narrative quality | AUD-02 | Prose review | Read trust spine section for accuracy |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity maintained
- [x] Wave 0 covers MISSING references (78-01)
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution

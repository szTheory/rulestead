---
phase: 74
slug: api-stability-catalog-sync
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 74 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (rulestead package) |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/release_contract_test.exs` |
| **Full suite command** | `cd rulestead && mix test` |
| **Estimated runtime** | ~15 seconds (contract file only) |

---

## Sampling Rate

- **After every task commit:** Run `cd rulestead && mix test test/rulestead/release_contract_test.exs`
- **After every plan wave:** Run full `cd rulestead && mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | API-01 | T-74-01 | Catalog lists all @root_exports names | unit | `mix test ...release_contract` (after 74-02) / grep | ✅ | ⬜ pending |
| 74-01-02 | 01 | 1 | API-01 | T-74-02 | Store/Policy/error/config surfaces documented | unit | grep api_stability.md | ✅ | ⬜ pending |
| 74-01-03 | 01 | 1 | API-03 | T-74-03 | Post-GA facades + product-boundary Runtime semver | unit | grep + optional post_ga test | ✅ | ⬜ pending |
| 74-02-01 | 02 | 2 | API-02, VER-03 | T-74-04 | Code→doc guards for exports/callbacks/types/config | unit | `mix test ...release_contract` | ✅ | ⬜ pending |
| 74-02-02 | 02 | 2 | API-02, VER-03 | T-74-05 | Doc→code guards for facades | unit | `mix test ...release_contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reader comprehension of facade vs core module list | API-03 | Prose quality | Skim new sections in api_stability for clarity |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution

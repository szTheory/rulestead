---
phase: 65
slug: host-preview-evidence-contract
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 65 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` |
| **Full suite command** | `cd rulestead && mix test test/rulestead/targeting/ test/rulestead/store/audience_impact_contract_test.exs test/rulestead/targeting/preview_evidence_contract_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command for files touched in that task
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | IMP-05 | T-65-01 | Resolver nil → no host I/O | unit | `mix test test/rulestead/targeting/preview_evidence_test.exs` | ❌ W0 | ⬜ pending |
| 65-01-02 | 01 | 1 | IMP-05 | T-65-02 | Oversized payload fail-closed | unit | same | ❌ W0 | ⬜ pending |
| 65-02-01 | 02 | 2 | IMP-05, IMP-06 | T-65-03 | impression_fingerprint in token | unit | `mix test test/rulestead/targeting/impact_preview_test.exs` | ✅ | ⬜ pending |
| 65-02-02 | 02 | 2 | IMP-05 | T-65-04 | PII stripped from impression summary | unit | same | ✅ | ⬜ pending |
| 65-03-01 | 03 | 3 | IMP-05 | T-65-05 | Store calls resolver before build | integration | `mix test test/rulestead/store/audience_impact_contract_test.exs` | ✅ | ⬜ pending |
| 65-03-02 | 03 | 3 | IMP-05 | — | Fake test resolver wired | integration | same | ✅ | ⬜ pending |
| 65-04-01 | 04 | 4 | IMP-05, IMP-06 | T-65-06 | Adapter parity @adapters loop | contract | `mix test test/rulestead/targeting/preview_evidence_contract_test.exs` | ❌ W0 | ⬜ pending |
| 65-04-02 | 04 | 4 | IMP-06 | T-65-07 | Evidence drift → stale preview | contract | same | ❌ W0 | ⬜ pending |
| 65-04-03 | 04 | 4 | GOV-05 (boundary) | T-65-08 | Blast radius ignores impressions | unit | `mix test test/rulestead/governance/blast_radius_threshold_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] ExUnit + RepoCase — existing
- [ ] `preview_evidence_test.exs` — created in 65-01
- [ ] `preview_evidence_contract_test.exs` — created in 65-04

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers MISSING references in plan 65-04
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution

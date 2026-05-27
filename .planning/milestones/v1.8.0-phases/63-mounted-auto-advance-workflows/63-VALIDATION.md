---
phase: 63
slug: mounted-auto-advance-workflows
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 63 — Validation Strategy

> Per-phase validation contract for feedback sampling during mounted auto-advance workflow execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (rulestead_admin LiveView tests) |
| **Config file** | `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs --only auto_advance` |
| **Full suite command** | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs && cd ../rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick rollouts/timeline auto_advance tests when present; otherwise `mix compile --warnings-as-errors` in both packages
- **After every plan wave:** Run full suite command above
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 63-01-01 | 01 | 1 | ADM-04 | T-63-01 | Panel renders mode copy without fleet-health claims | unit/LV | `mix test rollouts_test.exs --only auto_advance_panel` | ✅ | ✅ green |
| 63-01-02 | 01 | 1 | ADM-04 | T-63-02 | load_page assigns policy/tick/mode | unit/LV | `mix test rollouts_test.exs --only auto_advance_load` | ✅ | ✅ green |
| 63-02-01 | 02 | 2 | ADM-04 | T-63-03 | Policy save via upsert with authored fields | integration | `mix test rollouts_test.exs --only auto_advance_save` | ✅ | ✅ green |
| 63-02-02 | 02 | 2 | ADM-04 | T-63-04 | :advance_rollout capability gate blocks save | integration | `mix test rollouts_test.exs --only auto_advance_capability` | ✅ | ✅ green |
| 63-02-03 | 02 | 2 | ADM-04 | T-63-05 | Protected-env CR callout without auto-approve | integration | `mix test rollouts_test.exs --only auto_advance_protected` | ✅ | ✅ green |
| 63-03-01 | 03 | 3 | AUD-04 | T-63-06 | Auto rollout.advance labeled Automatic | unit/LV | `mix test timeline_test.exs --only auto_advance_label` | ✅ | ✅ green |
| 63-03-02 | 03 | 3 | AUD-04 | T-63-07 | Redaction allow-list for auto-advance keys | unit/LV | `mix test timeline_test.exs --only auto_advance_redaction` | ✅ | ✅ green |
| 63-04-01 | 04 | 4 | ADM-04, AUD-04 | — | Full contract matrix green | integration | Full suite command | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` — guardrail intervention patterns
- [x] `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` — automation vs manual labeling
- [x] `Rulestead.Fake` + `Control.set_now!/1` for window/tick timing
- [x] Phase 62 orchestration contract tests for core regression

New test tags/helpers added during 63-01 through 63-04 execution.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Copy tone review (no fleet/metrics language) | ADM-04 | Subjective operator UX | Scan panel HTML for banned phrases: "fleet healthy", "all signals green", "metrics dashboard" |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete (2026-05-27)

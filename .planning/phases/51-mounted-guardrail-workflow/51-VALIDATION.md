---
phase: 51
slug: mounted-guardrail-workflow
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix.LiveViewTest, Phoenix LiveView `1.1.30` |
| **Config file** | Standard Mix test setup; admin tests use `RulesteadAdmin.ConnCase` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test` plus `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guarded_rollout_test.exs test/rulestead/guardrails/decision_test.exs` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs`
- **After every plan wave:** Run `cd /Users/jon/projects/rulestead/rulestead_admin && mix test` plus `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guarded_rollout_test.exs test/rulestead/guardrails/decision_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-01 | 01 | 1 | ADM-01 | T-51-01 / T-51-02 | Guardrail status is read from core and missing data is not shown as healthy | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes | pending |
| 51-01-02 | 01 | 1 | ADM-01 | T-51-02 / T-51-03 | Mounted UI renders bounded normalized evidence without raw provider payloads | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes | pending |
| 51-01-03 | 01 | 1 | ADM-01 | T-51-04 | Percentage saves preserve authored `rollout.guardrails` | Regression | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes | pending |
| 51-02-01 | 02 | 1 | ADM-01 | T-51-01 / T-51-03 | Automatic guardrail audit rows are distinguishable from manual actions and remain redacted | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/timeline_test.exs` | yes | pending |

*Status: pending | green | red | flaky*

---

## Wave 0 Requirements

- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` — seed authored `rollout.guardrails` and guardrail status records for ADM-01 status and preservation tests.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs` — seed or assert automatic guardrail audit rows for ADM-01 manual/automatic distinction tests.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mounted rollout UI remains visually compact and not dashboard-like | ADM-01 | Visual density and page hierarchy require human review beyond text assertions | Open `/admin/flags/:key/rollouts?env=prod` in the mounted test host and confirm the guardrail panel is inside the existing rollout workflow, not a standalone dashboard |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing fixture references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-27

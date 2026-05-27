---
phase: 55
slug: mounted-operator-workflows
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (rulestead + rulestead_admin) |
| **Config file** | `rulestead/mix.exs`, `rulestead_admin/mix.exs` |
| **Quick run command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live test/rulestead_admin/live/flag_live/explain_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs` |
| **Full suite command** | `cd rulestead && mix verify.phase55 && cd ../rulestead_admin && mix test` |
| **Estimated runtime** | ~90 seconds (Fake adapter) |

---

## Sampling Rate

- **After every task commit:** Run the plan's `<automated>` verify command
- **After every plan wave:** Run `cd rulestead && mix verify.phase55`
- **Before `/gsd-verify-work`:** Full suite command above must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | ADM-01 | T-55-01 | Policy denies flag keys in used-by rows | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/index_test.exs` | ✅ | ⬜ pending |
| 55-01-02 | 01 | 1 | ADM-01 | T-55-02 | Routes registered before `/:key` | unit | `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs` | ✅ | ⬜ pending |
| 55-02-01 | 02 | 2 | ADM-02 | T-55-03 | Confirm requires core fingerprint params | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs` | ✅ | ⬜ pending |
| 55-02-02 | 02 | 2 | ADM-02 | T-55-04 | Delete preview has no apply CTA | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/` | ❌ W0 | ⬜ pending |
| 55-03-01 | 03 | 2 | ADM-03 | T-55-05 | Explain URL excludes traits | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/explain_test.exs` | ✅ | ⬜ pending |
| 55-03-02 | 03 | 2 | ADM-03 | T-55-06 | Rules missing-audience copy | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rules_test.exs` | ✅ | ⬜ pending |
| 55-04-01 | 04 | 3 | ADM-04 | T-55-07 | Compare shows dependency findings, no Apply | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/` | ✅ | ⬜ pending |
| 55-04-02 | 04 | 3 | VER prep | — | Phase verify includes admin + core | mix task | `cd rulestead && mix verify.phase55` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `rulestead_admin/test/rulestead_admin/live/audience_live/archive_confirm_test.exs` — archive confirm apply + reason
- [ ] `rulestead_admin/test/rulestead_admin/live/audience_live/delete_preview_test.exs` — fail-closed delete copy
- [ ] Extend `rulestead/lib/mix/tasks/verify.phase55.ex` — include admin test paths

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host `rs-*` token mapping | UI-SPEC visuals | CSS lives in host app | Spot-check one audience detail page in example host |
| Promotion CLI handoff | ADM-04 | Governed path is CLI/plan | Confirm compare has no Apply/Publish buttons |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

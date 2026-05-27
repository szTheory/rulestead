---
phase: 59
slug: mounted-governance-workflows
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 59 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir ~> 1.17) |
| **Config file** | `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/` |
| **Full suite command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/ test/rulestead_admin/live/change_request_live/show_test.exs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command for touched test file
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 59-01-01 | 01 | 1 | ADM-02 | T-59-01 | Panel never renders predicate/conditions | unit | `mix test test/rulestead_admin/components/governance_components_test.exs` | ❌ W0 | ⬜ pending |
| 59-01-02 | 01 | 1 | ADM-02 | T-59-02 | Governance loader fail-closed on assess error | unit | `mix test test/rulestead_admin/live/audience_live/governance_test.exs` | ❌ W0 | ⬜ pending |
| 59-02-01 | 02 | 2 | ADM-01 | T-59-03 | Governed preview CTA not "Continue to confirm" | LiveView | `mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs` | ✅ | ⬜ pending |
| 59-02-02 | 02 | 2 | ADM-01 | T-59-03 | Archive preview mirrors edit copy | LiveView | `mix test test/rulestead_admin/live/audience_live/archive_preview_test.exs` | ❌ W0 | ⬜ pending |
| 59-03-01 | 03 | 2 | ADM-01 | T-59-04 | No Apply when above threshold in prod | LiveView | `mix test test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs` | ❌ W0 | ⬜ pending |
| 59-03-02 | 03 | 2 | ADM-01 | T-59-05 | Post-submit navigates to CR show | LiveView | same file | ❌ W0 | ⬜ pending |
| 59-03-03 | 03 | 2 | ADM-03 | T-59-06 | Indeterminate blocks Apply and Submit | LiveView | same file | ❌ W0 | ⬜ pending |
| 59-04-01 | 04 | 3 | ADM-02 | T-59-07 | CR show uses frozen metadata only | LiveView | `mix test test/rulestead_admin/live/change_request_live/show_test.exs` | ✅ | ⬜ pending |
| 59-04-02 | 04 | 3 | ADM-03 | T-59-08 | Partial visibility blocks CR submit | LiveView | `mix test .../edit_confirm_governance_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ConnCase + Fake.Control infrastructure
- [ ] `test/rulestead_admin/components/governance_components_test.exs` — panel assigns/variants
- [ ] `test/rulestead_admin/live/audience_live/governance_test.exs` — mode/tier pure functions
- [ ] `test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs` — prod governed flows
- [ ] `test/rulestead_admin/live/audience_live/archive_preview_test.exs` — archive parity

*Wave 0 = create test files in 59-01/59-03 tasks if not present before assertions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual hierarchy on confirm | ADM-02 | Layout/tone subjective | Mount prod preview→confirm; verify panel above impact_preview |

*Primary behaviors are automated.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

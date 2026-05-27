---
phase: 67
slug: mounted-preview-evidence-workflows
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 67 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix LiveViewTest via RulesteadAdmin.ConnCase) |
| **Config file** | `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd rulestead_admin && mix test test/rulestead_admin/components/audience_components_test.exs` |
| **Full suite command** | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs test/rulestead_admin/live/audience_live/archive_preview_test.exs test/rulestead_admin/live/audience_live/delete_preview_test.exs test/rulestead_admin/live/audience_live/governance_test.exs` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run plan-specific quick command from Per-Task Verification Map
- **After every plan wave:** Run full audience preview test paths for completed waves
- **Before `/gsd-verify-work`:** Full suite command must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 67-01-01 | 01 | 1 | ADM-05 | T-67-01 | Sample/impression sections omit when empty | unit | `cd rulestead_admin && mix test test/rulestead_admin/components/audience_components_test.exs` | ✅ | ⬜ pending |
| 67-01-02 | 01 | 1 | ADM-05 | T-67-02 | Uncertainty uses core message; basis humanized | unit | same | ✅ | ⬜ pending |
| 67-02-01 | 02 | 2 | ADM-05 | T-67-03 | Edit preview renders evidence with resolver | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/edit_preview_test.exs` | ✅ | ⬜ pending |
| 67-02-02 | 02 | 2 | ADM-05 | T-67-04 | Archive preview fail-closed + drift unchanged | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/archive_preview_test.exs` | ✅ | ⬜ pending |
| 67-03-01 | 03 | 3 | ADM-05 | T-67-05 | Delete preview shows evidence + unsupported callout | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/delete_preview_test.exs` | ✅ | ⬜ pending |
| 67-03-02 | 03 | 3 | ADM-05 | — | Prod governance preview unchanged semantics | integration | `cd rulestead_admin && mix test test/rulestead_admin/live/audience_live/governance_test.exs` | ✅ | ⬜ pending |
| 67-04-01 | 04 | 4 | ADM-05 | T-67-06 | Confirm links preserve fingerprint params | integration | full suite command above | ✅ | ⬜ pending |
| 67-04-02 | 04 | 4 | ADM-05 | T-67-07 | No observability-product copy regression | integration | full suite command above | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `RulesteadAdmin.ConnCase` + `TestEndpoint`
- [x] `Rulestead.Fake.PreviewEvidenceResolver`
- [x] Audience preview test files (edit/archive/delete)

No new test framework install required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual spacing of sample table | ADM-05 | HTML assertions sufficient for content | Optional browser check on edit preview with resolver |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

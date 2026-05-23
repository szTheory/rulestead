---
phase: 33
slug: compare-drill-in-preview-identity-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 33 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Phoenix LiveView |
| **Config file** | `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`
- **After Wave 1:** Run `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | TEN-03 | T-33-01 | Summary drill-in links preserve `compare_token` with the existing mounted scope params | liveview | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs` | ✅ | ⬜ pending |
| 33-01-02 | 01 | 1 | TEN-03 | T-33-02 | Drill-in pages keep reviewed-preview and stale-preview behavior tied to the carried compare identity | liveview | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/show_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `33-01` | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Preserve compare summary preview identity into drill-in routes | `33-01-01`, `33-01-02` | Summary-link preservation plus drill-in state verification close the phase goal end to end |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| TEN-03 | `33-01-01`, `33-01-02` | Keeps the mounted compare preview identity explicit and consistent across the existing tenant-aware compare seam |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Preserve `compare_token` in summary drill-in links | `33-01-01` | Root-cause seam in `index.ex` |
| Keep stale-preview handling driven by shared compare findings | `33-01-02` | No UI-local stale state |
| Stay within mounted compare route scope only | `33-01-01`, `33-01-02` | No Phase 34 or public-promotion work |

### CONTEXT

No phase-local `33-CONTEXT.md` was present during planning. Roadmap, audit, repo guardrails, and prior compare-phase artifacts were treated as the operative context constraints.

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Respect Phase 33 roadmap boundary | all tasks | No Phase 34 audit-backfill work is planned here |
| Preserve linked-version two-package design | all tasks | Only mounted compare LiveView code and tests are in scope |
| Avoid standalone-admin drift | all tasks | No publish, packaging, or new admin workflow hub work |
| Reuse existing compare-token semantics | `33-01-01`, `33-01-02` | Drill-in uses the existing compare engine contract |

Audit result: all Phase 33 goal, requirement, research, and prompt-level constraints are covered by the single-plan set.

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-22

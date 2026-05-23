---
phase: 34
slug: milestone-auditability-backfill
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 34 - Validation Strategy

> Per-phase validation contract for evidence backfill and milestone traceability refresh.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | File-integrity checks + targeted ExUnit suites |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `test -f .planning/phases/30-mounted-admin-tenant-scope-closure/30-SUMMARY.md && test -f .planning/phases/30-mounted-admin-tenant-scope-closure/30-VERIFICATION.md && rg -n "30-SUMMARY.md|30-VERIFICATION.md|TEN-01|TEN-03" .planning/v1.1.0-MILESTONE-AUDIT.md` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs && cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-SUMMARY.md && test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-VERIFICATION.md && rg -n "status:|scores:|30-SUMMARY.md|30-VERIFICATION.md|TEN-01|TEN-03" /Users/jon/projects/rulestead/.planning/v1.1.0-MILESTONE-AUDIT.md` |
| **Estimated runtime** | ~20 seconds for targeted suites plus doc checks |

---

## Sampling Rate

- **After every task commit:** Run the task-specific file checks or targeted suites listed below.
- **After Wave 1:** Run the full Phase 30 targeted suite plus summary/verification file checks.
- **After Wave 2:** Run milestone-audit and active-doc integrity checks.
- **Before `$gsd-verify-work`:** Full suite plus final document integrity pass must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | artifact-1 | T-34-01 | Phase 30 regains canonical summary/frontmatter traceability | doc-integrity | `test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-SUMMARY.md && rg -n "^requirements-completed:|^# Phase 30 Execution Summary|30-VERIFICATION.md" /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-SUMMARY.md` | ✅ | ⬜ pending |
| 34-01-02 | 01 | 1 | artifact-2 | T-34-02 | Phase 30 verification is evidence-backed and reproducible | targeted-tests + doc-integrity | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs && cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-VERIFICATION.md && rg -n "TEN-01|TEN-03|score: 3/3 truths verified" /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-VERIFICATION.md` | ✅ | ⬜ pending |
| 34-02-01 | 02 | 2 | artifact-3 | T-34-03 | Refreshed milestone audit matches current completed tenancy evidence | doc-integrity | `rg -n "status:|scores:|30-SUMMARY.md|30-VERIFICATION.md|TEN-01|TEN-03|ready for closeout|not ready for closeout" /Users/jon/projects/rulestead/.planning/v1.1.0-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |
| 34-02-02 | 02 | 2 | artifact-3 | T-34-04 | Active roadmap/state route from the refreshed audit verdict, not stale plan state | doc-integrity | `rg -n "Phase 34|Milestone Auditability Backfill|Next Action|Latest Activity|ready to" /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `34-01` | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/environment_compare_live/index_test.exs test/rulestead_admin/live/environment_compare_live/show_test.exs && cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/store/compare_contract_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-SUMMARY.md && test -f /Users/jon/projects/rulestead/.planning/phases/30-mounted-admin-tenant-scope-closure/30-VERIFICATION.md` |
| 2 | `34-02` | `rg -n "status:|scores:|30-SUMMARY.md|30-VERIFICATION.md|TEN-01|TEN-03" /Users/jon/projects/rulestead/.planning/v1.1.0-MILESTONE-AUDIT.md && rg -n "Phase 34|Milestone Auditability Backfill|Next Action|Latest Activity" /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Restore missing Phase 30 verification artifact | `34-01-02` | Direct file creation plus rerunnable targeted suites |
| Restore missing Phase 30 summary/frontmatter artifact | `34-01-01` | Canonical summary shape check |
| Remove disagreement among milestone closeout inputs | `34-02-01`, `34-02-02` | Refreshes milestone audit and active planning routing |

### REQ

No new product requirements exist for Phase 34.

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| artifact-1 | `34-01-01` | Phase 30 summary/frontmatter backfill |
| artifact-2 | `34-01-02` | Phase 30 verification backfill |
| artifact-3 | `34-02-01`, `34-02-02` | Milestone audit and planning-state consistency |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Reconstruct Phase 30 artifacts before rerunning the milestone audit | `34-01-01`, `34-01-02` | Restores missing inputs first |
| Use rerunnable evidence instead of undocumented history | `34-01-02` | Targeted suites become the verification basis |
| Treat Phase 34 as planning-doc backfill only | all tasks | No production-code files are planned |

### CONTEXT

No phase-local `34-CONTEXT.md` was present during planning. Roadmap, milestone audit, requirements, state, and adjacent phase artifacts were treated as the operative context constraints.

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Respect Phase 34 roadmap boundary | all tasks | No new tenancy behavior or publish work |
| Preserve linked-version two-package design | all tasks | Only `.planning/` output plus rerun of existing targeted suites |
| Keep milestone evidence reproducible | `34-01-02`, `34-02-01` | Commands and doc checks are explicit |

Audit result: all Phase 34 goal and artifact-repair duties are covered by the two-plan set.

---

## Wave 0 Requirements

Existing targeted suites and planning-doc patterns cover all phase needs.

---

## Manual-Only Verifications

All expected Phase 34 behaviors have automated document or targeted-suite checks.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-23

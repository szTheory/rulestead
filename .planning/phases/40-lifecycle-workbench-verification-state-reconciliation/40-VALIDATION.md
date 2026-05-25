---
phase: 40
slug: lifecycle-workbench-verification-state-reconciliation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 40 - Validation Strategy

> Per-phase validation contract for mounted lifecycle workbench evidence closure, Phase 37 traceability cleanup, and post-evidence milestone-state reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit LiveView suites in `rulestead_admin` plus file-integrity checks across `.planning/` |
| **Config file** | `rulestead_admin/test/test_helper.exs`, `rulestead_admin/config/test.exs` |
| **Quick run command** | `test -f /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md && rg -n "LIF-03|LIF-04|score: 4/4 truths verified|cleanup_preview_test\\.exs|cleanup_confirm_test\\.exs" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md && rg -n "requirements-completed: \\[LIF-03\\]|requirements-completed: \\[LIF-04\\]" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-02-SUMMARY.md && rg -n "LIF-03 \\| Phase 40 \\| Complete|LIF-04 \\| Phase 40 \\| Complete|ready for closeout|Phase 37.*Complete" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` |
| **Estimated runtime** | ~30 seconds after compile warm-up for the targeted Phase 37 suites plus planning-doc checks |

---

## Sampling Rate

- **After the verification-artifact task:** Run the full targeted Phase 37 LiveView suite plus file-content checks for `37-VERIFICATION.md`.
- **After the summary-mapping task:** Run `rg` checks on `37-01-SUMMARY.md` and `37-02-SUMMARY.md` to confirm the intended requirement split.
- **After the milestone-state task:** Run the planning-doc integrity checks so `REQUIREMENTS.md`, `v1.2.0-MILESTONE-AUDIT.md`, `ROADMAP.md`, and `STATE.md` all agree.
- **Before `$gsd-verify-work`:** Re-run the full suite command and confirm there is no remaining “Phase 37 unverified” or `LIF-03`/`LIF-04` pending language in active docs.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 40-01-01 | 01 | 1 | LIF-03, LIF-04 | T-40-01 | Phase 37 regains a reproducible verification report that proves the mounted lifecycle queue, cleanup review, preview, confirm, and queue-return flow from current evidence | targeted-ui + doc-integrity | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md && rg -n "LIF-03|LIF-04|score: 4/4 truths verified|cleanup_preview_test\\.exs|cleanup_confirm_test\\.exs" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md` | ✅ | ⬜ pending |
| 40-01-02 | 01 | 1 | LIF-03, LIF-04 | T-40-02 | Phase 37 per-plan summary frontmatter maps requirements exactly so the evidence chain is not ambiguous | doc-integrity | `rg -n "requirements-completed: \\[LIF-03\\]|requirements-completed: \\[LIF-04\\]" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-02-SUMMARY.md && ! rg -n "LIF-05" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-02-SUMMARY.md` | ✅ | ⬜ pending |
| 40-01-03 | 01 | 1 | LIF-03, LIF-04 | T-40-03 | Active milestone traceability closes `LIF-03`/`LIF-04`, marks Phase 37 verified, and routes toward milestone closeout without claiming shipment | doc-integrity | `rg -n "LIF-03 \\| Phase 40 \\| Complete|LIF-04 \\| Phase 40 \\| Complete|ready for closeout|Phase 37.*Complete|\\$gsd-complete-milestone" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md && ! rg -n "Phase 37.*Unverified|LIF-03.*Pending|LIF-04.*Pending" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `40-01` | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-VERIFICATION.md && rg -n "requirements-completed: \\[LIF-03\\]|requirements-completed: \\[LIF-04\\]" /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-01-SUMMARY.md /Users/jon/projects/rulestead/.planning/phases/37-mounted-admin-lifecycle-workbench/37-02-SUMMARY.md && rg -n "LIF-03 \\| Phase 40 \\| Complete|LIF-04 \\| Phase 40 \\| Complete|ready for closeout" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Write the missing Phase 37 verification artifact | `40-01-01` | Direct file creation plus rerunnable targeted Phase 37 suites |
| Correct Phase 37 traceability drift, including the summary frontmatter typo and requirement mapping | `40-01-02` | Phase-local frontmatter integrity is checked explicitly |
| Reconcile roadmap, requirements, and state closeout posture once the evidence exists | `40-01-03` | Active docs move together to “ready for closeout” |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-03 | `40-01-01`, `40-01-02`, `40-01-03` | Verification artifact proves workbench visibility flow; traceability and milestone docs record it accurately |
| LIF-04 | `40-01-01`, `40-01-02`, `40-01-03` | Verification artifact proves explicit archive flow; traceability and milestone docs record it accurately |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Verification artifact first, traceability second | `40-01-01`, `40-01-03` | Prevents doc claims without proof |
| Correct phase-local mapping before milestone-wide mapping | `40-01-02`, `40-01-03` | Keeps evidence chain internally consistent |
| Route to closeout, not shipment | `40-01-03` | Milestone becomes ready for closeout only |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Close the Phase 37 evidence gap only | all tasks | No new lifecycle feature scope |
| Move `LIF-03` and `LIF-04` from partial to evidenced | `40-01-01`, `40-01-03` | Verification artifact plus active-doc reconciliation |
| Remove planning drift | `40-01-02`, `40-01-03` | Summary/frontmatter and milestone-state cleanup |

Audit result: the single-plan set covers the full Phase 40 boundary without widening into new product implementation or future-milestone work.

---

## Wave 0 Requirements

Existing Phase 37 summaries, validation strategy, targeted test suites, and active milestone docs provide everything needed. No additional scaffold is required.

---

## Manual-Only Verifications

No manual-only verification is required if the targeted Phase 37 suites pass and the planning-doc integrity checks all return matches consistent with the new evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-24

---
phase: 37
slug: mounted-admin-lifecycle-workbench
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 37 - Validation Strategy

> Per-phase validation contract for mounted lifecycle queue state, route-backed archive preview/confirm flows, queue-return continuity, and audit-safe operator messaging.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit LiveView suites in `rulestead_admin` plus existing core archive command coverage in `rulestead` |
| **Config file** | `rulestead_admin/test/test_helper.exs`, `rulestead_admin/config/test.exs`, `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/cleanup_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` |
| **Estimated runtime** | ~30 seconds after compile warm-up for the targeted Phase 37 suites |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command in the verification map below.
- **After Wave 1:** Run all index/show/cleanup suites together to confirm queue state and review-entry semantics still align.
- **After Wave 2:** Run the full Phase 37 LiveView suite so preview, confirm, and queue return behavior stay coherent end to end.
- **Before `$gsd-verify-work`:** Re-run the full suite command and confirm the plan artifacts still match the delivered route/state contract.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | LIF-03 | T-37-01, T-37-02 | Queue links preserve canonical `return_to` state and exact-owner semantics without introducing a second lifecycle filter dialect | targeted-ui | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs` | ✅ | ⬜ pending |
| 37-01-02 | 01 | 1 | LIF-03, LIF-04 | T-37-03 | Cleanup is the canonical review surface, preserves queue context, and links into route-backed preview instead of mutating inline | targeted-ui | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/cleanup_test.exs` | ✅ | ⬜ pending |
| 37-02-01 | 02 | 2 | LIF-04 | T-37-05 | Preview renders lifecycle evidence, archive consequences, preserves queue carry-through, and redirects unauthorized users before destructive review UI renders | targeted-ui | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` | ❌ W0 | ⬜ pending |
| 37-02-02 | 02 | 2 | LIF-04 | T-37-04, T-37-05, T-37-06 | Confirm requires reason + production typed key, blocks stale preview drift, redirects unauthorized users before confirm render, archives explicitly, and returns to the queue with audit-linked outcome visibility | targeted-ui | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs test/rulestead_admin/live/flag_live/index_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `37-01` | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs` |
| 2 | `37-02` | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Shareable lifecycle filters, owner filters, and archive-readiness views inside one canonical workbench | `37-01-01`, `37-01-02` | Index/show/cleanup queue-state and review-entry coverage |
| Detail-page lifecycle projection and cleanup recommendations without turning detail into the action hub | `37-01-01`, `37-01-02` | Detail routes into cleanup while staying read-first |
| Explicit archive/cleanup actions with preview, reason, and audit continuity | `37-02-01`, `37-02-02` | Preview/confirm plus queue-return outcome coverage |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-03 | `37-01-01`, `37-01-02` | Canonical lifecycle queue, exact owner semantics, shareable mounted filters |
| LIF-04 | `37-01-02`, `37-02-01`, `37-02-02` | Explicit previewable audited archive flow with uncertainty preserved |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| One inventory, multiple presets | `37-01-01` | `FlagLive.Index` remains the only lifecycle workbench |
| Canonical `return_to` path handling | `37-01-01`, `37-01-02`, `37-02-02` | Shared session/path helper and cross-route assertions |
| Cleanup as review, preview/confirm as action routes | `37-01-02`, `37-02-01`, `37-02-02` | Route-backed workflow only |
| Success returns to queue with explicit archived visibility and audit linkage | `37-02-02` | Outcome banner + row highlight + include_archived coverage |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| D-04 to D-07 | `37-01-01`, `37-01-02` | One canonical workbench, route-backed state, calm detail posture |
| D-08 to D-10 | `37-01-01` | Exact owner filter, no bulk semantics |
| D-15 to D-19 | `37-02-01`, `37-02-02` | Preview evidence, per-route capability gates, confirm revalidation, queue return, patch-vs-navigate discipline |
| D-20 to D-23 | `37-02-02` | Required reason, production typed confirmation, outcome visibility, route-backed return |

Audit result: the plan set covers every locked Phase 37 delivery area without drifting into bulk actions, standalone admin surfaces, or Phase 38 documentation work.

---

## Wave 0 Requirements

- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` — create dedicated preview-route coverage for readiness rendering, consequence copy, `return_to` carry-through, and unauthorized redirect behavior.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` — create governed confirm-route coverage for reason/typed-key validation, revalidation drift, unauthorized redirect behavior, archive apply, and success return.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` — extend queue assertions for lifecycle presets, outcome banner rendering, archived visibility, and row highlight on return.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` — extend queue-preserving cleanup entrypoint assertions from calm detail.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` — replace Phase 36 advisory-only expectations with review-entry and preview-link coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Outcome banner/highlight feels explicit rather than alarming, and the archived flag does not “disappear” after return | LIF-04 | Tone and visual continuity are easier to judge by reading the mounted page than by string assertions alone | Archive one prod and one non-prod fixture from the lifecycle queue, verify the returned queue keeps archived visibility explicit, and confirm the banner plus row highlight communicate success and audit linkage without implying hidden automation |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-23

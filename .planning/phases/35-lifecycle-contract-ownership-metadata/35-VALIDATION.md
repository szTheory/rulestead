---
phase: 35
slug: lifecycle-contract-ownership-metadata
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 35 - Validation Strategy

> Per-phase validation contract for authored ownership/lifecycle metadata, bounded audit summaries, and mounted-admin projection alignment.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit suites across `rulestead` and `rulestead_admin` |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/audit_event_governance_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/show_test.exs` |
| **Estimated runtime** | ~30 seconds for the targeted Phase 35 suites after compile warm-up |

---

## Sampling Rate

- **After every task commit:** Run the task-specific suite listed below.
- **After Wave 1:** Run all authored contract and mounted form suites.
- **After Wave 2:** Run audit, projector, and mounted detail suites.
- **Before `$gsd-verify-work`:** Run the full suite command and confirm roadmap/plan artifacts still match the finished code.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | LIF-01 | T-35-01, T-35-04 | Authored ownership/lifecycle contract stays bounded, explicit, and free of machine lifecycle status persistence | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs` | ✅ | ⬜ pending |
| 35-01-02 | 01 | 1 | LIF-01 | T-35-02, T-35-03 | Commands, adapters, and mounted authoring preserve one canonical ownership/lifecycle payload | targeted-core+ui | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store_ecto_admin_test.exs test/rulestead/admin_contract_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs` | ✅ | ⬜ pending |
| 35-02-01 | 02 | 2 | LIF-01 | T-35-05, T-35-06 | Audit rows expose bounded lifecycle/ownership transition summaries without schema sprawl or sensitive context leakage | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/store_ecto_admin_test.exs` | ✅ | ⬜ pending |
| 35-02-02 | 02 | 2 | LIF-01 | T-35-07, T-35-08 | Projector and mounted detail render authored truth without pulling in runtime hot-path or future-phase semantics | targeted-core+ui | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/show_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `35-01` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs` |
| 2 | `35-02` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/show_test.exs` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Bounded authored ownership contract that stays host-friendly and auditable | `35-01-01`, `35-01-02`, `35-02-01` | Durable ownership metadata, normalization, and audit continuity |
| Explicit lifecycle intent independent from the runtime hot path | `35-01-01`, `35-01-02`, `35-02-02` | Advisory defaults + authored facts + shared projector |
| Mounted-admin contract alignment without Phase 36/37 scope creep | `35-01-02`, `35-02-02` | Authoring and detail alignment only; filters/workbench deferred |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-01 | `35-01-01`, `35-01-02`, `35-02-01`, `35-02-02` | Authored ownership/lifecycle truth across writes, reads, audit, and mounted-admin surfaces |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Use authored `ownership` and `lifecycle` embeds on `flags` | `35-01-01`, `35-01-02` | Follows the recommended Ecto embedded-schema path |
| Keep lifecycle defaults advisory and admin-only | `35-01-01`, `35-01-02` | `LifecycleDefaults` seam and form override controls |
| Add bounded audit summaries inside the existing envelope | `35-02-01` | Central summary generation in `AuditEvent.metadata/1` |
| Keep `Rulestead.Admin.Lifecycle` as the derived projector | `35-02-02` | Detail/projection alignment through existing seam |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| D-01, D-02 | all tasks | One coherent Phase 35-only contract path |
| D-03 to D-08 | `35-01-01`, `35-01-02`, `35-02-02` | Bounded host-owned ownership metadata, no runtime owner resolution |
| D-09 to D-18 | `35-01-01`, `35-01-02`, `35-02-02` | Authored lifecycle truth plus admin-only suggestions, no computed persistence |
| D-19 to D-23 | `35-02-01` | Stable audit envelope with bounded transition summaries |
| D-24, D-25 | `35-01-01`, `35-01-02`, `35-02-01`, `35-02-02` | Legacy owner compatibility, no auto-archive/cleanup |

Audit result: all Phase 35 goal items, requirement coverage, research recommendations, and locked context decisions are covered by the two-plan set. Deferred Phase 36-38 items remain intentionally excluded.

---

## Wave 0 Requirements

Existing core/admin test harnesses cover the planned work. No extra Wave 0 scaffold is required.

---

## Manual-Only Verifications

All planned behaviors have automated verification commands. Optional human review can confirm wording and mounted-admin copy after execution, but it is not required for phase completion.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-23

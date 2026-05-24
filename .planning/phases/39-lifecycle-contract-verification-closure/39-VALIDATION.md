---
phase: 39
slug: lifecycle-contract-verification-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 39 - Validation Strategy

> Per-phase validation contract for Phase 35 evidence reconstruction and active milestone traceability reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | File-integrity checks + targeted ExUnit suites |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `test -f /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md && rg -n "LIF-01|score: 4/4 truths verified|admin_lifecycle_test\\.exs|form_test\\.exs|show_test\\.exs" /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/show_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md && rg -n "LIF-01|35-VERIFICATION\\.md|Phase 35|verified" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` |
| **Estimated runtime** | ~30 seconds after compile warm-up for the targeted Phase 35 suites plus doc checks |

---

## Sampling Rate

- **After the verification-artifact task:** Run the targeted Phase 35 suites plus file-content checks for `35-VERIFICATION.md`.
- **After the traceability task:** Run the milestone-doc `rg` checks to confirm `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, and the milestone audit all agree.
- **Before `$gsd-verify-work`:** Re-run the full suite command and verify there is no stale Phase 38 next-action routing left in active planning docs.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | LIF-01 | T-39-01 | Phase 35 regains a reproducible verification report that proves authored ownership/lifecycle truth across writes, reads, audit, and mounted-admin projection | targeted-tests + doc-integrity | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/show_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md && rg -n "LIF-01|score: 4/4 truths verified|admin_lifecycle_test\\.exs|audit_event_governance_test\\.exs|form_test\\.exs|show_test\\.exs" /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md` | ✅ | ⬜ pending |
| 39-01-02 | 01 | 1 | LIF-01 | T-39-02, T-39-03 | Active milestone traceability closes `LIF-01` without claiming `v1.2.0` is fully complete before the Phase 37/40 gap is resolved | doc-integrity | `rg -n "LIF-01|Complete|Phase 39|Phase 40|not ready for closeout|missing Phase 37|remaining blocker" /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `39-01` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/show_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md && rg -n "LIF-01|Phase 35|verified|not ready for closeout|Phase 40" /Users/jon/projects/rulestead/.planning/phases/35-lifecycle-contract-ownership-metadata/35-VERIFICATION.md /Users/jon/projects/rulestead/.planning/REQUIREMENTS.md /Users/jon/projects/rulestead/.planning/v1.2.0-MILESTONE-AUDIT.md /Users/jon/projects/rulestead/.planning/ROADMAP.md /Users/jon/projects/rulestead/.planning/STATE.md` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Write the missing Phase 35 verification artifact | `39-01-01` | Direct file creation plus rerunnable targeted suites |
| Reconcile `LIF-01` milestone traceability with verified evidence | `39-01-02` | Active requirements and audit/state routing all updated from the new artifact |
| Keep milestone closeout language honest | `39-01-02` | `LIF-03` and `LIF-04` remain open |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-01 | `39-01-01`, `39-01-02` | Verification artifact proves the contract; active docs record it accurately |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Verification artifact first, traceability second | `39-01-01`, `39-01-02` | Prevents active-doc claims without evidence |
| Use fresh reruns, not historical inference | `39-01-01` | Required targeted suites are explicit |
| Keep milestone incomplete beyond `LIF-01` | `39-01-02` | Phase 37/40 gap remains visible |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Close the Phase 35 evidence gap only | all tasks | No new lifecycle behavior or UI work |
| Move `LIF-01` from partial to evidenced | `39-01-01`, `39-01-02` | Verification artifact plus active-doc reconciliation |
| Do not widen into milestone-complete claims | `39-01-02` | Remaining blocker stays explicit |

Audit result: the single-plan set covers the full Phase 39 boundary without widening into Phase 37 verification or new product implementation.

---

## Wave 0 Requirements

Existing Phase 35 summaries, validation strategy, targeted test suites, and active milestone docs provide everything needed. No additional scaffold is required.

---

## Manual-Only Verifications

No manual-only verification is required if the targeted Phase 35 suites pass and the planning-doc integrity checks all return matches consistent with the new evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-24

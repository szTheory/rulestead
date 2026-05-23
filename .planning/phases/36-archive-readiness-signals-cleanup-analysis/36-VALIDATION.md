---
phase: 36
slug: archive-readiness-signals-cleanup-analysis
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 36 - Validation Strategy

> Per-phase validation contract for archive-readiness classification, uncertainty handling, mounted-admin reporting, and read-only CLI lifecycle reporting.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Targeted ExUnit suites across `rulestead` and `rulestead_admin` |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead/config/test.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test && cd /Users/jon/projects/rulestead/rulestead_admin && mix test` |
| **Estimated runtime** | ~25 seconds for the per-task quick check after compile warm-up |

---

## Sampling Rate

- **After every task commit:** Run the task-specific automated command in the map below, keeping the default quick check at or under the 30-second feedback target.
- **After every plan wave:** Run the full suite command for both sibling packages.
- **Before `$gsd-verify-work`:** Full suite must be green and mounted-admin/CLI output must still match the shared projection contract.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-01 | 01 | 1 | LIF-02 | T-36-00 | Accepted code-reference uploads persist a bounded scan receipt even when the scan finds zero references, and unauthorized/malformed uploads cannot forge fresh-scan evidence | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/webhooks/code_refs_plug_test.exs` | ✅ | ⬜ pending |
| 36-01-02 | 01 | 1 | LIF-02 | T-36-01, T-36-02 | Archive-readiness keeps authored posture, freshness evidence, and guidance separate and only treats “no refs” as positive when a recent scan receipt exists | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs` | ✅ | ⬜ pending |
| 36-01-03 | 01 | 1 | LIF-02 | T-36-03 | Ecto and Fake list/detail payloads expose the same readiness, evidence-quality, reasons, unknowns, blockers, next-action contract, and scan-freshness semantics | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/store_ecto_admin_test.exs test/rulestead/store/fake_contract_test.exs` | ✅ | ⬜ pending |
| 36-02-01 | 02 | 2 | LIF-02 | T-36-04, T-36-05 | Mounted-admin list/detail/cleanup surfaces remain read-only advisory views with shareable filters and explicit uncertainty language for stale/no-scan code-reference evidence | targeted-ui | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs` | ✅ | ⬜ pending |
| 36-02-02 | 02 | 2 | LIF-02 | T-36-06 | `mix rulestead.lifecycle` renders stable text and JSON output without mutation flags, preserves machine-readable schema versioning, and distinguishes fresh empty scans from stale/missing scans | targeted-core | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `36-01` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/store/fake_contract_test.exs test/rulestead/webhooks/code_refs_plug_test.exs` |
| 2 | `36-02` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/show_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Advisory archive-readiness from lifecycle metadata, evaluation evidence, and code references | `36-01-01`, `36-01-02` | Shared projector and store payload work |
| Read-only admin/CLI reporting surface for stale and cleanup review | `36-02-01`, `36-02-02` | Mounted-admin and Mix task consume the same contract |
| Recommendation-heavy next-action guidance with explicit uncertainty | `36-01-01`, `36-02-01`, `36-02-02` | Reasons, blockers, unknowns, and next actions stay explainable |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-02 | `36-01-01`, `36-01-02`, `36-02-01`, `36-02-02` | Bounded lifecycle/archive-readiness guidance without stale-only collapse |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Extend `Rulestead.Admin.Lifecycle` instead of adding a second engine | `36-01-01`, `36-01-02` | Shared projector remains the classification seam |
| Model code-reference freshness gaps as uncertainty | `36-01-01`, `36-02-01`, `36-02-02` | UI and CLI must distinguish no refs vs no fresh scan |
| Keep one canonical JSON-backed payload for UI and CLI | `36-01-02`, `36-02-01`, `36-02-02` | Prevents Ecto/Fake/UI/CLI drift |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| D-01 to D-08 | `36-01-01`, `36-01-02` | Read-only guidance, no persisted computed truth, stale as one signal |
| D-09 to D-15 | `36-01-01`, `36-02-01`, `36-02-02` | Bounded readiness/evidence vocabulary and explainability |
| D-16 to D-24 | `36-01-01`, `36-01-02`, `36-02-01`, `36-02-02` | Missing evidence degrades confidence, never boosts readiness; D-17 now has an explicit scan-receipt source of truth |
| D-25 to D-35 | `36-02-01`, `36-02-02` | One primary next action, read-only CLI/reporting, no mutation commands |
| D-36 to D-39 | `36-01-01`, `36-01-02`, `36-02-01` | Shared projector seam and reusable payload contract |

Audit result: all current Phase 36 goal items, requirement coverage, research recommendations, and locked context decisions are represented in the expected plan set, including explicit D-17 coverage through the new scan-receipt seam. Phase 37 mutation and preview flows remain intentionally excluded.

---

## Wave 0 Requirements

- [ ] `rulestead/test/rulestead/admin_lifecycle_test.exs` — add archive-readiness coverage for split freshness buckets, evidence quality, blockers, unknowns, and withheld recommendations.
- [ ] `rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` — add zero-reference scan receipt coverage and ensure invalid/unauthorized uploads do not advance freshness evidence.
- [ ] `rulestead/test/rulestead/store_ecto_admin_test.exs` — add list/detail assertions for distinct lifecycle vs stale vs readiness payload/filter semantics.
- [ ] `rulestead/test/rulestead/store/fake_contract_test.exs` — extend Fake contract coverage to prove readiness payload and advisory filter parity with the Ecto adapter.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` — add readiness/evidence filter and badge assertions with URL-state preservation.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs` — add reasons, unknowns, blockers, and recommended-next-action assertions.
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` — add advisory cleanup-read-surface assertions that avoid Phase 37 mutation scope creep.
- [ ] `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` — create text/json contract coverage and exit-code assertions for the new read-only lifecycle report task.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mounted-admin copy stays calm and clearly uncertainty-first when evidence is weak or conflicting | LIF-02 | Wording/tone regressions are easier to spot by reading the rendered screens than by only asserting strings in isolation | Visit the flag inventory, detail, and cleanup views for one active flag, one uncertain flag, and one archive candidate; confirm the primary recommendation, blockers, and unknowns read as advisory rather than authoritative |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies
- [x] Sampling continuity preserved
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-23

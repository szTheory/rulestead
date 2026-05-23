---
phase: 38
slug: lifecycle-docs-runbooks-verification
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 38 - Validation Strategy

> Per-phase validation contract for lifecycle docs coherence, release-surface verification, and milestone closeout evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | File-content checks + targeted ExUnit contract suites |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `rg -n "lifecycle|birth to retirement|mounted admin companion|mix rulestead.lifecycle" /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/guides/flows/admin-ui.md /Users/jon/projects/rulestead/guides/flows/explainability.md /Users/jon/projects/rulestead/guides/recipes/testing.md` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md` |
| **Estimated runtime** | ~20-30 seconds for targeted suites plus file checks |

---

## Sampling Rate

- **After every docs task commit:** run the relevant `rg` file checks for newly touched docs.
- **After docs/readme wave:** run file-content checks across root/package READMEs and shared guides.
- **After verification/test wave:** run the full targeted ExUnit suite for lifecycle CLI, release contract, publish/parity, and admin mount seams.
- **Before `$gsd-verify-work`:** full suite plus phase-local evidence artifact existence check must be green.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 38-01-01 | 01 | 1 | LIF-05 | T-38-01 | root/package entrypoints route readers into one canonical lifecycle story without standalone-admin drift | doc-integrity | `rg -n "lifecycle|birth to retirement|mounted admin companion" /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md` | ✅ | ⬜ pending |
| 38-01-02 | 01 | 1 | LIF-05 | T-38-02 | lifecycle spine guide exists and teaches least-surprise defaults plus explicit archive posture | doc-integrity | `rg -n "archive_candidate|host owns|preview|audit|archive-readiness" /Users/jon/projects/rulestead/guides/**/*.md` | ✅ | ⬜ pending |
| 38-02-01 | 02 | 2 | LIF-05 | T-38-03 | supporting runbooks keep admin, explainability, testing, and host integration vocabulary aligned | doc-integrity | `rg -n "mix rulestead.lifecycle|\\?env=|read-only|mounted admin" /Users/jon/projects/rulestead/guides/flows/admin-ui.md /Users/jon/projects/rulestead/guides/flows/explainability.md /Users/jon/projects/rulestead/guides/recipes/testing.md /Users/jon/projects/rulestead/guides/introduction/getting-started.md` | ✅ | ⬜ pending |
| 38-03-01 | 03 | 3 | LIF-05 | T-38-04 | lifecycle CLI contract remains versioned, aligned to docs vocabulary, and read-only | targeted-tests | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` | ✅ | ⬜ pending |
| 38-03-02 | 03 | 3 | LIF-05 | T-38-05 | release contract and mounted-admin host seam verify lifecycle discoverability without internal UI lock-in | targeted-tests | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs` | ✅ | ⬜ pending |
| 38-03-03 | 03 | 3 | LIF-05 | T-38-06 | milestone closeout evidence is phase-local, machine-backed, and traceable to exact checks | doc-integrity | `test -f /Users/jon/projects/rulestead/.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md && rg -n "LIF-05|README.md|rulestead.lifecycle|admin_mount_test" /Users/jon/projects/rulestead/.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `38-01` | `rg -n "lifecycle|birth to retirement|mounted admin companion|host owns" /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md /Users/jon/projects/rulestead/guides/**/*.md` |
| 2 | `38-02` | `rg -n "mix rulestead.lifecycle|archive_candidate|preview|audit|\\?env=" /Users/jon/projects/rulestead/guides/**/*.md /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md` |
| 3 | `38-03` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs && cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs && test -f /Users/jon/projects/rulestead/.planning/phases/38-lifecycle-docs-runbooks-verification/38-VERIFICATION.md` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| docs and runbooks teach one lifecycle operator story | `38-01`, `38-02` | spine guide plus satellite updates |
| release-surface verification covers docs, CLI, and mounted admin | `38-03` | targeted contract suites and file checks |
| milestone closeout evidence is explicit and traceable | `38-03` | phase-local verification artifact required |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| LIF-05 | `38-01`, `38-02`, `38-03` | discoverability, runbooks, and verification all required |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| lifecycle spine plus satellites | `38-01`, `38-02` | docs architecture reused rather than reinvented |
| public seam verification over browser-heavy E2E | `38-03` | targeted ExUnit suites only |
| phase-local closeout evidence | `38-03` | explicit verification artifact required |

### CONTEXT

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| preserve sibling-package posture | all plans | root guides own shared story; admin stays mounted companion |
| no new lifecycle capabilities | all plans | docs/tests/evidence only |
| keep archive posture advisory and explicit | `38-01`, `38-02`, `38-03` | wording and contract tests both enforce this |

Audit result: the recommended three-plan split covers the full Phase 38 scope without widening into product or UI redesign work.

---

## Wave 0 Requirements

Existing README/guide structure and targeted release-contract tests provide the baseline needed for execution. No additional infrastructure bootstrap is required.

---

## Manual-Only Verifications

No manual-only verification is required if the phase produces the expected docs, contract tests, and `38-VERIFICATION.md` evidence artifact.

---

## Validation Sign-Off

- [x] All expected task areas have automated verification paths
- [x] Sampling continuity preserved
- [x] No browser-heavy E2E dependency introduced
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-23

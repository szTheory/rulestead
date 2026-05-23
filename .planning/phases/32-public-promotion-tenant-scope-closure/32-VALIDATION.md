---
phase: 32
slug: public-promotion-tenant-scope-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/test/test_helper.exs` |
| **Quick run command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs` |
| **Full suite command** | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs`
- **After Wave 1:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs`
- **After Wave 2:** Run `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 25 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | TEN-01 / TEN-03 | T-32-01 | Public `plan_promotion/3` forwards only `flag_keys` and explicit `tenant_key` into compare without widening the option surface | unit | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | TEN-01 / TEN-03 | T-32-02 | Saved promote plans generated from the public flow keep top-level `tenant_key` through normalization and stale replay handling | integration | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs` | ✅ | ⬜ pending |
| 32-02-01 | 02 | 2 | TEN-01 / TEN-03 | T-32-03 | Direct and governed replay rebuild commands from the saved plan's existing `tenant_key` and preserve parity across apply/change-request paths | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs` | ✅ | ⬜ pending |
| 32-02-02 | 02 | 2 | TEN-01 / TEN-03 | T-32-04 | Mix-task and release-surface regressions prove the public wrapper and documented runtime contract preserve the tenant-scoped plan/apply flow without CLI widening | contract | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave Commands

| Wave | Plans | Command |
|------|-------|---------|
| 1 | `32-01` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs` |
| 2 | `32-02` | `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/promotion/apply_test.exs test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs test/rulestead/release_contract_test.exs` |

---

## Source Coverage Audit

### GOAL

| Source Item | Covered By | Notes |
|-------------|------------|-------|
| Preserve explicit tenant scope through compare, saved-plan serialization, and apply handoff | `32-01-01`, `32-01-02`, `32-02-01` | End-to-end path is split across generation then replay parity |
| Do not silently drop tenant scope in public promotion plans | `32-01-01`, `32-01-02` | Public façade is the confirmed root-cause seam |

### REQ

| Requirement | Covered By | Notes |
|-------------|------------|-------|
| TEN-01 | `32-01-01`, `32-01-02`, `32-02-01`, `32-02-02` | Explicit tenant scope remains available in public runtime/apply flows |
| TEN-03 | `32-01-01`, `32-01-02`, `32-02-01`, `32-02-02` | Reuses the existing bounded tenant/provenance contract rather than widening the surface |

### RESEARCH

| Research Item | Covered By | Notes |
|---------------|------------|-------|
| Fix `Rulestead.plan_promotion/3` to forward `tenant_key` alongside `flag_keys` | `32-01-01` | Primary code seam from `32-RESEARCH.md` |
| Reuse top-level `tenant_key` in `Manifest.Plan` instead of a new tenant dialect | `32-01-02`, `32-02-01` | Public plan and replay tasks both lock this |
| Verify direct apply, governed replay, and programmatic Mix wrappers | `32-02-01`, `32-02-02` | Matches the recommended plan split in research |
| Exclude new CLI tenant UX | `32-02-02` | Mix wrapper test locks current API without adding flags |

### CONTEXT

No phase-local `32-CONTEXT.md` was present during planning. The user prompt and repo guardrails were treated as the operative context constraints.

| Context Constraint | Covered By | Notes |
|--------------------|------------|-------|
| Respect Phase 32 boundary from `.planning/ROADMAP.md` | all tasks | No task crosses into Phase 33 or Phase 34 work |
| Exclude compare drill-in `compare_token` issue because it belongs to Phase 33 | `32-01-01`, `32-02-02` | Explicitly called out in both plans as out of scope |
| Keep work focused on public `rulestead` | all tasks | No `rulestead_admin` file ownership |
| Reuse existing compare/apply/provenance contract from Phases 29-31 | `32-01-01`, `32-01-02`, `32-02-01` | Plans reference the existing `tenant_key` and replay helpers |
| Do not widen `rulestead_admin` or publish-prep work | all tasks | No admin or publish artifact changes planned |

Audit result: all Phase 32 goal, requirement, research, and prompt-level context items are covered by the two-plan set. No deferred or out-of-phase item is scheduled here.

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** drafted 2026-05-22

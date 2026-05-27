---
phase: 64-proof-docs-and-support-truth
review_path: 64-REVIEW.md
fix_scope: critical_warning
findings_in_scope: 1
fixed: 1
skipped: 0
iteration: 1
status: all_fixed
fixed_at: 2026-05-27T22:30:00Z
---

# Phase 64: Code Review Fix Report

**Fix scope:** critical_warning (Critical + Warning only)  
**Iteration:** 1  
**Status:** all_fixed

## Summary

Applied WR-01: moved `rulestead_admin deps.get` before `verify.phase*` in three maintainer CI scopes so admin subprocess tests inside verify tasks have dependencies installed on fresh checkouts.

## Fixes Applied

### WR-01 — `guarded_rollout_auto_advance` CI scope installs admin deps after `verify.phase64`

**Status:** fixed  
**Commit:** fix(64): install admin deps before verify in CI scopes  
**Files:** `scripts/ci/test.sh`

Reordered `run_guarded_rollout_auto_advance/0`, `run_blast_radius_governance/0`, and `run_reusable_targeting_deepening/0` to match `run_guarded_rollout_foundations/0`:

1. `rulestead deps.get`
2. `prepare_rulestead_test_db`
3. `rulestead_admin deps.get` ← moved before verify
4. `verify.phase{56,60,64}`

Removed redundant post-success `rulestead_admin deps.get` (no longer needed once deps are installed before admin subprocess tests).

**Verification:** `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` — exit 0

## Skipped (out of scope)

| ID | Severity | Reason |
|----|----------|--------|
| IN-01 | info | fix_scope=critical_warning |
| IN-02 | info | fix_scope=critical_warning |
| IN-03 | info | fix_scope=critical_warning |

## Next Steps

- `/gsd-verify-work` — Verify phase completion
- Optional: re-run `/gsd-code-review 64` to confirm clean status

---

*Phase: 64-proof-docs-and-support-truth*

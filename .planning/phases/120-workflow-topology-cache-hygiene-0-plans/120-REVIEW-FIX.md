---
phase: 120-workflow-topology-cache-hygiene
fixed_at: 2026-06-16T00:00:00Z
review_path: .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 120: Code Review Fix Report

**Fixed at:** 2026-06-16
**Source review:** .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (WR-01, WR-02, WR-03)
- Fixed: 3
- Skipped: 0

The 4 Info findings (IN-01 through IN-04) were out of scope (`fix_scope: critical_warning`) and were not addressed.

## Fixed Issues

### WR-01: New `$GITHUB_STEP_SUMMARY` writes in ci.yml are unguarded, unlike the script changes

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 3eb2a43
**Applied fix:** Wrapped both new inline report steps ("Report lint cache hit" and "Report test cache hit") in an `if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]` guard, matching the discipline already applied to the shell lanes (lint.sh:12, test.sh:506). This prevents an empty-filename / ambiguous-redirect failure under `act` and other local runners that do not export `GITHUB_STEP_SUMMARY`.

### WR-03: Cache-hit report prints empty value on a restore-key (partial) hit, mislabeling a warm cache as a miss

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 894275a
**Applied fix:** Replaced the raw `Cache hit: <value>` echo in both report steps with an explicit branch on the `cache-hit` output: `true` -> "Cache: exact hit", anything else (empty string from a restore-keys partial hit, or `false`) -> "Cache: miss or restore-key (partial) hit". This removes the misleading blank-value rendering on partial hits and delivers the accurate cache-posture reporting that was D-06's goal. The normalization was nested inside the WR-01 guard so both fixes coexist.

### WR-02: PLT cache restore vs save key both pin `rulestead/mix.lock` with no restore-keys fallback

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 8f7fc15
**Applied fix:** Added a `restore-keys: ${{ runner.os }}-plt-` partial-restore fallback to the "Restore Dialyzer PLT" step, mirroring the Mix-deps cache fallback two steps above. A change to `rulestead/mix.lock` or `.tool-versions` now rehydrates from the prior PLT as an incremental base instead of forcing a full cold Dialyzer PLT rebuild. The exact-match save key was left unchanged (correct as-is).

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-06-16_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

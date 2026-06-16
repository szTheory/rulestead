---
phase: 120-workflow-topology-cache-hygiene
fixed_at: 2026-06-16T00:00:00Z
review_path: .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-REVIEW.md
iteration: 2
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 120: Code Review Fix Report

**Fixed at:** 2026-06-16
**Source review:** .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 5 (WR-01, IN-01, IN-02, IN-03, IN-04)
- Fixed: 5
- Skipped: 0

This is iteration 2 against a FRESH re-review. The prior iteration (iteration 1)
fixed WR-01/WR-02/WR-03 from the OLD review. Fix scope was `--all`, so every
finding in the current REVIEW.md was in scope. WR-01 and IN-03 are coupled (key
narrowing + its doc) and were fixed together in one commit.

## Fixed Issues

### WR-01: Test/adopter/mounted cache keys over-invalidate on unrelated companion/demo lockfile bumps (coupled with IN-03)

**Files modified:** `.github/workflows/ci.yml`, `MAINTAINING.md`
**Commit:** c04edcf
**Applied fix:** Narrowed the three multi-package lane cache keys from
`hashFiles('**/mix.lock')` (all four tracked lockfiles) to
`hashFiles('rulestead/mix.lock', 'rulestead_admin/mix.lock', '.tool-versions')`
— the exact set these lanes build — for the test matrix (ci.yml:188),
adopter-contract (:255), and mounted-proof (:307). The test-matrix key
previously had no `.tool-versions` component; it was added for consistency and
to strengthen the under-invalidation guard. This honors phase decision D-06
(avoid under-invalidation on multi-package lanes) while removing the
over-invalidation: `open_feature_rulestead/mix.lock` and
`examples/demo/backend/mix.lock` no longer bust these caches since neither is
compiled by these lanes. Lint/PLT keys (already `rulestead/mix.lock`) and the
openfeature-companion key were deliberately left untouched. IN-03 was folded in:
the MAINTAINING.md "Cache key components" cells for these three lanes now name
`rulestead/mix.lock` + `rulestead_admin/mix.lock` instead of `**/mix.lock`, and
the under-invalidation justification prose was rewritten to stay accurate after
narrowing (it now explains the two-sibling glob is the tightest set that avoids
under-invalidation while excluding the two non-built lockfiles).

### IN-01: Duplicated multi-line cache-hit report step across lint and test jobs

**Files modified:** `scripts/ci/report_cache_hit.sh` (new), `.github/workflows/ci.yml`
**Commit:** 6c086fe
**Applied fix:** Extracted the copy-pasted cache-hit report block (lint
:113-122, test :191-200) into a new shared script
`scripts/ci/report_cache_hit.sh` that takes the cache-hit value as `$1`. It
preserves the `[[ -n "${GITHUB_STEP_SUMMARY:-}" ]]` guard and the exact-hit vs
partial/miss branching byte-for-byte, and follows existing scripts/ci/
conventions (`#!/usr/bin/env bash`, `set -euo pipefail`). Both jobs now invoke
`scripts/ci/report_cache_hit.sh "${{ steps.mix-cache.outputs.cache-hit }}"`.
Behavior was verified identical for the exact-hit (`true`), partial-hit (empty
string), miss (`false`), and no-`GITHUB_STEP_SUMMARY` cases.

### IN-02: Version-banner subshells in scripts duplicate `--version` invocations

**Files modified:** `scripts/ci/lint.sh`, `scripts/ci/test.sh`
**Commit:** c26d5e0
**Applied fix:** Captured `elixir --version` and `mix --version` once each into
`elixir_ver` / `mix_ver` locals and reused them in both the echo banner and the
`$GITHUB_STEP_SUMMARY` block (lint.sh, test.sh). Output wording is preserved:
the banner emits the full multi-line `--version` output (guarded so a missing
binary prints no extra blank line, matching the original `|| true` behavior),
and the summary uses `head -1` of the elixir output plus the mix line, retaining
the `elixir not found` / `mix not found` fallbacks. A trailing `true` was added
after the guarded banner echoes so a short-circuited `[[ ]] &&` cannot trip
`set -e`.

### IN-03: MAINTAINING.md cache-key cells consistent with narrowed keys

**Files modified:** `MAINTAINING.md`
**Commit:** c04edcf (committed together with WR-01 — coupled)
**Applied fix:** No lockfile-count correction was needed (the "four tracked
lockfiles" figure was verified correct). Because WR-01's narrowing was adopted,
the doc was made consistent: the test/adopter/mounted cache-key cells now name
`rulestead/mix.lock` + `rulestead_admin/mix.lock`, and the justification prose
was adjusted so it remains accurate after narrowing.

### IN-04: `mounted-proof` job's explicit `mix deps.get` is load-bearing but undocumented

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 7cb3c6d
**Applied fix:** Added a comment on the mounted-proof "Install mounted proof
deps" step explaining that test.sh's `mounted_admin_contract` scope
intentionally does not fetch deps (unlike peer scopes), so this step is the only
dep fetch for the mounted lane and must not be removed as redundant. Comment
only; no behavior change. YAML re-validated.

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-06-16_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_

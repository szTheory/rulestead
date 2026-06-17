---
phase: 120-workflow-topology-cache-hygiene
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/ci.yml
  - scripts/ci/lint.sh
  - scripts/ci/test.sh
  - MAINTAINING.md
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 120: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Re-review of the Phase 120 edit-only CI/CD changes after the prior fix cycle.
Scope: wiring `openfeature-companion` into the `release_gate` aggregate, removing
the cross-lane cache fallback from the test matrix, scoping lint/PLT cache keys to
`rulestead/mix.lock`, and adding cache/version observability to the shell lanes.
`release_gate.sh` was intentionally not changed.

**Prior-warning verification (all three confirmed genuinely fixed):**

- **WR-01 (unguarded `$GITHUB_STEP_SUMMARY` writes) — FIXED.** Both new inline
  report steps now wrap the redirect in `if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]`
  (ci.yml:115 for lint, ci.yml:193 for test). Matches the shell-lane discipline.
- **WR-02 (missing PLT restore-keys fallback) — FIXED.** The Restore Dialyzer PLT
  step now has `restore-keys: | ${{ runner.os }}-plt-` (ci.yml:128-129). The save
  step (ci.yml:137) correctly retains only the exact key — `restore-keys` on a
  save step would be meaningless, so this asymmetry is correct, not a regression.
- **WR-03 (empty cache-hit value mislabeled as miss) — FIXED.** Both report steps
  now branch on `hit == "true"` and emit `Cache: exact hit` vs
  `Cache: miss or restore-key (partial) hit` (ci.yml:116-121, 194-199), so a
  partial restore-key hit no longer renders as a blank/cold-miss line.

**Core correctness re-confirmed:**

- The `needs['openfeature-companion'].result` bracket accessor (ci.yml:338) is
  correct — hyphenated job ids require bracket access.
- The skipped→success transform for `openfeature-companion` (ci.yml:350-352)
  mirrors the `mounted-proof` pattern exactly and only rewrites the literal
  `skipped` result, so `failure`/`cancelled` are never masked.
- Lint/PLT key narrowing to `rulestead/mix.lock` matches `lint.sh`'s build scope
  (it builds only `rulestead/`).
- Removal of the cross-lane `${{ runner.os }}-mix-` fallback from the test matrix
  is correct (prevents OTP-incompatible `_build` restores across matrix legs).

No critical/blocker defects. One remaining warning (a cache over-invalidation
that the new doc table surfaces but does not flag), plus the four prior info
items re-assessed below. The IN-03 lockfile count is now verified as ground truth.

## Warnings

### WR-01: Test/adopter/mounted cache keys over-invalidate on unrelated companion/demo lockfile bumps

**File:** `.github/workflows/ci.yml:188` (test), `:255` (adopter-contract), `:307` (mounted-proof); `MAINTAINING.md:71,74,76`
**Issue:** The test-matrix, adopter-contract, and mounted-proof caches key on
`hashFiles('**/mix.lock')`. Verified ground truth: the repo has **four** tracked
lockfiles —

```
examples/demo/backend/mix.lock
open_feature_rulestead/mix.lock
rulestead/mix.lock
rulestead_admin/mix.lock
```

— so `**/mix.lock` hashes all four. But these three lanes only build
`rulestead` + `rulestead_admin` (their `path:` lists name only those two trees).
A dependency bump in `open_feature_rulestead/mix.lock` or
`examples/demo/backend/mix.lock` therefore busts the test/adopter/mounted caches
and forces a cold deps+build, even though nothing those lanes compile changed.

MAINTAINING.md:76 justifies `**/mix.lock` as protection against "silent
under-invalidation on sibling dependency bumps," but the glob is broader than
"the two siblings these lanes build" — it also captures the OpenFeature provider
and the demo backend, neither of which these lanes compile. So the same phase
that tightened the *lint* key to `rulestead/mix.lock` to avoid spurious busting
left the heavier lanes over-broad in the opposite direction. The doc presents the
four-lockfile glob as intentional, but does not acknowledge that two of those
four files are irrelevant to these lanes' build scope. This is a robustness/cost
issue (needless cold rebuilds), not a correctness bug — but it is the precise
inverse of the under-invalidation the doc claims to be guarding against, and it
contradicts the phase's own narrowing rationale.
**Fix:** Scope the glob to the lockfiles these lanes actually build, e.g.
`hashFiles('rulestead/mix.lock', 'rulestead_admin/mix.lock', '.tool-versions')`,
and update the MAINTAINING.md "Cache key components" cells to name those two
files explicitly instead of `**/mix.lock`. If the broad glob is deliberate (e.g.
to keep one cache key shape across lanes), document *why* the demo/OpenFeature
lockfiles are intentionally included despite not being built here.

## Info

### IN-01: Duplicated multi-line cache-hit report step across lint and test jobs

**File:** `.github/workflows/ci.yml:113-122` and `:191-200`
**Issue:** Still valid — and the WR-03 fix made it worse. The report step is now
a multi-line `if/else` block copy-pasted verbatim into both the lint and test
jobs. Any future change to the cache-posture wording or the guard must be applied
in two places and can silently drift. This is the kind of non-trivial repeated
workflow logic CLAUDE.md's "scripts-first CI surfaces where workflow logic gets
non-trivial" guidance steers away from.
**Fix:** Fold the report logic into a small shared script (e.g.
`scripts/ci/report_cache_hit.sh "$cache_hit"`) invoked from both jobs, or accept
the duplication but keep the two copies byte-identical and add a comment cross-
linking them.

### IN-02: Version-banner subshells in scripts duplicate `--version` invocations

**File:** `scripts/ci/lint.sh:9-16`, `scripts/ci/test.sh:501-513`
**Issue:** Still valid. Both scripts run `elixir --version` / `mix --version`
once for the plain `echo` banner (lint.sh:9-10, test.sh:502-503) and again inside
the `$GITHUB_STEP_SUMMARY` block via command substitution (lint.sh:16,
test.sh:510). The two invocations could in principle disagree if the environment
mutated between them, and it doubles the process spawns. Observability-only.
**Fix:** Capture once into a local and reuse:
`elixir_ver="$(elixir --version 2>/dev/null | head -1 || echo 'elixir not found')"`,
then reference `${elixir_ver}` in both the echo and the summary block.

### IN-03: MAINTAINING.md "all four repo lockfiles" — count VERIFIED correct; one mismatch with the prose's intent

**File:** `MAINTAINING.md:71`
**Issue:** Ground truth confirmed via `git ls-files '**/mix.lock'`: there are
exactly **four** tracked lockfiles (`examples/demo/backend/mix.lock`,
`open_feature_rulestead/mix.lock`, `rulestead/mix.lock`,
`rulestead_admin/mix.lock`). So the "all four repo lockfiles" figure on line 71
is **accurate** — the prior IN-03 count concern is resolved; no number change is
needed. The residual issue is purely interpretive and is captured by WR-01 above:
the parenthetical "(all four repo lockfiles)" frames the broad glob as a feature,
but two of those four files (`open_feature_rulestead`, `examples/demo/backend`)
are not built by the test/adopter/mounted lanes, so hashing them only causes
over-invalidation. Downgraded from the prior review to an accuracy note now that
the count is verified.
**Fix:** No count correction required. If WR-01's narrowing is adopted, update
this cell to name `rulestead/mix.lock` + `rulestead_admin/mix.lock`. If the
four-file glob is kept intentionally, add one clause noting that the demo and
OpenFeature lockfiles are included by the glob but are not compiled by these
lanes.

### IN-04: `mounted-proof` job's explicit `mix deps.get` is load-bearing but undocumented

**File:** `.github/workflows/ci.yml:310-315` (pre-existing, adjacent to the edited gate wiring)
**Issue:** Still valid. The `mounted-proof` job runs an explicit
`cd rulestead && mix deps.get` / `cd ../rulestead_admin && mix deps.get`
(ci.yml:311-313) before invoking `test.sh`, while `run_mounted_admin_contract`
in test.sh (lines 92-122) deliberately does **not** run `deps.get` — unlike peer
scopes such as `run_openfeature_companion` (test.sh:124-129) and
`run_guarded_rollout_foundations` (test.sh:173), which fetch deps themselves.
This asymmetry is load-bearing: the job-step `deps.get` is the only dep fetch for
the mounted scope, so a future refactor that "tidies up" the redundant-looking
step would silently break the mounted lane with an `Unchecked dependencies`
failure. Not changed in this phase, but adjacent to the gate edits.
**Fix:** Add a comment on the job step noting that the `mounted_admin_contract`
scope in `test.sh` intentionally does not fetch deps, so this step is required —
not redundant.

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

---
phase: 120-workflow-topology-cache-hygiene
reviewed: 2026-06-16T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - .github/workflows/ci.yml
  - MAINTAINING.md
  - scripts/ci/lint.sh
  - scripts/ci/test.sh
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 120: Code Review Report

**Reviewed:** 2026-06-16
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Phase 120 made edit-only CI/CD changes: wired `openfeature-companion` into the
`release_gate` aggregate, removed a cross-lane cache fallback, scoped lint/PLT
cache keys to `rulestead/mix.lock`, and added cache/version observability to the
shell lanes. `release_gate.sh` was intentionally not changed.

The core correctness items hold up:

- The `needs['openfeature-companion'].result` bracket-accessor expression is
  syntactically correct (hyphenated job ids require bracket access; dot access
  would be a syntax error).
- The skipped-to-success transform mirrors the existing `mounted-proof` pattern
  exactly and is sound: `release_gate.sh` treats any value other than the
  literal string `success` as a failure, so converting a legitimately-skipped
  (path-not-relevant) job to `success` is the correct behavior and does not mask
  a real failure (`failure`/`cancelled` results are not rewritten).
- The lint/PLT cache-key narrowing to `rulestead/mix.lock` matches the lane's
  actual build scope (`lint.sh` builds only `rulestead/`), and the PLT save key
  equals the restore key.
- Removal of the cross-lane `${{ runner.os }}-mix-` restore fallback from the
  test matrix is correct: it prevented OTP-incompatible `_build` restores across
  matrix legs.

No critical/blocker defects found. The findings below concern an
observability-guard inconsistency, a cache-key staleness window, and a few
quality items.

## Warnings

### WR-01: New `$GITHUB_STEP_SUMMARY` writes in ci.yml are unguarded, unlike the script changes

**File:** `.github/workflows/ci.yml:113-115` and `.github/workflows/ci.yml:182-184`
**Issue:** The two new inline report steps write directly to
`$GITHUB_STEP_SUMMARY` with no presence guard:

```yaml
- name: Report lint cache hit
  run: |
    echo "Cache hit: ${{ steps.mix-cache.outputs.cache-hit }}" >> "$GITHUB_STEP_SUMMARY"
```

This is the *opposite* discipline applied to the shell lanes in the same phase,
where every summary write is guarded with `[[ -n "${GITHUB_STEP_SUMMARY:-}" ]]`
(lint.sh:12, test.sh:506). Under hosted GitHub Actions the variable is always
set, so CI is fine. But line 1 of this file explicitly names `act` as a
first-class consumer of the workflow ("stable YAML `jobs:` keys relied on by
docs, `act`, and branch protection"). Under `act` (and any local runner that
does not export `GITHUB_STEP_SUMMARY`), `>> "$GITHUB_STEP_SUMMARY"` expands to
`>> ""`, which fails with an ambiguous-redirect / empty-filename error and
fails the step. The phase deliberately hardened the shell side against exactly
this; the YAML side was left inconsistent.
**Fix:** Guard the redirect the same way the scripts do, or skip the step when
the var is absent:

```yaml
- name: Report lint cache hit
  run: |
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
      echo "Cache hit: ${{ steps.mix-cache.outputs.cache-hit }}" >> "$GITHUB_STEP_SUMMARY"
    fi
```

### WR-02: PLT cache restore vs save key both pin `rulestead/mix.lock` with no restore-keys fallback — first run after a lock bump rebuilds the full PLT

**File:** `.github/workflows/ci.yml:116-128`
**Issue:** The PLT restore step (line 120) and save step (line 128) both use the
exact key `${{ runner.os }}-plt-${{ hashFiles('rulestead/mix.lock', '.tool-versions') }}`
and the restore step has **no `restore-keys:` fallback**. The Mix-deps cache two
lines above (line 111-112) does have a `${{ runner.os }}-lint-mix-` fallback.
The asymmetry means: any change to `rulestead/mix.lock` or `.tool-versions`
produces a brand-new PLT key with zero partial-hit fallback, forcing a
full-from-scratch Dialyzer PLT rebuild on that run (and it is only saved
`if: always()` at the end). For incremental dependency bumps this is the
slowest possible Dialyzer path even though the prior PLT would have been a
near-perfect incremental base. This is a robustness/cost issue, not a
correctness bug — `mix dialyzer` will still rebuild the PLT correctly — but the
missing fallback is an easy-to-miss regression-cost trap and is inconsistent
with the deps cache in the same job.
**Fix:** Add a partial restore fallback so a lock bump rehydrates from the prior
PLT instead of rebuilding cold:

```yaml
- name: Restore Dialyzer PLT
  uses: actions/cache/restore@... # v5.0.5
  with:
    path: rulestead/priv/plts
    key: ${{ runner.os }}-plt-${{ hashFiles('rulestead/mix.lock', '.tool-versions') }}
    restore-keys: |
      ${{ runner.os }}-plt-
```

### WR-03: Cache-hit report prints empty value on a restore-key (partial) hit, mislabeling a warm cache as a miss

**File:** `.github/workflows/ci.yml:115` and `.github/workflows/ci.yml:184`
**Issue:** `steps.mix-cache.outputs.cache-hit` is set to the string `'true'`
**only on an exact-key match**. On a restore-keys partial hit (which is the
common case after a lockfile bump — and the entire reason the
`${{ runner.os }}-lint-mix-` / `${{ runner.os }}-${{ matrix.otp }}-...-mix-`
fallbacks exist) the output is the empty string, not `'false'`. The new
observability line will render `Cache hit: ` (blank) and the reader will
reasonably conclude the cache cold-missed when in fact a partial restore
occurred. Since the stated goal of D-06 was accurate cache-posture reporting,
this defeats the feature in precisely the partial-hit scenario operators most
need to distinguish.
**Fix:** Normalize the empty/partial case explicitly, e.g.:

```yaml
run: |
  hit="${{ steps.mix-cache.outputs.cache-hit }}"
  if [[ "$hit" == "true" ]]; then
    echo "Cache: exact hit" >> "$GITHUB_STEP_SUMMARY"
  else
    echo "Cache: miss or restore-key (partial) hit" >> "$GITHUB_STEP_SUMMARY"
  fi
```

## Info

### IN-01: Duplicated inline report step across lint and test jobs

**File:** `.github/workflows/ci.yml:113-115`, `182-184`
**Issue:** The "Report cache hit" step is copy-pasted verbatim into two jobs.
Combined with WR-01/WR-03, any guard/normalization fix must be applied in two
places, and they can silently drift. This is the kind of repeated workflow
logic CLAUDE.md's "scripts-first CI surfaces where workflow logic gets
non-trivial" guidance steers away from.
**Fix:** If the reporting grows beyond one line, fold it into a small shared
script invoked with the `cache-hit` value as an argument; otherwise accept the
duplication but keep the two copies byte-identical.

### IN-02: Version-banner subshells in scripts duplicate work and can disagree with the banner echo

**File:** `scripts/ci/lint.sh:9-16`, `scripts/ci/test.sh:501-510`
**Issue:** Both scripts run `elixir --version` / `mix --version` once for the
plain `echo` banner and then **again** inside the `$GITHUB_STEP_SUMMARY` block
via command substitution. The two invocations could in principle report
different toolchains if the environment mutated between them, and it doubles the
process spawns. Minor, observability-only code.
**Fix:** Capture once into locals and reuse:
`elixir_ver="$(elixir --version 2>/dev/null | head -1 || echo 'elixir not found')"`
then reference `${elixir_ver}` in both the echo and the summary block.

### IN-03: MAINTAINING.md test-matrix cache row says "all four repo lockfiles" — verify the count

**File:** `MAINTAINING.md:71`
**Issue:** The new caching table asserts `**/mix.lock` matches "all four repo
lockfiles." The repo paths referenced across the workflow are `rulestead/`,
`rulestead_admin/`, and `open_feature_rulestead/` (three). The "four" figure is
plausible if a root or examples/demo lockfile also exists, but the doc states it
as fact without the count being self-evident from the workflow. If the true
count is three, this is a doc inaccuracy that will mislead a maintainer reasoning
about cache invalidation.
**Fix:** Confirm the actual `mix.lock` count (`git ls-files '**/mix.lock'`) and
correct the prose to the verified number, or name the four files inline.

### IN-04: `mounted-proof` job duplicates `mix deps.get` that `test.sh` already runs

**File:** `.github/workflows/ci.yml:294-299` (pre-existing, adjacent to the
edited gate wiring)
**Issue:** The `mounted-proof` job runs an explicit `mix deps.get` for both
siblings (lines 295-297) before invoking `test.sh`, while
`run_mounted_admin_contract` in test.sh does **not** run `deps.get` (unlike
peer scopes such as `run_openfeature_companion`, which does). This asymmetry is
load-bearing — the job-step `deps.get` is the only dep fetch for the mounted
scope — but it is undocumented and fragile: a future refactor that "tidies up"
the redundant-looking step would silently break the mounted lane. Not changed
in this phase, but adjacent to the gate edits and worth a guard comment.
**Fix:** Add a comment on the job step noting that `test.sh`'s
`mounted_admin_contract` scope intentionally does not fetch deps, so this step
is required (not redundant).

---

_Reviewed: 2026-06-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

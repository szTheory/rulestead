---
phase: 120-workflow-topology-cache-hygiene
plan: "02"
subsystem: ci
tags: [cache-hygiene, observability, ci-workflow]
dependency_graph:
  requires: ["120-01"]
  provides: ["CIDX-07-cache-correctness", "CIDX-07-observability"]
  affects: [".github/workflows/ci.yml", "scripts/ci/test.sh", "scripts/ci/lint.sh"]
tech_stack:
  added: []
  patterns:
    - "hashFiles scoped to single-package lockfile for single-package lanes"
    - "actions/cache id: + steps.<id>.outputs.cache-hit for $GITHUB_STEP_SUMMARY"
    - "GITHUB_STEP_SUMMARY guarded with [[ -n \"${GITHUB_STEP_SUMMARY:-}\" ]]"
key_files:
  modified:
    - .github/workflows/ci.yml
    - scripts/ci/test.sh
    - scripts/ci/lint.sh
decisions:
  - "D-05: removed ${{ runner.os }}-mix- cross-lane fallback restore key from test matrix — OTP-incompatible _build must not restore across lanes"
  - "D-06: scoped lint/PLT cache hashFiles to rulestead/mix.lock (single-package lane) — correctness-safe since lint.sh builds only rulestead/"
  - "D-06 discretionary: scoped openfeature-companion hashFiles to open_feature_rulestead/mix.lock — single-package lane confirmed"
  - "D-06 non-action: test/adopter/mounted keys left broad (**/mix.lock) — multi-package lanes would under-invalidate on single-lock scoping"
  - "PLT restore key and save key kept byte-identical — both changed together to rulestead/mix.lock scope"
  - "D-08: observability via id: mix-cache + steps.mix-cache.outputs.cache-hit (built-in cache-hit output, no hand-rolling)"
  - "D-08: version + rerun output in scripts guarded on GITHUB_STEP_SUMMARY to avoid noise in local runs"
metrics:
  duration: "~3 minutes"
  completed_date: "2026-06-16"
  tasks: 2
  files: 3
---

# Phase 120 Plan 02: Cache Key Hygiene + Scripts-First Observability Summary

**One-liner:** Scoped lint+PLT cache keys to `rulestead/mix.lock`, removed the cross-lane OTP-incompatible `${{ runner.os }}-mix-` fallback, and added version+cache-hit+rerun observability via `$GITHUB_STEP_SUMMARY` and `actions/cache`'s built-in `cache-hit` output.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Cache key hygiene — remove cross-lane fallback (D-05) + scope lint/PLT keys (D-06) | 3a096db | `.github/workflows/ci.yml` |
| 2 | Scripts-first observability — versions, cache hit/miss, rerun command (D-08) | bb56dca | `.github/workflows/ci.yml`, `scripts/ci/test.sh`, `scripts/ci/lint.sh` |

## What Was Built

**Task 1 — Cache key hygiene (`ci.yml`):**
- Removed the `${{ runner.os }}-mix-` restore key at line 177 from the test matrix job. This key was cross-lane: a warm cache from OTP 26 could restore `_build` to an OTP 28 lane, corrupting BEAM bytecode. The matrix-scoped restore key `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-` at line 176 was kept.
- Changed the lint deps/build cache key `hashFiles` from `'**/mix.lock'` to `'rulestead/mix.lock'` (line 109). Correctness-safe: `lint.sh` builds only `rulestead/`; the prior glob busted on 3 unrelated lockfiles (rulestead_admin, open_feature_rulestead, examples/demo/backend).
- Changed both PLT restore key (line 116) and PLT save key (line 124) from `'**/mix.lock'` to `'rulestead/mix.lock'`. Both changed together to maintain byte-identity between restore and save.
- Discretionarily scoped `openfeature-companion` cache key to `open_feature_rulestead/mix.lock` (single-package lane confirmed by path: block and test.sh cd scope).
- Left `test`, `adopter-contract`, and `mounted-proof` cache keys at `**/mix.lock` — those lanes build both `rulestead/` and `rulestead_admin/`; narrowing to one lockfile would cause silent under-invalidation on sibling package dependency bumps.

**Task 2 — Observability (`ci.yml`, `test.sh`, `lint.sh`):**
- Added `id: mix-cache` to the lint cache step and the test matrix cache step in `ci.yml`.
- Added thin "Report cache hit" steps after each that write `Cache hit: ${{ steps.mix-cache.outputs.cache-hit }}` to `$GITHUB_STEP_SUMMARY` using the built-in `actions/cache` `cache-hit` output.
- Extended `test.sh` lane banner (near line 500) to also emit `elixir --version` + `mix --version` output alongside the existing `MATRIX_ELIXIR`/`MATRIX_OTP` echo.
- Added a `$GITHUB_STEP_SUMMARY` block to `test.sh` (guarded on `[[ -n "${GITHUB_STEP_SUMMARY:-}" ]]`) that writes: version heading, Elixir/mix version line, and a copy-pasteable `MATRIX_ELIXIR=... MATRIX_OTP=... bash scripts/ci/test.sh` rerun command.
- Added equivalent observability to `lint.sh` after the `cd "${RULESTEAD_REPO}/rulestead"`: version echo to stdout plus a `$GITHUB_STEP_SUMMARY` block with version line and `bash scripts/ci/lint.sh` rerun command.
- No new env vars introduced; `MATRIX_ELIXIR`/`MATRIX_OTP` reused as-is.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] YAML syntax error in inline `run:` with `${{ ... }}: ...` pattern**
- **Found during:** Task 2
- **Issue:** `actionlint` flagged `run: echo "Cache hit: ${{ steps.mix-cache.outputs.cache-hit }}" >> "$GITHUB_STEP_SUMMARY"` as a YAML mapping parse error — the `:` in the expression caused the parser to interpret the line as a mapping value.
- **Fix:** Changed both "Report cache hit" run steps to block scalar form (`run: |`).
- **Files modified:** `.github/workflows/ci.yml`
- **Commit:** bb56dca (same task commit)

## Verification Results

All acceptance criteria passed:

| Check | Result |
|-------|--------|
| `actionlint .github/workflows/ci.yml` exits 0 | PASS |
| Exactly 3 `hashFiles('rulestead/mix.lock', '.tool-versions')` occurrences | PASS (3) |
| Zero bare cross-lane `${{ runner.os }}-mix-` fallback keys | PASS (0) |
| Matrix-scoped restore key `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-` present | PASS |
| PLT restore + save keys byte-identical (2 occurrences) | PASS (2) |
| test/adopter/mounted keys NOT narrowed to single lockfile | PASS |
| `bash -n` passes for test.sh and lint.sh | PASS |
| `GITHUB_STEP_SUMMARY` in test.sh | PASS |
| `GITHUB_STEP_SUMMARY` in lint.sh | PASS |
| `steps.mix-cache.outputs.cache-hit` referenced in ci.yml | PASS |
| Protected surfaces (publish-hex.yml, verify-published-release.yml, dependabot.yml) unchanged | PASS |
| `release_gate.sh --skip-phase7` exits 0 | PASS |

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Changes are confined to CI workflow YAML and CI utility scripts. Supply-chain surfaces (SHA pins, `permissions:`, publish workflows, dependabot.yml) verified unchanged via `git diff`.

## Known Stubs

None.

## Self-Check: PASSED

Files created/modified:
- `.github/workflows/ci.yml` — exists, actionlint green
- `scripts/ci/test.sh` — exists, bash -n pass
- `scripts/ci/lint.sh` — exists, bash -n pass

Commits verified:
- `3a096db` — Task 1 (cache hygiene)
- `bb56dca` — Task 2 (observability)

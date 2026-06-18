---
phase: 125-version-truth-sweep-release-docs
plan: 02
subsystem: ci-guards
status: complete
tags: [ci, drift-guard, version-truth, release-docs, REL-02]
requires:
  - 125-01  # the doc sweep that makes the tree clean before the guard's first run
provides:
  - scripts/check_version_truth.py  # fail-closed CI drift guard (criterion-1 surface)
  - lint.sh version-truth wiring     # guard runs in the lint lane, fail-closed
affects:
  - scripts/ci/lint.sh
  - 125-03  # guard exempts the 0.1.x -> 1.0 heading Plan 03 must add
tech-stack:
  added: []
  patterns:
    - "sibling check_*.py guard convention (main()->int, sys.exit(main()), Usage docstring, UPPERCASE OK/DRIFT messaging)"
    - "anchored negative-lookahead regex to exclude a legitimate third-party pin"
    - "line-scoped, arrow-gated exemption for a sanctioned upgrade-path heading"
key-files:
  created:
    - scripts/check_version_truth.py
  modified:
    - scripts/ci/lint.sh
    - rulestead/test/rulestead/release_contract_test.exs  # Rule 1 coherence fix (mix format)
decisions:
  - "Guard scans the criterion-1 shipped surface only (fixed README/maintainer list + recursive guides/ glob); excludes .planning/, prompts/, rulestead/doc/, examples/ (D-06)."
  - "Anchored `~> 0.1` negative-lookahead `(?![.\\d])` excludes the third-party `~> 0.1.3` pin with no per-file carve-out (D-06)."
  - "MANDATORY orchestrator deviation: line-scoped, arrow-gated exemption for the sanctioned `0.1.x -> 1.0` upgrade heading so ROADMAP SC-4 (Plan 03's required heading) stays satisfiable while every other stale `0.1.x` claim is still caught."
metrics:
  duration: 3min
  tasks: 2
  files: 3
  completed: 2026-06-18
---

# Phase 125 Plan 02: Version-Truth Drift Guard Summary

Fail-closed CI guard `scripts/check_version_truth.py` scans the criterion-1 shipped doc surface for stale pre-1.0 release language, wired into `scripts/ci/lint.sh` under `set -euo pipefail`; uses an anchored negative-lookahead so the legitimate third-party `~> 0.1.3` pin never trips it, plus a line-scoped arrow-gated exemption for the one mandated `0.1.x → 1.0` upgrade heading.

## What was built

### Task 1 — `scripts/check_version_truth.py` (commit e3e25e6)
A new fail-closed drift guard mirroring the 8 sibling `check_*.py` brand-token guards exactly:
- `main() -> int`, `sys.exit(main())`, `ROOT = Path(__file__).resolve().parents[1]`, "Usage (from repo root)" docstring, `VERSION TRUTH OK (N files clean)` / `VERSION TRUTH DRIFT DETECTED` messaging.
- Scans a fixed file list (`README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `open_feature_rulestead/README.md`, `MAINTAINING.md`, `CONTRIBUTING.md`) plus a recursive `guides/` glob (`*.md` + `*.cheatmd`). Excludes `.planning/`, `prompts/`, `rulestead/doc/`, `examples/`.
- Six drift patterns: `0\.1\.x`, `0\.1\.7`, `future…1\.0` (case-insensitive), `1\.0 API freeze`, `Two version lines`, and the anchored `~> 0\.1(?![.\d])`.
- Executable bit set (`chmod +x`) to match convention.
- Exits 0 on the post-Plan-01 clean tree: `VERSION TRUTH OK (33 files clean)`.

### Task 2 — `scripts/ci/lint.sh` wiring (commit 319ece5)
One comment-then-invoke line added to the Python-guard block, immediately after the `check_logo_assets.py` invocation. `set -euo pipefail` (L2) + `cd "${RULESTEAD_REPO}"` (L40) make the guard fail-closed with correct relative-path resolution. `grep -c 'check_version_truth.py' scripts/ci/lint.sh` == 1. Full `bash scripts/ci/lint.sh` exits 0.

## Deviations from Plan

### Mandated deviation (orchestrator directive — Rule 1 coherence)

**1. [Rule 1 - Coherence] Arrow-gated exemption for the sanctioned `0.1.x → 1.0` upgrade heading**
- **Found during:** Task 1 (orchestrator cross-plan conflict directive)
- **Issue:** ROADMAP success criterion 4 requires Plan 03 to add a section titled exactly `## Upgrading 0.1.x → 1.0` to `guides/introduction/upgrading.md`. That heading contains the literal `0.1.x`, and the guard globs `guides/` and patterns on bare `0\.1\.x` — so without an exemption the guard would flag criterion 4's own required heading, making Plan 03 impossible to pass.
- **Fix:** Added a line-scoped, arrow-gated exemption: a line matching `0\.1\.x\s*(?:→|->)\s*1\.0` (Unicode `→` OR ASCII `->`) is the sanctioned upgrade-path instruction and is skipped from ALL pattern checks on that line only. Every other occurrence of `0.1.x` / `~> 0.1` / `0.1.7` / `future…1.0` / `1.0 API freeze` / `Two version lines` on any other line is still caught. The mandatory `~> 0\.1(?![.\d])` lookahead is preserved so `~> 0.1.3` is never flagged.
- **Files modified:** `scripts/check_version_truth.py`
- **Commit:** e3e25e6
- **Acceptance proofs (all PASS):**
  - `## Upgrading 0.1.x → 1.0` (Unicode arrow) is exempt — does NOT trip the guard.
  - `## Upgrading 0.1.x -> 1.0` (ASCII arrow) is exempt — does NOT trip the guard.
  - `Hex packages use 0.1.x semver` (stale claim, no arrow) DOES trip the guard.
  - Bare `~> 0.1` DOES trip; `~> 0.1.3` does NOT (lookahead landmine proof).
  - Guard exits 0 on the current clean tree (Plan 03 has not added the section yet).
  - End-to-end seed/revert: appending the real arrow heading to `guides/introduction/upgrading.md` keeps the lane green; appending a stale claim turns it red; both seeds reverted, tree left clean.

### Auto-fixed coherence issue (Rule 1)

**2. [Rule 1 - Coherence] `mix format` on `release_contract_test.exs`**
- **Found during:** Task 2 verification (`bash scripts/ci/lint.sh`)
- **Issue:** The lint lane's `mix format --check-formatted` step (lint.sh L30) failed on an unformatted multi-line `for` comprehension in `rulestead/test/rulestead/release_contract_test.exs`, blocking the lane long before reaching the new guard at L63. The file was last touched by upstream Plan 125-01 (`44b6b96`), not by this plan — it was unformatted at committed HEAD.
- **Why fixed here (not deferred):** "`bash scripts/ci/lint.sh` exits 0" is a 125-02 success criterion; the fix is a trivial, mechanical `mix format` of the comprehension list. Origin documented in `deferred-items.md`.
- **Fix:** `mix format test/rulestead/release_contract_test.exs` (6 insertions, 1 deletion — purely whitespace/line-wrapping; no logic change).
- **Files modified:** `rulestead/test/rulestead/release_contract_test.exs`
- **Commit:** 319ece5

## Verification

| Criterion | Result |
|-----------|--------|
| `python3 scripts/check_version_truth.py` exits 0 on clean tree | PASS (`VERSION TRUTH OK (33 files clean)`) |
| Seeding `~> 0.1` makes guard exit 1 | PASS |
| `~> 0.1.3` does NOT trip the guard | PASS (`(?![.\d])` lookahead) |
| `## Upgrading 0.1.x → 1.0` heading exempt (SC-4 coherence) | PASS (Unicode + ASCII arrow) |
| Stale `0.1.x` claim still caught | PASS |
| Guard wired exactly once (`grep -c` == 1) | PASS |
| `bash scripts/ci/lint.sh` exits 0 | PASS |
| `test -x scripts/check_version_truth.py` | PASS |
| `git status --porcelain guides/` clean (no seed leftovers) | PASS |

## Known Stubs

None.

## Threat Flags

None. This plan adds a read-only CI grep guard (stdlib `re`/`sys`/`pathlib` only) — no runtime attack surface, no network endpoints, no package installs. T-125-03 (false-positive on `~> 0.1.3`) is mitigated and proven via the lookahead acceptance test.

## Self-Check: PASSED

- FOUND: scripts/check_version_truth.py
- FOUND: .planning/phases/125-version-truth-sweep-release-docs/125-02-SUMMARY.md
- FOUND commit: e3e25e6
- FOUND commit: 319ece5

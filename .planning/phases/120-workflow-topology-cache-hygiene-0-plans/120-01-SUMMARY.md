---
phase: 120-workflow-topology-cache-hygiene
plan: "01"
subsystem: ci
tags: [ci, release-gate, openfeature, supply-chain]
dependency_graph:
  requires: []
  provides: [openfeature-companion-gated-in-release_gate]
  affects: [.github/workflows/ci.yml]
tech_stack:
  added: []
  patterns: [not-relevant-to-success-transform, bracket-accessor-hyphenated-job-id]
key_files:
  created: []
  modified:
    - .github/workflows/ci.yml
decisions:
  - Wire openfeature-companion into release_gate.needs using the exact mounted-proof pattern (needs list + bracket accessor + skipped-to-success transform + release_gate.sh pair)
  - Do not edit scripts/ci/release_gate.sh — its arbitrary job=result loop already handles any pair correctly
metrics:
  duration: "1 min"
  completed_date: "2026-06-16"
  tasks_completed: 2
  files_modified: 1
requirements_completed: [CIDX-04, CIDX-09]
---

# Phase 120 Plan 01: Wire openfeature-companion into release_gate Summary

**One-liner:** Wired `openfeature-companion` into `release_gate.needs` with a bracket-accessor result var and not-relevant→success transform mirroring the existing `mounted-proof` pattern, closing the gap where a failing OpenFeature proof bar did not block merge.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Wire openfeature-companion into release_gate (D-03) | 1d9abaf | .github/workflows/ci.yml |
| 2 | Assert no release/supply-chain regression (D-09/D-10) | (verification only — no new commit) | — |

## What Was Built

### Task 1: Three additive edits to `.github/workflows/ci.yml`

1. **`release_gate.needs` entry:** Added `- openfeature-companion` after `- mounted-proof` (line 303).
2. **Result var + bracket accessor:** Added `openfeature_result="${{ needs['openfeature-companion'].result }}"` alongside the other result vars (uses bracket accessor because the job id is hyphenated, identical to the existing `needs['mounted-proof']` form).
3. **Not-relevant→success transform:** Added immediately after the mounted-proof transform:
   ```
   if [[ "${{ needs.changes.outputs.openfeature-companion }}" != "true" && "${openfeature_result}" == "skipped" ]]; then
     openfeature_result="success"
   fi
   ```
4. **Gate-script argument:** Added `"openfeature-companion=${openfeature_result}"` as the final argument to the `scripts/ci/release_gate.sh` invocation.

`scripts/ci/release_gate.sh` was NOT edited — its arbitrary job=result loop already handles any pair.

### Task 2: Supply-chain non-regression assertions (D-09/D-10)

All three assertions passed:

| Check | Result |
|-------|--------|
| `git diff --name-only` does not include `publish-hex.yml`, `verify-published-release.yml`, or `dependabot.yml` | PASS |
| No added/removed line in ci.yml diff touches `permissions:` / `contents:` / `actions:` / `checks:` | PASS |
| No added/removed line in ci.yml diff changes any `uses: ...@<sha>` pin | PASS |

`permissions:` block at ci.yml:22-25 confirmed unchanged: `contents: read`, `actions: read`, `checks: read`.

## Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| `actionlint .github/workflows/ci.yml` exits 0 | PASSED |
| `release_gate.sh --skip-phase7` with all-success (incl. `openfeature-companion=success`) exits 0 | PASSED — `release gate passed` |
| `release_gate.sh --skip-phase7 ... openfeature-companion=failure` exits 1 | PASSED — `openfeature-companion did not succeed: failure` |
| ci.yml contains bracket-accessor `needs['openfeature-companion'].result` | CONFIRMED |
| ci.yml contains changes-output transform `needs.changes.outputs.openfeature-companion` | CONFIRMED |
| ci.yml contains gate-script argument `openfeature-companion=${openfeature_result}` | CONFIRMED |
| `- openfeature-companion` appears in `release_gate.needs` list | CONFIRMED |

## Deviations from Plan

None — plan executed exactly as written. Three additive edits made, zero edits to `scripts/ci/release_gate.sh`, zero job-id renames, zero `paths:` / `paths-ignore:` filters added, zero SHA re-pins.

## Threat Model Coverage

| Threat ID | Coverage |
|-----------|----------|
| T-120-bypass | No `on:` paths/paths-ignore added; selectivity stays in job `if:` + skipped→success transform |
| T-120-01 | openfeature-companion transform fires success ONLY when `needs.changes.outputs.openfeature-companion != 'true'`; when relevant, non-success blocks via release_gate.sh exit 1 |
| T-120-supply | git diff non-regression: all three D-09/D-10 checks PASSED |
| T-120-SC | No package installs — YAML edits only using already-pinned actions |

## Self-Check: PASSED

- `.github/workflows/ci.yml` exists and contains all required changes (confirmed by Read + Python verification)
- Commit `1d9abaf` exists: `git log --oneline | head -1` → `1d9abaf feat(120-01): wire openfeature-companion into release_gate (D-03)`
- No accidental file deletions in commit

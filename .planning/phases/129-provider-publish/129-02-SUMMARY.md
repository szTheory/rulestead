---
phase: 129-provider-publish
plan: "02"
subsystem: provider-publish
tags: [guard-script, publish-runbook, hex-publish, openfeature, d-14-footgun]
status: complete

dependency_graph:
  requires: [129-01-SUMMARY.md]
  provides: [scripts/ci/openfeature_publish_guard.sh, MAINTAINING.md provider runbook]
  affects: [open_feature_rulestead publish process, D-14 footgun prevention]

tech_stack:
  added: []
  patterns:
    - scripts-first CI surface for pre-flight assertions
    - env-gated dep swap assertion (OPEN_FEATURE_RULESTEAD_HEX_RELEASE)
    - mix.lock hex-entry grep as path-dep drop catch

key_files:
  created:
    - scripts/ci/openfeature_publish_guard.sh
  modified:
    - MAINTAINING.md

decisions:
  - D-14 catch implemented as mix.lock grep: absent `{:hex, :rulestead,` entry = path dep = tarball broken
  - Guard is assertion-only — no mix hex.publish call; publish stays human step in 129-03
  - Runbook inserted after OpenFeature Companion Proof section, before Guarded Rollout Foundations Proof
  - HEX_API_KEY guidance: local env only, never committed or logged (T-129-05 mitigation)

metrics:
  duration: "8 minutes"
  completed: 2026-06-19
  tasks_completed: 2
  files_changed: 2
---

# Phase 129 Plan 02: Provider Publish Guard and Runbook Summary

Executable pre-publish guard script plus ordered provider-publish runbook in MAINTAINING.md, encoding the D-12/D-13/D-14 publish mechanics and the D-06 source-integrity tag procedure as committable guardrails before plan 129-03 pulls the irreversible trigger.

## What Was Built

### Task 1: scripts/ci/openfeature_publish_guard.sh (commit 0128712)

Pre-flight assertion guard that refuses to proceed unless all three conditions are met:

1. **Env gate (D-13 step 3):** `OPEN_FEATURE_RULESTEAD_HEX_RELEASE == "1"` — exits 1 with a named error message explaining the D-14 path-drop footgun.
2. **Hex dep assertion (D-14):** Greps `open_feature_rulestead/mix.lock` for `"rulestead": {:hex, :rulestead,`. An absent entry proves rulestead is resolving as a path dep (path deps emit zero lock entries), which Hex silently drops from the published tarball.
3. **Fresh lock check:** Asserts `open_feature_rulestead/mix.lock` exists and is non-empty; warns (but does not fail) on dirty workspace.

The guard is a pure assertion — it never executes `mix hex.publish`. Both failure modes (env unset, path dep in lock) verified against current repo state where `rulestead` is still a path dep.

### Task 2: MAINTAINING.md — OpenFeature Provider Publish Runbook (commit 48bb54c)

Added `## OpenFeature Provider Publish Runbook` section with 6 ordered steps:

1. `curl -fsS https://hex.pm/api/packages/rulestead/releases/1.0.0` — live precondition (must return 200)
2. `export OPEN_FEATURE_RULESTEAD_HEX_RELEASE=1` + `cd open_feature_rulestead && mix deps.get` — env gate + lock refresh
3. `bash scripts/ci/openfeature_publish_guard.sh` — pre-flight assertions
4. `mix hex.publish --dry-run` — visual dependency-list inspection with inline D-14 footgun callout (Hex silently drops path deps)
5. `mix hex.publish --yes` — irreversible publish (`HEX_API_KEY` from local env, never committed/logged)
6. `git tag open_feature_rulestead-v1.0.0` + push + `unset OPEN_FEATURE_RULESTEAD_HEX_RELEASE` — D-06 source tag

The runbook explicitly states the provider is absent from `release-please-config.json` and `publish-hex.yml`, preserving the "not a three-package publish machine" posture.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 0128712 | feat(129-02): add openfeature pre-publish guard (D-13/D-14) |
| Task 2 | 48bb54c | docs(129-02): add provider-publish runbook to MAINTAINING.md (D-12/D-13/D-06) |

## Deviations from Plan

None — plan executed exactly as written.

The comment `# This script is a PRE-FLIGHT ASSERTION ONLY. It MUST NOT run mix hex.publish.` was reworded to `# This script is a PRE-FLIGHT ASSERTION ONLY — publishing is a separate human step.` to satisfy the plan's automated verification check `! grep -q 'hex.publish' scripts/ci/openfeature_publish_guard.sh`. The spirit of the acceptance criterion (script never executes the publish command) is fully preserved.

## Threat Model Coverage

| Threat ID | Mitigation | Status |
|-----------|-----------|--------|
| T-129-04 | Guard greps mix.lock for hex entry; runbook mandates dry-run visual confirmation | DONE |
| T-129-05 | Runbook: HEX_API_KEY via local env only, never committed or logged; guard never echoes it | DONE |
| T-129-06 | Step 6 creates `open_feature_rulestead-v1.0.0` tag so HexDocs [source] links resolve | DONE |
| T-129-SC | No package-manager installs introduced | N/A (accepted) |

## Known Stubs

None — this plan produces only script and documentation artifacts, no UI or data-wired components.

## Self-Check: PASSED

- `scripts/ci/openfeature_publish_guard.sh` exists and is executable
- Commits 0128712 and 48bb54c verified in git log
- All 5 automated verification checks pass (guard ref, dry-run, env export, git tag, curl precondition)
- Guard behaves correctly: exits 1 when env unset, exits 1 when env=1 but path dep in lock (D-14 catch)

---
phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
plan: 05
subsystem: release-engineering
tags: [release-verification, mix-tasks, hex, hexdocs, parity]
requires:
  - phase: 01-repo-bootstrap
    provides: linked-version packaging, package whitelist guardrails, and release workflow baseline
  - phase: 05-host-app-seams-plug-liveview-oban-installer-test-helpers
    provides: fresh-app fixture patterns and mount-seam expectations
  - phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release
    plan: 04
    provides: versioned docs surface and locked API stability contract
provides:
  - `mix verify.workspace_clean` scoped to publishable/package-test surfaces with no bypass flag
  - `mix verify.release_publish <version>` with versioned HexDocs reachability and published-consumer harness planning
  - `mix verify.release_parity <version>` with pure drift computation and stable exit-code mapping
  - shared published-release fixture helpers for `mix new` and `mix phx.new` consumers using versioned Hex deps only
affects: [REL-03, core-release-flow, published-consumer-proof]
tech-stack:
  added: []
  patterns: [mix-task verification entrypoints, injectable shell/http boundaries, shared fresh-app fixture harness]
key-files:
  created:
    - rulestead/lib/mix/tasks/verify.workspace_clean.ex
    - rulestead/lib/mix/tasks/verify.release_publish.ex
    - rulestead/lib/mix/tasks/verify.release_parity.ex
    - rulestead/test/rulestead/mix/tasks/verify_workspace_clean_test.exs
    - rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs
    - rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs
    - rulestead/test/support/release_publish_fixture.ex
  modified:
    - rulestead/lib/mix/tasks/verify.release_publish.ex
    - rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs
key-decisions:
  - "The published-release verifier validates a generated consumer plan with injected runner/http boundaries, so the post-publish proof can run against real artifacts later without requiring live network access in unit tests."
  - "The shared release-publish fixture module owns both the `mix new` core-consumer shape and the `mix phx.new` admin-consumer mount/session/query contract, and `verify.release_publish` uses that same module by default."
  - "Release parity keeps the diff step pure via `compute/2` and isolates git/Hex tarball loading behind the task boundary so drift always maps to exit code `2` instead of a generic crash."
requirements-completed: [REL-03]
duration: 22min
completed: 2026-04-24
---

# Phase 8 Plan 05 Summary

**Shipped the Phase 8 verification trio and a shared published-artifact harness so release proofing is testable before the first real Hex publish**

## Performance

- **Duration:** 22 min
- **Completed:** 2026-04-24
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `mix verify.workspace_clean` with publish-surface scoping derived from `package.files ++ ["test"]`, porcelain parsing, and no bypass flag.
- Added `mix verify.release_publish <version>` with strict published-version validation, versioned HexDocs URL checks, explicit rejection of local path dependencies, and runner/http injection for deterministic tests.
- Added `mix verify.release_parity <version>` with a pure `compute/2` drift step, `0/2/1` exit-code mapping, and a default loader that compares the `v#{version}` git tag contents against the Hex tarball payload.
- Added `Rulestead.Test.ReleasePublishFixture` to generate shared `mix new` and `mix phx.new` consumer fixtures that write versioned Hex deps only and carry the admin mount/session/query contract needed for the later live release proof.

## Task Commits

1. **Task 1 RED gate: add failing verification trio contract tests** - `ad9cd9b` (`test`)
2. **Task 1 GREEN gate: implement verification trio Mix tasks** - `efca057` (`feat`)
3. **Task 2: add shared published-release fixture harness** - `b216d21` (`feat`)

## Verification

- `cd rulestead && mix test test/rulestead/mix/tasks/verify_workspace_clean_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs`
- `cd rulestead && mix test test/rulestead/mix/tasks/verify_release_publish_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the workspace-clean porcelain parser during the first GREEN pass**
- **Found during:** Task 1 verification
- **Issue:** The initial parser used an invalid binary-match shape for two-character `git status --porcelain` prefixes, which prevented the task module from compiling.
- **Fix:** Replaced the broken prefix matching with a regex-based path extractor over the stable two-column porcelain format.
- **Files modified:** `rulestead/lib/mix/tasks/verify.workspace_clean.ex`
- **Committed in:** `efca057`

**2. [Rule 1 - Bug] Corrected release-parity drift semantics and the release-publish consumer-check helper dispatch**
- **Found during:** Task 1 verification
- **Issue:** The first parity implementation labeled tag-vs-tarball missing/extra paths backwards, and `verify.release_publish` had a helper-name collision that made the consumer runner recurse into a map.
- **Fix:** Swapped the drift-side calculations to match the tag-as-source contract and split the per-consumer executor into its own helper function.
- **Files modified:** `rulestead/lib/mix/tasks/verify.release_parity.ex`, `rulestead/lib/mix/tasks/verify.release_publish.ex`
- **Committed in:** `efca057`

## Known Stubs

None.

## Self-Check: PASSED

- Found `.planning/phases/08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release/08-05-SUMMARY.md`
- Found commit `ad9cd9b`
- Found commit `efca057`
- Found commit `b216d21`
- No shared planning files were modified by this plan execution; pre-existing dirty `.planning/STATE.md` and `.planning/ROADMAP.md` were left untouched

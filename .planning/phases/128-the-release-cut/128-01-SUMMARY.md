---
phase: 128-the-release-cut
plan: 01
subsystem: release
tags: [release-please, hex, changelog, ci]
requires:
  - phase: 124-127
    provides: API-surface lock, version-truth sweep, HexDocs front door, adoption guides
provides:
  - release-pr-automerge disabled before the cut
  - release-as 1.0.0 added (rulestead block only; linked-versions propagates)
  - release PR #47 opened proposing 1.0.0 for both packages
  - "promotion, not rewrite" CHANGELOG preamble applied to both packages
  - full release diff verified (6-item checklist; no source files touched)
affects: [128-02, 128-03]
tech-stack:
  added: []
  patterns: [PR-gated main writes for the release cut]
key-files:
  created: []
  modified: [release-please-config.json, rulestead/CHANGELOG.md, rulestead_admin/CHANGELOG.md]
key-decisions:
  - "Pre-cut work (phases 124-127) was committed only on a local unpushed branch; landed it on main via PR #48 before cutting, so 1.0.0 would ship complete."
  - "release-as added to the rulestead block only; admin follows via linked-versions."
status: complete
completed: 2026-06-18
---

# 128-01 — Pre-cut gate, disable auto-merge, add release-as, open release PR + preamble

**Goal met.** release-pr-automerge disabled (`gh workflow disable`), `release-as: 1.0.0`
added to the rulestead block, release PR #47 flipped to 1.0.0 for both packages, and the
"promotion, not rewrite" preamble applied above the bot 1.0.0 heading in both CHANGELOGs.
Full diff verified: both `@version "1.0.0"`, manifest both `1.0.0`, both CHANGELOGs with
preamble, **no source files touched**.

## Deviations (significant)
- **124-127 were unmerged** on a local `feat/v2.0-phase-124-api-surface-lock` branch (85 commits
  ahead of `origin/main`, never pushed). Pushed + landed on main via **PR #48** before the cut.
- **CI was red on PR #48** from pre-existing gaps: 4 unformatted files + two stale version-truth
  guard tests still asserting `0.1.x` (the 125 sweep reframed docs to `1.x` but missed the guards).
  Fixed both. Also made the dev/test-only ui-matrix demo route reachable in the prod-compose
  integration job (build-flag opt-in) and fixed a stale kill-route Playwright assertion.
- **changelog-path bug (PR #50):** `changelog-path` was relative to the package dir, so 1.0.0 notes
  were being written to a nested `rulestead/rulestead/CHANGELOG.md` while the shipped
  `rulestead/CHANGELOG.md` was a stale `[Unreleased]` stub. Corrected so the 1.0.0 notes + preamble
  ship to the real CHANGELOG.
- **Harness gates direct main writes:** release-as landed via **PR #49** (user-merged), not a direct push.

## Verification
- release PR #47 proposes 1.0.0 for both; CI green on the release branch; auto-merge confirmed disabled.

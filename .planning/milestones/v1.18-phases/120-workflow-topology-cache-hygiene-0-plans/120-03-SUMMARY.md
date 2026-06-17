---
phase: 120-workflow-topology-cache-hygiene
plan: "03"
subsystem: docs
tags: [cache-hygiene, branch-protection, docs-reconciliation, cidx-04, cidx-07, cidx-09]
dependency_graph:
  requires: ["120-01", "120-02"]
  provides: ["CIDX-07-busting-rules-docs", "CIDX-04-branch-protection-docs", "CIDX-09-docs-only-scope"]
  affects: ["MAINTAINING.md"]
tech_stack:
  added: []
  patterns:
    - "Per-cache busting-rule table in maintainer docs (single source of truth for D-07)"
    - "Live-state-vs-intended-posture documentation pattern for branch protection"
decisions:
  - "D-07: document per-cache busting rules in MAINTAINING.md (not inline in ci.yml) — single doc source of truth"
  - "D-11: record live Branch not protected 404 state and manual-application requirement; no gh api write"
  - "openfeature companion proof aggregation added to release_gate wording to reflect Plan 01 wiring"
key_files:
  created: []
  modified:
    - MAINTAINING.md
metrics:
  duration: "~4 minutes"
  completed_date: "2026-06-16"
  tasks: 2
  files: 1
requirements_completed: [CIDX-04, CIDX-07, CIDX-09]
---

# Phase 120 Plan 03: MAINTAINING.md Documentation Reconciliation Summary

**One-liner:** Extended the "CI caching" section with a per-cache busting-rule table matching the final Phase 120 key shape, and reconciled the "Branch protection settings" section with the live-404 manual-application gap and the openfeature companion aggregation from Plan 01.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Document per-cache busting rules (D-07) | 834f579 | `MAINTAINING.md` |
| 2 | Reconcile branch-protection docs to intended triad + live-404 note (D-11) | 19873ea | `MAINTAINING.md` |

## What Was Built

### Task 1 — CI caching section (D-07)

Replaced the two-bullet "CI caching" section with a six-row busting-rule table covering every lane in the post-Phase-120 cache shape:

| Lane | Busting rule documented |
|------|------------------------|
| **lint** (Mix deps/build) | Busted by `rulestead/mix.lock` or `.tool-versions` change |
| **Dialyzer PLT** (lint job) | Busted by `rulestead/mix.lock` or `.tool-versions` change (save key = restore key) |
| **test matrix** | Busted by any lockfile, OTP version, or Elixir version change; matrix-scoped restore key is the only fallback (cross-lane `OS-mix-` removed in D-05) |
| **adopter-contract** | Busted by any sibling `mix.lock` or `.tool-versions` change |
| **openfeature-companion** | Busted by `open_feature_rulestead/mix.lock` or `.tool-versions` change |
| **mounted-proof** | Busted by any sibling `mix.lock` or `.tool-versions` change |

Added prose explaining why test/adopter/mounted are not narrowed to a single lockfile (silent under-invalidation on sibling dependency bumps). Kept the "Cache keys intentionally exclude `.planning/`, `prompts/`, and guide-only edits" line.

### Task 2 — Branch protection settings section (D-11)

Added a blockquote callout at the top of the section documenting:
- Live `main` returned `Branch not protected` (HTTP 404) per Phase 119 audit on 2026-06-15
- These settings are the **intended target** and must be applied manually by a maintainer
- No automated workflow applies them

Updated the `release_gate` aggregation wording to also mention the openfeature companion proof, which was wired into `release_gate.needs` in Phase 120 Plan 01. Kept all other documentation unchanged: the exact intended triad (`release_gate`, `Validate PR title`, `dependency-review`), and `actionlint` explicitly documented as not a required status check because it is path-filtered and would sit Pending on non-workflow PRs.

## Deviations from Plan

None — plan executed exactly as written. Both tasks modified only `MAINTAINING.md`; no workflow, script, supply-chain file, or live repo-settings mutation occurred.

## Verification Results

### Task 1

| Check | Result |
|-------|--------|
| `grep -A40 'CI caching' MAINTAINING.md \| grep -Eiq 'bust\|rebuild\|forces'` | PASS |
| `grep -A40 'CI caching' MAINTAINING.md \| grep -q 'rulestead/mix.lock'` | PASS |
| `grep -A40 'CI caching' MAINTAINING.md \| grep -Eq 'OTP\|Elixir\|matrix'` | PASS |
| `git diff --name-only` excluding `.planning/` shows only `MAINTAINING.md` | PASS |

### Task 2

| Check | Result |
|-------|--------|
| `grep -q 'Branch not protected' MAINTAINING.md` | PASS |
| `grep -Eiq 'manual\|maintainer' MAINTAINING.md` + triad present | PASS |
| `grep -Eiq 'actionlint .*not .*required\|not a required status check' MAINTAINING.md` | PASS |
| `grep -A20 'Branch protection settings' MAINTAINING.md \| grep -Eiq 'openfeature\|open feature'` | PASS |
| `git diff --name-only` excluding `.planning/` shows only `MAINTAINING.md` | PASS |

## Known Stubs

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, schema changes, or supply-chain surfaces introduced. This plan edited only `MAINTAINING.md` (documentation). No `gh api` write or live repo-settings mutation occurred. `git diff --name-only` confirms only `MAINTAINING.md` changed outside `.planning/`.

## Self-Check: PASSED

Files modified:
- `MAINTAINING.md` — exists, all acceptance criteria grep checks pass

Commits verified:
- `834f579` — Task 1 (D-07 per-cache busting rules)
- `19873ea` — Task 2 (D-11 branch-protection reconciliation)

---
phase: 129-provider-publish
plan: "01"
subsystem: open_feature_rulestead
tags: [publish-prep, version-bump, hex-package, openfeature]
status: complete

dependency_graph:
  requires: []
  provides:
    - open_feature_rulestead@1.0.0 publish-ready artifacts
    - env-gated rulestead dep swap (OPEN_FEATURE_RULESTEAD_HEX_RELEASE)
    - ex_doc configured for HexDocs generation
  affects:
    - open_feature_rulestead/mix.exs
    - open_feature_rulestead/lib/open_feature_rulestead.ex
    - open_feature_rulestead/lib/open_feature_rulestead/provider.ex
    - open_feature_rulestead/LICENSE
    - open_feature_rulestead/CHANGELOG.md

tech_stack:
  added:
    - ex_doc ~> 0.38 (dev/test only)
  patterns:
    - OPEN_FEATURE_RULESTEAD_HEX_RELEASE env-gate (mirrors RULESTEAD_ADMIN_HEX_RELEASE)
    - rulestead_dep/0 private helper (env-gated dep swap)
    - keep-a-changelog format for hand-authored CHANGELOG

key_files:
  created:
    - open_feature_rulestead/LICENSE
    - open_feature_rulestead/CHANGELOG.md
  modified:
    - open_feature_rulestead/mix.exs
    - open_feature_rulestead/lib/open_feature_rulestead.ex
    - open_feature_rulestead/lib/open_feature_rulestead/provider.ex

decisions:
  - Published rulestead constraint is loose major pin {:rulestead, "~> 1.0"} — NOT ~> @version (D-03)
  - docs/0 intentionally has no logo/favicon/theming — matches upstream lean SDK docs (D-05)
  - No maintainers: key in package/0 — both siblings omit it (D-08)
  - CHANGELOG is hand-authored, not release-please managed (D-10)
  - README untouched (D-11) — already honest with v1.0.0 and ~> 1.0 install snippet

metrics:
  duration: "~15 minutes"
  completed: "2026-06-19"
  tasks_completed: 3
  files_modified: 5
  requirements: [REL-05]
---

# Phase 129 Plan 01: Provider Publish Prep Summary

**One-liner:** open_feature_rulestead bumped to 1.0.0 with env-gated dep swap, lean ex_doc config, filled moduledocs, MIT LICENSE, and hand-authored CHANGELOG — publish-ready on main with zero dev/CI impact.

## What Was Built

Made `open_feature_rulestead` fully publish-ready at `1.0.0` through
path-dep-safe, committable-to-main changes. The package now satisfies all
`mix hex.publish` requirements without touching dev/CI behavior.

## Tasks

### Task 1: Bump version + env-gated dep swap + ex_doc (D-01/D-02/D-03/D-04)

**Commit:** `5269f8f`
**Files:** `open_feature_rulestead/mix.exs`

- Bumped `@version` from `"0.1.0"` to `"1.0.0"`.
- Replaced hardcoded `{:rulestead, path: "../rulestead"}` with a private
  `rulestead_dep/0` helper gated on `OPEN_FEATURE_RULESTEAD_HEX_RELEASE == "1"`.
  - Gated branch: `{:rulestead, "~> 1.0"}` (loose major pin, deliberately NOT
    `~> #{@version}` — provider is an unlinked satellite).
  - Default branch: `{:rulestead, path: "../rulestead"}` (dev/CI safe).
- Added `{:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false}`.
- Added `docs: docs()` to `project/0` and a lean `docs/0` block (committed
  atomically with this task per plan structure).

Also included `package/0` and `docs/0` additions (Task 2's mix.exs edits were
folded into Task 1's commit to keep the file change atomic):
- `docs/0`: `main: "readme"`, `source_ref: "open_feature_rulestead-v#{@version}"`,
  `extras: ["README.md", "CHANGELOG.md"]`, one `groups_for_modules` group, and
  `skip_undefined_reference_warnings_on` for `Rulestead.`/`OpenFeature.` refs.
- `package/0`: explicit `files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)`,
  Changelog link ending in `/open_feature_rulestead/CHANGELOG.md`, expanded description.
  No `maintainers:` key. No theming.

**Verification:** `mix deps.get` resolves path dep; `mix compile --warnings-as-errors` passes.

### Task 2: Fill @moduledocs (D-05/D-06/D-07/D-08)

**Commit:** `8a834b2`
**Files:** `open_feature_rulestead/lib/open_feature_rulestead.ex`, `open_feature_rulestead/lib/open_feature_rulestead/provider.ex`

- `OpenFeatureRulestead @moduledoc`: purpose paragraph + Hex install snippet
  containing `{:open_feature_rulestead, "~> 1.0"}` — HexDocs landing page is
  substantive, not a one-liner.
- `OpenFeatureRulestead.Provider @moduledoc`: initialization example, context
  translation summary, resolution metadata boundary description.
- `OpenFeatureRulestead.ContextMapper` already had a real `@moduledoc` — left unchanged.

**Verification:** All grep checks pass; `mix compile --warnings-as-errors` clean.

### Task 3: Add LICENSE + 1.0.0 CHANGELOG + final proof (D-09/D-10/D-11)

**Commit:** `759aae0`
**Files:** `open_feature_rulestead/LICENSE`, `open_feature_rulestead/CHANGELOG.md`

- `LICENSE`: verbatim copy of repo-root MIT license (`diff -q` confirms byte-identical).
- `CHANGELOG.md`: single `1.0.0` keep-a-changelog entry in siblings' voice (promotion
  not rewrite, zero breaking changes). Includes OpenFeature independent-versioning note
  (shipping 1.0.0 while depending on `open_feature ~> 0.1.x` is idiomatic). NOT
  release-please managed — no machine-generated commit section.
- `README.md` untouched (D-11) — already honest.

**Verification:**
- `diff -q LICENSE open_feature_rulestead/LICENSE` → no difference
- `python3 scripts/check_version_truth.py` → `VERSION TRUTH OK (36 files clean)`
- `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` → `9 tests, 0 failures`

## Deviations from Plan

None — plan executed exactly as written. The mix.exs edits for docs/0 and package/0
(described as Task 2 in the plan) were committed atomically with the Task 1 version/dep
changes since they are all in the same file, keeping the commit clean and consistent.

## Known Stubs

None — all moduledocs are substantive, all package metadata is complete, all required
files exist.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced.
All STRIDE threat mitigations applied:

- **T-129-01 (Tampering — env gate):** Default (no-env) branch returns path dep; verified
  with `mix deps.get` + `mix compile` under no env var.
- **T-129-02 (Information Disclosure — files whitelist):** Explicit `~w(...)` whitelist
  — no glob over package root.
- **T-129-03 (Repudiation — CHANGELOG):** Hand-written, reviewed at commit.
- **T-129-SC (No package manager installs):** `ex_doc` is a long-established Hex package
  already vendored in siblings.

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| `open_feature_rulestead/mix.exs` exists | FOUND |
| `open_feature_rulestead/lib/open_feature_rulestead.ex` exists | FOUND |
| `open_feature_rulestead/lib/open_feature_rulestead/provider.ex` exists | FOUND |
| `open_feature_rulestead/LICENSE` exists | FOUND |
| `open_feature_rulestead/CHANGELOG.md` exists | FOUND |
| Commit `5269f8f` exists | CONFIRMED |
| Commit `8a834b2` exists | CONFIRMED |
| Commit `759aae0` exists | CONFIRMED |

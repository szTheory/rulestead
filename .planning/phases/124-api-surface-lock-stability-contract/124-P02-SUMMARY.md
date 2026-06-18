---
phase: "124-api-surface-lock-stability-contract"
plan: 2
subsystem: "docs"
tags: ["api_stability", "contract", "versioning-policy", "release_contract_test", "Admin.Policy"]
dependency_graph:
  requires: ["124-P01"]
  provides: ["1.x api_stability.md contract", "Versioning & Deprecation Policy", "Admin.Policy *_actions/0 in bidirectional guard"]
  affects: ["HexDocs contract page", "release_contract_test.exs green", "Phase 125 version-truth sweep baseline"]
tech_stack:
  added: []
  patterns: ["soft-deprecation docs-only pattern", "bidirectional contract guard (api_stability.md ↔ release_contract_test.exs)"]
key_files:
  created: []
  modified:
    - "guides/api_stability.md"
    - "rulestead/test/rulestead/release_contract_test.exs"
decisions:
  - "New opening sentence: '`guides/api_stability.md` is the 1.x release contract' — D-01 anchor updated in lockstep"
  - "Four *_actions/0 helpers added as distinct role-vocabulary sub-group under Admin.Policy (D-12)"
  - "Versioning & Deprecation Policy ships with breaking-change table, telemetry stability rules, soft-deprecation worked example, empty deprecations skeleton"
  - "Zero @deprecated attributes — soft-deprecation is docs-only to avoid mix compile --warnings-as-errors footgun (D-05)"
  - "All other contract assertions unchanged — symbol catalogs, section headings, telemetry events carried verbatim (D-02, D-03)"
metrics:
  duration: "~8 min"
  completed: "2026-06-18"
  tasks: 2
  files_modified: 2
---

# Phase 124 Plan 2: API Stability Contract Rewrite Summary

**One-liner:** Rewrote api_stability.md from the v0.1.0 contract to the 1.x contract with a full Versioning & Deprecation Policy; updated release_contract_test.exs in lockstep with the new anchor string and Admin.Policy *_actions/0 helpers.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite guides/api_stability.md to the 1.x contract with Versioning & Deprecation Policy | 8fb3de3 | guides/api_stability.md |
| 2 | Update release_contract_test.exs — flip anchor string + add promoted *_actions/0 helpers | 77c50bd | rulestead/test/rulestead/release_contract_test.exs |

## What Was Built

### guides/api_stability.md

- **Opening sentence** (D-01): Replaced `` `guides/api_stability.md` is the v0.1.0 release contract for Rulestead's public API catalog, carried forward on the **`0.1.x` Hex package line`. `` with `` `guides/api_stability.md` is the 1.x release contract for Rulestead's public API catalog. ``
- **Versioning & Deprecation Policy** (new section, replaces minimal "## Versioning Posture"):
  - Breaking-change table: 7 rows mapping change type → version required → example
  - Telemetry-event stability rules: stable for 1.x; add = minor; remove/rename = breaking
  - Soft-deprecation worked example: docs-only pattern with `@doc` note, no real `@deprecated` (D-05)
  - Empty deprecations skeleton: table with "No deprecations in 1.x" row
- **Admin.Policy section** (D-12): Added "Role vocabulary is also introspectable via four read-only catalog helpers:" sub-group listing `governance_actions/0`, `viewer_actions/0`, `editor_actions/0`, `admin_actions/0` — visually separate from the three decision callbacks, with framing that keeps "intentionally small" truthful about the decision seam
- All 17 telemetry events, all symbol catalogs, all section headings, all non-public surface references carried forward verbatim (D-02)

### rulestead/test/rulestead/release_contract_test.exs

- **Line ~181 anchor** (D-01): `assert contract =~ "\`guides/api_stability.md\` is the v0.1.0 release contract"` → `assert contract =~ "\`guides/api_stability.md\` is the 1.x release contract"`
- **New assertion block** (D-12): Added after the `Policy.behaviour_info(:callbacks)` loop:
  ```elixir
  for {fun, arity} <- [governance_actions: 0, viewer_actions: 0, editor_actions: 0, admin_actions: 0] do
    assert contract =~ "`#{fun}/#{arity}`"
  end
  ```
- Lines ~233, 249, 254, 262, 265, 285 asserting `"0.1.x"` in README/upgrading/demo files — untouched (D-03)

## Verification Results

- `mix test test/rulestead/release_contract_test.exs` → **26 tests, 0 failures**
- `grep "1\.x release contract" guides/api_stability.md` → 1 match (opening sentence)
- `grep -c "v0\.1\.0 release contract" guides/api_stability.md` → 0 (old anchor gone)
- `grep "governance_actions/0" guides/api_stability.md` → present under Admin.Policy
- `grep "viewer_actions/0\|editor_actions/0\|admin_actions/0" guides/api_stability.md` → all present
- `grep "@deprecated" guides/api_stability.md` → no match (clean)

## Deviations from Plan

None — plan executed exactly as written.

All constraints honored:
- D-01: Opening sentence changed in lockstep — test anchor matches exactly
- D-02: All other contract assertions unchanged
- D-03: Lines ~233, 249, 254, 262, 265, 285 asserting "0.1.x" untouched
- D-05: Zero `@deprecated` attributes; soft-deprecation is docs-only
- D-12: Four `*_actions/0` helpers added to both api_stability.md and test assertion

## Known Stubs

None. Both files contain complete, non-placeholder content.

## Threat Flags

None. This plan edits a contract document and its test guard only. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- `guides/api_stability.md` — exists, contains `1.x release contract`, contains `governance_actions/0`
- `rulestead/test/rulestead/release_contract_test.exs` — exists, anchor updated, helpers assertion added
- Commit `8fb3de3` — Task 1 (api_stability.md rewrite)
- Commit `77c50bd` — Task 2 (release_contract_test.exs updates)
- `mix test test/rulestead/release_contract_test.exs` → 26 tests, 0 failures

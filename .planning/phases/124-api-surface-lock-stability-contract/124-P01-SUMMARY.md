---
phase: "124-api-surface-lock-stability-contract"
plan: 1
subsystem: "docs"
tags: ["@moduledoc", "@doc", "hexdocs", "public-api", "mix-exs", "groups_for_modules"]
dependency_graph:
  requires: []
  provides: ["Rulestead.Context HexDocs page", "Rulestead.Runtime HexDocs page", "Rulestead.Admin.Policy HexDocs page", "Runtime (cached lookup) mix.exs group"]
  affects: ["HexDocs rendering", "mix docs", "api_stability.md contract visibility"]
tech_stack:
  added: []
  patterns: ["@moduledoc flip from false to real doc", "@doc on public functions only", "@doc before @callback for behaviour documentation"]
key_files:
  created: []
  modified:
    - "rulestead/lib/rulestead/context.ex"
    - "rulestead/lib/rulestead/runtime.ex"
    - "rulestead/lib/rulestead/admin/policy.ex"
    - "rulestead/mix.exs"
decisions:
  - "Kept all @spec lines intact — D-07: zero new specs authored"
  - "No @deprecated attributes — D-05: soft-deprecation only"
  - "No autolinks to @moduledoc false modules in new @doc bodies — D-06 compliance"
  - "Four *_actions/0 helpers framed as role-vocabulary / introspection helpers (D-10)"
  - "Runtime (cached lookup) group added between Public API and Store Adapters (D-09)"
  - "Rulestead.Runtime.Snapshot removed from Extensibility group (D-09)"
  - "iex doctest in Context @moduledoc is a pure-function doctest (new/1 has no store dep)"
  - "Runtime @doc examples use fenced elixir blocks, not doctests (cache dependency)"
metrics:
  duration: "~12 min"
  completed: "2026-06-17"
  tasks: 2
  files_modified: 4
---

# Phase 124 Plan 1: API Surface Lock — @moduledoc/@doc Flip Summary

**One-liner:** Flipped `@moduledoc false` to real module docs and added per-function `@doc` on all public symbols in `Rulestead.Context`, `Rulestead.Runtime`, and `Rulestead.Admin.Policy`; updated `mix.exs` groups.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author @moduledoc and @doc for Rulestead.Context and Rulestead.Runtime | 4f096df | context.ex, runtime.ex |
| 2 | Author @moduledoc and @doc for Admin.Policy + update mix.exs groups_for_modules | 40e6295 | admin/policy.ex, mix.exs |

## What Was Built

### Rulestead.Context (`context.ex`)

- Replaced `@moduledoc false` with a full module doc including: intent paragraph, `## Building a context` section with an iex doctest for `new/1` (pure function — no store dependency), and a `## Stable fields` section referencing `api_stability.md`.
- Added `@doc` to `new/1`: describes keyword/map/struct input, alias normalization (`:subject` → `:actor`, `:traits` → `:attributes`), and `targeting_key` defaulting behavior.
- Added `@doc` to `normalize/1`: describes the same input union, idempotency guarantee, and normalization of each field type.

### Rulestead.Runtime (`runtime.ex`)

- Replaced `@moduledoc false` with a full module doc including: cached-lookup purpose, payload-first vs cached-lookup comparison table, supported surface catalog, and note that `Rulestead.Runtime.*` submodules are implementation detail.
- Added `@doc` to all 6 public functions:
  - `evaluate/3` — cache lookup + evaluation, fenced elixir code example
  - `enabled?/3` — derives boolean from `evaluate/3`
  - `get_value/4` — fourth arg as fallback for nil value or `:default` reason
  - `get_variant/3` — returns matched variant key or `nil`
  - `explain/3` — human-readable explanation string, requires running cache
  - `diagnostics/1` — cache state map for all environments, `opts` reserved

### Rulestead.Admin.Policy (`admin/policy.ex`)

- Replaced `@moduledoc false` with a full module doc including: host-owned auth seam framing, inline `MyApp.RulesteadPolicy` implementation example (uses `viewer_actions/0` inside `can?/4`), `## Canonical role model` section, and `## Callbacks` section. No iex doctest (behaviour, not pure function — per HEXDOCS.md:377-378).
- Added `@doc` to 4 read-only role-vocabulary / introspection helpers (D-10 promotion):
  - `governance_actions/0` — 5 high-impact mutation atoms requiring change-request approval
  - `viewer_actions/0` — 14 read-only/safe simulation action atoms
  - `editor_actions/0` — 8 authoring operation atoms
  - `admin_actions/0` — 10 administrative/approval operation atoms
- Added `@doc` before each `@callback`:
  - `can?/4` — required; explicit actor+action+resource+env mapping
  - `change_request_required?/4` — optional; defaults to `false` (no approval required)
  - `allow_self_approval?/4` — optional; defaults to `false` (submitter cannot self-approve)

### `rulestead/mix.exs`

- Added `"Runtime (cached lookup)": [Rulestead.Runtime]` group between "Public API" and "Store Adapters" (D-09).
- Removed `Rulestead.Runtime.Snapshot` from the Extensibility group. Extensibility is now `[Rulestead.Store, Rulestead.Tenancy]` (D-09).

## Verification Results

All acceptance criteria and plan verification checks passed:

1. `mix compile` exits 0 — no compilation errors
2. `@moduledoc false` count: 0 in all three target files
3. `grep -c "@doc" context.ex` = 2 (new/1 and normalize/1)
4. `grep -n "@doc" runtime.ex` = 6 entries (all 6 public functions)
5. `grep -n "@doc" policy.ex` = 7 entries (4 helpers + 3 callbacks)
6. `grep "Runtime.Snapshot" mix.exs` = no match (Snapshot removed)
7. `grep "Rulestead.Runtime" mix.exs` = match on `Rulestead.Runtime` (not Snapshot)
8. No `@deprecated` in any of the three files
9. No new `@spec` lines in any of the three files

## Deviations from Plan

None — plan executed exactly as written.

All D-05 through D-10 constraints honored:

- D-05: Zero `@deprecated` attributes
- D-06: No autolinks to `@moduledoc false` modules; Runtime examples use fenced blocks
- D-07: No new `@spec` lines authored
- D-08: Module doc style matches contract framing per HEXDOCS.md drafts
- D-09: Both mix.exs edits applied (Runtime added, Snapshot removed)
- D-10: Four `*_actions/0` helpers promoted with `@doc`, framed as read-only introspection helpers

## Known Stubs

None. All four files contain real implementation and documentation. No placeholder text.

## Threat Flags

None. This plan edits documentation attributes and a docs-config list only. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- `rulestead/lib/rulestead/context.ex` — exists and contains `@moduledoc """`
- `rulestead/lib/rulestead/runtime.ex` — exists and contains `@moduledoc """`
- `rulestead/lib/rulestead/admin/policy.ex` — exists and contains `@moduledoc """`
- `rulestead/mix.exs` — contains `Rulestead.Runtime` in groups, no `Runtime.Snapshot`
- Commit `4f096df` — Task 1 (Context + Runtime)
- Commit `40e6295` — Task 2 (Admin.Policy + mix.exs)

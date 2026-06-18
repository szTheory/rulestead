---
phase: 126-hexdocs-front-door
plan: "05"
subsystem: rulestead-core-docs
tags: [hexdocs, mix-exs, module-groups, extras, theming, branding, og-meta, css-vars]
dependency_graph:
  requires: [plan-01-symlinks, plan-02-why-rulestead, plan-04-moduledoc-flips]
  provides: [6-module-groups, funnel-extras, asset-wiring, main-theming, og-meta]
  affects: [plan-06-admin-parity, mix-docs-gate, check-logo-bytes-gate]
tech_stack:
  added: []
  patterns: [exdoc-css-var-retint, symlink-based-asset-shipping, funnel-extras-order]
key_files:
  created: []
  modified:
    - rulestead/mix.exs
    - guides/introduction/why-rulestead.md
decisions:
  - "D-01..D-05: Exactly 6 module groups (Core API, Runtime (cached lookup), Testing, Behaviours & Seams, Store Adapters, Telemetry & Config) — Rulestead.Rule dangling ref deleted, Ruleset/Flag dropped, Tenancy excluded"
  - "D-06: groups_for_extras uses explicit ordered list for API & Stability placed first — defuses first-match footgun where Introduction regex would swallow upgrading.md"
  - "D-07: extras in onboarding-funnel order — why-rulestead.md first Introduction extra, api_stability -> upgrading -> cheatsheet -> CONVENTIONS at end"
  - "D-09: plain-relative brandbook/assets/logo/*.svg glob in files: and logo/favicon/assets in docs: (no ../ tokens)"
  - "D-13..D-16: before_closing_head_tag/1 re-tints --main* HSL family at :root + body.dark; PNG og:image/twitter:image; no <script>; :epub returns empty string"
metrics:
  duration: "3m"
  completed: "2026-06-18"
  tasks_completed: 2
  files_modified: 2
status: complete
---

# Phase 126 Plan 05: Full HexDocs Front Door Wiring Summary

Rewrote `rulestead/mix.exs` `docs/0` and `package files:` into the full 1.0 HexDocs front door:
6 module groups with correct 1.x stable membership (D-01..D-05), funnel-ordered extras with
"API & Stability" first-match defuse (D-06/D-07), logo/favicon/assets via plain-relative symlink
paths (D-09), and ExDoc 0.40.3 `--main*` CSS-var re-tint + PNG OG meta head-tag (D-13..D-16).

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | 6 module groups + funnel extras + asset wiring (D-01..D-09) | 992681d | rulestead/mix.exs, guides/introduction/why-rulestead.md |
| 2 | before_closing_head_tag --main* re-tint + PNG OG meta (D-13..D-16) | 992681d | rulestead/mix.exs |

Both tasks were implemented in a single mix.exs edit and committed together.

## What Was Built

### Task 1 — 6 Module Groups + Funnel Extras + Asset Wiring

**groups_for_modules:** Replaced the stale 4-group block (`Public API`, `Runtime (cached lookup)`, `Store Adapters`, `Extensibility`) with exactly 6 groups matching the frozen `api_stability.md` stable module list:
- `Core API`: [Rulestead, Rulestead.Context, Rulestead.Result, Rulestead.Error]
- `Runtime (cached lookup)`: [Rulestead.Runtime]
- `Testing`: [Rulestead.TestHelpers]
- `Behaviours & Seams`: [Rulestead.Store, Rulestead.Admin.Policy]
- `Store Adapters`: [Rulestead.Store.Ecto, Rulestead.Store.Redis]
- `Telemetry & Config`: [Rulestead.Telemetry, Rulestead.Config]

Deleted dangling `Rulestead.Rule` (module does not exist — real one is `Rulestead.Ruleset.Rule`). Dropped `Rulestead.Ruleset` and `Rulestead.Flag` (exist but not in frozen stable list). Excluded `Rulestead.Tenancy` from all groups (only the config key is public, not the module).

**groups_for_extras:** Added "API & Stability" as an explicit ordered file list placed FIRST in the keyword list to defuse the first-match footgun (a broad `~r"guides/introduction/"` would otherwise swallow `upgrading.md` before it could be assigned to "API & Stability"). Groups:
- `API & Stability`: explicit list [api_stability.md, upgrading.md, cheatsheet.cheatmd]
- `Introduction`: ~r"guides/introduction/"
- `Concepts & Guides`: ~r"guides/flows/"
- `Recipes`: ~r"guides/recipes/"
- `Contributing`: ~r"CONVENTIONS"

**extras:** Reordered in onboarding-funnel order with `why-rulestead.md` as the first Introduction extra. Added to the existing list (guides/recipes/telemetry.md intentionally omitted per D-08 — avoid duplicate telemetry surface). API stability surface placed at end: api_stability.md → upgrading.md → cheatsheet.cheatmd → CONVENTIONS.md.

**package files:** Added plain-relative globs (no `../` tokens per D-09):
`brandbook/assets/logo/*.svg brandbook/assets/specimens/readme-header.svg`

**docs: asset keys:** Added plain-relative paths:
- `logo: "brandbook/assets/logo/rs-mark.svg"` (square viewBox 0 0 62 62)
- `favicon: "brandbook/assets/logo/rs-favicon.svg"`
- `assets: %{"brandbook/assets/logo" => "assets"}`

### Task 2 — before_closing_head_tag --main* Re-tint + PNG OG Meta

Added `before_closing_head_tag: &before_closing_head_tag/1` to the docs keyword list and defined two private clauses:

`before_closing_head_tag(:html)` — returns heredoc string with:
- OG/Twitter meta: `og:title`, `og:description`, `og:type=website`, `twitter:card=summary_large_image`
- `og:image` AND `twitter:image` pointing at `rs-social-card.png` (PNG per D-15 — unfurlers don't render SVG)
- Inline `<style>` re-tinting the ExDoc 0.40 `--main*` HSL family at `:root` (light) and `body.dark` (dark)
  — uses `body.dark` not `.dark` to match ExDoc 0.40.3 specificity (RESEARCH.md V1 refinement)
- Targets: `--main`, `--mainDark`, `--mainDarkest`, `--mainLight`, `--mainLightest`,
  `--searchBarFocusColor`, `--searchBarBorderColor` (all verified present in installed 0.40.3 CSS)
- Values sourced from `brandbook/tokens.css` mineral palette (Stead Blue #3A6F8F family)
- No `<script>`, no custom stylesheet file, no manual `a:focus-visible` block (D-14/D-16)

`before_closing_head_tag(:epub)` — returns `""` (D-16)

## Verification

- `mix docs --warnings-as-errors` exits 0 — autolink gate green (no undefined-reference warnings)
- `scripts/ci/check_logo_bytes.sh` — "logo SVG bytes verified in tarball" (D-10 assertion green)
- `scripts/ci/check_package_whitelist.sh` — "package whitelist checks passed"
- `release_contract_test.exs` — 26 tests, 0 failures (contract unchanged)
- All task-level grep checks: 6 module groups, no Rulestead.Rule,, no ../brandbook, *.svg glob present, logo path present, why-rulestead present, API & Stability present, before_closing_head_tag defined, --main: present, body.dark present, PNG og:image present, :epub clause present, no <script>, no a:focus-visible

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed broken MAINTAINING.md relative link in why-rulestead.md**
- **Found during:** Task 1 verification — `mix docs --warnings-as-errors` failed with: "documentation references file `../../MAINTAINING.md` but it does not exist"
- **Issue:** The relative path `../../MAINTAINING.md` in `guides/introduction/why-rulestead.md` was not resolvable by ExDoc from the `rulestead/` package root context, causing the `--warnings-as-errors` gate to fail.
- **Fix:** Replaced the relative file link with the absolute GitHub URL: `https://github.com/szTheory/rulestead/blob/main/MAINTAINING.md`
- **Files modified:** `guides/introduction/why-rulestead.md` (line 139)
- **Commit:** 992681d

**Note on task boundary:** Tasks 1 and 2 are both a single file (`rulestead/mix.exs`) and were combined into one commit. Both tasks landed atomically since there was no intermediate verification state between adding the module groups and adding `before_closing_head_tag`.

## Known Stubs

None.

## Threat Flags

None — documentation configuration changes only. No new network endpoints, auth paths, file access patterns, or schema changes. The `files:` glob change only adds plain-relative `brandbook/assets/logo/*.svg` (non-recursive, excludes `.DS_Store`/`svgo.config.mjs`/`concepts/` as designed). `check_package_whitelist.sh` confirmed no cross-package leakage.

## Self-Check: PASSED

- `rulestead/mix.exs` — FOUND, 6 module groups, funnel extras, asset wiring, before_closing_head_tag
- `guides/introduction/why-rulestead.md` — FOUND, MAINTAINING.md link fixed
- Commit 992681d — FOUND (`git log --oneline | head -1` confirms)
- `mix docs --warnings-as-errors` — exits 0
- `scripts/ci/check_logo_bytes.sh` — "logo SVG bytes verified in tarball"
- `scripts/ci/check_package_whitelist.sh` — "package whitelist checks passed"
- `release_contract_test.exs` — 26 tests, 0 failures

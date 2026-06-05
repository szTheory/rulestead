---
phase: 97-logo-mark-svg-system
plan: "03"
subsystem: brand-assets
tags: [logo, svg, admin, demo, phoenix-digest]
dependency_graph:
  requires: [97-02]
  provides: [LOGO-04, LOGO-05]
  affects: [rulestead_admin/priv/static/images, examples/demo/backend/priv/static/images]
tech_stack:
  added: []
  patterns: [phoenix-digest, admin-package-assets]
key_files:
  created:
    - rulestead_admin/priv/static/images/rs-mark.svg
    - rulestead_admin/priv/static/images/rs-mark-dark.svg
    - examples/demo/backend/priv/static/images/logo-2d303e8acdf20eb43468b22535dfba4e.svg
    - examples/demo/backend/priv/static/images/logo-2d303e8acdf20eb43468b22535dfba4e.svg.gz
  modified:
    - examples/demo/backend/priv/static/images/logo.svg
    - examples/demo/backend/priv/static/images/logo.svg.gz
  deleted:
    - examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg
    - examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg.gz
decisions:
  - "cache_manifest.json is gitignored in the demo backend (.gitignore: /priv/static/cache_manifest.json) — correct Phoenix behavior; not committed but verified regenerated with new fingerprint"
  - "New fingerprint hash: 2d303e8acdf20eb43468b22535dfba4e (replaced 06a11be1f2cdde2c851763d00bdd2e80)"
metrics:
  duration: "5"
  completed_date: "2026-06-05"
  task_count: 1
  file_count: 8
---

# Phase 97 Plan 03: Admin Embed + Demo Logo Replacement Summary

**One-liner:** Copied G4c rs-mark SVGs into admin priv/static/images and replaced the phoenix-flame demo logo with the new Rulestead mark, regenerating Phoenix digest fingerprints and sidecars.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Copy marks to admin package + replace demo logo + re-digest | 04a46a5 | rs-mark.svg, rs-mark-dark.svg (admin); logo.svg, logo-2d303e8a*.svg, *.gz (demo) |

## What Was Built

**LOGO-04 — Admin package copies:**
- Created `rulestead_admin/priv/static/images/` directory
- Copied `brandbook/assets/logo/rs-mark.svg` and `brandbook/assets/logo/rs-mark-dark.svg` exactly (byte-preserving copy from canonical brandbook source)
- Files committed as package assets in `priv/` (included in `mix.exs files:` list per rulestead_admin README)
- No admin `.ex` files modified — Phase 98 wires the mark into the shell UI

**LOGO-05 — Phoenix-flame retired, demo logo replaced:**
- Replaced `examples/demo/backend/priv/static/images/logo.svg` with G4c rs-mark.svg (icon-only mark, correct for width=36 embed in layouts.ex line 41)
- Deleted stale `logo-06a11be1f2cdde2c851763d00bdd2e80.svg` and its `.gz` sidecar
- Deleted old `logo.svg.gz`
- Ran `mix phx.digest` from `examples/demo/backend/` to regenerate:
  - `logo-2d303e8acdf20eb43468b22535dfba4e.svg` (new fingerprint)
  - `logo-2d303e8acdf20eb43468b22535dfba4e.svg.gz` (new fingerprinted gz)
  - `logo.svg.gz` (plain gz sidecar)
  - `cache_manifest.json` updated (gitignored — not committed; standard Phoenix behavior)

## Acceptance Criteria Results

| Criterion | Result |
|-----------|--------|
| 2 admin marks exist | PASS — `ls rs-mark.svg rs-mark-dark.svg \| wc -l` = 2 |
| FD4F00 phoenix-flame fill gone | PASS — `grep -c 'FD4F00' logo.svg` = 0 |
| Old hash file deleted | PASS — `ls logo-06a11be1f2cdde2c851763d00bdd2e80.svg 2>/dev/null \| wc -l` = 0 |
| Exactly 1 new fingerprinted SVG | PASS — `ls logo-*.svg \| wc -l` = 1 |
| ≥1 gz sidecar regenerated | PASS — `ls logo*.gz \| wc -l` = 2 |
| cache_manifest references images/logo- | PASS — grep succeeds (file is gitignored but verified before commit) |
| cache_manifest CLEAN of old hash | PASS — old hash absent from manifest |
| All copied SVGs contain `<title>` | PASS — grep -c '<title' = 1 for each file |

## Deviations from Plan

None — plan executed exactly as written.

Note: `cache_manifest.json` is listed in `files_modified` in the plan frontmatter and the plan's key_links, but it is gitignored by `examples/demo/backend/.gitignore` (`/priv/static/cache_manifest.json`). This is correct Phoenix behavior — the manifest is a generated build artifact. The file was verified to have been regenerated and to reference the new fingerprint hash before commit.

## Known Stubs

None — all files are fully wired. The admin marks are committed to priv/static/images/ as package assets but are not yet referenced in any admin .ex template (per plan scope: Phase 98 wires them into the shell UI).

## Remaining Item — Orchestrator Visual Confirmation Required

**Task 2** is a `checkpoint:human-verify` gate that requires visual confirmation. The orchestrator will perform this via headless Chrome after this executor returns.

**What to confirm:**
1. Boot the demo: `(cd examples/demo/backend && mix phx.server)`
2. Open the app; the header logo renders via `<img src="/images/logo.svg" width="36">` (layouts.ex line 41)
3. Confirm: the new Rulestead G4c mark displays in place of the orange phoenix-flame, reads clearly at 36px, and is not clipped/distorted
4. Also confirm: `brandbook/assets/logo/rs-favicon.svg` is legible at 16px (LOGO-03 manual gate)

**Automated preconditions already verified:**
- FD4F00 fill absent from logo.svg
- New fingerprint `2d303e8acdf20eb43468b22535dfba4e` present and referenced in cache_manifest.json
- Old fingerprint `06a11be1f2cdde2c851763d00bdd2e80` deleted

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are static asset file copies and Phoenix digest regeneration — within the brandbook source → consumer packages trust boundary and demo build → served static assets trust boundary as defined in the plan's threat model.

T-97-07 (Tampering — copied SVGs differ from canonical): Mitigated — files were copied byte-for-byte from `brandbook/assets/logo/` using `cp` with no modifications.

T-97-08 (Stale fingerprinted file left in repo): Mitigated — old hash `06a11be1f2cdde2c851763d00bdd2e80` deleted from both `.svg` and `.gz`; cache_manifest.json verified CLEAN.

T-97-09 (mix phx.digest.clean --all wiping CSS/JS): Mitigated — used targeted `rm` of only the three logo sidecar files; ran plain `mix phx.digest` without `--all`.

## Self-Check: PASSED

- `rulestead_admin/priv/static/images/rs-mark.svg` — FOUND
- `rulestead_admin/priv/static/images/rs-mark-dark.svg` — FOUND
- `examples/demo/backend/priv/static/images/logo.svg` — FOUND (new mark, FD4F00 absent)
- `examples/demo/backend/priv/static/images/logo-2d303e8acdf20eb43468b22535dfba4e.svg` — FOUND
- `examples/demo/backend/priv/static/images/logo-2d303e8acdf20eb43468b22535dfba4e.svg.gz` — FOUND
- `examples/demo/backend/priv/static/images/logo.svg.gz` — FOUND
- Old hash files (`logo-06a11be1f2cdde2c851763d00bdd2e80.*`) — CONFIRMED DELETED
- Commit `04a46a5` — FOUND in git log

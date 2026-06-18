---
phase: 126-hexdocs-front-door
plan: "01"
subsystem: doc-assets
tags: [hexdocs, brandbook, symlink, ci, social-card, rasterization]
status: complete

dependency_graph:
  requires: []
  provides:
    - rulestead/brandbook symlink (D-09) — enables plain-relative brandbook/* globs in core mix.exs
    - rulestead_admin/brandbook symlink (D-09) — enables plain-relative brandbook/* globs in admin mix.exs
    - brandbook/assets/logo/rs-social-card.png — 1200x630 PNG for og:image + GitHub social-preview
    - scripts/ci/check_logo_bytes.sh — D-10 tarball content assertion gate
  affects:
    - scripts/ci/contributor.sh (check_logo_bytes.sh wired in)
    - plans 02-06 (depend on symlinks and PNG being committed)
    - plan 05 (adds files: glob that makes check_logo_bytes.sh pass end-to-end)

tech_stack:
  added: []
  patterns:
    - committed symlink (mode 120000) per-package pointing at ../brandbook
    - "@resvg/resvg-js JS API (npx, /tmp, not a project dep) for SVG->PNG rasterization"
    - bash tarball-inspection pattern mirroring check_package_whitelist.sh

key_files:
  created:
    - rulestead/brandbook (symlink -> ../brandbook, mode 120000)
    - rulestead_admin/brandbook (symlink -> ../brandbook, mode 120000)
    - brandbook/assets/logo/rs-social-card.png (1200x630 PNG, 27008 bytes)
    - scripts/ci/check_logo_bytes.sh (D-10 tarball content assertion)
  modified:
    - scripts/ci/contributor.sh (check_logo_bytes.sh wired after mix docs step)

decisions:
  - "D-09 symlink approach confirmed: mode 120000 stored by git, resolves to real rs-mark.svg from both package roots"
  - "D-19 rasterization simplified: card is pure-path SVG, used @resvg/resvg-js JS API in /tmp (not npx CLI, which has no bin entry), no headless Chrome needed"
  - "D-10 CI gate expected-fail until plan 05 adds brandbook/assets/logo/*.svg to core files: — documented in script header and contributor.sh comment"

metrics:
  duration: "15 min"
  completed: "2026-06-18"
  tasks_completed: 3
  files_changed: 5
---

# Phase 126 Plan 01: Brandbook Symlinks + Social Card + CI Gate Summary

Wave-0 prerequisites for the HexDocs front door: committed brandbook symlinks in both packages (D-09), rasterized 1200x630 social card PNG (D-19), and D-10 CI tarball-content assertion gate wired into contributor.sh.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create committed brandbook symlinks (D-09) | 314be02 | rulestead/brandbook, rulestead_admin/brandbook |
| 2 | Rasterize rs-social-card.png at 1200x630 (D-19) | 3e4bfbc | brandbook/assets/logo/rs-social-card.png |
| 3 | Add D-10 CI tarball logo-bytes assertion + wire into CI | b58b336 | scripts/ci/check_logo_bytes.sh, scripts/ci/contributor.sh |

## Verification Results

- `test -L rulestead/brandbook` — PASS (mode 120000 symlink)
- `test -L rulestead_admin/brandbook` — PASS (mode 120000 symlink)
- Both resolve to `brandbook/assets/logo/rs-mark.svg` — PASS
- `git ls-files --error-unmatch rulestead/brandbook rulestead_admin/brandbook` — PASS (tracked as symlinks)
- `file brandbook/assets/logo/rs-social-card.png` reports `PNG image data, 1200 x 630` — PASS
- `test -x scripts/ci/check_logo_bytes.sh` — PASS
- `bash -n scripts/ci/check_logo_bytes.sh` — PASS (syntax clean)
- `grep -q 'check_logo_bytes.sh' scripts/ci/contributor.sh` — PASS

## Deviations from Plan

### Minor Adjustments

**1. [Rule 1 - Implementation Detail] @resvg/resvg-js has no CLI bin — used JS API in /tmp**
- **Found during:** Task 2
- **Issue:** The plan referenced `npx @resvg/resvg-js ... --width 1200 --height 630 -o ...` as a CLI command, but `@resvg/resvg-js` has no `bin` entry in its package.json (it is a JS library, not a CLI tool).
- **Fix:** Installed `@resvg/resvg-js` in `/tmp/resvg_work` (not added to project), invoked it via a small Node.js script using the `Resvg` JS API with `fitTo: { mode: 'width', value: 1200 }`. The card SVG has `height="630"` set, so 1200w produces exactly 1200x630. Headless Chrome fallback was not needed.
- **Files modified:** brandbook/assets/logo/rs-social-card.png (output only; no project dependency added)
- **Commit:** 3e4bfbc

None — plan executed within the spirit of all decisions. The rasterization approach (resvg-js JS API vs CLI) is the only deviation, and it produces the identical output artifact.

## Known Stubs

None — all three artifacts are real and complete:
- Symlinks resolve to real SVG bytes (verified via `test -f rulestead/brandbook/assets/logo/rs-mark.svg`)
- PNG is a genuine raster at 1200x630 (not a placeholder)
- CI script asserts real content (not a stub assertion)

## Threat Flags

No new security surface introduced beyond the plan's threat model (T-126-01, T-126-02, T-126-SC). The `check_logo_bytes.sh` script mitigates T-126-01 as designed.

## Self-Check: PASSED

- `rulestead/brandbook` exists and is a symlink: CONFIRMED
- `rulestead_admin/brandbook` exists and is a symlink: CONFIRMED
- `brandbook/assets/logo/rs-social-card.png` exists at 1200x630: CONFIRMED
- `scripts/ci/check_logo_bytes.sh` exists and is executable: CONFIRMED
- All 3 task commits exist in git log: 314be02, 3e4bfbc, b58b336 — CONFIRMED

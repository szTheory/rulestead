---
phase: 102-logo-delta-audit-tournament-studio
plan: "01"
subsystem: scripts
tags: [tooling, svg, fonts, tournament, python, shell]
dependency_graph:
  requires: []
  provides: [gen_glyph_paths.py, 102-studio.html, render_studio.sh]
  affects: [.gitignore]
tech_stack:
  added: []
  patterns:
    - curl-subprocess font fetch (never urllib — urllib hangs on gstatic)
    - per-glyph SVG path emission with per-glyph transform (one <path> per character)
    - headless Chrome screenshot via --headless=new with file:// absolute path
    - Y-flip transform: translate(x, em_size) scale(scale, -scale)
key_files:
  created:
    - scripts/gen_glyph_paths.py
    - .planning/phases/102-logo-delta-audit-tournament-studio/102-studio.html
    - .planning/phases/102-logo-delta-audit-tournament-studio/render_studio.sh
  modified:
    - .gitignore
decisions:
  - "Use measured advance width (334.4 SVG units) for viewBox rather than Phase 97 hardcoded 372 — exact measurement avoids phantom right-padding"
  - "Favicon cell uses R-glyph-only crop (viewBox 0 0 47 64) rather than full wordmark scaled to 16px — renders recognizable mark not illegible blur"
  - "studio HTML has incumbent paths fully inlined (not placeholder) — render harness proves pipeline end-to-end with real glyph data"
metrics:
  duration: "~18 minutes"
  completed: "2026-06-11"
  tasks_completed: 2
  files_created: 3
  files_modified: 1
requirements:
  - LOGO-06
---

# Phase 102 Plan 01: Tournament Tooling Infrastructure Summary

Build the tournament tooling infrastructure: generalized glyph-to-path pipeline, studio HTML template, and headless-Chrome render helper. Proven end-to-end with test render of incumbent "Rulestead" wordmark (Sora Bold 700) at sheet / 36px admin header / 16px favicon sizes.

## What Was Built

### Task 1: scripts/gen_glyph_paths.py

Generalizes `scripts/gen_wordmark_paths.py` with the following upgrades:

- **`--font-url`**: accepts any pinned `fonts.gstatic.com` TTF (not hardcoded to one URL)
- **`--tracking`**: letter-spacing in em fractions per glyph (e.g. `-0.02` = tighten by 2% em)
- **`--weight`**: display label only (weight is baked into URL)
- **curl-only font fetch**: `subprocess.run(["curl", ...])` — no urllib anywhere in the file
- **Per-glyph emission**: one `<path>` element per character with its own `transform` — never merged
- **SHORTLIST constant**: documents all 9 verified gstatic URLs (Sora 600/700/800, Space Grotesk 600/700, Archivo 600/700, IBM Plex Sans 600/700)
- **Security**: T-97-03 assertion enforced — URL must start with `https://fonts.gstatic.com/`
- **Temp dir cleanup**: `shutil.rmtree` in `finally` block

Verification:
- `python3 scripts/gen_glyph_paths.py --text "RS" | grep -c 'path transform'` → **2**
- `python3 scripts/gen_glyph_paths.py --text "Rulestead" | grep -c 'path transform'` → **9**
- `grep -c "urllib" scripts/gen_glyph_paths.py` → **0**
- `python3 scripts/gen_glyph_paths.py --help` shows `--font-url`, `--em-size`, `--tracking`

### Task 2: Studio HTML + Render Helper + .gitignore

**102-studio.html**: Phase 102 tournament studio with:
- Incumbent / Control section: Sora Bold 700 paths pasted inline (generated live by gen_glyph_paths.py)
- Light card (fill `#1a2332`) and dark card (fill `#e8edf2`) on `#ffffff` / `#10161f` surfaces
- Size stress strip in each card: 128px column, 36px admin header column, 16px favicon column (R initial crop)
- Phase 103 candidate slots placeholder section
- `document.fonts.ready` settle guard with 4s safety net
- `--rs-primary` token drift check (warns to console if tokens.css fails to load)
- Links `brandbook/tokens.css` via relative path from phase dir

**render_studio.sh**: headless Chrome screenshot helper with:
- Absolute path resolution via `$(cd "$(dirname "$0")" && pwd)`
- Background Chrome launch + PID capture + file-poll loop (30 × 0.5s)
- Verified Chrome flags: `--headless=new`, `--force-device-scale-factor=2`, `--virtual-time-budget=10000`
- TMPDIR cleanup after render

**.gitignore**: added `studio-render-*.png` exclusion for Phase 102 phase dir (below existing Phase 97 lines). Also added `__pycache__/` and `*.pyc` exclusions (Rule 2 fix — running the script created untracked bytecode).

## Test Render

Pipeline proven end-to-end. Test render produced:
- **File**: `.planning/phases/102-logo-delta-audit-tournament-studio/studio-render-20260611-210123.png`
- **Size**: 255 KB (non-empty)
- **Dimensions**: 3200 × 1800 pixels (1600×900 @ 2× scale factor)
- **Git-ignored**: confirmed via `git check-ignore`

Visual confirmation (automated rendering and visual inspection of output PNG):
- "Rulestead" wordmark legible on light card
- "Rulestead" wordmark legible on dark card
- 128px strip: clean, readable wordmark
- 36px admin-header strip: recognizable wordmark
- 16px favicon cell: "R" initial visible (not blank)
- Text is right-side up — Y-flip transform applied correctly

Checkpoint deferred to orchestrator — renders at:
`.planning/phases/102-logo-delta-audit-tournament-studio/studio-render-20260611-210123.png`

## Commits

| Hash | Message |
|------|---------|
| `fb2dad4` | feat(102-01): add generalized glyph-to-path pipeline (gen_glyph_paths.py) |
| `3d1e977` | feat(102-01): add tournament studio HTML + render helper + gitignore |
| `d67d8b4` | chore(102-01): add __pycache__/*.pyc to .gitignore |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing gitignore] Added __pycache__/*.pyc gitignore entries**
- **Found during**: Task 2 verification
- **Issue**: Running `gen_glyph_paths.py` created `scripts/__pycache__/gen_glyph_paths.cpython-314.pyc` — untracked generated bytecode
- **Fix**: Added `__pycache__/` and `*.pyc` entries to `.gitignore`
- **Files modified**: `.gitignore`
- **Commit**: `d67d8b4`

**2. [Claude's Discretion] Inline paths instead of placeholder**
- **Context**: Plan said "Executor should run gen_glyph_paths.py and paste paths here"; as an automated executor with no human checkpoint, the pasting was done inline during Task 2
- **Effect**: Studio HTML renders the incumbent control immediately without manual editing step; the placeholder comment remains in the Phase 103 candidate slots section

**3. [Claude's Discretion] viewBox width 336 (not 372)**
- **Context**: Plan spec said `viewBox="0 0 372 64"` (Phase 97 incumbent dimensions). Actual measured advance width from gen_glyph_paths.py was 334.4 SVG units.
- **Fix**: Used `336` (334.4 rounded up with 1-unit padding) for accuracy. Phase 97 used a different TTF URL and font version; 372 would produce phantom right-side whitespace.

## Pre-existing CI Failure (Out of Scope)

`bash scripts/ci/lint.sh` exits non-zero due to a pre-existing broken link:
```
ERROR: local non-fragment href does not resolve from brandbook/: ../.planning/phases/101-html-brand-book/101-UI-SPEC.md
```
Confirmed pre-existing (fails on commits before this plan's changes). Not introduced by Phase 102 plan 01. Logged to deferred items — not fixed.

## Known Stubs

None. Incumbent paths are fully inlined with real glyph data. Phase 103 candidate slots section contains explicit placeholder text directing Phase 103 executors to paste their paths.

## Threat Flags

None. No new network endpoints, auth paths, or trust-boundary changes introduced. The studio HTML is in `.planning/` (not served by Phoenix). The `--font-url` gstatic assertion (T-97-03) is in place.

## Self-Check: PASSED

- `scripts/gen_glyph_paths.py` exists and passes all automated checks
- `102-studio.html` exists and contains size-strip section
- `render_studio.sh` exists
- `.gitignore` contains `studio-render-*.png` entry (line 16) and `__pycache__/` entry (line 5)
- All 3 commits exist in git log: `fb2dad4`, `3d1e977`, `d67d8b4`
- PNG render exists at `.planning/phases/102-logo-delta-audit-tournament-studio/studio-render-20260611-210123.png` (255 KB, 3200×1800)
- PNG is git-ignored (`.gitignore:16` confirmed)

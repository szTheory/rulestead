---
phase: 126-hexdocs-front-door
plan: "03"
subsystem: docs
tags: [readme, shields.io, badges, brand, hero, hexdocs]

requires:
  - phase: 125-version-truth-sweep
    provides: "~> 1.0 install snippet in README; 'two version lines' callout deleted; check_version_truth.py guard"

provides:
  - "Centered rs-wordmark-tagline.svg hero at top of root README"
  - "5 clickable badges: Hex version (self-healing), HexDocs, CI, License, Elixir version"

affects:
  - 126-04
  - 126-05
  - 128-release-cut

tech-stack:
  added: []
  patterns:
    - "shields.io self-healing badge pattern (hexpm/v/rulestead never hardcodes version)"
    - "align=center div block for hex.pm + GitHub dual rendering compatibility"

key-files:
  created: []
  modified:
    - README.md

key-decisions:
  - "D-20: Centered hero uses rs-wordmark-tagline.svg (viewBox 0 0 340 96) via in-repo relative path"
  - "Hex version badge uses shields.io/hexpm/v/rulestead — self-heals on every publish, no hardcoded version"
  - "CI badge references ci.yml (filename verified present under .github/workflows/)"
  - "Elixir badge tinted 9b5931 (Ember Copper from brand palette)"
  - "HexDocs badge tinted 3A6F8F (Stead Blue from brand palette)"

patterns-established:
  - "Brand hero placement: div align=center block above the # heading for dual-renderer compatibility"

requirements-completed: [DOC-05]

duration: 2min
completed: 2026-06-18
status: complete
---

# Phase 126 Plan 03: README Brand Hero + 5-Badge Row Summary

**Centered rs-wordmark-tagline.svg hero and 5 self-healing shields.io badges added to root README as the 1.0 first impression on hex.pm and GitHub.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-06-18T06:59:55Z
- **Completed:** 2026-06-18T07:02:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Added `<div align="center">` hero block at the top of README.md with the `rs-wordmark-tagline.svg` wordmark (viewBox 0 0 340 96) above the existing `# Rulestead` heading
- Added 5 clickable `<a href>` badges in a centered paragraph: Hex version (shields self-healing), HexDocs (Stead Blue tint), CI (ci.yml verified), License (shields self-healing), Elixir version (Ember Copper tint)
- Preserved existing `~> 1.0` install snippet; confirmed no `~> 0.1` regression

## Task Commits

Each task was committed atomically:

1. **Task 1: Add centered brand hero + 5-badge clickable row to README (D-20)** - `18d01db` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `README.md` — Added hero block: centered wordmark SVG + 5 clickable badge row above existing H1

## Decisions Made

- Used `<div align="center">` (not `<p align="center">`) for the outer wrapper to support the nested `<img>` + `<p>` structure that renders correctly on both hex.pm and GitHub
- Hex version badge points to `img.shields.io/hexpm/v/rulestead` so it self-heals on every Hex publish — never hardcoded per D-20 and T-126-05 threat mitigation
- CI badge URL uses `actions/workflows/ci.yml/badge.svg` with workflow filename verified present at `.github/workflows/ci.yml` — per T-126-06 threat mitigation
- Elixir badge uses `badge/elixir-%7E%3E%201.17` (URL-encoded `~> 1.17`) tinted `9b5931` (Ember Copper per brand palette)

## Deviations from Plan

None — plan executed exactly as written.

**Note (out of scope):** A pre-existing `check_version_truth.py` failure in `guides/introduction/why-rulestead.md:148` was discovered but is NOT caused by this plan's changes (confirmed via stash test). That file contains a narrative sentence referencing `0.1.x` without the upgrade-arrow exemption pattern. This is out of scope for plan 126-03 (which only modifies README.md). Logged as a deferred item.

## Issues Encountered

None — automated verification for all 7 grep checks passed immediately.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-126-05 (Tampering — stale version badge) | Used `shields.io/hexpm/v/rulestead` (self-heals); no version string hardcoded |
| T-126-06 (Tampering — broken CI badge filename) | Verified `ci.yml` exists at `.github/workflows/ci.yml` before committing URL |

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- README now has the branded hero + badges as the 1.0 front-door first impression
- Plan 126-04 (HexDocs module groups + extras) can proceed without dependency on this plan
- Plan 126-05 (asset wiring + `files:` manifest) can proceed — this plan's hero references the SVG via its in-repo path which works for GitHub/local; hex.pm asset resolution covered by plan 126-05

## Self-Check: PASSED

- README.md: FOUND
- 126-03-SUMMARY.md: FOUND
- Commit 18d01db: FOUND

---
*Phase: 126-hexdocs-front-door*
*Completed: 2026-06-18*

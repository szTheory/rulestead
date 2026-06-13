---
phase: 95-brand-audit-palette-reconciliation
plan: 01
subsystem: scripts
tags: [accessibility, wcag, oklch, palette, brand, python3]
dependency_graph:
  requires: []
  provides:
    - scripts/check_contrast.py
  affects:
    - Phase 96 (check_brand_tokens.py formula source)
    - Phase 98 (WCAG-AA gate anchor)
tech_stack:
  added: []
  patterns:
    - python3 stdlib only (math, sys)
    - self-test anchors on startup
    - exits 0/1 with descriptive output (check_synced_pair.py style)
key_files:
  created:
    - scripts/check_contrast.py
  modified: []
decisions:
  - "OKLCH drift check encoded with negative min_ratio sentinel (< 0 = drift assertion, >= 0 = contrast assertion)"
  - "Success #2d7753 and Danger #b04848 on Stone Mist included per RESEARCH.md Gap 2 (not in PITFALLS.md)"
  - "Warning light drift compared against book hex #B57A21 (0.02 deg — trivially passes)"
metrics:
  duration: 5
  completed_date: "2026-06-04"
  tasks: 1
  files: 1
---

# Phase 95 Plan 01: Write check_contrast.py Summary

**One-liner:** WCAG 2.x contrast ratio + Ottosson OKLCH hue-angle verification script for Phase 95 palette reconciliation — stdlib-only, self-testing, 18 checks exit 0.

## What Was Built

`scripts/check_contrast.py` — a dependency-free python3 stdlib script that:

1. Implements the WCAG 2.1 relative-luminance formula (`linearize`, `relative_luminance`, `contrast_ratio`) with the exact coefficient values from RESEARCH.md.
2. Implements the Ottosson M1+M2 matrix chain (`rgb_to_oklch`) for sRGB → XYZ D65 → LMS → LMS^(1/3) → OKLab → OKLCH, plus `hue_drift` with 360-wraparound correction.
3. Self-tests four known-good anchors on startup and exits non-zero if any fails.
4. Asserts 18 Phase 95 palette checks: 9 light-surface (≥4.5:1), 6 dark-surface (≥4.5:1 on #10161f), 3 OKLCH-drift (<3°).

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write scripts/check_contrast.py | 98f4b52 | scripts/check_contrast.py |

## Verification Output

```
ANCHORS OK
PASS  4.550:1  Ember Copper canonical #9b5931 on Stone Mist #E8ECE8
PASS  4.573:1  Ember Copper #ac6336 on White #FFFFFF
PASS  4.531:1  Ember Copper #a65f34 on Rain Tint #F5F7F6
PASS  4.563:1  Warning canonical #8f601a on Stone Mist #E8ECE8
PASS  4.570:1  Warning #9f6b1d on White #FFFFFF
PASS  4.539:1  Moss Grey canonical #606d66 on Stone Mist #E8ECE8
PASS  4.544:1  Moss Grey #67746d on Rain Tint #F5F7F6
PASS  4.540:1  Success #2d7753 on Stone Mist #E8ECE8
PASS  4.550:1  Danger #b04848 on Stone Mist #E8ECE8
PASS  4.563:1  Stead Blue dark #5885a0 on #10161f
PASS  4.545:1  Ember Copper dark #ba6b3c on #10161f
PASS  4.581:1  Success dark #488d6b on #10161f
PASS  4.515:1  Danger dark #bf6464 on #10161f
PASS  4.526:1  Info dark #55859e on #10161f
PASS  4.527:1  Moss Grey dark #75827b on #10161f
PASS  drift=0.09deg  OKLCH drift: Ember Copper light canonical #B96A3A -> #9b5931 (must be <3 deg)
PASS  drift=0.02deg  OKLCH drift: Warning light canonical #B57A21 -> #8f601a (must be <3 deg)
PASS  drift=0.37deg  OKLCH drift: Ember Copper dark #B96A3A -> #ba6b3c (must be <3 deg)
CONTRAST CHECK PASS (18 checks)
```

Exit code: 0.

## Deviations from Plan

None — plan executed exactly as written.

The two "uncatalogued failures" from RESEARCH.md Gap 2 (Success `#2d7753` and Danger `#b04848` on Stone Mist) were included as plan-specified PALETTE_CHECKS entries, not as deviations.

The Warning OKLCH drift check uses book hex `#B57A21` → `#8f601a` (measured 0.02°), matching the plan spec. The RESEARCH.md documents Warning light drift as 0.38° (comparing against the per-surface White variant `#9f6b1d`); the 0.02° difference reflects this check comparing against the Stone Mist canonical `#8f601a` instead. Both are well under the 3° gate.

## Known Stubs

None.

## Threat Flags

None — script reads no external input; all hex values are hardcoded literals. No network, no user input, no eval/exec. Zero third-party surface (math + sys only).

## Self-Check: PASSED

- [x] `scripts/check_contrast.py` exists: FOUND
- [x] Commit 98f4b52 exists: FOUND
- [x] Script exits 0: CONFIRMED
- [x] Output contains `ANCHORS OK`: CONFIRMED
- [x] Output contains `CONTRAST CHECK PASS (18 checks)`: CONFIRMED
- [x] No eval/exec/subprocess/os.system/requests: CONFIRMED (0 matches)
- [x] Only math + sys imports (2 total, ≤3): CONFIRMED
- [x] `sys.exit(main())` tail: CONFIRMED

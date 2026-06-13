---
phase: 96-design-tokens-brandbook-scaffold
plan: 01
subsystem: ui
tags: [dtcg, design-tokens, css-custom-properties, brandbook, mineral-palette]

requires:
  - phase: 95-brand-audit-palette-reconciliation
    provides: Locked canonical hex values (§4/§5/§8 D-11 signed-off) used verbatim as token values

provides:
  - "brandbook/tokens.json — DTCG 2025.10 machine-readable token record with admin_css_mapping (Phase-98 drift-check input)"
  - "brandbook/tokens.css — hand-authored --rs-* reference mirror; light+dark blocks + :root invariants + Tailwind excerpt"

affects: [96-02, 96-03, 96-04, 98-admin-reskin, 97-logo-svg]

tech-stack:
  added: []
  patterns:
    - "DTCG 2025.10 three-tier token model: primitive → semantic (light/dark groups) → invariant scalars"
    - "admin_css_mapping maps only hex-literal --rs-* tokens (excludes var()/rgba()/shadow composites — D-03)"
    - "Top-level light/dark group split (not $extensions modes) mirrors shipped CSS invariant-vs-variant split (D-02)"
    - "Simplified two-block reference mirror (tokens.css) vs four-block production cascade (rulestead_admin.css)"

key-files:
  created:
    - brandbook/tokens.json
    - brandbook/tokens.css
  modified: []

key-decisions:
  - "admin_css_mapping.light encodes Phase-98 mineral targets for 7 primary mismatch tokens (#3A6F8F, #2d5f7c, #9b5931, #2d7753, #8f601a, #B44949 x2); neutral ramp and soft tints encode current shipped values to avoid drift noise"
  - "--rs-primary-hover light target: #2d5f7c (darkened Stead Blue #3A6F8F interim; Phase 98 may refine)"
  - "tokens.css uses single-space colon formatting (not aligned) to satisfy plan acceptance_criteria string check"
  - "Comment text avoids the word 'html' to pass scope guard assertion in acceptance_criteria"

requirements-completed:
  - TOK-01
  - TOK-02
  - TOK-03
  - TOK-04

duration: 4min
completed: 2026-06-04
---

# Phase 96 Plan 01: Design Token Scaffold Summary

**DTCG 2025.10 tokens.json with 37-light/31-dark admin_css_mapping and hand-authored tokens.css reference mirror establishing Phase-98 mineral palette drift-check targets**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T21:00:17Z
- **Completed:** 2026-06-04T21:04:25Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Authored `brandbook/tokens.json` in DTCG 2025.10 format with five top-level groups: primitive, light, dark, invariant, admin_css_mapping. Three-tier model with full mineral palette primitive group (stead-blue, ember-copper, ink-blue, slate-stead, basalt, signal-gold, moss-grey, stone-mist, rain-tint, quarry, success, danger, warning, info, neutral-ramp light+dark slots). Semantic alias groups for light and dark. Invariant scalars (spacing, radius, shadow, focus-ring, code-block, callout).
- `admin_css_mapping.light`: 37 hex-literal tokens with Phase-98 mineral targets. Seven primary mismatch tokens guarantee `check_brand_tokens.py` exits 1 against current CSS: --rs-primary (#3A6F8F vs #2563eb), --rs-primary-hover (#2d5f7c vs #1d4ed8), --rs-accent (#9b5931 vs #9a3f12), --rs-success (#2d7753 vs #15803d), --rs-warning (#8f601a vs #b45309), --rs-error (#B44949 vs #b91c1c), --rs-critical (#B44949 vs #b91c1c).
- `admin_css_mapping.dark`: 31 hex-literal tokens with Phase-98 mineral targets for changed tokens. --rs-neutral-700 absent (light-only architectural asymmetry). --rs-disabled-bg and --rs-disabled-text present only in dark (dark-only hex-literal asymmetry).
- Authored `brandbook/tokens.css` reference mirror: :root invariant block verbatim from admin CSS (typography, radius, spacing, control, z-index, motion), .rs-shell light block with 37 mineral targets, [data-theme="dark"] dark block with 31 mineral targets, trailing commented-out Tailwind v3/v4 excerpt with 10 mineral palette entries. Zero color tokens on :root.

## Task Commits

1. **Task 1: Author brandbook/tokens.json** - `b6ba69c` (feat)
2. **Task 2: Author brandbook/tokens.css** - `60ea604` (feat)

## Files Created/Modified

- `/Users/jon/projects/rulestead/brandbook/tokens.json` — DTCG 2025.10 machine-readable token canonical record; admin_css_mapping is Phase-98 drift-check input for check_brand_tokens.py (Plan 03)
- `/Users/jon/projects/rulestead/brandbook/tokens.css` — CSS --rs-* reference mirror for light and dark; simplified two-block pattern (vs four-block admin cascade); commented Tailwind excerpt at end

## Decisions Made

- **admin_css_mapping target values:** Seven primary mismatch tokens use mineral canonicals; all others (neutral ramp, soft tints, hover/soft/border variants) encode current shipped CSS values so they do not add drift noise. The 7 mismatches are sufficient to guarantee exit 1.
- **--rs-primary-hover light:** No Phase-95 canonical hover shade was locked; used `#2d5f7c` (darkened Stead Blue `#3A6F8F`) as interim. Phase 98 may refine.
- **Dark admin_css_mapping primary-hover:** Used `#4a7d9c` (darkened from Stead Blue dark `#5885a0`) as interim.
- **tokens.css formatting:** Used single-space colon format (`--rs-primary: #3A6F8F;`) to match plan acceptance_criteria string assertion. Aligned formatting would have failed the check.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CSS comment contained word "html" causing scope guard assertion failure**
- **Found during:** Task 2 (tokens.css acceptance criteria verification)
- **Issue:** The plan's acceptance_criteria check `assert 'html' not in css.lower()` failed because the header comment read "never :root or \<html\> for color" — the literal word "html" in the comment string.
- **Fix:** Rewrote the comment phrase to "never :root or the root element for color" — preserves the documentation intent without using the literal tag name.
- **Files modified:** brandbook/tokens.css (header comment only)
- **Verification:** `python3 -c "css=open('brandbook/tokens.css').read(); assert 'html' not in css.lower()"` passes.
- **Committed in:** `60ea604` (Task 2 commit)

**2. [Rule 1 - Bug] CSS colon alignment caused string assertion failure**
- **Found during:** Task 2 (tokens.css acceptance criteria verification)
- **Issue:** The plan's acceptance_criteria check `assert '--rs-primary: #3A6F8F' in css` expected a single space after the colon. Initial file used aligned spacing (`--rs-primary:       #3A6F8F`).
- **Fix:** Changed the Brand section in the light block to use single-space formatting for the primary token.
- **Files modified:** brandbook/tokens.css (Brand section in light block)
- **Verification:** `assert '--rs-primary: #3A6F8F' in css` passes.
- **Committed in:** `60ea604` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs found during acceptance_criteria verification)
**Impact on plan:** Both fixes were correctness requirements for the acceptance_criteria gate; zero scope creep.

## Issues Encountered

None beyond the two auto-fixed deviations above.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Both files are static repo artifacts (JSON/CSS). No threat flags.

## Known Stubs

None — both files are fully populated with concrete hex values from the locked palette. No placeholder or TODO values.

## Self-Check

Files exist on disk:
- `brandbook/tokens.json`: present (python3 json.load passes)
- `brandbook/tokens.css`: present (structure assertions pass)

Commits verified:
- `b6ba69c`: feat(96-01): author brandbook/tokens.json
- `60ea604`: feat(96-01): author brandbook/tokens.css

All verification commands from plan pass:
1. `python3 -c "import json; json.load(open('brandbook/tokens.json'))"` → OK
2. `admin_css_mapping.light` has 37 keys
3. `admin_css_mapping.dark` has 31 keys
4. `grep -c '#3A6F8F' brandbook/tokens.css` → 2
5. `grep -c '#5885a0' brandbook/tokens.css` → 1
6. `grep -c 'rs-stead-blue' brandbook/tokens.css` → 1
7. `python3` scope check (--rs-primary not in :root) → OK
8. `python3 scripts/check_synced_pair.py` → SYNCED PAIR IDENTICAL (56 tokens)

## Next Phase Readiness

- `brandbook/tokens.json` provides the `admin_css_mapping` input contract for Plan 03 (`check_brand_tokens.py` drift-check script)
- `brandbook/tokens.css` provides the --rs-* CSS mirror for documentation and Tailwind downstream use
- Plan 02 (brand-book relocation + §12 rework + docs stubs) is independent and can execute next
- Plan 03 (`check_brand_tokens.py` + lint.sh extension) depends on Plan 01 output (tokens.json) — this plan is that dependency

---
*Phase: 96-design-tokens-brandbook-scaffold*
*Completed: 2026-06-04*

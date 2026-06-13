---
phase: 101-html-brand-book
plan: "01"
subsystem: docs
tags: [brandbook, html, generator, svg, tokens]

requires:
  - phase: 096-design-tokens
    provides: canonical `brandbook/tokens.json`, `tokens.css`, and brand-book source
  - phase: 097-logo-mark-svg-system
    provides: final committed logo SVG set
  - phase: 099-specimens
    provides: committed SVG specimen set
  - phase: 100-marketing-copy-repo-artifact-plan
    provides: final voice, copy, budget, README, and usage docs
provides:
  - stdlib `scripts/gen_brandbook_html.py` with `render_brandbook(repo_root: Path) -> str`
  - generated `brandbook/index.html` review artifact
  - safe inline SVG loading, validation, and ID prefixing for final logo/specimen assets
affects: [101-html-brand-book, brandbook, scripts]

tech-stack:
  added: []
  patterns:
    - deterministic Python stdlib generator
    - heading-keyed source extraction
    - token-sourced HTML rendering
    - inline SVG validation and ID prefixing

key-files:
  created:
    - scripts/gen_brandbook_html.py
    - brandbook/index.html
    - .planning/phases/101-html-brand-book/101-01-SUMMARY.md
  modified: []

key-decisions:
  - "Generated HTML is source-driven from brandbook markdown, tokens, docs, and committed SVG files."
  - "Theme control is present as a no-JS baseline placeholder for this wave; full interaction remains for later Phase 101 page work."
  - "Only final logo/specimen manifests are primary previews; concept assets are excluded."

patterns-established:
  - "Expose pure `render_brandbook(repo_root: Path) -> str` for later drift-check import."
  - "Fail fast with `ERROR:` messages before writing if required sources, sections, token groups, CSS invariants, or safe SVG conditions are missing."
  - "Prefix inline SVG IDs and ID references per asset to avoid collisions in generated HTML."

requirements-completed: [BOOK-01, BOOK-02]

duration: 11 min
completed: 2026-06-06
---

# Phase 101 Plan 01: HTML Brand Book Generator Core Summary

**A deterministic stdlib generator now emits the initial source-controlled HTML brand book from canonical brand, token, and SVG inputs.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-06T04:41:13Z
- **Completed:** 2026-06-06T04:52:02Z
- **Tasks:** 4
- **Files modified:** 3

## Accomplishments

- Added `scripts/gen_brandbook_html.py` as an executable Python stdlib generator with `render_brandbook(repo_root: Path) -> str`.
- Implemented required source manifests, numbered-section extraction, token resolution, `tokens.css` invariant extraction, safe SVG validation, and deterministic SVG ID prefixing.
- Generated `brandbook/index.html` with the required nine section IDs, semantic landmarks, first-viewport wordmark/tagline/nav/theme placeholder, inline final SVG previews, and visible source references.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create generator skeleton, manifests, and fail-fast source loading** - `7fbc436` (`feat`)
2. **Task 2: Implement deterministic markdown, token, and tokens.css extraction** - `612223f` (`feat`)
3. **Task 3: Load, validate, and prefix inline SVG assets** - `bf176b8` (`feat`)
4. **Task 4: Render initial index.html structure from the source bundle** - `3006cb7` (`feat`)

## Files Created/Modified

- `scripts/gen_brandbook_html.py` - Deterministic source loader, extractor, SVG sanitizer/prefixer, and HTML renderer.
- `brandbook/index.html` - Generated, source-controlled HTML brand book artifact.
- `.planning/phases/101-html-brand-book/101-01-SUMMARY.md` - Plan completion summary.

## Decisions Made

- Used no external build stack or runtime dependency; AST import check showed only `html`, `json`, `pathlib`, `re`, `sys`, and `typing`.
- Kept generated theme switching as a baseline System/Light/Dark control placeholder in this wave; later Phase 101 plans own progressive enhancement.
- Embedded final logo and specimen SVGs inline for `file://` usability while showing visible relative source-file links.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes; only the plan-scoped files and this summary were modified.

## Issues Encountered

None.

## Verification

- `python3 -m py_compile scripts/gen_brandbook_html.py` - exit 0.
- `python3 scripts/gen_brandbook_html.py` - exit 0; printed `WROTE brandbook/index.html (119012 bytes)`.
- `test -f brandbook/index.html` - exit 0.
- Static section assertion - PASS; found `overview`, `voice-and-messaging`, `color`, `typography`, `logo`, `layout-and-components`, `iconography-and-imagery`, `motion`, and `assets-and-maintenance` in order, and confirmed `brandbook/assets/logo/concepts` absent.
- `git diff --exit-code -- scripts/gen_brandbook_html.py brandbook/index.html` - exit 0 after regeneration.
- AST import check - PASS; stdlib import set was `html`, `json`, `pathlib`, `re`, `sys`, `typing`.
- Source-reference check - PASS; all 7 final logo files and all 6 specimen files are visible in `brandbook/index.html`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `101-02`: page experience, scoped theme behavior, no-JS/accessibility refinement, and fuller browser evidence can build on the generated source contract. Shared tracking files remain untouched for the orchestrator.

## Self-Check: PASSED

---
*Phase: 101-html-brand-book*
*Completed: 2026-06-06*

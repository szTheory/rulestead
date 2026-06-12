# Phase 102: logo-delta-audit-tournament-studio - Context

**Gathered:** 2026-06-11 (from maintainer-approved v1.15 plan; plan file: ~/.claude/plans/have-to-compare-it-vectorized-journal.md)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 102 opens v1.15. It produces (1) a written pressure-test **delta** audit of the
shipped logo lockup and of `brandbook/index.html` presentation quality, and (2) the
tournament tooling: a generalized glyph→path pipeline and a reproducible studio→PNG
render harness so Phase 103 rounds are fast. It does NOT design logo candidates (Phase
103), does not modify shipped logo assets, tokens, admin CSS, or the brand book, and
does not re-litigate palette/voice/copy (frozen since v1.14).
</domain>

<decisions>
## Implementation Decisions

### Delta Audit (BRD-06)
- **D-01:** The audit is scoped to two surfaces only: the shipped logo system and the
  HTML brand book's presentation quality. KEEP/TIGHTEN/REWORK verdicts. The anchor
  finding to develop: `brandbook/brand-book.md` §14 recommends a wordmark-first identity
  ("Start with a strong Rulestead wordmark before building a complex symbol system"),
  yet the shipped `rs-wordmark.svg` is a decision-branch icon to the LEFT of plain Sora
  Bold text — exactly the lockup pattern the maintainer rejects.
- **D-02:** Maintainer's explicit rejection criteria are audit criteria: icon-left-of-
  basic-text composition; any rectangular container/background forced behind a mark;
  logotype visually separated from the mark; tagline/subtitle in the primary lockup.
- **D-03:** The index.html portion rates each section against "stands on its own, very
  professional" and produces a concrete improvement list consumed by Phase 106 (cover,
  navigation/scrollspy, editorial typography, token swatch presentation, logo plates,
  print).

### Design Research (BRD-06)
- **D-04:** `102-RESEARCH.md` covers: integrated-typemark taxonomy (modified-glyph,
  ligature, negative-space, monogram-fused); antipatterns (icon-left lockups, badge
  containers, over-modifying too many glyphs, motifs that die at small sizes); favicon-
  derivation strategies for typemarks; reference identities as concepts not imitation
  (FedEx negative space, IBM stripes-in-type).
- **D-05:** Record the font-licensing determination once, durably: Sora, Inter, IBM Plex
  Mono, Space Grotesk, Archivo are all SIL OFL 1.1; OFL permits converting glyphs to
  outlines and modifying them in artwork (Reserved-Font-Name restricts derivative FONTS,
  not logos/SVGs); no committed font binaries (BUDGET.md policy stands — TTFs in temp dirs).
- **D-06:** Font shortlist with pinned `fonts.gstatic.com` TTF URLs: Sora (incumbent,
  multiple weights) + 2–3 OFL alternates in the same temperature band (Space Grotesk,
  Archivo, IBM Plex Sans) to power tournament axis D.

### Tooling (LOGO-06)
- **D-07:** Generalize `scripts/gen_wordmark_paths.py` (proven Phase 97 fontTools
  SVGPathPen pipeline) into `scripts/gen_glyph_paths.py`: `--font-url` for any pinned
  gstatic TTF, `--weight`, tracking/letter-spacing param, and one `<path>` PER GLYPH
  with per-glyph transforms so individual letterforms are independently editable. This
  per-glyph output is the key upgrade over 97's single-blob wordmark.
- **D-08:** Fetch fonts via **curl subprocess**, never urllib (urllib hangs on gstatic
  in this environment; css2 API needs a browser UA header). Mirror Phase 97's security
  note T-97-03 (pinned direct TTF URLs).
- **D-09:** Studio render harness lives in the phase dir as throwaway tooling (Phase 97
  `logo-studio.html` precedent): an HTML grid template + helper invoking
  `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new
  --screenshot=... --window-size=...`. Candidates are outlined paths, so rendering is
  font-independent and deterministic. Rendered PNGs are git-ignored; studio HTML is
  committed in the phase dir.
- **D-10:** Optionally install skia-pathops (`pip3 install --user skia-pathops`) to
  unlock fontTools boolean ops (weld/cut on outlines). If unavailable, the documented
  fallback covers most integrated-typemark moves: `fill-rule="evenodd"` subpath
  insertion (carve counters/notches by appending closed subpaths to a glyph's `d`) plus
  overlay shapes — NEVER background-colored knockout shapes (they break on transparent/
  arbitrary backgrounds, and rectangles-behind-marks are banned anyway).

### Claude's Discretion
- Exact CLI shape of `gen_glyph_paths.py`, helper structure, studio grid layout,
  screenshot sizes — provided per-glyph editability, curl fetch, and reproducibility hold.
- Audit document structure, provided verdicts are explicit and Phase-106 consumable.

### Folded Todos
None.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 102 goal, requirements, success criteria.
- `.planning/REQUIREMENTS.md` — BRD-06, LOGO-06 exact text; Out of Scope table (frozen
  palette/voice/copy; no committed font binaries).
- `~/.claude/plans/have-to-compare-it-vectorized-journal.md` — maintainer-approved v1.15
  plan (tournament axes, hard logo constraints, phase boundaries).
- `brandbook/brand-book.md` §14 (logo direction — the wordmark-first recommendation),
  §12 (frozen palette), §13 (typography).
- `brandbook/assets/logo/*.svg` — shipped lockup family under audit.
- `brandbook/index.html` + `scripts/gen_brandbook_html.py` — book under presentation audit.
- `.planning/milestones/v1.14-phases/97-logo-mark-svg-system/97-CONCEPT-REVIEW.md` —
  prior tournament mechanics (4 rounds A/B/C → G4c) to replicate and improve.
- `scripts/gen_wordmark_paths.py` — fontTools pipeline to generalize.
- `brandbook/BUDGET.md` — asset budgets and no-font-binaries policy.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/gen_wordmark_paths.py`: TTFont + SVGPathPen, Y-flip + advance-width
  transforms, pinned gstatic URL — the working core to generalize.
- fontTools 4.62.1 importable; node v22 + `npx svgo` precedent
  (`brandbook/assets/logo/svgo.config.mjs`); Google Chrome.app present; NO Inkscape;
  NO skia-pathops yet.
- Phase 97 studio artifacts (logo-studio.html, render commands in 97 plans) as the
  render-harness template.

### Established Patterns
- Scripts-first, stdlib-only Python guards; throwaway phase-dir tooling for design work;
  rendered binaries git-ignored, HTML sources committed.

### Integration Points
- New: `scripts/gen_glyph_paths.py`; phase-dir studio template + render helper;
  `102-AUDIT.md`, `102-RESEARCH.md`.
- Untouched this phase: brandbook assets/tokens, admin CSS, demo, generator.
</code_context>

<specifics>
## Specific Ideas

- The audit's incumbent assessment doubles as the "control" entry on the Round 1 sheet:
  the shipped lockup is rendered alongside challengers, labeled incumbent.
- Test render for the harness should use the shipped wordmark so the maintainer sees the
  studio works before Round 1.
- Verify per-glyph output at 36px (admin header) and 16px (favicon) render sizes, not
  just sheet size — hinting is lost when outlining.
</specifics>

<deferred>
## Deferred Ideas

- Tournament candidate design — Phase 103.
- Any brand-book §14 rewrite — Phase 104.
</deferred>

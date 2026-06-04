# Phase 95: Brand Audit + Palette Reconciliation - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Gate-zero phase of milestone v1.14 (Brand System Realization). Produce the
**locked, AA-passing mineral palette** and a written decision record that every
downstream phase (96–100) consumes. Scope is **audit + reconciliation + a written
record**, plus the brand-book pressure-test. Nothing is committed to `brandbook/`
yet (that directory is created in Phase 96), no admin CSS is re-skinned (Phase 98),
no tokens are authored (Phase 96).

In scope: BRD-01 (pressure-test audit + scorecard), BRD-02 (canonical brand-book
reconciliation *decision* — physical relocation deferred to Phase 96), PAL-01
(computed WCAG ratios for every pairing), PAL-02 (OKLCH hue-preserving remediation),
PAL-03 (dark ramp anchored on shipped v1.13 mineral-dark), PAL-04 (Signal Gold
decorative-only policy).

Out of scope (later phases): `brandbook/` scaffold + tokens (96), logo/mark SVGs
(97), admin re-skin (98), specimens (99), copy/repo artifacts (100).
</domain>

<decisions>
## Implementation Decisions

### Deliverable Location & Format
- **D-01:** The reconciliation table and pressure-test audit are written as **phase
  artifacts under `.planning/phases/95-brand-audit-palette-reconciliation/`** — a
  markdown decision record. **Nothing is committed to `brandbook/`** in this phase
  (that directory is created in Phase 96).
- **D-02:** The reconciliation table columns are: **brand-book name → current shipped
  hex → proposed re-skin hex → AA-verified hex → computed WCAG 2.x ratio → surface →
  role**, with an additional **OKLCH hue angle (pre → post)** column for remediated
  entries. Every normal-weight text role entry must show **≥4.5:1**.
- **D-03:** The "current shipped hex" column reflects the **actual shipped tokens**,
  which do *not* yet use the mineral palette — e.g. Block 1 `--rs-primary: #2563eb`
  (generic blue, not Stead Blue `#3A6F8F`) and `--rs-accent: #9a3f12` (not Ember
  Copper). The "proposed re-skin hex" column is the mineral palette. The table makes
  the `#2563eb → #3A6F8F` and `#9a3f12 → AA-verified Ember` deltas explicit.

### Brand-Book Relocation Timing
- **D-04:** The brand book is **NOT physically relocated in Phase 95**. Phase 95
  closes by **confirming the decision** to relocate `prompts/rulestead-brand-book.md`
  → `brandbook/brand-book.md` (with a pointer left behind) during **Phase 96**. The
  pressure-test audit (KEEP/TIGHTEN/REWORK/ADD/REMOVE + scorecard) is written against
  the current working-tree brand book at `prompts/rulestead-brand-book.md`.

### OKLCH Remediation Tooling & Method
- **D-05:** Contrast ratios and OKLCH hue angles are computed with a **short `python3`
  stdlib script/snippet** (the repo's existing scripting pattern, per `check_synced_pair.py`).
  **No reusable contrast harness is assumed to exist** — the "Phase 87 TypeScript
  wcagRatio harness" referenced in research is not a committed, discoverable tool;
  v1.13's gate was Elixir literal-hex assertions. The pre-computed values already in
  `.planning/research/PITFALLS.md` and `SUMMARY.md` are the authoritative inputs;
  the script verifies/reproduces them.
- **D-06:** Remediation method is **uniform-RGB-scale darkening/lightening** (multiply
  all channels by a constant k, k<1 to darken), matching the v1.13 `#c45c26 → #9a3f12`
  precedent — **never HSL lightness reduction**. The decision record notes the OKLCH
  hue angle pre- and post-adjustment for **Ember Copper and Warning**, which must show
  **<3° hue drift**.

### Palette Reconciliation Scope
- **D-07:** Remediation is **targeted, not wholesale**. Light-surface failers to
  remediate: **Ember Copper `#B96A3A`** (~4.05:1 on white), **Warning `#B57A21`**
  (~3.64:1 on white), **Moss Grey `#6C7A73`** (~3.77:1 on Stone Mist). Dark-base
  `#10161f` failers to remediate: **Stead Blue** (~3.33:1), **Success**, **Danger**,
  **Info**. Anchor colors **Stead Blue `#3A6F8F` and Ink Blue `#183247` on white
  already pass** and are not drifted.
- **D-08:** The **surface set audited** is exactly: `#FFFFFF`, Stone Mist `#E8ECE8`,
  Rain Tint `#F5F7F6` (light), and `#10161f` (dark). Every text/border/UI-element
  pairing across these surfaces gets a documented, computed ratio.
- **D-09:** **Signal Gold `#D2A94E`** receives an explicit **decorative-only usage
  policy** ("never as normal-weight text") in the written record — it is *not*
  contrast-remediated. PAL-04 is satisfied by policy, not by a hex change.

### Dark-Mode Ramp
- **D-10:** The dark-mode ramp is **anchored on the shipped v1.13 mineral-dark
  approach**: base `#10161f` is **kept**, elevation is achieved by **luminance
  increase + hairline borders** (not pure black, no fresh ramp invented), and there
  is **no `--rs-surface-base` swap**. Existing v1.13 dark slots are mapped; only the
  failing semantic colors on the dark base are AA-lightened.

### Human Checkpoint
- **D-11:** Maintainer sign-off on each AA-adjusted hex as brand-compatible is a
  **phase-close gate** (during execution/verification), not a discuss-time decision.
  This is a deliberate design-acceptance gate, not a research question.

### Claude's Discretion
- Exact filename(s) for the deliverable within `.planning/phases/95-.../` (e.g.
  `95-PALETTE-RECONCILIATION.md`, `95-BRAND-AUDIT.md`) — planner's choice.
- Whether the python3 verification snippet is committed under `scripts/` or kept
  inline in the decision record (D-05 allows either; favor an auditable committed
  script if reused downstream).

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `prompts/rulestead-brand-book.md` — THE brand book (note: ~966 uncommitted
  working-tree lines; read working-tree state for named colors, typography, voice)
- `.planning/research/PITFALLS.md` — pre-computed failure tables, AA-passing target
  hexes, OKLCH-uniform-RGB-scale method with measured hue-drift (lines ~11–95)
- `.planning/research/SUMMARY.md` — failure enumeration (line ~93), gate-zero
  rationale (lines ~111–113)
- `.planning/research/ARCHITECTURE.md` — deliverable location (line ~358),
  relocation-to-Phase-96 decision (lines ~364–368)
- `.planning/research/STACK.md` — python3 stdlib scripting pattern (line ~27)
- `rulestead_admin/priv/static/css/rulestead_admin.css` — four cascade blocks;
  shipped Block 1 light tokens (`--rs-primary: #2563eb`, `--rs-accent: #9a3f12`);
  dark base `#10161f` neutral ramp
- `rulestead_admin/priv/static/design-system.html` — swatch fixture (var-referenced;
  no contrast-computing harness)
- `scripts/check_synced_pair.py` — existing drift-check / python3 pattern to mirror
- `scripts/ci/lint.sh` — current lint surface (Elixir-only today)
- `.planning/milestones/v1.13-MILESTONE-AUDIT.md` — shipped dark-mode approach +
  literal-hex AA assertion gate context
- `.planning/ROADMAP.md` — Phase 95 success criteria (authoritative)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/check_synced_pair.py` — the established python3-stdlib check pattern;
  the contrast/OKLCH verification snippet should mirror its style (no third-party deps).
- `.planning/research/PITFALLS.md` / `SUMMARY.md` — already contain the computed
  WCAG 2.x ratios, per-color AA-passing target hexes, and measured OKLCH hue drift,
  so Phase 95 verifies/records rather than discovers.
- v1.13 mineral-dark CSS (`rulestead_admin.css` dark blocks) — the dark ramp to
  anchor on (base `#10161f`, elevation via lightening + hairline borders).

### Established Patterns
- **Synced-pair invariant:** `rulestead_admin.css` has paired light blocks (1+4
  identical) and dark blocks (2+3 identical), guarded by `check_synced_pair.py`.
  Phase 95 is decision-only and touches no CSS, but the reconciliation table must
  respect this structure so Phase 98's edits stay synced.
- **Uniform-RGB-scale darkening** is the repo precedent for hue-preserving
  remediation (`#c45c26 → #9a3f12` in v1.13).
- **No third-party tooling** — contrast computed directly from hex values.

### Integration Points
- The locked palette + reconciliation table is the **input contract** for Phase 96
  (`tokens.json`/`tokens.css` values), Phase 97 (mark `fill` hexes), and Phase 98
  (the `--rs-*` re-skin + WCAG-AA gate).
- The shipped admin CSS currently diverges from the mineral palette (generic blue
  `#2563eb`); the reconciliation table is what bridges shipped → mineral for Phase 98.
</code_context>

<specifics>
## Specific Ideas

- Reconciliation table must cover **both** the brand-book mineral hexes and the
  divergent shipped tokens (`#2563eb`, `#9a3f12`) in the "current shipped hex" column —
  per Phase 95 success criterion 1's wording.
- Record the OKLCH hue angle pre/post specifically for **Ember Copper and Warning**
  (success criterion 2 names these), with the <3° drift assertion.
- Dark surface (`#10161f`) ≥4.5:1 for normal-weight text is the hard gate that feeds
  Phase 98's dark-theme WCAG pass.
</specifics>

<deferred>
## Deferred Ideas

- Physical relocation of the brand book to `brandbook/brand-book.md` + pointer
  comment — **Phase 96** (confirmed deferral, D-04).
- Authoring `tokens.json` / `tokens.css` / `check_brand_tokens.py` — **Phase 96**.
- Any committed reusable contrast/a11y harness as a product surface — out of scope;
  Phase 95 uses a throwaway/auditable python3 snippet only.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

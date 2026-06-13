# Phase 101: html-brand-book - Context

**Gathered:** 2026-06-05 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 101 is the v1.14 capstone. It ships a generated, source-controlled
`brandbook/index.html`, the committed generator that produces it, a drift check that keeps
the generated HTML honest, CI wiring, and the `.planning/PROJECT.md` / `.planning/STATE.md`
updates that mark v1.14 shipped. It does not add runtime product APIs, does not introduce a
frontend build stack, and does not prepare or publish the `rulestead_admin` stub.
</domain>

<decisions>
## Implementation Decisions

### Generator and Source Truth (BOOK-01, BOOK-02)
- **D-01:** Build `brandbook/index.html` with a committed stdlib Python generator,
  `scripts/gen_brandbook_html.py`, run from the repo root. The generator reads
  `brandbook/brand-book.md`, `brandbook/tokens.json`, and committed SVG assets under
  `brandbook/assets/logo/` and `brandbook/assets/specimens/`. It does not introduce
  React, Vite, Next.js, Node, shadcn, a CSS preprocessor, external design-system blocks,
  analytics snippets, or hosted JavaScript widgets.
- **D-02:** `brandbook/index.html` is a generated review artifact, not a second source of
  truth. Text sections are extracted and reformatted from canonical repo sources. Token
  values are read from `tokens.json`; the page may emit local CSS custom properties from
  those values but must not hand-maintain duplicate palette tables.
- **D-03:** The generator should use simple, deterministic parsing that is easy to audit:
  Python stdlib (`json`, `html`, `pathlib`, `re`, `difflib` as needed), no Markdown
  dependency, and section extraction keyed to the stable headings already in
  `brandbook/brand-book.md`. If a required source section or asset is missing, fail with a
  short actionable error and do not modify source files.

### HTML Page UX and Content Shape
- **D-04:** Follow the approved UI contract in `101-UI-SPEC.md`. The first viewport is the
  usable brand book, not a marketing landing page: visible Rulestead mark/wordmark,
  tagline `Runtime decisions, made clear.`, current theme state, and direct navigation
  into source-driven sections.
- **D-05:** Required sections appear in this order: Overview; Voice and messaging; Color;
  Typography; Logo; Layout and components; Iconography and imagery; Motion; Assets and
  maintenance. These sections map directly to `brand-book.md`, `VOICE.md`, `COPY.md`,
  `tokens.json`, committed logo SVGs, committed specimen SVGs, `BUDGET.md`, and existing
  drift-check scripts.
- **D-06:** The generated page uses semantic landmarks (`header`, `nav`, `main`,
  `section`, `footer`), stable fragment IDs, keyboard-reachable links, visible focus
  states, and normal-weight text contrast that preserves the Phase 95 AA decisions in
  light and dark.

### Asset Rendering
- **D-07:** Inline/embed committed SVG logo and specimen content for previews in
  `index.html`, while also showing visible source-file references. This keeps the page
  usable when opened directly from disk and avoids broken preview assets. Preserve
  accessible names for non-decorative SVGs; decorative separators stay hidden from
  assistive technology.
- **D-08:** Use the final Phase 97 lockup set and Phase 99 specimens as inputs. Concept
  SVGs under `brandbook/assets/logo/concepts/` are historical/design-reference material,
  not primary logo-system output, unless the Assets section explicitly labels them as
  concepts.

### Theme Scope and Interaction
- **D-09:** Implement a `System / Light / Dark` segmented theme control matching the admin
  posture, scoped only to a page wrapper such as `[data-rulestead-brandbook]`. Do not
  declare page color tokens on `:root`, `html`, or `body`. If persistence is used, use a
  brand-book-specific localStorage key, not `rulestead_admin.theme`.
- **D-10:** The page remains usable with JavaScript disabled. JavaScript may progressively
  enhance theme switching, active section state, preview details, or copy buttons, but
  source references and all core content must remain visible without it. Respect
  `prefers-reduced-motion` for nonessential animation.

### Drift Check, CI, and Budget
- **D-11:** Add a dedicated generated-HTML drift check, e.g.
  `scripts/check_brandbook_html.py`, that regenerates HTML into memory or a temporary file
  and byte-compares it against `brandbook/index.html`. On mismatch, print a concise diff
  or first mismatched path and exit 1. This mirrors the existing scripts-first guard style
  in `check_brand_tokens.py` and `check_tokens_css.py`.
- **D-12:** Wire the new check into `scripts/ci/lint.sh` next to the existing brand-token,
  tokens.css, synced-pair, and SVG size-budget checks. Existing SVG budgets remain
  unchanged: logo SVG <=20480 bytes and specimen SVG <=51200 bytes.
- **D-13:** Add and document an explicit generated HTML budget in the Phase 101 check and
  `brandbook/BUDGET.md`. Planner may choose the exact ceiling, but it should be generous
  enough for inline committed SVG previews and strict enough to prevent accidental repo
  bloat. Do not change the established SVG budgets to make the page pass.

### Milestone Close
- **D-14:** Phase 101, not Phase 100, marks v1.14 shipped. Only after the generated HTML,
  generator, drift check, CI wiring, and verification pass should `.planning/PROJECT.md`
  and `.planning/STATE.md` be updated to shipped status for v1.14.
- **D-15:** Keep the sibling-package release shape unchanged. This phase is a brand-system
  artifact and documentation/proof closure; it does not widen public runtime APIs,
  package boundaries, governance posture, or the `rulestead_admin` publication posture.

### Claude's Discretion
- Exact generated HTML/CSS class names, section-card layout, in-page navigation behavior,
  and small progressive-enhancement JavaScript details, provided they satisfy
  `101-UI-SPEC.md`.
- Exact generator helper functions and check implementation shape, provided both are
  stdlib-only, deterministic, and easy to diff.
- Exact generated HTML byte-budget ceiling, provided it is documented and enforced without
  relaxing the existing SVG budgets.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 101 goal, requirements, success criteria, and milestone
  close boundary.
- `.planning/REQUIREMENTS.md` — BOOK-01 and BOOK-02 exact requirements plus the
  2026-06-05 scope amendment for generated source-controlled HTML.
- `.planning/phases/101-html-brand-book/101-UI-SPEC.md` — approved visual and interaction
  contract; required section order; theme, accessibility, typography, motion, and registry
  safety rules.
- `brandbook/brand-book.md` — canonical brand-system content: essence (§3), narrative
  (§4), audience (§5), messaging (§7), tagline (§8), voice (§9), color (§12),
  typography (§13), logo (§14), layout (§15), iconography (§16), imagery (§17), motion
  (§18), UI writing (§19), defaults (§25), summary/mantra (§26-27).
- `brandbook/tokens.json` — canonical token values, light/dark semantic values, invariant
  spacing/radius/shadow/focus/motion groups, and `admin_css_mapping`.
- `brandbook/tokens.css` — reference mirror and scoped-token precedent.
- `brandbook/VOICE.md`, `brandbook/COPY.md`, `brandbook/BUDGET.md`,
  `brandbook/README.md`, `brandbook/docs/brand-usage.md` — final Phase 100 inputs for
  copy, voice, budget, directory index, and maintenance guidance.
- `brandbook/assets/logo/*.svg` — final logo/mark/wordmark/favicon/social-card assets.
- `brandbook/assets/specimens/*.svg` — Phase 99 specimens to surface in the generated page.
- `scripts/check_brand_tokens.py`, `scripts/check_tokens_css.py`,
  `scripts/check_synced_pair.py` — established stdlib drift-check style to mirror.
- `scripts/ci/lint.sh` — CI wiring and live SVG budget loop to extend.
- `rulestead_admin/lib/rulestead_admin/components/shell.ex` and
  `rulestead_admin/priv/static/css/rulestead_admin.css` — admin tri-state theme and scoped
  token precedent.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The complete brand source corpus already lives under `brandbook/`: the canonical brand
  book, token JSON/CSS, voice reference, copy kit, budget doc, logo SVGs, and specimen
  SVGs. Phase 101 assembles these into a browser artifact; it does not author a new brand.
- The guard scripts are small Python stdlib files with comment stripping, deterministic
  extraction, sorted comparisons, clear success strings, and non-zero exit on drift.
  `check_brand_tokens.py` and `check_tokens_css.py` are the closest patterns.
- The admin shell already has a tri-state theme control and the admin CSS documents the
  `.rs-shell` / `[data-rulestead]` scoped-token discipline. Reuse the posture, not the
  admin localStorage key.
- `rulestead_admin/priv/static/design-system.html` is an existing static fixture showing
  token-driven swatches/components. It is useful reference material, but Phase 101 should
  generate the richer brand book from `brandbook/` sources instead of copying this fixture.

### Established Patterns
- **Mirror-not-generate for tokens, generate-and-check for HTML:** tokens remain canonical
  in `tokens.json`; `index.html` is generated from canonical sources and guarded by a drift
  check.
- **Scripts-first CI:** repo-local shell + Python checks are preferred; no external build
  system for brand artifacts.
- **Scoped colors:** variant color tokens live under package/page wrappers, never globally.
- **No binary brand-book artifact:** the new deliverable is reviewable source-controlled
  HTML, not PDF/Figma/binary exports.
- **Accessible SVG policy:** committed brand SVGs are text-diffable, optimized, accessible,
  and free of embedded raster/script content.

### Integration Points
- New files: `brandbook/index.html`, `scripts/gen_brandbook_html.py`, and a generated-HTML
  drift check such as `scripts/check_brandbook_html.py`.
- Existing files to extend: `scripts/ci/lint.sh` for the new check; `brandbook/BUDGET.md`
  for the HTML budget; `.planning/PROJECT.md` and `.planning/STATE.md` only after Phase
  101 verification proves v1.14 is shipped.
- Existing verification to keep green: `python3 scripts/check_synced_pair.py`,
  `python3 scripts/check_brand_tokens.py`, `python3 scripts/check_tokens_css.py`, SVG
  size-budget loop, and the new generated-HTML drift check.
</code_context>

<specifics>
## Specific Ideas

- The generated page should expose source references visibly in the Assets and maintenance
  section so reviewers can trace every rendered brand-book surface back to repo files.
- Keep the section navigation dense and practical: this is a brand-system browser, not a
  landing page.
- Treat Signal Gold as decorative-only and preserve the Phase 95 light/dark contrast rules
  in generated color examples.
- Inline SVG previews are acceptable because current logo/specimen files are small; the
  HTML budget check is the guardrail if this ever grows.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 101 capstone scope.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

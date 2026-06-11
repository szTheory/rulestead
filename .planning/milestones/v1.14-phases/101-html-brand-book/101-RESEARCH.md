# Phase 101 Research: HTML Brand Book

**Status:** Ready to plan
**Reader:** Phase 101 planner/executor lead
**Post-read action:** Write a Phase 101 plan with concrete source inputs, task boundaries,
drift gates, browser/static verification, and milestone-close checks.

## Planning Answer

Phase 101 is a documentation/static-artifact phase, not a product runtime phase. The plan
should build a deterministic stdlib Python generator for `brandbook/index.html`, render a
usable light/dark brand book from existing canonical files, add a generated-HTML drift and
size-budget check, wire that check into the existing scripts-first lint lane, and only then
mark v1.14 shipped in planning state.

The important implementation constraint is source truth. `index.html` must be a generated
review artifact. Brand copy comes from existing markdown, palette values come from
`tokens.json`, final visual assets come from committed SVG files, and source references
remain visible in the generated page. Do not create a parallel hand-maintained palette,
voice, logo, or typography source inside the HTML.

## Phase Boundary

- In scope: `brandbook/index.html`, `scripts/gen_brandbook_html.py`,
  `scripts/check_brandbook_html.py` or equivalent, `scripts/ci/lint.sh` wiring,
  `brandbook/BUDGET.md` HTML budget update, and planning closeout updates.
- Out of scope: React/Vite/Next/shadcn, Style Dictionary, PDF/Figma, hosted widgets,
  analytics, runtime APIs, schema changes, release/publish preparation, and any
  `rulestead_admin` publication work.
- Current repo state already has Phase 100 worktree changes. Plan with those current
  files, but do not revert unrelated user/generated changes.

## Existing Inputs

### Brandbook files

- `brandbook/brand-book.md` is the canonical 27-section brand book. Relevant headings are
  stable and numbered: essence (`## 3`), narrative (`## 4`), audience (`## 5`),
  messaging (`## 7`), tagline (`## 8`), voice (`## 9`), color (`## 12`), typography
  (`## 13`), logo (`## 14`), layout (`## 15`), iconography (`## 16`), imagery
  (`## 17`), motion (`## 18`), UI writing (`## 19`), defaults (`## 25`), summary
  (`## 26`), and mantra (`## 27`).
- `brandbook/VOICE.md` contains 11 say-this/not-this examples plus writing rules.
- `brandbook/COPY.md` contains ready-to-paste GitHub, Hex, README, landing, feature, and
  szTheory copy.
- `brandbook/BUDGET.md` currently documents SVG budgets only: logo SVG <= 20480 bytes and
  specimen SVG <= 51200 bytes.
- `brandbook/README.md` is the directory index and currently says Phase 101 will add the
  generated HTML brand book.
- `brandbook/docs/brand-usage.md` documents token sync, synced-pair rules, and
  verification commands.

### Token format

- `brandbook/tokens.json` is DTCG-shaped with top-level metadata plus `primitive`,
  `light`, `dark`, `invariant`, and `admin_css_mapping`.
- `admin_css_mapping.light` has 37 hex-literal `--rs-*` tokens. `admin_css_mapping.dark`
  has 31. Existing check scripts skip metadata keys beginning with `$`.
- `invariant` contains spacing, radius, shadow, focus-ring, code-block, and callout
  groups. It does not currently contain the full typography scale or motion durations.
- `brandbook/tokens.css` is the hand-authored reference mirror. It contains the practical
  `--rs-font-*`, `--rs-text-*`, `--rs-leading-*`, `--rs-weight-*`, `--rs-motion-*`, and
  `--rs-ease-*` variables that the UI spec references.

Planning implication: color can be sourced entirely from `tokens.json`; exact typography
and motion token values currently require either parsing `tokens.css`, extending
`tokens.json`, or consciously using the UI contract values in generator CSS. To avoid a
silent second source of truth, the plan should make this choice explicit. The smallest
coherent option is to let the generator consume `tokens.css` for invariant display CSS
while continuing to treat `tokens.json` as the canonical color/token data source.

### Asset layout

Final logo assets are in `brandbook/assets/logo/`:

- `rs-wordmark.svg`
- `rs-wordmark-dark.svg`
- `rs-mark.svg`
- `rs-mark-dark.svg`
- `rs-mark-mono.svg`
- `rs-favicon.svg`
- `rs-social-card.svg`

Historical concept SVGs are under `brandbook/assets/logo/concepts/` and should not be
primary logo-system output unless explicitly labeled as concepts.

Specimens are in `brandbook/assets/specimens/`:

- `palette.svg`
- `typography.svg`
- `components.svg`
- `code-block.svg`
- `readme-header.svg`
- `social-card.svg`

Current final logo/specimen SVG total is about 40 KB. Inline embedding is feasible, but
the generated HTML still needs its own budget.

## Source Map for the Page

Use the approved section order from `101-UI-SPEC.md`.

| Generated section | Primary source inputs | Notes |
|---|---|---|
| Overview | `brand-book.md` sections 3, 4, 5, 26, 27; logo wordmark | Must show mark/wordmark, tagline `Runtime decisions, made clear.`, brand essence, north-star message, audience, and mantra in first viewport/navigation. |
| Voice and messaging | `brand-book.md` sections 7, 8, 9, 19; `VOICE.md`; `COPY.md` | Prefer direct extraction. `VOICE.md` and `COPY.md` are canonical Phase 100 outputs, not new copy. |
| Color | `tokens.json` primitive/admin mappings; `brand-book.md` section 12; `palette.svg` | Palette tables must be generated from token JSON, not hand-maintained. Include Signal Gold decorative-only policy and light/dark semantic values. |
| Typography | `brand-book.md` section 13; `typography.svg`; optionally `tokens.css` for exact variables | Planning gap: full text/motion CSS vars live in `tokens.css`, not JSON. |
| Logo | final `assets/logo/*.svg`; `brand-book.md` section 14 | Inline final logo SVGs, show visible source-file refs, and keep concepts separate/labeled if shown at all. |
| Layout and components | `brand-book.md` section 15; `tokens.json` invariants; `components.svg`; `code-block.svg` | Demonstrate grid, spacing, radius, panel, button, badge, code, and callout examples. |
| Iconography and imagery | `brand-book.md` sections 16 and 17; specimens | Covers allowed themes and forbidden motifs. No new custom icon library. |
| Motion | `brand-book.md` section 18; `tokens.css` motion vars or UI contract values | Respect `prefers-reduced-motion`; use only approved timing/easing values. |
| Assets and maintenance | `README.md`, `BUDGET.md`, `docs/brand-usage.md`, scripts, CI checks | Show source references, generator command, drift command, budget policy, and lint integration. |

## Generator Architecture

Recommended shape:

- `scripts/gen_brandbook_html.py` runs from repo root and writes
  `brandbook/index.html`.
- Expose a pure `render_brandbook(repo_root: Path) -> str` function so the drift check can
  import it instead of duplicating rendering logic.
- Use only stdlib modules: `json`, `html`, `pathlib`, `re`, `textwrap`, `xml.etree` or
  similarly small helpers, and optionally `argparse`.
- Keep output deterministic: sorted asset paths, no timestamps, no absolute paths, stable
  newline at EOF, stable class names, and stable section IDs.
- Fail fast with short actionable errors when a required source file, heading, token group,
  or final SVG is missing. The generator should not modify source files other than
  `brandbook/index.html`.
- Prefer heading-keyed markdown extraction over broad markdown rendering. The source
  headings are stable enough to extract exact sections. A limited renderer only needs to
  support headings, paragraphs, lists, blockquotes, code spans/fences, simple markdown
  tables from `VOICE.md`/`COPY.md`, horizontal rules, and inline emphasis. Escape all text
  with `html.escape`.

Avoiding second source of truth:

- The generator may have an output-section map, but not duplicated brand copy or token
  values.
- Palette swatches and token labels should be built from `tokens.json` data.
- Asset cards should be built from file discovery plus a required final-asset manifest.
  The manifest names the expected source files; the SVG bodies come from disk.
- UI examples can use generated CSS classes, but any brand value displayed to humans
  should come from source files or generated token data.

## SVG and Browser Risks

Inline SVGs keep `index.html` usable from `file://` and avoid broken image previews. They
also create two plan-level risks:

- Several SVGs use generic IDs such as `t` and `d` for `<title>`/`<desc>`. Inlining
  multiple SVGs into one document will duplicate IDs and can break `aria-labelledby`.
  The generator should prefix SVG IDs and corresponding ID references per asset, for
  example with the stem `rs-wordmark__t`. Use a structured XML parser if practical.
- Final logo SVG roots have `aria-labelledby`, `title`, and `desc`, but not all have
  `role="img"` on the root. The generated copy should ensure non-decorative inline SVGs
  expose an accessible name, either by adding `role="img"` to the embedded SVG root or by
  wrapping the figure with an equivalent accessible label.

Other static/browser risks:

- Do not rely on external images, external JavaScript, or relative `img src` paths for the
  required previews. Source-file links are fine, but preview rendering should be inline.
- Google Fonts CDN links are allowed by the UI spec, but the page must remain usable with
  system fallbacks and no committed font binaries.
- Theme CSS must be scoped to `[data-rulestead-brandbook]`. Do not put color tokens on
  `:root`, `html`, or `body`.
- System theme should be implemented with wrapper-scoped CSS and
  `@media (prefers-color-scheme: dark)` for the no-JS path. Explicit Light/Dark can set
  `data-theme` on the wrapper.
- If persistence is used, use a new key such as `rulestead.brandbook.theme`, validate it
  against `system|light|dark`, and never reuse `rulestead_admin.theme`.
- With JavaScript disabled, all content and source references must remain visible. The
  theme control may be inert, but the page should still follow system light/dark through
  CSS.

## Drift Check and CI

Recommended new checker: `scripts/check_brandbook_html.py`.

Responsibilities:

- Import the generator render function or run generation into memory/temp output.
- Byte-compare rendered HTML against `brandbook/index.html`.
- Exit 1 on missing file, drift, source extraction failure, or size-budget failure.
- Print a concise unified diff with `difflib.unified_diff` on drift.
- Enforce an explicit `brandbook/index.html` budget. Recommended ceiling: 262144 bytes
  (256 KiB). That is generous relative to the current 40 KB SVG corpus while still
  preventing accidental bloat.
- Optionally perform static assertions in the same checker: required section IDs,
  required source references, no unresolved local `src`/`href`, no inline SVG duplicate
  IDs, no `<script src=...>`, no `base64`, no `<image>` in embedded brand SVGs.

Exact CI integration point:

- Add `python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"` to
  `scripts/ci/lint.sh` after `check_tokens_css.py` and before the existing SVG budget
  loop.
- `.github/workflows/ci.yml` already runs `scripts/ci/lint.sh` in the lint lane, so a
  workflow edit is not required for CI enforcement.
- Update `brandbook/BUDGET.md` in the same phase to document the generated HTML budget and
  checker.

Keep existing checks green:

```bash
python3 scripts/check_synced_pair.py
python3 scripts/check_brand_tokens.py
python3 scripts/check_tokens_css.py
python3 scripts/check_brandbook_html.py
bash scripts/ci/lint.sh
```

## Browser and Static Verification

The repo has an existing Playwright dependency under `examples/demo/frontend` and current
`file://` fixture tests for admin theme/design-system behavior. Phase 101 can reuse that
stack for executor verification if the plan wants true browser evidence without adding a
new frontend build stack.

Recommended browser checks:

- Load `file://<repo>/brandbook/index.html` in Chromium at desktop and mobile widths.
- Verify `[data-rulestead-brandbook]`, `header`, `nav`, `main`, all nine required section
  IDs, and final logo/specimen figures are visible.
- Verify Light, Dark, and System controls update `data-theme` and `aria-checked`; System
  removes explicit `data-theme`.
- Verify a dark color-scheme context renders the page without pinned theme.
- Verify no local image/style/script request fails. If previews are inline, there should be
  no required local asset fetches for previews.
- Verify a JavaScript-disabled context still shows the content, nav, and inline SVGs.
- Verify focus reaches nav links and theme controls.

If the plan adds a Playwright spec, keep it as verification support, not as the generator's
implementation dependency. Do not wire Node/Playwright into `scripts/ci/lint.sh` unless the
phase explicitly accepts the CI cost.

Static checks that do not require a browser:

- Parse generated HTML and assert required fragments:
  `overview`, `voice-and-messaging`, `color`, `typography`, `logo`,
  `layout-and-components`, `iconography-and-imagery`, `motion`, and
  `assets-and-maintenance`.
- Assert the generated page includes the final logo filenames and specimen filenames as
  visible source references.
- Assert no final logo/specimen SVG contains `base64`, `<image`, `<script`, or
  `<foreignObject>`.
- Assert inline SVG IDs are unique after embedding.
- Assert local links point to existing repo files when resolved from `brandbook/`.

## Task Boundaries for Planning

Recommended slices:

1. Source contract and generator core: required-file manifest, markdown section extraction,
   token loading, SVG loading/sanitizing/prefixing, and deterministic render function.
2. Generated page rendering: semantic HTML, scoped CSS, required sections, inline assets,
   theme control, reduced-motion behavior, no-JS baseline, and source references.
3. Drift and budget guard: `check_brandbook_html.py`, HTML budget in `BUDGET.md`, and
   `scripts/ci/lint.sh` wiring.
4. Browser/static verification: narrow static assertions plus optional Playwright
   `file://` checks for light/dark/system and JS-disabled behavior.
5. Milestone closeout: update `brandbook/README.md` if needed, mark BOOK-01/BOOK-02 and
   Phase 101 complete, and update `.planning/PROJECT.md` plus `.planning/STATE.md` to
   v1.14 shipped after verification passes.

## Plan-Relevant Files

New files:

- `brandbook/index.html`
- `scripts/gen_brandbook_html.py`
- `scripts/check_brandbook_html.py`
- Optional browser spec under `examples/demo/frontend/tests/` if planned

Existing files likely touched:

- `scripts/ci/lint.sh`
- `brandbook/BUDGET.md`
- `brandbook/README.md` if the directory index should link `index.html`
- `.planning/REQUIREMENTS.md` to check BOOK-01 and BOOK-02
- `.planning/ROADMAP.md` to mark Phase 101 complete and v1.14 shipped
- `.planning/PROJECT.md` and `.planning/STATE.md` for milestone closeout

Read-only source inputs:

- `brandbook/brand-book.md`
- `brandbook/tokens.json`
- `brandbook/tokens.css` if used for invariant typography/motion values
- `brandbook/VOICE.md`
- `brandbook/COPY.md`
- `brandbook/docs/brand-usage.md`
- `brandbook/assets/logo/*.svg`
- `brandbook/assets/specimens/*.svg`

Reference-only files:

- `scripts/check_brand_tokens.py`
- `scripts/check_tokens_css.py`
- `scripts/check_synced_pair.py`
- `rulestead_admin/lib/rulestead_admin/components/shell.ex`
- `rulestead_admin/priv/static/css/rulestead_admin.css`
- `examples/demo/frontend/tests/theme-control.spec.ts`
- `examples/demo/frontend/tests/design-system.spec.ts`

## Schema, Database, and Publishing Risk

No schema, database, migration, runtime API, package-version, or publish pipeline changes
are needed. The phase should not touch release preparation or `rulestead_admin` publishing
posture. The only CI/publishing-adjacent risk is accidental lint-lane cost if browser tests
are wired into `scripts/ci/lint.sh`; keep browser verification separate unless explicitly
planned.

## Nyquist Validation Architecture

Source assertions:

- Required markdown headings exist before generation.
- Required final logo and specimen files exist; concept assets are excluded or labeled.
- `tokens.json` has `primitive`, `light`, `dark`, and `admin_css_mapping` groups.
- If `tokens.css` is consumed, required font/text/motion variables are present.
- Embedded SVG copies have unique IDs and accessible names.

Generation/drift commands:

```bash
python3 scripts/gen_brandbook_html.py
python3 scripts/check_brandbook_html.py
```

Guard commands:

```bash
python3 scripts/check_synced_pair.py
python3 scripts/check_brand_tokens.py
python3 scripts/check_tokens_css.py
bash scripts/ci/lint.sh
```

Browser/static checks:

- Browser-open `brandbook/index.html` from `file://` in light and dark contexts.
- Verify all required sections and inline assets in desktop/mobile widths.
- Verify theme control behavior with JavaScript enabled and content visibility with
  JavaScript disabled.
- Run static HTML/SVG assertions as part of the drift checker or a narrow verification
  helper.

Milestone closeout checks:

- `BOOK-01` and `BOOK-02` are marked complete.
- Phase 101 is marked complete in `ROADMAP.md`.
- `.planning/PROJECT.md` and `.planning/STATE.md` say v1.14 shipped only after generator,
  drift check, size budget, lint, and browser/static verification pass.
- No Phase 8-only docs are introduced and no `rulestead_admin` publication preparation is
  added.

# Phase 101: HTML Brand Book - Pattern Map

**Mapped:** 2026-06-06
**Phase boundary:** Phase 101 only
**Files analyzed:** CONTEXT, UI-SPEC, RESEARCH, ROADMAP, REQUIREMENTS, AGENTS, guard scripts, admin shell/CSS, static fixtures, brandbook docs/assets, Playwright fixture specs
**Analogs found:** 9 / 10 file targets have useful local analogs

## File Classification

| File | Role | Data flow | Closest existing analog | Match quality |
|---|---|---|---|---|
| `brandbook/index.html` | generated static review artifact | batch render from canonical sources | `rulestead_admin/priv/static/design-system.html`; admin shell/CSS theme structure | strong role-match |
| `scripts/gen_brandbook_html.py` | stdlib generator | read markdown/json/css/svg -> write HTML | `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/gen_wordmark_paths.py` for committed generator posture | partial |
| `scripts/check_brandbook_html.py` | drift + budget guard | render in memory -> byte-compare -> exit code | `scripts/check_brand_tokens.py`; `scripts/check_tokens_css.py`; `scripts/check_synced_pair.py` | exact guard style |
| `scripts/ci/lint.sh` | CI wiring | batch gate runner | existing `scripts/ci/lint.sh` guard block | exact |
| `brandbook/BUDGET.md` | policy doc | budget source read by humans/checker | current `brandbook/BUDGET.md` SVG budget table | exact |
| `brandbook/README.md` | directory index | human navigation | current `brandbook/README.md` table + command block | exact |
| `examples/demo/frontend/tests/brandbook.spec.ts` (optional) | browser verification support | file:// Playwright checks | `theme-control.spec.ts`, `theme-cascade.spec.ts`, `design-system.spec.ts` | strong optional analog |
| `.planning/ROADMAP.md` | phase closeout state | status update after verification | Phase 100 closeout pattern in roadmap | exact closeout analog |
| `.planning/REQUIREMENTS.md` | requirement traceability | BOOK-01/BOOK-02 status after verification | Phase 100 requirement closeout pattern | exact closeout analog |
| `.planning/PROJECT.md`, `.planning/STATE.md` | milestone closeout state | mark v1.14 shipped after verification only | current shipped-milestone sections + Phase 100 plan note | exact closeout analog |

Read-only inputs for Phase 101:

| Source | Use | Modification posture |
|---|---|---|
| `brandbook/brand-book.md` | canonical section text keyed by stable numbered headings | read only |
| `brandbook/tokens.json` | canonical color/token values and admin mappings | read only |
| `brandbook/tokens.css` | practical typography/motion/invariant CSS variables | read only unless a later plan explicitly chooses token JSON expansion |
| `brandbook/VOICE.md`, `brandbook/COPY.md` | canonical voice/copy extracts | read only |
| `brandbook/assets/logo/*.svg` | final logo previews and source refs | read only |
| `brandbook/assets/specimens/*.svg` | final specimen previews and source refs | read only |
| `rulestead_admin/lib/rulestead_admin/components/shell.ex` | tri-state theme behavior analog | read only |
| `rulestead_admin/priv/static/css/rulestead_admin.css` | scoped token/theme/focus analog | read only |
| `rulestead_admin/priv/static/design-system.html` | static fixture/layout analog | read only |

Do not edit implementation files outside the listed targets. Do not prepare or publish `rulestead_admin`.

## Shared Implementation Patterns

### Repo-root script posture

Existing Python checks use short constants, stdlib only, repo-root relative paths, clear success strings, and `sys.exit(main())`.

```python
#!/usr/bin/env python3
"""Token-drift check: brandbook/tokens.json admin_css_mapping vs rulestead_admin.css Blocks 1 + 3."""
import sys
import re
import json

TOKENS_JSON = "brandbook/tokens.json"
CSS = "rulestead_admin/priv/static/css/rulestead_admin.css"

if __name__ == "__main__":
    sys.exit(main())
```

Reuse this guard style for both new scripts, but prefer `pathlib.Path` where it reduces path ambiguity:

```python
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "brandbook" / "index.html"
```

### Drift-check style

The current checks collect all mismatches, print a clear header, then return `1`. They sort token iteration to keep output stable.

```python
for name, expected in sorted(mapping.items()):
    if not name.startswith("--rs-"):
        continue
    css_val = css_decls.get(name)
    if css_val is None:
        mismatches.append(f"  {name}: tokens.json={expected}  css=<missing>")
    elif css_val.lower() != expected.lower():
        mismatches.append(f"  {name}: tokens.json={expected}  css={css_val}")

if not mismatches:
    print(f"BRAND TOKENS SYNCED ({matched} tokens)")
    return 0

print("BRAND TOKEN DRIFT DETECTED")
for m in mismatches:
    print(m)
return 1
```

For HTML drift, use the same contract but compare bytes/text against `render_brandbook(repo_root)` and print a concise unified diff:

```python
diff = difflib.unified_diff(
    actual.splitlines(),
    expected.splitlines(),
    fromfile="brandbook/index.html",
    tofile="generated",
    lineterm="",
)
print("BRANDBOOK HTML DRIFT DETECTED")
print("\n".join(diff))
return 1
```

### CSS token scope

Admin CSS is the precedent for color token scoping:

```css
.rs-shell,
[data-rulestead] {
  color-scheme: light;
  --rs-bg: var(--rs-neutral-50);
  --rs-surface: var(--rs-neutral-0);
  --rs-text: var(--rs-neutral-900);
  --rs-primary: #3A6F8F;
}

@media (prefers-color-scheme: dark) {
  .rs-shell:not([data-theme]),
  [data-rulestead]:not([data-theme]) {
    color-scheme: dark;
    --rs-neutral-0: #10161f;
    --rs-primary: #5885a0;
  }
}

.rs-shell[data-theme="dark"],
[data-rulestead][data-theme="dark"] {
  color-scheme: dark;
  --rs-neutral-0: #10161f;
  --rs-primary: #5885a0;
}
```

For Phase 101, adapt this to `[data-rulestead-brandbook]`. Do not declare generated page color tokens on `:root`, `html`, or `body`.

### Theme control posture

Admin shell radiogroup pattern:

```html
<div
  id="rs-theme-control"
  role="radiogroup"
  aria-labelledby="rs-theme-label"
  data-theme-default="system"
  class="rs-theme-control__group"
>
  <button type="button" role="radio" aria-checked="true" tabindex="0" data-value="system">System</button>
  <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="light">Light</button>
  <button type="button" role="radio" aria-checked="false" tabindex="-1" data-value="dark">Dark</button>
</div>
```

Admin JS behavior to reuse, adapted to static HTML:

```js
const VALID = ["system", "light", "dark"];
const readTheme = () => {
  try {
    const v = localStorage.getItem("rulestead.brandbook.theme");
    return VALID.includes(v) ? v : "system";
  } catch (_) {
    return "system";
  }
};

const applyTheme = (val) => {
  wrapper.setAttribute("data-theme-switching", "");
  if (val === "dark") wrapper.setAttribute("data-theme", "dark");
  else if (val === "light") wrapper.setAttribute("data-theme", "light");
  else wrapper.removeAttribute("data-theme");
  requestAnimationFrame(() => wrapper.removeAttribute("data-theme-switching"));
};
```

Important adaptations:

- Use `rulestead.brandbook.theme`, never `rulestead_admin.theme`.
- Set/remove `data-theme` on `[data-rulestead-brandbook]`, not `.rs-shell`.
- System mode removes `data-theme`; CSS `@media (prefers-color-scheme: dark)` handles no-JS/system dark.
- Keep all content visible and usable when JavaScript is disabled.

### Theme-control styling and focus

Existing CSS pattern:

```css
.rs-theme-control__opt {
  min-height: var(--rs-control-h-sm);
  border: 1px solid var(--rs-border);
  border-radius: var(--rs-radius-full);
  background: var(--rs-surface);
  color: var(--rs-text-muted);
  font-size: 0.8rem;
  font-weight: var(--rs-weight-semibold);
}

.rs-theme-control__opt[aria-checked="true"] {
  border-color: var(--rs-primary);
  background: var(--rs-primary-soft);
  color: var(--rs-primary-hover);
}

.rs-theme-control__opt:focus-visible {
  outline: none;
  border-radius: var(--rs-radius-sm);
  box-shadow: var(--rs-focus-ring);
}
```

Use the same active/focus posture in generated CSS. Keep generated text weights to `400` and `600` per UI-SPEC; do not copy admin weights `500` or `700` into page text.

### Static fixture shape

`design-system.html` is the closest static HTML analog:

```html
<div class="rs-shell" id="shell">
  <header class="rs-shell__header">...</header>
  <div class="rs-shell__layout">
    <nav class="rs-shell__rail">
      <a href="#section-surface" class="rs-shell__rail-link" aria-current="page">Surfaces</a>
    </nav>
    <main class="rs-shell__main">
      <section id="section-surface" class="ds-section">
        <h2 class="ds-section-heading">Surface Elevation Ladder</h2>
      </section>
    </main>
  </div>
</div>
```

For Phase 101, generate semantic landmarks directly (`header`, `nav`, `main`, `section`, `footer`) and stable IDs:

```text
overview
voice-and-messaging
color
typography
logo
layout-and-components
iconography-and-imagery
motion
assets-and-maintenance
```

### Inline SVG accessibility

Existing logo/specimen SVGs use accessible root metadata:

```xml
<svg role="img" xmlns="http://www.w3.org/2000/svg" aria-labelledby="t d" viewBox="0 0 860 520">
  <title id="t">Rulestead - Palette Specimen</title>
  <desc id="d">Brand color palette swatches with hex values and token names.</desc>
  <g aria-hidden="true">...</g>
</svg>
```

When embedding multiple SVGs into `index.html`, prefix IDs per asset stem to avoid duplicate `t` / `d` IDs:

```text
rs-wordmark.svg: t -> rs-wordmark__t, d -> rs-wordmark__d
palette.svg: t -> palette__t, d -> palette__d
```

Update every ID reference in the embedded SVG body, especially `aria-labelledby`, `href`, `xlink:href`, `clip-path`, `filter`, `mask`, `fill`, and `stroke` URL references. Use `xml.etree.ElementTree` or a tightly scoped helper; do not broad-replace arbitrary HTML.

Also assert embedded final SVGs contain no `base64`, `<image`, `<script`, or `<foreignObject>`.

### Markdown extraction

There is no existing markdown renderer to reuse. The approved local pattern is deterministic, limited parsing, keyed to stable headings.

Required heading keys from `brandbook/brand-book.md`:

```text
## 3. Brand essence
## 4. Product narrative
## 5. Audience
## 7. Messaging architecture
## 8. Tagline directions
## 9. Verbal identity
## 12. Color system
## 13. Typography
## 14. Logo direction
## 15. Layout system
## 16. Iconography
## 17. Imagery
## 18. Motion
## 19. UI writing standards
## 25. Practical implementation defaults
## 26. Internal summary for future LLM or design context
## 27. Final brand mantra
```

Pattern:

```python
SECTION_RE = re.compile(r"^##\s+(?P<num>\d+)\.\s+(?P<title>.+?)\s*$", re.M)

def extract_numbered_section(markdown: str, number: str) -> str:
    matches = list(SECTION_RE.finditer(markdown))
    for index, match in enumerate(matches):
        if match.group("num") == number:
            start = match.end()
            end = matches[index + 1].start() if index + 1 < len(matches) else len(markdown)
            return markdown[start:end].strip()
    raise SystemExit(f"ERROR: required brand-book section {number} not found")
```

Only render the markdown constructs Phase 101 needs: headings, paragraphs, unordered/ordered lists, blockquotes, fenced code, inline code, emphasis, links, and simple tables from `VOICE.md` / `COPY.md`. Escape text with `html.escape`.

## File-Specific Patterns

### `brandbook/index.html`

Generate, do not hand-maintain. The generated page should be self-contained enough to open via `file://`: inline CSS, inline final SVG previews, optional inline JS. Google Fonts links are allowed by UI-SPEC, but system fallbacks must preserve usability.

Core wrapper:

```html
<body>
  <div data-rulestead-brandbook data-theme-pending>
    <header>...</header>
    <nav aria-label="Brand book sections">...</nav>
    <main>
      <section id="overview" aria-labelledby="overview-title">...</section>
      ...
    </main>
    <footer>...</footer>
  </div>
</body>
```

Token CSS should be emitted from `tokens.json` / `tokens.css`, not copied by hand. Use generated custom properties only under the wrapper:

```css
[data-rulestead-brandbook] {
  color-scheme: light;
  --rs-bg: #f4f6f8;
  --rs-surface: #ffffff;
  --rs-text: #1a2332;
  --rs-primary: #3A6F8F;
}

@media (prefers-color-scheme: dark) {
  [data-rulestead-brandbook]:not([data-theme]) {
    color-scheme: dark;
    --rs-bg: #19222e;
    --rs-surface: #141c27;
    --rs-text: #e8edf3;
    --rs-primary: #5885a0;
  }
}
```

Content sections must follow UI-SPEC order. Source refs should be visible, e.g.:

```html
<a class="source-link" href="brand-book.md">brandbook/brand-book.md</a>
<a class="source-link" href="tokens.json">brandbook/tokens.json</a>
<a class="source-link" href="assets/logo/rs-wordmark.svg">brandbook/assets/logo/rs-wordmark.svg</a>
```

Use stable dimensions for previews:

```css
.asset-preview {
  aspect-ratio: 16 / 9;
  display: grid;
  place-items: center;
  overflow: hidden;
}

.asset-preview svg {
  max-width: min(100%, 720px);
  max-height: 100%;
  height: auto;
}
```

### `scripts/gen_brandbook_html.py`

Expose a pure render function for the checker:

```python
def render_brandbook(repo_root: Path) -> str:
    sources = load_sources(repo_root)
    html_text = render_page(sources)
    return html_text.rstrip() + "\n"
```

Write only `brandbook/index.html` from `main()`:

```python
def main() -> int:
    output = render_brandbook(REPO_ROOT)
    OUTPUT.write_text(output, encoding="utf-8")
    print(f"WROTE {OUTPUT.relative_to(REPO_ROOT)} ({len(output.encode('utf-8'))} bytes)")
    return 0
```

Recommended source manifest:

```python
REQUIRED_FILES = [
    "brandbook/brand-book.md",
    "brandbook/tokens.json",
    "brandbook/tokens.css",
    "brandbook/VOICE.md",
    "brandbook/COPY.md",
    "brandbook/BUDGET.md",
    "brandbook/README.md",
    "brandbook/docs/brand-usage.md",
]

FINAL_LOGOS = [
    "rs-wordmark.svg",
    "rs-wordmark-dark.svg",
    "rs-mark.svg",
    "rs-mark-dark.svg",
    "rs-mark-mono.svg",
    "rs-favicon.svg",
    "rs-social-card.svg",
]

SPECIMENS = [
    "palette.svg",
    "typography.svg",
    "components.svg",
    "code-block.svg",
    "readme-header.svg",
    "social-card.svg",
]
```

Fail fast on missing source files/assets with actionable messages and without modifying sources.

### `scripts/check_brandbook_html.py`

Mirror existing guard scripts:

```python
#!/usr/bin/env python3
"""Generated HTML drift and budget check for brandbook/index.html.

Usage (from repo root):
    python3 scripts/check_brandbook_html.py
Exits 0 on success; exits 1 on drift, missing output, render failure, or budget failure.
"""
import difflib
import sys
from pathlib import Path

from gen_brandbook_html import render_brandbook

REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT = REPO_ROOT / "brandbook" / "index.html"
HTML_BUDGET_BYTES = 262144
```

Budget check pattern:

```python
size = len(actual.encode("utf-8"))
if size > HTML_BUDGET_BYTES:
    print(
        f"BRANDBOOK HTML BUDGET EXCEEDED: brandbook/index.html is {size} bytes "
        f"(limit: {HTML_BUDGET_BYTES})"
    )
    return 1
```

Static assertions worth folding into this checker:

- Required section IDs exist.
- Final logo and specimen filenames appear as visible source refs.
- No `<script src=`, `<img src=`, `base64`, `<image`, `<foreignObject>`, or duplicate inline SVG IDs.
- Local `href` references resolve from `brandbook/` to existing repo files, except fragment-only links.
- HTML ends with one newline.

Expected success string:

```text
BRANDBOOK HTML SYNCED (N bytes)
```

### `scripts/ci/lint.sh`

Current guard sequence after returning to repo root:

```bash
python3 "${RULESTEAD_REPO}/scripts/check_synced_pair.py"
python3 "${RULESTEAD_REPO}/scripts/check_brand_tokens.py"
python3 "${RULESTEAD_REPO}/scripts/check_tokens_css.py"
```

Add the new check immediately after `check_tokens_css.py` and before the SVG loop:

```bash
# Generated HTML brand book drift and size budget.
python3 "${RULESTEAD_REPO}/scripts/check_brandbook_html.py"
```

Do not add Node/Playwright to `lint.sh` for this phase unless a later approved plan explicitly accepts that CI cost.

### `brandbook/BUDGET.md`

Add a row to the existing table; do not relax SVG budgets:

```markdown
| Generated HTML brand book | `brandbook/index.html` | 256 KB / 262144 bytes | `scripts/check_brandbook_html.py` |
```

Add policy bullets:

- `brandbook/index.html` is generated and reviewable source, not a hand-authored second source of truth.
- Inline committed SVG previews are allowed, guarded by the HTML budget.
- If the HTML exceeds budget, simplify page markup/previews or reduce embedded preview scope; do not raise SVG budgets to compensate.

### `brandbook/README.md`

Add `index.html` to the directory index once generated:

```markdown
| [`index.html`](index.html) | Generated, source-controlled HTML brand book for browser review. Regenerate with `scripts/gen_brandbook_html.py`; guarded by `scripts/check_brandbook_html.py`. | Active |
```

Extend maintenance commands:

```bash
python3 scripts/gen_brandbook_html.py
python3 scripts/check_brandbook_html.py
```

Update the current "Phase 101 will add..." paragraph to say `index.html` is generated from canonical sources and should not be edited by hand.

### Optional `examples/demo/frontend/tests/brandbook.spec.ts`

If the plan wants browser evidence, follow the existing file-based Playwright pattern:

```ts
import { expect, test } from "@playwright/test";
import path from "path";

const brandbookUrl =
  "file://" +
  path.resolve(__dirname, "../../../../brandbook/index.html");

test("brandbook loads required sections", async ({ page }) => {
  await page.goto(brandbookUrl);
  await expect(page.locator("[data-rulestead-brandbook]")).toBeVisible();
  await expect(page.locator("header")).toBeVisible();
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator("main")).toBeVisible();
  await expect(page.locator("#overview")).toBeVisible();
  await expect(page.locator("#assets-and-maintenance")).toBeVisible();
});
```

Theme-control assertions can adapt the existing fixture tests:

```ts
await page.locator("[data-value='dark']").click();
await expect(page.locator("[data-rulestead-brandbook]")).toHaveAttribute("data-theme", "dark");
await page.locator("[data-value='system']").click();
await expect(page.locator("[data-rulestead-brandbook]")).not.toHaveAttribute("data-theme", /.+/);
```

Also verify a JavaScript-disabled context:

```ts
const context = await browser.newContext({ javaScriptEnabled: false, colorScheme: "dark" });
const page = await context.newPage();
await page.goto(brandbookUrl);
await expect(page.locator("#color")).toBeVisible();
await expect(page.locator("svg").first()).toBeVisible();
```

Keep this as verification support. Do not make it a generator dependency.

### Planning closeout files

Only after generated HTML, generator, checker, CI wiring, budget/docs, and verification pass:

- `.planning/ROADMAP.md`: mark Phase 101 complete and v1.14 shipped.
- `.planning/REQUIREMENTS.md`: mark BOOK-01 and BOOK-02 complete.
- `.planning/PROJECT.md`: move v1.14 from current milestone to shipped history, matching existing shipped milestone prose.
- `.planning/STATE.md`: set milestone state to shipped/complete, record Phase 101 completion, and remove "ready to plan" next action.

The Phase 100 closeout plan is the boundary analog:

```text
Mark COPY-01, COPY-02, REPO-01, and REPO-02 complete. Mark Phase 100 complete and
Phase 101 ready to plan. Do not mark v1.14 shipped.
```

Phase 101 is the inverse: do not mark v1.14 shipped until the brandbook HTML drift check and full lint gate have passed.

## Verification Commands

Expected narrow commands after implementation:

```bash
python3 scripts/gen_brandbook_html.py
python3 scripts/check_brandbook_html.py
python3 scripts/check_synced_pair.py
python3 scripts/check_brand_tokens.py
python3 scripts/check_tokens_css.py
bash scripts/ci/lint.sh
```

Optional browser evidence, if a spec is added:

```bash
cd examples/demo/frontend
npm run test:e2e -- brandbook.spec.ts
```

## Scope Guardrails

- No React, Vite, Next, shadcn, Style Dictionary, CSS preprocessor, analytics, hosted widget, external JS, or registry import.
- No runtime APIs, schema changes, or release/publish preparation.
- No edits to `rulestead_admin` package metadata or publication posture.
- No Phase 8-only docs.
- No hand-maintained palette, voice, logo, or typography tables inside `index.html`; regenerate from canonical source files.
- Treat `brandbook/assets/logo/concepts/` as historical design-reference material only unless explicitly labeled as concepts.

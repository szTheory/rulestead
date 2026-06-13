# Phase 97: Logo & Mark SVG System — Research

**Researched:** 2026-06-05
**Domain:** SVG authoring, accessible logos, SVGO optimization, Phoenix static asset digesting, text-to-path conversion
**Confidence:** HIGH

---

## Summary

Phase 97 commits the full Rulestead logo system to `brandbook/assets/logo/` and wires it into both the admin package and the demo. The phase is a creative-then-technical sequence: three SVG mark concepts (A/B/C) are produced first; the maintainer selects one; then the full lockup set is authored and deployed. No design tools are assumed — all SVGs are hand-authored or script-generated, then SVGO-optimized with a custom config that preserves accessibility metadata.

The dominant technical challenge is **text-to-path conversion for the wordmark**. The project has no Figma, no Illustrator, no Inkscape. fontTools 4.62.1 is installed at a user site-packages path and its `SVGPathPen` + `TTFont` APIs work correctly, enabling a one-shot Python script to download the Sora Bold TTF from Google Fonts, extract glyph outlines for the word "Rulestead", and emit path data. This is the recommended toolchain for the wordmark.

The **Phoenix digest workflow** is fully understood: `mix phx.digest` (alias `mix assets.deploy`) in the demo backend rewrites `priv/static/images/logo.svg` to produce a fingerprinted copy and `.gz` sidecars and updates `cache_manifest.json`. The correct procedure for LOGO-05 is: replace `logo.svg`, run `mix phx.digest.clean --all` then `mix phx.digest`, and commit all generated files. The old fingerprinted file (`logo-06a11be1f2cdde2c851763d00bdd2e80.svg` + `.gz`) must be deleted before re-digesting.

The **admin embedding** for LOGO-04 is a simple file copy: create `rulestead_admin/priv/static/images/` and place `rs-mark.svg` + `rs-mark-dark.svg` there. The admin package does not run `phx.digest` on its own assets — the host app copies `priv/static/css/rulestead_admin.css` into its asset pipeline at build time; image files would follow the same manual-copy pattern documented in the README.

**The mid-phase human checkpoint (concept A/B/C selection) must be an autonomous:false plan task.** The plan waves must split: Wave 1 produces concepts; Wave 2 is gated by human selection; Waves 3–4 produce the full lockup set and wire it in.

**Primary recommendation:** Hand-author all three mark concepts as SVGs directly (no external tools), use a one-shot fontTools Python script to extract Sora Bold glyph paths for the wordmark, optimize with a custom `svgo.config.mjs` that disables `removeTitle` and `removeViewBox`, and run `mix phx.digest` to regenerate demo sidecars.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOGO-01 | Three SVG mark concepts (A structured path / B stead frame / C layered field) produced for maintainer selection | Brand book §14 defines all three directions; visual metaphor territory in §11 drives design vocabulary; hex fills from tokens.json primitives |
| LOGO-02 | Chosen mark ships a full lockup: primary (wordmark + icon), icon-only, monochrome (`fill="currentColor"`), and dark/light variants | Accessible SVG skeleton pattern; monochrome pattern; dark variant = light fills on dark background |
| LOGO-03 | `rs-favicon.svg` legible at 16px; 1200×630 social/OG card committed as SVG | Favicon design constraints (16px legibility budget, stroke weight floor); social card viewBox convention |
| LOGO-04 | All logo SVGs optimized (SVGO), accessible (title/desc), free of embedded raster, outlined text | SVGO config with disabled removeTitle/removeViewBox/removeDesc; accessible SVG skeleton; fontTools text-to-path script |
| LOGO-05 | Phoenix-flame demo logo replaced; fingerprinted copy + .gz sidecars regenerated; admin copies placed | `mix phx.digest` workflow; `mix phx.digest.clean --all`; rulestead_admin/priv/static/images/ dir creation |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mark concept SVGs (A/B/C) | `brandbook/assets/logo/` | — | Brand source of truth; consumed by all downstream phases |
| Full lockup set (wordmark, icon, mono, dark, favicon, social) | `brandbook/assets/logo/` | — | Single source; copied out to consumers |
| Admin mark embedding (rs-mark.svg, rs-mark-dark.svg) | `rulestead_admin/priv/static/images/` | — | Mounted package ships its own static assets per existing CSS pattern |
| Demo logo replacement | `examples/demo/backend/priv/static/images/` | — | Demo's `priv/static` is digested by `mix phx.digest` |
| SVGO optimization + config | `brandbook/assets/logo/` (via npx svgo) | — | Runs at authoring time, not at CI or runtime |
| Phoenix digest (fingerprint + .gz) | Demo build step (`mix phx.digest`) | — | Phoenix Plug.Static uses digested files in prod (gzip: true when code_reloading? = false) |

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| SVG (hand-authored) | SVG 1.1 / 2.0 elements | All logo files | No external tool dependency; reviewable diffs; source-controlled |
| `npx svgo` | 4.0.1 [VERIFIED: npm registry] | Optimize SVGs post-authoring | Confirmed available (`npx svgo --version` = 4.0.1); project confirmed no global install |
| fontTools (Python) | 4.62.1 [VERIFIED: pip registry] | Text-to-path: extract Sora Bold glyph outlines programmatically | Installed at `~/.local/Python/3.14/lib/python/site-packages`; `SVGPathPen` + `TTFont` confirmed importable |
| `mix phx.digest` | Phoenix 1.8.7 [VERIFIED: demo mix.exs] | Fingerprint + gzip static assets in demo | Already used by demo's `assets.deploy` alias; generates `cache_manifest.json` |
| Python 3.14 | 3.14.4 [VERIFIED: command -v python3] | fontTools driver script; WCAG scripts | Already in PATH at `/opt/homebrew/bin/python3` |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Google Fonts CDN | current | Download Sora Bold TTF for text-to-path | One-time download during wordmark authoring; TTF not committed |
| `curl` | system | Download Sora Bold TTF URL from Google Fonts API | One-shot; part of text-to-path script setup |

### No Package Installation Required

This phase installs no npm or hex packages. `npx svgo` is invoked ad-hoc (no `package.json` needed). fontTools is already present. The plan should NOT add a `package.json` or run `npm install`.

---

## Package Legitimacy Audit

> slopcheck ran against `svgo` in the Python/PyPI ecosystem, producing a false `[SLOP]` verdict because svgo is an npm package, not a Python package. This is the documented cross-ecosystem confusion vector. The npm registry check is authoritative.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| svgo | npm | 12+ years (created 2012-09-27) | Very high (standard SVG tooling) | github.com/svg/svgo | false positive (slopcheck tested PyPI not npm) | Approved — npm registry confirmed, 12-year track record, official SVG optimization tool |

**Packages removed due to slopcheck [SLOP] verdict:** none (slopcheck ecosystem confusion — svgo is npm-only, not PyPI)
**Packages flagged as suspicious [SUS]:** none

**fontTools** is the reference Python font library maintained by Google, Just van Rossum, and the open-type community — confirmed at pip registry, 4.62.1, installed and partially importable. [VERIFIED: pip registry]

---

## Architecture Patterns

### System Architecture Diagram

```
Google Fonts CDN
    |
    | (one-time curl download — Sora-Bold.ttf, not committed)
    v
[fontTools Python script]
    |
    | SVGPathPen — extracts glyph outlines for "Rulestead"
    v
rs-wordmark.svg (wordmark glyph paths)
rs-wordmark-dark.svg
    |
brandbook/assets/logo/        (canonical source — all 7 files)
  rs-wordmark.svg             |
  rs-wordmark-dark.svg        |
  rs-mark.svg                 |--- npx svgo (custom config: preserves title/desc/viewBox/currentColor)
  rs-mark-dark.svg            |
  rs-mark-mono.svg            |
  rs-favicon.svg              |
  rs-social-card.svg ----------

                              |
              +---------------+--------------+
              |                              |
    [COPY to admin]                [COPY to demo]
              |                              |
rulestead_admin/                  examples/demo/backend/
  priv/static/images/               priv/static/images/
    rs-mark.svg                       logo.svg  (replaces phoenix-flame)
    rs-mark-dark.svg                      |
                                  mix phx.digest (in backend/)
                                      |
                              priv/static/images/
                                logo-<hash>.svg
                                logo.svg.gz
                                logo-<hash>.svg.gz
                                cache_manifest.json (updated)
```

### Recommended Project Structure

```
brandbook/
  assets/
    logo/
      rs-mark.svg             # icon-only, light
      rs-mark-dark.svg        # icon-only, dark
      rs-mark-mono.svg        # fill="currentColor", no fills
      rs-wordmark.svg         # wordmark + icon, light
      rs-wordmark-dark.svg    # wordmark + icon, dark
      rs-favicon.svg          # 16px-legible icon
      rs-social-card.svg      # 1200x630 OG card
      concepts/
        rs-mark-concept-a.svg
        rs-mark-concept-b.svg
        rs-mark-concept-c.svg
scripts/
  gen_wordmark_paths.py       # fontTools text-to-path script (one-shot)
```

The `concepts/` subdirectory holds the three options for human review; only one selected mark graduates to the root `logo/` directory.

---

### Pattern 1: Accessible SVG Skeleton

**What:** Every logo SVG must carry a `<title>` and `<desc>` element and use `aria-labelledby` so screen readers announce the logo identity. The `<svg>` element must have `role="img"`.

**When to use:** Every file in `brandbook/assets/logo/*.svg` (required by LOGO-04).

**Example:**

```svg
<!-- Source: W3C SVG Accessibility Notes / WAI-ARIA 1.2 -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 120 40"
     role="img"
     aria-labelledby="rs-logo-title rs-logo-desc">
  <title id="rs-logo-title">Rulestead</title>
  <desc id="rs-logo-desc">Rulestead logo — wordmark with geometric mark</desc>
  <!-- paths here -->
</svg>
```

SVGO's `removeTitle` and `removeDesc` plugins are in `preset-default` and **must be disabled** to preserve these elements. [CITED: svgo.dev/docs/plugins]

---

### Pattern 2: SVGO Custom Config (preserves a11y + currentColor + viewBox)

**What:** A `brandbook/assets/logo/svgo.config.mjs` (or repo-root `svgo.config.mjs`) that extends `preset-default` with three plugin overrides.

**When to use:** Whenever running `npx svgo` against logo SVGs.

```javascript
// Source: svgo.dev docs — config format for SVGO 4.x
// File: brandbook/assets/logo/svgo.config.mjs
export default {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          removeTitle: false,      // MUST keep <title> for aria-labelledby
          removeDesc: false,       // MUST keep <desc> for screen readers
          removeViewBox: false,    // MUST keep viewBox for fluid scaling
          cleanupIds: false,       // keep IDs used by aria-labelledby
        },
      },
    },
  ],
};
```

Run: `npx svgo --config brandbook/assets/logo/svgo.config.mjs -f brandbook/assets/logo/`

SVGO 4.x config: `.js`, `.mjs`, or `.cjs` only — no `.json` config. [VERIFIED: npx svgo --help]

---

### Pattern 3: Monochrome Mark (`fill="currentColor"`)

**What:** `rs-mark-mono.svg` uses `fill="currentColor"` on all paths so the mark inherits the surrounding text color in any embedding context (dark/light/high-contrast).

**When to use:** Admin sidebar, documentation inline marks, anywhere the host controls theme color via CSS.

```svg
<!-- rs-mark-mono.svg — NO fill hex values anywhere -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 40 40"
     role="img"
     aria-labelledby="rs-mark-mono-title">
  <title id="rs-mark-mono-title">Rulestead mark</title>
  <path fill="currentColor" d="M..." />
</svg>
```

Caution: SVGO's `convertColors` plugin may convert `currentColor` to a hex if it parses it incorrectly. After SVGO pass, verify `grep -c 'currentColor' rs-mark-mono.svg` > 0. [ASSUMED]

---

### Pattern 4: Favicon SVG (16px legibility constraints)

**What:** `rs-favicon.svg` must be legible when rendered at 16×16 CSS pixels. Modern browsers (Firefox 84+, Chrome 80+) support `<link rel="icon" href="favicon.svg">` natively.

**Design budget at 16px:**
- Minimum stroke weight if stroked: 1.5px (thinner disappears at 16px)
- Maximum detail: 2–3 distinct shapes; avoid thin negative-space gaps < 2px
- ViewBox: `0 0 32 32` or `0 0 64 64` (square; never rectangular for favicon)
- Fill-only approach preferred (no strokes at this size — sub-pixel stroke bleed)
- The mark at 16px should read as an "R" initial or recognizable geometric, not the full wordmark

The `rs-favicon.svg` and `rs-mark.svg` may share the same geometry; the favicon is the mark scaled to a square viewBox. [ASSUMED: design best practice from favicon.io / realfavicongenerator.net docs]

The existing demo `favicon.ico` (152 bytes, a minimal file) is separate and is NOT replaced by this phase — only `logo.svg` is replaced. [VERIFIED: cache_manifest.json shows `favicon.ico` in digest, but this phase's scope is `logo.svg` only per LOGO-05]

---

### Pattern 5: Social Card SVG (1200×630)

**What:** `rs-social-card.svg` uses a fixed `viewBox="0 0 1200 630"` with `width="1200" height="630"` attributes set explicitly. This is the standard OG/Twitter card aspect ratio.

```svg
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 1200 630"
     width="1200"
     height="630"
     role="img"
     aria-labelledby="rs-social-title">
  <title id="rs-social-title">Rulestead — Runtime decisions, made clear.</title>
  <!-- Background rect, mark, wordmark paths, tagline paths -->
  <rect width="1200" height="630" fill="#183247"/>
  <!-- ... -->
</svg>
```

The social card is static SVG (no `<text>` elements — all text outlined to paths per LOGO-02 success criterion). [ASSUMED: OG/Twitter card conventions; SVG social cards are valid for GitHub opengraph]

Size budget: ≤20KB per `scripts/ci/lint.sh` loop — social card with outlined text paths can get large; keep background simple (single rect, not gradient-heavy) and limit path count. [VERIFIED: lint.sh lines 31–44]

---

### Pattern 6: Text-to-Path via fontTools

**What:** A one-shot Python script downloads Sora Bold TTF from Google Fonts, extracts glyph outlines for the string "Rulestead", and emits SVG `<path>` data with correct advance widths. The TTF file is downloaded to a temp directory and NOT committed.

**Why this approach:** No Inkscape, no Figma, no design tools available on this machine. fontTools `SVGPathPen` + `TTFont` are confirmed importable. [VERIFIED: python3 confirmed fontTools SVGPathPen + TTFont]

```python
# scripts/gen_wordmark_paths.py — skeleton
# Requires: fontTools 4.62.1 (already installed)
# Usage: python3 scripts/gen_wordmark_paths.py --text "Rulestead" --output /tmp/wordmark_paths.txt
import sys, urllib.request, tempfile, os
sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

SORA_BOLD_URL = "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mX-K.ttf"

def glyph_to_svg_path(font, glyph_name, x_offset=0, scale=1.0):
    pen = SVGPathPen(font.getGlyphSet())
    font.getGlyphSet()[glyph_name].draw(pen)
    return pen.getCommands()

# ... fetch TTF, build cmap, iterate "Rulestead" chars, accumulate advance widths
```

**Alternative if fontTools script proves difficult:** Hand-trace simplified letterforms as geometric paths (not font-accurate but brand-consistent). This is acceptable for a wordmark where exact font fidelity is traded for simplicity. The success criterion is `grep -c '<text'` = 0, not font accuracy. [ASSUMED: design tradeoff]

**Third alternative:** Use an online SVG font converter (e.g., everything-fonts.com or convertio.co) as a one-time manual step, then commit the resulting path data. This is fully compliant with "no font binaries committed" since only the output paths are committed. [ASSUMED: viable workaround]

---

### Pattern 7: Light/Dark Variant Strategy

**What:** Light and dark variants differ only in fill hex values. The mark paths are identical; only the color changes.

| File | Background | Mark fill | Text fill |
|------|-----------|-----------|-----------|
| `rs-wordmark.svg` | transparent | `#3A6F8F` (Stead Blue) | `#183247` (Ink Blue) |
| `rs-wordmark-dark.svg` | transparent | `#5885a0` (Stead Blue dark) | `#e8edf3` (neutral-900 dark) |
| `rs-mark.svg` | transparent | `#3A6F8F` | — |
| `rs-mark-dark.svg` | transparent | `#5885a0` | — |
| `rs-mark-mono.svg` | transparent | `currentColor` | — |
| `rs-favicon.svg` | `#3A6F8F` (solid bg) | `#ffffff` | — |
| `rs-social-card.svg` | `#183247` (Ink Blue) | `#5885a0` + `#e8edf3` | all paths |

Fill values sourced directly from `brandbook/tokens.json` primitives. [VERIFIED: tokens.json — primitives.stead-blue.base `#3A6F8F`, primitives.stead-blue.dark `#5885a0`, primitives.ink-blue.base `#183247`, primitives.neutral-ramp.dark-900 `#e8edf3`]

---

### Pattern 8: Phoenix Digest Workflow for Demo Logo Replacement (LOGO-05)

**What:** Replacing `logo.svg` and regenerating all fingerprinted/gzipped sidecars.

**Exact procedure:**

```bash
# 1. Replace the source logo
cp brandbook/assets/logo/rs-mark.svg examples/demo/backend/priv/static/images/logo.svg

# 2. Remove old fingerprinted file and sidecars (prevents stale files)
rm examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg
rm examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg.gz
rm examples/demo/backend/priv/static/images/logo.svg.gz

# 3. Re-digest from the demo backend directory
cd examples/demo/backend
mix phx.digest

# 4. New files generated:
#   priv/static/images/logo.svg          (unchanged — source)
#   priv/static/images/logo.svg.gz       (new gzip)
#   priv/static/images/logo-<newhash>.svg  (new fingerprint)
#   priv/static/images/logo-<newhash>.svg.gz
#   priv/static/cache_manifest.json      (updated with new hash)
```

**What `mix phx.digest` generates per output file:**
1. The original file (unchanged)
2. The file compressed with gzip (`.gz` sidecar)
3. A fingerprinted copy (`filename-<md5hash>.ext`)
4. A fingerprinted + gzip compressed copy
5. Updated `cache_manifest.json`

[VERIFIED: `mix help phx.digest` confirms this exactly; `cache_manifest.json` inspected and shows `"images/logo.svg":"images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg"` pattern]

**Why NOT to use `mix phx.digest.clean --all` before replacing:** `phx.digest.clean --all` removes ALL generated files including other assets (CSS, JS). Use targeted `rm` for only the logo sidecar files. [VERIFIED: `mix help phx.digest.clean` confirms `--all` removes all generated artifacts]

**Demo serving:** In development, `Plug.Static` with `gzip: not code_reloading?` serves the plain file (no digest needed for dev). In production/Docker, the digested+gzipped version is served. The Dockerfile runs `mix assets.deploy` which is aliased to `[..., "phx.digest"]`. [VERIFIED: endpoint.ex + Dockerfile]

---

### Pattern 9: Admin Image Embedding (LOGO-04)

**What:** Create `rulestead_admin/priv/static/images/` and place mark SVGs there. The admin package ships images in `priv/` (same as CSS). The host copies them during its asset pipeline.

```bash
# Create the directory
mkdir -p rulestead_admin/priv/static/images/

# Copy canonical marks
cp brandbook/assets/logo/rs-mark.svg rulestead_admin/priv/static/images/rs-mark.svg
cp brandbook/assets/logo/rs-mark-dark.svg rulestead_admin/priv/static/images/rs-mark-dark.svg
```

There is currently no reference to images in the admin's shell component or layouts — the admin does not currently display a logo. The `rulestead_admin/priv/static/images/` files are committed as package assets; Phase 98+ may wire them into the admin shell UI. For now, LOGO-04 just requires the files to exist. [VERIFIED: grep of all admin .ex files — no img/logo/svg src references found]

---

### Anti-Patterns to Avoid

- **Embedded raster in SVG:** Never use `<image>` with base64 data or an external PNG/JPG reference. Success criterion: `grep -c 'base64' brandbook/assets/logo/*.svg` = 0.
- **Live `<text>` elements in final SVGs:** All text must be paths. Success criterion: `grep -c '<text' brandbook/assets/logo/*.svg` = 0.
- **Removing title/desc with SVGO default config:** Running `npx svgo` without the custom config will strip `<title>` and `<desc>` (they are in `preset-default`). Always use `--config svgo.config.mjs`.
- **Committing TTF/OTF font files:** Font policy forbids font binaries. Only the derived SVG path data is committed.
- **Using `mix phx.digest.clean --all`:** This nukes all generated files (CSS, JS, favicon) not just logo. Use targeted `rm` for logo sidecars only.
- **Forgetting to delete the old fingerprinted file:** If `logo-06a11be1f2cdde2c851763d00bdd2e80.svg` is left, `cache_manifest.json` may point to the old file. Always remove old fingerprinted copies before re-digesting.
- **Using Signal Gold as a fill in logo SVGs:** Signal Gold `#D2A94E` is decorative-only and fails all light surfaces. Never use as logo fill. [VERIFIED: tokens.json PAL-04 policy]
- **Omitting `role="img"` on the `<svg>` element:** Without `role="img"`, `aria-labelledby` may be ignored by some screen readers.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG optimization | Custom minifier | `npx svgo` with custom config | SVGO handles path precision, useless groups, redundant attrs — thousands of edge cases |
| Text-to-path conversion | Manual bezier tracing | fontTools `SVGPathPen` + `TTFont` script | Font hinting, advance widths, kerning — impossible to hand-trace accurately |
| Phoenix static file fingerprinting | Manual MD5 + gzip script | `mix phx.digest` | Generates `cache_manifest.json` that Phoenix reads at runtime; custom scripts won't integrate |
| WCAG contrast verification for mark fills | Eyeball judgment | Reuse `python3 scripts/check_contrast.py` | AA compliance is a hard requirement; the script already exists and verified the palette |

**Key insight:** The text-to-path conversion is the only genuinely hard mechanical step. Everything else (path authoring, SVGO optimization, file copying, mix phx.digest) is straightforward. The plan should allocate a dedicated task for the wordmark text-to-path step.

---

## Common Pitfalls

### Pitfall 1: SVGO Strips `<title>` and `<desc>` by Default

**What goes wrong:** Running `npx svgo` without a custom config removes both `<title>` and `<desc>` (both are in `preset-default`). The SVGs pass the grep test but fail WCAG 1.1.1 (non-text content).

**Why it happens:** SVGO's philosophy is maximum compression; accessibility elements are considered "unnecessary" metadata by default.

**How to avoid:** Always supply `--config brandbook/assets/logo/svgo.config.mjs` with `removeTitle: false` and `removeDesc: false`. Verify after each SVGO run: `grep -c '<title' brandbook/assets/logo/*.svg` should equal the file count.

**Warning signs:** Output SVG has no `<title>` element; `aria-labelledby` attribute has no target.

---

### Pitfall 2: SVGO Removes `viewBox` on Root Element

**What goes wrong:** `removeViewBox` plugin (in `preset-default`) removes the `viewBox` attribute if `width` and `height` are set, making the SVG non-scalable. Logos embedded without explicit size constraints will render at 0×0 or a fixed pixel size.

**Why it happens:** SVGO assumes width+height are sufficient. For logos embedded as `<img>` or inline SVG in CSS, `viewBox` is required for responsive scaling.

**How to avoid:** Add `removeViewBox: false` to the custom SVGO config override. Verify: `grep 'viewBox' brandbook/assets/logo/*.svg` should match all files.

---

### Pitfall 3: Old Fingerprinted Logo File Left in Demo Repo

**What goes wrong:** `logo-06a11be1f2cdde2c851763d00bdd2e80.svg` remains in `priv/static/images/` after `mix phx.digest`. Phoenix may serve the old file from cache, and the repo contains orphan files.

**Why it happens:** `mix phx.digest` does NOT delete old fingerprinted copies — it only adds new ones and updates `cache_manifest.json`. The `latest` key in `cache_manifest.json` will point to the new file, but the old fingerprinted file stays on disk.

**How to avoid:** Explicitly `rm` the old fingerprinted file and both `.gz` sidecars before committing. Verify: `ls priv/static/images/` shows only the new `logo-<newhash>.svg` variant.

**Warning signs:** Git diff shows both old and new fingerprinted files; `cache_manifest.json` shows old hash under `digests` key but not under `latest`.

---

### Pitfall 4: fontTools Import Path Issue

**What goes wrong:** fontTools is installed at `~/Library/Python/3.14/lib/python/site-packages` (user install), not in the system Python path. A script using just `import fontTools` fails with `ModuleNotFoundError`.

**Why it happens:** Python 3.14 user site-packages is not on the default `sys.path` in all execution contexts.

**How to avoid:** The `gen_wordmark_paths.py` script must include:

```python
import sys, os
sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont
```

[VERIFIED: confirmed by testing `python3 -c "..."` with the path prefix — import succeeds]

---

### Pitfall 5: `fill="currentColor"` Converted by SVGO

**What goes wrong:** SVGO's `convertColors` plugin (in `preset-default`) may convert `currentColor` to a computed hex or remove it, breaking the monochrome mark's theme-following behavior.

**Why it happens:** `convertColors` normalizes color values; `currentColor` is a CSS-inherited keyword, not a static value, and some SVGO versions handle it differently.

**How to avoid:** After SVGO optimization of `rs-mark-mono.svg`, verify: `grep -c 'currentColor' brandbook/assets/logo/rs-mark-mono.svg` returns > 0. If it returns 0, add `convertColors: false` to the SVGO config overrides for that file.

---

### Pitfall 6: Concepts Directory SVGs Pulled Into Lint Budget

**What goes wrong:** If `concepts/` is a subdirectory of `brandbook/assets/logo/`, the `scripts/ci/lint.sh` size-budget loop may pick up concept SVGs (`for f in brandbook/assets/logo/*.svg`) — but since the glob is `*.svg` (not recursive), subdirectory files are NOT matched. No action needed.

**Why this is safe:** `for f in "${RULESTEAD_REPO}/brandbook/assets/logo/"*.svg` with `shopt -s nullglob` only matches files directly in the `logo/` directory, not in subdirectories. [VERIFIED: lint.sh lines 31–37 inspected; uses `/*.svg` not `/**/*.svg`]

---

## Code Examples

### Accessible SVG Skeleton (complete)

```svg
<!-- Source: W3C SVG Accessibility Notes; WAI-ARIA 1.2 §6.6 -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 120 40"
     role="img"
     aria-labelledby="rs-logo-title rs-logo-desc">
  <title id="rs-logo-title">Rulestead</title>
  <desc id="rs-logo-desc">Rulestead wordmark — a geometric mark beside the word Rulestead in structured letterforms</desc>
  <g aria-hidden="true">
    <!-- All visual paths here; aria-hidden on group prevents double-reading -->
    <path fill="#3A6F8F" d="M..." />
    <path fill="#183247" d="M..." />
  </g>
</svg>
```

The `aria-hidden="true"` on the path group prevents screen readers from announcing individual path elements after already reading the `<title>` + `<desc>`. [CITED: w3.org/WAI/WCAG21/Techniques/aria/ARIA6]

### SVGO Config (`brandbook/assets/logo/svgo.config.mjs`)

```javascript
// Source: svgo.dev/docs/configuration
export default {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          removeTitle: false,
          removeDesc: false,
          removeViewBox: false,
          cleanupIds: false,
          convertColors: false,   // only add if currentColor is used (rs-mark-mono.svg)
        },
      },
    },
  ],
};
```

Invoke: `npx svgo --config brandbook/assets/logo/svgo.config.mjs -f brandbook/assets/logo/ -r --exclude "svgo.config.mjs"`

### fontTools text-to-path skeleton

```python
# Source: fonttools.readthedocs.io — SVGPathPen usage
# scripts/gen_wordmark_paths.py
import sys, os, urllib.request, tempfile

# User install path (confirmed working 2026-06-05)
sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

SORA_BOLD_TTF_URL = "https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mX-K.ttf"

def get_font(url):
    with tempfile.NamedTemporaryFile(suffix=".ttf", delete=False) as f:
        urllib.request.urlretrieve(url, f.name)
        return TTFont(f.name)

def text_to_svg_paths(text, font, em_size=64):
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    units_per_em = font['head'].unitsPerEm
    scale = em_size / units_per_em
    paths = []
    x_cursor = 0
    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if not glyph_name:
            continue
        pen = SVGPathPen(glyphs)
        glyphs[glyph_name].draw(pen)
        adv = glyphs[glyph_name].width
        # pen.getCommands() returns the path data string
        d = pen.getCommands()
        if d:
            # Apply scale + x_cursor translation via SVG transform
            paths.append(f'<path transform="translate({x_cursor * scale:.2f},0) scale({scale:.4f},-{scale:.4f})" d="{d}"/>')
        x_cursor += adv
    return paths

if __name__ == '__main__':
    font = get_font(SORA_BOLD_TTF_URL)
    paths = text_to_svg_paths("Rulestead", font)
    for p in paths:
        print(p)
```

Note: SVG coordinate system is Y-down, font coordinate system is Y-up — the `scale(s, -s)` flip is required. [CITED: fonttools.readthedocs.io — coordinate system notes]

### Phoenix Digest — Exact shell commands for LOGO-05

```bash
# Replace demo logo (run from repo root)
cp brandbook/assets/logo/rs-mark.svg \
   examples/demo/backend/priv/static/images/logo.svg

# Remove old fingerprinted files (old hash: 06a11be1f2cdde2c851763d00bdd2e80)
rm examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg
rm examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg.gz
rm examples/demo/backend/priv/static/images/logo.svg.gz

# Re-digest from backend dir
cd examples/demo/backend && mix phx.digest && cd -

# Verify: exactly one fingerprinted logo file exists (new hash)
ls examples/demo/backend/priv/static/images/logo-*.svg | wc -l  # expect: 1
```

---

## Wave / Human Checkpoint Structure

The phase roadmap says "4 plans" with the mid-phase A/B/C selection as a human checkpoint. The correct wave structure is:

**Wave 1 (autonomous):**
- Produce three mark concepts (A, B, C) as SVGs in `brandbook/assets/logo/concepts/`
- Present to maintainer with embedded rendered view in a `CONCEPT-REVIEW.md`

**Wave 1 checkpoint (autonomous:false):**
- Maintainer selects concept A, B, or C
- This MUST be an `autonomous: false` plan task — a human decision, not automatable
- No downstream work proceeds until selection is made

**Wave 2 (autonomous, blocked on Wave 1 checkpoint):**
- Author full lockup set based on selected concept
- Run fontTools script to generate wordmark paths
- Produce all 7 files in `brandbook/assets/logo/`
- Run SVGO

**Wave 3 (autonomous):**
- Copy marks to `rulestead_admin/priv/static/images/`
- Replace demo `logo.svg`, run `mix phx.digest`, commit generated files

**Wave 4 (autonomous):**
- Verification pass: grep checks, lint.sh, demo smoke

This structure maps cleanly to the 4 planned plan files (97-01 through 97-04). [ASSUMED: plan count matches wave count — planner may adjust]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SVGO config as `.svgorc` JSON | SVGO 4.x requires `.mjs`/`.cjs`/`.js` only | SVGO 4.0 (2024) | Must use `svgo.config.mjs`; no JSON config |
| `title` + `desc` ignored by screen readers | `aria-labelledby` pointing to `<title id>` | WAI-ARIA 1.2 (2023) | `id` attributes on `<title>` and `<desc>` are required |
| `role="img"` on SVG | Still current best practice | — | Required for SVG used as standalone images |
| Browser `favicon.svg` support | Supported in Chrome 80+, Firefox 84+, Safari 12+ | 2020+ | SVG favicon is viable; `.ico` fallback for IE only |

**Deprecated/outdated:**
- `xlink:href` in SVG: replaced by plain `href` (SVG 2.0); SVGO's `removeXlink` plugin handles this automatically
- `xml:space="preserve"` on SVG: deprecated; SVGO removes it by default

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `npx svgo` | LOGO-04 optimization | Yes | 4.0.1 | None needed |
| Python 3 | fontTools driver script | Yes | 3.14.4 | — |
| fontTools (`SVGPathPen`, `TTFont`) | Wordmark text-to-path | Yes (user install) | 4.62.1 | Manual path tracing or online converter |
| `mix phx.digest` | LOGO-05 demo digest | Yes | Phoenix 1.8.7 | — |
| `curl` / `urllib.request` | Download Sora Bold TTF | Yes (both available) | system | — |
| Google Fonts CDN | Download Sora Bold TTF | Yes (verified 2026-06-05) | Sora v17 | Bundle TTF locally (not committed — temp download) |
| Inkscape | Text-to-path (alternative) | No | — | fontTools script (primary) |

**Missing dependencies with no fallback:** None — all required tools available.

**Missing dependencies with fallback:** fontTools user install path — if import fails, fall back to manual outline or online converter.

---

## Validation Architecture

`workflow.nyquist_validation` is not explicitly `false` in `.planning/config.json` — include validation.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash/grep/Python (no test framework needed — all checks are grep-count or file-existence assertions) |
| Config file | none — checks are inline shell commands |
| Quick run command | `bash scripts/ci/lint.sh` (SVG budget section only — no-op before dirs exist) |
| Full suite command | `bash scripts/ci/lint.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOGO-01 | Three concept SVGs exist | smoke | `ls brandbook/assets/logo/concepts/rs-mark-concept-{a,b,c}.svg` | No — Wave 1 creates them |
| LOGO-01 | One selected mark in logo/ | smoke | `ls brandbook/assets/logo/rs-mark.svg` | No — Wave 2 creates |
| LOGO-02 | Full lockup set (7 files) | smoke | `ls brandbook/assets/logo/rs-{wordmark,wordmark-dark,mark,mark-dark,mark-mono,favicon,social-card}.svg \| wc -l` (expect 7) | No — Wave 2 |
| LOGO-02 | No `<text>` elements | unit/grep | `grep -c '<text' brandbook/assets/logo/*.svg` (expect all zeros) | No |
| LOGO-03 | No base64 raster data | unit/grep | `grep -c 'base64' brandbook/assets/logo/*.svg` (expect all zeros) | No |
| LOGO-03 | Social card viewBox 1200×630 | unit/grep | `grep 'viewBox="0 0 1200 630"' brandbook/assets/logo/rs-social-card.svg` | No |
| LOGO-04 | All SVGs have `<title>` | unit/grep | `for f in brandbook/assets/logo/*.svg; do grep -q '<title' "$f" || echo "MISSING TITLE: $f"; done` | No |
| LOGO-04 | `rs-mark-mono.svg` has `currentColor` | unit/grep | `grep -c 'currentColor' brandbook/assets/logo/rs-mark-mono.svg` (expect > 0) | No |
| LOGO-04 | SVG size budget green | integration | `bash scripts/ci/lint.sh` → "SVG SIZE BUDGET OK" | Yes (lint.sh exists) |
| LOGO-04 | Admin marks exist | smoke | `ls rulestead_admin/priv/static/images/rs-mark.svg rulestead_admin/priv/static/images/rs-mark-dark.svg` | No — Wave 3 |
| LOGO-05 | Demo logo replaced | smoke | `grep -c 'FD4F00' examples/demo/backend/priv/static/images/logo.svg` (expect 0 — phoenix-flame fill) | Yes (logo.svg exists but is old) |
| LOGO-05 | Fingerprinted file updated | smoke | `ls examples/demo/backend/priv/static/images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg 2>/dev/null \| wc -l` (expect 0 — old hash gone) | Yes (currently 1 — must become 0) |
| LOGO-05 | New fingerprinted file present | smoke | `ls examples/demo/backend/priv/static/images/logo-*.svg \| wc -l` (expect 1) | Yes (currently old hash) |
| LOGO-05 | `.gz` sidecars present | smoke | `ls examples/demo/backend/priv/static/images/logo*.gz \| wc -l` (expect 2: plain + fingerprinted) | Yes (old) |

### Wave 0 Gaps

None — no test files to create. All validation is grep/file-existence checks runnable inline in plan tasks. The `scripts/ci/lint.sh` SVG budget loop is already wired and will be non-op until `brandbook/assets/logo/` is created.

---

## Security Domain

`security_enforcement` is not explicitly set to `false` in config.json — include.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No | SVGs are authored files, not user input |
| V6 Cryptography | No | — |
| V9 Communications | Partial | Sora Bold TTF download from Google Fonts CDN over HTTPS only; verify URL is `fonts.gstatic.com` |

### Known Threat Patterns for SVG files

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SVG with embedded `<script>` | Tampering / Elevation | SVGO's `removeScripts` plugin is in `preset-default` — verify after optimization |
| SVG with external URL references (`href` to external) | Information Disclosure | Do not use `<image href="http://...">` in logo SVGs; LOGO-03 success criterion (`grep -c 'base64'`) covers embedded raster but not external URLs — additionally verify no `http` in SVG files |
| SVG served as `image/svg+xml` with scripts | XSS (if inline embed) | The demo serves SVG via `<img src=...>` (layout.ex line 41) — img tag prevents script execution; admin marks also served as `<img>` |

SVG security is LOW risk here: all files are hand-authored, no user input involved, served via `<img>` not inline `<svg>`, and SVGO removes scripts by default. [ASSUMED: admin embed pattern — shell.ex grep found no current img tag; mark files are placed but not yet rendered]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Wordmark will use Sora Bold font glyphs converted via fontTools | Pattern 6, Code Examples | If fontTools script fails for this font/version, manual tracing or online converter is fallback — LOGO-02 still satisfied |
| A2 | Three mark concepts (A/B/C) are authored by Claude as SVGs, not by the maintainer | Wave structure | If maintainer wants to supply their own concepts, Wave 1 becomes human-authored — plan must accommodate |
| A3 | `rs-mark.svg` (icon-only, light) is the correct SVG to replace the demo `logo.svg` | Pattern 8 | If maintainer prefers a different file (e.g., wordmark), the copy command changes |
| A4 | Admin mark SVGs do not need to be rendered in the admin UI in Phase 97 (just committed to `priv/static/images/`) | Pattern 9 | If maintainer expects the admin shell to display the mark, a shell.ex template change is also needed in Phase 97 |
| A5 | `CONCEPT-REVIEW.md` is the right artifact for presenting concepts A/B/C to the maintainer | Wave structure | Planner may prefer a different presentation format |
| A6 | The social card text (tagline, wordmark) must also be outlined to paths (not live `<text>`) | Pattern 5 | LOGO-02 success criterion says 0 `<text>` elements across ALL logo SVGs — this includes social card |
| A7 | favicon.svg legibility at 16px is verified by visual review, not automated test | Validation Architecture | No automated 16px render check exists; this is a human-review gate |

---

## Open Questions

1. **Which file replaces `demo/priv/static/images/logo.svg`?**
   - What we know: The mark (icon-only) makes more sense than the full wordmark at 36px width (current `<img width="36">` in layouts.ex)
   - What's unclear: Maintainer preference — icon-only (`rs-mark.svg`) vs. wordmark (`rs-wordmark.svg`)
   - Recommendation: Use `rs-mark.svg` (icon-only) for the demo at 36px; the wordmark is too wide at that size. Planner should note this as a decision point.

2. **Does the admin shell need a logo display in Phase 97?**
   - What we know: No current logo in admin shell (no img/svg src found in any .ex file)
   - What's unclear: Whether Phase 97 should wire the mark into the admin shell UI template, or just commit it to `priv/static/images/` for Phase 98+ to use
   - Recommendation: Scope to file-existence only (LOGO-04 says "exist as admin-embedded copies") — do NOT modify shell.ex in Phase 97; that's Phase 98 territory.

3. **Should concept SVGs stay in the repo after selection?**
   - What we know: ROADMAP says "produced and presented"; does not say retained
   - What's unclear: Whether `concepts/` directory should be committed long-term or removed after selection
   - Recommendation: Keep `concepts/` committed for audit trail; `brandbook/README.md` already mentions Phase 97 will add `assets/logo/`.

---

## Sources

### Primary (HIGH confidence)

- `scripts/ci/lint.sh` — SVG size-budget loop verified (lines 29–45); logo ≤20480 bytes, specimen ≤51200 bytes
- `examples/demo/backend/priv/static/images/` — current files inventoried: `logo.svg` (3072 bytes, phoenix-flame `fill="#FD4F00"`), fingerprinted copy, both `.gz` sidecars
- `examples/demo/backend/priv/static/cache_manifest.json` — confirms `"images/logo.svg":"images/logo-06a11be1f2cdde2c851763d00bdd2e80.svg"` pattern
- `brandbook/tokens.json` — all fill hex values confirmed from primitives section
- `mix help phx.digest` — exact output behavior confirmed (fingerprint + gzip + cache_manifest)
- `mix help phx.digest.clean` — `--all` removes all generated artifacts confirmed
- `examples/demo/backend/Dockerfile` — `mix assets.deploy` = `mix phx.digest` in prod build confirmed
- `npx svgo --show-plugins` — `removeTitle`, `removeDesc`, `removeViewBox` all confirmed in `preset-default`
- `npx svgo --help` — config file format confirmed (`.mjs`/`.cjs`/`.js` only)
- `python3` import test — `fontTools.pens.svgPathPen.SVGPathPen` + `fontTools.ttLib.TTFont` confirmed working with user site-packages path prefix
- `curl https://fonts.googleapis.com/css2?family=Sora:wght@700` — Sora Bold v17 TTF URL confirmed live
- `examples/demo/backend/lib/rulestead_demo_web/components/layouts.ex` — `<img src={~p"/images/logo.svg"} width="36">` confirmed on line 41

### Secondary (MEDIUM confidence)

- `rulestead_admin/README.md` — manual CSS copy pattern confirmed; `priv/` included in hex package `files:` list
- `rulestead_admin/mix.exs` — `files: ~w(lib priv ...)` confirmed; `priv/static/images/` would be included in published package
- W3C SVG Accessibility notes — `aria-labelledby` + `<title id>` + `role="img"` pattern is current standard

### Tertiary (LOW confidence — assumed)

- favicon.svg design constraints at 16px (fill-only, 2–3 shapes max) — from general favicon design best practices; not verified against an authoritative spec source
- Social card SVG `1200×630` viewBox convention — OG image spec defines raster dimensions; SVG convention follows same aspect ratio by community practice
- `convertColors` plugin stripping `currentColor` — noted as potential risk; not directly tested in this research session

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools verified available; SVGO confirmed working; fontTools confirmed importable
- Architecture: HIGH — Phoenix digest workflow fully traced; file inventory complete; admin package structure confirmed
- Pitfalls: HIGH for SVGO and digest pitfalls (verified by direct inspection); MEDIUM for fontTools coordinate-system details and favicon design constraints (assumed from general knowledge)
- Mark design (A/B/C concept content): ASSUMED — the brand book §11/§14 defines the design vocabulary but concept execution is creative work; no automated verification possible

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (stable tooling; fontTools + SVGO APIs are mature)

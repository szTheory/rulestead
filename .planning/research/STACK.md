# Stack Research — v1.14 Brand System Realization

**Domain:** Source-controlled brand system for an Elixir/Hex OSS monorepo (design tokens, SVG assets, font references, repo hygiene)
**Researched:** 2026-06-04
**Confidence:** HIGH (DTCG spec, SVGO, font licensing verified via official sources; Tailwind v4 @theme verified)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| DTCG `tokens.json` | 2025.10 stable | Machine-readable token source of truth | First stable spec published 2025-10-28; vendor-neutral; `$value`/`$type`/`$description` keys; aliasing with `{group.token}` syntax; `.tokens.json` extension is spec-blessed; no build required to read |
| Hand-authored `tokens.css` | n/a | Emitted CSS custom properties for direct consumption | For an OSS repo with no JS build pipeline, a human-maintained CSS file mirroring `tokens.json` is lower-friction than Style Dictionary; the existing `--rs-*` shape is already the right output format |
| SVGO | v4.0.1 | SVG optimization for logo, icon, favicon, and specimen files | Latest stable (2025-03); v4 disables `removeViewBox` and `removeTitle` by default — correct accessibility posture out of the box; `svgo.config.mjs` ESM-only |
| Google Fonts CDN reference (no binaries) | n/a | Sora, Inter, IBM Plex Mono delivery | All three fonts are SIL OFL 1.1; reference via `<link>` in specimens/marketing; do NOT commit font binary files |

### Supporting Libraries / Tools

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Style Dictionary | v5.4.x (current) | Transform `tokens.json` to CSS / JSON / other | Use only if multi-platform output (iOS, Android, JS constants) is needed; overkill for CSS-only OSS context |
| Terrazzo / Cobalt UI | latest | Alternative DTCG-to-CSS transformer | Lighter than Style Dictionary if a build step is ever added; both understand DTCG 2025.10 aliases |
| `npx svgo` CLI | v4.0.1 | One-shot SVG optimization, no install required | Run as `npx svgo --config svgo.config.mjs` per asset; or add to a `Makefile` target in `brandbook/` |
| `python3` (stdlib) | 3.x (already in repo via `check_synced_pair.py`) | Lightweight token-sync / size-budget CI script | Use the existing scripting pattern — no new runtime dependency |
| `lfs-warning` GitHub Action | latest | Flag files exceeding a per-file byte threshold in PRs | Zero-config guard; set threshold to 50 KB for `brandbook/` directory |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `brandbook/svgo.config.mjs` | SVGO configuration committed to `brandbook/` | ESM module; override `preset-default` per asset category (logo, icon, specimen) |
| `Makefile` or `scripts/brandbook/` | Orchestrate `npx svgo` passes and validation | Keeps build logic in shell, consistent with repo's existing `scripts/` pattern |
| SVGOMG (web) | Interactive SVGO exploration during authoring | https://jakearchibald.github.io/svgomg/ — use for author workflow, not CI |

---

## Token File Format

### Use DTCG `tokens.json` (2025.10 stable) — hand-authored, no build step

The DTCG spec reached its first stable release 2025-10-28. The format uses `$value`, `$type`, `$description` keys and supports group nesting and `{group.token}` alias references.

**Three-tier structure to commit:**

1. `brandbook/tokens.json` — DTCG source: primitive (raw brand values) → semantic (role aliases) → state (hover/disabled/focus). Light and dark value sets are separate alias groups (or split into `tokens.light.json` / `tokens.dark.json`) rather than a single flat file, because DTCG 2025.10 Resolver module (for modes/themes) is still a draft — alias-per-set is the current stable approach.

2. `brandbook/tokens.css` — Hand-maintained CSS custom properties mirroring the `--rs-*` shape; acts as the authoritative emitted artifact for adopters who want to copy-paste. Updated whenever `tokens.json` changes. Enforce via a `scripts/check_tokens_sync.py` script (same pattern as the existing synced-pair check).

3. `brandbook/tokens.tailwind.js` or `brandbook/tokens.tailwind.css` — Optional hand-authored excerpt: either a `theme.extend` block for Tailwind v3 or a `@theme {}` CSS block for Tailwind v4.

**Skeleton `tokens.json` structure:**

```json
{
  "primitive": {
    "color": {
      "basalt":       { "$value": "#0F1720", "$type": "color", "$description": "Primary dark surface" },
      "slate-stead":  { "$value": "#24313D", "$type": "color" },
      "stead-blue":   { "$value": "#3A6F8F", "$type": "color" },
      "ember-copper": { "$value": "#B96A3A", "$type": "color" }
    }
  },
  "semantic": {
    "color": {
      "light": {
        "primary":    { "$value": "{primitive.color.stead-blue}", "$type": "color" },
        "bg":         { "$value": "{primitive.color.rain-tint}",  "$type": "color" }
      },
      "dark": {
        "primary":    { "$value": "{primitive.color.stead-blue}", "$type": "color" },
        "bg":         { "$value": "{primitive.color.basalt}",     "$type": "color" }
      }
    }
  }
}
```

**Why not Style Dictionary for this milestone:**

Style Dictionary v5 introduces an async plugin API and non-trivial config. For a `brandbook/` folder emitting only CSS, the added complexity is unjustified. The existing `check_synced_pair.py` proves the team can maintain a mirrored-pair contract without a build tool. If a future milestone adds multi-platform token output, reach for Style Dictionary v5+ or Terrazzo — both understand DTCG aliases and modes.

**Style Dictionary version caveat:** v4.x has first-class support for pre-2025.10 DTCG. v5.4.x is the current release; full 2025.10 Resolver support is still in progress as of mid-2026.

---

## CSS Custom Properties Emission

### Keep the existing `--rs-*` namespace and four-block cascade

The shipped `rulestead_admin.css` already encodes the correct shape:

- Invariant tokens on `:root` (typography, spacing, radius, motion, z-index)
- Variant tokens on `.rs-shell` / `[data-rulestead]` in four cascade blocks

`brandbook/tokens.css` follows the same structure but scoped to `:root` only — it is the portable brand reference, not the mounted-admin theme engine. The admin re-skin in `rulestead_admin.css` remains the single place where the four-block cascade lives.

**Tailwind v4 `@theme` bridge (optional, hand-authored):**

```css
/* brandbook/tokens.tailwind.css — paste into a Tailwind v4 project's CSS input */
@theme {
  --color-basalt:       #0F1720;
  --color-slate-stead:  #24313D;
  --color-stead-blue:   #3A6F8F;
  --color-ember-copper: #B96A3A;
  --font-display: "Sora", "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-sans:    "Inter", ui-sans-serif, system-ui, -apple-system, sans-serif;
  --font-mono:    "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, monospace;
}
```

Tailwind v4 reads `@theme` blocks from CSS and generates utilities from them. No `tailwind.config.js` required. This file is a copy-paste excerpt for adopters, not a build input.

---

## SVG Hygiene

### SVGO v4.0.1 configuration

Commit a `brandbook/svgo.config.mjs`:

```js
export default {
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          removeViewBox: false,   // REQUIRED — preserves SVG scalability (v4 default is already false)
          removeTitle: false,     // REQUIRED — preserves <title> for screen readers (v4 default is already false)
        },
      },
    },
    { name: 'removeEditorsNSData' },  // strip Figma/Inkscape namespace metadata
  ],
};
```

Note: SVGO v4 already has `removeViewBox` and `removeTitle` disabled by default. Spelling them out in the config makes the intent explicit and guards against accidental re-enablement.

**Accessible title/desc pattern** for every meaningful logo or icon SVG:

```svg
<svg viewBox="0 0 200 48" xmlns="http://www.w3.org/2000/svg"
     role="img" aria-labelledby="rs-logo-title">
  <title id="rs-logo-title">Rulestead wordmark</title>
  <!-- paths here -->
</svg>
```

For decorative SVGs (dividers, background specimens): `aria-hidden="true"`, no `<title>`.

### Wordmark: outline text on export, no embedded fonts in committed SVGs

Do NOT use `<text font-family="Sora">` in committed wordmark SVGs — this creates a font-file dependency that breaks rendering for anyone without the font installed. Convert text to path outlines before export.

- **Figma:** enable "Outline text" in export settings before saving SVG
- **Inkscape:** `Path > Object to Path` on all text layers before export

Keep a separate master source file (`.fig` or editable `.svg` with live text layers) outside committed `brandbook/` artifacts if future editing is needed.

**Exception for documentation specimens:** `brandbook/specimens/typography.svg` and similar files may use `<text font-family="...">` if they are always displayed in a browser where fonts are loaded. Add a `<!-- REQUIRES FONTS LOADED -->` comment.

---

## Favicon Strategy

### `favicon.svg` primary + `favicon.ico` legacy fallback

```html
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

Safari does not support SVG favicons as of mid-2026 (partial/inconsistent support; home-screen icon still requires PNG/ICO). The layered approach covers all browsers.

**File inventory for `brandbook/favicon/`:**

| File | Format | Approx Size | Notes |
|------|--------|-------------|-------|
| `favicon.svg` | SVG | 1–3 KB | Clean icon mark (no wordmark), viewBox preserved, `<title>Rulestead</title>` |
| `favicon.ico` | ICO | ~5 KB | 16×16 + 32×32 embedded; only raster binary allowed by hard constraint |
| `apple-touch-icon.png` | PNG | ~3–5 KB | 180×180; required for iOS home-screen pinning |

These are the only raster binaries that should enter the repo. Generate them once locally:

```bash
# Using Inkscape CLI (adjust paths)
inkscape favicon.svg --export-filename=favicon-32.png --export-width=32
# ICO from PNG pairs — use ImageMagick locally, commit result:
convert favicon-16.png favicon-32.png favicon.ico
```

---

## Social / OG Card

### Canonical dimensions: 1200×630 px

All major platforms (Facebook, X/Twitter large card, LinkedIn, Slack, Discord) use 1200×630 px as of 2026.

**Approach:** Commit `brandbook/social/og-card.svg` at `viewBox="0 0 1200 630"`. This is the authored source and renders correctly in any browser for preview.

Rasterize on demand when needed for platform upload:

```bash
# resvg (Rust, no Node dependency):
resvg brandbook/social/og-card.svg og-card.png -w 1200 -h 630
# OR via npx (Node):
npx svgexport brandbook/social/og-card.svg og-card.png 1200:630
```

Do NOT commit the PNG to the repo. The SVG is the source; the PNG is a build artifact. If Hex.pm or GitHub's social preview requires a static raster, generate in CI or document the one-liner for maintainers.

**SVG social card text:** Use outlined paths or embed font data URIs (woff2 base64) inside the SVG itself so it renders standalone without a `<link>` to Google Fonts. The social card is a standalone artifact, not a browser page.

---

## Font Licensing

All three typefaces are **SIL Open Font License 1.1** — confirmed against upstream source repositories:

| Font | Upstream | License | Binary in Repo? |
|------|----------|---------|-----------------|
| **Sora** | github.com/sora-xor/sora-font | OFL-1.1 | NO |
| **Inter** | github.com/rsms/inter | OFL-1.1 | NO |
| **IBM Plex Mono** | github.com/IBM/plex | OFL-1.1 | NO |

**OFL key terms (relevant facts, not legal advice):**

- Free to use, study, modify, and redistribute — including commercially
- May be bundled with software (including sold products)
- Cannot be sold as standalone fonts
- Derivative fonts using reserved font names are prohibited; derivatives must be renamed

**CDN reference (recommended for all `brandbook/` HTML specimens):**

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700&family=Inter:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">
```

**Do NOT commit:** `.ttf`, `.woff`, `.woff2`, `.otf`, or `.eot` files. The OFL permits it legally, but it violates the repo-light constraint and adds binary blob churn.

**If offline/air-gapped self-hosting is needed in future:** Document Fontsource as the path — `@fontsource/sora`, `@fontsource/inter`, `@fontsource/ibm-plex-mono` are all OFL-1.1 npm packages. Add guidance to `brandbook/FONTS.md` without committing binaries.

---

## Repo-Size Guard

### Strategy: prevention over remediation

| Layer | Mechanism | Threshold |
|-------|-----------|-----------|
| `.gitattributes` | Mark SVG/JSON/CSS as `text` (diffable); mark PNG/ICO as `binary`; mark font extensions as `binary` so size is obvious | — |
| Pre-commit script | `scripts/check_brand_assets.sh` — reject any font file, reject non-raster brandbook files >50 KB | 50 KB |
| CI step | `find brandbook/ -size +100k ! -name "*.ico" ! -name "*.png"` exits 1 on any match | 100 KB hard wall for non-raster |
| PR feedback (optional) | `lfs-warning` GitHub Action | 50 KB default |

**`.gitattributes` additions:**

```gitattributes
# Brand system — SVG/JSON/CSS are text (diffable, meaningful diffs)
brandbook/**/*.svg  text eol=lf
brandbook/**/*.json text eol=lf
brandbook/**/*.css  text eol=lf
brandbook/**/*.js   text eol=lf
# Raster exceptions (favicon + apple-touch only)
brandbook/**/*.png  binary
brandbook/**/*.ico  binary
# Font binaries are banned — mark so they stand out in size reports
*.ttf   binary
*.woff  binary
*.woff2 binary
*.otf   binary
*.eot   binary
```

**`scripts/check_brand_assets.sh` skeleton:**

```bash
#!/usr/bin/env bash
set -euo pipefail
LIMIT_BYTES=51200  # 50 KB

# Reject font binaries anywhere in the tree
if git diff --cached --name-only | grep -qE '\.(ttf|woff2?|otf|eot)$'; then
  echo "ERROR: Font binary files must not be committed." \
       "Reference via CDN or document Fontsource instead." >&2
  exit 1
fi

# Reject non-raster brandbook files over 50 KB
while IFS= read -r file; do
  if [[ -f "$file" ]]; then
    size=$(wc -c < "$file")
    if [[ $size -gt $LIMIT_BYTES ]]; then
      echo "ERROR: $file is ${size} bytes (limit: ${LIMIT_BYTES})" >&2
      exit 1
    fi
  fi
done < <(git diff --cached --name-only | grep '^brandbook/' | grep -vE '\.(png|ico)$')

echo "Brand asset size check passed."
```

Add as a pre-commit hook or call from the existing CI workflow.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|------------------------|
| Hand-authored `tokens.json` + `tokens.css` | Style Dictionary v5 build | Use Style Dictionary if multi-platform output (iOS Swift, Android XML, JS constants) is needed — not the case for this milestone |
| SVGO v4 CLI via `npx` | SVGR, Vite SVG plugin | Use SVGR/Vite only inside a React/Vue app — not applicable to a static `brandbook/` folder |
| Google Fonts CDN for specimen HTML | Fontsource npm packages | Use Fontsource if admin UI or docs site adds a Node build step and wants self-hosted fonts |
| `favicon.svg` + `favicon.ico` (16+32) + `apple-touch-icon.png` | Full PWA icon suite (192, 512, maskable) | Full suite only if Rulestead adds a PWA manifest — out of scope for v1.14 |
| `og-card.svg` source, rasterize on demand | Commit `og-card.png` | Commit PNG only if a platform definitively requires it and the file is <300 KB |
| Hand-written `check_brand_assets.sh` | `size-limit` npm tool | `size-limit` is JS-bundle focused; a shell script is idiomatic for this repo's tooling pattern |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Committing `.woff`, `.woff2`, `.ttf`, `.otf` | Binary blob churn, repo bloat — OFL does not require it | Google Fonts CDN reference or Fontsource documentation |
| Style Dictionary as a mandatory `brandbook/` build step | Adds a Node.js toolchain dependency to a pure Elixir/Hex repo | Hand-authored `tokens.css` mirroring `tokens.json` |
| Figma plugin token exports committed verbatim | Figma export format produces proprietary metadata noise; goes stale when design changes | Hand-author `tokens.json` from brand book values; Figma is the design source, not the token source |
| `removeViewBox: true` in SVGO | Destroys SVG scalability | Leave at SVGO v4 default (`false`) |
| `<text font-family="...">` in committed logo/icon SVGs | Renders incorrectly when font is not loaded | Outline text on export |
| Generating `og-card.png` via headless Chrome/Puppeteer in CI | Heavy CI dependency for a static brand artifact | `resvg` CLI (Rust, no Node dependency) or generate once locally |
| Embedding full font data URIs in `tokens.css` | Massively inflates file size; wrong layer | Keep fonts separate from token CSS |
| DTCG Resolver module features (theming modes via `$resolvers`) | The Resolver module is still a draft in the 2025.10 release cycle | Use explicit alias groups (`semantic.color.light.*` / `semantic.color.dark.*`) for now |

---

## Integration with Existing `--rs-*` CSS

`brandbook/tokens.css` is the **brand reference layer** (`:root` scope, portable primitives). `rulestead_admin/priv/static/css/rulestead_admin.css` is the **mounted admin theme layer** (`.rs-shell` / `[data-rulestead]` scope, four cascade blocks, semantic roles).

The two files remain **independent** — no `@import` coupling. The admin ships as a Hex package asset and must be self-contained.

The v1.14 re-skin task is: update the color literal values in the four cascade blocks of `rulestead_admin.css` to match the brand book mineral palette (e.g., `#3A6F8F` Stead Blue replaces `#2563eb`; `#B96A3A` Ember Copper replaces `#9a3f12`) while keeping `check_synced_pair.py` green and WCAG-AA contrast passing in both themes.

---

## Version Compatibility

| Package | Version | Notes |
|---------|---------|-------|
| SVGO | v4.0.1 | Requires Node ≥18; `svgo.config.mjs` (ESM only in v4) |
| DTCG spec | 2025.10 stable | File extension `.tokens.json` or `.tokens`; `$value`/`$type` keys |
| Style Dictionary (if added later) | v5.4.x | Full 2025.10 DTCG Resolver support WIP; v4.x covers pre-2025.10 DTCG |
| Tailwind CSS v4 `@theme` | v4.x | CSS-first config; `@theme {}` block in CSS file replaces `tailwind.config.js` |
| Tailwind CSS v3 `theme.extend` | v3.x | Still valid JS config for adopters on v3 |

---

## Sources

- [DTCG Design Tokens Format Module 2025.10](https://www.designtokens.org/tr/drafts/format/) — spec structure, file extensions, alias syntax — HIGH confidence (official spec)
- [DTCG first stable version announcement 2025-10-28](https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/) — HIGH confidence
- [Style Dictionary DTCG support page](https://styledictionary.com/info/dtcg/) — v4 first-class DTCG; v5 working toward 2025.10 Resolver — HIGH confidence (official docs)
- [style-dictionary npm](https://www.npmjs.com/package/style-dictionary) — current latest v5.4.x — HIGH confidence
- [SVGO GitHub Releases](https://github.com/svg/svgo/releases) — v4.0.1 latest; `removeViewBox`/`removeTitle` disabled by default in v4 — HIGH confidence
- [SVGO preset-default docs](https://svgo.dev/docs/preset-default/) — plugin list — HIGH confidence (official docs)
- [Sora OFL.txt](https://github.com/sora-xor/sora-font/blob/master/OFL.txt) — SIL OFL 1.1 confirmed — HIGH confidence
- [Inter LICENSE.txt](https://github.com/rsms/inter/blob/master/LICENSE.txt) — SIL OFL 1.1 confirmed — HIGH confidence
- [IBM Plex on Fontsource](https://fontsource.org/fonts/ibm-plex-mono) — OFL-1.1 confirmed — HIGH confidence
- [Favicon best practices 2025](https://browserux.com/blog/guides/web-icons/favicons-best-practices.html) — SVG + ICO + apple-touch-icon strategy — MEDIUM confidence (community source, consistent across multiple references)
- [Tailwind CSS v4 announcement](https://tailwindcss.com/blog/tailwindcss-v4) — `@theme` CSS-first config — HIGH confidence (official)
- [lfs-warning GitHub Action](https://github.com/ppremk/lfs-warning) — per-file size threshold — MEDIUM confidence
- Direct read of `rulestead_admin/priv/static/css/rulestead_admin.css` — `--rs-*` token shape and four-block cascade — HIGH confidence

---

*Stack research for: v1.14 Brand System Realization — design tokens, SVG hygiene, font licensing, repo-size guard*
*Researched: 2026-06-04*

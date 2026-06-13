# Phase 99: Specimens — Pattern Map

**Mapped:** 2026-06-05
**Files analyzed:** 6 new SVG specimen files
**Analogs found:** 6 / 6 (all have strong role-match analogs from Phase 97 logo lockup set)

---

## File Classification

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `brandbook/assets/specimens/palette.svg` | static brand specimen | transform (tokens.json → hex literals in SVG) | `brandbook/assets/logo/rs-mark.svg` | role-match |
| `brandbook/assets/specimens/typography.svg` | static brand specimen | transform (tokens.css type scale → live `<text>` SVG) | `brandbook/assets/logo/rs-wordmark.svg` | partial (live text NOT used in logos; pattern inverted here) |
| `brandbook/assets/specimens/components.svg` | static brand specimen | transform (rulestead_admin.css var-resolved → hex literals in SVG) | `brandbook/assets/logo/rs-mark.svg` | role-match |
| `brandbook/assets/specimens/code-block.svg` | static brand specimen | transform (mineral dark palette → hex literals in SVG) | `brandbook/assets/logo/rs-mark.svg` | role-match |
| `brandbook/assets/specimens/readme-header.svg` | static brand specimen | transform (rs-mark geometry + tagline → self-contained SVG) | `brandbook/assets/logo/rs-wordmark.svg` | exact (same mark geometry reused inline) |
| `brandbook/assets/specimens/social-card.svg` | static brand specimen | transform (rs-social-card layout reference + token annotations → SVG) | `brandbook/assets/logo/rs-social-card.svg` | exact (same layout, distinct file) |

---

## Shared Patterns

### Accessible SVG Skeleton
**Source:** `brandbook/assets/logo/rs-mark.svg` (line 1), `brandbook/assets/logo/rs-wordmark.svg` (line 1), `brandbook/assets/logo/rs-social-card.svg` (line 1)
**Apply to:** All 6 specimen files

Two `aria-labelledby` ID conventions appear in the logo set:
- `rs-mark.svg` uses `aria-labelledby="rs-mark-title rs-mark-desc"` with `id="rs-mark-title"` / `id="rs-mark-desc"` — long-form IDs
- `rs-wordmark.svg` and `rs-social-card.svg` use `aria-labelledby="t d"` with `id="t"` / `id="d"` — short-form IDs (SVGO-safe; `cleanupIds: false` in config preserves both)

Use short-form for specimens (matches the two more recent logo files):

```xml
<!-- Source: brandbook/assets/logo/rs-wordmark.svg line 1 -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 WIDTH HEIGHT"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — [Specimen Name]</title>
  <desc id="d">[One-sentence description of what the specimen shows.]</desc>
  <g aria-hidden="true">
    <!-- all visual content here -->
  </g>
</svg>
```

**Constraints:**
- `role="img"` on root SVG element (present in all 3 logo analogs)
- `<title>` and `<desc>` linked via `aria-labelledby` (required — SVGO config preserves these)
- All content inside `<g aria-hidden="true">` (present in all 3 logo analogs)
- NO `<script>`, NO event handler attributes, NO base64, NO external `<use href="...">` references

### SVGO Optimization Config
**Source:** `brandbook/assets/logo/svgo.config.mjs` (lines 1–27)
**Apply to:** All 6 specimen files (run after authoring, before commit)

```js
// Source: brandbook/assets/logo/svgo.config.mjs lines 11–27
export default {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          removeDesc: false,       // MUST keep <desc> for screen readers
          cleanupIds: false,       // keep IDs used by aria-labelledby
          convertColors: false,    // keep hex literals as-is; no color normalization
        },
      },
    },
  ],
};
```

Invocation (from repo root):
```bash
npx svgo --config brandbook/assets/logo/svgo.config.mjs brandbook/assets/specimens/FILENAME.svg
```

### Hard-Coded Hex Literals (No var())
**Source:** `brandbook/tokens.json` (all primitive.* and admin_css_mapping sections)
**Apply to:** All 6 specimen files

Specimens are standalone SVG files, not inside `.rs-shell` scope. All fills must be hex literals.

Key resolved values extracted from `brandbook/tokens.json`:

| Token name | Light hex | Dark hex |
|------------|-----------|----------|
| `--rs-primary` / stead-blue.base | `#3A6F8F` | `#5885a0` |
| `--rs-accent` / ember-copper.base | `#9b5931` | `#ba6b3c` |
| ink-blue.base | `#183247` | — |
| slate-stead.base | `#24313D` | — |
| basalt.base | `#0F1720` | — |
| signal-gold.base (decorative-only) | `#D2A94E` | — |
| moss-grey.canonical | `#606d66` | `#75827b` |
| stone-mist.base | `#E8ECE8` | — |
| rain-tint.base | `#F5F7F6` | — |
| quarry.base | `#C4CCD1` | — |
| success.canonical | `#2d7753` | `#488d6b` |
| danger.canonical | `#b04848` | `#bf6464` |
| danger.white-rt (on white/rain-tint) | `#B44949` | — |
| warning.canonical | `#8f601a` | `#B57A21` |
| info.base | `#356E8C` | `#55859e` |
| `--rs-neutral-0` (light) | `#ffffff` | `#10161f` |
| `--rs-neutral-25` | `#f8fafc` | `#141c27` |
| `--rs-neutral-50` | `#f4f6f8` | `#19222e` |
| `--rs-neutral-100` | `#eef1f5` | `#1f2a38` |
| `--rs-neutral-200` | `#e7ebf0` | `#253243` |
| `--rs-neutral-300` | `#d8dee6` | `#2e3d52` |
| `--rs-neutral-400` | `#b8c2cf` | `#3d5168` |
| `--rs-neutral-500` | `#99a3af` | `#7a8fa3` |
| `--rs-neutral-600` | `#5c6b7a` | `#a8b9ca` |
| `--rs-neutral-900` | `#1a2332` | `#e8edf3` |

### Size Budget Gate
**Source:** `scripts/ci/lint.sh` (lines 41–48)
**Apply to:** All 6 specimen files (CI gate; authors must verify before commit)

```bash
# Source: scripts/ci/lint.sh lines 41–48 (exact)
for f in "${RULESTEAD_REPO}/brandbook/assets/specimens/"*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 51200 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 51200)"
    exit 1
  fi
done
echo "SVG SIZE BUDGET OK"
```

Threshold: `51200` bytes (50 × 1024). NOT 50,000 (decimal). Files must be SVGO-optimized before checking. `shopt -s nullglob` (lint.sh line 33) means the loop silently passes if the `specimens/` directory does not exist — create the directory first.

---

## Pattern Assignments

### `brandbook/assets/specimens/palette.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-mark.svg`

**Accessible SVG header pattern** (rs-mark.svg line 1 — short-form IDs from rs-wordmark.svg):
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 860 520"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Palette Specimen</title>
  <desc id="d">Brand color palette swatches with hex values and token names.</desc>
  <g aria-hidden="true">
    <!-- swatches go here -->
  </g>
</svg>
```

**Swatch geometry pattern** (derived from rs-mark.svg rect/circle primitives — same `rx`, `fill` literal approach):
```xml
<!-- Source: Pattern 2 from RESEARCH.md, anchored to rs-mark.svg fill literal convention -->
<!-- Swatch: chip 112×48px, rx="6" (--rs-radius-sm), label area below -->
<rect x="24" y="40" width="112" height="48" fill="#3A6F8F" rx="6"/>
<text x="32" y="106" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#1a2332">#3A6F8F</text>
<text x="32" y="117" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="8" fill="#5c6b7a">stead-blue.base</text>
```

**Fill values:** Use hex literals from `brandbook/tokens.json` `primitive.*` section. No `var()`.

**Anti-pattern to avoid:** `fill="var(--rs-primary)"` — renders black outside `.rs-shell` scope.

---

### `brandbook/assets/specimens/typography.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-wordmark.svg` (inverted pattern — wordmark uses outlined paths; typography.svg uses live `<text>` elements because outlined paths for a full type ramp would exceed 50 KB)

**Accessible SVG header** (same skeleton as all specimens):
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 760 580"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Typography Specimen</title>
  <desc id="d">Type scale ramp showing Sora, Inter, and IBM Plex Mono at each --rs-text-* size with weight and role labels.</desc>
  <g aria-hidden="true">
    <!-- type rows here -->
  </g>
</svg>
```

**Live `<text>` pattern** (font-family stacks from `brandbook/tokens.css` lines 27–29):
```xml
<!-- Source: brandbook/tokens.css :root block lines 27–29 for font-family values -->
<!-- --rs-font-display: "Sora", "Inter", ui-sans-serif, system-ui, sans-serif -->
<!-- --rs-font-sans:   "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif -->
<!-- --rs-font-mono:   "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, monospace -->

<!-- Row structure: specimen text + label row -->
<!-- --rs-text-2xl = clamp(1.5rem, 2vw, 2rem) — render at 32px in SVG -->
<text x="24" y="60"
      font-family="Sora, Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="32" font-weight="700" fill="#1a2332">The quick brown fox</text>
<text x="24" y="75"
      font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#5c6b7a">--rs-text-2xl · Sora · 700 · --rs-leading-tight</text>
```

**Type scale pixel approximations** (from `brandbook/tokens.css` lines 32–39, rendered as fixed px in SVG):

| Token | CSS value | SVG px approx |
|-------|-----------|---------------|
| `--rs-text-2xl` | clamp(1.5rem, 2vw, 2rem) | 32 |
| `--rs-text-xl` | 1.4rem | 22 |
| `--rs-text-lg` | 1.15rem | 18 |
| `--rs-text-md` | 1.05rem | 17 |
| `--rs-text-base` | 0.95rem | 15 |
| `--rs-text-sm` | 0.86rem | 14 |
| `--rs-text-xs` | 0.78rem | 12 |
| `--rs-text-2xs` | 0.72rem | 11 |

**Critical constraint:** Do NOT use fontTools to outline glyphs for this specimen — would exceed 50 KB. Logo LOGO-04 outlined-text requirement applies ONLY to files in `brandbook/assets/logo/`, not specimens.

---

### `brandbook/assets/specimens/components.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-mark.svg` (same rect/circle geometry; same hex-literal fills)
**Secondary analog:** `rulestead_admin/priv/static/css/rulestead_admin.css` lines 598–730 (button shapes), 1574–1585 (card shapes), 2646–2730 (badge shapes) — resolve var() to hex before writing SVG

**Accessible SVG header:**
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 800 560"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Components Specimen</title>
  <desc id="d">Buttons (default, primary, danger, text), card, and badge variants in light mode mineral palette.</desc>
  <g aria-hidden="true">
    <!-- components here -->
  </g>
</svg>
```

**Button geometry** (from `rulestead_admin.css` lines 617–682, var() resolved via `tokens.json admin_css_mapping.light`):
```xml
<!-- Default button: border #d8dee6, bg #f4f6f8, text #1a2332, radius 6px, h ~40px -->
<rect x="24" y="40" width="120" height="40" fill="#f4f6f8" stroke="#d8dee6"
      stroke-width="1" rx="6"/>
<text x="84" y="65" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="14" font-weight="500" fill="#1a2332" text-anchor="middle">Default</text>

<!-- Primary button: bg #3A6F8F, text #ffffff, radius 6px -->
<rect x="160" y="40" width="120" height="40" fill="#3A6F8F" rx="6"/>
<text x="220" y="65" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="14" font-weight="500" fill="#ffffff" text-anchor="middle">Primary</text>

<!-- Danger button: border #fca5a5, bg #fee2e2, text #B44949, radius 6px -->
<rect x="296" y="40" width="120" height="40" fill="#fee2e2" stroke="#fca5a5"
      stroke-width="1" rx="6"/>
<text x="356" y="65" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="14" font-weight="500" fill="#B44949" text-anchor="middle">Danger</text>

<!-- Text button: no border, color #3A6F8F, underline -->
<text x="440" y="65" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="14" font-weight="600" fill="#3A6F8F"
      text-decoration="underline">Text link</text>
```

**Card geometry** (from `rulestead_admin.css` lines 1574–1585, var() resolved):
```xml
<!-- Card: bg #ffffff, border #d8dee6, radius 14px (--rs-radius-lg) -->
<rect x="24" y="110" width="360" height="120" fill="#ffffff" stroke="#d8dee6"
      stroke-width="1" rx="14"/>
```

**Badge geometry** (from `rulestead_admin.css` lines 2646–2730, var() resolved):
```xml
<!-- Badge neutral: bg #eef1f5, border #d8dee6, text #5c6b7a, radius-full -->
<rect x="24" y="260" width="72" height="22" fill="#eef1f5" stroke="#d8dee6"
      stroke-width="1" rx="999"/>
<text x="60" y="275" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="10" font-weight="600" fill="#5c6b7a" text-anchor="middle">neutral</text>

<!-- Badge positive: bg #dcfce7, border #86efac, text #2d7753 -->
<rect x="108" y="260" width="72" height="22" fill="#dcfce7" stroke="#86efac"
      stroke-width="1" rx="999"/>

<!-- Badge warning: bg #fef3c7, border #fcd34d, text #8f601a -->
<rect x="192" y="260" width="72" height="22" fill="#fef3c7" stroke="#fcd34d"
      stroke-width="1" rx="999"/>

<!-- Badge critical: bg #fee2e2, border #fca5a5, text #B44949 -->
<rect x="276" y="260" width="72" height="22" fill="#fee2e2" stroke="#fca5a5"
      stroke-width="1" rx="999"/>

<!-- Badge accent/draft: bg #fde8dc, border #9b5931, text #9b5931 -->
<rect x="360" y="260" width="72" height="22" fill="#fde8dc" stroke="#9b5931"
      stroke-width="1" rx="999"/>
```

---

### `brandbook/assets/specimens/code-block.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-mark.svg` (same accessible SVG skeleton, rect geometry, hex fills)

**Accessible SVG header:**
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 680 280"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Code Block Specimen</title>
  <desc id="d">Code block specimen showing Rulestead Elixir API on mineral dark background with IBM Plex Mono.</desc>
  <g aria-hidden="true">
    <!-- code block here -->
  </g>
</svg>
```

**Code block geometry** (hex values from `brandbook/tokens.json` `primitive.neutral-ramp` dark section):
```xml
<!-- Source: tokens.json primitive.neutral-ramp dark-0=#10161f, dark-50=#19222e, dark-600=#a8b9ca, dark-900=#e8edf3 -->
<!-- Container: mineral dark base #10161f, radius 10px -->
<rect x="0" y="0" width="680" height="280" fill="#10161f" rx="10"/>
<!-- Header bar: dark-50 #19222e (slightly lighter) -->
<rect x="0" y="0" width="680" height="36" fill="#19222e" rx="10"/>
<rect x="0" y="18" width="680" height="18" fill="#19222e"/>
<!-- Filename label in header -->
<text x="20" y="23" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="11" fill="#7a8fa3">feature_flags.ex</text>
<!-- Code lines: IBM Plex Mono -->
<!-- comment: dark-600 #a8b9ca (muted) -->
<text x="20" y="70" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="12" fill="#a8b9ca"># Evaluate a feature flag</text>
<!-- keyword (ok atom): primary dark #5885a0 -->
<!-- string/value: accent dark #ba6b3c -->
<!-- base text: dark-900 #e8edf3 -->
<text x="20" y="90" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="12" fill="#e8edf3">{:ok, result} = Rulestead.evaluate(:dark_mode, ctx)</text>
```

**Syntax color palette** (all from `brandbook/tokens.json` dark neutral ramp + brand tokens):
- Background: `#10161f` (dark-0)
- Header bar: `#19222e` (dark-50)
- Base text: `#e8edf3` (dark-900)
- Comments / muted: `#a8b9ca` (dark-600)
- Keywords / primary accents: `#5885a0` (stead-blue.dark)
- String / value accents: `#ba6b3c` (ember-copper.dark)
- Placeholder / line numbers: `#7a8fa3` (dark-500)

---

### `brandbook/assets/specimens/readme-header.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-wordmark.svg` (exact — reuse the inline mark `<g>` contents from rs-wordmark.svg line 1)

**Accessible SVG header:**
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 480 96"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — README Header</title>
  <desc id="d">README header mock showing the Rulestead mark and wordmark with tagline: Runtime decisions, made clear.</desc>
  <g aria-hidden="true">
    <!-- mark + wordmark + tagline here -->
  </g>
</svg>
```

**Mark geometry to inline** (copy verbatim from `brandbook/assets/logo/rs-mark.svg` line 1 `<g aria-hidden="true">` contents):
```xml
<!-- Source: brandbook/assets/logo/rs-mark.svg line 1 — exact geometry, scaled to 64×64 -->
<rect width="7.5" height="39.5" x="30" y="13" fill="#3a6f8f" rx="1"/>
<rect width="20" height="7.5" x="12" y="28.25" fill="#3a6f8f" rx="1"/>
<circle cx="12" cy="32" r="6.5" fill="#3a6f8f"/>
<rect width="14" height="7.5" x="32" y="12.25" fill="#9b5931" rx="1"/>
<circle cx="50" cy="16" r="6.5" fill="#9b5931"/>
<rect width="14" height="7.5" x="32" y="28.25" fill="#3a6f8f" rx="1"/>
<circle cx="50" cy="32" r="6.5" fill="#c4ccd1"/>
<rect width="14" height="7.5" x="32" y="44.25" fill="#3a6f8f" rx="1"/>
<circle cx="50" cy="48" r="6.5" fill="#c4ccd1"/>
```

**Wordmark text** (use live `<text>` — this is a specimen, not a logo distribution file; LOGO-04 outlined-text rule is logo-only):
```xml
<!-- Wordmark text: Sora Bold, Ink Blue #183247 (matches rs-wordmark.svg fill="#183247" paths) -->
<text x="80" y="44" font-family="Sora, Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="32" font-weight="700" fill="#183247">Rulestead</text>
<!-- Tagline: muted neutral-600 #5c6b7a -->
<text x="80" y="68" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="14" font-weight="400" fill="#5c6b7a">Runtime decisions, made clear.</text>
```

**Note on mark colors:** The README header specimen uses the light-mode mark colors (`#3a6f8f` Stead Blue, `#9b5931` Ember Copper, `#c4ccd1` Quarry) — same as `rs-mark.svg`. The social card uses dark-mode colors (`#5885a0`). Do not swap them.

---

### `brandbook/assets/specimens/social-card.svg` (static brand specimen, transform)

**Analog:** `brandbook/assets/logo/rs-social-card.svg` (exact layout reference — same viewBox, background, mark transform, wordmark path data; adds token-name annotations)

**Critical distinction:** `brandbook/assets/logo/rs-social-card.svg` is the Phase 97 production asset used for OG/Twitter meta tags. This specimen in `brandbook/assets/specimens/social-card.svg` is a NEW file — a design reference that annotates the layout. Never modify the logo-lockup file.

**Accessible SVG header** (same pattern as rs-social-card.svg line 1, with distinct IDs and title):
```xml
<!-- Source: brandbook/assets/logo/rs-social-card.svg line 1 — same structure -->
<svg xmlns="http://www.w3.org/2000/svg"
     width="1200" height="630"
     viewBox="0 0 1200 630"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Social Card Specimen</title>
  <desc id="d">Social card design reference (1200×630). Ink Blue background with mark, wordmark, and tagline. Annotated with key token names.</desc>
  <g aria-hidden="true">
    <!-- background, mark, wordmark, tagline, token annotations -->
  </g>
</svg>
```

**Background fill** (from `brandbook/assets/logo/rs-social-card.svg` line 1 — `fill="#183247"`):
```xml
<!-- Source: rs-social-card.svg — background path fill -->
<path fill="#183247" d="M0 0h1200v630H0z"/>
```

**Mark geometry** (from `rs-social-card.svg` line 1 — 4× scale transform, dark-mode mark color `#5885a0`):
```xml
<!-- Source: rs-social-card.svg line 1 — copy this transform + mark geometry exactly -->
<g transform="matrix(4 0 0 4 120 187)">
  <rect width="7.5" height="39.5" x="30" y="13" fill="#5885a0" rx="1"/>
  <rect width="20" height="7.5" x="12" y="28.25" fill="#5885a0" rx="1"/>
  <circle cx="12" cy="32" r="6.5" fill="#5885a0"/>
  <rect width="14" height="7.5" x="32" y="12.25" fill="#9b5931" rx="1"/>
  <circle cx="50" cy="16" r="6.5" fill="#9b5931"/>
  <rect width="14" height="7.5" x="32" y="28.25" fill="#5885a0" rx="1"/>
  <circle cx="50" cy="32" r="6.5" fill="#c4ccd1"/>
  <rect width="14" height="7.5" x="32" y="44.25" fill="#5885a0" rx="1"/>
  <circle cx="50" cy="48" r="6.5" fill="#c4ccd1"/>
</g>
```

**Wordmark + tagline** (specimen may use live `<text>` — specimen is a design reference, not a distribution asset; the wordmark outlined paths from `rs-social-card.svg` may also be copied verbatim for fidelity):

Option A — copy outlined paths from `rs-social-card.svg` (pixel-perfect, large but within 50 KB after SVGO):
The `<g fill="#e8edf3" transform="matrix(3 0 0 3 444 195)">` block in `rs-social-card.svg` contains the wordmark outlined paths at 3× scale. Copy this block verbatim.

Option B — live `<text>` for the specimen (smaller, acceptable for design reference):
```xml
<text x="444" y="310" font-family="Sora, Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="84" font-weight="700" fill="#e8edf3">Rulestead</text>
<text x="444" y="400" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="40" font-weight="400" fill="#e8edf3" opacity="0.7">Runtime decisions, made clear.</text>
```

**Token annotation labels** (per RESEARCH.md Pattern 7 / Option A recommendation — minimal annotations):
```xml
<!-- Small token label below background fill area -->
<text x="36" y="580" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="16" fill="#e8edf3" opacity="0.5">bg: #183247 · ink-blue.base</text>
```

---

## No Analog Found

All 6 files have analogs. No entries in this section.

---

## Key Resolved Hex Values for Component Specimen

Resolved from `brandbook/tokens.json` `admin_css_mapping.light` (lines 305–345):

| var() reference in admin CSS | Resolved hex |
|------------------------------|-------------|
| `var(--rs-surface)` (= neutral-50) | `#f4f6f8` |
| `var(--rs-surface-muted)` (= neutral-100) | `#eef1f5` |
| `var(--rs-surface-faint)` (= neutral-25) | `#f8fafc` |
| `var(--rs-border)` (= neutral-300) | `#d8dee6` |
| `var(--rs-border-subtle)` (= neutral-200) | `#e7ebf0` |
| `var(--rs-border-strong)` (= neutral-400) | `#b8c2cf` |
| `var(--rs-text)` (= neutral-900) | `#1a2332` |
| `var(--rs-text-muted)` (= neutral-600) | `#5c6b7a` |
| `var(--rs-text-placeholder)` (= neutral-500) | `#99a3af` |
| `var(--rs-primary)` | `#3A6F8F` |
| `var(--rs-on-primary)` | `#ffffff` |
| `var(--rs-accent)` | `#9b5931` |
| `var(--rs-accent-soft)` | `#fde8dc` |
| `var(--rs-error)` / `--rs-critical` | `#B44949` |
| `var(--rs-error-soft)` | `#fee2e2` |
| `var(--rs-error-border)` | `#fca5a5` |
| `var(--rs-success)` | `#2d7753` |
| `var(--rs-success-soft)` | `#dcfce7` |
| `var(--rs-success-border)` | `#86efac` |
| `var(--rs-warning)` | `#8f601a` |
| `var(--rs-warning-soft)` | `#fef3c7` |
| `var(--rs-warning-border)` | `#fcd34d` |

---

## Metadata

**Analog search scope:** `brandbook/assets/logo/`, `brandbook/tokens.json`, `brandbook/tokens.css`, `rulestead_admin/priv/static/css/rulestead_admin.css`, `scripts/ci/lint.sh`
**Files scanned:** 7 (rs-mark.svg, rs-wordmark.svg, rs-social-card.svg, svgo.config.mjs, tokens.json, tokens.css, rulestead_admin.css, lint.sh)
**Pattern extraction date:** 2026-06-05

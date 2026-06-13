# Phase 99: Specimens — Research

**Researched:** 2026-06-05
**Domain:** SVG authoring, design-system specimens, font handling, SVGO optimization
**Confidence:** HIGH

---

## Summary

Phase 99 commits six reproducible SVG specimens to `brandbook/assets/specimens/` — palette,
typography, components, code-block, README header, and social card — all ≤50 KB each, all
lint-passing. Every upstream artifact Phase 99 depends on is already committed and verified:
tokens.json (Phase 96), tokens.css (Phase 96), the 7-SVG logo lockup set (Phase 97), and the
re-skinned admin CSS (Phase 98).

The key authoring decision is **hand-authored SVGs with hard-coded hex literals sourced
directly from `brandbook/tokens.json`**. This is the same approach used in Phase 97 for the
logo lockup set. There is no generator script for specimens — they are source-of-truth
committed files, not outputs of a build step. Reproducibility means: the SVGs are committed in
their final optimized state; any agent can reproduce the content by following the same
token-sourcing rules. A generator script (like Phase 101's `gen_brandbook_html.*`) is
explicitly NOT required for Phase 99 — the REQUIREMENTS.md wording is "reproducible SVG
specimens exist", which in context means "hand-authored from canonical sources, committed,
auditable" (the contrast with Phase 101, which explicitly requires a committed generator, makes
this clear). [CITED: .planning/REQUIREMENTS.md SPEC-01, SPEC-02]

The dominant technical constraint is **font handling in typography.svg**. The v1.14 font
policy prohibits committed font binaries and the exec environment cannot reach Google Fonts CDN
reliably (Phase 97 hit urllib hang; curl works but CDN may still be unreachable at authoring
time). For the logo wordmark, Phase 97 solved this by outlining glyphs to paths via fontTools.
For typography.svg (a type ramp showing Sora/Inter/IBM Plex Mono at multiple sizes), outlining
every glyph would produce a massive SVG well over 50 KB. The correct approach is to use live
`<text>` elements with `font-family` referencing the system fallbacks (`"Sora", "Inter",
ui-sans-serif, system-ui, sans-serif` etc.) so the specimen renders correctly when viewed in a
browser. The type-ramp specimen is not a browser-agnostic distribution artifact — it is a
reference document consumed by the Phase 101 HTML brand book and by developers with web fonts
available. This approach keeps typography.svg well under 50 KB and is consistent with how the
Phase 97 logo-studio.html handled fonts (Google Fonts `<link>` with live `<text>`). Typography.svg
is NOT a logo — LOGO-04's "outlined text" requirement applies only to the logo lockup files.

The six specimens follow a clear authoring pattern derived from the Phase 97 logo-studio.html:
hard-coded hex values from `brandbook/tokens.json` primitive and admin_css_mapping sections,
font-family references matching the `--rs-font-*` tokens in tokens.css, geometric SVG primitives
(rect/circle/text/path) with no embedded raster, accessible title/desc/role=img, SVGO-optimized
with the existing `svgo.config.mjs`.

The `social-card.svg` specimen is a NEW file in `brandbook/assets/specimens/` — it is distinct
from `brandbook/assets/logo/rs-social-card.svg` (the existing OG/Twitter card in the logo
lockup set). The specimen social-card.svg demonstrates the brand social card layout as a design
reference, while `rs-social-card.svg` is the production asset. Both exist; they do not conflict.

**Primary recommendation:** Hand-author all six SVG specimens directly using hard-coded hex
values from `brandbook/tokens.json`; use live `<text>` elements (not outlined paths) for the
type ramp specimen; optimize with `npx svgo --config brandbook/assets/logo/svgo.config.mjs`;
commit; verify with the lint.sh size-budget loop.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPEC-01 | Reproducible SVG specimens exist for the color palette and the typography system | `palette.svg` hand-authored from `tokens.json` primitive section; `typography.svg` hand-authored with `--rs-font-*` families + token-labeled size scale from `tokens.css :root` invariant block |
| SPEC-02 | Reproducible SVG specimens exist for core UI components (buttons/cards/badges), a code block, a README header mock, and a social card | `components.svg` reflects `rulestead_admin.css` button/card/badge shapes; `code-block.svg` shows IBM Plex Mono code with mineral dark background; `readme-header.svg` embeds rs-wordmark geometry + tagline; `social-card.svg` distinct from existing `rs-social-card.svg` logo lockup |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| palette.svg | `brandbook/assets/specimens/` | — | Static design reference; hard-coded hex values from tokens.json |
| typography.svg | `brandbook/assets/specimens/` | — | Static reference; `<text>` elements with font-family from tokens.css invariant block |
| components.svg | `brandbook/assets/specimens/` | — | Mirrors shapes/colors from rulestead_admin.css components |
| code-block.svg | `brandbook/assets/specimens/` | — | Illustrative; IBM Plex Mono code on mineral dark background |
| readme-header.svg | `brandbook/assets/specimens/` | — | Reuses rs-wordmark mark geometry inline; adds tagline text |
| social-card.svg | `brandbook/assets/specimens/` | — | Separate from logo-lockup rs-social-card.svg; a design reference specimen |
| SVGO optimization | brandbook authoring step | `brandbook/assets/logo/svgo.config.mjs` | Same config reused; run at authoring time, not CI |
| Size-budget gate | `scripts/ci/lint.sh` | — | Existing loop already covers `brandbook/assets/specimens/*.svg` |

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| SVG (hand-authored) | SVG 1.1 / 2.0 | All six specimen files | No build tools; reviewable diffs; zero external deps |
| `npx svgo` | 4.0.1 [VERIFIED: npm registry] | Optimize specimen SVGs post-authoring | Confirmed at `npx svgo --version` = 4.0.1; already used by Phase 97 |
| Python 3.14 | 3.14.4 [VERIFIED: `python3 --version`] | Optional: gen script for any computed content | Already in PATH at `/opt/homebrew/bin/python3` |
| fontTools | 4.62.1 [VERIFIED: pip + import test] | NOT needed for specimens — only for outlined wordmark glyphs (done in Phase 97) | Available if needed; not required for type-ramp `<text>` approach |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `brandbook/assets/logo/svgo.config.mjs` | Phase 97 committed | SVGO config that preserves `<title>`, `<desc>`, `aria-labelledby` IDs, and `fill="currentColor"` | Reuse for all specimen SVGO runs — do not create a separate config |
| `brandbook/tokens.json` | Phase 96 committed | Canonical hex values for specimen colors | Source of truth for all swatch fills and labels |
| `brandbook/tokens.css` | Phase 96 committed | Font-family and type-scale token values | Source for `--rs-font-*`, `--rs-text-*`, radius, spacing values shown in specimens |

### No New Package Installation Required

Phase 99 installs no npm or pip packages. `npx svgo` is invoked ad-hoc (no `package.json`
needed). fontTools is already present but is not needed for this phase.

---

## Package Legitimacy Audit

> Phase 99 installs zero new packages. The only external tool invoked is `npx svgo` (existing,
> already audited in Phase 97).

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| svgo | npm | 12+ years (2012-09-27) | Very high | github.com/svg/svgo | N/A (Phase 97 audited; slopcheck unavailable — PyPI vs npm cross-ecosystem false positive documented) | Approved — npm registry `4.0.1` confirmed, 12-year track record |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*slopcheck was unavailable at research time (pip install failed). svgo is tagged [ASSUMED]
re: slopcheck verdict, but is verified [VERIFIED: npm registry] with 12-year track record and
was audited in Phase 97.*

---

## Architecture Patterns

### System Architecture Diagram

```
brandbook/tokens.json (DTCG 2025.10)
├── primitive.* hex values
└── admin_css_mapping.light / .dark
        │
        ▼ (manual: read canonical hexes)
        
brandbook/tokens.css (invariant block)
├── --rs-font-display / sans / mono
└── --rs-text-2xs … 2xl / radius / spacing
        │
        ▼ (manual: read type scale + families)

brandbook/assets/logo/rs-mark.svg + rs-wordmark.svg
        │
        ▼ (inline mark geometry in readme-header + social-card)

 ┌──────────────────────────────────────────────────────┐
 │         brandbook/assets/specimens/                  │
 │                                                      │
 │  palette.svg          ← tokens.json primitives       │
 │  typography.svg       ← tokens.css type scale        │
 │  components.svg       ← rulestead_admin.css shapes   │
 │  code-block.svg       ← mineral dark palette         │
 │  readme-header.svg    ← rs-mark geometry + tagline   │
 │  social-card.svg      ← rs-social-card layout ref    │
 └──────────────────────────────────────────────────────┘
        │
        ▼ (npx svgo --config brandbook/assets/logo/svgo.config.mjs)
        
SVGO-optimized committed SVGs
        │
        ▼
scripts/ci/lint.sh SVG size-budget loop
        └── all *.svg in specimens/ ≤ 51200 bytes → "SVG SIZE BUDGET OK"
```

### Recommended Project Structure

```
brandbook/
└── assets/
    └── specimens/
        ├── palette.svg          # all brand swatches with hex + token name
        ├── typography.svg       # Sora/Inter/IBM Plex Mono type ramp with token labels
        ├── components.svg       # buttons (default/primary/danger/text), card, badge variants
        ├── code-block.svg       # code block on mineral dark background, IBM Plex Mono
        ├── readme-header.svg    # README header mock with wordmark mark + tagline
        └── social-card.svg      # social card reference (1200×630 proportions)
```

### Pattern 1: Specimen SVG Skeleton (Accessible, No Raster)

**What:** Every specimen follows this accessibility and policy skeleton.
**When to use:** All six specimen files.

```xml
<!-- Source: Phase 97 logo lockup pattern; accessible SVG spec -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 WIDTH HEIGHT"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — [Specimen Name]</title>
  <desc id="d">[One-sentence description of what the specimen shows]</desc>
  <g aria-hidden="true">
    <!-- all visual content here — rect, circle, text, path -->
    <!-- NO base64, NO <image>, NO <use href="external"> -->
  </g>
</svg>
```

**Constraints enforced:**
- `grep -c 'base64' specimen.svg` must equal 0
- `role="img"` on root; `<title>` and `<desc>` linked via `aria-labelledby`
- All fills are hard-coded hex literals (not `var(--rs-*)`) — specimens are standalone files, not inside a `.rs-shell` scope

### Pattern 2: Palette Swatch Row

**What:** Colored rect + hex label + token name label for each brand color.
**Source:** tokens.json `primitive.*` section + `admin_css_mapping.light/dark`.

Swatch layout (per color):
```xml
<!-- chip height: 48px; label area: ~28px; total per swatch: 76px tall, ~120px wide -->
<rect x="X" y="Y" width="112" height="48" fill="#3A6F8F" rx="6"/>
<!-- hex label -->
<text x="X+8" y="Y+66" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#1a2332">#3A6F8F</text>
<!-- token name label -->
<text x="X+8" y="Y+76" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="8" fill="#5c6b7a">stead-blue.base</text>
```

**Palette to include (from `tokens.json` primitive):**
- Stead Blue `#3A6F8F` / dark `#5885a0`
- Ember Copper `#9b5931` / dark `#ba6b3c`
- Ink Blue `#183247`
- Slate Stead `#24313D`
- Basalt `#0F1720`
- Signal Gold `#D2A94E` (with "decorative-only" note)
- Moss Grey `#606d66` / dark `#75827b`
- Stone Mist `#E8ECE8`
- Rain Tint `#F5F7F6`
- Quarry `#C4CCD1`
- Success `#2d7753` / dark `#488d6b`
- Warning `#8f601a` / dark `#B57A21`
- Danger `#b04848` (canonical; `#B44949` on white/rain-tint)
- Info `#356E8C` / dark `#55859e`

Also include neutral ramp spot checks: `#ffffff`, `#f4f6f8`, `#e7ebf0`, `#d8dee6`,
`#99a3af`, `#5c6b7a`, `#1a2332` (light) and `#10161f`, `#19222e`, `#2e3d52`, `#7a8fa3`,
`#a8b9ca`, `#e8edf3` (dark).

### Pattern 3: Typography Ramp (`<text>` elements, NOT outlined paths)

**What:** Uses live `<text>` elements with `font-family` referencing the brand stack.
**Why not outlined paths:** A type ramp with ~10 rows across 3 fonts would require thousands
of path commands, likely exceeding 50 KB. The logo wordmark has only 9 characters; a type
ramp has 30+ lines of sample text. Outlined-to-path is a logo requirement (LOGO-04); it is
explicitly NOT stated for specimens. [CITED: REQUIREMENTS.md SPEC-01 — "typography system",
no mention of path outlining; LOGO-04 applies only to logo lockup files]

**Font rendering reality:** `typography.svg` will render correctly in any browser that has
the Google Fonts CDN-loaded versions of Sora/Inter/IBM Plex Mono. On systems without them,
the fallbacks (ui-sans-serif, system-ui, ui-monospace) provide acceptable rendering.
The specimen is a reference document for brand consumers, not a pixel-perfect distribution
artifact.

```xml
<!-- Source: tokens.css invariant block for size values -->
<!-- Row for each type role: size token + sample text + label -->

<!-- Display H1 — Sora Bold -->
<text x="24" y="60" font-family="Sora, Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="28" font-weight="700" fill="#1a2332">The quick brown fox</text>
<text x="24" y="75" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#5c6b7a">--rs-text-2xl · Sora · 700 · --rs-leading-tight</text>

<!-- Body — Inter Regular -->
<text x="24" y="120" font-family="Inter, ui-sans-serif, system-ui, sans-serif"
      font-size="15.2" font-weight="400" fill="#1a2332">Body text at base scale</text>
<text x="24" y="135" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#5c6b7a">--rs-text-base (0.95rem) · Inter · 400</text>

<!-- Mono — IBM Plex Mono -->
<text x="24" y="180" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="13.7" font-weight="400" fill="#1a2332">const flag = evaluate(ctx)</text>
<text x="24" y="195" font-family="IBM Plex Mono, ui-monospace, monospace"
      font-size="9" fill="#5c6b7a">--rs-font-mono · 400 · code/annotation role</text>
```

**Type ramp rows to include (from `tokens.css` `--rs-text-*` values):**
- `--rs-text-2xl` clamp(1.5rem, 2vw, 2rem) — Sora 700 (page title)
- `--rs-text-xl` 1.4rem — Sora 600 (sub-page title)
- `--rs-text-lg` 1.15rem — Sora 600 (section header)
- `--rs-text-md` 1.05rem — Inter 500 (lead / card title)
- `--rs-text-base` 0.95rem — Inter 400 (body default)
- `--rs-text-sm` 0.86rem — Inter 400 (secondary body / label)
- `--rs-text-xs` 0.78rem — Inter 400 (caption / helper)
- `--rs-text-2xs` 0.72rem — IBM Plex Mono 500 (overline / badge / micro-label)
- Code line — IBM Plex Mono 400 (code/pre contexts)

### Pattern 4: Component Specimen Geometry

**What:** SVG geometric approximation of admin UI components using hard-coded mineral palette
hex values. Not a pixel-perfect screenshot — a styleguide reference.
**Source:** `rulestead_admin.css` component rules.

Key values to hard-code (resolve var() references via tokens.css/tokens.json):

| Component property | Light hex | Dark hex |
|-------------------|-----------|----------|
| `--rs-surface` (card/button bg) | `#f4f6f8` | `#141c27` |
| `--rs-border` (`--rs-neutral-300`) | `#d8dee6` | `#2e3d52` |
| `--rs-text` (`--rs-neutral-900`) | `#1a2332` | `#e8edf3` |
| `--rs-primary` | `#3A6F8F` | `#5885a0` |
| `--rs-on-primary` | `#ffffff` | `#ffffff` |
| `--rs-accent` | `#9b5931` | `#ba6b3c` |
| `--rs-accent-soft` | `#fde8dc` | rgba(232,131,74,0.12) ≈ `#1a2332` tinted |
| `--rs-radius-sm` | 6px | 6px |
| `--rs-radius-lg` | 14px | 14px |
| `--rs-radius-full` | 999px | 999px |

**Components to render:**
1. Default button (border: `#d8dee6`, bg: `#f4f6f8`, text: `#1a2332`, radius 6px)
2. Primary button (bg: `#3A6F8F`, text: `#ffffff`, radius 6px)
3. Danger button (border: `#fca5a5`, bg: `#fee2e2`, text: `#B44949`, radius 6px)
4. Text button (no border, color: `#3A6F8F`, underline)
5. Card (bg: `#ffffff`, border: `#d8dee6`, radius 14px, shadow hint)
6. Badge — neutral (bg: `#eef1f5`, border: `#d8dee6`, text: `#5c6b7a`, radius-full)
7. Badge — positive (bg: `#dcfce7`, border: `#86efac`, text: `#2d7753`, radius-full)
8. Badge — warning (bg: `#fef3c7`, border: `#fcd34d`, text: `#8f601a`, radius-full)
9. Badge — critical (bg: `#fee2e2`, border: `#fca5a5`, text: `#B44949`, radius-full)
10. Badge — accent/draft (bg: `#fde8dc`, border: `#9b5931`, text: `#9b5931`, radius-full)

### Pattern 5: Code Block Specimen

**What:** A code block on mineral dark background (`#10161f`) with IBM Plex Mono text.
**Palette:** Use mineral dark neutral ramp for the background + muted text; use semantic
accent colors for syntax-style highlighting.

```xml
<!-- Code block container -->
<rect x="0" y="0" width="W" height="H" fill="#10161f" rx="10"/>
<!-- Header bar / filename tab -->
<rect x="0" y="0" width="W" height="36" fill="#19222e" rx="10"/>
<rect x="0" y="18" width="W" height="18" fill="#19222e"/>
<!-- Code text lines — IBM Plex Mono -->
<text font-family="IBM Plex Mono, ui-monospace, monospace" font-size="12">
  <!-- comment: muted text #a8b9ca -->
  <!-- keyword: primary #5885a0 -->
  <!-- string/value: accent #ba6b3c -->
  <!-- base text: #e8edf3 -->
</text>
```

**Representative Elixir code snippet** (fits the Rulestead product):
```elixir
# Evaluate a feature flag
{:ok, result} = Rulestead.evaluate(:dark_mode, ctx)
IO.inspect(result.value)     # => true
IO.inspect(result.reason)    # => "matched rule 3"
```

### Pattern 6: README Header Specimen

**What:** README header mock showing the brand mark and wordmark.
**Source:** Reuse the exact geometric primitives from `rs-mark.svg` inline (copy the `<g>`
contents) rather than referencing the external file, so the specimen is self-contained.

Layout: mark on left (~64px square) + wordmark text on right + tagline below.
Use Stead Blue `#3A6F8F` for the mark structure, Ember Copper `#9b5931` for the active
top route, Quarry `#c4ccd1` for off-nodes. White or Rain Tint background.

Tagline: "Runtime decisions, made clear." — Sora or Inter, muted `#5c6b7a`.

### Pattern 7: Social Card Specimen

**What:** A 1200×630 viewBox reference specimen showing the social card layout.
**Distinction from `rs-social-card.svg`:** The existing
`brandbook/assets/logo/rs-social-card.svg` IS the production asset (committed Phase 97,
used for OG/Twitter cards). The specimen `social-card.svg` in `specimens/` is a design
reference that demonstrates the layout principles and brand color application — it can be
nearly identical in content but serves a different role (brand book reference, not live
meta tag asset). They live in different directories and serve different downstream consumers.

**Option A (recommended):** Make the specimen social-card.svg a simplified, slightly annotated
version of `rs-social-card.svg` — same layout, but with token-name labels for the key colors.
**Option B:** Exact copy with a different title/desc. Less useful as a reference.

Use Option A. The viewBox stays 1200×630. Background `#183247` (Ink Blue). Wordmark text
uses the same outlined-path approach already in `rs-social-card.svg` (copy the paths).

### Anti-Patterns to Avoid

- **Embedded base64 raster:** `grep -c 'base64' specimen.svg` must be 0. No PNG/JPEG embedded.
- **External SVG references via `<use href="external">`:** Specimens must be self-contained; use inline geometry copies.
- **Live CSS var() references:** Specimens are not inside `.rs-shell` scope — all fills must be hard-coded hex literals, not `var(--rs-primary)`.
- **Outlined glyphs for typography.svg:** Would exceed 50 KB budget; outlining is for logos only.
- **Creating a `package.json` or running `npm install`:** SVGO is invoked via `npx svgo` ad-hoc.
- **Separate svgo config:** Reuse the existing `brandbook/assets/logo/svgo.config.mjs`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SVG optimization | Custom minification script | `npx svgo --config brandbook/assets/logo/svgo.config.mjs` | Already configured; preserves accessibility metadata; confirmed at 4.0.1 |
| Size budget gate | New script | Existing `scripts/ci/lint.sh` loop (lines 41-48) | Loop already iterates `brandbook/assets/specimens/*.svg`; no changes needed |
| Hex values for swatches | Manual color memory / guessing | `brandbook/tokens.json` primitive section + admin_css_mapping | Single source of truth; D-11 signed-off values |
| Font family strings | Guessing | `brandbook/tokens.css` `:root` block `--rs-font-display/sans/mono` values | Already canonically defined |
| Type scale values | Guessing | `brandbook/tokens.css` `:root` block `--rs-text-*` values | Already canonically defined with rem values and role comments |

**Key insight:** Specimens are intentionally static committed artifacts. Phase 99 has no
generator script because the source files (`tokens.json`, `tokens.css`, logo SVGs) are the
authoritative record — specimens are committed views of that record, not builds of it.
Phase 101's HTML brand book is where the generator pattern applies.

---

## Common Pitfalls

### Pitfall 1: Using CSS `var()` References in Specimen SVGs

**What goes wrong:** Specimen SVG contains `fill="var(--rs-primary)"` — renders as black in
any SVG viewer that isn't inside the `.rs-shell` CSS scope.
**Why it happens:** Developers accustomed to working inside the admin CSS scope assume tokens
are globally available.
**How to avoid:** All specimen SVG fills must be hard-coded hex literals read from
`brandbook/tokens.json`. Use tokens.json as the lookup table, not tokens.css.
**Warning signs:** Any `var(--` in specimen SVG content.

### Pitfall 2: typography.svg Exceeds 50 KB Due to Outlined Text

**What goes wrong:** Attempting to outline Sora/Inter/IBM Plex Mono glyphs via fontTools
for all type ramp rows produces SVG paths totaling 80–200 KB.
**Why it happens:** The Phase 97 "outline wordmark text" requirement is misapplied to the
type ramp specimen.
**How to avoid:** Use live `<text>` elements with `font-family` fallback stacks. The
50 KB limit is enforced by `scripts/ci/lint.sh` line 43: `[ "$size" -gt 51200 ]`.
**Warning signs:** fontTools invocations for specimen generation; SVG file above 30 KB
before SVGO.

### Pitfall 3: social-card.svg Conflicts with rs-social-card.svg

**What goes wrong:** Phase 99 overwrites or replaces `brandbook/assets/logo/rs-social-card.svg`
instead of creating a new `brandbook/assets/specimens/social-card.svg`.
**Why it happens:** Name confusion between the two similarly-titled artifacts.
**How to avoid:** The logo lockup `rs-social-card.svg` is a Phase 97 artifact in
`brandbook/assets/logo/` — Phase 99 ONLY creates files in `brandbook/assets/specimens/`.
Never modify Phase 97 logo files. [CITED: lint.sh line 34 — logo loop checks `assets/logo/`;
specimens loop checks `assets/specimens/`]
**Warning signs:** Any edit to `brandbook/assets/logo/rs-social-card.svg`.

### Pitfall 4: Forgetting the `brandbook/assets/specimens/` Directory Itself

**What goes wrong:** SVG files are committed without first creating the directory; or the
lint.sh `nullglob` loop silently passes because the directory doesn't exist yet.
**Why it happens:** `shopt -s nullglob` in lint.sh means the loop exits 0 (no files found)
if the directory is absent — this would appear as a false "SVG SIZE BUDGET OK" without
actually checking the specimen files. [CITED: lint.sh lines 33, 41]
**How to avoid:** Wave 0 task: `mkdir -p brandbook/assets/specimens/`. Verify the directory
exists before running the lint gate. The final verification task must confirm all 6 files
are present in the directory.
**Warning signs:** Lint passes with 0 SVG files processed.

### Pitfall 5: SVGO Strips Accessibility Metadata

**What goes wrong:** Running `npx svgo` without the custom config removes `<title>`, `<desc>`,
or `aria-labelledby` IDs, breaking accessibility.
**Why it happens:** SVGO's preset-default includes `removeDesc: true` and `cleanupIds: true`.
**How to avoid:** Always pass `--config brandbook/assets/logo/svgo.config.mjs` which disables
`removeDesc`, `cleanupIds`, and `convertColors` via preset-default overrides.
[CITED: brandbook/assets/logo/svgo.config.mjs lines 17-21]
**Warning signs:** `<desc>` or `aria-labelledby` targets missing from SVGO output.

### Pitfall 6: Google Fonts CDN Unreachable in Exec Environment

**What goes wrong:** Any script that tries to `urllib.request` the Sora TTF from
`fonts.gstatic.com` hangs indefinitely.
**Why it happens:** Documented Phase 97 exec-env reality — urllib hangs; curl works.
[CITED: brandbook-visual-rendering memory note; gen_wordmark_paths.py uses urllib]
**How to avoid:** Phase 99 does NOT need to download any fonts. Specimens use live `<text>`
elements with `font-family` stacks — no TTF download required. If for any reason a font
download is needed, use `curl -A Mozilla/5.0` not `urllib.request`.
**Warning signs:** Any `urllib.request` or `requests.get` call targeting `fonts.gstatic.com`
or `fonts.googleapis.com`.

### Pitfall 7: Specimen Size Budget — The Exact Threshold

**What goes wrong:** "50KB" is stated in ROADMAP.md but lint.sh uses 51200 bytes (50 × 1024).
**Why it matters:** A specimen slightly over 50,000 bytes (decimal) but under 51,200 bytes
(binary) would pass. A specimen over 51,200 bytes fails.
**Exact enforcement:** `if [ "$size" -gt 51200 ]` — hard-coded in lint.sh lines 43-45.
[CITED: scripts/ci/lint.sh lines 41-47]
**Warning signs:** Specimens pre-SVGO that are 40–48 KB need careful monitoring; SVGO
typically reduces SVG by 15–40%.

---

## Code Examples

Verified patterns from official sources / project codebase:

### SVGO invocation for specimens (reusing Phase 97 config)

```bash
# Source: Phase 97 RESEARCH.md + svgo.config.mjs
# Run from repo root
npx svgo --config brandbook/assets/logo/svgo.config.mjs \
  brandbook/assets/specimens/palette.svg

# Or batch all specimens after authoring:
for f in brandbook/assets/specimens/*.svg; do
  npx svgo --config brandbook/assets/logo/svgo.config.mjs "$f"
done
```

### Verify no text elements in logo files (not required for specimens, but cross-check)

```bash
# Source: Phase 97 success criterion check
grep -c '<text' brandbook/assets/logo/*.svg
# Expected: 0 for all logo files
# For specimens: typography.svg WILL have text elements (expected)
```

### Verify no base64 in any SVG (applies to both logo and specimens)

```bash
# Source: Phase 97 success criterion check
grep -c 'base64' brandbook/assets/specimens/*.svg
# Expected: 0 for all specimen files
```

### Run size-budget lint

```bash
# Source: scripts/ci/lint.sh lines 41-48
# Run from repo root:
shopt -s nullglob
for f in brandbook/assets/specimens/*.svg; do
  size=$(wc -c < "$f" | tr -d ' ')
  if [ "$size" -gt 51200 ]; then
    echo "SVG budget exceeded: $f is ${size} bytes (limit: 51200)"
    exit 1
  fi
done
echo "SVG SIZE BUDGET OK"
```

### Specimen file existence check (for verification)

```bash
# Source: Phase 99 success criteria
ls brandbook/assets/specimens/palette.svg
ls brandbook/assets/specimens/typography.svg
ls brandbook/assets/specimens/components.svg
ls brandbook/assets/specimens/code-block.svg
ls brandbook/assets/specimens/readme-header.svg
ls brandbook/assets/specimens/social-card.svg
```

### Minimal accessible SVG specimen skeleton

```xml
<!-- Source: Phase 97 rs-mark.svg + ARIA accessible SVG pattern -->
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 800 480"
     aria-labelledby="t d"
     role="img">
  <title id="t">Rulestead — Palette Specimen</title>
  <desc id="d">Brand color palette swatches with hex values and token names.</desc>
  <g aria-hidden="true">
    <!-- swatches go here -->
  </g>
</svg>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 97 logo-studio.html (decision aid HTML file) | Phase 99 committed SVG specimens | Phase 99 | HTML throwaway → permanent SVG reference; specimens are Phase 101 inputs |
| Generic/shipped CSS palette (pre-Phase 98) | Mineral palette across all 4 cascade blocks | Phase 98 complete | Component specimen must reflect mineral palette, not Tailwind defaults |
| Outlined wordmark text (logo-specific, Phase 97) | Live `<text>` for type ramp specimens | Phase 99 decision | Keeps typography.svg well under 50 KB |

**Deprecated/outdated:**
- Phoenix-flame demo logo: retired in Phase 97. Specimens must never reference the old logo.
- Generic Tailwind hex values (e.g. `#2563eb` for primary, `#15803d` for success): replaced by mineral palette in Phase 98. Any specimen using these is wrong.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `social-card.svg` in specimens/ should be a distinct new file (design reference), not a replacement or copy of `rs-social-card.svg` in logo/ | Architecture Patterns Pattern 7 | If wrong: we either duplicate an artifact unnecessarily or damage the Phase 97 logo lockup set |
| A2 | SVGO-optimized specimens will stay under 51,200 bytes — estimated ~10–30 KB each for palette/typography/components, ~5–15 KB for simpler specimens | Pitfall 7 | If wrong: need to simplify content (fewer swatches, shorter code sample, simpler card mock) |
| A3 | `brandbook/assets/logo/svgo.config.mjs` is appropriate to reuse for specimens (no specimen-specific SVGO tuning needed) | Standard Stack | If wrong: may need a separate specimens SVGO config, but the existing config is conservative and preserves all needed metadata |

**If this table is empty:** All claims in this research were verified or cited — no user
confirmation needed. The three assumptions above are low-risk and the planner can proceed
without gating them behind human checkpoints.

---

## Open Questions

1. **Should social-card.svg be labeled/annotated with token names?**
   - What we know: palette.svg explicitly requires hex + token name labels; social-card.svg is a layout reference
   - What's unclear: whether token annotations add value to the social card specimen or clutter it
   - Recommendation: Minimal annotation (one or two color labels) is better than none; full swatch annotations would clutter the card

2. **Does readme-header.svg need to show both light and dark variants side-by-side?**
   - What we know: Phase 97 produced separate light/dark mark files; specimens could show both themes
   - What's unclear: REQUIREMENTS.md just says "README header mock" (singular)
   - Recommendation: Light-only is sufficient; the specimen demonstrates the layout, not both themes

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | Optional scripts | ✓ | 3.14.4 | — |
| fontTools | NOT needed for Phase 99 | ✓ | 4.62.1 | — (not needed) |
| npx / node | SVGO optimization | ✓ | node v22.14.0 / npm 11.1.0 | Manual SVGO if needed |
| svgo (via npx) | SVGO optimization | ✓ | 4.0.1 | Skip optimization (would risk size budget failure) |
| curl | Font TTF download if needed | ✓ | 8.7.1 | — (font download not required for this phase) |
| Google Fonts CDN | typography.svg rendering (browser-side only) | Unknown | — | System font fallbacks render acceptably |

**Missing dependencies with no fallback:** None.

**Note on Google Fonts CDN:** Phase 99 does NOT need to download fonts at authoring time.
The CDN is only needed when viewing `typography.svg` in a browser. System fallback fonts
render acceptably for the specimen's reference purpose.

---

## Validation Architecture

> `nyquist_validation: true` is confirmed in `.planning/config.json`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash assertions + `scripts/ci/lint.sh` |
| Config file | `scripts/ci/lint.sh` (existing) |
| Quick run command | `bash scripts/ci/lint.sh` (or targeted size checks below) |
| Full suite command | `bash scripts/ci/lint.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPEC-01 | palette.svg exists with swatches annotated with hex + token name | smoke | `ls brandbook/assets/specimens/palette.svg` | ❌ Wave 0 |
| SPEC-01 | typography.svg exists with Sora/Inter/IBM Plex Mono type ramp | smoke | `ls brandbook/assets/specimens/typography.svg` | ❌ Wave 0 |
| SPEC-01 | typography.svg contains text elements (not paths) | unit | `grep -c '<text' brandbook/assets/specimens/typography.svg` (expect ≥1) | ❌ Wave 0 |
| SPEC-01 | palette.svg contains known brand hex values | unit | `grep -c '#3A6F8F\|#3a6f8f' brandbook/assets/specimens/palette.svg` (expect ≥1) | ❌ Wave 0 |
| SPEC-02 | components.svg, code-block.svg, readme-header.svg, social-card.svg all exist | smoke | `ls brandbook/assets/specimens/{components,code-block,readme-header,social-card}.svg` | ❌ Wave 0 |
| SPEC-01+02 | No base64 in any specimen | unit | `grep -c 'base64' brandbook/assets/specimens/*.svg` (expect all 0) | ❌ Wave 0 |
| SPEC-01+02 | All specimens ≤51200 bytes (size budget) | integration | Size-budget loop from lint.sh (or `wc -c < f`) | ✅ lint.sh exists |
| SPEC-01+02 | lint.sh exits 0 with "SVG SIZE BUDGET OK" | integration | `bash scripts/ci/lint.sh 2>&1 \| grep 'SVG SIZE BUDGET OK'` | ✅ lint.sh exists |
| SPEC-01+02 | Specimens have accessible title/desc | unit | `grep -c '<title' brandbook/assets/specimens/palette.svg` (expect 1 per file) | ❌ Wave 0 |
| SPEC-01+02 | All 6 files committed | smoke | `git status brandbook/assets/specimens/` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `wc -c < brandbook/assets/specimens/FILENAME.svg` (size spot check on the file just authored)
- **Per wave merge:** Full size-budget loop for all files authored so far
- **Phase gate:** `bash scripts/ci/lint.sh` exits 0 with `SVG SIZE BUDGET OK` + all 6 file-existence assertions green

### Wave 0 Gaps

- [ ] `brandbook/assets/specimens/` directory — create before Wave 1 SVG authoring begins
- [ ] No new test files or test framework needed — all validation is file-existence + grep + lint.sh

*(Existing lint.sh infrastructure covers the phase gate. No new test framework install needed.)*

---

## Security Domain

> `security_enforcement` is not set to `false` in `.planning/config.json` — section required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 99 has no runtime code |
| V3 Session Management | no | Static file authoring only |
| V4 Access Control | no | Static file authoring only |
| V5 Input Validation | no | No user input processed |
| V6 Cryptography | no | No cryptographic operations |

### Known Threat Patterns for Phase 99 (SVG Authoring)

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SVG XSS via `<script>` or `javascript:` URIs | Tampering | No `<script>` or event handler attributes in specimens; SVGO preset-default strips script elements |
| Embedded raster (base64) bloating repo and leaking data | Information Disclosure | `grep -c 'base64'` = 0 assertion in validation; SVG policy: no raster binaries |
| Typosquatted SVGO package via npm | Tampering | `npx svgo` resolves to confirmed `svgo@4.0.1` (npm registry); project has no package.json auto-install |
| Committed font binary violating v1.14 font policy | Repudiation | Policy: no font binaries committed; Phase 99 uses `<text>` elements (no TTF); verify with `file brandbook/assets/specimens/*.svg` |

---

## Sources

### Primary (HIGH confidence)

- `brandbook/tokens.json` — all hex values used in palette/component/code-block specimens
- `brandbook/tokens.css` — font-family stacks and type-scale values for typography.svg
- `scripts/ci/lint.sh` — exact 51200-byte threshold, loop logic, "SVG SIZE BUDGET OK" exit message
- `brandbook/assets/logo/svgo.config.mjs` — SVGO configuration to reuse
- `brandbook/assets/logo/rs-social-card.svg` — layout reference; confirms specimen social-card.svg is a SEPARATE artifact
- `brandbook/assets/logo/rs-mark.svg` — mark geometry to inline in readme-header.svg
- `.planning/REQUIREMENTS.md` — SPEC-01, SPEC-02 definitions
- `.planning/ROADMAP.md` — Phase 99 success criteria (exact 6-file list + ≤50KB requirement)
- `.planning/STATE.md` — v1.14 font policy, SVG policy, "mirror-not-generate" approach
- `rulestead_admin/priv/static/css/rulestead_admin.css` — button/card/badge component shapes and color var resolution

### Secondary (MEDIUM confidence)

- `.planning/phases/97-logo-mark-svg-system/97-RESEARCH.md` — fontTools pattern, SVGO config rationale, accessible SVG skeleton
- `.planning/phases/97-logo-mark-svg-system/logo-studio.html` — palette swatch and type ramp HTML reference pattern
- `~/.claude/projects/rulestead/memory/brandbook-visual-rendering.md` — urllib hang gotcha; curl works; Chrome rendering approach

### Tertiary (LOW confidence)

- None — all findings verified against project artifacts.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact versions confirmed; no new packages
- Architecture: HIGH — all upstream artifacts committed and verified; lint.sh logic read directly
- Pitfalls: HIGH — based on Phase 97 lived experience (exec env font download hang; SVGO config errors; base64/text assertions)
- Font handling decision: HIGH — LOGO-04 text-outline requirement confirmed logo-only; 50KB size budget analysis is conclusive

**Research date:** 2026-06-05
**Valid until:** Phase 99 execution (artifacts are locked; tokens.json will not change before Phase 99 closes)

## Project Constraints (from CLAUDE.md)

- Preserve the sibling-package layout — Phase 99 only adds files to `brandbook/assets/specimens/`; zero changes to `rulestead/` or `rulestead_admin/`
- Prefer narrow, auditable changes — 6 new SVG files, zero edits to existing files (except possibly STATE/ROADMAP updates at close)
- Scripts-first CI surfaces — validation uses existing `scripts/ci/lint.sh`; no new CI scripts needed for Phase 99
- Post-GA band (v1.1–v1.9) is feature-complete — Phase 99 is brand assets only; no runtime API changes
- `rulestead_admin` is a mounted companion — Phase 99 does not modify admin code or CSS

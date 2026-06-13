# 102-AUDIT.md — Logo Delta Audit + HTML Brand Book Presentation Audit

**Phase:** 102 — Logo Delta Audit + Tournament Studio
**Authored:** 2026-06-11
**Status:** Final — feeds Phase 103 tournament and Phase 106 brand book elevation
**Sources read:** brandbook/brand-book.md §14, brandbook/assets/logo/*.svg, brandbook/index.html

---

## Section 1: Audit Scope and Criteria

### In Scope

1. The shipped Rulestead logo system (`rs-wordmark.svg`, `rs-wordmark-dark.svg`, `rs-mark.svg`, `rs-favicon.svg`) — scored against brand-book §14's wordmark-first recommendation and four explicit rejection criteria.
2. `brandbook/index.html` presentation quality — rated section-by-section against "stands on its own, very professional."

### Explicitly Not Re-litigated

Palette, voice copy, type scale, animation tokens — frozen since v1.14. This audit does not revisit those decisions.

### The Four Rejection Criteria (D-02) — Pass/Fail Checkers

| # | Criterion | Pass Condition | Fail Condition |
|---|-----------|----------------|----------------|
| 1 | Icon-left-of-basic-text composition | Mark and type are fused or integrated | A separate graphical group is placed to the left of plain-set text |
| 2 | Rectangular container/background behind a mark | No `<rect>` functions as a background within the lockup boundary | Any `<rect>` serving as a background or badge behind the mark |
| 3 | Logotype visually separated from the mark | Mark and wordmark share visual space; no visible gap reads as "two elements" | Transform separation or whitespace makes icon and text read as independent parts |
| 4 | Tagline/subtitle in primary lockup | No tagline element in the primary wordmark SVG | A tagline or subtitle text appears inside the primary lockup file |

### Overall Lockup Verdict Scale

- **KEEP** — Ship as-is; the composition meets the wordmark-first standard.
- **TIGHTEN** — Keep the composition direction but adjust specific parameters (gap, scale, weight).
- **REWORK** — The shipped composition must not be carried forward into v1.15+; Phase 103 must replace it.

---

## Section 2: Shipped Logo Lockup Audit

### 2a. Composition — Rejection Criteria Check

The evidence is drawn from the actual SVG source of `brandbook/assets/logo/rs-wordmark.svg`.

**Structure of rs-wordmark.svg (viewBox="0 0 372 64"):**

The SVG contains one `<g aria-hidden="true">` group with two distinct visual clusters:

- **Cluster A — Icon group (x ≈ 0–57px):** A series of `<rect>` and `<circle>` elements forming the G4c decision-branch mark. Occupies the left portion of the 372-unit viewBox. Top-left corner of first `<rect>` is at `x="30" y="13"`.
- **Cluster B — Text group (x ≈ 78px onwards):** A single `<path fill="#183247">` element containing the Sora Bold "Rulestead" glyph paths. The first glyph (`R`) begins at approximately x=78.493 in font-unit space.

The gap between the rightmost icon element (circle at `cx="50"`, `r="6.5"`, rightmost edge = 56.5px) and the leftmost text path (`x=78.493`) is approximately **21.5 SVG units** (~5.8% of the 372-unit viewBox width).

---

**Criterion 1 — Icon-left-of-basic-text: FAIL**

The SVG is structurally a separate geometric icon group placed to the LEFT of a plain Sora Bold text path. There is no integration between the icon geometry and the letterform geometry. The icon (`<rect>/<circle>` G4c decision-branch) occupies x=0–57; the wordmark text paths begin at x=78. These are two independent visual objects side by side. This is precisely the icon-left-of-basic-text antipattern.

**Criterion 2 — Rectangular container behind mark: PASS**

Inspecting all `<rect>` elements in `rs-wordmark.svg`: there are six `<rect>` elements, all of which are structural bars within the G4c icon itself (the vertical trunk and three horizontal branch arms). None serve as a background or container for either the icon or the overall lockup. The background of the SVG is transparent (no background `<rect>` spanning the full viewBox). This criterion passes.

**Criterion 3 — Logotype visually separated: FAIL**

The approximately 21.5-unit gap between the icon cluster and the text cluster is visually meaningful at any rendered size. There is no shared stroke, connected contour, overlay, or visual bridge between the icon geometry and the "R" glyph. The eye reads the lockup as: [icon] [space] [word]. Two elements, not one mark. The separation is functional and visible, not merely optical kerning.

**Criterion 4 — Tagline in primary lockup: PASS**

`rs-wordmark.svg` contains no tagline text, subtitle `<text>` element, or additional glyph path below the wordmark. The file is the primary lockup only. The tagline variant exists separately as `rs-wordmark-tagline.svg` — that file was not found in the assets directory (ls output: only `rs-wordmark.svg`, `rs-wordmark-dark.svg`, `rs-mark.svg`, `rs-mark-dark.svg`, `rs-mark-mono.svg`, `rs-favicon.svg`, `rs-social-card.svg`). The primary lockup file itself passes this criterion.

---

**Composition criteria summary:**

| Criterion | Result |
|-----------|--------|
| 1. Icon-left-of-basic-text | **FAIL** |
| 2. Rectangular container behind mark | PASS |
| 3. Logotype visually separated | **FAIL** |
| 4. Tagline in primary lockup | PASS |

Two of four rejection criteria fail. The composition fails the audit.

---

### 2b. Alignment with brand-book §14

The exact text from `brandbook/brand-book.md` §14 ("Logo direction"), subsection "Recommended logo direction":

> **Wordmark-first identity**
> Start with a strong **Rulestead** wordmark before building a complex symbol system.
> This is the right move for an OSS infrastructure brand.

The shipped `rs-wordmark.svg` contradicts this recommendation directly. Rather than a strong wordmark that stands on its own, the lockup presents a separate decision-branch icon placed to the left of plain-set Sora Bold type. The icon is built first; the type is appended to the right. This is the "complex symbol system first" approach that §14 explicitly flags as the wrong starting point.

The brand book's own stated direction for what the logo should be — a strong wordmark — is not what the shipped logo is. The shipped logo is an icon-left lockup: the design pattern that §14 is specifically advising against before any more complex symbol work begins.

This is the anchor finding of the audit.

---

### 2c. Typography — Separate Assessment

The Sora Bold glyph paths in `rs-wordmark.svg` are assessed independently from the composition verdict.

**Glyph paths vs. text elements:** The wordmark uses a single `<path fill="#183247" d="..."/>` element containing all glyph outlines. There are no `<text>` or `<tspan>` elements. The letterforms are cleanly outlined. This is the correct approach for a committed SVG logo — no font dependency at render time.

**Tracking/letter-spacing at logo size:** The path data places the "R" baseline at approximately x=78.5 in a 372-unit-wide viewBox at 64 units tall. The nine characters of "Rulestead" span from x≈78 to x≈372, giving approximately 294 SVG units for 9 characters in a 64-unit em context. The resulting spacing is slightly open — appropriate for a logo-scale wordmark but potentially improvable with tighter tracking for the condensed/architected character described in §14.

**Weight — 700 Bold:** Sora Bold at logo size renders with strong presence without being heavy or slab-like. The stroke contrast is low (geometric sans), which suits the infrastructure brand character. Bold (700) is appropriate; ExtraBold (800) would read as aggressive, Regular (400) as weak for a primary wordmark.

**Typography verdict: KEEP**

The Sora Bold glyph outlines are correctly executed, appropriate weight, readable at all sizes inspected, and free of text element dependencies. The typography itself is not the problem. The composition is the problem.

---

### 2d. Lockup Components — Individual Verdicts

| Component | What It Does | Verdict | Rationale |
|-----------|--------------|---------|-----------|
| rs-wordmark.svg (primary lockup) | G4c icon-left composition with Sora Bold text paths | **REWORK** | Fails Criteria 1 and 3 (icon-left, visually separated). Contradicts brand-book §14 wordmark-first direction. Must be replaced by Phase 103 tournament winner. |
| rs-wordmark-dark.svg | Dark-surface variant of the same icon-left composition | **REWORK** | Same structural finding as rs-wordmark.svg — identical icon-left pattern with color-adjusted fills for dark backgrounds. Replaced when primary lockup is replaced. |
| rs-mark.svg | Standalone G4c decision-branch icon | **KEEP (conditionally)** | The icon geometry itself is not the problem — the icon-left composition is. The mark may serve as a standalone contextual element (admin favicon, doc callouts) in the current era. However, it is likely superseded by the favicon derived from the Phase 103 tournament winner. |
| rs-favicon.svg | Favicon: G4c on solid `#3a6f8f` background | **KEEP / RE-DERIVE** | Solid-background favicon is functionally correct for a 16px icon and renders legibly. However, it is built around the current G4c mark. After the Phase 103 winner is selected and Phase 104 derives the integrated typemark favicon, this file must be regenerated. It is not wrong for the current era. |
| Sora Bold typography (path outlines) | Wordmark letterforms in glyph-path form | **KEEP** | Clean paths, appropriate weight, correct technique. The typeface and its outline execution are the reusable KEEP element from the current lockup. The tournament may keep Sora Bold on Axis D or select an alternate, but the execution pattern is sound. |

---

### 2e. Incumbent as Tournament Control

The existing `rs-wordmark.svg` paths — specifically the Sora Bold "Rulestead" glyph outlines — are carried into the Phase 103 studio as the **Round 1 "Incumbent / Control"** entry.

**What the tournament must solve:** Replace the composition. The icon-left-of-plain-text arrangement is the finding. Phase 103 does not need to interrogate the Sora Bold weight choice or the glyph-path technique — those are sound. It must produce integrated typemark candidates that fuse the mark concept and the wordmark into a single designed object.

**What Phase 103 carries forward from the incumbent:**
- Sora Bold glyph outlines (the KEEP element) — used as the baseline on tournament Axis D
- Palette: `#183247` for the wordmark text on light surfaces; `#e8edf3` for dark-surface variants
- Brand-book §14 constraints: no flags, no phoenix, no shield, no lightning bolt, no SaaS hexagon
- The G4c decision-branch concept (three output nodes from one stem) as a candidate motif to be integrated INTO letterforms, not placed beside them

---

## Section 3: HTML Brand Book Presentation Audit

`brandbook/index.html` is a 1,154-line generated HTML document. Structure: a `<header>` with the wordmark, tagline, theme toggle (System/Light/Dark), and a flat nav strip linking to nine sections by anchor. The nine sections are: Overview, Voice and messaging, Color, Typography, Logo, Layout and components, Iconography and imagery, Motion, Assets and maintenance.

| Section | Current State | Rating | Phase 106 Improvement |
|---------|--------------|--------|----------------------|
| Cover / Hero | The document opens with a `<header>` containing the wordmark SVG, an `h1` reading "Rulestead Brand Book", and a `<p>` tagline "Runtime decisions, made clear." This is a header, not a designed cover. There is no full-bleed color field, no brand mantra treatment, no visual hierarchy that signals "this is a designed document." The first impression is a utility page, not a brand statement. | **Weak** | Add a full-bleed cover/hero region: brand palette background (`#0F1720` or brand gradient), the new tournament-winning lockup at hero scale, brand mantra "Rulestead makes change feel governed, not chaotic." as display text in Sora. |
| Navigation / Scrollspy | The `<nav class="brand-nav">` is a flat strip of anchor links in the header. There is no sticky sidebar, no scrollspy (no IntersectionObserver, no `position: sticky` applied to any nav element — confirmed by grep), no active-section highlighting, no visual indication of reading progress. The nav disappears from view as soon as the user scrolls past the header. On a multi-section long-form document, this means the user is navigationally blind after the first screen. | **Weak** | Add a sticky scrollspy sidebar: `position: sticky`, IntersectionObserver to track active section, highlight current section in the nav. Place to the right of content or as a floating left rail on wide viewports. |
| Editorial Typography | Section headings are bare `<h2>` elements styled in Sora 600 at 1.4rem. Subsections use `<h3>` at 1.05rem Sora 600. There are no section numbers, no large display numerals, no pull-quote treatment (the `blockquote` CSS exists and is used in the Voice section, but it is a simple left-border style, not a designed pull-quote component). The typography hierarchy is competent but undifferentiated — every section reads the same structural weight. | **Adequate** | Add Sora display section numbering (e.g., "01 Overview", "02 Voice" as styled large numerals preceding section titles); elevate blockquote/pull-quote treatment with larger Sora text, more breathing room, and accent color. |
| Token Swatch Presentation | The Color section shows primitive palette swatches as `<article class="swatch">` cards with a color chip (4:1 aspect ratio rectangle), a token name in bold, and a hex code. There are no WCAG contrast ratios, no AA/AAA badges, no semantic role labels (e.g., "primary action background" vs. "on-primary text"), and no live link from primitive token to semantic token usage. The swatches convey the colors but not their relationships or accessibility compliance. | **Adequate** | Live token swatch cards sourced from `tokens.json`: hex value + semantic role description + AA/AAA badge computed from token-defined text/background pairs. Show semantic token (e.g., `--rs-primary`) mapped to its primitive (e.g., `#3A6F8F`) alongside the accessibility status. |
| Logo Plates Section | The Logo section (`id="logo"`) contains brand-book copy only — strategy text, wordmark character description, symbol direction options, constraints. There are no rendered SVG plates, no asset cards, no light/dark tile demos, no clear-space diagram, no do/don't examples. The section has source links to the SVG files but does not display them in context. A designer or developer reading this section cannot see the logo family rendered at any scale. | **Weak** | Designed logo plates: full family displayed on light tile (`#f4f6f8`) and dark tile (`#10161f`), each as `asset-card` components with captions; clear-space diagram (minimum exclusion zone shown as dashed border at 1× cap-height); do/don't examples (correct isolation, wrong background-forced version, wrong scaling). Update after Phase 103 tournament winner is placed. |
| Print Stylesheet | No `@media print` block exists anywhere in `brandbook/index.html` — confirmed by grep. The document has no print behavior. On print, the entire page renders with dark backgrounds, token variables that may not resolve, navigation elements, and theme-control buttons cluttering the output. The brand book is a specification document that practitioners need to print or PDF-export for stakeholder review; the absence of a print stylesheet is a notable gap for a professional document. | **Weak** | Add `@media print`: hide nav, theme-control, source-refs; force light background + dark text regardless of theme token; set page breaks before each major section; convert color swatches to show hex labels prominently; ensure logo SVGs render without background clipping. |

**Overall brand book presentation verdict:**

`brandbook/index.html` does **not** currently "stand on its own as a professional document." It reads as a competent developer reference sheet: functionally accurate, well-structured in HTML, and technically complete in coverage. It does not read as a designed brand artifact. The three critical gaps are:

1. No designed cover/entry point — the document starts as if it were a settings page.
2. No sticky navigation — users are navigationally blind through 90% of the document.
3. No logo plate display — the Logo section describes the logo without showing it.

The token swatch presentation and editorial typography are adequate but not distinguished. The print gap is a usability failure for its actual intended use as a practitioner reference.

Phase 106 must close these gaps for the brand book to serve its purpose as a standalone, very professional document.

---

## Section 4: Font Licensing Determination (Durable Record)

**Recorded per D-05. This determination is final and does not need to be re-researched in subsequent phases.**

| Font | OFL Source | RFN Status | Artwork Permission |
|------|------------|------------|-------------------|
| Sora | `github.com/google/fonts/ofl/sora/OFL.txt` [VERIFIED: curl HTTP 200 2026-06-11] | No Reserved Font Name declared in copyright line. Copyright 2019 The Sora Project Authors. | Glyphs may be outlined to SVG `<path>` elements for logo artwork. Permitted. |
| Space Grotesk | `github.com/floriankarsten/space-grotesk/OFL.txt` [VERIFIED: curl HTTP 200 2026-06-11] | No Reserved Font Name declared. Copyright 2020 The Space Grotesk Project Authors. | Permitted. |
| Archivo | `github.com/Omnibus-Type/Archivo/OFL.txt` [VERIFIED: curl HTTP 200 2026-06-11] | No Reserved Font Name declared. Copyright 2020 The Archivo Project Authors. | Permitted. |
| IBM Plex Sans | `github.com/IBM/plex/LICENSE.txt` [VERIFIED: curl HTTP 200 2026-06-11] | **RFN "Plex" declared.** Copyright 2017 IBM Corp. with Reserved Font Name "Plex". | RFN restricts derivative FONTS only, not artwork. Outlining glyphs to SVG paths produces artwork, not Font Software. Artwork permitted. |
| Inter | SIL OFL 1.1 [CITED: project STATE.md v1.14 font policy] | No RFN (inter.typeface.com OFL.txt) | Permitted. |
| IBM Plex Mono | SIL OFL 1.1 [CITED: project STATE.md v1.14 font policy] | Same RFN "Plex" as IBM Plex Sans; same ruling applies. | Artwork permitted. |

### Settled OFL Interpretation

OFL §5 permits fonts to be "embedded" in other software. OFL §1 defines "Font Software" as the font data files themselves. OFL §3 restricts "Modified Versions" of Font Software — it does not restrict the USE of fonts to produce artwork.

Outlining glyphs to SVG `<path>` elements for use in a logo is using the font as a tool to produce artwork. The resulting path data is not "Font Software" — it is designer artwork derived from the font's shapes. The Reserved Font Name restriction (where declared, as with IBM Plex) only prohibits calling a derivative font by the reserved name; it has no bearing on artwork derived by outlining glyphs. [CITED: scripts.sil.org/OFL_web — OFL FAQ confirms logo artwork is unrestricted]

### Asset Policy

TTF binaries are downloaded to OS temp directories by `scripts/gen_glyph_paths.py` and are never committed to the repository. This is the `brandbook/BUDGET.md` no-font-binaries policy. The policy applies to all six fonts above. Committed SVG logo assets contain outlined paths only — not font data.

---

## Appendix: Phase 103 Tournament Entry Frame

The incumbent wordmark is framed as the Round 1 "Incumbent / Control" as follows:

**Entry label:** Incumbent — rs-wordmark.svg (current shipping lockup)
**Status:** Control — all challenger candidates must be compared against this baseline render.
**Known failing criteria:** Criterion 1 (icon-left-of-text), Criterion 3 (logotype visually separated).
**Tournament task:** Produce integrated typemark candidates (Axes A–C) and font-alternate treatments (Axis D) that PASS all four rejection criteria and align with the §14 wordmark-first recommendation.
**KEEP elements carried into Phase 103:** Sora Bold glyph outline technique; Ink Blue (`#183247`) wordmark fill; `viewBox="0 0 372 64"` as the working canvas reference.

# Phase 102: Logo Delta Audit + Tournament Studio — Research

**Researched:** 2026-06-11
**Domain:** Integrated-typemark design, font licensing (SIL OFL 1.1), fontTools glyph-path pipeline, headless-Chrome screenshot harness, skia-pathops boolean ops
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** The audit is scoped to two surfaces only: the shipped logo system and the HTML brand book's presentation quality. KEEP/TIGHTEN/REWORK verdicts. The anchor finding to develop: `brandbook/brand-book.md` §14 recommends a wordmark-first identity ("Start with a strong Rulestead wordmark before building a complex symbol system"), yet the shipped `rs-wordmark.svg` is a decision-branch icon to the LEFT of plain Sora Bold text — exactly the lockup pattern the maintainer rejects.

**D-02:** Maintainer's explicit rejection criteria are audit criteria: icon-left-of-basic-text composition; any rectangular container/background forced behind a mark; logotype visually separated from the mark; tagline/subtitle in the primary lockup.

**D-03:** The index.html portion rates each section against "stands on its own, very professional" and produces a concrete improvement list consumed by Phase 106 (cover, navigation/scrollspy, editorial typography, token swatch presentation, logo plates, print).

**D-04:** `102-RESEARCH.md` covers: integrated-typemark taxonomy (modified-glyph, ligature, negative-space, monogram-fused); antipatterns (icon-left lockups, badge containers, over-modifying too many glyphs, motifs that die at small sizes); favicon-derivation strategies for typemarks; reference identities as concepts not imitation (FedEx negative space, IBM stripes-in-type).

**D-05:** Record the font-licensing determination once, durably: Sora, Inter, IBM Plex Mono, Space Grotesk, Archivo are all SIL OFL 1.1; OFL permits converting glyphs to outlines and modifying them in artwork (Reserved-Font-Name restricts derivative FONTS, not logos/SVGs); no committed font binaries (BUDGET.md policy stands — TTFs in temp dirs).

**D-06:** Font shortlist with pinned `fonts.gstatic.com` TTF URLs: Sora (incumbent, multiple weights) + 2–3 OFL alternates in the same temperature band (Space Grotesk, Archivo, IBM Plex Sans) to power tournament axis D.

**D-07:** Generalize `scripts/gen_wordmark_paths.py` (proven Phase 97 fontTools SVGPathPen pipeline) into `scripts/gen_glyph_paths.py`: `--font-url` for any pinned gstatic TTF, `--weight`, tracking/letter-spacing param, and one `<path>` PER GLYPH with per-glyph transforms so individual letterforms are independently editable.

**D-08:** Fetch fonts via **curl subprocess**, never urllib (urllib hangs on gstatic in this environment; css2 API needs a browser UA header). Mirror Phase 97's security note T-97-03 (pinned direct TTF URLs).

**D-09:** Studio render harness lives in the phase dir as throwaway tooling (Phase 97 `logo-studio.html` precedent): an HTML grid template + helper invoking `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --screenshot=... --window-size=...`. Candidates are outlined paths, so rendering is font-independent and deterministic. Rendered PNGs are git-ignored; studio HTML is committed in the phase dir.

**D-10:** Optionally install skia-pathops (`pip3 install --user skia-pathops`) to unlock fontTools boolean ops (weld/cut on outlines). If unavailable, the documented fallback covers most integrated-typemark moves: `fill-rule="evenodd"` subpath insertion (carve counters/notches by appending closed subpaths to a glyph's `d`) plus overlay shapes — NEVER background-colored knockout shapes (they break on transparent/arbitrary backgrounds, and rectangles-behind-marks are banned anyway).

### Claude's Discretion

- Exact CLI shape of `gen_glyph_paths.py`, helper structure, studio grid layout, screenshot sizes — provided per-glyph editability, curl fetch, and reproducibility hold.
- Audit document structure, provided verdicts are explicit and Phase-106 consumable.

### Deferred Ideas (OUT OF SCOPE)

- Tournament candidate design — Phase 103.
- Any brand-book §14 rewrite — Phase 104.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRD-06 | Written pressure-test delta audit of shipped logo lockup (scored against brand-book §14 wordmark-first recommendation and maintainer's icon-left rejection) and HTML brand book presentation quality — palette/voice/copy not re-litigated. | D-01/D-02/D-03 locked; §14 text read; shipped `rs-wordmark.svg` inspected and confirms icon-left pattern. Integrated-typemark taxonomy documented in this research for the planner to author `102-AUDIT.md`. |
| LOGO-06 | Tournament infrastructure: generalized glyph→path pipeline (`scripts/gen_glyph_paths.py`: any pinned OFL font via curl fetch, per-glyph editable `<path>` output, weight/tracking params) plus reproducible studio→PNG render harness (headless Chrome). | All technical questions answered: fontTools SVGPathPen confirmed, curl subprocess pattern confirmed, GPOS kerning assessed, skia-pathops installed, headless Chrome flags verified, file:// relative CSS loading confirmed. |
</phase_requirements>

---

## Summary

Phase 102 has two deliverables that are independent in implementation but thematically linked: (1) a written delta audit of the shipped logo lockup against its own brand-book recommendation, and (2) the generalized tooling infrastructure so Phase 103 tournament rounds can be run quickly.

The audit deliverable is primarily a design-reasoning task. The shipped `rs-wordmark.svg` has been inspected: it is a decision-branch icon (G4c mark) to the LEFT of "Rulestead" set in Sora Bold glyph paths — this is precisely the icon-left-of-text pattern the brand book §14 flags as the wrong starting point ("Start with a strong Rulestead wordmark before building a complex symbol system") and the pattern the maintainer explicitly rejects. The audit verdict is therefore predetermined by the brand book's own stated direction: REWORK. The research section on integrated-typemark taxonomy documents what the correct direction looks like so the audit document can be actionable.

The tooling deliverable generalizes the Phase 97 `gen_wordmark_paths.py` script. All technical questions have been resolved in this session: font TTF URLs for all four shortlist fonts are pinned and verified live (HTTP 200). The existing script uses `urllib.request` and hangs on gstatic — the generalized script must use `curl` subprocess. GPOS kerning for Sora is present but produces negligible corrections at logo sizes (Ru: −2 units at UPM 1000 = −0.13px at em=64), so basic advance-width-only spacing is acceptable for paths. skia-pathops is confirmed installed at `/opt/homebrew/lib/python3.14/site-packages` (as the `pathops` Python module). The headless Chrome screenshot harness has been tested end-to-end including `file://` relative CSS loading. The Phase 97 `logo-studio.html` is available as the direct template.

**Primary recommendation:** Implement in two waves — (1) write `102-AUDIT.md` using the integrated-typemark taxonomy in this document, and (2) author `scripts/gen_glyph_paths.py` plus a phase-dir studio HTML and render helper, confirming with a test render of the shipped wordmark.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Delta audit document | `.planning/phases/102-.../102-AUDIT.md` | — | Written artifact; no code tier — pure design assessment |
| HTML brand book quality audit | `.planning/phases/102-.../102-AUDIT.md` | `brandbook/index.html` (read-only) | Rating consumed by Phase 106 generator changes |
| Generalized glyph→path pipeline | `scripts/gen_glyph_paths.py` | TTF temp dir (not committed) | Generalizes Phase 97 pattern; upstream of all tournament candidates |
| Studio HTML template | `.planning/phases/102-.../102-studio.html` | — | Throwaway phase-dir tooling per D-09; not a brand deliverable |
| Render helper script | `.planning/phases/102-.../render_studio.sh` (or `.py`) | headless Chrome at fixed path | Wraps Chrome headless invocation; phase-dir only |
| Rendered PNGs | `/tmp/` or phase-dir (git-ignored) | — | Binary outputs are never committed (BUDGET.md policy; D-09) |
| Font TTFs | OS temp dir (not committed) | — | BUDGET.md no-font-binaries policy; downloaded fresh by gen_glyph_paths.py |

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Python 3 | 3.14.4 [VERIFIED: `python3 --version`] | `gen_glyph_paths.py` driver | In PATH at `/opt/homebrew/bin/python3` |
| fontTools | 4.62.1 [VERIFIED: `python3 -c "import fontTools; print(fontTools.version)"`] | TTFont + SVGPathPen for glyph outline extraction | Proven in Phase 97; user install at `~/Library/Python/3.14/lib/python/site-packages` |
| curl (system) | system [VERIFIED: `curl --head` HTTP 200 on all shortlist TTF URLs] | TTF fetch from gstatic CDN | Never urllib — urllib hangs on gstatic in this exec environment (documented in memory + D-08) |
| Google Chrome.app | 149.0.7827.103 [VERIFIED: `--version`] | Headless screenshot render harness | At `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`; `--headless=new` confirmed working |
| skia-pathops | 0.9.2 [VERIFIED: `pip show skia-pathops`; slopcheck: OK] | Boolean glyph ops (union, difference) via `pathops` Python module | Installed at `/opt/homebrew/lib/python3.14/site-packages`; wraps Skia's path ops library |
| npx svgo | 4.0.1 [VERIFIED: Phase 97 research] | SVGO optimization of output SVGs (for Phase 104 use) | No phase-102 install needed; used at authoring time for committed SVGs |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| pathops Python module | 0.9.2 (installed by skia-pathops) | Low-level Skia path operations | Used directly when `fontTools.pens.pathops` is unavailable (see Pitfall 5) |
| Google Fonts css v1 API | current | Resolve TTF URLs for a given font family + weight | `curl "https://fonts.googleapis.com/css?family=Sora:700"` returns TTF URLs (no browser UA needed for v1 API) |
| `brandbook/assets/logo/svgo.config.mjs` | existing | SVGO config preserving title/desc/viewBox/currentColor | Re-used unchanged in Phase 104; Phase 102 does not modify it |

### No Package Installation Required (Phase 102)

All required tools are already present. The planner must NOT add npm install / pip install steps for Phase 102 execution. skia-pathops is already installed. If `pathops` import fails during execution, fall back to the evenodd technique documented in Code Examples.

---

## Package Legitimacy Audit

> slopcheck run 2026-06-11. Note: slopcheck tests PyPI. svgo and pathops are NOT PyPI packages — svgo is npm-only and pathops installs via the `skia-pathops` PyPI package. slopcheck correctly flags them as absent from PyPI; this is not a hallucination signal for these specific packages.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| fonttools | PyPI | 20+ years | Very high | github.com/fonttools/fonttools | OK | Approved |
| skia-pathops | PyPI | 5+ years | High | github.com/fonttools/skia-pathops | OK | Approved |
| svgo | npm | 12+ years | Very high | github.com/svg/svgo | SLOP (PyPI — cross-ecosystem false positive) | Approved — npm-only; `npm view svgo version` = 4.0.1 confirmed [VERIFIED: npm registry] |
| pathops | PyPI | SLOP (PyPI) | — | — | SLOP | NOT a PyPI package — this is the Python module name installed by `skia-pathops`. Do NOT `pip install pathops`. Import via `import pathops` after installing `skia-pathops`. |

**Packages removed due to slopcheck [SLOP] verdict:** none (both SLOP verdicts are explainable: `svgo` is npm-only; `pathops` is a module installed by `skia-pathops`, not a standalone PyPI package).
**Packages flagged as suspicious [SUS]:** none.

---

## Design Research: Integrated Typemark Taxonomy

### What Is an Integrated Typemark?

An integrated typemark (also called a logotype or typemark) fuses the letterforms of the brand name with a distinctive visual treatment so that the mark and the word are inseparable — there is no "icon" you could remove from the word and still have a coherent logo. The opposite is an "icon-left lockup": a separate graphic placed adjacent to plain-set type. [ASSUMED — from design training knowledge and cited references below]

The icon-left-of-plain-text pattern is the weakest form of a logo because:
1. The icon and the type are independent; neither reinforces the other.
2. At small sizes the icon competes with the type for the available visual budget.
3. If the icon is removed (favicon, embossed contexts, single-color print), the remaining plain text is a generic wordmark with no distinctive character.
4. The icon becomes visual noise adjacent to text that was designed to stand alone at its own size.

For OSS infrastructure products with no dedicated design team, integrated typemarks are superior: they require one designed object (the wordmark itself) rather than two (icon + wordmark), scale down to monochrome cleanly, and cannot be misused by assembling the parts separately. [ASSUMED — design best practice knowledge; supported by brand-book §14's own explicit recommendation]

### The Four Typemark Integration Techniques

**1. Modified Glyph** — one or more letterforms in the wordmark are custom-drawn or subtly altered from the base font. The letter itself carries the brand idea as a shape variation. The alteration is permanent and intrinsic to the wordmark.

Canonical reference concept: FedEx's hidden arrow between the E and x (negative-space modification of the counter). Not visible as a separate icon; it is baked into the letterspace. [ASSUMED — widely documented design case study; cannot attribute to a single authoritative source]

Risk: over-modifying multiple glyphs produces a wordmark that reads as "broken type" rather than "branded type." The rule of thumb is: alter one or two letterforms, never more than 30% of the total.

**2. Ligature** — two adjacent letters are joined, sharing a stroke, crossbar, or common element. The join is the brand idea: connection, continuity, flow.

Canonical reference concept: the double-g ligature in a product name that suggests linked systems. The ligature is the only custom element; all other letters are standard.

Risk: forced ligatures on letter pairs that do not naturally connect (non-adjacent letters, letters with incompatible x-heights) read as errors rather than design decisions.

**3. Negative Space** — a meaningful shape is carved into or framed by the letterforms, visible only as the absence of ink. The counter of a letter, the space between letters, or the interior space of the wordmark envelope becomes the brand mark.

Canonical reference concept: FedEx arrow (letterspace negative space); IBM Plex's crossbars replaced by stripes. [ASSUMED — IBM stripes-in-type is widely cited as a pattern; the IBM Plex letterform use is a near-example]

Risk: negative space motifs that are too subtle disappear at small sizes; those that are too large damage the letterform legibility. They must survive in a single color and at a 16px favicon scale.

**4. Monogram-Fused** — an initial (or initials) is drawn in a custom geometric treatment that replaces or heavily transforms the first letter of the wordmark. The initial is the logotype; the remaining letters may be standard-set. This is the closest to "icon + wordmark" but differs in that the custom initial is not a separate element — it IS the first letter.

Canonical reference concept: the Google "G" mark used as a standalone — the letterform IS the mark, styled to carry the brand colors and weight.

Risk: if the custom-initial is too abstract, it reads as a separate icon rather than a styled letter, recreating the separation problem.

### For "Rulestead": Which Techniques Apply?

The tournament (Phase 103) will explore all four axes (A–D). The implications for each:

- **Axis A** (evolved G4c mark fused into type): the decision-branch motif must be embedded in or emerging from a letterform — e.g., the branch arms growing from the crossbar of the "R" or "t", not placed to the left of plain text. This is the modified-glyph + negative-space approach.
- **Axis B** (abstract mark interlocked/overlapping): the G4c is repositioned to overlap, emerge from, or be interlocked with the wordmark — mark and type share visual space. The mark is NOT left-of-text; it is IN the text or behind/through it.
- **Axis C** (pure custom typemark): the motif is worked INTO letterforms without any separate mark — a modified "R" crossbar, a custom "s" terminal, or a ligature between "e" and "s" that echoes the branch structure. No separate icon at all.
- **Axis D** (alternate font treatments): Sora Bold is the incumbent. Space Grotesk, Archivo, IBM Plex Sans at 600–700 weight provide structural alternatives. Custom treatments applied to whichever font wins.

### Antipatterns (Audit Criteria + Phase 103 Candidate Guarantee)

Per D-02, these are both audit criteria for the current shipped logo AND the candidate guarantee for every Phase 103 round:

| Antipattern | Why It Fails | Detection Check |
|-------------|-------------|-----------------|
| Icon-left of plain text | Mark and type are separate; removing the icon leaves generic text; icon competes at small sizes | `<rect>` or `<circle>` groups visually distinct from `<path>` wordmark |
| Rectangular container/badge behind mark | Forces a color requirement on the background; fails on transparent/arbitrary-color surfaces; a container is not a mark | Any `<rect>` functioning as a background within the lockup boundary |
| Logotype visually separated | Any visible gap, divider, or spacing that reads as "these are two separate elements" | No visual connection between mark geometry and letterform geometry |
| Tagline in primary lockup | Dilutes the lockup to a communications package, not a mark; destroys small-size legibility | Any text element below or beside the primary wordmark in the primary file |
| Motif that dies at 16px | Cannot serve as favicon; counters fill in, thin strokes disappear, shape becomes unreadable | Must test candidate at `width="16"` render in the studio harness |
| Over-modified glyphs (>2 letterforms) | Reads as broken type; cognitive load of "is this a typo?" | Subjective; flag if more than 2 of 9 characters in "Rulestead" are non-standard |

### Favicon Derivation for Integrated Typemarks

When the primary lockup is an integrated typemark (no separate icon), the favicon is typically:

1. The first letter of the wordmark in its custom-styled form (the "R" if it carries the modification)
2. A simplified version of the most distinctive modified glyph, cropped to a square viewport
3. The negative-space motif isolated and filled for legibility at 16px

The favicon must use `fill-only` (no strokes below 1.5px render weight) and contain no more than 2–3 distinct shape regions. [ASSUMED — favicon design constraints from Phase 97 research + general practice]

The shipped `rs-favicon.svg` currently shows the G4c mark (not the wordmark). This is the correct approach for the icon-left lockup family that ships today. After the tournament winner is selected, the favicon must be re-derived from the winning typemark. Phase 104 handles this.

---

## Font Licensing: SIL OFL 1.1 Determination

### Confirmed OFL 1.1 Status

| Font | OFL Source | Copyright / RFN | Artwork Permission |
|------|------------|-----------------|-------------------|
| Sora | `github.com/google/fonts/ofl/sora/OFL.txt` [VERIFIED: curl HTTP 200, text read] | Copyright 2019 The Sora Project Authors. No "with Reserved Font Name" declaration in copyright line. | Glyphs may be outlined to paths in artwork. OFL RFN (if any) restricts derivative FONTS, not artwork. |
| Space Grotesk | `github.com/floriankarsten/space-grotesk/OFL.txt` [VERIFIED: curl HTTP 200, text read] | Copyright 2020 The Space Grotesk Project Authors. No "with Reserved Font Name" declaration in copyright line. | Same as Sora. |
| Archivo | `github.com/Omnibus-Type/Archivo/OFL.txt` [VERIFIED: curl HTTP 200, text read] | Copyright 2020 The Archivo Project Authors. No "with Reserved Font Name" declaration in copyright line. | Same as Sora. |
| IBM Plex Sans | `github.com/IBM/plex/LICENSE.txt` [VERIFIED: curl HTTP 200, text read] | Copyright 2017 IBM Corp. **with Reserved Font Name "Plex"**. | RFN "Plex" means a derivative font cannot be named "Plex." Outlining glyphs into logo artwork is NOT creating a derivative font. Artwork permitted. |
| Inter | Confirmed SIL OFL 1.1 [CITED: STATE.md v1.14 font policy] | — | Artwork permitted. |
| IBM Plex Mono | Confirmed SIL OFL 1.1 [CITED: STATE.md v1.14 font policy] | — | Artwork permitted. |

### OFL and Artwork: The Settled Interpretation

OFL §5 permits fonts to be "embedded" in other software. OFL §1 defines "Font Software" as the font data files. OFL §3 restricts "Modified Versions" of Font Software — it does not restrict the USE of fonts to produce artwork.

Outlining glyphs to SVG `<path>` elements for use in a logo is using the font as a tool to produce artwork; the resulting paths are not "Font Software" — they are the designer's artwork derived from the font's shapes. The Reserved Font Name restriction (if declared) only prohibits calling a derivative font by the reserved name — it has no bearing on artwork. [CITED: scripts.sil.org/OFL_web — OFL FAQ "Can I use the font to make a logo?" answer confirms artwork is unrestricted]

**Durably recorded determination:** All five fonts (Sora, Space Grotesk, Archivo, IBM Plex Sans, IBM Plex Mono) are SIL OFL 1.1. Outlining their glyphs into SVG path artwork for the Rulestead logo is permitted by the OFL. No font binaries are committed (BUDGET.md policy). TTFs are downloaded to temp dirs and deleted after path extraction.

---

## Pinned Font TTF URLs

All URLs verified live (HTTP 200, `content-type: font/ttf`) on 2026-06-11. Retrieved via the Google Fonts CSS v1 API (no browser UA header needed for v1, unlike css2).

### Retrieval Method

```bash
# CSS v1 API — returns TTF URLs, no browser UA required
curl -s "https://fonts.googleapis.com/css?family=Sora:700"

# CSS v2 API — returns woff2 by default; can return woff with old UA header
# Do NOT use css2 API for TTF discovery — it does not reliably serve TTFs
```

### Sora (incumbent — four weights)

| Weight | TTF URL | Content-Length |
|--------|---------|---------------|
| 600 (SemiBold) | `https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSeMmU-NKQc.ttf` | 32,112 bytes |
| 700 (Bold — current wordmark) | `https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSe1mU-NKQc.ttf` | 32,036 bytes |
| 800 (ExtraBold) | `https://fonts.gstatic.com/s/sora/v17/xMQOuFFYT72X5wkB_18qmnndmSfSmU-NKQc.ttf` | 32,124 bytes |

Note: The Phase 97 `gen_wordmark_paths.py` hardcodes `xMQOuFFYT72X5wkB_18qmnndmSe1mX-K.ttf` (with `-K` suffix instead of `NKQc`). That URL returns HTTP 200 [VERIFIED: HEAD request]. Both URL forms are live; the css v1 API form (`NKQc.ttf` suffix) is the canonical discovery source.

### Space Grotesk (alternate)

| Weight | TTF URL | Content-Length |
|--------|---------|---------------|
| 500 (Medium) | `https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj7aUXskPMU.ttf` | (from css API) |
| 600 (SemiBold) | `https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj42VnskPMU.ttf` | 31,968 bytes |
| 700 (Bold) | `https://fonts.gstatic.com/s/spacegrotesk/v22/V8mQoQDjQSkFtoMM3T6r8E7mF71Q-gOoraIAEj4PVnskPMU.ttf` | 31,928 bytes |

### Archivo (alternate)

| Weight | TTF URL | Content-Length |
|--------|---------|---------------|
| 500 (Medium) | `https://fonts.gstatic.com/s/archivo/v25/k3k6o8UDI-1M0wlSV9XAw6lQkqWY8Q82sJaRE-NWIDdgffTTBjNZ9xds.ttf` | 40,804 bytes |
| 600 (SemiBold) | `https://fonts.gstatic.com/s/archivo/v25/k3k6o8UDI-1M0wlSV9XAw6lQkqWY8Q82sJaRE-NWIDdgffTT6jRZ9xds.ttf` | 40,804 bytes |
| 700 (Bold) | `https://fonts.gstatic.com/s/archivo/v25/k3k6o8UDI-1M0wlSV9XAw6lQkqWY8Q82sJaRE-NWIDdgffTT0zRZ9xds.ttf` | 40,804 bytes |

### IBM Plex Sans (alternate)

| Weight | TTF URL | Content-Length |
|--------|---------|---------------|
| 500 (Medium) | `https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYYaJe8bpLHnCwDKr932-G7dytD-Dmu1swZSAXcomDVmadSD2FlDB6g9.ttf` | 56,684 bytes |
| 600 (SemiBold) | `https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYYaJe8bpLHnCwDKr932-G7dytD-Dmu1swZSAXcomDVmadSDNF5DB6g9.ttf` | 56,684 bytes |
| 700 (Bold) | `https://fonts.gstatic.com/s/ibmplexsans/v23/zYXGKVElMYYaJe8bpLHnCwDKr932-G7dytD-Dmu1swZSAXcomDVmadSDDV5DB6g9.ttf` | 56,684 bytes |

[VERIFIED: all 12 URLs return HTTP 200 with `content-type: font/ttf` — tested 2026-06-11]

---

## fontTools Pipeline: Verified Specifics

### What Phase 97 gen_wordmark_paths.py Does

The existing script: downloads Sora Bold via `urllib.request` (hangs — must replace with curl subprocess), loads via `TTFont`, iterates characters, draws each glyph via `SVGPathPen`, emits one `<path>` per glyph with `transform="translate(x, em_size) scale(scale, -scale)"`.

### What gen_glyph_paths.py Must Add / Change

1. **curl subprocess instead of urllib** — critical; urllib hangs on gstatic in this environment [VERIFIED: documented in `brandbook-visual-rendering.md` memory + D-08]
2. **`--font-url` parameter** — accepts any pinned gstatic TTF URL, not just the hardcoded Sora Bold URL
3. **`--weight` display parameter** — for labeling output only (the weight is baked into the TTF URL; the script does not dynamically select weight from a family — that requires a separate URL)
4. **`--tracking` / letter-spacing parameter** — adds uniform extra advance after each glyph; negative tracking tightens, positive loosens; units in em fractions (e.g., `--tracking -0.02` = tighten by 2% of em_size per glyph)
5. **Per-glyph `<path>` with per-glyph transform** — the existing script already does this; the key is NOT to merge paths into a single blob (Phase 97 fallback Pattern 6 merged; the new script must NOT merge)
6. **Character label metadata** in SVG comment per path — `<!-- glyph: R -->` so the output is human-readable

### fontTools API Verified Patterns

```python
# Source: scripts/gen_wordmark_paths.py (Phase 97, working code) + verified session test
import sys, os, subprocess, tempfile
sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

# CRITICAL: use curl subprocess, never urllib.request
def download_font_curl(url: str, tmp_dir: str) -> str:
    """Download TTF via curl subprocess. Returns local path. Raises on non-gstatic URL."""
    assert url.startswith("https://fonts.gstatic.com/"), f"Security: only fonts.gstatic.com permitted. Got: {url}"
    out_path = os.path.join(tmp_dir, "font.ttf")
    result = subprocess.run(
        ["curl", "-s", "-o", out_path, url],
        capture_output=True, timeout=30
    )
    if result.returncode != 0:
        raise RuntimeError(f"curl failed: {result.stderr.decode()}")
    return out_path

# Scale formula (verified: Sora UPM = 1000)
#   units_per_em = font["head"].unitsPerEm  # 1000 for Sora
#   scale = em_size / units_per_em
#   At em_size=64: scale = 0.064

# Per-glyph emission with per-glyph transform (the upgrade from Phase 97):
def glyph_to_path(glyph_name, glyphs, x_cursor, scale, em_size, tracking_extra=0.0):
    pen = SVGPathPen(glyphs)
    glyphs[glyph_name].draw(pen)
    d = pen.getCommands()
    adv = glyphs[glyph_name].width
    x_px = x_cursor * scale
    # transform: translate(x, em_size) scale(s, -s)
    # Y-flip required: SVG Y-down, font Y-up
    transform = f"translate({x_px:.3f},{em_size:.3f}) scale({scale:.6f},-{scale:.6f})"
    path_elem = f'<path transform="{transform}" d="{d}"/>'
    advance = (adv + tracking_extra / scale) * scale  # tracking_extra in SVG units per glyph
    return path_elem, advance
```

### GPOS Kerning: Assessment

Sora Bold has GPOS PairPos Format 1 (explicit pairs, 4 pairs) and Format 2 (class pairs). [VERIFIED: Python session test]

Kern pairs in "Rulestead":
- `Ru`: −2 font units → −0.128px at em=64
- `te`: −2 font units → −0.128px at em=64

These are sub-pixel corrections at working size and negligible at logo scale. The existing advance-width-only approach in Phase 97 is acceptable for all four shortlist fonts. The `--tracking` parameter provides the designer-level control that matters. Full GPOS implementation is not worth the complexity for this use case. [VERIFIED: kerning values measured in session]

If a future phase requires tight GPOS implementation, the access pattern is:
```python
gpos = font["GPOS"].table
for lookup in gpos.LookupList.Lookup:
    if lookup.LookupType == 2:  # PairPos
        # Format 1 (explicit): lookup subtable has .PairSet
        # Format 2 (class): lookup subtable has .ClassDef1, .ClassDef2
```

### skia-pathops: Boolean Ops

skia-pathops is installed at `/opt/homebrew/lib/python3.14/site-packages` as the `pathops` Python module. [VERIFIED: `pip show skia-pathops`, `import pathops` confirmed working]

**Important:** `fontTools.pens.pathops` (the fontTools wrapper module for pathops) does NOT exist in the user-installed fontTools 4.62.1 at `~/Library/Python/3.14/lib/python/site-packages/fontTools/pens/` — there is no `pathops.py` file there. Use the `pathops` module directly.

```python
# Source: verified session test — pathops API
import pathops

# Build a path from glyph outline
path = pathops.Path()
pen = pathops.PathPen(path)  # pathops.PathPen accepts fontTools pen protocol
glyphs[glyph_name].draw(pen)

# Boolean operations
result = pathops.Path()
pathops.op(path_a, path_b, pathops.PathOp.UNION, result)
pathops.op(path_a, path_b, pathops.PathOp.DIFFERENCE, result)

# Simplify (remove self-intersections from a single path — useful for counters)
pathops.simplify(path, path.fillType)

# Available PathOp values:
# PathOp.DIFFERENCE, PathOp.INTERSECTION, PathOp.UNION, PathOp.XOR, PathOp.REVERSE_DIFFERENCE
```

The `pathops.PathPen` accepts glyph draw calls directly. To emit the resulting path as SVG `d` data, draw the same glyph to an `SVGPathPen` (the pathops.Path does not have a direct SVG emit method). Use pathops for boolean computation; use SVGPathPen for the final `d` string. [VERIFIED: session test — draw to pathops.PathPen, separately draw to SVGPathPen for output]

### evenodd Subpath Fallback (when pathops not needed)

For carved counters or notches without boolean ops, the SVG `fill-rule="evenodd"` technique works on any path with multiple subpaths:

```svg
<!-- Carve a diamond notch into the crossbar of the 'e' glyph:
     outer_subpath + inner_notch_subpath → even-odd rule carves the inner shape -->
<path fill-rule="evenodd" d="
  M ... Z   <!-- outer letterform subpath -->
  M ... Z   <!-- inner cutout subpath — winding reversal not needed for evenodd -->
"/>
```

The inner subpath's winding direction does NOT need to be reversed for evenodd (unlike nonzero rule). Append the cutout as a second `M...Z` block in the same `d` attribute. [CITED: SVG 1.1 specification §11.3 fill-rule — evenodd definition]

**Critical constraint (D-10):** NEVER use background-colored fill shapes as knockouts. They break on transparent backgrounds and any non-white surface. The evenodd technique is transparent-safe. Overlay shapes (adding color on top) are permitted. Background-colored rectangles are banned in all contexts (D-02 audit criterion).

---

## Phase 97 Lessons: What to Replicate and What to Improve

### What Worked (from 97-CONCEPT-REVIEW.md)

1. **Rendered studio as the decision aid, not text descriptions.** The CONCEPT-REVIEW.md initially presented three concepts as HTML with `<img>` embeds; the maintainer needed rendered-at-size PNG evidence to decide. The studio HTML + headless Chrome render was added mid-phase and was the deciding factor. Phase 102 bakes this in from the start.

2. **Four rounds of iteration, not one commit-to-a-direction.** A/B/C got eliminated quickly (Round 1); meaningful design exploration happened in Rounds 2–4. The tournament structure acknowledges this: soft cap of 5 rounds, human checkpoint after each.

3. **Logo-studio.html as throwaway phase-dir artifact.** Committed HTML, git-ignored PNGs, no attempt to make the studio a permanent deliverable. The Phase 102 studio follows this exactly.

4. **Inline SVG geometry in the HTML (not `<img src=...>`)**, so a single headless Chrome render with `--virtual-time-budget` captures everything without network fetches or load-timing races.

5. **Light + dark surface cards in the studio.** Showing candidates on white AND `#10161f` dark surfaces in the same render caught color problems (washed-out on dark, too heavy on light) early.

### What to Improve

1. **urllib was used in gen_wordmark_paths.py** — the script hangs when called in this execution environment. The new script must use curl subprocess from the start. [VERIFIED: memory + D-08]

2. **The Phase 97 wordmark was a single merged path blob** (Pattern 6 fallback), not per-glyph paths. The upgrade to per-glyph paths is the key Phase 102 tooling improvement. This enables independent letter modification for tournament Axis A/B/C candidates.

3. **No size-stress test in the studio.** The studio showed marks at design scale but not at 36px (admin header) or 16px (favicon). Phase 102 must include size stress cells in the studio template.

4. **The CONCEPT-REVIEW.md checkpoint was write-only.** Once G4c was selected, there was no machine-readable bracket file. Phase 103 introduces `103-TOURNAMENT.md` as the persistent bracket; Phase 102's contribution is making it clear that the studio render (not just the SVG files) is what the maintainer reviews.

5. **No kerning param in the script.** Phase 97's script had no tracking control. The tournament will explore tighter/looser spacing as part of axis D. The new `--tracking` parameter enables this without manual path editing.

---

## Architecture Patterns

### System Architecture Diagram

```
[fonts.gstatic.com CDN]
    |
    | curl subprocess (never urllib)
    | pinned TTF URL for any OFL font + weight
    v
[temp dir: font.ttf]  ──────────────────────────────────────┐
    |                                                         |
    v                                                         v
[fontTools.ttLib.TTFont]                             [pathops.PathPen]
    |                                                  (for boolean ops)
    | SVGPathPen per glyph                                    |
    | advance width + optional GPOS kern                      |
    | tracking param applied                                  |
    v                                                         |
scripts/gen_glyph_paths.py stdout:                           |
  <!-- glyph: R -->                                           |
  <path transform="translate(0,em) scale(s,-s)" d="..."/>    |
  <!-- glyph: u -->                                           |
  <path transform="translate(adv,em) scale(s,-s)" d="..."/>  ┘
  ... (one path per character)
    |
    v (paths pasted into studio HTML candidates)
[phase-dir/102-studio.html]
  Grid of candidate lockups (light + dark surface cards)
  Size stress cells: 128px / 36px / 16px columns
  Uses inline SVG paths (no font dependency — deterministic render)
  Links to brandbook/tokens.css for live color tokens
    |
    v (render_studio.sh)
[Google Chrome.app --headless=new]
  --disable-gpu --no-sandbox --no-first-run
  --user-data-dir=<tmp>
  --hide-scrollbars --force-color-profile=srgb
  --default-background-color=FFFFFFFF
  --force-device-scale-factor=2
  --virtual-time-budget=10000
  --screenshot=out.png --window-size=1600,900
  file:///abs/path/to/102-studio.html
    |
    v
[phase-dir/studio-render-YYYY.png]  ←── git-ignored
```

### Recommended Project Structure

```
.planning/phases/102-logo-delta-audit-tournament-studio/
├── 102-CONTEXT.md          # already exists
├── 102-RESEARCH.md         # this file
├── 102-AUDIT.md            # Phase 102 Wave 1 deliverable: delta audit
├── 102-studio.html         # Phase 102 Wave 2 deliverable: studio template (committed)
├── render_studio.sh        # Phase 102 Wave 2 deliverable: render helper (committed)
└── (studio-render-*.png)   # git-ignored rendered PNGs

scripts/
└── gen_glyph_paths.py      # Phase 102 Wave 2 deliverable: generalized pipeline
```

`.gitignore` must include `*.png` in the phase dir (or use the existing git-ignored binary policy for this directory).

### Pattern 1: curl-subprocess Font Fetch

```python
# Source: brandbook-visual-rendering.md memory (confirmed working pattern)
import subprocess, tempfile, os

def download_font_curl(url: str) -> str:
    """Download TTF from fonts.gstatic.com via curl. Returns path to temp file."""
    assert url.startswith("https://fonts.gstatic.com/"), (
        f"Security (T-97-03): TTF download must be from fonts.gstatic.com. Got: {url}"
    )
    tmp_dir = tempfile.mkdtemp(prefix="rulestead_glyphs_")
    out_path = os.path.join(tmp_dir, "font.ttf")
    result = subprocess.run(
        ["curl", "-s", "-o", out_path, url],
        capture_output=True,
        timeout=30
    )
    if result.returncode != 0:
        raise RuntimeError(f"curl download failed (exit {result.returncode}): {result.stderr.decode()}")
    return out_path
```

### Pattern 2: Per-Glyph Path Emission with Tracking

```python
# Source: verified extension of gen_wordmark_paths.py (Phase 97) + session test
import sys, os, argparse, tempfile, subprocess
sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

def text_to_glyph_paths(text, font, em_size=64.0, tracking=0.0):
    """
    Emit one <path> per glyph with per-glyph transform.
    tracking: extra advance per glyph in em fractions (e.g. -0.02 = tighter)
    """
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    scale = em_size / upm
    tracking_units = tracking * upm  # convert em fraction to font units

    paths = []
    x_cursor = 0.0  # in font units

    for ch in text:
        cp = ord(ch)
        glyph_name = cmap.get(cp)
        if not glyph_name:
            # Space or missing glyph — advance but don't emit
            x_cursor += font["hmtx"].metrics.get("space", (500, 0))[0] + tracking_units
            continue

        pen = SVGPathPen(glyphs)
        glyphs[glyph_name].draw(pen)
        d = pen.getCommands()
        adv = glyphs[glyph_name].width

        if d:
            x_px = x_cursor * scale
            t = f"translate({x_px:.3f},{em_size:.3f}) scale({scale:.6f},-{scale:.6f})"
            paths.append(f'<!-- glyph: {ch} -->\n<path transform="{t}" d="{d}"/>')

        x_cursor += adv + tracking_units

    total_w = x_cursor * scale
    return paths, total_w
```

### Pattern 3: Headless Chrome Screenshot (verified flags)

```bash
#!/bin/bash
# render_studio.sh — Phase 102 render helper
# Source: brandbook-visual-rendering.md memory (confirmed working 2026-06-11)

STUDIO_HTML="$(cd "$(dirname "$0")" && pwd)/102-studio.html"
OUT_PNG="$(cd "$(dirname "$0")" && pwd)/studio-render-$(date +%Y%m%d-%H%M%S).png"
TMPDIR=$(mktemp -d)
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-sandbox \
  --no-first-run \
  --user-data-dir="$TMPDIR" \
  --hide-scrollbars \
  --force-color-profile=srgb \
  --default-background-color=FFFFFFFF \
  --force-device-scale-factor=2 \
  --virtual-time-budget=10000 \
  --screenshot="$OUT_PNG" \
  --window-size=1600,900 \
  "file://$STUDIO_HTML" 2>/dev/null

# Chrome can linger — wait for output file then kill
for i in $(seq 1 30); do
  [ -f "$OUT_PNG" ] && break
  sleep 0.5
done
rm -rf "$TMPDIR"
echo "Rendered: $OUT_PNG"
```

**Critical flags explained:**
- `--headless=new`: the modern headless mode (Chrome 112+); `--headless=old` is deprecated
- `--force-device-scale-factor=2`: retina-quality 2× pixel density in the output PNG
- `--virtual-time-budget=10000`: budget 10 seconds of virtual time for webfont loading, JS settle, etc.
- `--disable-gpu`: suppress GPU errors on macOS CI/headless contexts
- `--user-data-dir=<tmp>`: prevents profile lock issues when Chrome is already running
- `--force-color-profile=srgb`: consistent color rendering between runs
- `--default-background-color=FFFFFFFF`: white background for transparent-bg SVGs

**file:// relative CSS loading:** Verified — headless Chrome loads relative CSS from `file://` URIs. The studio HTML can use `<link rel="stylesheet" href="../../../brandbook/tokens.css">` with a relative path from the phase dir. [VERIFIED: session test — relative CSS loaded and computed style applied]

**Theme gotcha:** headless Chrome defaults to `prefers-color-scheme: dark`. To render light theme explicitly, apply `data-theme="light"` to the shell wrapper in the HTML, or render two screenshots with different theme attributes.

### Pattern 4: Studio HTML Structure

The Phase 97 `logo-studio.html` is the canonical template. Key structural decisions to replicate:

1. **Inline SVG marks in JS/HTML** (not `<img src=...>`) — no network fetch race during render
2. **`document.fonts.ready` + `--virtual-time-budget`** guard — prevents capturing text before webfonts load
3. **Live tokens.css link** — `<link rel="stylesheet" href="...brandbook/tokens.css">` for accurate brand colors
4. **Size stress row required (Phase 102 addition):** each candidate must appear at 128px, 36px (admin header), and 16px (favicon) in the same render

```html
<!-- Phase 102 addition not in Phase 97 template: size stress row -->
<div class="size-strip">
  <div class="cell">
    <div class="holder" style="width:128px;height:128px">
      <svg viewBox="0 0 372 64" width="128" height="22"><!-- paths --></svg>
    </div>
    <div class="px">128px</div>
  </div>
  <div class="cell">
    <div class="holder" style="width:36px">
      <svg viewBox="0 0 372 64" width="36" height="6"><!-- paths --></svg>
    </div>
    <div class="px demo">36px (admin header)</div>
  </div>
  <div class="cell">
    <div class="holder" style="width:16px;height:16px">
      <svg viewBox="0 0 64 64" width="16" height="16"><!-- favicon mark --></svg>
    </div>
    <div class="px">16px (favicon)</div>
  </div>
</div>
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Glyph outline extraction | Manual bezier tracing | fontTools SVGPathPen + TTFont | Font hinting, advance widths, counter accuracy — impossible to hand-trace reliably |
| Boolean path operations | Custom intersection algorithm | `pathops` (skia-pathops) | Sub-pixel accuracy; handles self-intersections, winding, colinear edges — thousands of edge cases |
| Font file download | urllib.request | `curl` subprocess | urllib hangs on gstatic in this exec environment; curl is sub-100ms |
| SVG optimization | Custom minifier | `npx svgo` with `svgo.config.mjs` | Already exists in project; handles path precision, useless groups, attribute normalization |
| Headless screenshot | Playwright / puppeteer / resvg | Chrome `--headless=new` | Chrome is present, zero install, reproduces the exact browser rendering used in the admin shell |
| Precise tracking/spacing | GPOS re-implementation | `--tracking` uniform advance param | GPOS kern in Sora is sub-pixel at logo size; uniform tracking param covers 99% of designer intent |

**Key insight:** For glyph path work, two thin layers — `SVGPathPen` for path emission, `pathops` for boolean ops — cover every integrated-typemark move. Do not build path geometry by hand except for the mark geometry (branches, nodes) that is not derived from a font.

---

## Common Pitfalls

### Pitfall 1: urllib Hangs on gstatic

**What goes wrong:** `urllib.request.urlretrieve` hangs indefinitely when fetching from `fonts.gstatic.com` in this execution environment. The script never returns.

**Why it happens:** The gstatic CDN requires a browser-like User-Agent header on some endpoints; `urllib.request` uses a Python default UA that may be rate-limited or dropped. [VERIFIED: brandbook-visual-rendering.md memory; documented as the "font-fetch gotcha"]

**How to avoid:** Use `subprocess.run(["curl", "-s", "-o", out, url])` for every gstatic TTF download. Never use `urllib.request` in this codebase. The existing `gen_wordmark_paths.py` still uses urllib on line 48 — do not call it; the new `gen_glyph_paths.py` replaces it.

**Warning signs:** Script hangs with no output and no timeout error.

---

### Pitfall 2: pathops Import Confusion

**What goes wrong:** `from fontTools.pens.pathops import PathPen, Op` raises `ModuleNotFoundError` even though skia-pathops is installed.

**Why it happens:** The user-installed fontTools 4.62.1 at `~/Library/Python/3.14/lib/python/site-packages/fontTools/pens/` does NOT include a `pathops.py` module. The `fontTools.pens.pathops` wrapper requires a version of fontTools that ships with it, or a different install source. [VERIFIED: `ls` of pens dir — no pathops.py]

**How to avoid:** Import directly from `pathops` (the module installed by `skia-pathops`): `import pathops; pen = pathops.PathPen(path)`. Do NOT use `from fontTools.pens.pathops import ...`. The `sys.path.insert(0, '~/Library/Python/3.14/...')` prefix is still required for `TTFont` and `SVGPathPen`.

**Warning signs:** `ModuleNotFoundError: No module named 'fontTools.pens.pathops'` — even though `import pathops` works fine.

---

### Pitfall 3: headless Chrome Defaults to Dark Mode

**What goes wrong:** The studio HTML renders as dark by default when headless Chrome emulates `prefers-color-scheme: dark`, even though no explicit theme attribute is set.

**Why it happens:** Chrome's headless mode emulates system dark preference. [VERIFIED: brandbook-visual-rendering.md memory — "headless Chrome emulates prefers-color-scheme: dark by default"]

**How to avoid:** For light renders, either (a) apply `data-theme="light"` on the `.rs-shell` wrapper element in the HTML, or (b) set `--force-dark-mode=0` Chrome flag, or (c) capture two renders (one with `data-theme="light"`, one with `data-theme="dark"`) and stitch side by side. The studio template should show both explicitly so the single screenshot contains both themes.

**Warning signs:** The "light" studio render shows dark backgrounds.

---

### Pitfall 4: Chrome Lingers After Screenshot

**What goes wrong:** The render helper exits, but the Chrome process stays running, blocking subsequent renders or consuming CPU.

**Why it happens:** `--headless=new` Chrome can linger after writing the screenshot file. [VERIFIED: brandbook-visual-rendering.md memory — "wrap each render in a background launch + watchdog loop that waits for the output file then kills the PID"]

**How to avoid:** In the render helper, launch Chrome with `&` and capture PID, poll for the output file, then `kill $PID`. The `render_studio.sh` pattern in Code Examples uses a file-wait loop.

---

### Pitfall 5: gen_glyph_paths.py Merges Paths

**What goes wrong:** The script emits a single `<path>` with all glyph subpaths concatenated (as Phase 97's Pattern 6 fallback did), rather than one `<path>` per glyph.

**Why it happens:** It is simpler to concatenate `d` strings; per-glyph transforms require individual path elements.

**How to avoid:** The output MUST be one `<path>` element per input character, each with its own `transform` attribute. This is the entire point of the generalization — independently editable letterforms. Verify: `python3 scripts/gen_glyph_paths.py --text "RS" | grep -c '<path'` should return 2.

**Warning signs:** Output contains a single `<path d="..."/>` with no transform; `grep -c '<path'` returns 1 regardless of text length.

---

### Pitfall 6: SVG Coordinate Y-Flip Missing or Wrong

**What goes wrong:** Glyph paths render upside down (below the baseline, flipped vertically).

**Why it happens:** Font coordinate systems are Y-up (baseline at y=0, ascenders go positive). SVG is Y-down. Without the flip transform, glyphs are mirrored vertically.

**How to avoid:** Always apply `transform="translate(x, em_size) scale(scale, -scale)"`. The `em_size` translation shifts the baseline down to y=em_size after the flip, so glyphs render with the baseline at y=em_size and cap-height upward (toward y=0). [VERIFIED: gen_wordmark_paths.py line 96 — this is the exact pattern in the working script]

---

### Pitfall 7: Tracking Parameter Units

**What goes wrong:** `--tracking -0.015` (em fraction) produces wildly tight or loose output because the implementation adds font-unit values instead of scaling correctly.

**How to avoid:** Convert tracking from em fractions to font units before accumulating: `tracking_font_units = tracking_em_fraction * upm`. Apply to `x_cursor` after each advance, not to the scale. At em_size=64 and UPM=1000: `--tracking -0.02` = −20 font units per glyph = −1.28px per glyph.

---

## Code Examples

### Complete gen_glyph_paths.py Skeleton

```python
#!/usr/bin/env python3
"""
gen_glyph_paths.py — Generalized glyph-to-SVG-path converter for Rulestead tournament tooling.

Fetches any pinned OFL font TTF from fonts.gstatic.com via curl (never urllib),
extracts glyph outlines for a given text string via fontTools SVGPathPen,
applies Y-axis flip + per-glyph translate, and emits one <path> per glyph.

Per-glyph output enables independent letterform editing for tournament candidates.

Security: TTF download URL must be from fonts.gstatic.com only (T-97-03).

Usage:
  python3 scripts/gen_glyph_paths.py --font-url URL --text "Rulestead" [--em-size 64] [--tracking -0.01]
"""
import sys, os, argparse, tempfile, subprocess

sys.path.insert(0, os.path.expanduser('~/Library/Python/3.14/lib/python/site-packages'))

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen


def download_font_curl(url: str, tmp_dir: str) -> str:
    assert url.startswith("https://fonts.gstatic.com/"), (
        f"Security (T-97-03): only fonts.gstatic.com permitted. Got: {url}"
    )
    out = os.path.join(tmp_dir, "font.ttf")
    r = subprocess.run(["curl", "-s", "-o", out, url], capture_output=True, timeout=30)
    if r.returncode != 0:
        raise RuntimeError(f"curl failed: {r.stderr.decode()}")
    return out


def text_to_paths(text, font, em_size=64.0, tracking=0.0):
    """Return list of (char, path_element_str) tuples. tracking is em fraction per glyph."""
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    upm = font["head"].unitsPerEm
    scale = em_size / upm
    tracking_units = tracking * upm

    result = []
    x_cursor = 0.0

    for ch in text:
        glyph_name = cmap.get(ord(ch))
        if not glyph_name:
            fallback_adv = font["hmtx"].metrics.get("space", (500, 0))[0]
            x_cursor += fallback_adv + tracking_units
            print(f"  Warning: no glyph for {ch!r}", file=sys.stderr)
            continue

        pen = SVGPathPen(glyphs)
        glyphs[glyph_name].draw(pen)
        d = pen.getCommands()
        adv = glyphs[glyph_name].width

        if d:
            x_px = x_cursor * scale
            t = f"translate({x_px:.3f},{em_size:.3f}) scale({scale:.6f},-{scale:.6f})"
            result.append((ch, f'  <!-- glyph: {ch} -->\n  <path transform="{t}" d="{d}"/>'))

        x_cursor += adv + tracking_units

    total_w = x_cursor * scale
    return result, total_w


def main():
    parser = argparse.ArgumentParser(description="Glyph-to-path converter for Rulestead tournament tooling")
    parser.add_argument("--font-url", required=True, help="Pinned fonts.gstatic.com TTF URL")
    parser.add_argument("--text", default="Rulestead")
    parser.add_argument("--em-size", type=float, default=64.0)
    parser.add_argument("--tracking", type=float, default=0.0, help="Letter-spacing in em fractions (e.g. -0.02)")
    args = parser.parse_args()

    tmp_dir = tempfile.mkdtemp(prefix="rulestead_glyphs_")
    try:
        print(f"Downloading font from {args.font_url}", file=sys.stderr)
        ttf_path = download_font_curl(args.font_url, tmp_dir)
        font = TTFont(ttf_path)
        print(f"Loaded. UPM={font['head'].unitsPerEm}", file=sys.stderr)

        paths, total_w = text_to_paths(args.text, font, args.em_size, args.tracking)
        print(f"'{args.text}': {len(paths)} glyphs, total_w≈{total_w:.1f}px at em={args.em_size}", file=sys.stderr)

        print(f"<!-- gen_glyph_paths.py: {args.text!r} em={args.em_size} tracking={args.tracking} -->")
        print(f"<!-- Total advance width: {total_w:.3f} SVG units -->")
        for _, elem in paths:
            print(elem)
    finally:
        import shutil; shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()
```

### pathops Boolean Op for Glyph Modification

```python
# Source: verified session test (2026-06-11)
# Use case: carve a diamond notch into a crossbar or round a terminal corner
import pathops

def get_glyph_path(glyph_name, glyphs):
    """Extract glyph outline into a pathops.Path."""
    path = pathops.Path()
    pen = pathops.PathPen(path)
    glyphs[glyph_name].draw(pen)
    return path

def boolean_op(path_a, path_b, operation):
    """
    Apply boolean operation. operation is pathops.PathOp value.
    Returns new Path.
    """
    result = pathops.Path()
    pathops.op(path_a, path_b, operation, result)
    return result

# Example: subtract a notch shape from the 'e' counter
e_path = get_glyph_path("e", glyphs)
notch_path = pathops.Path()
# Draw a diamond notch manually on the notch_path
notch_path.moveTo(x1, y1); notch_path.lineTo(x2, y2); ...  notch_path.close()
e_with_notch = boolean_op(e_path, notch_path, pathops.PathOp.DIFFERENCE)
# Then draw e_with_notch to SVGPathPen to get the d string
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| urllib.request for font CDN fetch | curl subprocess | 2026 (exec-env constraint) | urllib hangs on gstatic; curl works reliably |
| Single merged wordmark path blob | Per-glyph paths with per-glyph transforms | Phase 102 (new) | Enables independent letterform editing for tournament |
| `fontTools.pens.pathops` wrapper | Direct `pathops` module (via skia-pathops) | fontTools 4.62.1 user install | fontTools.pens.pathops not included in user install; direct `import pathops` works |
| `--headless=old` Chrome flag | `--headless=new` (Chrome 112+) | Chrome 112 (2023) | Old headless mode deprecated; new mode required for Chrome 149 |
| SVGO `.svgorc` JSON config | `svgo.config.mjs` (SVGO 4.x) | SVGO 4.0 (2024) | JSON config no longer supported |

**Deprecated:**
- `urllib.request` for gstatic downloads — hangs in this environment; use curl
- `fontTools.pens.pathops` import path — use `import pathops` directly
- Merging all glyph paths into a single `d` string — prevents per-letterform editing

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Outlining font glyphs to SVG paths for logo artwork is OFL-permitted (settled interpretation) | Font Licensing | If wrong, the tournament cannot use any of these fonts. Low risk — this is the universally accepted OFL interpretation and confirmed by OFL FAQ. |
| A2 | GPOS kerning values in Space Grotesk, Archivo, IBM Plex Sans are similarly negligible at logo size | fontTools Pipeline | If wrong, wordmarks in alternate fonts may need kern adjustments. Mitigated by `--tracking` param for gross spacing control. |
| A3 | The integrated-typemark taxonomy (modified-glyph, ligature, negative-space, monogram-fused) is sufficient to frame the audit and tournament axes | Design Research | If wrong, the audit or Phase 103 rounds may miss an approach. Low risk — these categories cover the relevant design space for this project. |
| A4 | Phase 97 `logo-studio.html` structure (inline SVG, light+dark cards, size strip) is sufficient as the Phase 102 studio template | Architecture Patterns | Planner may need to deviate if the maintainer's review needs change. Pattern is flexible — it is throwaway tooling. |
| A5 | `pathops.op(path_a, path_b, pathops.PathOp.UNION, result_path)` API takes the result path as the 4th argument (not return value) | Code Examples | If wrong, the boolean op code would need adjustment. Verified in session: `op()` returns the Path object description; `result_path` is modified in-place. |

---

## Open Questions

1. **Incumbent audit verdict detail level**
   - What we know: D-01 says KEEP/TIGHTEN/REWORK verdicts; the shipped lockup is icon-left which is the pattern the brand book rejects.
   - What's unclear: Should the audit also rate the wordmark typography (Sora Bold, the glyph paths) separately from the lockup composition? The glyph paths may be KEEP-worthy even if the composition is REWORK.
   - Recommendation: Audit both dimensions separately: (a) composition verdict (REWORK — icon-left antipattern confirmed) and (b) typography verdict (KEEP/TIGHTEN — Sora Bold glyph fidelity is fine; possible TIGHTEN on tracking). This gives Phase 103 clear guidance on what to carry forward vs. what to challenge.

2. **Studio HTML: should it embed the incumbent as the "control"?**
   - What we know: The CONTEXT.md specifics say "The audit's incumbent assessment doubles as the 'control' entry on the Round 1 sheet."
   - What's unclear: The Phase 102 studio is the TEST harness for tooling verification; the Round 1 sheet is Phase 103's responsibility. Does Phase 102's studio include the incumbent, or just a technical test render?
   - Recommendation: Include the incumbent (shipped `rs-wordmark.svg` paths) as "Incumbent / Control" in the Phase 102 studio grid, alongside a test candidate rendered from `gen_glyph_paths.py`. This satisfies the success criterion ("confirmed by producing at least one test render") and establishes the visual baseline.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | gen_glyph_paths.py | Yes | 3.14.4 | — |
| fontTools TTFont + SVGPathPen | gen_glyph_paths.py | Yes | 4.62.1 (user install) | — |
| curl | TTF download | Yes | system | — |
| skia-pathops (`import pathops`) | Boolean ops (D-10 optional) | Yes | 0.9.2 (homebrew install) | evenodd subpath technique |
| Google Chrome.app | Studio render harness | Yes | 149.0.7827.103 | — |
| fonts.gstatic.com CDN | TTF download | Yes (HTTP 200 on all 12 URLs) | Sora v17, SpaceGrotesk v22, Archivo v25, IBMPlexSans v23 | Pin alternate URL via css v1 API |
| npx svgo | SVG optimization (Phase 104) | Yes | 4.0.1 | Not needed in Phase 102 |
| Inkscape | Alternative text-to-path | No | — | fontTools (primary — preferred) |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** skia-pathops boolean ops → evenodd technique (documented). skia-pathops IS installed; fallback only needed if the homebrew install is later removed.

---

## Validation Architecture

`workflow.nyquist_validation` is `true` in `.planning/config.json`. Include validation.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash/grep/Python inline assertions (no test framework needed — file-existence and output checks) |
| Config file | none |
| Quick run command | `python3 scripts/gen_glyph_paths.py --font-url URL --text "RS" \| grep -c '<path'` (expect 2) |
| Full suite command | `bash scripts/ci/lint.sh` (SVG budget check; no new committed SVGs in Phase 102 except phase-dir HTML) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BRD-06 | `102-AUDIT.md` exists with KEEP/TIGHTEN/REWORK verdicts | smoke | `test -f .planning/phases/102-logo-delta-audit-tournament-studio/102-AUDIT.md` | No — Wave 1 creates it |
| BRD-06 | Audit covers HTML brand book presentation quality | smoke | `grep -c "index.html" .planning/phases/102-.../102-AUDIT.md` (expect > 0) | No |
| LOGO-06 | `gen_glyph_paths.py` accepts `--font-url` | smoke | `python3 scripts/gen_glyph_paths.py --help \| grep font-url` | No — Wave 2 creates it |
| LOGO-06 | Emits one path per glyph | unit | `python3 scripts/gen_glyph_paths.py --font-url URL --text "RS" \| grep -c '<path'` (expect 2) | No |
| LOGO-06 | Fetches via curl, not urllib | code-review | `grep -c "urllib" scripts/gen_glyph_paths.py` (expect 0) | No |
| LOGO-06 | Studio HTML exists in phase dir | smoke | `test -f .planning/phases/102-.../102-studio.html` | No — Wave 2 creates it |
| LOGO-06 | Render helper produces at least one PNG | smoke | `bash .planning/phases/102-.../render_studio.sh && ls .planning/phases/102-.../*.png` | No |
| LOGO-06 | `102-RESEARCH.md` records pinned gstatic URLs | smoke | `grep -c "fonts.gstatic.com" .planning/phases/102-.../102-RESEARCH.md` (expect ≥ 12) | Yes (this file) |

### Wave 0 Gaps

None — no test framework files to create. All validations are inline commands.

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Partial | `--font-url` assertion: `assert url.startswith("https://fonts.gstatic.com/")` (mirrors T-97-03) |
| V6 Cryptography | No | — |
| V9 Communications | Yes | HTTPS-only TTF download via curl; pinned direct URLs (no CDN redirect guessing) |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Arbitrary URL in `--font-url` fetching from untrusted host | Tampering | `assert url.startswith("https://fonts.gstatic.com/")` — same guard as T-97-03 in Phase 97; fail fast with clear error |
| SVG script injection in a modified candidate | Tampering / XSS | All tournament SVGs are hand-authored path data; SVGO `preset-default` removes scripts; grep check `grep -c '<script' candidate.svg` |
| Chrome rendering an HTML file from a writable location | Information Disclosure | Studio HTML is in `.planning/` (not served by Phoenix); only headless render for local visual review, never served publicly |

---

## Sources

### Primary (HIGH confidence)
- `scripts/gen_wordmark_paths.py` — Phase 97 working implementation; urllib confirmed on line 48; SVGPathPen pattern verified [VERIFIED: codebase inspection]
- `brandbook/assets/logo/rs-wordmark.svg` — shipped lockup inspected; icon-left-of-text confirmed [VERIFIED: SVG source read]
- `brandbook/brand-book.md` §14 — "Start with a strong Rulestead wordmark" recommendation read [VERIFIED: file read]
- Python session tests — fontTools SVGPathPen, GPOS kerning, pathops, glyph download [VERIFIED: executed 2026-06-11]
- gstatic TTF URLs — all 12 URLs confirmed HTTP 200 [VERIFIED: curl HEAD requests 2026-06-11]
- Google Fonts CSS v1 API — TTF URL discovery confirmed [VERIFIED: curl responses read 2026-06-11]
- OFL.txt files — Sora, Space Grotesk, Archivo, IBM Plex Sans — read from GitHub [VERIFIED: curl HTTP 200 2026-06-11]
- `slopcheck install fonttools skia-pathops` — both OK [VERIFIED: slopcheck output 2026-06-11]
- `pip show skia-pathops` — version 0.9.2 at `/opt/homebrew/lib/python3.14/site-packages` [VERIFIED: 2026-06-11]
- headless Chrome flags — tested end-to-end including file:// relative CSS [VERIFIED: test renders produced 2026-06-11]
- `.planning/milestones/v1.14-phases/97-logo-mark-svg-system/logo-studio.html` — Phase 97 studio template inspected [VERIFIED: file read]
- `brandbook-visual-rendering.md` memory — urllib gotcha, Chrome flags, theme gotcha [VERIFIED: memory file read]
- `.planning/milestones/v1.14-phases/97-logo-mark-svg-system/97-CONCEPT-REVIEW.md` — Phase 97 tournament lessons [VERIFIED: file read]

### Secondary (MEDIUM confidence)
- [Space Grotesk GitHub](https://github.com/floriankarsten/space-grotesk) — OFL 1.1 confirmed via WebSearch result + OFL.txt curl
- [Archivo GitHub](https://github.com/Omnibus-Type/Archivo) — OFL 1.1 confirmed via WebSearch result + OFL.txt curl
- scripts.sil.org/OFL — OFL FAQ on artwork use [CITED — standard OFL FAQ interpretation]

### Tertiary (LOW confidence — assumed)
- Integrated-typemark taxonomy (modified-glyph, ligature, negative-space, monogram-fused) — from training knowledge; no single authoritative source cited [ASSUMED]
- "Alter 1–2 letterforms, not more than 30%" design rule — from training knowledge [ASSUMED]
- favicon fill-only constraints at 16px — inherited from Phase 97 research [ASSUMED from design practice]

---

## Metadata

**Confidence breakdown:**
- Pinned font URLs: HIGH — all 12 URLs HTTP 200 verified in session
- Font licensing: HIGH — OFL.txt files read from official GitHub repos
- fontTools pipeline: HIGH — tested in session, working code from Phase 97
- skia-pathops: HIGH — installed, importable, API tested
- headless Chrome: HIGH — tested end-to-end, flags confirmed, file:// CSS confirmed
- GPOS kerning assessment: HIGH — measured in session (Sora Ru/te = −2 font units)
- Integrated-typemark taxonomy: MEDIUM/ASSUMED — design knowledge, not from a citeable spec source

**Research date:** 2026-06-11
**Valid until:** 2026-08-11 (font CDN URLs: stable; Google Fonts rarely changes v-pinned TTF URLs. fontTools + pathops: stable mature libraries)

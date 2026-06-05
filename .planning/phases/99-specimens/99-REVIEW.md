---
phase: 99-specimens
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - brandbook/assets/specimens/palette.svg
  - brandbook/assets/specimens/typography.svg
  - brandbook/assets/specimens/components.svg
  - brandbook/assets/specimens/code-block.svg
  - brandbook/assets/specimens/readme-header.svg
  - brandbook/assets/specimens/social-card.svg
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: resolved
resolution: "WR-01, WR-02, IN-01, IN-02 fixed in commit 2f6f115; IN-03, IN-04 accepted as intentional (convention / design choice)."
---

# Phase 99: Code Review Report

**Reviewed:** 2026-06-05
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Six static SVG brand specimen assets were reviewed. All six are well-formed XML
(`xmllint --noout` passes), self-contained, and within the 51200-byte CI budget
(largest is `palette.svg` at 10034 bytes). There are no security concerns: no
`<script>`, no `foreignObject`, no event-handler attributes, no `base64`, and no
external/`xlink:href`/`<use href>` references in any file. The accessible skeleton
(`role="img"`, `aria-labelledby="t d"`, `<title id="t">`, `<desc id="d">`, content
wrapped in `<g aria-hidden="true">`) is applied consistently and matches the
pattern map.

Hex-value fidelity is strong. Every swatch fill in `palette.svg` exactly matches
both its printed hex text label and the corresponding value in `brandbook/tokens.json`.
Component/code-block/header/social-card fills cross-check cleanly against
`tokens.json` and `admin_css_mapping`. Typography font-sizes match the pattern-map
px approximation table exactly (32/22/18/17/15/14/12/11). No element overflows its
viewBox in any file.

The defects found are quality issues, not correctness or security failures. The two
warnings concern (1) an oversized `components.svg` canvas that renders half-blank and
(2) a semantically inconsistent "enabled" label rendered as a neutral-gray chip in
one place and a green success badge in another within the same file. Info items cover
additional dead-canvas padding and an accessibility note about hex/token labels being
hidden from assistive tech.

## Warnings

### WR-01: `components.svg` viewBox is ~2x taller than its content (50% empty canvas)

**File:** `brandbook/assets/specimens/components.svg:1`
**Issue:** The root `viewBox="0 0 800 560"` declares a 560px-tall canvas, but the
last visual element (the Badges row) ends at approximately y=286. Roughly 50% of the
rendered area below the content is blank. The `<desc>` advertises "Buttons ... card,
and badge variants" — all present — but anyone embedding or screenshotting this
specimen at its natural aspect ratio gets a large dead band of `#f8fafc` background.
This degrades the specimen's usefulness as a drop-in reference image and is
inconsistent with `social-card.svg` (3% empty) and `palette.svg` (16% empty).
**Fix:** Tighten the height to fit the content with a small bottom margin, e.g.:
```xml
<svg role="img" xmlns="http://www.w3.org/2000/svg" aria-labelledby="t d" viewBox="0 0 800 310">
```
Adjust the background `<path>` height (`d="M0 0h800v560H0z"`) to match the new
viewBox height as well.

### WR-02: Inconsistent semantics for the "enabled" label within `components.svg`

**File:** `brandbook/assets/specimens/components.svg` (card badge ~line 1, `x="40" y="185"`; badges row, `x="108" y="264"`)
**Issue:** The same word "enabled" is rendered two ways in one specimen:
- Inside the Card, the "enabled" chip uses the **neutral** palette: fill `#eef1f5`,
  border `#d8dee6`, text `#5c6b7a` (gray).
- In the Badges row, the "enabled" badge uses the **success** palette: fill `#dcfce7`,
  border `#86efac`, text `#2d7753` (green).

A brand specimen exists to demonstrate the canonical mapping of state -> color. Showing
the identical state label "enabled" in two different color treatments in the same image
is contradictory and will mislead anyone using this as the reference. (For comparison,
the admin success token is `#2d7753`, so the green badge is the correct mapping; the
card chip should either use a different label such as "status" / "neutral" or adopt the
success treatment.)
**Fix:** Make the two consistent. Either relabel the card chip (e.g. to a neutral
metadata label) or restyle it to the success palette so "enabled" always maps to the
success/green treatment:
```xml
<!-- card chip, if it should mean enabled -->
<rect width="76" height="22" x="40" y="185" fill="#dcfce7" stroke="#86efac" rx="999"/>
<text x="78" y="200" fill="#2d7753" ... >enabled</text>
```

## Info

### IN-01: `typography.svg` has ~26% empty vertical canvas

**File:** `brandbook/assets/specimens/typography.svg:1`
**Issue:** `viewBox="0 0 760 580"` but the last text row (the "Scale tokens:" footer)
ends near y=430, leaving ~150px (~26%) of blank canvas at the bottom. Less severe than
WR-01 but the same class of dead-space padding.
**Fix:** Reduce the viewBox height (and the background `<path>` height `d="M0 0h760v580H0z"`)
to roughly `460`–`480`.

### IN-02: `readme-header.svg` has ~29% empty vertical canvas

**File:** `brandbook/assets/specimens/readme-header.svg:1`
**Issue:** `viewBox="0 0 480 96"` but content (wordmark + tagline) ends near y=68,
leaving ~28px (~29%) of empty space below. For a header strip this is more defensible
(headers often carry breathing room), but worth a deliberate decision rather than
incidental padding.
**Fix:** Optional — tighten to `viewBox="0 0 480 80"` (and background path height) if a
tighter crop is desired.

### IN-03: Hex/token text labels are hidden from assistive technology

**File:** all six files (content wrapped in `<g aria-hidden="true">`)
**Issue:** All visual content, including the hex codes and `--rs-*` token names in
`palette.svg`, lives inside `<g aria-hidden="true">`. A screen-reader user therefore
receives only the `<desc>` text, never the individual swatch hex/token values. This is
consistent with the documented pattern-map convention and is acceptable for decorative
brand imagery, but note that `palette.svg`'s `<desc>` does not enumerate any actual hex
values or token names — so the specimen's data content is entirely inaccessible.
**Fix:** Acceptable as-is per project convention. If richer accessibility is later
desired, expand the `<desc>` to summarize the represented tokens, or expose select
labels via `aria-label` outside the hidden group. No change required for this phase.

### IN-04: `code-block.svg` window-control dots render as a single flat color

**File:** `brandbook/assets/specimens/code-block.svg` (three `<circle>` at `cy="18"`)
**Issue:** The three "traffic light" window dots all use `fill="#2e3d52"` (the same
dark border color). This is purely cosmetic and intentional (monochrome treatment), so
not a defect — flagged only so a reviewer confirms the monochrome choice is intended
rather than three missing distinct colors. All three hex values match `tokens.json`
`dark-300`.
**Fix:** None required. If distinct dots are wanted, assign three different mineral
hexes; otherwise leave as-is.

---

_Reviewed: 2026-06-05_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

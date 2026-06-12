# Phase 104: winner-lockup-family - Context

**Gathered:** 2026-06-11 (decisions frozen by 103-WINNER.md — the executable contract)
**Status:** Ready for execution

<domain>
## Phase Boundary
Build the complete canonical asset family FROM `103-logo-tournament/candidates/a3-3.svg`
and reconcile all brand sources. No admin/demo propagation (Phase 105), no index.html
chrome redesign (Phase 106 — only a regen to un-break the drift check). Requirements:
LOGO-09, LOGO-10.
</domain>

<decisions>
## Locked decisions
- **D-01:** `103-WINNER.md` is the binding contract: geometry frozen, derivations
  (dark swap, mono, d-sigil mark/favicon crop, tagline secondary, social card) specified
  there. Do not redraw; transform the canonical source.
- **D-02:** Keep existing filenames in `brandbook/assets/logo/`: rs-wordmark.svg,
  rs-wordmark-dark.svg, rs-mark.svg, rs-mark-dark.svg, rs-mark-mono.svg, rs-favicon.svg,
  rs-social-card.svg. ADD: rs-wordmark-tagline.svg. Old G4c-era files are REPLACED in
  place (concepts/ history preserves the old era).
- **D-03:** Token sweep is a NO-OP — winner uses frozen palette + Sora Bold (no
  tokens.json/tokens.css/admin-CSS/font-URL changes). Assert guards still pass anyway.
- **D-04:** SVGO via existing brandbook/assets/logo/svgo.config.mjs (`npx svgo`); pin
  floatPrecision if not already; keep `role="img"` + `<title>`/`<desc>` post-optimize;
  20,480-byte budget per logo SVG (lint.sh enforces).
- **D-05:** brand-book.md §14 rewritten from "Logo direction" (exploratory) to shipped
  "Logo system": construction (route collinear from R leg, node semantics), clear space
  (≥1 cap height), min sizes (lockup ≥120px width; below that use d-sigil), variant usage
  table, misuse list (no container rects, no icon-left recomposition, no tagline in
  primary, no recolor/redraw). Tournament provenance one-liner.
- **D-06:** Regenerate affected specimens: readme-header.svg + social-card.svg (new
  lockup), typography.svg untouched (no font change). Specimen budget 51,200 bytes.
- **D-07:** Update scripts/check_brandbook_html.py FINAL_LOGO_SOURCE_REFS (+ tagline
  variant), BUDGET.md asset table if it lists files, then regen index.html via
  scripts/gen_brandbook_html.py so the drift check passes. brandbook/README.md and
  docs/brand-usage.md updated if they enumerate logo files.
- **D-08:** Favicon: transparent d-sigil per winner spec; verify in a real Chrome tab at
  16px (harness render of an HTML page with <link rel="icon">); solid-bg fallback file
  only if contrast genuinely fails.
- **D-09:** Demo/admin static copies are Phase 105 — do NOT touch them here.
</decisions>

<canonical_refs>
- .planning/phases/103-logo-tournament/103-WINNER.md (THE contract)
- .planning/phases/103-logo-tournament/candidates/a3-3.svg (canonical source)
- brandbook/assets/logo/ + svgo.config.mjs, brandbook/BUDGET.md
- brandbook/brand-book.md §14, brandbook/README.md, brandbook/docs/brand-usage.md
- scripts/check_brandbook_html.py (FINAL_LOGO_SOURCE_REFS), scripts/gen_brandbook_html.py,
  scripts/ci/lint.sh, scripts/check_brand_tokens.py, check_tokens_css.py, check_synced_pair.py
</canonical_refs>

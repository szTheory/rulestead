# Phase 105: propagation-admin-demo - Context
**Gathered:** 2026-06-12 · **Status:** Ready (maintainer decision: proceed on v1.15 now; polish branch resolves conflicts later on its side)

<domain>
Propagate the shipped winner identity (brandbook/assets/logo/, Phase 104) to every rendered surface: admin shell wordmark + --logo-* CSS vars (all theme blocks), admin static marks, demo logo + favicon (+ phx.digest regen). Requirement: LOGO-11. No brandbook source changes; no index.html chrome changes (106).
</domain>

<decisions>
- D-01: shell.ex brand wordmark inline SVG replaced with the rs-wordmark geometry, classed by SEMANTIC ROLE so the existing --logo-* var pattern carries: route/trace = --logo-line, lit copper node = --logo-active, muted nodes = --logo-muted, type glyphs = --logo-type. New aspect ratio 340:62 (was 372:64) — update .rs-shell__wordmark sizing + aspect-ratio.
- D-02: CSS: redefine the four --logo-* values per the winner palette in ALL theme blocks (light default, system-dark @media, explicit dark pin, explicit light pin), preserving the synced-pair discipline (check_synced_pair.py must stay green): light = line #3A6F8F / active #9b5931 / muted #C4CCD1 / type #183247; dark = line #5885a0 / active #9b5931 / muted #3d4a55 / type #e8edf3.
- D-03: admin static images (rulestead_admin/priv/static/images/rs-mark*.svg etc.) replaced with Phase 104 d-sigil family; design-system.html / theme-control-harness.html updated ONLY where they embed the old wordmark/mark.
- D-04: demo: logo.svg → new lockup, favicon.svg/ico → new d-sigil favicon (ico regenerated from the SVG render; BUDGET-sanctioned binary), then mix phx.digest.clean --all && mix phx.digest (Phase 97 documented procedure); root.html.heex untouched (no font change).
- D-05: verification: admin LiveView test suite + demo favicon-related e2e if cheap; screenshot evidence light+dark at 36px header via theme harness or admin page render; check_synced_pair + check_brand_tokens still green.
</decisions>
<canonical_refs>
- 103-WINNER.md, brandbook/assets/logo/* (shipped family), 104-01-SUMMARY.md
- rulestead_admin/lib/rulestead_admin/components/shell.ex, rulestead_admin/priv/static/css/rulestead_admin.css
- examples/demo/backend/priv/static/, scripts/check_synced_pair.py
</canonical_refs>

# Phase 107: Brand/UI Audit + UI-SPEC — Context

**Gathered:** 2026-06-12
**Status:** Ready

## Ground Truth

- v1.15 identity is frozen: A3-3 integrated Sora wordmark, route from the R leg, copper selected node, d-sigil small mark.
- v1.14 palette/tokens are canonical; token mirrors must remain checked by `check_brand_tokens.py`, `check_tokens_css.py`, and synced-pair guards.
- v1.13 theme model remains canonical: `.rs-shell` / `[data-rulestead]` scoped tokens, System/Light/Dark, mineral-dark base.

## Brand Boundary

Rulestead-owned surfaces:

- mounted admin shell and all admin routes
- brandbook generated HTML
- admin static fixtures and theme harnesses
- Phoenix demo launcher chrome, favicon, and logo

Host-owned surface:

- FleetDesk Next.js app. It must remain a distinct sample customer app, not a Rulestead-branded product.

## Risks

- Static fixtures can drift from the real admin shell.
- Browser evidence can prove file fixtures but miss live admin route clusters.
- Old pre-brand generic blue/teal literals can survive in focus rings, demo styles, or tests.
- Full pixel baselines would be high-maintenance for little adopter value.

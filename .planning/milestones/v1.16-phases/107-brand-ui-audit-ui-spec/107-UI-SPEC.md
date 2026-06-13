# Phase 107 UI-SPEC — Brand-Faithful UI Iteration

## North Star

The admin should feel like calm infrastructure: dense, legible, stable, and brand-specific. The demo should teach the adopter story: Rulestead is the mounted operator/control plane; FleetDesk is the host product.

## Required Behaviors

- Rulestead lockup is visible on admin/demo/fixture surfaces at usable sizes in light, dark, and system modes.
- The logo is derived from canonical v1.15 assets or the existing inline shell geometry; no redraws.
- Focus rings, selected states, primary actions, and soft-primary surfaces use Stead Blue-derived values, not old generic blues.
- FleetDesk has its own tokenized visual system and supports system dark mode, but does not use the Rulestead wordmark or claim to be Rulestead.
- Evidence uses broad screenshots/assertions across route clusters, theme modes, and desktop/mobile widths.

## Non-Goals

- Runtime API, schema, storage, package, or release-flow changes.
- New component libraries or CSS build systems.
- Pixel baseline snapshots for every route.
- Forced-colors/high-contrast OS mode.
- `rulestead_admin` publish preparation.

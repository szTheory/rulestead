---
phase: 115
slug: foundations-hardening
status: active
requirements: [FND-01, FND-02, FND-03, FND-04, FND-05, FND-06]
created: 2026-06-14
---

# Phase 115 Foundations Contract

This contract records the mounted-admin foundation rules that later v1.17 phases
must cite instead of rediscovering. It is source-backed by
`rulestead_admin/priv/static/css/rulestead_admin.css`, `brandbook/tokens.css`,
and `brandbook/brand-book.md`.

## Scope

Phase 115 is foundation-only. Allowed work is limited to breakpoint usage,
scalar token documentation, typography rhythm, radius and shape rules,
shadow/elevation discipline, focus affordances, reduced-motion behavior, dense
technical content containment, and focused matrix evidence.

Do not add product behavior, public routes, schemas, package metadata,
release-workflow changes, Storybook/PhoenixStorybook, checked-in pixel baselines,
FleetDesk rebranding, logo redraws, palette redesigns, component-framework
adoption, or `rulestead_admin` standalone publish preparation.

## Breakpoint Contract

The canonical admin breakpoint set is the documented rem set in
`rulestead_admin.css`:

| Token | Value | Meaning |
| --- | --- | --- |
| `--bp-sm` | `40rem` / 640px | Large phone / small tablet |
| `--bp-md` | `48rem` / 768px | Tablet |
| `--bp-lg` | `60rem` / 960px | Small desktop |
| `--bp-xl` | `75rem` / 1200px | Shell max |

New repeatable layout breakpoints must use `40rem`, `48rem`, `60rem`, or
`75rem` unless this file records a selector-level exception. The guard allows
`47.99rem` only as the max-width complement to the `48rem` rail switch.

## Noncanonical Breakpoint Exceptions

Current noncanonical media thresholds in `rulestead_admin.css` are allowed only
because they are recorded here with selector and purpose. If a threshold is
migrated to a canonical rem value, remove or update the row in the same change.

| Threshold | Direction | Selector(s) | Purpose / disposition |
| --- | --- | --- | --- |
| `760px` | min | `.rs-form-grid--two` | Two-column form layout when the paired fields have enough room; candidate for later `48rem` migration after form-route proof. |
| `720px` | min | `.rs-radio-card-grid--two`, `.rs-radio-card-grid--three`, `.rs-radio-card-grid--value-types` | Radio-card fit threshold below tablet canonical to avoid overly late card grouping on medium widths. |
| `1040px` | min | `.rs-radio-card-grid--value-types` | Five-value-type card row needs wider content capacity than `60rem`; content-specific exception. |
| `900px` | min | `.rs-shell__breadcrumbs`, `.rs-shell__header`, `.rs-hub-priority`, `.rs-task-board`, `.rs-hub-grid`, `.rs-runbook__state`, `.rs-runbook__action`, `.rs-runbook__context`, `.rs-rollouts__layout`, `.rs-rules-workspace__layout` | Legacy admin desktop assembly threshold used across page-level layouts; migrate only with broad matrix screenshots. |
| `47.99rem` | max | `.rs-shell__rail-link--overview` | Canonical `48rem` complement for the mobile rail treatment. |
| `700px` | min | `.rs-filter-grid` | Compact filter panel becomes three columns before tablet width; content-specific exception. |
| `860px` | min | `.rs-hub-hero` | Hub hero side rail needs content capacity between tablet and desktop. |
| `760px` | min | `.rs-env-state-grid` | Environment state cards auto-fit once cards can hold their labels without crowding. |
| `920px` | min | `.rs-progressive-detail__grid` | Three-column progressive detail layout waits for wider technical content. |
| `720px` | max | `.rs-event-timeline`, `.rs-event-timeline__item`, `.rs-event-timeline__time`, `.rs-event-panel`, `.rs-diff-card__values` | Mobile stack for audit timeline and diff content; content-specific complement to dense technical containment. |

Resolved canonical migrations:

- `.rs-tool-layout` now uses canonical `60rem` instead of the former exact pixel
  equivalent.

Feature media queries for `prefers-color-scheme: dark`,
`prefers-reduced-motion: no-preference`, and
`prefers-reduced-motion: reduce` are foundation features, not layout
breakpoints.

## Scalar Token Contract

Scalar values remain the current invariant token set. Do not introduce new
typography families, viewport-scaled type rules, spacing scales, radius scales,
z-index ladders, motion easings, or token source hierarchies in Phase 115.

| Foundation | Contract |
| --- | --- |
| Typography | Use `--rs-font-display`, `--rs-font-sans`, `--rs-font-mono`, `--rs-text-2xs` through `--rs-text-2xl`, `--rs-leading-*`, `--rs-weight-*`, and `--rs-tracking-*`. |
| Spacing | Use the existing 4px-base `--rs-space-*`, `--rs-section-gap`, and `--rs-page-gap` scale. |
| Control sizing | Use `--rs-control-h`, `--rs-control-h-sm`, `--rs-control-h-lg`, `--rs-control-px`, and `--rs-touch-target-min`. |
| Theme tokens | Keep color, surface, text, shadow, focus-color, overlay, and logo tokens scoped to `.rs-shell` / `[data-rulestead]`. |
| Guard chain | `tokens.json`, `tokens.css`, and `rulestead_admin.css` stay verified by the existing token and synced-pair guards. |

## Focus Contract

The default visible focus affordance is the unified shell ring:

`--rs-focus-ring`

Default scope:

`.rs-shell :where(a, button, input, select, textarea, [tabindex], [role="option"], [role="tab"], summary):focus-visible`

Exceptions must include either a visible replacement state or a source comment
that names the reason. The known exception is the command-palette text input:
`cmdk: inside modal`. Its modal shell and selected option state are the visible
affordance, so the input ring may be suppressed only with that marker present.

## Reduced Motion Contract

Nonessential scale, translate, staged entrance, hover lift, and confirm-pop
motion must be absent for users who request reduced motion.

Required source floor:

- CSS contains `@media (prefers-reduced-motion: reduce)`.
- The reduced-motion block sets transition and animation durations to `0ms`.
- The reduced-motion block keeps required state changes visible without relying
  on motion.
- Hover/active transform neutralization belongs in the CSS hardening plan and
  should preserve color, border, and shadow state where those states communicate
  meaning.

The existing `@media (prefers-reduced-motion: no-preference)` block remains the
place for nonessential animations and hover/entrance motion.

## Radius, Pill, Elevation, And Emphasis Rules

Use the current softened-rectangle language from the brand book:

| Surface | Radius / elevation rule |
| --- | --- |
| Product cards, panels, callouts, modals, diffs | Prefer `--rs-radius-md` or `--rs-radius-lg` with `--rs-shadow-sm`, `--rs-shadow`, or `--rs-shadow-panel`. |
| Inputs, buttons, small action links, table cells | Prefer `--rs-radius-sm` or inherited local radius. |
| Badges, tags, segmented controls, context chips | `--rs-radius-full` is allowed. Keep pill use reserved for compact state/context controls. |
| Critical/warning emphasis | Use color plus text/status semantics; avoid color-only meaning. |
| Shadows | Low-contrast elevation only. Do not add glossy, decorative, or floating hero shadows. |

No new hardcoded hex colors or new shadow roles should appear outside existing
theme-token cascade contexts.

## Dense Technical Content Rules

Dense operator evidence must avoid page-level horizontal overflow on mobile and
narrow viewports. Prefer generic containment over route-specific rewrites:

- Tables use local horizontal scrolling when needed.
- Raw JSON/code can scroll inside `.rs-raw-detail pre`; the page itself should
  remain contained.
- Long keys, targeting values, audit reasons, mutation-confirm scopes, timeline
  rows, and diff values wrap or local-scroll rather than clipping critical
  operator evidence.
- Semantic component/API rewrites are Phase 116 unless a foundation proof is
  blocked.

## Verification Commands

Primary guard:

```bash
python3 scripts/check_admin_foundations.py
```

Full targeted Phase 115 suite:

```bash
python3 scripts/check_admin_foundations.py && cd examples/demo/backend && mix test test/rulestead_demo_web/live/ui_matrix_live_test.exs && cd ../frontend && npm run test:e2e -- ui-matrix.spec.ts
```

Static fixture support:

```bash
cd examples/demo/frontend && npm run test:e2e -- design-system.spec.ts theme-control.spec.ts theme-cascade.spec.ts theme-scope.spec.ts
```

CI guard chain:

```bash
bash scripts/ci/lint.sh
```

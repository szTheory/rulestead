---
phase: 115
slug: foundations-hardening
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-14
reviewed_at: 2026-06-14T06:45:00Z
---

# Phase 115 - UI Design Contract

> Visual and interaction contract for foundation hardening. Generated inline from context, research, and existing v1.17 artifacts.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none - harden the existing Phoenix LiveView mounted admin design system |
| Preset | not applicable |
| Component library | Existing `RulesteadAdmin.Components.*` modules and route-owned HEEx only |
| Icon library | Existing admin glyphs and inline affordances only; do not add an icon package |
| Font | Keep `--rs-font-display` Sora, `--rs-font-sans` Inter, and `--rs-font-mono` IBM Plex Mono |

No shadcn, Tailwind, React, Storybook, PhoenixStorybook, third-party registry, package install, public route, schema, release workflow, palette redesign, logo redraw, FleetDesk rebrand, or `rulestead_admin` publish-prep change belongs in this phase.

---

## Scope Guardrails

| Guardrail | Contract |
|-----------|----------|
| Phase boundary | Harden foundations only: breakpoints, typography/scalar docs, radius, shadow/elevation, focus, reduced motion, dense-table responsiveness, and guard agreement. |
| Existing surface | Use the shipped admin CSS and Phase 114 UI matrix as the proof surface. Do not create a new component catalog. |
| Future-phase boundary | Primitive/composite consolidation is Phase 116. Page-flow IA is Phase 117. Milestone-wide evidence closeout is Phase 118. |
| Brand boundary | Palette, logo, voice, and FleetDesk host-brand boundary remain frozen. |

---

## Foundation Rules

| Foundation | Contract |
|------------|----------|
| Breakpoints | Canonical values are `40rem`, `48rem`, `60rem`, and `75rem`. Any other media threshold must be listed in `115-FOUNDATIONS-CONTRACT.md` with selector and reason. |
| Typography | Use the existing role tokens: `--rs-text-2xs` through `--rs-text-2xl`, `--rs-leading-*`, `--rs-weight-*`, and `--rs-tracking-*`. Do not add font families or viewport-scaled typography beyond existing tokens. |
| Spacing | Keep the 4px-base `--rs-space-*` scale and existing page/section gap tokens. |
| Radius | Product panels/cards use softened rectangles (`--rs-radius-md` / `--rs-radius-lg`). Pills are reserved for chips, tags, badges, segmented controls, and small context controls. |
| Shadow/elevation | Use `--rs-shadow-sm`, `--rs-shadow`, and `--rs-shadow-panel` as low-contrast elevation roles. Do not add glossy or decorative shadows. |
| Focus | The unified `--rs-focus-ring` is the default visible focus affordance. Any exception must name its visible alternative in source or the foundation contract. |
| Motion | Nonessential scale, translate, blur, staged entrance, and hover motion must be absent or disabled under `prefers-reduced-motion: reduce`. |
| Dense technical content | Long keys, raw JSON/code, diffs, tables, mutation-confirm scope rows, and timeline rows must not create page-level horizontal overflow at mobile width. Local scrolling is acceptable for code/raw detail. |

---

## Visual Hierarchy

| Area | Contract |
|------|----------|
| Shell | Preserve the current shell/header/rail hierarchy. Phase 115 may fix focus/responsive behavior but must not rename or restructure navigation. |
| Cards and panels | Keep foundation changes restrained. Do not use large hero-scale type inside cards, nested cards, decorative gradients, or oversized rounded shapes. |
| Emphasis | Use color plus text/status semantics. Avoid color-only status encoding. |
| Dense rows | Preserve scan rhythm. Wrap or local-scroll technical values rather than hiding critical operator evidence. |

---

## Interaction Contract

| Interaction | Contract |
|-------------|----------|
| Keyboard focus | Shell search, theme control, rail links, task links, form controls, subnav tabs, command palette options, and destructive controls remain keyboard reachable with visible focus. |
| Command palette | The command-palette input may suppress the ring only if the modal context and selected option state remain visibly active. |
| Reduced motion | Matrix content remains reachable and stateful under reduced motion; animation must not be required to understand state changes. |
| Mobile/narrow | The admin remains responsive but desktop-oriented. Mobile must preserve critical paths such as kill/destructive flows and avoid page-level overflow. |

---

## Evidence Contract

| Evidence target | Contract |
|-----------------|----------|
| Source guard | `scripts/check_admin_foundations.py` should prove breakpoint exception coverage, foundation contract sections, reduced-motion floor, and known focus exception markers. |
| Existing guard chain | `scripts/ci/lint.sh` should continue to run brand/token/logo/contrast/brandbook/SVG guards and add the foundation guard. |
| Browser matrix | `ui-matrix.spec.ts` should keep light/dark/system-dark, desktop/mobile, reduced-motion, no-overflow, command-palette keyboard, and screenshot artifact coverage. |
| Static fixtures | `design-system.html`, `theme-control-harness.html`, and `theme-harness.html` remain supporting low-level token/theme/focus evidence. |

---

## UI-SPEC Verification

All 6 dimensions pass:

| Dimension | Result | Notes |
|-----------|--------|-------|
| Design-system fit | PASS | Reuses existing admin CSS and component system. |
| Scope control | PASS | No new product or package surface. |
| Accessibility | PASS | Focus, keyboard, reduced motion, no color-only semantics preserved. |
| Responsiveness | PASS | Mobile/narrow work is no-overflow and critical-path preservation. |
| Evidence | PASS | Uses matrix/static fixtures and deterministic guards. |
| Brand alignment | PASS | Preserves v1.14/v1.15 tokens, logo, shape, and motion character. |

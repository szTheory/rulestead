---
phase: 113
slug: design-system-inventory-ui-matrix-contract
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-13
reviewed_at: 2026-06-13
---

# Phase 113 - UI Design Contract

> Visual and interaction contract for the design-system inventory and future UI matrix. Phase 113 creates docs only; Phase 114 implements the repo-native matrix.

---

## Design System

| Property | Value |
| --- | --- |
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix.Component / Phoenix LiveView already in repo |
| Icon library | none added |
| Font | `Sora` display, `Inter` sans, `IBM Plex Mono` mono from `brandbook/tokens.css` |

---

## Spacing Scale

Declared values use the existing 4px-base token scale:

| Token | Value | Usage |
| --- | --- | --- |
| `--rs-space-1` | 0.25rem | Micro gaps |
| `--rs-space-2` | 0.5rem | Compact controls |
| `--rs-space-3` | 0.75rem | Field/control gaps |
| `--rs-space-4` | 1rem | Default card/section spacing |
| `--rs-space-5` | 1.25rem | Page gaps |
| `--rs-space-6` | 1.5rem | Dense page groups |
| `--rs-space-8` | 2rem | Major layout breaks |

Exceptions: Phase 113 must document existing exceptions if found; it must not introduce new spacing tokens.

---

## Typography

| Role | Size | Weight | Line Height |
| --- | --- | --- | --- |
| Body | `--rs-text-base` 0.95rem | `--rs-weight-normal` 400 | `--rs-leading-normal` 1.5 |
| Label | `--rs-text-sm` 0.86rem | `--rs-weight-semibold` 600 | `--rs-leading-snug` 1.35 |
| Heading | `--rs-text-lg` 1.15rem to `--rs-text-xl` 1.4rem | `--rs-weight-semibold` 600 | `--rs-leading-tight` 1.2 |
| Display | `--rs-text-2xl` clamp(1.5rem, 2vw, 2rem) | `--rs-weight-bold` 700 | `--rs-leading-tight` 1.2 |

---

## Color

| Role | Value | Usage |
| --- | --- | --- |
| Dominant (60%) | `--rs-bg`, `--rs-surface` | Shell and page surfaces |
| Secondary (30%) | `--rs-surface-muted`, `--rs-surface-faint`, `--rs-border` | Cards, sections, inputs, tables |
| Accent (10%) | `--rs-primary`, `--rs-primary-soft`, `--rs-accent` | Primary actions, selected states, specific emphasis |
| Destructive | `--rs-error`, `--rs-error-soft`, `--rs-error-border` | Destructive actions, kill/cleanup/delete/denied states |

Accent reserved for: primary actions, selected navigation, focus-supporting soft-primary surfaces, and documented operator emphasis. Do not use accent for all interactive elements.

---

## Required State Contract

The Phase 113 matrix contract must name every required state before Phase 114 implementation:

| State | Required Coverage |
| --- | --- |
| normal | Baseline component/page rendering |
| dense | High row count, compact metadata, or packed technical data |
| empty | No records or no available evidence |
| loading | Pending async/refresh flow where the source supports it |
| error | Failed load, validation error, or unavailable dependency |
| permission-denied/read-only | Capability denied, hidden, or unavailable action |
| long-label/long-key | Long flag keys, tenant/environment names, audit reasons, JSON/code values, and command labels |
| narrow-width/mobile | No horizontal page overflow and preserved primary actions |
| destructive-action | Kill, cleanup/archive/delete, risky rollout jump, governed execute, typed confirmation |
| disabled/unavailable | Disabled controls, unavailable env/tenant, blocked guardrail or action |
| focus/keyboard | Visible focus and keyboard path for links, buttons, forms, tabs, command palette, and task links |

Evidence dimensions: light, dark, system-dark, desktop, mobile/narrow, and reduced-motion where behavior or visual correctness changes.

---

## Copywriting Contract

| Element | Copy Rule |
| --- | --- |
| Primary CTA | Specific verb + domain noun, for example "Publish rules" or "Confirm kill switch" |
| Empty state heading | State the absent object, not generic emptiness |
| Empty state body | Explain next step or why there is no action |
| Error state | Name the problem and a recovery path |
| Destructive confirmation | Action-specific warning, typed confirmation when production/destructive risk requires it, required reason, and back link |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
| --- | --- | --- |
| shadcn official | none | not required |
| third-party registries | none | no registry code allowed in Phase 113 |

---

## Phase Boundary

- Phase 113 creates planning/design artifacts only.
- No runtime API, schema, migration, package, release workflow, palette, logo, component framework, broad pixel-baseline, FleetDesk rebrand, or `rulestead_admin` publish-prep work is allowed.
- Static fixtures remain token/theme guard inputs; they are not the primary future component contract.

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-06-13

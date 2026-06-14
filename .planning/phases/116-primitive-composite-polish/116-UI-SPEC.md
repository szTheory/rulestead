---
phase: 116
slug: primitive-composite-polish
status: approved
shadcn_initialized: false
preset: none
created: 2026-06-14
reviewed_at: 2026-06-14T15:05:43Z
---

# Phase 116 - UI Design Contract

> Visual and interaction contract for primitive and composite polish. Generated inline from Phase 116 context and verified against the six UI checker dimensions.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none - existing Phoenix LiveView components and mounted-admin CSS |
| Preset | not applicable |
| Component library | Phoenix.Component plus `RulesteadAdmin.Components.*`; no third-party UI registry |
| Icon library | Existing inline glyphs/SVG affordances only; do not add an icon package |
| Font | `--rs-font-display` Sora for display/title roles, `--rs-font-sans` Inter for UI/body roles, `--rs-font-mono` IBM Plex Mono for keys, fingerprints, JSON, and code values |

Manual design-system source: `rulestead_admin/priv/static/css/rulestead_admin.css`, `115-FOUNDATIONS-CONTRACT.md`, and the reusable component modules under `rulestead_admin/lib/rulestead_admin/components/`.

No shadcn, Tailwind, React, Storybook, PhoenixStorybook, third-party registry, public route, schema, release workflow, palette redesign, logo redraw, FleetDesk branding, or `rulestead_admin` publish-prep change belongs in this phase.

---

## Scope Guardrails

| Guardrail | Contract |
|-----------|----------|
| Foundation reuse | Use Phase 115's breakpoint, focus, reduced-motion, radius/elevation, and dense-content rules. Do not redefine foundation policy. |
| Component source | Prefer existing function components with `attr` and `slot` contracts. Do not introduce LiveComponents for ordinary markup reuse. |
| Matrix proof | Use `/dev/rulestead-admin/ui-matrix` as the primary review surface and extend deterministic fixtures only where a component state is missing. |
| Raw markup | Consolidate repeated `rs-*` markup only when it is a stable primitive or composite; document page-owned exceptions for Phase 117. |
| Product semantics | Preserve authorization, governance, audit, rollout, preview uncertainty, and authored-state behavior exactly. |

---

## Spacing Scale

Declared values for new component polish decisions (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, compact metadata gaps, badge/tag internals |
| sm | 8px | Inline button groups, form helper gaps, compact list rows |
| md | 16px | Default component stack gaps and card internals |
| lg | 24px | Composite panel padding and grouped evidence spacing |
| xl | 32px | Major component group separation inside matrix/page sections |
| 2xl | 48px | Large taxonomy bucket breaks when needed |
| 3xl | 64px | Page-level spacing only; avoid inside compact components |

Exceptions: existing admin components keep their current internal tokenized spacing unless the polish work proves a component-level inconsistency. Any exception must stay inside `--rs-space-*`, `--rs-section-gap`, or `--rs-page-gap` contracts from Phase 115.

---

## Typography

Use existing admin scalar tokens. Do not add viewport-scaled type or new font families.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | `--rs-text-base` / 0.95rem | `--rs-weight-normal` / 400 | `--rs-leading-normal` / 1.5 |
| Label | `--rs-text-sm` / 0.86rem | `--rs-weight-semibold` / 600 | `--rs-leading-snug` / 1.35 |
| Heading | `--rs-text-lg` / 1.15rem | `--rs-weight-semibold` / 600 | `--rs-leading-tight` / 1.2 |
| Display | `--rs-text-2xl` / clamp(1.5rem, 2vw, 2rem) | `--rs-weight-semibold` / 600 | `--rs-leading-tight` / 1.2 |

Long keys, fingerprints, raw audit detail, JSON, rule keys, and audience keys use `--rs-font-mono` within Body or Label roles. Component headings inside cards and panels must stay compact; do not use display-scale type inside dense composites.

---

## Color

Use the existing theme-scoped admin tokens. Phase 116 must prove light, explicit dark, and system-dark behavior without introducing new palette values.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `--rs-bg`, `--rs-surface` | Shell background, component bodies, page body |
| Secondary (30%) | `--rs-surface-muted`, `--rs-surface-faint`, `--rs-border`, `--rs-border-subtle`, `--rs-text-muted` | Cards, panels, metadata, disabled/read-only copy, separators |
| Accent (10%) | `--rs-primary` | Primary actions, active/focus emphasis, selected command/result states, section anchors |
| Destructive | `--rs-error`, `--rs-critical`, `--rs-error-soft`, `--rs-error-border` | Destructive buttons, danger confirm emphasis, denied/blocked states |

Accent reserved for: primary calls to action, active/current states, visible focus emphasis, selected command palette option, and existing route-active affordances. It is not for every link, every card border, or decorative callout.

Status tones must use text and semantics in addition to color. Warning, critical, positive, muted, archived, draft, stale, and unavailable states must remain understandable without color perception.

---

## Primitive Contract

| Primitive | Contract |
|-----------|----------|
| Buttons and action links | Use `.rs-button`, `.rs-button--primary`, `.rs-button--danger`, or `.rs-button--text` consistently. Disabled or unavailable actions need nearby explanatory copy. |
| Badges, tags, and status indicators | Keep pill usage reserved for compact state/context markers. Every badge/status must expose readable text, not only tone. |
| Cards, callouts, stats, and panels | Use softened rectangles, low-contrast elevation, compact headings, and tokenized borders from Phase 115. Avoid nested card-in-card composition. |
| Forms and field help | Consolidate repeated form-field/help/action-row markup only when it preserves LiveView form recovery, labels, errors, and `phx-change`/`phx-submit` behavior. |
| Detail grids and technical values | Long values wrap or local-scroll within the component boundary; page-level horizontal overflow remains forbidden. |
| Empty states | Empty state copy must name whether absence is valid, missing fixture/data, denied by policy, or a next-step condition. |
| Pagination and task links | Preserve keyboard/focus visibility, URL-driven state, and stable dimensions under long labels. |

---

## Composite Contract

| Composite | Contract |
|-----------|----------|
| Mutation confirms | Canonical shape is scope/evidence -> optional typed confirmation -> reason -> return link -> primary/danger submit. Disabled/unavailable variants must explain why action cannot proceed. |
| Audit, timeline, and diff | Preserve readable diff before/after labels, raw redacted JSON disclosure, rollback/action affordances, automatic/manual distinction, and long-value containment. |
| Rollout and guardrail panels | Keep guardrail evidence fail-closed and explicit. Stale, held, pending, blocked, and unavailable states must show reason and inspection path. |
| Rule editor surfaces | Keep draft/publish separation visible, missing audience errors explicit, rule order controls reachable, and long rule/audience keys contained. |
| Audience impact/dependency | Keep hidden/denied references explicit, preview uncertainty visible, and host-supplied evidence basis truthful. |
| Governance panels | Reviewer/operator variants must preserve threshold, breach, remediation, fingerprint, and redaction semantics. |
| Simulation and explain traces | Summary first, trace disclosure second. Missing host evidence and no-trace states must be honest and support-safe. |

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Review Matrix Evidence |
| Empty state heading | No examples match this state |
| Empty state body | Add or select a deterministic fixture before planning polish for this component group. |
| Error state | Component fixture failed to render. Inspect the named fixture helper and rerun the matrix smoke test after the assigns are fixed. |
| Destructive confirmation | Preview destructive change: review evidence, type the required key when production scoped, record the reason, then submit or return to the previous page. |

Additional copy rules:

- Success copy states what changed and where the audit trail is.
- Warning copy states what is risky and what evidence the operator should inspect.
- Blocked/unavailable copy states why action cannot proceed and what condition unlocks it.
- Destructive copy names the target and consequence without dramatic language.
- Permission-denied/read-only copy must distinguish policy denial from archived or unavailable state.
- Missing host evidence must not imply healthy status or authoritative population counts.

---

## Evidence Contract

| Evidence target | Contract |
|-----------------|----------|
| Source assertions | Plans should assert component functions, raw `rs-*` consolidation ledger entries, and absence of Storybook/PhoenixStorybook/pixel-baseline tooling. |
| ExUnit/Phoenix | Use component render tests and UI matrix route tests for canonical primitives, mutation-confirm variants, and domain composite examples. |
| Playwright matrix | Reuse `ui-matrix.spec.ts` for light, dark, system-dark, desktop, mobile, reduced-motion, overflow, and screenshot artifact coverage. |
| CSS/source guards | Preserve `check_admin_foundations.py` and existing token/logo/contrast guards; extend only for real repeatable component drift. |
| Human review | Use matrix screenshot artifacts for qualitative polish review; do not add checked-in visual baselines. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable - no shadcn, no third-party registries, no package install, no registry block |

No third-party component source is approved for Phase 116. If a future change proposes one, rerun UI phase and complete registry vetting before it can enter a plan.

---

## Pre-Populated From

| Source | Decisions Used |
|--------|----------------|
| `116-CONTEXT.md` | D-01 through D-19 locked implementation and scope decisions |
| `115-FOUNDATIONS-CONTRACT.md` | Foundation rules for breakpoints, focus, reduced motion, radius/elevation, and dense content |
| `113-DESIGN-SYSTEM-INVENTORY.md` | Component taxonomy and raw `rs-*` consolidation ledger |
| `113-UI-MATRIX-CONTRACT.md` | Required states, evidence dimensions, operator lenses, and fixture-data needs |
| `114-UI-SPEC.md` | Matrix visual/interaction and evidence contracts |
| Existing CSS/components | Token names, component selectors, matrix fixtures, and current component APIs |
| Prompt anchors | Admin UX, personas/JTBD, testing, and LiveView best-practice constraints |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-06-14

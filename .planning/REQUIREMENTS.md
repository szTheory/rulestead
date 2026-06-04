# Requirements: v1.13 — Admin UI: First-Class Dark Mode + Design-System Polish

**Defined:** 2026-06-04
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

This milestone deepens the **mounted `rulestead_admin` companion UI** only. No new `rulestead` runtime APIs; no widening of the sibling-package product shape. Dark mode was already prescribed by the admin UX spec (`prompts/rulestead-admin-ux-and-operator-ia.md` §9) but never implemented.

## v1.13 Requirements

### Theming (`THM`)

- [x] **THM-01**: An operator viewing the mounted admin sees a dark theme automatically when their OS reports `prefers-color-scheme: dark`, with no explicit action.
- [x] **THM-02**: An operator can choose System / Light / Dark from a control in the admin shell, and the choice persists across reloads on that device.
- [x] **THM-03**: An explicit Light or Dark choice overrides the OS preference; "System" tracks live OS changes while selected.
- [x] **THM-04**: First paint shows the correct theme with no visible flash for System users; a pinned-theme correction is an instant snap, never an animated wipe.
- [x] **THM-05**: The theme is scoped to the mounted admin (`.rs-shell` / `[data-rulestead]`) and never alters the host application's own styling, `<head>`, or cookies.
- [x] **THM-06**: The dark theme is on-brand and calm — mineral-dark surfaces (not pure black), desaturated brand blue/ember, and elevation expressed via lightened surfaces plus hairline borders rather than dark-on-dark shadows.

### Accessibility & Interaction States (`A11Y`)

- [ ] **A11Y-01**: All body text, status pills, and UI-component borders meet WCAG AA contrast (text 4.5:1, large text / UI components 3:1) in both light and dark themes, verified against the actual surface they render on.
- [x] **A11Y-02**: Every interactive element shows a single, consistent `:focus-visible` indicator (≥3:1, ≥2px perimeter) that stays legible on light surfaces, dark surfaces, and colored fills.
- [x] **A11Y-03**: Hover, active, and disabled states stay legible and AA-compliant in both themes — no unreadable white-on-light or crushed-on-dark states.

### Design System (`DSY`)

- [x] **DSY-01**: All color, surface, border, text, shadow, and focus values are token-driven; no hardcoded color literals remain in component CSS outside the theme token blocks.
- [x] **DSY-02**: The token contract (theme-invariant vs theme-variant) is documented, and a token/contrast reference fixture renders every token pair, status tone, and interaction state as the regression gate for later phases.

### Information Architecture (`IA`)

- [x] **IA-01**: The home/overview surface makes "what needs me now / where do I go next" obvious for operator, support, and SRE personas (uk.gov-style clarity), legible and on-brand in both themes.
- [x] **IA-02**: Global navigation and orientation affordances are consistent and follow least-surprise conventions across all admin screens.

### Per-Screen Polish (`SCRN`)

- [ ] **SCRN-01**: Every mounted admin screen (~31) renders correctly and on-brand in both themes — elevation reads, status pills stay legible, empty/hero states are correct — verified by both-theme screenshot plus a contrast check.

### Motion (`MOT`)

- [ ] **MOT-01**: Micro-animations are restrained and purposeful — transform/opacity only, ease-out, under ~300ms — and confirm an action rather than decorate.
- [ ] **MOT-02**: All motion respects `prefers-reduced-motion` and never blocks a task; theme switching produces no flicker.

## Future Requirements

Deferred beyond v1.13. Tracked but not in this roadmap.

- **THM-07**: Per-host theme branding overrides (host supplies a token palette to re-skin the mounted admin beyond light/dark).
- **A11Y-04**: High-contrast / forced-colors (`forced-colors` media) first-class support.
- **MOT-03**: Richer view-transition choreography across route changes (LiveView morph + View Transitions API).

## Out of Scope

| Feature | Reason |
|---------|--------|
| New `rulestead` runtime APIs | Milestone is companion-UI quality only; runtime contract stays frozen. |
| Standalone control-plane admin UX | Preserves the mounted sibling-package design (CLAUDE.md constraint). |
| Introducing a CSS build step / Tailwind / CSS-in-JS | The token-based hand-authored static CSS is the chosen scalable architecture; do not switch midstream. |
| Host `<head>` ownership as a *required* FOUC fix | Mounted package must work without host cooperation; optional host head-script is documented, not mandatory. |
| Deferred v2 feature wedges (GOV-02-ext, ROL-08, ADM-06) | Gated separately in `.planning/DEFERRED.md`; this milestone is UX quality, not feature scope. |
| Forced-colors / high-contrast OS mode | Deferred to A11Y-04; AA in light+dark is the v1.13 bar. |

## Capability Selection Rubric

| Capability Family | Route-Owner Expectation | Permission / Policy Sensitivity | Support-Matrix Impact | Proof Required | Package Classification |
|-------------------|-------------------------|----------------------------------|-----------------------|----------------|------------------------|
| Theme token layer + dark palette | `rulestead_admin` owns the CSS token contract | low | low | both-theme screenshots + automated contrast pass | `companion` |
| Tri-state theme control + persistence | `rulestead_admin` owns a client-only preference (localStorage hook) inside the mounted shell | low | low | persistence + FOUC + live-OS-change proof | `companion` |
| Accessibility / focus unification | `rulestead_admin` owns interaction-state CSS | low | low | keyboard-focus + axe contrast proof | `companion` |
| IA / home refinement, per-screen polish, motion | `rulestead_admin` owns presentation | low | low | both-theme visual + reduced-motion proof | `companion` |
| Host global theme system / SSR theme injection | host application concern | n/a | n/a | optional documented seam only | `defer` |

## Packaging Ledger

| Surface | Classification | Milestone Scope |
|---------|----------------|-----------------|
| Theme token layer, dark palette, focus/interaction CSS in `rulestead_admin` | `companion` | In scope |
| Tri-state theme control + colocated localStorage hook in `rulestead_admin` shell | `companion` | In scope |
| Token-contract docs + contrast reference fixture | `companion` / docs | In scope |
| Optional host `<head>` fast-path snippet + integration note | `docs-only` | In scope (documented, not required) |
| `rulestead` runtime APIs, host global theme system, forced-colors mode, standalone admin | `defer` | Out of scope |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| THM-01 | Phase 87 | Complete |
| THM-03 | Phase 87 | Complete |
| THM-05 | Phase 87 | Complete |
| THM-06 | Phase 87 | Complete |
| DSY-01 | Phase 88 | Complete |
| A11Y-02 | Phase 89 | Complete |
| A11Y-03 | Phase 89 | Complete |
| THM-02 | Phase 90 | Complete |
| THM-04 | Phase 90 | Complete |
| DSY-02 | Phase 91 | Complete |
| IA-01 | Phase 92 | Complete |
| IA-02 | Phase 92 | Complete |
| A11Y-01 | Phase 93 | Pending |
| SCRN-01 | Phase 93 | Pending |
| MOT-01 | Phase 94 | Pending |
| MOT-02 | Phase 94 | Pending |

**Coverage:**
- v1.13 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-06-04 — traceability finalized by roadmapper (Phases 87–94)*

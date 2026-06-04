# Requirements: Rulestead — v1.14 Brand System Realization

**Defined:** 2026-06-04
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

**Milestone goal:** Turn the recovered 27-section brand book into a buildable, WCAG-AA-verified, source-controlled brand system in a self-contained `brandbook/`, and re-skin the shipped admin UI to the canonical mineral palette — without repo bloat or widening the sibling-package product shape. No new runtime APIs. Phases 95–100.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase.

### Brand Audit & Strategy (BRD)

- [ ] **BRD-01**: Maintainer has a written pressure-test audit of the recovered brand book (KEEP / TIGHTEN / REWORK / ADD / REMOVE + scorecard) identifying what is strong vs needs work.
- [x] **BRD-02**: A canonical living `brand-book.md` exists in `brandbook/` (relocated from `prompts/` with a pointer left behind), reconciled to ship-true reality.
- [ ] **BRD-03**: A short szTheory suite brand-architecture note defines what is shared vs unique across Rulestead and sibling libraries (Parapet, Scoria, Cairnloop).

### Color & Palette (PAL)

- [x] **PAL-01**: Every brand-palette pairing (text / border / UI element) on light and dark surfaces has a documented, computed WCAG contrast ratio.
- [x] **PAL-02**: All AA-failing pairings are remediated with hue-preserving (OKLCH uniform-scale) variants, and one canonical AA-passing value is selected per role/surface.
- [x] **PAL-03**: A full dark-mode ramp is derived, anchored on the shipped v1.13 mineral-dark approach (not pure black; elevation via lightening + hairline borders).
- [x] **PAL-04**: Decorative-only colors (e.g. Signal Gold) carry an explicit "never as normal-weight text" usage policy.

### Design Tokens (TOK)

- [ ] **TOK-01**: `brandbook/tokens.json` expresses raw → semantic → state tokens in DTCG format with light and dark values.
- [ ] **TOK-02**: `brandbook/tokens.css` emits CSS custom properties mirroring the shipped `--rs-*` token shape for light and dark.
- [ ] **TOK-03**: Tokens cover semantic + state roles (default/hover/active/focus/disabled/selected/success/warning/error/info/subtle/muted) plus spacing, radius, border, shadow, focus-ring, code-block, and callout primitives.
- [ ] **TOK-04**: An optional Tailwind token excerpt is provided for downstream marketing/site reuse.

### Logo & Mark System (LOGO)

- [ ] **LOGO-01**: Three SVG mark concepts (A structured path / B stead frame / C layered field) are produced for maintainer selection.
- [ ] **LOGO-02**: The chosen mark ships a full lockup: primary (wordmark + icon), icon-only, monochrome, and dark/light variants.
- [ ] **LOGO-03**: A `favicon.svg` (with minimal raster fallback) is legible at 16px, and a 1200×630 social/OG card is committed as SVG.
- [ ] **LOGO-04**: All logo SVGs are optimized (SVGO), accessible (`title`/`desc`), free of embedded raster, and use outlined text or a documented font fallback.
- [ ] **LOGO-05**: The off-brand phoenix-flame demo logo (and its fingerprinted copy) is replaced with the new mark, and admin/demo references are updated.

### Admin Re-skin (SKIN)

- [ ] **SKIN-01**: `rulestead_admin/priv/static/css/rulestead_admin.css` is re-skinned to the canonical mineral palette across all 4 cascade blocks — colors only, invariant tokens untouched.
- [ ] **SKIN-02**: The re-skin passes `scripts/check_synced_pair.py` and WCAG-AA in both light and dark themes, with the `design-system.html` fixture updated.
- [ ] **SKIN-03**: A token-drift check (`check_brand_tokens.py`, mirroring `check_synced_pair.py`) verifies the admin CSS palette matches `brandbook/tokens`.

### Specimens (SPEC)

- [ ] **SPEC-01**: Reproducible SVG specimens exist for the color palette and the typography system.
- [ ] **SPEC-02**: Reproducible SVG specimens exist for core UI components (buttons/cards/badges), a code block, a README header mock, and a social card.

### Marketing & Voice Copy (COPY)

- [ ] **COPY-01**: Ready-to-paste copy blocks exist for the GitHub repo description, Hex.pm package description, 140-char blurb, README intro/hero, landing hero/sub + primary/secondary CTAs, and three feature blurbs.
- [ ] **COPY-02**: A voice/microcopy reference (say-this / not-this) covers error, empty, and success states plus a release-announcement template.

### Repo Artifacts & Guard (REPO)

- [ ] **REPO-01**: `brandbook/` has a self-contained directory structure with a `README.md` and a `docs/brand-usage.md`, cross-linked to the admin CSS and the canonical brand book.
- [ ] **REPO-02**: A repo-size guard (size budget + CI check + `.gitattributes`) prevents binary bloat, and the token-sync + SVG checks are wired into the existing scripts-first CI.

## v2 Requirements

Deferred to future milestones. Tracked but not in this roadmap.

### Theme (THM)

- **THM-07**: Per-host branding token overrides (trigger: host-supplied palette) — already a deferred v2 wedge.

### Accessibility (A11Y)

- **A11Y-04**: Forced-colors / high-contrast mode (trigger: beyond AA light+dark) — already a deferred v2 wedge.

### Brand (BRD)

- **BRD-04**: Full custom icon library beyond the logo/mark set (trigger: sustained UI icon demand) — anti-feature for now per research.
- **BRD-05**: Standalone marketing/docs website build (trigger: adoption justifies a dedicated site) — copy blocks ship now, the site does not.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| PDF / binary brand book | Rots immediately, bloats repo; the source-controlled markdown + SVG system replaces it. |
| Figma (or any external tool) as source of truth | `brandbook/` text+SVG files are the canonical, reviewable source; no vendor lock-in. |
| Mascot / character | Conflicts with the Architect+Steward positioning and the book's explicit no-phoenix/no-mascot stance. |
| New product runtime APIs | This is a brand/UX-quality milestone; the sibling-package product shape does not widen. |
| Re-deriving the v1.13 dark base | The shipped `#10161f` mineral-dark base is kept; only brand hues change, anchored on it. |
| Build-time token pipeline (Style Dictionary) | Mirror-not-generate; hand-authored CSS + a drift-check avoids coupling the auto-publish release pipeline. |

## Traceability

Which phases cover which requirements. Filled during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| BRD-01 | Phase 95 | Pending |
| BRD-02 | Phase 95 | Complete |
| BRD-03 | Phase 100 | Pending |
| PAL-01 | Phase 95 | Complete |
| PAL-02 | Phase 95 | Complete |
| PAL-03 | Phase 95 | Complete |
| PAL-04 | Phase 95 | Complete |
| TOK-01 | Phase 96 | Pending |
| TOK-02 | Phase 96 | Pending |
| TOK-03 | Phase 96 | Pending |
| TOK-04 | Phase 96 | Pending |
| LOGO-01 | Phase 97 | Pending |
| LOGO-02 | Phase 97 | Pending |
| LOGO-03 | Phase 97 | Pending |
| LOGO-04 | Phase 97 | Pending |
| LOGO-05 | Phase 97 | Pending |
| SKIN-01 | Phase 98 | Pending |
| SKIN-02 | Phase 98 | Pending |
| SKIN-03 | Phase 98 | Pending |
| SPEC-01 | Phase 99 | Pending |
| SPEC-02 | Phase 99 | Pending |
| COPY-01 | Phase 100 | Pending |
| COPY-02 | Phase 100 | Pending |
| REPO-01 | Phase 100 | Pending |
| REPO-02 | Phase 100 | Pending |

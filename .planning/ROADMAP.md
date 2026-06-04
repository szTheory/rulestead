# Roadmap: Rulestead

## Milestones

- 🔄 **v1.13 - Admin UI: First-Class Dark Mode + Design-System Polish** — Phases 87-94 (active 2026-06-04)
- ✅ **v1.12 - Adoption Evidence Depth** — Phases 82-86 (shipped 2026-05-29) — [.planning/milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)
- ✅ **v1.11.1 - Gap Closure** — Phases 79-81 (shipped 2026-05-29) — [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md) · [audit](milestones/v1.11.1-MILESTONE-AUDIT.md)
- ✅ **v1.11 - Integration Spine (docs-only)** — Phases 76-78 (shipped 2026-05-28) — [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)
- ✅ **v1.10.1 - Support-truth & Contract Honesty** — Phases 73-75 (shipped 2026-05-28) — [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)
- ✅ **v1.10.0 - Post-GA Band Truth & Adopter Closure** — Phases 69-72 (shipped 2026-05-28) — [.planning/milestones/v1.10.0-ROADMAP.md](milestones/v1.10.0-ROADMAP.md)
- ✅ **v1.9.0 - Host-Supplied Preview Evidence** — Phases 65-68 (shipped 2026-05-28) — [.planning/milestones/v1.9.0-ROADMAP.md](milestones/v1.9.0-ROADMAP.md)
- ✅ **v1.8.0 - Guarded Rollout Auto-Advance** — Phases 61-64 (shipped 2026-05-27)

## Current focus

**v1.13 — Admin UI: First-Class Dark Mode + Design-System Polish** (Phases 87–94, opened 2026-06-04)

Give `rulestead_admin` a first-class, system-aware tri-state (System / Light / Dark) theme that stays on-brand and WCAG-AA legible in both modes, with unified interaction states and a consolidated, documented token contract. No new `rulestead` runtime APIs.

**Proof spine:** `cd rulestead && mix verify.phase82` · `mix verify.adopter`

## Phase numbering

Phases 82–86 complete v1.12 adoption evidence depth. This milestone (v1.13) runs **Phases 87–94**. Next milestone starts at **95**.

## Phases

- [x] **Phase 87: Token Theme Foundation** — THM-01, THM-03, THM-05, THM-06
- [x] **Phase 88: Hardcoded-Color Remediation** — DSY-01
- [x] **Phase 89: Focus + Interaction-State Unification** — A11Y-02, A11Y-03
- [x] **Phase 90: Tri-State Theme Control + Persistence + FOUC** — THM-02, THM-04
- [x] **Phase 91: Design-System Consolidation** — DSY-02
- [ ] **Phase 92: IA / Home Refinement** — IA-01, IA-02
- [ ] **Phase 93: Per-Screen Polish Across All Admin Screens** — A11Y-01, SCRN-01
- [ ] **Phase 94: Restrained Micro-Animation** — MOT-01, MOT-02

## Phase Details

### Phase 87: Token Theme Foundation
**Goal**: The CSS token layer is split into theme-invariant and theme-variant blocks, with a complete on-brand mineral-dark token set declared — every later phase can re-theme by reading tokens, not touching component rules.
**Depends on**: Nothing (first phase; blocks all others)
**Requirements**: THM-01, THM-03, THM-05, THM-06
**Success Criteria** (what must be TRUE):
  1. Toggling `data-theme="dark"` on `.rs-shell` in devtools re-themes the home, flags index, and a detail screen visually with no light-mode color bleed.
  2. The system-dark `@media (prefers-color-scheme: dark)` block fires correctly on a device set to dark OS mode with no `[data-theme]` present — confirmed by screenshot.
  3. An explicit `[data-theme="light"]` or `[data-theme="dark"]` attribute beats the `@media` rule in both directions (explicit-wins cascade verified).
  4. The dark palette reads as mineral-dark (base ~`#10161f`, off-white text ~`#e8edf3`) — not pure black, not generic grey — with elevation expressed via lightened surfaces and hairline borders.
  5. The theme scope is contained to `.rs-shell` / `[data-rulestead]`; a devtools inspection of `:root` and `<html>` shows no dark-mode token overrides from the admin package.
**Plans**: 3 plans
Plans:
- [x] 87-01-PLAN.md — Validation scaffolding: HTML harness + Playwright cascade/scope specs + contrast-check helper
- [x] 87-02-PLAN.md — CSS token split: :root invariant-only + .rs-shell light default block (new tokens + --rs-warning-hover)
- [x] 87-03-PLAN.md — Dark cascade blocks: mineral-dark token set (verified AA), system-dark @media, explicit dark/light, SYNCED PAIR
**UI hint**: yes

### Phase 88: Hardcoded-Color Remediation
**Goal**: Every hardcoded color literal that would break or look wrong on dark surfaces is routed through a token, leaving no inline `rgba()`/hex values in component CSS outside the theme token blocks.
**Depends on**: Phase 87
**Requirements**: DSY-01
**Success Criteria** (what must be TRUE):
  1. A grep for known inline color patterns (`rgba(26,35,50`, `rgba(37,99,235`, `rgba(255,255,255`, hard-hex `#` values) outside the token block sections returns zero matches in `rulestead_admin.css`.
  2. The ~12 inline `box-shadow` / gradient veil / cmdk scrim values are replaced by `--rs-shadow*`, `--rs-overlay-veil`, and `--rs-scrim` tokens; a visual diff in both themes shows no regressions on surfaces that previously used those values.
  3. Inline focus tints (raw `rgba()` outlines used in earlier focus rules) are removed; no component rule references a color literal for focus state.
**Plans**: 1 plan
Plans:
- [x] 88-01-PLAN.md — Token-redirect all 18 hardcoded literals + warning-flash fix + --rs-primary-ring gap token
**UI hint**: yes

### Phase 89: Focus + Interaction-State Unification
**Goal**: Every interactive element in the admin shows one consistent, WCAG-AA-legible two-stop `:focus-visible` ring across light surfaces, dark surfaces, and colored fills; hover and disabled states are legible in both themes.
**Depends on**: Phase 87
**Requirements**: A11Y-02, A11Y-03
**Success Criteria** (what must be TRUE):
  1. Keyboard-tabbing through every interactive element on 5 representative screens in both light and dark themes shows the same ring shape (two-stop `box-shadow`: surface-colored inner gap + brand outer ring) on every element.
  2. The focus ring meets WCAG 2.4.11 / 2.4.13 (≥3:1 contrast, ≥2px perimeter) on light cards, dark surfaces, and colored fills — confirmed by axe-core focus-indicator checks.
  3. Hover states are visually distinct and legible in both themes — no white-on-light or crushed-on-dark states appear on any sampled interactive element.
  4. Disabled states are legible in both themes — explicit `--rs-disabled-*` tokens used rather than opacity that crushes to invisible on dark.
**Plans**: 2 plans
Plans:
- [x] 89-01-PLAN.md — Harness extension: interactive focus targets (input, select, tab strip, primary/secondary/danger buttons)
- [x] 89-02-PLAN.md — CSS unification: two-stop --rs-focus-ring in all 4 cascade blocks + :where() base rule + idiom removal + hover/disabled fixes
**UI hint**: yes

### Phase 90: Tri-State Theme Control + Persistence + FOUC
**Goal**: Operators can pin Light, Dark, or System from a segmented control in the shell header; the choice persists across device reloads; System users see zero flash; pinned users see an instant snap with no animated wipe on mismatch.
**Depends on**: Phase 87 (parallel with 88 and 89)
**Requirements**: THM-02, THM-04
**Success Criteria** (what must be TRUE):
  1. The shell header shows a segmented System / Light / Dark control; selecting each option applies the correct theme immediately and the selection persists after a hard reload.
  2. A device in System mode with OS set to dark sees the correct dark theme on first paint with no light flash — `@media (prefers-color-scheme: dark)` resolves before JS without any `data-theme` attribute.
  3. A device with a pinned theme (light or dark) that mismatches its OS setting sees an instant snap to the correct theme — no animated color wipe, confirmed by removing and re-adding `data-theme-pending` in devtools.
  4. Switching OS preference while System mode is active live-updates the admin theme without a reload.
  5. The optional `theme_default` attribute on `shell.ex page/1` is documented; a host that supplies it gets the correct initial token without JS.
**Plans**: 3 plans
Plans:
- [x] 90-01-PLAN.md — File:// fixture (theme-control-harness.html) + Playwright spec (theme-control.spec.ts, 11 THM-02/THM-04 behavioral tests)
- [x] 90-02-PLAN.md — shell.ex: .ThemeControl ColocatedHook + radiogroup markup + data-theme-pending + theme_default attr; rulestead_admin.css: control styles + FOUC suppression
- [x] 90-03-PLAN.md — Integration guide: theme_default attr + optional host head-script + CSP note
**UI hint**: yes

### Phase 91: Design-System Consolidation
**Goal**: One-off color patterns discovered during Phases 88 and 89 are folded into the token contract; the invariant-vs-variant split is documented in the CSS header and a guide; the token/contrast reference fixture page is complete and serves as the regression gate.
**Depends on**: Phases 87, 88, and 89
**Requirements**: DSY-02
**Success Criteria** (what must be TRUE):
  1. The token/contrast reference fixture page renders every token pair, every `.rs-badge[data-tone]`, focus rings, and hover/disabled states in both themes — a human can visually audit the full palette in one place.
  2. An automated WCAG-ratio assertion (axe-core or equivalent script over computed token values) passes with zero contrast violations on the fixture in both light and dark themes.
  3. The CSS file header and a companion guide document which tokens are theme-invariant (`:root`) and which are theme-variant (re-declared per theme scope), with clear guidance for future additions.
**Plans**: 2 plans
Plans:
- [x] 91-01-PLAN.md — Token-contract CSS header comment + guide section + one-off literal-scan verification
- [x] 91-02-PLAN.md — design-system.html fixture + assertAABatch extension + design-system.spec.ts WCAG AA gate
**UI hint**: yes

### Phase 92: IA / Home Refinement
**Goal**: The home/overview surface and global navigation are clear, on-brand, and immediately useful for operator, support, and SRE personas in both themes — "what needs me now / where do I go next" is obvious at a glance.
**Depends on**: Phase 91
**Requirements**: IA-01, IA-02
**Success Criteria** (what must be TRUE):
  1. The home/overview screen in both themes makes the "what needs attention" signal visible at first glance for operator, support, and SRE personas — no digging required (uk.gov-style clarity).
  2. Global navigation affordances (active state, hover, focus) are consistent across all admin screens in both themes — same visual treatment, same position, no screen-specific overrides.
  3. Both-theme screenshots of the home screen and global nav pass the token/contrast fixture gate from Phase 91 with zero contrast violations.
**Plans**: 1 plan
Plans:
- [x] 92-01-PLAN.md — Rail Overview link distinction + attention-empty dark-mode token fix
**UI hint**: yes

### Phase 93: Per-Screen Polish Across All Admin Screens
**Goal**: All ~31 mounted admin screens render correctly and on-brand in both light and dark themes — elevation reads, status pills are legible, empty/hero states look right — verified by both-theme screenshot plus a contrast check per screen.
**Depends on**: Phases 87, 88, 89, and 91
**Requirements**: A11Y-01, SCRN-01
**Success Criteria** (what must be TRUE):
  1. Every mounted admin screen (~31) has a passing both-theme screenshot on file — light and dark renders captured without layout breakage, missing icons, or unreadable overlays.
  2. axe-core (or equivalent automated contrast tool) reports zero WCAG-AA contrast violations (text 4.5:1, large text/UI components 3:1) across all screened pages in both themes.
  3. Status pills, badges, and `.rs-badge[data-tone]` variants stay legible on their actual dark surfaces — soft-fill tints are low-opacity hue tints, not washed-out near-white.
  4. Empty states and hero-state illustrations/copy remain readable and on-brand in both themes with no hardcoded light-mode-only fills.
**Plans**: TBD
**UI hint**: yes

### Phase 94: Restrained Micro-Animation
**Goal**: Purposeful confirm/enter micro-animations are added via existing `--rs-motion-*` / `--rs-ease-*` tokens; all motion respects `prefers-reduced-motion`; theme switching produces no flicker.
**Depends on**: Phases 89 and 93
**Requirements**: MOT-01, MOT-02
**Success Criteria** (what must be TRUE):
  1. Micro-animations on confirm/enter interactions use transform/opacity only, ease-out, under ~300ms — a stopwatch check on 3 representative actions confirms timing.
  2. With `prefers-reduced-motion: reduce` set in the OS or devtools, all animations are suppressed or replaced with instant transitions; no task is blocked.
  3. Switching theme (System → Dark → Light → System) produces no animated color wipe or flicker — the `data-theme-pending` transition-suppression remains effective alongside the new animations.
  4. New animation rules do not conflict with the `data-theme-pending` no-transition snap established in Phase 90.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 87. Token Theme Foundation | 3/3 | Complete   | 2026-06-04 |
| 88. Hardcoded-Color Remediation | 1/1 | Complete   | 2026-06-04 |
| 89. Focus + Interaction-State Unification | 2/2 | Complete   | 2026-06-04 |
| 90. Tri-State Theme Control + Persistence + FOUC | 3/3 | Complete   | 2026-06-04 |
| 91. Design-System Consolidation | 2/2 | Complete   | 2026-06-04 |
| 92. IA / Home Refinement | 1/1 | Complete   | 2026-06-04 |
| 93. Per-Screen Polish Across All Admin Screens | 0/? | Not started | - |
| 94. Restrained Micro-Animation | 0/? | Not started | - |

<details>
<summary>✅ v1.12 Adoption Evidence Depth (Phases 82-86) — SHIPPED 2026-05-29</summary>

- [x] Phase 82: Adoption Lab Doc + Persona Cross-Links — ADL-01, ADL-02
- [x] Phase 83: Curated Admin Playwright Proofs — ADL-03
- [x] Phase 84: Fresh-Install Journey Script + CI Scope — ADL-04
- [x] Phase 85: FleetDesk Seeds + Smoke Tests — ADL-05
- [x] Phase 86: Proof Umbrella + Contract Guards Closure — VER-01, VER-02

**Archive:** [.planning/milestones/v1.12-MILESTONE-AUDIT.md](milestones/v1.12-MILESTONE-AUDIT.md)

**Proof:** `cd rulestead && mix verify.phase82` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.11.1 Gap Closure (Phases 79-81) — SHIPPED 2026-05-29</summary>

- [x] Phase 79: Lifecycle Deep-Link Anchor Fix — DOC-02, INT-02
- [x] Phase 80: Phase 76–77 Verification Backfill — INT-01, INT-03, DOC-01, DOC-03
- [x] Phase 81: Doc Contract Hardening — DOC-01 (contract guards), Nyquist Phase 76

**Archive:** [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md)

**Audit:** [.planning/milestones/v1.11.1-MILESTONE-AUDIT.md](milestones/v1.11.1-MILESTONE-AUDIT.md) (`passed`)

</details>

<details>
<summary>✅ v1.11 Integration Spine (Phases 76-78) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/milestones/v1.11-MILESTONE-AUDIT.md](milestones/v1.11-MILESTONE-AUDIT.md)

- [x] Phase 76: Phoenix Integration Spine Doc — INT-01–03
- [x] Phase 77: Evaluation And Lifecycle Doc Alignment — DOC-01–03
- [x] Phase 78: Doc Contract Guards And Milestone Closure — VER-01–02, AUD-01–02

**Proof:** `cd rulestead && mix verify.phase76` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.10.1 Support-truth & Contract Honesty (Phases 73-75) — SHIPPED 2026-05-28</summary>

**Audit:** [.planning/v1.10.1-MILESTONE-AUDIT.md](v1.10.1-MILESTONE-AUDIT.md)

- [x] Phase 73: Context And Maintainer Doc Truth — CTX-01, CTX-02, DOC-01
- [x] Phase 74: API Stability Catalog Sync — API-01–03, VER-03
- [x] Phase 75: Proof Umbrella And Milestone Closure — VER-01–02, DOC-02, AUD-01–02

**Proof:** `cd rulestead && mix verify.phase73` · `mix verify.adopter`

</details>

<details>
<summary>✅ v1.10.0 Post-GA Band Truth & Adopter Closure (Phases 69-72) — SHIPPED 2026-05-28</summary>

Archived to `.planning/milestones/v1.10.0-phases/`.

</details>

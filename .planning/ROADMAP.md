# Roadmap: v1.16 Brand-Faithful UI Iteration

**Status:** Complete
**Defined:** 2026-06-12
**Phase range:** 107-112

## Milestone Goal

Make every rendered Rulestead-owned surface faithfully reflect the v1.15 identity in light, dark, and system modes, with reusable browser evidence. FleetDesk remains a differently branded host/example app.

## Phase 107: Brand/UI Audit + UI-SPEC

**Goal:** Define the conformance matrix and brand boundary before polishing screens.
**Requirements:** BUI-01
**Success Criteria:**

1. Admin route clusters, demo launcher, FleetDesk, static fixtures, and brandbook evidence surfaces are inventoried.
2. The UI-SPEC locks the Rulestead-vs-FleetDesk brand boundary: Rulestead admin/demo chrome uses the v1.15 identity; FleetDesk stays host-branded.
3. Out-of-scope constraints are explicit: no palette redesign, logo redraw, component framework, public API/schema change, or admin publish prep.

## Phase 108: Fixture + Guardrail Alignment

**Goal:** Static fixtures and CI guards represent the shipped brand system.
**Depends on:** Phase 107
**Requirements:** BUI-02
**Success Criteria:**

1. Design/theme fixtures expose the shipped wordmark family instead of text-only brand headers.
2. Stale token literals and old generic blues are removed from fixture tests and generated brandbook chrome.
3. Logo asset drift and contrast checks run in the normal guard path.

## Phase 109: Shared Admin Primitive Pass

**Goal:** Shared admin primitives are brand-faithful and AA-safe in light, dark, and system modes.
**Depends on:** Phase 108
**Requirements:** BUI-03
**Success Criteria:**

1. Primary/action foregrounds, focus rings, selection rings, hover, disabled, and soft primary states use current brand tokens and pass the relevant contrast gates.
2. Tokens remain scoped to `.rs-shell` / `[data-rulestead]`; synced-pair and token mirror guards stay green.
3. Status components retain text/icon/label semantics and do not rely on color alone.

## Phase 110: Admin Workflow Screen Pass

**Goal:** Admin route clusters preserve the v1.15 shell identity and remain dense, scannable, keyboard-oriented operator surfaces.
**Depends on:** Phase 109
**Requirements:** BUI-04
**Success Criteria:**

1. Build & release, Explain & diagnose, Review & approve, and destructive per-flag flows render with visible lockup, theme control, and no horizontal overflow at desktop/mobile widths.
2. Command/search focus, navigation, tables/lists, and long technical labels remain usable in light, dark, and system-dark modes.
3. No domain behavior or data model changes are introduced for visual polish.

## Phase 111: Demo Surface Alignment

**Goal:** Demo entrypoints teach the adopter story without confusing the host app with the Rulestead brand.
**Depends on:** Phase 110
**Requirements:** BUI-05
**Success Criteria:**

1. Phoenix demo launcher uses the Rulestead wordmark, title, navigation, and mineral theme instead of Phoenix boilerplate.
2. FleetDesk remains visibly host-branded, gains its own tokenized light/system-dark visual system, and no longer carries stale teal/Phoenix-style defaults.
3. Demo asset build/digest path succeeds from a dirty local generated-asset state.

## Phase 112: Visual Evidence + Closeout

**Goal:** The milestone closes with reusable browser evidence and planning truth.
**Depends on:** Phase 111
**Requirements:** BUI-06
**Success Criteria:**

1. Playwright evidence captures admin route clusters, demo launcher, FleetDesk, fixtures, theme modes, and desktop/mobile widths as test artifacts.
2. Guard sweep passes: token/brandbook/logo drift, static contrast, fixture specs, admin tests, and targeted demo/browser specs.
3. Planning docs record decisions, verification, and shipped scope; no v2 or publish-posture work is smuggled in.

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 107. Brand/UI Audit + UI-SPEC | 1/1 | Complete | 2026-06-12 |
| 108. Fixture + Guardrail Alignment | 1/1 | Complete | 2026-06-12 |
| 109. Shared Admin Primitive Pass | 1/1 | Complete | 2026-06-12 |
| 110. Admin Workflow Screen Pass | 1/1 | Complete | 2026-06-12 |
| 111. Demo Surface Alignment | 1/1 | Complete | 2026-06-12 |
| 112. Visual Evidence + Closeout | 1/1 | Complete | 2026-06-12 |

# Phase 94: Restrained Micro-Animation - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning
**Mode:** Evidence-driven from the existing-motion audit + the great-animations research. Autonomous, hands-off. NO churn.

<domain>
## Phase Boundary

Ensure the admin's micro-animations are restrained, purposeful, and accessible — transform/opacity only, ease-out for entrances, <300ms, reduced-motion-safe, and never fighting the Phase-90 theme-switch snap. Requirements MOT-01 (restrained/purposeful: transform/opacity, ease-out, <~300ms, confirm-not-decorate) + MOT-02 (respects `prefers-reduced-motion`; theme switching produces no flicker).

**Audit reality:** the motion system is already strong (prior work): 2 keyframes (`rs-slide-in`, `rs-confirm-pop`) using ONLY opacity+transform; all motion gated behind `@media (prefers-reduced-motion: no-preference)` (so reduced-motion users get none by default — correct); 35 `--rs-motion-*`/`--rs-ease-*` token usages; NO transitions on layout props (no jank); durations ≤ `--rs-motion-base` (<300ms). So this phase = CONFIRMATION + a small set of principle-aligned refinements, NOT a motion overhaul.

**In scope:**
- Confirm/enforce MOT-01: every animation/transition uses transform/opacity (not layout props), tokenized durations <300ms, and is purposeful (entrance of new content, confirm feedback, subtle hover) — not decoration on high-frequency/keyboard-driven controls.
- Principle refinement: entrances should use **ease-out** (fast→settle, "responsive") per the great-animations research. The async-`.rs-settle` already uses ease-out; align the other ENTRANCE animations (`.rs-card--flag`, `.rs-record-row` currently use `--rs-ease-standard`) to `--rs-ease-out` for a more responsive feel. (Keep on-screen state-change moves on ease-in-out/standard.)
- Confirm `rs-confirm-pop` is actually WIRED to a confirmation/notice surface (it should confirm an action); if defined-but-unused, wire it to the appropriate confirm/flash entrance or remove it (no dead decoration).
- MOT-02: verify `prefers-reduced-motion: reduce` yields no motion (the `no-preference` gating already ensures this) and theme switching produces NO animated color wipe/flicker (the `[data-theme-pending]` snap + absence of color transitions already ensures this — confirm no color/bg `transition:` exists that would animate a theme swap).

**OUT OF SCOPE:** new decorative animations, motion on high-frequency controls, view-transitions API choreography (Future MOT-03), token-value changes, anything in 87-93.
</domain>

<decisions>
## Implementation Decisions
- Entrances → `--rs-ease-out`; keep <300ms tokens. Don't add motion to anything an operator repeats rapidly (per the research: never animate high-frequency/keyboard actions — would make the incident tool feel slow).
- Ensure no `transition:` animates color/background/border-color (those would animate the theme swap = flicker). Theme switch must be an instant token swap.
- Keep all motion behind `prefers-reduced-motion: no-preference`.
- Restraint over flourish — motion confirms/orients, never decorates.

### Claude's Discretion
- Whether to wire vs remove `rs-confirm-pop` (prefer wiring it to a genuine confirm/notice entrance if one exists; else remove dead keyframe).
- Any single additional purposeful entrance (e.g. async-resolved panels) if it clearly serves orientation — but bias to NOT adding.
</decisions>

<code_context>
## Existing Code Insights
- `rulestead_admin.css` motion region (~lines 4155-4200, 4455): `@keyframes rs-slide-in`/`rs-confirm-pop`; `.rs-card--flag`/`.rs-record-row`/`.rs-settle` entrances; `.rs-badge:hover` scale; all under `prefers-reduced-motion: no-preference`.
- `[data-theme-pending] *{transition:none}` (Phase 90, ~line 2076) — the theme-switch snap suppression; sub-frame window, won't fight real animations.
- Motion tokens: `--rs-motion-fast`(150), `--rs-motion-base`(200), `--rs-motion-slow`(320), `--rs-ease-out`, `--rs-ease-standard`, `--rs-ease-in-out`, `--rs-ease-emphasis`.

### Integration Points
- rulestead_admin.css motion blocks only (ease refinement + confirm-pop wiring/removal + a color-transition audit).
</code_context>

<specifics>
## Specific Ideas
- Verify: grep shows no `transition:` on color/background/border-color (theme-swap flicker guard); entrances use ease-out; durations all <300ms (tokenized); reduced-motion path yields no animation; theme switch (System↔Dark↔Light) shows instant token swap with no wipe (Playwright/manual on the harness/control). Existing 28 specs green; compile clean; design-system gate 0 violations.
</specifics>

<deferred>
## Deferred Ideas
- View Transitions API / route-change choreography → Future (MOT-03).
</deferred>

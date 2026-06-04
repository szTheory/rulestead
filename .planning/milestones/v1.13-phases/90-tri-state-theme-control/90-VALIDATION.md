---
phase: 90
slug: tri-state-theme-control
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 90 — Validation Strategy

> JS + LiveView component phase. All THM-02/THM-04 behavior is pure client-side → validate via a `file://` Playwright fixture that includes the control markup + an inlined copy of the colocated hook logic. Do NOT boot the demo (DB-conflict gotcha). Plus grep/compile assertions on the Elixir + CSS.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Playwright (`examples/demo/frontend`) + new `file://` control fixture |
| Fixture | `theme-control-harness.html` (control markup + inlined hook logic + localStorage) |
| Spec | `theme-control.spec.ts` |
| Compile | `cd rulestead_admin && mix compile --warnings-as-errors` |
| Existing | `theme-cascade.spec.ts` + `theme-scope.spec.ts` must stay 8/8 |

## Sampling Rate
- Per edit: `mix compile` on shell.ex; run `theme-control.spec.ts`.
- Phase gate: all persistence/system-follow/pinned-wins/snap/a11y cases pass + compile clean + existing theme specs 8/8.

## Per-Requirement Verification Map

| Req | Behavior | Method | Pass condition |
|-----|----------|--------|----------------|
| THM-02 | Selecting Dark/Light/System applies immediately | Playwright | clicking option sets/removes `data-theme` on `.rs-shell` correctly |
| THM-02 | Choice persists across reload (per device) | Playwright | reload page → previously-selected theme still applied; `localStorage["rulestead_admin.theme"]` set |
| THM-02 | System mode = NO `data-theme` attr (not `="system"`) | Playwright | system option → `data-theme` ABSENT; `@media` drives |
| THM-04 | System users: no flash on first paint (dark OS) | Playwright colorScheme emulation | dark tokens at first paint with no attribute |
| THM-04 | Pinned-mismatch: instant snap, no animated wipe | Playwright | `[data-theme-pending]` present at render, removed in mounted(); transitions suppressed during snap (no transition on color props while pending) |
| THM-04 | System mode live-updates on OS change; pinned ignores | Playwright matchMedia emulation | emulate OS dark→light: system follows; pinned does not |
| A11Y | Segmented control: radiogroup + arrow keys + aria-checked | Playwright keyboard | arrow keys move selection; aria-checked tracks active; focus ring (Phase 89) visible |
| — | `aria-checked` re-syncs after a LiveView patch | Playwright/code review | hook implements `updated()` to re-assert child state |
| — | theme_default attr documented + optional host head-script documented | grep docs | integration guide updated; attr present on page/1 |
| — | mix compile clean; existing theme specs 8/8 | compile + Playwright | exit 0; 8/8 |

## Wave 0 Gaps
- [ ] `theme-control-harness.html` (or extend theme-harness.html) — segmented control markup + inlined hook logic for file:// testing.
- [ ] `theme-control.spec.ts` — persistence, system-follow, pinned-wins, no-wipe snap, keyboard a11y.
- [ ] The colocated `.ThemeControl` hook MUST implement BOTH `mounted()` (read localStorage, apply, clear pending, wire clicks + matchMedia) AND `updated()` (re-sync aria-checked/tabindex after LiveView patches — finding #2).

## Phase-Complete Definition
A segmented System/Light/Dark control in the shell header applies + persists the theme per device across reloads; System mode follows the OS live and is the *absence* of `data-theme`; pinned themes win and correct with an invisible snap (no animated wipe); the control is keyboard/ARIA accessible with the Phase-89 focus ring; `aria-checked` survives LiveView patches; `theme_default` + optional host head-script are documented; compile clean; existing theme specs still 8/8.

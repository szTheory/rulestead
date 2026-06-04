---
phase: 87-token-theme-foundation
plan: "01"
subsystem: ui
tags: [playwright, typescript, css-tokens, wcag, theming, dark-mode]

requires: []
provides:
  - Standalone static HTML harness for rs-shell theming (no Phoenix required)
  - Playwright spec covering all 5 cascade-precedence cases (THM-01, THM-03)
  - Playwright spec covering :root token absence and outside-shell scope containment (THM-05)
  - WCAG AA contrast-check helper with correct W3C luminance formula (THM-06)
affects:
  - 87-02 (CSS light-default refactor — these specs are its acceptance gate)
  - 87-03 (dark token set — theme-cascade.spec.ts tests 2/3/5 are its acceptance gate)

tech-stack:
  added: []
  patterns:
    - "Theme harness: standalone file:// HTML with setTheme()/clearTheme() JS API"
    - "Playwright OS emulation: browser.newContext({ colorScheme }) per test case"
    - "WCAG ratio: W3C relative luminance formula, no external library"

key-files:
  created:
    - rulestead_admin/priv/static/theme-harness.html
    - examples/demo/frontend/tests/theme-cascade.spec.ts
    - examples/demo/frontend/tests/theme-scope.spec.ts
    - examples/demo/frontend/tests/support/contrast-check.ts
  modified: []

key-decisions:
  - "Harness uses file:// navigation (no server needed) — tests pass without booting Phoenix"
  - "Cascade spec uses browser.newContext({ colorScheme }) not prefers-color-scheme media mock — cleaner per-test isolation"
  - "wcagRatio is pure TypeScript with no external dependency — the W3C formula is trivial inline"
  - "outside-shell probe uses CSS var(--rs-bg, red) fallback — visual + automated check in one element"

patterns-established:
  - "Theme specs open harness via file:// path constructed with path.resolve(__dirname, ...)"
  - "shellVar() helper abstracts getComputedStyle(.rs-shell).getPropertyValue() for reuse"

requirements-completed:
  - THM-01
  - THM-03
  - THM-05
  - THM-06

duration: 15min
completed: 2026-06-04
---

# Phase 87 Plan 01: Token Theme Foundation — Validation Scaffolding Summary

**Standalone HTML harness, five-case Playwright cascade spec, scope-containment spec, and WCAG contrast-check helper providing the complete verification substrate for Plans 02 and 03.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-04T07:31:00Z
- **Completed:** 2026-06-04T07:46:00Z
- **Tasks:** 2 of 2
- **Files created:** 4

## Accomplishments

- Authored `rulestead_admin/priv/static/theme-harness.html` — a standalone static fixture that links the real stylesheet relatively, renders the full rs-shell with all five badge tones, three flash variants, surface swatches, disabled button, and an outside-shell scope probe. Requires no Phoenix, no Elixir, no server.
- Authored `theme-cascade.spec.ts` — five Playwright tests that cover the complete VALIDATION.md cascade-precedence matrix using `browser.newContext({ colorScheme })` for clean per-test OS emulation. Tests 2, 3, and 5 are the acceptance gate for Plan 03.
- Authored `theme-scope.spec.ts` — three tests verifying that `:root` carries no `--rs-neutral-0` or `--rs-bg` after Plan 02's refactor, and that the outside-shell probe element shows the red fallback (not the --rs-bg resolved value). Acts as a regression guard for the token-scoping discipline.
- Authored `contrast-check.ts` — pure TypeScript WCAG ratio helper (`wcagRatio` + `assertAA`) implementing the W3C relative luminance formula with no external dependencies. TypeScript compiles clean under the project's `module: ESNext / moduleResolution: Bundler` config.

## Task Commits

1. **Task 1: Static HTML theme harness** — `57df382` (feat)
2. **Task 2: Playwright cascade and scope specs** — `4029db3` (feat)

**Plan metadata commit:** (follows this SUMMARY)

## Files Created

- `rulestead_admin/priv/static/theme-harness.html` — Dev fixture; links `./css/rulestead_admin.css` relatively, `window.setTheme()` / `window.clearTheme()` exposed, no data-theme at load
- `examples/demo/frontend/tests/theme-cascade.spec.ts` — 5 cascade tests (THM-01, THM-03)
- `examples/demo/frontend/tests/theme-scope.spec.ts` — 3 scope-containment tests (THM-05)
- `examples/demo/frontend/tests/support/contrast-check.ts` — WCAG helper (THM-06)

## Decisions Made

- Used `file://` + `path.resolve(__dirname, ...)` for harness navigation — no demo server dependency. Tests remain runnable even during DB-conflict scenarios (RESEARCH §5 fallback).
- Kept `wcagRatio` as inline TypeScript rather than importing a third-party library — the W3C formula is ~10 lines; adding a dependency would be disproportionate.
- `shellVar()` helper abstracts the repeated `getComputedStyle(document.querySelector('.rs-shell')).getPropertyValue(v)` pattern — one place to change if the harness selector changes.
- Cascade tests use `browser.newContext({ colorScheme })` (not `page.emulateMedia`) — new context per test ensures clean state with no cross-test color-scheme leakage.

## Deviations from Plan

None — plan executed exactly as written. The `wcagRatio('#ffffff','#1a2332')` value is ~15.78 (the plan says "close to 14.0" as an approximation; both values clearly pass the ≥4.5:1 AA gate, confirming the formula is correct).

## Issues Encountered

None.

## Known Stubs

None. This plan creates test infrastructure only; no data flows to the UI.

## Threat Flags

None. All new files are static dev/test fixtures with no user input, no server exposure, and no secrets. Covered by T-87-01 in the plan's threat model (accepted: dev/test tool only).

## Self-Check

Files exist:
- [x] `rulestead_admin/priv/static/theme-harness.html`
- [x] `examples/demo/frontend/tests/theme-cascade.spec.ts`
- [x] `examples/demo/frontend/tests/theme-scope.spec.ts`
- [x] `examples/demo/frontend/tests/support/contrast-check.ts`

Commits exist:
- [x] `57df382` — feat(87-01): add standalone HTML theme harness
- [x] `4029db3` — feat(87-01): add Playwright theme specs and WCAG contrast-check helper

TypeScript: tsc --noEmit passes clean.

## Self-Check: PASSED

## Next Phase Readiness

- Plan 02 (CSS light-default token migration) can begin immediately — `theme-scope.spec.ts` will gate it.
- Plan 03 (dark token set) can begin immediately — `theme-cascade.spec.ts` tests 2, 3, and 5 will gate it.
- The harness is ready for `setTheme('dark')` visual inspection once Plan 02 completes.

---
*Phase: 87-token-theme-foundation*
*Completed: 2026-06-04*

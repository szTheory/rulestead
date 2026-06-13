---
phase: 87
slug: token-theme-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 87 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This phase is **pure CSS** (token-layer refactor, no Elixir/JS/route changes). There is no unit-testable logic — validation is **visual review + automated WCAG-AA contrast checks + CSS-scope inspection**.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright (existing, `examples/demo/frontend`) + standalone static HTML harness |
| **Config file** | `examples/demo/frontend/playwright.config.ts` |
| **Quick run command** | Open static harness, flip `data-theme` in devtools, visual inspect both themes |
| **Full suite command** | `cd examples/demo/frontend && npx playwright test theme-*.spec.ts` |
| **Contrast tool** | WCAG ratio computation per token pair (inline script or webaim contrast checker) |
| **Estimated runtime** | ~30s (harness) / ~2min (Playwright if demo reachable) |

**Local-demo gotcha:** `rulestead_demo_dev` is shared by two repos with conflicting migrations (`mix ecto.setup` → PendingMigrationError locally). Fallback for THIS phase: a standalone static HTML harness (`/tmp/rs-theme-harness.html`) that `<link>`s the stylesheet and renders representative `.rs-shell` markup — screenshot both themes without booting the Phoenix demo. Playwright specs are authored but may run in CI/compose rather than locally.

---

## Sampling Rate

- **After every token-block edit:** visual inspect in the static HTML harness in both themes (light + `data-theme="dark"`).
- **Phase gate (before close):** full contrast check across ALL token pairs in the map below + screenshots of home/flags/detail in both themes + all 5 cascade-precedence cases covered.
- **Max feedback latency:** ~30s (harness inspect).

---

## Per-Task Verification Map

| Req ID | Behavior to validate | Test Type | Command / Method | Pass condition |
|--------|----------------------|-----------|------------------|----------------|
| THM-01 | System dark applies on dark OS with no `data-theme` attribute | Visual | devtools emulate `prefers-color-scheme: dark`, no attribute → screenshot | Dark tokens active |
| THM-03 | Explicit `data-theme="dark"` beats system light | Visual | set attribute + emulate light OS → screenshot | Dark tokens active |
| THM-03 | Explicit `data-theme="light"` beats system dark | Visual | set attribute + emulate dark OS → screenshot | Light tokens active |
| THM-05 | `:root` carries no dark **color** variables | CSS inspect | grep CSS / devtools computed on `<html>` | No `--rs-bg`/ramp/color tokens resolve on `:root` |
| THM-05 | Element outside `.rs-shell` has no `--rs-*` color | CSS inspect | harness `<div>` outside `.rs-shell` → `var(--rs-bg)` empty | Resolves empty |
| THM-05 | `<html>` `color-scheme` not forced to dark by package | CSS inspect | devtools computed `color-scheme` on `<html>` | Browser/host default, not `dark` |
| THM-06 | Dark palette reads mineral-dark, on-brand (not pure black / not generic grey) | Visual | screenshot + human review (base ~#10161f, text ~#e8edf3) | On-brand, elevation via lighter surfaces + hairline |
| THM-06 | WCAG AA on every text/surface + base-on-soft pill pair, both themes | Contrast | WCAG ratio per pair (text ≥4.5:1, large/UI ≥3:1) | All pairs pass; **blocking gate** |

### Cascade-precedence matrix (all 5 must be screenshotted/inspected)

| Case | Setup | Expected |
|------|-------|----------|
| No attr, light OS | no `data-theme`, emulate light | Light active |
| No attr, dark OS | no `data-theme`, emulate dark | Dark active (THM-01) |
| Pinned dark, light OS | `data-theme="dark"`, emulate light | Dark active (THM-03) |
| Pinned light, dark OS | `data-theme="light"`, emulate dark | Light active (THM-03) |
| Pinned dark, dark OS | `data-theme="dark"`, emulate dark | Dark active (redundant, verify) |

---

## Wave 0 Gaps (validation assets to create during execution)

- [ ] Static HTML harness (`/tmp/rs-theme-harness.html` or `rulestead_admin/priv/static/theme-harness.html`) — links the stylesheet, renders `.rs-shell` representative markup, supports `data-theme` flip. Covers THM-06 visual + contrast sampling and THM-05 scope checks.
- [ ] `examples/demo/frontend/tests/theme-cascade.spec.ts` — covers THM-01, THM-03 (dark-OS, pinned-dark, pinned-light cases) via Playwright `colorScheme` emulation.
- [ ] `examples/demo/frontend/tests/theme-scope.spec.ts` — covers THM-05 (`:root`/`<html>`/outside-`.rs-shell` containment).
- [ ] Contrast-check assertion (small inline script or axe-core run over computed token values) producing a pass/fail list for the THM-06 AA gate.

---

## Phase-Complete Definition

Phase 87 is complete when: all 5 cascade-precedence cases render correctly in both themes (screenshots on file) **AND** every token pair in the verification map passes WCAG AA in both themes **AND** scope-containment confirms `:root`/`<html>`/outside-`.rs-shell` carry no dark color overrides.

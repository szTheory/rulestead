---
phase: 94
slug: restrained-micro-animation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 94 — Validation Strategy

> Confirmation + principle-aligned motion refinements. Validation = grep assertions (transform/opacity only, ease-out entrances, no color transitions, <300ms tokens, reduced-motion gating) + theme-switch no-flicker check + the design-system gate + compile.

## Per-Requirement Verification Map
| Req | Behavior | Method | Pass |
|-----|----------|--------|------|
| MOT-01 | Animations transform/opacity only (no layout props) | grep | 0 `transition:`/keyframes on width/height/top/left/margin/padding |
| MOT-01 | Entrances use ease-out; durations <300ms, tokenized | grep | entrance animations reference `--rs-ease-out`; durations use `--rs-motion-*` (<300ms) |
| MOT-01 | Purposeful, not decorative; no motion on high-frequency controls | review | motion only on entrances/confirm/subtle-hover |
| MOT-02 | `prefers-reduced-motion: reduce` → no motion | grep | all motion under `@media (prefers-reduced-motion: no-preference)` |
| MOT-02 | Theme switch = instant token swap, no animated wipe | grep + check | NO `transition:` on color/background/border-color; `[data-theme-pending]` snap intact |
| — | confirm-pop wired (not dead) or removed | grep | `rs-confirm-pop` referenced by a rule, or removed |
| — | specs green; gate 0 violations; compile clean | Playwright + compile | 28/28; 0 violations; exit 0 |

## Phase-Complete Definition
All motion is transform/opacity-only, ease-out for entrances, <300ms tokenized, gated behind reduced-motion, and never animates color (so theme switching is an instant flicker-free swap); confirm-pop is wired or removed; design-system gate + existing specs stay green; compile clean.

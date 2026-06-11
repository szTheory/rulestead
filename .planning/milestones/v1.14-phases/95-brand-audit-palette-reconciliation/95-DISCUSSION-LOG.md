# Phase 95: Brand Audit + Palette Reconciliation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 95-brand-audit-palette-reconciliation
**Mode:** assumptions
**Areas analyzed:** Deliverable Location & Format, Brand-Book Relocation Timing, OKLCH Remediation Tooling & Method, Palette Reconciliation Scope (failing pairings + surface set)

## Assumptions Presented

### Deliverable Location & Format
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reconciliation table + pressure-test audit written as phase artifact under `.planning/phases/95-.../`, not committed to `brandbook/`; columns brand name → shipped hex → proposed hex → AA-verified hex → ratio → surface → role + OKLCH hue pre/post | Confident | `ARCHITECTURE.md:358` ("can live in `.planning/` or as a phase artifact. No files committed to `brandbook/` yet"); `brandbook/` does not exist until Phase 96; ROADMAP Phase 95 success criteria 1 & 2 |

### Brand-Book Relocation Timing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Brand book NOT relocated in Phase 95; Phase 95 confirms relocation happens in Phase 96; pressure-test audit written against `prompts/rulestead-brand-book.md` working-tree | Confident | ROADMAP Phase 95 criterion 5 ("or the decision to relocate it during Phase 96 is confirmed"); Phase 96 criterion 5 owns the move; `ARCHITECTURE.md:364-368`; ~966 uncommitted lines in brand book |

### OKLCH Remediation Tooling & Method
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Ratios + OKLCH angles computed by short python3 stdlib snippet (values pre-computed in research docs), not a reusable harness; method = uniform-RGB-scale darkening, never HSL | Likely | `PITFALLS.md:5` ("no third-party tool required"); `STACK.md:27` (python3 stdlib); Phase-87 "wcagRatio harness" not discoverable in repo; v1.13 gate was Elixir literal-hex assertions (`v1.13-MILESTONE-AUDIT.md:57`); v1.13 precedent `#c45c26 → #9a3f12` |

### Palette Reconciliation Scope (failing pairings + surfaces)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Targeted remediation: light failers Ember Copper / Warning / Moss Grey; dark `#10161f` failers Stead Blue / Success / Danger / Info; Stead Blue & Ink Blue on white already pass; Signal Gold = decorative-only policy; surfaces `#FFFFFF`, `#E8ECE8`, `#F5F7F6`, `#10161f`. Shipped CSS not yet mineral (`--rs-primary: #2563eb`, `--rs-accent: #9a3f12`) | Confident | `SUMMARY.md:93`; `PITFALLS.md:11-50`; ROADMAP criteria 1 & 4; shipped `rulestead_admin.css` Block 1 tokens; `ARCHITECTURE.md:350` |

## Corrections Made

No corrections — all assumptions confirmed via single "Yes, proceed" gate.

## External Research

None performed. The committed research docs (`PITFALLS.md`, `SUMMARY.md`, `STACK.md`,
`ARCHITECTURE.md`) already supplied computed WCAG 2.x ratios, the OKLCH uniform-RGB-scale
method with measured hue drift, per-color AA-passing target hexes, and the deliverable
location. The one residual uncertainty (existence of a reusable Phase-87 TypeScript
contrast harness) was resolved by direct repo search — it does not exist as a committed
reusable tool; the prescribed fallback is python3 stdlib.

## Methodology

Applied lenses from `.planning/METHODOLOGY.md`: **Recommendation-First**,
**Research-Then-Recommend**, **Architect-Default Discuss**. Per these lenses, all
gray areas were researched together (via a single gsd-assumptions-analyzer pass) and
returned as one cohesive, evidence-backed decision set rather than an area-by-area
questionnaire. No decision in this phase hit the high-impact exception (public API /
wire contract / security / release model / package boundary), so decisions were locked
directly into CONTEXT.md after a single confirmation gate. The maintainer hex sign-off
remains an explicit phase-close gate (D-11), consistent with the high-impact-exception
spirit for materially user-facing design acceptance.

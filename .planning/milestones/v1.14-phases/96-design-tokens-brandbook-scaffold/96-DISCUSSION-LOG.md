# Phase 96: Design Tokens (`brandbook/` scaffold) - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 96-design-tokens-brandbook-scaffold
**Mode:** assumptions
**Areas analyzed:** DTCG token structure, tokens.css shape, check_brand_tokens.py semantics, brandbook/ directory layout, lint.sh SVG budget loop, brand-book relocation + §12 rework

## Methodology Lenses Applied

`.planning/METHODOLOGY.md` active lenses (Recommendation-First, Research-Then-Recommend,
Architect-Default Discuss) all bias toward deep in-agent analysis and one cohesive
recommendation set, escalating only materially high-impact choices. Phase 96 is a
well-specified scaffold phase (success criteria are prescriptive; all hex values
pre-locked in Phase 95), so the analyzer returned all assumptions at Confident/Likely
with zero Unclear items. Per the lenses, the full set was locked after a single
confirmation gate — no per-area questionnaire. No high-impact exception triggered
(no public API, wire contract, security/governance, release-model, or package-boundary
change; tokens.json is not programmatically consumed, so structural choices are reversible).

## Assumptions Presented

### DTCG token structure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Three-tier primitive→semantic→state DTCG model; scalars in shared invariant group | Likely | rulestead_admin.css:127–163 invariant/variant split; DTCG alias syntax models var() |
| Light/dark via top-level group split, NOT $extensions modes | Likely | mirrors CSS blocks, human-diffable, no programmatic consumer |
| admin_css_mapping = top-level dict, light/dark sub-objects, variant `--rs-*` only | Likely | criterion 1; invariants never vary per theme |
| Values encoded verbatim from Phase 95 lock; info/subtle/muted/selected have no 1:1 CSS name | Confident | 95-PALETTE-RECONCILIATION §4/§8; token inventory |

### tokens.css shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Simplified two-block light/dark pair + :root invariants, NOT all four blocks | Likely | 4-block precedence is a live-app concern only |
| Tailwind excerpt (TOK-04) as trailing commented-out block | Likely | "optional"; live tokens would break .rs-shell scope lock |

### check_brand_tokens.py semantics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reads tokens.json admin_css_mapping.light, compares vs CSS Block 1, mirrors check_synced_pair.py style | Confident | ROADMAP Phase 98 gate names Block 1 + exact pass message |
| Must FAIL now (exit 1, per-token diff) vs generic Block-1 hexes | Confident | shipped #2563eb/#9a3f12/etc vs mineral canonicals |

### brandbook/ directory layout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| brand-book.md, tokens.json, tokens.css, README.md, docs/brand-usage.md; VOICE/RELEASE/BUDGET/assets deferred | Confident | criteria 4–5; ROADMAP assigns rest to 97/99/100 |

### lint.sh SVG budget loop
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Strictly additive; token check + no-op-safe nullglob SVG budget loop (logo ≤20KB / specimen ≤50KB) | Confident | criterion 4 additive; set -euo pipefail needs nullglob; only intentional fail is token check |

### brand-book relocation + §12 rework
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| git mv + pointer stub in prompts/; commit working-tree edit first | Likely | locked relocation decision; git mv preserves history |
| §12 hex literals → AA-verified canonicals + Gap-2 per-surface note; §8 tagline unchanged | Likely | 95-PALETTE-RECONCILIATION §4/§8; §8 already "Runtime decisions, made clear." |

## Corrections Made

No corrections — all assumptions confirmed via the single confirmation gate ("Yes, proceed").

## External Research

None performed. DTCG 2025.10 is a known, stable spec; the locked mirror-not-generate
decision means no tooling-conformance pressure (the JSON only needs to be valid
DTCG-shaped and human-diffable). All hex values were pre-locked and verified in Phase 95
(`scripts/check_contrast.py`, 18 checks PASS). The analyzer flagged no research gaps.

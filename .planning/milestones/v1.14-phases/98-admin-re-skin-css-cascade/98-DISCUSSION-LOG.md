# Phase 98: Admin Re-skin (CSS Cascade) - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-05
**Phase:** 98-admin-re-skin-css-cascade
**Mode:** assumptions
**Areas analyzed:** Cascade block identity & edit surface, Exact hex swap set,
Verification-coverage strategy, design-system.html swatch update, Gap-2 encoding

## Assumptions Presented

### Cascade Block Identity & Edit Surface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Edit Block 1 (`:225-303`) + Block 3 (`:388-467`), mirror to Block 4 (`:469-549`) / Block 2 (`:305-386`); colors only; invariant `:root` untouched | Confident | `rulestead_admin.css:224,305,388,469`; synced-pair header `:186-193`; `:root` `:39-119`; ROADMAP SC-1 |

### Exact Hex Swap Set
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Block 1: 7 light declarations change to mineral; Block 3: parallel dark set + `--rs-success-border` `#166534`→`#166634` | Confident | Live `check_brand_tokens.py` prints the 7 light mismatches; `tokens.json` `admin_css_mapping.light:302-346` / `.dark:348-387` (incl. `:370`); case-insensitive `:69` |

### Verification-Coverage Strategy (gray area)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `check_synced_pair.py` guards 2≡3 ONLY (not 1≡4); `check_brand_tokens.py` diffs light Block 1 ONLY; `check_contrast.py` uses a CSS-independent hardcoded matrix | Confident | `check_synced_pair.py:45-48` (runs `SYNCED PAIR IDENTICAL (56 tokens)`); `check_brand_tokens.py:51,55`; `check_contrast.py:144-214`; Phase 96 D-08 permits dark diff |

### design-system.html Swatch Update
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Swatches 100% var-driven; auto-update; no manual hex edit, no new swatches | Confident | `design-system.html:213-270`; literal hexes `#333:57`/`#888:361` are scaffold chrome |

### Gap-2 Per-Surface Encoding
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Success `#2d7753` / Danger on Stone Mist already in `tokens.json admin_css_mapping`; encode verbatim | Confident | Phase 96 D-04/D-11; `tokens.json admin_css_mapping` |

## Corrections Made

No corrections — all assumptions confirmed ("All correct — proceed").

## Decisions Confirmed by User

### Verification-coverage strategy → "Extend both guard scripts"
- **Choice:** Extend `check_synced_pair.py` to also assert Block 1≡4 (light pair), AND
  extend `check_brand_tokens.py` to also diff Block 3 vs `admin_css_mapping.dark`.
- **Rejected alternatives:** (1) extend synced-pair only + manual dark checklist;
  (2) no script changes + manual checklists for both invariants.
- **Reason:** Machine-verify SC-2 and SC-4; matches milestone scripts-first drift-guard
  ethos; honors SC-2 as written (light-pair clause currently unguarded); prevents a wrong
  dark hex shipping silently. D-08 permits the additive dark diff. → CONTEXT.md D-05.

## External Research

None — self-contained colors-only edit; all targets locked in `tokens.json`; all three
harnesses exist, run, and have confirmed current exit statuses (synced=0, brand-tokens=1
as-designed, contrast=0).

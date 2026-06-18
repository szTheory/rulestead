# Phase 125: Version-Truth Sweep + Release Docs - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-18
**Phase:** 125-version-truth-sweep-release-docs
**Mode:** assumptions
**Areas analyzed:** A. File inventory · B. Exclusion classes · C. Drift guard shape · D. upgrading.md + MAINTAINING.md grafting · E. CHANGELOG preamble artifact + contract-test collision

## Assumptions Presented

### A. File inventory + per-file change set
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 13 shipped files carry stale version language (roadmap's "~14" rounds up; CONTRIBUTING.md clean) | Confident | criterion-1 grep over README.md, 3 package READMEs, guides/, MAINTAINING.md, CONTRIBUTING.md |
| `examples/demo/README.md` NOT swept (out of scope + asserted at test L265) | Confident | criterion-1 file list excludes examples/; `release_contract_test.exs:265` |

### B. Exclusion classes preserved verbatim
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Third-party `{:open_feature, "~> 0.1.3"}` untouched; generated `rulestead/doc/` not hand-edited; `.planning/`+`prompts/`+demo historical | Confident | `open_feature_rulestead/README.md:28`; `rulestead/mix.exs` extras source `../guides/...`; criterion-1 carve-out |

### C. lint.sh drift-guard shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Ship as scripts-first `scripts/check_version_truth.py` (not inline grep), fixed-string `~> 0.1` match to protect `~> 0.1.3`, scoped to shipped surface | Likely | `lint.sh` has 8 `check_*.py` guards + 1 inline SVG block; CLAUDE.md scripts-first rule; D-04 exclusion nuance |

### D. upgrading.md + MAINTAINING.md grafting
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Additive sections reframe in place; MAINTAINING runbook includes mandatory post-cut `Release-As` removal | Likely | existing skeletons in both files; `release-please.yml:~85` echoes `Release-As: 0.1.0` |
| Runbook must note `open_feature_rulestead` is manual (not release-please managed) | Likely | `release-please-config.json` lists only rulestead + rulestead_admin |

### E. CHANGELOG preamble artifact + contract-test collision
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preamble staged as `brandbook/CHANGELOG-PREAMBLE-1.0.md`, not committed to bot-managed CHANGELOGs | Confident | `changelog-path` in `release-please-config.json`; `brandbook/RELEASE-TEMPLATE.md` precedent |
| Contract-test `0.1.x`/"Two version lines" asserts must flip in lockstep — overrides Phase 124 D-03 for swept files; demo assert (L265) survives | Confident | `release_contract_test.exs:233-285` reads real files; bidirectional guard |

## Corrections Made

No corrections — all assumptions confirmed via the "Yes, proceed" gate.

Note: one orchestrator-level refinement was applied before presenting (not a user correction):
Area C diverged from the analyzer's "inline bash grep" recommendation to a scripts-first
`check_version_truth.py`, justified by the 8/9 Python-guard dominant pattern in `lint.sh` and
the CLAUDE.md scripts-first rule. Verified the contract-test collision (Area E) directly
against `release_contract_test.exs:233-285` before presenting.

## External Research

None — the codebase fully determined this docs-sweep phase.
</content>

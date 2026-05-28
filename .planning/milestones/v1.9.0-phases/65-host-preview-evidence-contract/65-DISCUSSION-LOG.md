# Phase 65: Host Preview Evidence Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 65-host-preview-evidence-contract
**Mode:** assumptions
**Areas analyzed:** Resolver seam, Store integration, ImpactPreview v2, preview_basis taxonomy, Bounded validation, Redaction, Stale fingerprint, Governance boundary, Phase scope, Plan structure

---

## Assumptions Presented

### Resolver seam shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Rulestead.Targeting.PreviewEvidence` behaviour + config via `:preview_evidence_resolver`, mirror `Guardrails.Provider` | Confident | `guardrails/provider.ex`, `guardrails.ex` |

### Integration point
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Call resolver from `audience_preview_payload/4` in Fake+Ecto before `ImpactPreview.build/1`; pure build stays in `ImpactPreview` | Confident | `store/ecto.ex`, `fake.ex` |

### ImpactPreview extension
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Schema version 2; add `impression_evidence`; fingerprint includes `impression_fingerprint` | Likely | `targeting/impact_preview.ex` |

### preview_basis taxonomy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New basis strings for host evidence present / unavailable; never set `authoritative_population_count?: true` | Likely | `impact_preview.ex`, `research/SUMMARY.md` pitfall #2 |

### Bounded payloads
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Hard caps (25 samples, ~16 KiB payload); fail-closed with existing `:invalid_command` errors | Confident | REQUIREMENTS IMP-05, Phase 57 error pattern |

### Redaction
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse `Redaction.redact_metadata/2`; impression allowlist for D-06 fields only | Confident | `impact_preview.ex` sample redaction |

### Stale fingerprint (IMP-06)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Evidence changes invalidate fingerprint; no bypass via richer evidence | Confident | `impact_preview_test.exs`, `ensure_fresh_audience_preview` |

### Governance boundary (GOV-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `BlastRadiusThreshold` remains reference-count-only | Confident | `blast_radius_threshold.ex`, STATE.md, Phase 57 CONTEXT |

### Phase scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Core contract only; no admin UI, audit carry-through, or phase 68 docs in 65 | Confident | ROADMAP 65–68 split |

### Plan structure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Four plans: seam → ImpactPreview v2 → store wiring → contract tests | Likely | Phase 61 CONTEXT D-09 |

### Defaults locked without user correction
| Topic | Locked default |
|-------|----------------|
| Impression summary shape | `window_label`, `sampled_impressions`, `matched_impressions`, optional `variant_breakdown` |
| Sample merge | Union with explicit `command.samples` preserved; cap 25 total |
| No resolver | Unchanged pre-v1.9 behavior |

---

## Corrections Made

No corrections — all assumptions confirmed by user ("Yes, proceed").

---

## External Research

None required — codebase and planning artifacts sufficient.

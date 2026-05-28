# Phase 67: Mounted Preview Evidence Workflows - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 67-mounted-preview-evidence-workflows
**Mode:** assumptions
**Areas analyzed:** Evidence presentation, Uncertainty/basis copy, Preview route behavior, Confirm/governance carry-through, Four-plan execution shape

## Assumptions Presented

### Evidence presentation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `AudienceComponents.impact_preview/1` with sample table + impression summary sections; no new routes | Likely | `audience_components.ex`, preview LiveViews use shared component |

### Uncertainty and basis copy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Use core `uncertainty.message`; extend `humanize_preview_basis/1` for all three Phase 65 basis values | Confident | `impact_preview.ex` `@uncertainty_messages`; component hardcodes old copy |

### Preview route behavior
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Minimal LiveView changes; keep `preview_audience_impact/3`; fail-closed via existing error alert | Confident | `edit_preview.ex`, `archive_preview.ex`, `delete_preview.ex` |

### Confirm / governance carry-through
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No confirm refactors; add mounted tests with `Fake.PreviewEvidenceResolver` | Confident | `edit_confirm.ex` apply attrs; Phase 66 CR metadata frozen |

### Four-plan execution
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 67-01 component, 67-02 edit/archive tests, 67-03 delete/governance tests, 67-04 contract sweep | Likely | Phases 63/65/66 four-plan pattern |

## Corrections Made

No corrections — all assumptions confirmed (user selected "Yes, proceed").

## External Research

Not performed — codebase evidence sufficient.

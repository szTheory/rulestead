# Phase 49: Guardrail Signal Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `49-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-05-26
**Phase:** 49-guardrail-signal-contract
**Mode:** assumptions
**Areas analyzed:** host-owned signal seam, authored-state contract, signal status normalization, explicit scope propagation, package-boundary discipline

## Assumptions Presented

### Host-owned signal seam
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Rulestead should consume a host-provided normalized guardrail signal seam and should not own provider adapters, metrics fetching, or observability storage. | Confident | `prompts/rulestead-host-app-integration-seam.md`, `prompts/rulestead-security-privacy-and-threat-model.md`, `prompts/rulestead-telemetry-observability-and-audit.md` |

### Authored-state contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Guardrail definitions should attach to rollout authored state with explicit threshold, freshness, sample-size, and scope semantics rather than live as ambient runtime-only health state. | Likely | `rulestead/lib/rulestead/ruleset/rollout.ex`, `rulestead/lib/rulestead/promotion/apply.ex`, `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md`, `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` |

### Signal status normalization
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 49 should lock a bounded normalized status vocabulary that distinguishes healthy from missing, stale, insufficient-sample, and unsupported conditions, all of which remain fail-closed inputs. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` |

### Explicit scope propagation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Every signal query contract should preserve explicit environment and tenant scope and reuse the repo’s existing bounded provenance/metadata style. | Confident | `rulestead/lib/rulestead/context.ex`, `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/audit_event.ex`, `rulestead_admin/lib/rulestead_admin/live/session.ex`, `.planning/phases/29-tenancy-helpers-validation/29-CONTEXT.md` |

### Package-boundary discipline
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 49 should define contract semantics only and should not pre-build Phase 50 decision execution or Phase 51 mounted-admin behavior. | Confident | `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` |

## Corrections Made

None. User approved the assumptions as presented.

## External Research Applied

None. Codebase, roadmap, and prompt anchors provided sufficient evidence for the Phase 49 contract assumptions.

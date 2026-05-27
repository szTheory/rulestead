# Phase 51: Mounted Guardrail Workflow - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 51-mounted-guardrail-workflow
**Mode:** assumptions
**Areas analyzed:** Status Source, Mounted Workflow Scope, Display Semantics, Preservation And Timeline

## Assumptions Presented

### Status Source

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 51 should read guardrail health from core-owned `Rulestead.fetch_guardrail_status/3`, scoped by mounted environment and current rollout rule, not recompute decisions in LiveView or query persistence directly. | Confident | `.planning/phases/50-guarded-decision-engine-audit/50-CONTEXT.md`; `rulestead/lib/rulestead.ex`; `rulestead/lib/rulestead/store/command.ex`; `rulestead/lib/rulestead/fake.ex` |

### Mounted Workflow Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Guardrail health should be added to the existing per-flag rollout workflow and timeline surfaces, not as a new guardrail dashboard or global observability screen. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`; `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex` |

### Display Semantics

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The UI should render authored guardrail definitions plus latest operational status: threshold operator/value, freshness window, min sample size, decision state, decision reason, and bounded normalized evidence; missing status must render as pending/missing prerequisite copy, not a hidden or healthy state. | Confident | `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `rulestead/lib/rulestead/ruleset/rollout.ex`; `rulestead/lib/rulestead/ruleset/guardrail.ex`; `rulestead/lib/rulestead/guardrail_decision.ex`; `rulestead/lib/rulestead/store/command.ex` |

### Preservation And Timeline

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 51 must preserve authored `rollout.guardrails` when percentage edits save/publish, and timeline rows should label automatic guardrail hold/rollback/evaluation distinctly from manual rollout actions. | Likely | `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`; `rulestead/lib/rulestead/fake.ex`; `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`; `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` |

## Corrections Made

No corrections - all assumptions were codebase-supported and no high-impact exception remained after applying the Recommendation-First and Architect-Default Discuss lenses from `.planning/METHODOLOGY.md`.

## External Research

No external research was performed. The existing Phase 51 research document plus local codebase evidence were sufficient.

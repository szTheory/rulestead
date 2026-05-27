# Phase 61: Auto-Advance Authored Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 61-auto-advance-authored-contract
**Mode:** assumptions
**Areas analyzed:** Policy persistence, Pure evaluator, Phase boundary, Fail-closed semantics, Store parity, Observation window, Execution shape

---

## Assumptions Presented

### Policy persistence (per rollout rule)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Dedicated `rollout_auto_advance_policies` table with enabled, observation_window_seconds, next_stage, next_percentage | Confident | No auto_advance in codebase; AdvanceRollout uses stage/percentage; ROADMAP SC #1 |

### Pure evaluator module
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Rulestead.Guardrails.AutoAdvance` composes `Decision.evaluate/2`; returns Eligibility struct | Confident | `guardrails/decision.ex`; Phase 57 BlastRadiusThreshold pattern |

### Phase 61 = contract only
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No ScheduledExecution ticks or advance_rollout on success in Phase 61 | Confident | ROADMAP phases 61 vs 62 split |

### Fail-closed blocking
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Block on non-healthy states, incomplete policy, closed window without healthy facts | Confident | ROL-05; `guarded_rollout_test.exs` |

### v1.5 hold/rollback untouched
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No changes to `execute_guardrail_decision` hold/rollback paths | Confident | ROL-07; `store/ecto.ex` |

### Store surface and adapter parity
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| upsert/fetch/evaluate callbacks on Fake + Ecto | Likely | `guarded_rollout_test.exs` @adapters pattern |

### Observation window semantics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse monitoring_window_* on commands; policy stores duration | Likely | AdvanceRollout/EvaluateGuardedRollout structs |

### Four-plan execution shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 61-01..61-04 mirror Phase 57/60 | Likely | ROADMAP "4 plans (typical)" |

### Unclear items (resolved on confirm without correction)
| Item | Resolution in CONTEXT.md |
|------|--------------------------|
| A. Storage shape | D-01 dedicated table |
| B. Public API | D-08 thin Rulestead facade |
| C. Eligibility shape | D-07 Eligibility struct, no new action_type |

---

## Corrections Made

No corrections — all assumptions confirmed with "Yes, proceed".

---

## External Research

None required — codebase and milestone docs sufficient.

# Phase 63: Mounted Auto-Advance Workflows - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 63-mounted-auto-advance-workflows
**Mode:** assumptions
**Areas analyzed:** Surface placement, Policy editing, Prerequisites gate, Pending observation state, Protected environment callout, Timeline distinction, Component shape

---

## Assumptions Presented

### Surface placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend existing `FlagLive.Rollouts` page; no new route | Confident | `rollouts.ex` guardrail sections; Phase 59 D-02; ROADMAP SC #1 |

### Policy editing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inline authored form with direct save via `upsert_rollout_auto_advance_policy`; not ruleset confirm chain | Likely | Phase 61 D-01 separate table; `rulestead.ex` facade; admin UX §3 scope |

### Prerequisites gate
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `@auto_advance_mode` with fail-closed remediation; never imply healthy fleet | Confident | ADM-04; `RolloutComponents.guardrail_status`; ROADMAP SC #2 |

### Pending observation state
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Compose guardrail window + `list_scheduled_executions` filtered to `guardrail_automation` ticks | Likely | Phase 62 schedule at `monitoring_window_ends_at`; facade `list_scheduled_executions` |

### Protected environment callout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Informational CR callout; policy save allowed; no auto-approve | Likely | Phase 62 D-04; Phase 59 D-05 approval expectations |

### Timeline distinction (AUD-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `guardrail_automation_event?` to `rollout.advance` with `source: guardrail_automation` | Confident | Phase 62 audit metadata; `AuditComponents.timeline_row` Automatic/Manual labels |

### Component shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `RolloutComponents.auto_advance_panel/1`; four-plan structure 63-01–63-04 | Likely | Phase 59 `blast_radius_panel`; Phases 61/62 plan granularity |

## Corrections Made

No corrections — all assumptions confirmed by user ("Yes, proceed").

## External Research

None required — codebase and prior phase contracts sufficient.

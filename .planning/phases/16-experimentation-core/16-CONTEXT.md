# Phase 16: Experimentation Core - Context & Decisions

## Context
Rulestead is expanding from boolean/variant feature flags into formal experimentation (Phase 16). The goal is to support A/B tests with deterministic, sticky assignments and explicit start/stop lifecycles, without bloating the runtime or violating the purity of the evaluator. Importantly, Rulestead will *not* build a stats engine or analytics warehouse—we only emit the ground-truth exposure events required for downstream systems to calculate lift.

## Resolved Implementation Decisions

### 1. Data Model: Embed Experiments in the Ruleset
**Decision:** Experiments will not be modeled as a standalone Ecto schema with relational joins to flags. Instead, they will be modeled as a specialized rule type (e.g., `%Rule.Experiment{}`) embedded directly within the `Ruleset` JSONB payload.
**Rationale:**
- Maintains the `Ruleset` as the absolute single source of truth.
- Guarantees "zero-cost" ETS cache snapshotting, avoiding cache synchronization drift between relational tables.
- Aligns perfectly with the pure evaluator by simply introducing a new rule type in the evaluation chain.
- The draft/publish workflow natively inherits experiment changes.

### 2. Sticky Assignments: Immutable Frozen Salts
**Decision:** We will use an immutable "Frozen Iteration Salt" bound to the experiment's active lifecycle.
**Rationale:**
- A pure evaluator cannot do stateful lookups to see what variant a user was previously assigned.
- To prevent users from shifting variants mid-experiment (which ruins statistical validity), we bind a unique `experiment_salt` to the iteration when it is started.
- If an operator needs to change rollout percentages mid-flight, the system structurally enforces a new experiment "iteration" (with a new salt, re-randomizing the population), preventing Simpson's Paradox and protecting the integrity of the data.

### 3. Lifecycle: Compile-Time Reduction
**Decision:** The runtime cache payload will only contain *active* experiments. Stopped experiments will be reduced to standard rollout rules by the control plane.
**Rationale:**
- When an experiment is stopped and a winning variant is chosen, the control plane "bakes" that decision into a standard `%Rule.Rollout{}` or `%Rule.Target{}` for the next ETS snapshot.
- The evaluator never has to branch logic for "stopped" or "completed" states.
- This keeps the ETS payload minimal, evaluation blazing fast, and the hot path simple.
- Emitting experiment-specific telemetry cleanly halts because the rule type changes back to standard.

## Deferred to Future Phases
- **Analytics & Metrics Ingestion (Phase 17):** Storing impressions and calculating lift.
- **Experimentation UI (Phase 18):** Visualizing active experiments and their results.
- **Automatic Stop (Guardrails):** Halting an experiment automatically if an error rate spikes.
- **Multi-armed Bandits:** We will stick strictly to static A/B/n tests for this iteration.

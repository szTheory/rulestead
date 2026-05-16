# Discussion Log: Phase 16 - Experimentation Core

*Generated during `/gsd-discuss-phase 16`*

## Exploration: Data Model
**Question:** Does an "Experiment" exist as a separate Ecto schema that points to a Flag, or is an "Experiment" just a special type of Rule inside the Flag's rule list?
- We debated decoupling experiments completely to allow non-developers to manage them without touching the "code" flag.
- However, separating them introduces heavy relational joins at compile-time and risks cache-sync drift.
- Rulestead's core DNA is the single-source-of-truth `Ruleset`.
- **Outcome:** We will embed `%Rule.Experiment{}` directly into the Ruleset.

## Exploration: Sticky Assignments
**Question:** How do we guarantee sticky assignment for the lifetime of an experiment without requiring stateful runtime lookups?
- True sticky assignment (where an actor stays in bucket B even if bucket B shrinks) requires a stateful control plane or complex math.
- Given we mandate a pure evaluator with zero I/O, we must rely on deterministic hashing: `hash(user_id + experiment_salt)`.
- If percentages change, users shift. This is bad for stats.
- **Outcome:** We enforce immutable iterations. Once started, the `experiment_salt` and weights are frozen. To change them, you must start a new iteration.

## Exploration: Start/Stop Lifecycle
**Question:** How do we represent the start/stop lifecycle of an experiment in the runtime snapshot without complex DB lookups?
- If we put "stopped_at" in the payload, the evaluator has to check the clock and branch.
- Clock drift and payload bloat become risks.
- **Outcome:** Compile-time reduction. When an operator clicks "Stop and Rollout Winner", the backend strips the `%Rule.Experiment{}` and replaces it with a 100% standard rollout rule. The runtime never even knows the experiment stopped—it just gets a new set of basic rules.

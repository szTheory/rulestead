# Phase 19: Redis Storage & Caching Adapter - Context & Decisions

## Context
This phase introduces a Redis caching layer for Rulestead (Requirements STO-01, STO-02). The goal is to allow the runtime engine to pull state from a centralized Redis instance, avoiding Ecto DB bottlenecks at scale.

## Architectural Decision

**Decision:** Implement Redis exclusively as a **Read-Only Adapter for the Evaluator** (Snapshot Distribution layer).
**Status:** Approved by user during the `/gsd-discuss-phase` interview.

### Rationale & Design
Instead of making Redis a primary `Rulestead.Store` that handles both reads and mutations, we are strictly separating the control plane from the evaluation plane:

1. **Control Plane (Ecto):** All mutations (authoring, approvals, lifecycle hygiene) occur via the primary `Ecto` store within `Ecto.Multi` transactions. This ensures auditability and maintains the append-only event ledger.
2. **Distribution:** Upon a successful mutation, the system compiles the current flag state into a flattened "Snapshot" and pushes it to Redis.
3. **Evaluation Plane (ETS + Redis Fallback):** The runtime `Rulestead.RuleEngine` evaluates flags entirely from a local ETS (or `persistent_term`) cache.
4. **Hydration / Cold-Starts:** When a node starts up (or its local cache expires), it hydrates its ETS cache by fetching the Snapshot from Redis. This bypasses Ecto entirely, preventing database stampedes during pod churn or auto-scaling events.

### Ecosystem Alignment
- **Idiomatic Elixir:** Aligns perfectly with Rulestead's engineering DNA ("Don't make DB reads the default runtime evaluation path").
- **Lessons Learned:** Adopts the successful patterns of enterprise tools like LaunchDarkly and Unleash, which compile relational control-plane data into flat payloads for distribution, avoiding tight coupling between authoring and evaluation.
- **Developer Ergonomics:** Provides sub-millisecond local evaluations while keeping the operational safety and transactional integrity of the Admin UI intact.

## Next Action
Proceed to `/gsd-plan-phase 19` to break down the implementation steps for this architecture.

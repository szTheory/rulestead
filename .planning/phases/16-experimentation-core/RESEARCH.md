# Phase 16: Experimentation Core - Research

**Researched:** [2024]
**Domain:** Feature Flag Evaluation & Experimentation
**Confidence:** HIGH

## Summary

The Experimentation Core extends the existing feature flag evaluation engine to support deterministic A/B testing. We must honor the purity of the `Rulestead.Evaluator` by embedding experiments directly into the `Ruleset` JSONB payload, ensuring that ETS-based snapshot evaluation remains "zero-cost" and stateless.

**Primary recommendation:** Introduce a new `:experiment` strategy to the existing `Rulestead.Ruleset.Rule` schema with an embedded `Experiment` struct containing an immutable `iteration_salt`. Use "Compile-Time Reduction" to transform stopped experiments into standard rollout rules before they ever reach the runtime cache.

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Data Model:** Experiments will not be modeled as a standalone Ecto schema with relational joins to flags. Instead, they will be modeled as a specialized rule type (e.g., `%Rule.Experiment{}`) embedded directly within the `Ruleset` JSONB payload.
- **Sticky Assignments:** We will use an immutable "Frozen Iteration Salt" bound to the experiment's active lifecycle.
- **Lifecycle:** The runtime cache payload will only contain *active* experiments. Stopped experiments will be reduced to standard rollout rules by the control plane.

### Deferred Ideas (OUT OF SCOPE)
- **Analytics & Metrics Ingestion (Phase 17):** Storing impressions and calculating lift.
- **Experimentation UI (Phase 18):** Visualizing active experiments and their results.
- **Automatic Stop (Guardrails):** Halting an experiment automatically if an error rate spikes.
- **Multi-armed Bandits:** We will stick strictly to static A/B/n tests for this iteration.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXP-01 | Support defining formal A/B test experiments on top of existing flags, including target audience rules, traffic allocation, and holdout groups. | Ecto Embeds and modifications to `Rulestead.Ruleset.Rule` struct. |
| EXP-02 | Ensure assignment to experiment variations is deterministic, sticky for the lifetime of the experiment, and distinct from regular feature rollouts. | Introduction of `iteration_salt` decoupled from `ruleset.salt` in the `Bucket` module. |
| EXP-03 | Support explicit start and stop lifecycle events for experiments, freezing traffic allocation during active periods to maintain statistical validity. | Compile-Time Reduction pattern ensures the evaluator hot path only sees active states. |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Experiment Data Model** | API / Backend | Database | Modeled as embedded Ecto structs in `Ruleset` JSONB payload. |
| **Deterministic Bucketing** | API / Backend | — | The Evaluator uses a pure SHA-256 hash against a frozen iteration salt. |
| **Lifecycle & Compilation** | Control Plane | Database | Evaluator must remain pure; Control plane flattens stopped experiments. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `Ecto` | ~> 3.13 | Data mapping & validation | The canonical way to model embedded JSONB structs in Elixir. |
| Erlang `:crypto` | core | Hash calculation | `:crypto.hash(:sha256, payload)` provides deterministic bucket assignment without external dependencies. |

## Architecture Patterns

### System Architecture Diagram

```
[Admin UI] 
   │ (Starts Experiment)
   ▼
[Control Plane API] ─(Generates)─> [Frozen Iteration Salt]
   │
   ▼
[Ecto Ruleset Struct] (Embeds %Rule{strategy: :experiment, experiment: %{salt: "..."}})
   │
   ▼
[PostgreSQL Database] ─(Replicates via PubSub)─> [ETS Runtime Cache]
                                                       │
                                                       ▼
[Host App Client] ───(Context + Flag Key)───> [Evaluator Hot Path]
                                                       │
                                       (Buckets via Iteration Salt)
                                                       ▼
                                             [Variant / Holdout]
```

### Pattern 1: Frozen Iteration Salts
**What:** Decouple the experiment hash seed from the `Ruleset.salt`. 
**When to use:** Whenever an experiment goes "Active".
**Rationale:** In Rulestead, a standard rollout rule uses the combined `ruleset.salt` + `rollout.salt`. Because the `ruleset.salt` refreshes on every flag publish, regular rollouts are *not sticky* across flag updates. Experiments *must* be sticky. Thus, the experiment struct must carry an immutable `iteration_salt` that `Bucket.compute/5` leverages directly.

### Pattern 2: Compile-Time Reduction
**What:** Transforming complex lifecycle states into standard evaluation rules upon state transition.
**When to use:** When stopping an experiment and declaring a winner.
**Rationale:** The `Evaluator.evaluate_rule/5` hot-path should not be bloated with `if experiment.status == :stopped`. Instead, the Admin Control Plane takes the winning variant and rewrites the experiment rule into a standard `:percentage_rollout` or `:forced_value` rule in the next `Ruleset` version.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| **Cache Relational Joins** | Separate `experiments` Ecto schema and ETS cache | Embedded Struct in Ruleset JSONB | Maintaining cache synchronization across relational boundaries destroys pure evaluation speed and risks race conditions. |
| **Stateful Stickiness** | Redis or Postgres lookup tables for assignments | Deterministic hashing with `Bucket` module | A pure evaluator cannot perform IO. Stickiness must rely purely on stable hashing keys. |
| **Lifecycle branching** | `status: :stopped` checks in `Evaluator.ex` | Compile-time reduction to standard rules | Bloats the evaluation hot path unnecessarily. |

## Common Pitfalls

### Pitfall 1: Ruleset Salt Interference
**What goes wrong:** Experiment subjects reshuffle every time the flag is updated (e.g. adding a new standard rule).
**Why it happens:** Reusing `Bucket.effective_salt(active_ruleset.salt, ...)` for experiments.
**How to avoid:** Ensure the Evaluator branches logic for the `:experiment` strategy to use the embedded `iteration_salt` instead of `active_ruleset.salt`.

### Pitfall 2: Simpson's Paradox on Mid-Flight Reallocations
**What goes wrong:** An operator changes the rollout split from 50/50 to 80/20 during an active experiment, causing buckets to shift without resetting the cohort metrics.
**How to avoid:** The Control Plane must enforce that any change to traffic allocation on an *Active* experiment triggers a "new Iteration" which rolls a new `iteration_salt`, fully re-randomizing the population and resetting analytics.

## Code Examples

### Ecto Schema Addition
```elixir
# lib/rulestead/ruleset/experiment.ex
defmodule Rulestead.Ruleset.Experiment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:iteration_salt, :string) # Frozen salt for sticky bucketing
    field(:bucket_by, :string, default: "subject")
    field(:holdout_percentage, :integer, default: 5)
    # The control vs variant splits are defined in the parent Rule's variants
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:iteration_salt, :bucket_by, :holdout_percentage])
    |> validate_required([:iteration_salt, :holdout_percentage])
  end
end
```

### Evaluator Hot Path Adjustment
```elixir
# In Rulestead.Evaluator
defp build_result(rule, flag, active_ruleset, rule_key, condition_trace, rollout_trace) do
  strategy = rule[:strategy] || rule["strategy"]

  case strategy do
    # ... existing strategies ...
    strategy when strategy in [:experiment, "experiment"] ->
      # 1. Use Iteration Salt, ignore ruleset salt!
      iteration_salt = rule[:experiment][:iteration_salt] || rule["experiment"]["iteration_salt"]
      
      # 2. Compute holdout vs traffic bucketing using Bucket.compute
      # ...
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stateful assignment caches | Deterministic Hashing | Standardized by LaunchDarkly/Statsig | Guarantees O(1) pure evaluation without IO or external dependencies. |
| Heavy rule evaluators | Compile-Time Reduction | Standardized by advanced feature flagging systems | Keeps evaluation latency in the microsecond range by eliminating dead-code branches. |

## Open Questions (RESOLVED)

1. **How is the Holdout group tracked in Telemetry?**
   - RESOLVED: The holdout group should receive the `Control Variant` but the telemetry payload should tag `experiment_bucket: "holdout"` so the analytics engine excludes them from the main variation lift calculation.
   - What we know: An experiment needs a holdout group vs. variant group.
   - What's unclear: Does the holdout group receive the `flag.default_value`, the Control Variant, or bypass the rule entirely?
   - Recommendation: The holdout group should receive the `Control Variant` but the telemetry payload should tag `experiment_bucket: "holdout"` so the analytics engine excludes them from the main variation lift calculation.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXP-01 | Rule changeset validates experiment struct | unit | `mix test test/rulestead/ruleset/rule_test.exs` | ✅ |
| EXP-02 | Evaluator uses immutable `iteration_salt` for sticky bucketing | unit | `mix test test/rulestead/evaluator_test.exs` | ✅ |
| EXP-03 | Control plane compiler replaces stopped experiments | unit | `mix test test/rulestead/store/command_test.exs` | ✅ |

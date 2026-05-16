# Phase 18: Experimentation UI & Reporting - Research

**Researched:** 2024-05-17
**Domain:** Experimentation Analytics, Phoenix LiveView, SQL Aggregation
**Confidence:** HIGH

## Summary

Phase 18 implements the operator-facing interface to observe experiment results. It acts on the data models established in Phase 16 (Experiments embedded in JSON Rulesets) and Phase 17 (Analytics telemetry/events). The feature requires querying the Postgres `rulestead_analytics_events` table using Ecto aggregation functions to group by variant and count exposures and custom conversion events.

**Primary recommendation:** Build a specialized `Rulestead.Analytics.Query` module that executes Postgres aggregations (like `GROUP BY` variant) to evaluate conversion lift. Surface this directly via Admin LiveView pages `ExperimentLive.Index` and `ExperimentLive.Show`, re-using existing `FlagLive` visual paradigms and adopting `summary_grid` and `banner` components for stats and guardrail warnings.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None specified in CONTEXT.md.

### the agent's Discretion
None specified in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
None specified in CONTEXT.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ANA-03 | Calculate and expose experiment results (e.g., conversion lift, statistical significance) and guardrail metrics (e.g., unexpected error rates) in the Admin UI. | SQL Aggregation queries in `Analytics.Query`, rendered with Phoenix LiveView using `summary_grid` and `banner` components. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Raw Metric Storage | Database | — | Postgres `rulestead_analytics_events` holds individual exposure and conversion events. |
| Result Aggregation | Database | API / Backend | Aggregating variant counts via Ecto/Postgres `GROUP BY` query avoids in-memory exhaustion. |
| Stats Engine | API / Backend | — | Computing exact p-values/significance requires mathematical transformations best executed in an Elixir `Rulestead.Analytics.Stats` module over the grouped dataset. |
| Admin Interface | Frontend Server | — | Phoenix LiveView acts as the interface, pulling from `Analytics.Query` and presenting to Operators. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto.Query` | ~> 3.13 | SQL Data Aggregation | Ideal for performing aggregate operations, like count distinct actors per variant for specific event types. |
| `Phoenix.LiveView` | ~> 0.20 | Server-side rendered UI | Existing standard for Rulestead admin interfaces. |

## Architecture Patterns

### Recommended Project Structure
```
lib/rulestead_admin/live/experiment_live/
├── index.ex      # Lists active experiments (reuses FlagLive.Index patterns)
├── show.ex       # Detail view showing metrics/lift (reuses FlagLive.Show patterns)
lib/rulestead/analytics/
├── query.ex      # New Ecto queries for fetching exposures/conversions
├── stats.ex      # New module for calculating statistical significance (e.g., Z-score/P-value)
```

### Pattern 1: Database-Level Event Aggregation
**What:** Performing all metric aggregations using SQL `COUNT()` and `GROUP BY` rather than pulling `Analytics.Event` records into memory.
**When to use:** When calculating exposure and conversion counts per variant.
**Example:**
```elixir
# lib/rulestead/analytics/query.ex
def get_variant_stats(experiment_salt, target_event_name) do
  # Example abstract pattern:
  # Query exposures by parsing JSON metadata fields where event_name == flag_key
  # Query conversions where event_name == target_event_name
  # Group by variant (from metadata)
end
```

### Pattern 2: Component-Driven Admin UI
**What:** Reusing specific UI components from `OperatorComponents` for reporting layout.
**When to use:** In `rulestead_admin/live/experiment_live/show.ex`.
**Example:**
- **Warning Banners:** `<OperatorComponents.banner tone="warning" title="Guardrail Alert" body="..." />`
- **Summary Grids:** `<OperatorComponents.summary_grid items={@stats} />`

### Anti-Patterns to Avoid
- **In-Memory Filtering:** Do not call `Repo.all/1` on the events table and pipe into `Enum.filter/2`. The analytics table will have millions of rows; filtering must occur at the database layer.
- **Direct LiveView Database Calls:** Do not embed Ecto queries directly inside `ExperimentLive` modules. Expose functions via `Rulestead.Analytics` context API to maintain clear boundaries.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-memory raw event filtering | `Enum.filter` over `Repo.all()` | Ecto Queries with `GROUP BY` | Loading thousands of events into memory will exhaust RAM and crash the server. |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ANA-03 | Aggregation queries properly isolate metadata variants | integration | `mix test test/rulestead/analytics/query_test.exs` | ❌ Wave 0 |
| ANA-03 | Stats engine correctly computes significance thresholds | unit | `mix test test/rulestead/analytics/stats_test.exs` | ❌ Wave 0 |
| ANA-03 | Experiment index/show pages load without errors | integration | `mix test test/rulestead_admin/live/experiment_live_test.exs` | ❌ Wave 0 |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | yes | LiveView `on_mount` lifecycle hooks enforcing admin policies |

### Known Threat Patterns for Elixir/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure Direct Object Reference | Elevation of Privilege | Ensure environment and policy checks apply to all experiment stats queries |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| In-memory aggregation | DB-level aggregations | Phase 18 | Massive reduction in memory footprint for reporting queries. |

---
phase: 18
plan: 01
subsystem: Analytics
tags: [experimentation, statistics, ecto]
provides: [Rulestead.Analytics.Query, Rulestead.Analytics.Stats]
requires: [Rulestead.Analytics.Event, Rulestead.Repo]
key-decisions:
  - "Implemented statistical significance math internally (Abramowitz & Stegun approximation) instead of relying on external dependencies."
  - "Used Ecto GROUP BY for aggregated variant counts rather than in-memory filtering."
metrics:
  duration: 15m
  tasks: 2
  files: 4
---

# Phase 18 Plan 01: Experimentation Data Backend Summary

Implemented backend queries and statistical engine for aggregating experiment variant metrics and computing significance directly in Elixir.

## Execution Details

- Implemented `Rulestead.Analytics.Query.experiment_metrics/3` to join exposures and conversions via `Ecto.Query`, aggregating counts directly in the database.
- Implemented `Rulestead.Analytics.Stats.evaluate/2` using internal Elixir math approximations for Z-score and p-value generation without third-party statistical dependencies.

## Deviations from Plan

- **None** - the plan executed exactly as written.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: Information Disclosure | `rulestead/lib/rulestead/analytics/query.ex` | Mitigated by scoping Ecto queries strictly to `env` and `flag_key`, as defined in the plan's threat model. |


## Self-Check: PASSED

# Phase 14: OpenFeature Ecosystem Integration - Context

## Objective
Operators can adopt Rulestead without vendor lock-in by using the standard OpenFeature API for evaluation.

## Decisions

### Locked Decisions
- **D-01**: Implement an official OpenFeature Provider package (`open_feature_rulestead`) as a sibling to the core `rulestead` package. (Requirements: ECO-01)
- **D-02**: Map OpenFeature's flat map context structure into Rulestead's strictly typed `Context` struct, placing unmapped keys into the `attributes` field. (Requirements: ECO-02)
- **D-03**: Extract key diagnostic properties (`matched_rule`, `flag_version`, `cache_age_ms`) from Rulestead's `Result.t` and inject them as flattened scalar values into OpenFeature's `ResolutionDetails.flag_metadata`. (Requirements: ECO-03)
- **D-04**: Require an `environment_key` during Provider initialization, as OpenFeature doesn't mandate an environment concept by default, but Rulestead strictly requires it.

### Scope and Boundaries
- This phase focuses exclusively on the runtime evaluation layer (Provider).
- The `open_feature_rulestead` package must correctly use `Rulestead.Runtime.evaluate/3` under the hood.
- Do not attempt to map Rulestead's rich, deeply-nested `debug_trace` directly into `flag_metadata`, as OpenFeature restricts metadata values to booleans, strings, and numbers.

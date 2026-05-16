# Phase 17 Validation

This document maps the Phase 17 requirements and success criteria to specific verification steps and tasks in the phase plans to ensure Nyquist compliance.

## Requirement Mapping

| Requirement | Success Criteria | Verifying Plan | Tasks | Verification Command |
|-------------|------------------|----------------|-------|----------------------|
| **ANA-01**  | 1. The platform reliably captures and stores evaluation "impressions" when an experiment variation is served. | 17-01, 17-02 | 17-01 Task 1, 17-02 Task 2 | `mix test test/rulestead/analytics/telemetry_handler_test.exs` |
| **ANA-01**  | 3. Events and impressions can be joined accurately based on the evaluation context. | 17-01 | 17-01 Task 2 | `mix test test/rulestead/analytics/event_mapper_test.exs` |
| **ANA-02**  | 2. The `rulestead` package exposes a new API (`Rulestead.track`) for the host app to report business events. | 17-03 | 17-03 Task 1 | `mix test test/rulestead/analytics_test.exs` |
| **Wiring**  | (Implicit) The backend batcher properly writes to the database. | 17-02, 17-03 | 17-02 Task 1, 17-03 Task 2 | `mix test test/rulestead/analytics/batcher_test.exs` |

## Goal-Backward Checks

### Truths
- **Events are stored with Ecto UUIDv4 and accurate occurred_at timestamps.**
  - Verified by `mix test test/rulestead/analytics/event_mapper_test.exs` checking the mapping logic for explicit ID and timestamp assignment before insert.
- **Raw event maps can be deterministically transformed into Ecto insertable maps.**
  - Verified by the event mapper unit tests.
- **Evaluation impressions are captured natively without coupling to core logic.**
  - Verified by `mix test test/rulestead/analytics/telemetry_handler_test.exs` ensuring telemetry metadata triggers event capture.
- **Events are buffered in a non-blocking ETS table.**
  - Verified by `mix test test/rulestead/analytics/batcher_test.exs` confirming asynchronous non-blocking storage in GenServer/ETS.
- **Host apps can submit custom analytics events using Rulestead.track/3.**
  - Verified by `mix test test/rulestead/analytics_test.exs`.

### Success Criteria Verification
Run the overall phase verification with:
```bash
mix test test/rulestead/analytics_test.exs test/rulestead/analytics/batcher_test.exs test/rulestead/analytics/event_mapper_test.exs test/rulestead/analytics/telemetry_handler_test.exs
```
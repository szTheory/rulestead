# Phase 19: Redis Storage & Caching Adapter - Validation Plan

## Goal
Verify the implementation of a high-performance Redis caching layer for the Rulestead evaluation plane, ensuring strict control-plane/evaluation-plane separation and graceful degradation.

## Dimension 1: Functional Correctness (STO-01)
- [ ] **Redis Adapter Read Success:** Verify `Rulestead.Store.Redis.fetch_snapshot/1` correctly retrieves and deserializes Erlang terms from Redis.
- [ ] **Redis Adapter Read Miss:** Verify a `{:error, :not_found}` is returned when the key does not exist.
- [ ] **Redis Adapter Write Rejection:** Verify all mutation callbacks (create, update, delete) return `{:error, :invalid_command}`.
- [ ] **Redis Publisher Sync:** Verify that a mutation via `Rulestead.Store.Ecto` triggers a telemetry event that correctly pushes the new snapshot to Redis.

## Dimension 2: Reliability & Resilience (STO-02)
- [ ] **Graceful Degradation (Network Failure):** Verify that if Redis is unreachable, the evaluation engine continues using its current ETS cache.
- [ ] **Graceful Degradation (Cold Start Failure):** Verify that if Redis is down during a cold start, the engine enters a degraded state (returning default values) and retries with backoff instead of crashing.
- [ ] **Connection Recovery:** Verify that `Redix` successfully reconnects and the adapter resumes operation after a Redis outage.

## Dimension 3: Operational Safety
- [ ] **Manual Seeding:** Verify the `mix rulestead.redis.sync` task correctly populates Redis from the Postgres database.
- [ ] **Deserialization Safety:** Verify that `binary_to_term(..., [:safe])` is used, preventing atom exhaustion or RCE from poisoned Redis data.

## Dimension 4: Performance
- [ ] **Evaluation Latency:** Verify that evaluations using the Redis-hydrated ETS cache maintain sub-millisecond performance.
- [ ] **Distribution Latency:** Measure the time from Ecto mutation to Redis snapshot availability (target < 100ms).

## Verification Evidence
Execution of `mix test test/rulestead/store/redis_test.exs` and `mix test test/rulestead/redis/integration_test.exs` will provide the primary evidence for this phase.

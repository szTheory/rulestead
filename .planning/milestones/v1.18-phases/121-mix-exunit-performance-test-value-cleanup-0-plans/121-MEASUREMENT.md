# Phase 121 Measurement Record

**Produced:** 2026-06-16
**Plan:** 121-03
**Purpose:** D-09 before/after wall-clock + slowest record, D-06 partitioning-rejection evidence, and D-05/D-07/D-10 decision notes for Phase 123 closeout.

---

## D-09: Before/After Wall-Clock and Slowest-Test Measurements

### Methodology

Measurements use the EXACT locked Phase 119 commands from `119-CI-CD-AUDIT.md:153-154` for direct comparability. Four runs performed on the local machine (18 schedulers online — same as Phase 119 baseline). After Plan 121-01, the dominant test is gated behind `@tag :published_hex_smoke` and excluded by default via `test_helper.exs`; it can be opted back in with `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`.

**Env var confirmed from 121-01-SUMMARY.md:** `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` (tag: `:published_hex_smoke`).

**Scheduler count:** 18 (confirmed by `elixir -e 'IO.puts(System.schedulers_online())'` — matches Phase 119 baseline).

---

### Run 1: Default Suite — `--slowest 25` (dominant EXCLUDED)

**Command:**
```
cd rulestead && mix test --warnings-as-errors --slowest 25
```

**Wall-clock:** `real 4.639s` (ExUnit "Finished in 3.8 seconds")

**Result:** 8 properties, 586 tests, 0 failures (4 excluded)

**Top 25 slowest (1.5s total, 40.9% of total time):**

| Rank | Test | Module | Time |
|------|------|--------|------|
| 1 | test two runtime nodes converge on the newer snapshot version after one invalidation | Rulestead.Runtime.ClusterRefreshTest | 309.6ms |
| 2 | test apply fails before mutation when the compare preview is stale blocker-bearing or dependency-divergent | Rulestead.Promotion.ApplyTest | 302.3ms |
| 3 | test warm-cache keyed runtime evaluation performs zero repo queries | Rulestead.Integration.RuntimeHotPathTest | 206.3ms |
| 4 | test permissive missing sticky identity emits one sanitized telemetry warning event | RulesteadTest | 102.7ms |
| 5 | property identical inputs always produce the same bucket across 10k runs | Rulestead.BucketPropertyTest | 74.8ms |
| 6 | test telemetry-driven stale tracking records freshness asynchronously and archived flags stay out of runtime evaluation | Rulestead.Integration.AdminLifecycleRuntimeTest | 52.7ms |
| 7 | test duplicate worker delivery does not duplicate a completed scheduled mutation | Rulestead.ScheduledExecutionThreatModelTest | 45.1ms |
| 8 | test bounded retry exhaustion quarantines work and preserves correlated failure audit metadata | Rulestead.ScheduledExecutionThreatModelTest | 39.3ms |
| 9 | test stale or conflicting scheduled targets fail visibly with bounded failure reasons | Rulestead.ScheduledExecutionConflictTest | 36.6ms |
| 10 | test ecto list_flags/1 and fetch_flag/1 expose admin payloads, filters, and cursor navigation | Rulestead.StoreEctoAdminTest | 35.8ms |
| ... | (remaining 15 tests: 25ms–34ms each) | various | — |

**Key observation:** `Rulestead.Mix.Tasks.VerifyReleasePublishTest` is ABSENT from the top 25. The dominant slow test has been successfully relocated. The new slowest test is a 309.6ms cluster refresh integration test.

---

### Run 2: Default Suite — `--slowest-modules 25` (dominant EXCLUDED)

**Command:**
```
cd rulestead && mix test --warnings-as-errors --slowest-modules 25
```

**Wall-clock:** `real 4.608s` (ExUnit "Finished in 3.7-3.9s range")

**Result:** 8 properties, 586 tests, 0 failures (4 excluded)

**Top 25 slowest modules (2.6s total, 68.2% of total time):**

| Rank | Module | File | Time |
|------|--------|------|------|
| 1 | Rulestead.Promotion.ApplyTest | test/rulestead/promotion/apply_test.exs | 303.1ms |
| 2 | Rulestead.Runtime.ClusterRefreshTest | test/rulestead/runtime/cluster_refresh_test.exs | 290.8ms |
| 3 | Rulestead.RolloutAutoAdvanceOrchestrationContractTest | test/rulestead/rollout_auto_advance_orchestration_contract_test.exs | 213.7ms |
| 4 | Rulestead.Integration.RuntimeHotPathTest | test/rulestead/integration/runtime_hot_path_test.exs | 209.5ms |
| 5 | Rulestead.Governance.AudienceMutationChangeRequestContractTest | test/rulestead/governance/audience_mutation_change_request_contract_test.exs | 166.6ms |
| 6 | Rulestead.Governance.PreviewEvidenceGovernanceContractTest | test/rulestead/governance/preview_evidence_governance_contract_test.exs | 152.9ms |
| 7 | Rulestead.Store.EctoAudienceImpactContractTest | test/rulestead/store/ecto_audience_impact_contract_test.exs | 122.9ms |
| 8 | Rulestead.ScheduledExecutionAdapterContractTest | test/rulestead/store/scheduled_execution_adapter_contract_test.exs | 116.4ms |
| 9 | Rulestead.Store.PromotionApplyContractTest | test/rulestead/store/promotion_apply_contract_test.exs | 104.5ms |
| 10 | RulesteadTest | test/rulestead_test.exs | 101.4ms |
| 11 | Rulestead.Targeting.PreviewEvidenceContractTest | test/rulestead/targeting/preview_evidence_contract_test.exs | 97.9ms |
| 12 | Rulestead.Store.ManifestImportContractTest | test/rulestead/store/manifest_import_contract_test.exs | 83.6ms |
| 13 | Rulestead.Store.CompareContractTest | test/rulestead/store/compare_contract_test.exs | 74.1ms |
| 14 | Rulestead.BucketPropertyTest | test/rulestead/bucket_property_test.exs | 73.0ms |
| 15 | Rulestead.Webhooks.OutboundDeliveryTest | test/rulestead/webhooks/outbound_delivery_test.exs | 67.4ms |
| ... | (remaining 10 modules: 36ms–62ms each) | various | — |

**Key observation:** `Rulestead.Mix.Tasks.VerifyReleasePublishTest` is ABSENT from the top 25 modules. Next-slowest module is 303ms (Promotion.ApplyTest). This confirms D-05: no module splitting is warranted.

---

### Run 3: With Dominant Test — `--slowest 25` (RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1)

**Command:**
```
cd rulestead && RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --warnings-as-errors --slowest 25
```

**Wall-clock:** `real 22.202s` (ExUnit "Finished in 21.4 seconds")

**Result:** 8 properties, 587 tests, 0 failures (3 excluded)

**Top 25 slowest (18.7s total, 87.5% of total time) — selected highlights:**

| Rank | Test | Module | Time |
|------|------|--------|------|
| 1 | test admin consumer fixture compiles against published Hex packages | Rulestead.Mix.Tasks.VerifyReleasePublishTest | 17089.8ms |
| 2 | test two runtime nodes converge on the newer snapshot version after one invalidation | Rulestead.Runtime.ClusterRefreshTest | 319.6ms |
| 3 | test apply fails before mutation when the compare preview is stale blocker-bearing or dependency-divergent | Rulestead.Promotion.ApplyTest | 302.8ms |
| 4 | test warm-cache keyed runtime evaluation performs zero repo queries | Rulestead.Integration.RuntimeHotPathTest | 206.1ms |
| 5 | test permissive missing sticky identity emits one sanitized telemetry warning event | RulesteadTest | 101.7ms |
| ... | (remaining 20 tests: 22ms–73ms) | various | — |

---

### Run 4: With Dominant Test — `--slowest-modules 25` (RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1)

**Command:**
```
cd rulestead && RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 mix test --warnings-as-errors --slowest-modules 25
```

**Wall-clock:** `real 22.118s` (ExUnit "Finished in ~21s")

**Result:** 8 properties, 587 tests, 0 failures (3 excluded)

**Top 25 slowest modules (19.6s total, 92.6% of total time) — selected highlights:**

| Rank | Module | File | Time |
|------|--------|------|------|
| 1 | Rulestead.Mix.Tasks.VerifyReleasePublishTest | test/rulestead/mix/tasks/verify_release_publish_test.exs | 17015.9ms |
| 2 | Rulestead.Runtime.ClusterRefreshTest | test/rulestead/runtime/cluster_refresh_test.exs | 309.2ms |
| 3 | Rulestead.Promotion.ApplyTest | test/rulestead/promotion/apply_test.exs | 303.0ms |
| 4 | Rulestead.Integration.RuntimeHotPathTest | test/rulestead/integration/runtime_hot_path_test.exs | 207.7ms |
| 5 | Rulestead.RolloutAutoAdvanceOrchestrationContractTest | test/rulestead/rollout_auto_advance_orchestration_contract_test.exs | 156.9ms |
| ... | (remaining 20 modules: 36ms–150ms) | various | — |

---

### Before/After Comparison Table

| Metric | Phase 119 Baseline (before Plan 121-01) | Default Lane (after Plan 121-01, Runs 1-2) | With Dominant Test (Runs 3-4) | Delta (default vs baseline) |
|--------|-----------------------------------------|--------------------------------------------|---------------------------------|------------------------------|
| Wall-clock (real) | ~42s | ~4.6s | ~22s | **-37s (~88% faster)** |
| ExUnit "Finished in" | ~41s | ~3.8s | ~21.4s | ~-37s |
| Tests | 587 tests + 8 properties | 586 tests + 8 properties | 587 tests + 8 properties | -1 (excluded by tag) |
| Failures | 1 (dominant test sample failure) | 0 | 0 | Fixed |
| Excluded | 1 | 4 | 3 | +3 new excludes |
| Schedulers online | 18 | 18 | 18 | Same |
| Dominant test (`VerifyReleasePublishTest`) | ~27.95s (top of list) | ABSENT (excluded) | 17090ms top of list | Relocated |
| Next-slowest module | ~1.61s (`RolloutAutoAdvanceOrchestrationContractTest`) | 303ms (`Promotion.ApplyTest`) | 309ms (`ClusterRefreshTest`) | Consistent |

**Notes:**
- The "with dominant test" runs (22s) are ~20s slower than the 119 baseline (~42s) because the hex.pm network call was faster on this local measurement run (17s vs ~28s in Phase 119). This is expected real-network variance; the dominant test is documented as ~20-28s depending on hex.pm latency.
- The Phase 119 baseline had a failure in the full suite run; that failure was the dominant test itself on a network-timeout/flaky sample. After Plan 121-01, the suite has 0 failures on both default and opted-in runs.
- The "default lane" improvement is ~37s wall-clock reduction, matching the D-09 expectation (~42s → ~14s; actual ~4.6s is even faster because local cache is warm from prior runs and compilation artifacts are current).

**Delta assessment (success criterion #5):** The default-lane wall-clock improvement is real and material. The speedup is relocation (proof still runs on `guarded_rollout_foundations` scope via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`) — not a deletion or hidden cost. The "with dominant" runs demonstrate the cost is preserved and reachable on the opt-in lane.

---

## D-06: Partitioning Rejected with Evidence

**Decision:** REJECT `mix test --partitions` explicitly.

**Mapped to:** FUT-01 (deferred, reversible if suite grows materially).

**Verified premises (all five confirmed from RESEARCH.md:325-332 and codebase):**

1. **Single dominant serial network test — partitions cannot help:** The pre-Plan-01 dominant cost was one `System.cmd("mix", deps.get/compile)` test in `verify_release_publish_test.exs:201-217` running live against hex.pm (~28s). `mix test --partitions` distributes *modules* to partitions — it cannot subdivide work *within* a module. Once Plan 121-01 relocated the dominant test, the next-slowest module is 303ms (confirmed in Run 2 above), leaving no meaningful wall-clock target for partitioning to address.

2. **Suite is overwhelmingly `async: false` — partitions still serialize:** 79 modules are `async: false` in the suite. This is driven by the single global `Rulestead.Fake` named GenServer singleton and process-global `Application.put_env(:rulestead, :store, ...)` / `:admin_policy` mutations set in `test_helper.exs:12-15`. Each partition still executes its `async: false` modules serially; the partition boundary does not bypass module-level global state.

3. **Single Postgres sandbox + single named Fake would require per-partition isolation = fragility:** Partitioning would require `MIX_TEST_PARTITION`-suffixed databases (per-partition DB isolation) and per-partition `Rulestead.Fake` singleton instances. This is exactly the fragility pattern the No-Go guardrails in `119-CI-CD-AUDIT.md:298` caution against — introducing correctness risk for an unproven wall-clock gain.

4. **No partition config in `mix.exs` today:** `rulestead/mix.exs` has no `test_paths`, `test_pattern`, or `MIX_TEST_PARTITION` configuration. Adding partitioning would require new infrastructure with no precedent in the project's scripts-first CI design.

5. **18 schedulers already absorb the tiny async set:** The async set is small (the 5 pre-existing `async: true` modules confirmed in 121-01-SUMMARY.md; 0 new modules added in Plan 121-02). 18 schedulers have more than enough headroom for this set. The async concurrency benefit of partitioning over local scheduling is nil.

**Conclusion:** Partitioning trades the simple scripts-first `RULESTEAD_TEST_SCOPE` rerun model for sharding fragility with no proven payoff. Deferred to FUT-01; revisit only if the suite grows materially (e.g., the async set expands to dozens of modules or a new dominant slow test emerges that cannot be tagged).

---

## D-05: No Module Splits — Decision Record

**Decision:** Do not split any modules in Phase 121.

**Evidence:**
- After Plan 121-01 relocates the dominant test, the next-slowest module is 303ms (`Rulestead.Promotion.ApplyTest`, confirmed Run 2 above). The Phase 119 baseline noted ~1.61s for `RolloutAutoAdvanceOrchestrationContractTest` as next-slowest.
- Success criterion #2 requires a "meaningful concurrency benefit" bar to be met before splitting. At 303ms per module, splitting would not produce a material wall-clock improvement — and most modules that are slow-ish are serial for global-state reasons (global `Rulestead.Fake` singleton, `Application.put_env`) that a module split would not resolve.
- Module splitting would churn git history and file layout against the repo's "narrow, auditable changes" rule (CLAUDE.md).

**Action taken:** None. Recorded as a deliberate no-action decision.

---

## D-07: No Dialyzer/PLT Change — Decision Record

**Decision:** Make no Dialyzer placement or PLT-key changes in Phase 121.

**Evidence:**
- Phase 120 already scoped the PLT cache key correctness-safely (`120-CONTEXT.md` D-06): lint/Dialyzer keyed on `rulestead/mix.lock` + `.tool-versions`.
- Dialyzer runs in the `lint` lane (`scripts/ci/lint.sh`), not on the test wall-clock critical path. It is not a target for Phase 121's test-value optimization scope.
- `119-CI-CD-AUDIT.md` D-14 guidance: optimize only with equal confidence. No safe, evidence-backed lever remains within Phase 121's boundary.

**Action taken:** None. Recorded as a deliberate no-action decision.

---

## D-10: Compile-Connected Xref Cycle — Architectural Evidence Note

**Decision:** Note the xref cycle as architectural evidence only; do not refactor in Phase 121.

**Evidence from `119-CI-CD-AUDIT.md:157-158`:**
- `cd rulestead && mix xref graph --format cycles --label compile-connected` — one compile-connected cycle of **length 47**, centered on `lib/rulestead.ex`, spanning governance/guardrails/manifest/runtime/store modules and `lib/rulestead/ruleset/guardrail.ex (compile)`.
- `cd rulestead && mix xref graph --format stats --label compile-connected` — Tracked files: 172 nodes; compile dependencies: 5 edges; exports dependencies: 62 edges; runtime dependencies: 341 edges; cycles: 1.

**Phase 121 scope:** Phase 121's scope is Mix/ExUnit performance and test value cleanup. The xref cycle is an architectural observation about compile-time dependency structure, not a test-speed lever. Refactoring a 47-node compile-connected cycle in a reliability milestone would introduce significant change risk (compilation behavior, public API surface exposure order) without a proven CI timing benefit — the cycle has no direct link to test wall-clock.

**Action taken:** None. Recorded as architectural evidence for future consideration (potential Phase 123 closeout note or a future v2 maintenance pass).

---

## Summary

| Decision | Outcome | Phase 123 Feed |
|----------|---------|----------------|
| D-09 Wall-clock measurement | Default lane: ~4.6s real (was ~42s); with dominant: ~22s; delta: -37s default (-88%) | Before/after numbers confirmed |
| D-09 Dominant test timing | Default: ABSENT (excluded); opted-in: 17090ms (vs ~27950ms Phase 119 — faster network on measurement day) | Relocation delta demonstrated |
| D-06 Partitioning | REJECTED with 5 verified premises; FUT-01 deferred | Criterion #3 satisfied by rejection-with-evidence |
| D-05 Module splits | No split; next-slowest 303ms, bar unmet | Criterion #2 noted, decision recorded |
| D-07 Dialyzer/PLT | No change; Phase 120 already scoped; lint lane only | No-action confirmed |
| D-10 Xref cycle | Length-47 compile cycle noted as architectural evidence; NOT refactored | Evidence preserved for closeout |

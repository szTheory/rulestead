# Phase 123 CI/CD Closeout — v1.18 CI/CD Reliability Milestone

**Produced:** 2026-06-17
**Purpose:** Milestone counterpart to `119-CI-CD-AUDIT.md`. A maintainer can diff the baseline ledger (`119-CI-CD-AUDIT.md`) against this closeout ledger to confirm the delta is exactly what the four optimization phases delivered.
**Before/after source:** All before/after deltas are forwarded from committed Phase 121 measurements. See `121-MEASUREMENT.md` (methodology at :12, before/after table at :136-154, relocation framing at :154, Phase 123 Feed at :222-229). No new measurements were taken for closeout per D-03: a fresh re-measurement would introduce a third, un-baselined sample with different cache warmth and hex.pm latency variance.

Evidence tags (mirroring `119-CI-CD-AUDIT.md:7-12`):
- `[VERIFIED: path]` — claim backed by a repo file or local command named in the tag.
- `[CITED: path:lines]` — claim backed by a committed planning document with line reference.
- `[ASSUMED: reason]` — explicit assumption where live evidence was unavailable.

---

## PR Wall-Clock (Before/After)

**CIDX-10 field:** PR wall-clock before/after impact.

### Endpoints

| Lane | Phase 119 Baseline (before Plan 121-01) | Default Lane (after Plan 121-01) | Delta |
|------|-----------------------------------------|----------------------------------|-------|
| Default suite (`mix test --warnings-as-errors`) | ~42s wall-clock | ~4.6s wall-clock | **-37s (~88% faster)** |
| Suite with dominant test opted in (`RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`) | ~42s (dominated by ~27.95s hex.pm call) | ~22s (dominant test: ~17090ms — faster hex.pm network on measurement day) | Not the primary improvement target |

[CITED: 121-MEASUREMENT.md:136-154]

### Measurement Corpus

- **Machine:** local development machine, 18 schedulers online (confirmed: `elixir -e 'IO.puts(System.schedulers_online())'`). [CITED: 121-MEASUREMENT.md:12]
- **Runs:** 4 total (2 default, 2 opted-in), using the EXACT locked Phase 119 commands from `119-CI-CD-AUDIT.md:153-154` for direct comparability. [CITED: 121-MEASUREMENT.md:12]
- **Commands:** `cd rulestead && mix test --warnings-as-errors --slowest 25` and `cd rulestead && mix test --warnings-as-errors --slowest-modules 25`. [CITED: 121-MEASUREMENT.md:12-17]

### Factor Delta

Default-lane wall-clock: **-37s / ~88% faster** (~42s baseline → ~4.6s default post-121). [CITED: 121-MEASUREMENT.md:136-154]

### Methodology Caveat

The "with dominant test" opt-in run shows ~22s vs ~42s baseline. This ~20s gap versus the ~37s default-lane gain reflects real-network variance: hex.pm latency was ~17s on the Phase 121 measurement day vs ~28s in the Phase 119 sample. The dominant test cost is documented as ~20-28s depending on hex.pm latency. [CITED: 121-MEASUREMENT.md:150]

### Relocation-Not-Deletion Framing

The speedup is **relocation, not deletion**. The dominant test (`"admin consumer fixture compiles against published Hex packages"` in `Rulestead.Mix.Tasks.VerifyReleasePublishTest`) was moved behind `@tag :published_hex_smoke` and excluded from the default suite via `test_helper.exs`. The proof still runs on the `guarded_rollout_foundations` scope via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`. No coverage was removed. [CITED: 121-MEASUREMENT.md:154]

---

## p95 Target

**CIDX-10 field:** p95 target if available.

p95 target **unavailable from current sample**.

Verbatim reason from `119-CI-CD-AUDIT.md:109`: "The 20-run sample includes `pull_request`, `push`, and `workflow_dispatch` runs across dependabot, main, release branch, and feature branch contexts. The sample is enough to identify the current critical path, but not enough to claim a defensible p95 across event types and branch classes." [CITED: 119-CI-CD-AUDIT.md:109]

### Representative Critical-Path Wall-Clocks (instead of p95)

The following three runs are the verified representative sample: [CITED: 119-CI-CD-AUDIT.md:103-107]

| run ID | event | branch | conclusion | wall-clock | longest job |
|--------|-------|--------|------------|------------|-------------|
| `27542317576` | `pull_request` | `dependabot/hex/rulestead_admin/a11y_audit-0.4.0` | success | 5m18s | `test (1.17.3 / OTP 26.2.5)` at 4m43s |
| `27471122598` | `push` | `main` | success | 5m04s | `test (1.17.3 / OTP 26.2.5)` at 4m38s |
| `27471186416` | `workflow_dispatch` | `release-please--branches--main` | failure | 4m46s | `test (1.19.2 / OTP 28.4.3)` at 4m03s |

[CITED: 119-CI-CD-AUDIT.md:103-107]

Note: These baseline wall-clocks reflect the Phase 119 CI state (before Phase 120/121/122 changes). The GitHub Actions critical path includes runner allocation, cache restore, compilation, and the `release_gate` aggregation overhead that local `mix test` timing does not capture. Post-Phase-121, local default-lane time is ~4.6s; the CI wall-clock will differ by runner scheduling and cache hit posture.

---

## Cache Hit Rate

**CIDX-10 field:** Cache hit rate.

Cache hit rate is recorded **qualitatively** — GitHub Actions surfaces no numeric cache hit rate, and `scripts/ci/report_cache_hit.sh` emits a qualitative exact-hit vs miss/partial signal only. No percentage is synthesized. [CITED: scripts/ci/report_cache_hit.sh]

### Cache Posture (Post-Phase-120)

**Signal reported by `scripts/ci/report_cache_hit.sh`:** [CITED: scripts/ci/report_cache_hit.sh]
- `"Cache: exact hit"` — when `actions/cache` `cache-hit` output is `"true"` (exact key match).
- `"Cache: miss or restore-key (partial) hit"` — when `cache-hit` is `""` (restore-key partial hit) or `"false"` (miss).

**Post-Phase-120 key posture:** The cross-lane `${{ runner.os }}-mix-` restore-key fallback was removed from `test`, `adopter-contract`, `openfeature-companion`, and `mounted-proof` jobs. Keys are now matrix-scoped per lane (e.g., `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-${{ hashFiles('**/mix.lock') }}`), eliminating the risk of cross-OTP/Elixir build cache contamination. [CITED: .planning/phases/120-workflow-topology-cache-hygiene-0-plans/]

The qualitative posture is: contributors hitting a warm local cache after a prior run see exact-hit behavior; cold CI runners with a lockfile change see miss behavior; restore-key partial hits fill the gap without cross-lane contamination.

---

## Top Slow Tests

**CIDX-10 field:** Top slow tests (post-Phase-121 default lane).

### Default Lane (RULESTEAD_RUN_PUBLISHED_HEX_SMOKE not set)

The slowest test in the default lane is now `Rulestead.Runtime.ClusterRefreshTest` at **309.6ms** (`test two runtime nodes converge on the newer snapshot version after one invalidation`). [CITED: 121-MEASUREMENT.md:136-148]

Top 5 slowest tests (default lane): [CITED: 121-MEASUREMENT.md:136-148]

| Rank | Test | Module | Time |
|------|------|--------|------|
| 1 | test two runtime nodes converge on the newer snapshot version after one invalidation | Rulestead.Runtime.ClusterRefreshTest | 309.6ms |
| 2 | test apply fails before mutation when the compare preview is stale blocker-bearing or dependency-divergent | Rulestead.Promotion.ApplyTest | 302.3ms |
| 3 | test warm-cache keyed runtime evaluation performs zero repo queries | Rulestead.Integration.RuntimeHotPathTest | 206.3ms |
| 4 | test permissive missing sticky identity emits one sanitized telemetry warning event | RulesteadTest | 102.7ms |
| 5 | property identical inputs always produce the same bucket across 10k runs | Rulestead.BucketPropertyTest | 74.8ms |

Next-slowest module: **303ms** (`Rulestead.Promotion.ApplyTest`). No module splitting is warranted at this level — the bar for meaningful concurrency benefit is unmet. [CITED: 121-MEASUREMENT.md:136-154]

### Dominant Test (Opt-In Lane)

The relocated dominant test (`"admin consumer fixture compiles against published Hex packages"` in `Rulestead.Mix.Tasks.VerifyReleasePublishTest`) is reachable via `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1` at **~17090ms** depending on hex.pm latency (was ~27.95s in Phase 119 baseline — faster network on Phase 121 measurement day). [CITED: 121-MEASUREMENT.md:136-154]

### Phase 123 Feed Summary

| Decision | Outcome | Phase 123 Feed |
|----------|---------|----------------|
| D-09 Wall-clock measurement | Default lane: ~4.6s real (was ~42s); with dominant: ~22s; delta: -37s default (-88%) | Before/after numbers confirmed |
| D-09 Dominant test timing | Default: ABSENT (excluded); opted-in: ~17090ms (vs ~27950ms Phase 119 — faster network on measurement day) | Relocation delta demonstrated |
| D-06 Partitioning | REJECTED with 5 verified premises; FUT-01 deferred | Criterion satisfied by rejection-with-evidence |
| D-05 Module splits | No split; next-slowest 303ms, bar unmet | Decision recorded |

[CITED: 121-MEASUREMENT.md:222-229]

---

## Flake Notes

**CIDX-10 field:** Flake notes.

### Playwright Trace/Retry Mismatch — Fixed (Phase 122)

The one known determinism issue entering the milestone was a Playwright config mismatch: `examples/demo/frontend/playwright.config.ts` had `trace: "on-first-retry"` with `retries: 0`. With zero retries, traces configured for first retry were never produced. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md]

**Fix (Phase 122 Plan 01, D-01/D-02):** Changed to `retain-on-failure` for trace and video, `only-on-failure` for screenshots. `retries: 0` is unchanged. Traces and artifacts now fire on real failures only, with no blind retries added. HTML report directory is created on failure and uploadable from CI. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md]

All 15 Playwright specs are KEEP. No spec was demoted: 10 functional journeys + 5 visual-evidence matrices, no two covering the same assertion surface, no CIDX-05 demotion evidence. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md]

### Compile-Connected Xref Cycle — Architectural Evidence Only

`cd rulestead && mix xref graph --format cycles --label compile-connected` returns one compile-connected cycle of length 47, centered on `lib/rulestead.ex`, spanning governance/guardrails/manifest/runtime/store modules and `lib/rulestead/ruleset/guardrail.ex (compile)`. [CITED: 119-CI-CD-AUDIT.md:157]

This is architectural evidence, not a flake. It was not refactored in v1.18. See Residual Risks below for FUT-01 disposition. [CITED: 121-MEASUREMENT.md:210-216]

### No Remaining Known Flakes

No other flaky behavior was identified in the Phase 119–122 audit. The full-suite sample failure recorded in Phase 119 (`Rulestead.Mix.Tasks.VerifyReleasePublishTest` network timeout) was resolved by the Phase 121 relocation. [CITED: 121-MEASUREMENT.md:136-154]

---

## Residual Risks

**CIDX-10 field:** Residual risks.

### D-14 Anti-Drift Guard for CI Failure Triage Table

The D-14 anti-drift guard (asserting that every `ci.yml` job id and every `RULESTEAD_TEST_SCOPE` rerun command in `MAINTAINING.md`'s CI Failure Triage section matches the rerun catalog) is included in Wave 2 (plan 123-02) via a `release_contract_test.exs` extension. If that guard is ultimately scoped down or deferred by the planner, record as a residual risk: the triage table could silently rot as `ci.yml` job ids or scope names change. [ASSUMED: D-14 disposition pending 123-02 execution]

### FUT-01 — Test Partitioning

`mix test --partitions` was explicitly rejected with 5 verified premises in Phase 121. The decision is recorded as FUT-01: revisit only if the suite grows materially (e.g., async set expands to dozens of modules, or a new dominant slow test emerges that cannot be tagged). No artifact exists to revert. [CITED: 121-MEASUREMENT.md:176]

### Compile-Connected Xref Cycle (Length 47)

The length-47 compile-connected cycle centered on `lib/rulestead.ex` is architectural evidence recorded in Phase 119 and Phase 121. It was not refactored in v1.18 (refactoring a 47-node cycle in a reliability milestone would introduce significant change risk). A future v2 maintenance pass may address it. [CITED: 119-CI-CD-AUDIT.md:157; CITED: 121-MEASUREMENT.md:210-216]

### Phase 122 Honest-Non-Execution Items

The following proof bars were not re-run for this docs diff (D-16/D-17):

- **Mounted/OpenFeature companion proofs** (`local.sh:44-47`): no signal for a docs diff. Cited as skipped-by-design. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md:89-91]
- **DB-backed product suites**: not required for planning-artifact changes. Cited as skipped-by-design.
- **`publish-hex` / `verify-published-release` / `gh api` branch-protection writes**: irreversible, gated, no version change in Phase 123; live hex.pm network and branch-protection 404 reconciled by docs only. Cited as not re-runnable. [ASSUMED: irreversible-release steps out of scope per D-17]

---

## Rollback Notes

**CIDX-10 field:** Rollback notes. Modeled on `119-CI-CD-AUDIT.md:284-309` but per-decision and git-revert-granular (D-06).

One entry per Phase 120/121/122 change:

---

### Phase 120: Wire `openfeature-companion` into `release_gate.needs`

**What changed:** `openfeature-companion` job was added to `release_gate.needs` in `ci.yml`. Previously it was path-gated and absent from the aggregate gate.

**Revert handle:** Revert the `ci.yml` commit that added `openfeature-companion` to `release_gate.needs`. [CITED: .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-01-SUMMARY.md]

**Trust boundary:** Reverting this removes `openfeature-companion` from the aggregate gate. After rollback, confirm the required-check posture in `MAINTAINING.md` and the live GitHub branch-protection state — the companion proof will no longer block merge failures, weakening the release gate. Do not revert silently.

**Footgun:** If the companion job was failing before the wire, reverting hides that signal entirely. Confirm the companion job is green before deciding to revert rather than fix.

---

### Phase 120: Remove Cross-Lane `${{ runner.os }}-mix-` Restore-Key Fallback

**What changed:** The broad `${{ runner.os }}-mix-` restore-key fallback was removed from `test`, `adopter-contract`, `openfeature-companion`, and `mounted-proof` job cache configs in `ci.yml`. Keys are now matrix-scoped per lane. [CITED: .planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-02-SUMMARY.md]

**Revert handle:** Revert the `ci.yml` commit that removed the cross-lane restore keys.

**Trust boundary:** Cache correctness. The fallback was removed because it could produce cross-OTP/Elixir build cache contamination.

**Footgun:** A cache-scope change reverted without a cache-key bump leaves poisoned OTP-incompatible `_build` entries in the GitHub Actions cache. **Always bump the key prefix after reverting cache scope changes** — otherwise runners may restore incompatible build artifacts silently, causing subtle compile or runtime failures.

---

### Phase 120: Path-Filter Rollback Risk (Documented, Not Applied)

**What changed:** Phase 120 documented the path-filter pending-check trap per `119-CI-CD-AUDIT.md:88,302` without applying workflow-level path filters to required checks.

**Revert handle:** No workflow path-filter changes were made in Phase 120 for required checks. This entry exists as a forward reminder: if a future phase adds path filters to any required PR check workflow, reverting those filters can leave a required check stuck pending on PRs that don't touch the filtered paths. [CITED: 119-CI-CD-AUDIT.md:302]

**Trust boundary:** Required-check pending trap blocks merges invisibly. See MAINTAINING.md branch-protection section.

---

### Phase 121: Relocate Dominant Published-Hex Smoke Test

**What changed:** `"admin consumer fixture compiles against published Hex packages"` in `Rulestead.Mix.Tasks.VerifyReleasePublishTest` was tagged `@tag :published_hex_smoke` and excluded from the default suite via `test_helper.exs`. [CITED: 121-MEASUREMENT.md:13]

**Revert handle:** Revert the Plan 121-01 commit that added `@tag :published_hex_smoke` to `verify_release_publish_test.exs` and the exclude clause to `test_helper.exs`. This is **reversible-by-design** per `121-MEASUREMENT.md:13` — no proof loss on rollback; the test resumes running by default after revert.

**Trust boundary:** After revert, the full `~42s` default-suite wall-clock returns. The `guarded_rollout_foundations` CI scope opt-in (`RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1`) disappears; test will run unconditionally again.

**Footgun:** None beyond the wall-clock cost. The revert is safe because the proof was not deleted — only tagged. Reversing the tag restores the exact pre-Phase-121 behavior. [CITED: 121-MEASUREMENT.md:154]

---

### Phase 121: FUT-01 Partitioning Rejection

**What changed:** No artifact. The decision to reject `mix test --partitions` was recorded as a deliberate no-action decision (FUT-01). [CITED: 121-MEASUREMENT.md:176]

**Revert handle:** No artifact to revert. FUT-01 is a recorded decision, not a code change.

**Trust boundary:** Not applicable (no behavioral change).

---

### Phase 122: Fix Playwright Config Trace/Retry Mismatch

**What changed:** `examples/demo/frontend/playwright.config.ts` changed `trace: "on-first-retry"` to `retain-on-failure`. Video was set to `retain-on-failure`; screenshot to `only-on-failure`. `retries: 0` was unchanged. `scripts/demo/verify.sh` failure block and CI `upload-artifact` step were also added. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md]

**Revert handle:** Revert the Plan 122-01 commit that updated `playwright.config.ts`, `scripts/demo/verify.sh`, and `.github/workflows/ci.yml`. Specifically: restore `trace: "on-first-retry"` in `playwright.config.ts`.

**Trust boundary:** After revert, traces will again not be produced with `retries: 0` (the original mismatch returns). The CI upload-artifact step disappears; failed Playwright runs will produce no downloadable report in GitHub Actions. The verify.sh failure block output (URLs, artifact paths, rerun commands) also disappears.

**Footgun:** The fix is safe to preserve even if the companion proofs are rolled back — it makes failure evidence more accessible, not less. Reverting it silently removes failure ergonomics. If reverting for other reasons, explicitly confirm you want to lose the trace artifacts and the CI failure report upload. [CITED: .planning/phases/122-browser-demo-integration-determinism-0-plans/122-VERIFICATION.md]

---

*Cross-references: `119-CI-CD-AUDIT.md` (baseline ledger), `121-MEASUREMENT.md` (committed before/after deltas), `122-VERIFICATION.md` (Phase 122 determinism evidence).*

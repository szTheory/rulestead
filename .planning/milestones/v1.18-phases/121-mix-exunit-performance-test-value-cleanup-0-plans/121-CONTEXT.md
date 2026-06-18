# Phase 121: Mix/ExUnit Performance + Test Value Cleanup - Context

**Gathered:** 2026-06-16 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 121 improves core Elixir (`rulestead/`) test and runtime efficiency without hiding risk or making local reproduction harder. It turns the Phase 119 Mix/ExUnit/Dialyzer/xref diagnostics (`119-CI-CD-AUDIT.md`) and the Phase 121 handoff notes into narrow, evidence-gated changes to ExUnit `async:` flags, the treatment of the single dominant slow test, and the before/after measurement record — while preserving `scripts/ci/test.sh` understandability and its `RULESTEAD_TEST_SCOPE` failure microcopy.

This phase does NOT change: workflow topology / cache keys / required checks (Phase 120, done), browser/Playwright/demo/integration determinism (Phase 122), contributor-command and closeout docs (Phase 123), product runtime APIs, schemas, product UI, brand, or the design system, and `rulestead_admin` publish posture. It does not delete or demote any test or check solely because it is slow, and it does not apply async/sharding without evidence about global/shared-state hazards (No-Go guardrails, `119-CI-CD-AUDIT.md:284-299`).

</domain>

<decisions>
## Implementation Decisions

### Async Marking Strategy & Safety Methodology
- **D-01 (Confirmed):** Apply an evidence-gated, allowlist-style flip of `async: false → async: true`, NOT a broad sweep. A module qualifies only when it (a) uses `Rulestead.RepoCase` AND (b) contains zero global-state hazards: no global `Rulestead.Fake` singleton use, no `:rulestead, :store`/`:admin_policy` (or other) app-env mutation, no named-process/ETS singletons, no telemetry handler attach, no log capture, no `System.cmd`, no filesystem writes. Evidence: `test/test_helper.exs:12-15` sets process-global app env + single named `Rulestead.Fake`; `test/support/repo_case.ex:18-28` already does correct per-process sandbox isolation on the async path; `test/support/store_contract_case.ex:21-41` mutates store app env in setup (inherently serial). Audit success criterion #1.
- **D-02 (Confirmed):** Expect a SMALL net-new-async count (plausibly 0–3 modules), and treat that as a success, not a shortfall. Of 78 `async: false` modules, ~53 use bare `use ExUnit.Case` (global Fake), ~52 mutate app env, ~46 touch `Fake.Control`, ~9 touch telemetry; the safe "RepoCase AND hazard-free" intersection is tiny. Known correctly-serial modules that must NOT be flipped include `oban/stale_flag_worker_test.exs` (named `Rulestead.Telemetry.Cache` + `:ets`), `analytics/batcher_test.exs` (terminates the supervised global `Analytics.Batcher`, shares `:rulestead_analytics_batcher` ETS), and `webhooks/inbound_http_test.exs`. Each proposed flip must cite the specific hazard-absence evidence; when in doubt, leave serial (correctness-first).

### The Dominant Slow Test (VerifyReleasePublishTest)
- **D-03 (Decided — opt-in tag; maintainer-confirmed):** Treat `"admin consumer fixture compiles against published Hex packages"` (`test/rulestead/mix/tasks/verify_release_publish_test.exs:201-217`) as the only meaningful wall-clock lever and gate it behind an opt-in tag/env, mirroring the existing `install_integration` exclusion in `test_helper.exs:1-6`. The default `mix test` / `test`-matrix lane drops ~20–28s (~42s → ~14s expected). The published-Hex installability proof is PRESERVED — it must still run under a named release/adopter scope (`post_ga_band_closure` and/or `adopter`) in `scripts/ci/test.sh`, never deleted (No-Go `119-CI-CD-AUDIT.md:293/298`).
- **D-04 (Decided — no blind retry):** Do NOT wrap the test's live-hex.pm `System.cmd("mix", deps.get/compile)` (`verify_release_publish_test.exs:208-210`, pinned `@published_smoke_version "0.1.4"`) in a blind retry to mask the sample flake. The variance is real-network latency, not a logic bug; the opt-in tag already removes it from the hot default loop, and the proof remains on the release-trust path. (Hiding flakes behind blind retries is forbidden — same guardrail family the milestone enforces.) The planner may set an explicit, documented timeout if it improves failure clarity, but not silent retries.

### Module Splitting
- **D-05 (Confirmed):** Split no modules in Phase 121. Once the dominant test is set aside, the next-slowest module is ~1.6s and the rest are fast (`119-CI-CD-AUDIT.md:154`); success criterion #2's "meaningful concurrency benefit" bar is not met, and most slow-ish modules are serial for global-state reasons a split would not fix. Splitting would churn files/history against the repo's "narrow, auditable changes" rule.

### Test Partitioning
- **D-06 (Decided — REJECT with evidence):** Explicitly reject `mix test --partitions` (success criterion #3 satisfied by rejection-with-evidence). Reasons: (1) partitions cannot subdivide the single serial network test that dominates wall-clock; (2) the suite is largely `async: false` due to the global `Rulestead.Fake` singleton + app-env mutation, so each partition still serializes its async:false modules, and the single Postgres sandbox + single named Fake would require per-partition DB isolation (`MIX_TEST_PARTITION`-suffixed DBs) = fragility the No-Go guardrails caution against; (3) `mix.exs` has no partition config today and 18 schedulers already absorb the tiny async set. Partitioning would trade the simple scripts-first `RULESTEAD_TEST_SCOPE` rerun model for sharding fragility with no proven payoff. Reversible later if the suite grows materially.

### Dialyzer / PLT
- **D-07 (Confirmed — no change):** Make no Dialyzer placement or PLT-key changes. Phase 120 already scoped the PLT cache key correctness-safely (`120-CONTEXT.md` D-06: lint/Dialyzer keyed on `rulestead/mix.lock` + `.tool-versions`); Dialyzer runs in the `lint` lane (`scripts/ci/lint.sh`), not on the test wall-clock critical path; audit D-14 / `119-CI-CD-AUDIT.md:190` says optimize only with equal confidence. No safe, evidence-backed lever remains within Phase 121's test-value boundary.

### test.sh Value & Failure-Category Preservation
- **D-08 (Confirmed):** Keep `scripts/ci/test.sh` structurally as-is — preserve the `case "${TEST_SCOPE}"` dispatch and every scope's failure microcopy (category + boundary + exact `Rerun:` command + matrix-aware rerun output). Any async tagging must not change the scope contract or break the `release_gate` fan-in Phase 120 stabilized. The dominant-test opt-in (D-03) must keep its proof reachable via a named scope with intact microcopy. Audit classifies all scopes `keep` (`119-CI-CD-AUDIT.md:196-205`); success criterion #4.

### Before/After Measurement
- **D-09 (Confirmed):** Record before/after using the exact Phase 119 commands for comparability: `cd rulestead && mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25`, capturing `real` wall-clock and the slowest-test line, run both with and without the dominant test included. Baseline to beat: ~42s real, 587 tests + 8 properties, dominant ~27.95s; 18 schedulers online (`119-CI-CD-AUDIT.md:144-154`). Expected post-change default ~14s with the dominant test's time relocated to its opt-in/release scope. Success criterion #5; feeds Phase 123 closeout.

### Compile-Connected Xref Cycle
- **D-10 (Confirmed — note, do not refactor):** Treat the length-47 compile-connected xref cycle centered on `lib/rulestead.ex` as architectural evidence only, not an automatic refactor request (`119-CI-CD-AUDIT.md:157,324`). No Phase 121 refactor of it; record it as a noted observation for future consideration.

### Planner Discretion
- The planner may choose the exact tag name/env var for D-03 (consistent with the `install_integration` precedent), the exact module list for D-01/D-02 (each with hazard-absence evidence), the precise `scripts/ci/test.sh` scope wiring that keeps the published-Hex proof reachable, and the wording of before/after notes — provided every decision above is honored.
- The planner may sequence the work into one or more plans as long as the `release_gate` aggregate (and every named proof scope) stays green at each commit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Ground Truth
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` — Mix/ExUnit/Dialyzer/xref diagnostics (lines ~141-163), Test/Check Classification Matrix (165-205), Rerun Command Catalog (207-224), No-Go guardrails (284-309), Phase 121 handoff notes (320-324). Decision ledger.
- `.planning/phases/120-workflow-topology-cache-hygiene-0-plans/120-CONTEXT.md` — what Phase 120 did/deferred (PLT key scoping D-06; ExUnit async/sharding explicitly deferred to 121).
- `.planning/ROADMAP.md` — Phase 121 success criteria + 120/122/123 scope boundary.
- `.planning/REQUIREMENTS.md` — CIDX-06 and out-of-scope constraints.
- `.planning/STATE.md` — strict 119→120→121→122→123 sequence and release-trust boundary.

### Prompt Grounding
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, proof-scope contracts, release-trust posture.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir OSS test/workflow baseline (ExUnit async, partitioning norms).

### Code Surfaces (edit targets / cited)
- `rulestead/test/test_helper.exs` — global app env + named Fake + sandbox manual mode; the `install_integration` opt-in precedent for D-03.
- `rulestead/test/support/repo_case.ex` — correct per-process async sandbox path (enables D-01 flips).
- `rulestead/test/support/store_contract_case.ex` — store app-env mutation (serial hazard reference).
- `rulestead/lib/rulestead/fake/control.ex`, `rulestead/lib/rulestead/fake.ex` — the global singleton store driving most `async: false`.
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` — the dominant slow test (D-03/D-04 target).
- `rulestead/test/rulestead/oban/stale_flag_worker_test.exs`, `rulestead/test/rulestead/analytics/batcher_test.exs`, `rulestead/test/rulestead/webhooks/inbound_http_test.exs` — correctly-serial, do-not-flip references.
- `scripts/ci/test.sh` — scope dispatcher + failure microcopy (D-08; keep proof reachable for D-03).
- `rulestead/mix.exs` — no partition config today (D-06 rejection basis); aliases/test env.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test_helper.exs:1-8` already implements the exact opt-in-integration pattern D-03 needs (`RULESTEAD_RUN_INSTALL_INTEGRATION` env → `exclude: [install_integration: true]`). Mirror it for the published-Hex test.
- `Rulestead.RepoCase` (`repo_case.ex:18-28`) already does correct async sandbox isolation (no `{:shared, self()}` on the async path); 5 modules already run `async: true` on it cleanly — D-01 just widens this narrow, proven path.
- `scripts/ci/test.sh` already has per-scope failure microcopy and matrix-aware rerun output — D-03's relocated proof reuses an existing named scope rather than inventing infrastructure.

### Established Patterns
- Most `async: false` is caused by the global `Rulestead.Fake` named GenServer + `Application.put_env(:rulestead, :store, ...)` — a single global mutable store. This is the dominant async blocker, not Ecto (the sandbox supports async correctly).
- Scripts-first CI: `RULESTEAD_TEST_SCOPE` is the contributor/maintainer rerun abstraction; keep it intact.
- Correctness-first conservatism: prefer a known-good serial test over a possibly-flaky concurrent one; cite hazard-absence evidence per flip.

### Integration Points
- D-03's opt-in tag must keep the published-Hex proof reachable under a named `scripts/ci/test.sh` scope so the `release_gate` aggregate (Phase 120 D-01/D-03) and the release-trust bar stay intact.
- Before/after measurement (D-09) reuses Phase 119's locked commands so the delta is directly comparable and feeds Phase 123 closeout metrics.

</code_context>

<specifics>
## Specific Ideas

- Maintainer-confirmed during discussion: the dominant published-Hex test moves behind an opt-in tag (default suite fast), with the proof preserved on the release/adopter path and NO blind retry (network jitter is not a logic bug). This was the one genuinely high-impact, reversible-hard call; everything else was locked from codebase + audit evidence.
- The phase is deliberately small and conservative: a 0–3 module async widening, one test relocation, an evidenced partitioning rejection, and a measurement record — not a test-suite restructuring.

</specifics>

<deferred>
## Deferred Ideas

- Refactoring the length-47 compile-connected xref cycle centered on `lib/rulestead.ex` — noted as architectural evidence, out of scope for 121.
- ExUnit `mix test --partitions` / sharding — rejected for this milestone (D-06); reconsider only if the suite grows materially.
- Module splitting — none warranted now (D-05); revisit if a module becomes genuinely oversized.
- Dialyzer placement / further PLT tuning — no safe lever remains (D-07); future milestone if evidence appears.
- Browser/Playwright/demo/integration determinism — Phase 122.
- Contributor-command docs, closeout metrics, rollback notes — Phase 123.

### Reviewed Todos (not folded)
- None — no pending todos matched Phase 121 scope.

</deferred>

---

*Phase: 121-mix-exunit-performance-test-value-cleanup-0-plans*
*Context gathered: 2026-06-16*

---
phase: 121-mix-exunit-performance-test-value-cleanup
verified: 2026-06-16T00:00:00Z
status: passed
score: 5/5
overrides_applied: 0
live_confirmation:
  - test: "RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh (live hex.pm)"
    result: "PASSED — orchestrator ran the full scope live: guarded rollout foundations '44 tests, 0 failures (1 excluded)', published-Hex smoke '1 test, 0 failures (8 excluded)' in 28.0s via the --only path, then rulestead_admin '27 tests, 0 failures'. Admin tests run only after the smoke passes (nested if-chain), confirming success propagation. ExUnit prints test names only on failure, so the green result is the correct success signal."
---

# Phase 121: Mix/ExUnit Performance + Test Value Cleanup — Verification Report

**Phase Goal:** Improve core Elixir test/runtime efficiency without hiding risk or making local reproduction harder.
**Verified:** 2026-06-16T00:00:00Z
**Status:** passed (live supply-chain proof confirmed by orchestrator — see Human Verification Required below)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | ExUnit modules marked `async: true` only when proven safe — 0 unsafe flips, do-not-flip trio preserved, borderline code_refs_plug_test stays serial | VERIFIED | 121-ASYNC-AUDIT.md exists, all 23 candidates KEEP SERIAL with cited evidence; stale_flag_worker_test.exs `async: false`, batcher_test.exs `async: false`, inbound_http_test.exs `async: false`, code_refs_plug_test.exs uses `use Rulestead.RepoCase` (no async flag = serial); 0 RepoCase modules flipped; only 5 pre-existing async:true RepoCase modules confirmed in audit |
| 2 | Oversized modules split only with profiling evidence — no splits made, decision recorded | VERIFIED | 121-MEASUREMENT.md §D-05: next-slowest module is 303ms (Promotion.ApplyTest), bar unmet; no module was split; decision recorded explicitly |
| 3 | Test partitioning explicitly rejected with evidence — mix.exs has no partition config | VERIFIED | 121-MEASUREMENT.md §D-06: 5 verified premises documented (serial-only dominant test, overwhelmingly async:false suite, single Postgres + named Fake isolation cost, no partition config, 18 schedulers absorb async set); `grep -n "MIX_TEST_PARTITION\|test_paths\|test_pattern" rulestead/mix.exs` returns nothing |
| 4 | scripts/ci/test.sh keeps scope dispatch + per-scope failure microcopy + dominant test DEFAULT-EXCLUDED and RE-INCLUDED on guarded_rollout_foundations scope | VERIFIED | `run_guarded_rollout_foundations` at line 218-261 wires `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix_logged rulestead "${log_file}" test --only published_hex_smoke` (line 231); `print_guarded_rollout_foundations_failure_guidance` at line 173 contains category + boundary + Rerun + published-hex hint + remediation; `case "${TEST_SCOPE}"` dispatch intact (line 598-649); "Supported scopes:" line 647 unchanged; `all)` arm line 604 still reads `run_mix rulestead test --warnings-as-errors --exclude install_integration` |
| 5 | Before/after slowest-test and wall-clock notes recorded — baseline ~42s, default now ~4.6s, dominant test on opt-in lane | VERIFIED | 121-MEASUREMENT.md §D-09: Run 1 wall-clock `real 4.639s` (vs ~42s baseline); Run 2 `real 4.608s`; Run 3 (with dominant) `real 22.202s`; dominant test at 17089.8ms in Run 3 top-5; VerifyReleasePublishTest ABSENT from default top-25; comparison table at line 138 with -37s delta (-88%) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `rulestead/test/test_helper.exs` | Env-conditional default exclude with both tags; `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE` present; lines 15-29 (global setup) untouched | VERIFIED | File reads correctly: `|> then(fn ex -> if System.get_env("RULESTEAD_RUN_PUBLISHED_HEX_SMOKE") == "1", do: ex, else: [{:published_hex_smoke, true} | ex] end)` at lines 8-12; `ExUnit.start(exclude: default_excludes)` at line 14; global app setup at lines 16-29 intact |
| `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` | `@tag :published_hex_smoke` + `@tag timeout: 300_000` per-test above dominant test; no retry; `@published_smoke_version "0.1.4"` unchanged; fast sibling test at ~line 221 untagged | VERIFIED | Line 199: `@published_smoke_version "0.1.4"` unchanged; line 201: `@tag :published_hex_smoke`; line 202: `@tag timeout: 300_000`; line 203: `test "admin consumer fixture compiles against published Hex packages"`; no retry/loop around `System.cmd` at line 212; line 221: `test "verify.release_publish can plan with the shared fixture helper"` untagged (fast sibling) |
| `scripts/ci/test.sh` | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix_logged` within `run_guarded_rollout_foundations`; `all)` arm unchanged; dispatch structure unchanged; microcopy present | VERIFIED | Line 231: `if RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix_logged rulestead "${log_file}" test --only published_hex_smoke`; line 604: `run_mix rulestead test --warnings-as-errors --exclude install_integration` (all arm unchanged); `guarded_rollout_foundations` at line 617 in case dispatch; line 647 "Supported scopes:" list unchanged (no new scope added) |
| `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-ASYNC-AUDIT.md` | Per-module async verdict record with hazard evidence and net-flip count | VERIFIED | File exists, 183 lines; contains 30 occurrences of "KEEP SERIAL"; Section §7 states "Net-new async modules: 0"; §5 explicitly confirms do-not-flip trio; §4 covers code_refs_plug_test DDL-in-setup verdict |
| `.planning/phases/121-mix-exunit-performance-test-value-cleanup-0-plans/121-MEASUREMENT.md` | Before/after wall-clock + slowest record, partitioning rejection, D-05/D-07/D-10 decisions | VERIFIED | File exists; §D-09 has 4 run tables; §D-06 has 5 partitioning rejection premises; §D-05 records no-split decision; §D-07 no-Dialyzer decision; §D-10 xref cycle note |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `rulestead/test/test_helper.exs` | `verify_release_publish_test.exs :published_hex_smoke tag` | `ExUnit.start(exclude: default_excludes)` with `{:published_hex_smoke, true}` | WIRED | `ExUnit.start(exclude: default_excludes)` at line 14 receives the list built with `{:published_hex_smoke, true}` when env unset |
| `scripts/ci/test.sh run_guarded_rollout_foundations` | `verify_release_publish_test.exs dominant test` | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 run_mix_logged rulestead "${log_file}" test --only published_hex_smoke` | WIRED | Line 231: the env var + `--only` combination opts the tagged test back in and scopes it to exactly 1 test |
| `scripts/ci/test.sh case dispatch` | `run_guarded_rollout_foundations` function | `guarded_rollout_foundations)` case arm at line 617 | WIRED | Line 617-619: `guarded_rollout_foundations) echo "Running guarded rollout foundations proof bar"; run_guarded_rollout_foundations` |
| `guarded_rollout_foundations_failure_category` | `print_guarded_rollout_foundations_failure_guidance` | log file grep → category string → guidance function | WIRED | Line 255: `print_guarded_rollout_foundations_failure_guidance "$(guarded_rollout_foundations_failure_category "${log_file}")"` — post code-review fix (f75402d), smoke run uses `run_mix_logged` so output lands in `${log_file}` for category detection |

### Data-Flow Trace (Level 4)

Not applicable — this phase modifies test infrastructure only (ExUnit tags, test_helper exclusions, CI shell scripts). No dynamic data rendering components to trace.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Default `mix test` excludes the dominant published-Hex test | `cd rulestead && mix test --slowest 5` | 8 properties, 586 tests, 1 failure (4 excluded); top-5 slowest: cluster_refresh 15007ms, apply 303ms, hot_path 206ms, telemetry 101ms, bucket 72ms — `Rulestead.Mix.Tasks.VerifyReleasePublishTest` ABSENT | PASS (dominant test absent; 1 failure is pre-existing cluster_refresh flake, not Phase 121-related — test last modified in commit c649552 / Phase 26, caused by `:peer.start_it/2` timeout, unrelated to async/tag changes) |
| `@tag :published_hex_smoke` present on dominant test only (not @moduletag) | `grep -n "@tag :published_hex_smoke\|@moduletag :published_hex_smoke" verify_release_publish_test.exs` | Line 201: `@tag :published_hex_smoke` (per-test); no @moduletag variant found | PASS |
| `@tag timeout: 300_000` on dominant test; no retry | `grep -n "timeout: 300_000\|retry\|loop" verify_release_publish_test.exs` | Line 202: `@tag timeout: 300_000`; no retry/loop found | PASS |
| No partition config in mix.exs | `grep "MIX_TEST_PARTITION\|test_partitions\|test_paths" rulestead/mix.exs` | No output | PASS |
| No source async flips — do-not-flip trio serial | `grep -n "async:" stale_flag_worker_test.exs batcher_test.exs inbound_http_test.exs` | All three: `async: false` | PASS |
| code_refs_plug_test stays serial | `head -5 rulestead/test/rulestead/webhooks/code_refs_plug_test.exs` | `use Rulestead.RepoCase` (no async flag — defaults serial) | PASS |
| test.sh all) arm unchanged | `grep -A 8 "all)" scripts/ci/test.sh` | Line 604: `run_mix rulestead test --warnings-as-errors --exclude install_integration` | PASS |
| Supported scopes list unchanged | `grep "Supported scopes:" scripts/ci/test.sh` | Line 647: unchanged list (guarded_rollout_foundations present, no new scope added) | PASS |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` probes were declared or expected for this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CIDX-06 | 121-01-PLAN.md, 121-02-PLAN.md, 121-03-PLAN.md | Mix, ExUnit, Dialyzer, Playwright, demo, and release workflows use runner time efficiently without fragile over-sharding or hidden correctness risk | SATISFIED | Default lane: ~4.6s (was ~42s, -88%); dominant test relocated not deleted; proof reachable on named scope; no over-sharding (partitioning rejected); no hidden risk (correctness-first async audit, 0 flips, D-04 no retry) |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers in modified files. No stub patterns. No placeholder returns. No hardcoded empty data flowing to user-visible output.

**Note — pre-existing cluster_refresh_test.exs flake:** `mix test` reports 1 failure in `Rulestead.Runtime.ClusterRefreshTest` due to `:peer.start_it/2` timeout. This is an intermittent infrastructure flake that pre-dates Phase 121 (file last modified in commit c649552, Phase 26). Phase 121 made zero changes to `rulestead/test/rulestead/runtime/cluster_refresh_test.exs`. This failure is not a Phase 121 anti-pattern and does not represent a regression. It is noted here for completeness only.

### Human Verification Required — ✅ CONFIRMED LIVE BY ORCHESTRATOR

### 1. Live Hex.pm Smoke Scope Execution — ✅ PASSED

**Test:** `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` (run live by the orchestrator, 2026-06-16, active hex.pm connection).
**Result:** PASSED. The full scope ran green end-to-end:
- guarded rollout foundations core: `44 tests, 0 failures (1 excluded)`
- published-Hex smoke (the dominant test) via the `--only published_hex_smoke` path: `1 test, 0 failures (8 excluded)`, `Finished in 28.0 seconds` (live hex.pm round-trip)
- rulestead_admin: `27 tests, 0 failures`

The `rulestead_admin` tests run only *after* the smoke passes (nested `if`-chain in `run_guarded_rollout_foundations`), so their green result confirms the smoke's success propagated. ExUnit prints a test's name only on failure, so the absence of the name string with a `1 test, 0 failures` result is the correct success signal (not a miss). The `--only` selection (`8 excluded`) also confirms the WR-02 code-review fix — the file's other 8 tests no longer re-run.
**Why it was flagged human:** the smoke makes a live `deps.get`/`compile` call against published hex.pm packages, intentionally excluded from the default lane (D-03). The orchestrator executed the live run, so the item is resolved.

---

## Gaps Summary

No gaps found. All 5 roadmap success criteria are verified in the codebase. The single human verification item is a live network confirmation of the supply-chain smoke test scope — the source wiring, tagging, exclusion mechanism, and failure microcopy are all verified programmatically.

---

_Verified: 2026-06-16T00:00:00Z_
_Verifier: Claude (gsd-verifier)_

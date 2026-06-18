---
phase: 121
slug: mix-exunit-performance-test-value-cleanup
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
validated: 2026-06-17
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir `~> 1.17`) + Ecto SQL Sandbox [VERIFIED: rulestead/mix.exs] |
| **Config file** | `rulestead/test/test_helper.exs` [VERIFIED] |
| **Quick run command** | `cd rulestead && mix test --warnings-as-errors` |
| **Full suite command** | `bash scripts/ci/test.sh` (default `all` scope) + named proof scopes |
| **Estimated runtime** | ~14s default after D-03 (baseline ~42s); published-Hex proof ~20–28s on its named scope |

---

## Sampling Rate

- **After every task commit:** Run `cd rulestead && mix test --warnings-as-errors` (fast default lane after D-03).
- **After every plan wave:** Run the affected named scope, e.g. `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh`, plus `--slowest 5` to confirm the dominant test is absent from the default lane.
- **Before `/gsd:verify-work`:** Full `bash scripts/ci/local.sh` green AND the published-Hex proof verified reachable + executing on its named scope.
- **Max feedback latency:** ~14 seconds (default lane).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 121-01-T1 | 01 | 1 | CIDX-06 | — | Default suite excludes the dominant slow test | smoke | `cd rulestead && mix test test/rulestead/mix/tasks/verify_release_publish_test.exs --slowest 5` (dominant test reported `(excluded)`) | ✅ existing | ✅ green |
| 121-01-T2 | 01 | 1 | CIDX-06 | T-V14 | Published-Hex proof still runs on a named scope (not zero lanes) | integration | `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` exercises `verify_release_publish_test.exs` | ✅ existing | ✅ green |
| 121-02 | 02 | 1 | CIDX-06 | — | Any flipped async module stays green under concurrency | unit | N/A — Plan 02 audit flipped **0** modules (every candidate carries a disqualifying global-state hazard); condition never triggers | ✅ existing | N/A |
| 121-shared | — | 1 | CIDX-06 | T-V14 | `release_gate` aggregate stays green | gate | Phase 120 fan-in; CI-verified (not a local assertion) — see Manual-Only | ✅ existing | 🟦 CI-gate |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · N/A not-applicable · 🟦 CI-gate*

---

## Wave 0 Requirements

*Existing ExUnit infrastructure covers all phase requirements.* No new test files needed — the phase modifies tagging/wiring of existing tests. If the planner elects to flip `code_refs_plug_test.exs` (the lone borderline candidate, DDL-in-setup), add a verification step that runs it under async twice; this is a verification step, not a new file.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Before/after slowest-test + wall-clock notes | CIDX-06 (success criterion #5) | Comparative measurement recorded in phase summary, not an assertion | Run `cd rulestead && mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25` with and without the dominant test; record `real` wall-clock vs the ~42s/~28s baseline. Recorded in `121-MEASUREMENT.md` (default ~4.6s vs ~42s baseline, -88%) |
| `release_gate` aggregate stays green | CIDX-06 | Cross-phase CI fan-in (Phase 120), not a single local command | Verified in CI on merge; the `guarded_rollout_foundations` scope feeds the aggregate. Locally approximated by `RULESTEAD_RUN_PUBLISHED_HEX_SMOKE=1 RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` (orchestrator confirmed green, 28.0s, live hex.pm — see 121-VERIFICATION.md) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none required)
- [x] No watch-mode flags
- [x] Feedback latency < 14s (default lane ~4.6s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-17

---

## Validation Audit 2026-06-17

State A audit (existing VALIDATION.md). No MISSING gaps — the phase re-tags/wires
existing tests rather than adding behavior, so no new test files were generated.
Behavior 1 re-confirmed live (`--slowest 5` on the dominant test file reported
`(excluded)`, 8 tests 0 failures); Behavior 2 / release_gate confirmed via
121-VERIFICATION.md live run. The async-flip row is N/A (Plan 02 flipped 0 modules).

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| N/A (condition never triggers) | 1 |
| CI-gate (cross-phase) | 1 |

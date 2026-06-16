---
phase: 121
slug: mix-exunit-performance-test-value-cleanup
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
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
| 121-XX | — | 1 | CIDX-06 | — | Default suite excludes the dominant slow test | smoke | `cd rulestead && mix test --slowest 5` (dominant test absent) | ✅ existing | ⬜ pending |
| 121-XX | — | 1 | CIDX-06 | T-V14 | Published-Hex proof still runs on a named scope (not zero lanes) | integration | `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh` exercises `verify_release_publish_test.exs` | ✅ existing | ⬜ pending |
| 121-XX | — | 1 | CIDX-06 | — | Any flipped async module stays green under concurrency | unit | `cd rulestead && mix test <flipped_file> --warnings-as-errors` (run twice for flake check) | ✅ existing | ⬜ pending |
| 121-XX | — | 1 | CIDX-06 | T-V14 | `release_gate` aggregate stays green | gate | Phase 120 fan-in; verify in CI | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing ExUnit infrastructure covers all phase requirements.* No new test files needed — the phase modifies tagging/wiring of existing tests. If the planner elects to flip `code_refs_plug_test.exs` (the lone borderline candidate, DDL-in-setup), add a verification step that runs it under async twice; this is a verification step, not a new file.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Before/after slowest-test + wall-clock notes | CIDX-06 (success criterion #5) | Comparative measurement recorded in phase summary, not an assertion | Run `cd rulestead && mix test --warnings-as-errors --slowest 25` and `--slowest-modules 25` with and without the dominant test; record `real` wall-clock vs the ~42s/~28s baseline |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none required)
- [ ] No watch-mode flags
- [ ] Feedback latency < 14s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

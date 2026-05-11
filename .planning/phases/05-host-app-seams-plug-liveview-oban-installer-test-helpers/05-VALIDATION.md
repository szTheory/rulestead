---
phase: 05
slug: host-app-seams-plug-liveview-oban-installer-test-helpers
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 05 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `cd rulestead && mix test test/rulestead/plug_test.exs test/rulestead/oban_test.exs test/rulestead/test_helpers_test.exs` |
| **Full suite command** | `bash -lc 'cd rulestead && mix test test/rulestead/plug_test.exs test/rulestead/live_view_test.exs test/rulestead/oban_test.exs test/rulestead/test_helpers_test.exs test/rulestead/telemetry_test.exs test/rulestead/mix/tasks/rulestead_install_test.exs test/rulestead/integration/install_smoke_test.exs test/rulestead/integration/install_golden_test.exs --include golden --timeout 300000 && cd ../rulestead_admin && mix test test/rulestead_admin/router_test.exs'` |
| **Estimated runtime** | ~360 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-local `<automated>` verify command for the task just completed
- **After every plan wave:** Run the full suite command above
- **Before phase closure:** Full automated suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | CTX-02, CTX-03, INST-04, INST-05 | T-05-01 / T-05-02 | Conn/socket seams normalize explicit context and call `Rulestead.Runtime` only | unit | `cd rulestead && mix test test/rulestead/plug_test.exs test/rulestead/live_view_test.exs` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | CTX-04, CTX-05, INST-06 | T-05-03 | Oban propagation stays explicit, bounded, and worker-facing via `use Rulestead.Oban.Worker` | unit + docs | `cd rulestead && mix test test/rulestead/oban_test.exs` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 2 | INST-01, INST-02, INST-06 | T-05-04 / T-05-05 / T-05-06 | Installer injection is idempotent and the sibling admin seam compiles without future-phase UI | unit | `bash -lc 'cd rulestead && mix test test/rulestead/mix/tasks/rulestead_install_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/router_test.exs'` | ✅ | ⬜ pending |
| 05-03-01 | 03 | 1 | TEST-01, TEST-02, TEST-03, TEST-05 | T-05-07 / T-05-08 | Fake-backed helpers remain deterministic and `with_flag` works as macro syntax | unit | `cd rulestead && mix test test/rulestead/test_helpers_test.exs` | ✅ | ⬜ pending |
| 05-03-02 | 03 | 1 | TEST-05 | T-05-09 | Telemetry-backed helper assertions observe bounded metadata and always detach | unit | `cd rulestead && mix test test/rulestead/test_helpers_test.exs test/rulestead/telemetry_test.exs` | ✅ | ⬜ pending |
| 05-04-01 | 04 | 3 | INST-03 | T-05-11 | Fresh Phoenix app installs, migrates, boots, and exposes `/admin/flags` without speculative UI assertions | integration | `cd rulestead && mix test test/rulestead/integration/install_smoke_test.exs --timeout 300000` | ✅ | ⬜ pending |
| 05-04-02 | 04 | 3 | INST-03 | T-05-10 / T-05-12 | Golden tree/stdout fixtures stay byte-stable after timestamp normalization and second-run idempotency | integration | `bash -lc 'cd rulestead && mix test test/rulestead/integration/install_golden_test.exs --include golden --timeout 300000'` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers all planned Phase 5 verification surfaces.
- [x] Existing `rulestead/test/test_helper.exs` and `rulestead_admin/test/test_helper.exs` provide the needed harness entrypoints.

---

## Typed Human-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `guides/recipes/context-propagation.md` stays explicit and non-magical for host developers | CTX-05 | Clarity and wording quality are easier to judge manually than with a brittle string check | Read the final guide and confirm it describes Plug -> LiveView -> Oban as opt-in seams, explicitly rejects ambient process magic, and avoids future-phase admin promises |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure support
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target is bounded by the longest integration proof (`<= 300000ms`)
- [ ] `nyquist_compliant: true` set in frontmatter after execution validation is complete

**Approval:** pending

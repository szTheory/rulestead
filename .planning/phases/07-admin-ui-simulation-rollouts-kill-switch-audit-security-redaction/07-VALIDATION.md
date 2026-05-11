---
phase: 07
slug: admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-23
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `rulestead/test/test_helper.exs`, `rulestead_admin/test/test_helper.exs` |
| **Quick run command** | `bash -lc 'cd rulestead && mix test test/rulestead/admin_security_contract_test.exs test/rulestead/admin_audit_kill_switch_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/session_test.exs'` |
| **Full suite command** | `bash -lc 'cd rulestead && mix test test/rulestead/admin_security_contract_test.exs test/rulestead/admin_audit_kill_switch_test.exs test/rulestead/credo_checks_test.exs && mix credo --strict && cd ../rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/flag_live/simulate_test.exs test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs test/rulestead_admin/live/flag_live/kill_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs test/rulestead_admin/live/audit_live/index_test.exs test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs'` |
| **Estimated runtime** | ~420 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task-local `<automated>` verify command from the active plan
- **After every plan wave:** Run the full suite command above
- **Before phase closure:** Full automated suite must be green
- **Max feedback latency:** 420 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | ADMIN-06, ADMIN-07, SEC-01, SEC-02, SEC-03 | T-07-01 / T-07-02 | Public admin verbs authorize first, redact first, and expose a safe simulation seam | unit | `cd rulestead && mix test test/rulestead/admin_security_contract_test.exs` | ❌ W0 | ⬜ pending |
| 07-01-02 | 01 | 1 | ADMIN-06, ADMIN-07, SEC-01, SEC-02 | T-07-03 / T-07-04 | Kill-switch persistence, denied rows, and rollback all append to one ledger without mutating history | unit | `cd rulestead && mix test test/rulestead/admin_audit_kill_switch_test.exs` | ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-09 | T-07-05 / T-07-06 | All Phase 7 routes stay inside the shared live session with canonical `?env=` state | unit | `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/session_test.exs` | ✅ | ⬜ pending |
| 07-02-02 | 02 | 1 | ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07 | T-07-07 | Shared operator shells and placeholders keep policy/env signaling consistent across screens | unit | `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs` | ✅ | ⬜ pending |
| 07-03-01 | 03 | 2 | ADMIN-04, ADMIN-09, SEC-03 | T-07-08 / T-07-09 / T-07-10 | Simulation page renders summary-first explain output, page-scoped archetypes, and canonical fixture export | liveview | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_test.exs` | ❌ W0 | ⬜ pending |
| 07-03-02 | 03 | 2 | ADMIN-04, SEC-03 | T-07-08 | Simulation route stays accessible and redacts non-allowlisted visible metadata while preserving reproducible fixture export | accessibility | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/simulate_accessibility_test.exs` | ❌ W0 | ⬜ pending |
| 07-04-01 | 04 | 2 | ADMIN-05, ADMIN-09 | T-07-11 / T-07-12 | Rollout edits widen exposure only, preserve draft/publish, and keep preview bounded | liveview | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | ❌ W0 | ⬜ pending |
| 07-04-02 | 04 | 2 | ADMIN-05 | T-07-13 | Risky rollout jumps require elevated confirmation and the page remains accessible | accessibility | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_accessibility_test.exs` | ❌ W0 | ⬜ pending |
| 07-05-01 | 05 | 2 | ADMIN-06, ADMIN-09, SEC-01, SEC-02 | T-07-14 | Kill-switch route and detail banner enforce production confirm and clean restore semantics | liveview | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/kill_test.exs` | ❌ W0 | ⬜ pending |
| 07-05-02 | 05 | 2 | ADMIN-07, SEC-01, SEC-02 | T-07-15 / T-07-16 | Per-flag and global timelines read the same ledger, show denied rows, and project rollback honestly | liveview + accessibility | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/timeline_test.exs test/rulestead_admin/live/audit_live/index_test.exs test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs` | ❌ W0 | ⬜ pending |
| 07-06-01 | 06 | 3 | TEL-03, SEC-03, SEC-04 | T-07-17 / T-07-18 / T-07-19 | Strict Credo loads the Phase 7 custom checks after the Phase 7 UI/core code is in place | lint | `cd rulestead && mix credo --strict` | ✅ | ⬜ pending |
| 07-06-02 | 06 | 3 | TEL-03, SEC-03, SEC-04 | T-07-17 / T-07-18 / T-07-19 | Fixture-backed tests prove each local check catches the intended anti-pattern | unit | `cd rulestead && mix test test/rulestead/credo_checks_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers both `rulestead` and `rulestead_admin` verification surfaces.
- [x] Existing `rulestead/test/test_helper.exs` and `rulestead_admin/test/test_helper.exs` provide the needed harness entrypoints.
- [x] Existing router/session test seams cover the Phase 7 mount and URL-state contract.

---

## Typed Human-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Kill-switch and audit copy reads as calm but high-signal under `env=prod` | ADMIN-06, ADMIN-07, ADMIN-09 | Tone, visual hierarchy, and operator confidence are hard to judge with brittle assertions | Open the kill, timeline, and audit screens after implementation. Confirm prod warnings are plain-language, destructive confirmations are explicit, and the detail page still reads as a summary surface rather than a crowded console. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure support
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency target is bounded by the longest combined phase suite (`<= 420s`)
- [ ] `nyquist_compliant: true` set in frontmatter after execution validation is complete

**Approval:** pending

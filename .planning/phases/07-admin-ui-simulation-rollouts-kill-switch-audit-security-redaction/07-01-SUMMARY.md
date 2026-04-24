---
phase: 07
plan: 01
subsystem: rulestead
tags: [admin, security, audit, kill-switch, redaction]
requires: [ADMIN-06, ADMIN-07, SEC-01, SEC-02, SEC-03]
provides: [phase7-admin-facade, append-only-audit-ledger, kill-switch-persistence]
affects:
  - rulestead/lib/rulestead.ex
  - rulestead/lib/rulestead/admin/authorizer.ex
  - rulestead/lib/rulestead/admin/redaction.ex
  - rulestead/lib/rulestead/store.ex
  - rulestead/lib/rulestead/store/command.ex
  - rulestead/lib/rulestead/store/ecto.ex
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/audit_event.ex
  - rulestead/test/rulestead/admin_security_contract_test.exs
  - rulestead/test/rulestead/admin_audit_kill_switch_test.exs
decisions:
  - "Phase 7 mutations route through root facade verbs that authorize first and redact metadata before adapter writes."
  - "Denied kill-switch mutations persist through the same ledger contract by marking adapter commands with `audit_result: :denied`."
  - "Rollback is a single linked audit row that applies the inverse kill-switch state change without editing prior history."
tech_stack:
  added: []
  patterns:
    - "append-only audit metadata contract via `AuditEvent.metadata/1`"
    - "fake/ecto parity for kill-switch and audit behavior"
key_files:
  created:
    - rulestead/lib/rulestead/admin/authorizer.ex
    - rulestead/lib/rulestead/admin/redaction.ex
    - rulestead/test/rulestead/admin_security_contract_test.exs
    - rulestead/test/rulestead/admin_audit_kill_switch_test.exs
  modified:
    - rulestead/lib/rulestead.ex
    - rulestead/lib/rulestead/store.ex
    - rulestead/lib/rulestead/store/command.ex
    - rulestead/lib/rulestead/store/ecto.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/lib/rulestead/audit_event.ex
metrics:
  completed_at: 2026-04-24T08:13:00Z
  task_commits:
    - b9523d3
    - 7733d8a
    - 58cd967
    - 434d910
---

# Phase 07 Plan 01: Admin Core Contract Summary

Phase 7 now has a public core contract for operator-safe simulation, kill-switch actions, audit listing, and rollback. Root verbs authorize first, redact metadata before persistence, and route kill-switch writes plus rollback through one append-only ledger contract shared by the fake and Ecto adapters.

## Outcomes

- Added `Rulestead.Admin.Authorizer` and `Rulestead.Admin.Redaction` as the central seams for Phase 7 authz and redact-before-emit/persist handling.
- Extended `Rulestead.Store.Command` and `Rulestead.Store` with typed kill-switch, audit list, and rollback commands/callbacks.
- Implemented fake and Ecto parity for kill-switch engage/release, denied mutation auditing, audit listing, and rollback-as-inverse-write.
- Enriched `Rulestead.AuditEvent` with normalized metadata helpers so before/after diff and rollback linkage stay inside the existing ledger row shape.

## Verification

- `cd rulestead && mix test test/rulestead/admin_security_contract_test.exs`
- `cd rulestead && mix test test/rulestead/admin_audit_kill_switch_test.exs`
- `cd rulestead && mix test test/rulestead/admin_security_contract_test.exs test/rulestead/admin_audit_kill_switch_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Task 2 fixtures needed valid lifecycle defaults**
- **Found during:** Task 2 RED phase
- **Issue:** Existing flag validation rejected seed flags without an explicit lifecycle mode, which blocked the new kill-switch contract tests before they reached the missing Phase 7 behavior.
- **Fix:** Updated the new Task 2 tests to seed permanent flags and made the Ecto environment seeding idempotent.
- **Files modified:** `rulestead/test/rulestead/admin_audit_kill_switch_test.exs`
- **Verification:** `mix test test/rulestead/admin_audit_kill_switch_test.exs`
- **Commit:** `434d910`

**Total deviations:** 1 auto-fixed. **Impact:** Test coverage now exercises Phase 7 behavior directly instead of failing on unrelated setup preconditions.

## Known Stubs

None.

## Self-Check: PASSED

- Found task commits: `b9523d3`, `7733d8a`, `58cd967`, `434d910`
- Found summary file: `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-01-SUMMARY.md`

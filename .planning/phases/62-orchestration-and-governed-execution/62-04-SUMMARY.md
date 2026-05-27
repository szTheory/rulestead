---
phase: 62-orchestration-and-governed-execution
plan: 62-04
subsystem: test
tags: [contract-test, auto-advance, orchestration, guardrail-automation, fake, ecto]

requires:
  - phase: 62-orchestration-and-governed-execution
    plan: 62-03
    provides: protected-env CR routing, automation tick finalize metadata, Fake/Ecto execute branches
provides:
  - rollout_auto_advance_orchestration_contract_test.exs with 8 scenarios looping @adapters
  - OrchestrationStubProvider (Guardrails.Provider) for healthy/blocked signal simulation
  - Flat signal_fact pass-through fix in RolloutAutoAdvance.resolve_signal_facts/3
  - Fake.OrchestrationStore reentrant store for tick execute inside GenServer
affects:
  - 62-VALIDATION Nyquist closure
  - Phase 62 completion

tech-stack:
  added: []
  patterns:
    - "@adapters [Rulestead.Fake, StoreEcto] on every orchestration contract scenario"
    - "Application env stub provider mode for cross-process Fake GenServer fetches"
    - "Map.from_struct signal facts for eligibility evaluate (not SignalFact.metadata/1)"

key-files:
  created:
    - rulestead/lib/rulestead/fake/orchestration_store.ex
    - rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
  modified:
    - rulestead/lib/rulestead/governance/rollout_auto_advance.ex
    - rulestead/lib/rulestead/fake.ex
    - rulestead/test/support/store_fixtures.ex

key-decisions:
  - "resolve_signal_facts passes Map.from_struct/1 facts — metadata/1 nests evidence and breaks eligibility"
  - "OrchestrationStubProvider mode via Application env so Fake GenServer process reads healthy/blocked"
  - "Fake OrchestrationStore holds GenServer state for nested store calls during automation tick"

patterns-established:
  - "Contract tests assert schedule_for == monitoring_window_ends_at and metadata source guardrail_automation"
  - "Healthy execute asserts rollout.advance audit with source guardrail_automation and percentage == policy.next_percentage"
  - "Protected production tick asserts change_request_submitted outcome without ruleset mutation"

requirements-completed: [ORC-01, ORC-02, ROL-06, AUD-03]

duration: 45min
completed: 2026-05-27
---

# Phase 62 Plan 04: Orchestration Contract Tests Summary

**Fake and Ecto pass identical orchestration contract tests proving schedule→execute auto-advance, guardrail_automation audit evidence, blocked non-advance, protected-env CR submit, replay safety, manual-advance races, and idempotent tick scheduling.**

## Performance

- **Duration:** ~45 min (including prior session continuation)
- **Started:** 2026-05-27T15:55:00Z
- **Completed:** 2026-05-27T20:12:00Z
- **Tasks:** 3
- **Files modified:** 5 (+1 created)

## Accomplishments

- `rollout_auto_advance_orchestration_contract_test.exs` — 8 contract scenarios, each iterating `@adapters [Rulestead.Fake, StoreEcto]`.
- ORC-01: schedule at `monitoring_window_ends_at`, disabled policy skips tick, healthy execute advances, blocked tick completes without mutation.
- AUD-03: healthy automation advance emits `rollout.advance` audit with `source: guardrail_automation`.
- ROL-06: production environment submits change request without ruleset percentage change.
- ORC-02: duplicate execute replay-safe, manual advance race fails closed, deterministic idempotency_key prevents duplicate pending ticks.
- Production fix: `resolve_signal_facts/3` uses flat struct maps instead of `SignalFact.metadata/1` (which nested evidence and caused `guardrail_held:invalid_provider_response`).
- Fake `OrchestrationStore` enables reentrant store operations during automation tick execute inside GenServer.

## Task Commits

Each task was committed atomically:

1. **Task 1: Contract test module and stub provider** - `515c88f` (test)
2. **Task 2: ORC-01 and AUD-03 contract cases** - `9d07283` (fix) + `51c9e31` (test, shared with task 3 scenarios)
3. **Task 3: ROL-06 and ORC-02 race contract cases** - `51c9e31` (test)

**Plan metadata:** `dd39556` (docs)

## Files Created/Modified

- `rulestead/test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` — 8 adapter contract scenarios + OrchestrationStubProvider
- `rulestead/test/support/store_fixtures.ex` — auto-advance seed/list/execute helpers; Page.entries parity
- `rulestead/lib/rulestead/governance/rollout_auto_advance.ex` — flat signal fact pass-through
- `rulestead/lib/rulestead/fake/orchestration_store.ex` — reentrant state for orchestration
- `rulestead/lib/rulestead/fake.ex` — auto-advance schedule hook + OrchestrationStore integration + `*_in_state` delegates

## Decisions Made

- Stub provider mode stored in Application env (`:orchestration_stub_provider_mode`) for Fake GenServer cross-process reads.
- Audit listing handles both `audit_events` and `entries` Page keys (Fake/Ecto parity).

## Deviations from Plan

- **Production fix required during contract testing:** `SignalFact.metadata/1` was incorrect for eligibility evaluation; switched to `Map.from_struct/1` in orchestrator (not anticipated in plan scope but required for ORC-01 healthy path).
- **Fake reentrancy:** Added `Rulestead.Fake.OrchestrationStore` so `execute_scheduled_tick/3` can call back into Fake state from GenServer `handle_call` (extends 62-03 Fake parity beyond plan file list).

## Issues Encountered

- Initial healthy tick blocked with `guardrail_held:invalid_provider_response` — root cause was nested metadata from `SignalFact.metadata/1`.
- Process-dictionary stub mode failed on Fake (GenServer process) — fixed with Application env.
- Fake audit list returned `Page.entries` not `audit_events` — contract helper handles both.

## Verification

```bash
cd rulestead && mix compile --warnings-as-errors
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs
cd rulestead && mix test test/rulestead/rollout_auto_advance_orchestration_contract_test.exs \
  test/rulestead/rollout_auto_advance_contract_test.exs \
  test/rulestead/guarded_rollout_test.exs \
  test/rulestead/scheduled_execution_conflict_test.exs \
  test/rulestead/guardrails/auto_advance_test.exs
```

All commands exit 0 (29 tests).

## User Setup Required

None.

## Next Phase Readiness

- Phase 62 plan 62-04 complete — ready for phase-level verification / 62-VALIDATION closure and phase 63 if defined on roadmap.

## Self-Check: PASSED

- [x] 8 contract scenarios present, each loops `@adapters`
- [x] ORC-01 schedule + execute through ScheduledExecution envelope
- [x] ORC-02 idempotency, replay, race cases
- [x] ROL-06 production CR without auto-approve
- [x] AUD-03 guardrail_automation audit on successful advance
- [x] Full regression command exits 0

---
*Phase: 62-orchestration-and-governed-execution*
*Completed: 2026-05-27*

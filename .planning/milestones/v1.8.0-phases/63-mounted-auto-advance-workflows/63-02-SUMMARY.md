---
phase: 63-mounted-auto-advance-workflows
plan: 63-02
subsystem: ui
tags: [liveview, auto-advance, rollouts, authorization, admin]

requires:
  - phase: 63-mounted-auto-advance-workflows
    plan: 63-01
    provides: auto_advance_panel/1, load assigns, mode derivation
provides:
  - save_auto_advance_policy and validate_auto_advance LiveView events
  - :advance_rollout Authorizer gate (not capabilities.execute?)
  - Direct Rulestead.upsert_rollout_auto_advance_policy/4 save path
  - Capability denial and protected-env policy save LiveView tests
affects:
  - 63-03 timeline automation labeling
  - 63-04 LiveView contract test matrix

tech-stack:
  added: []
  patterns:
    - "Policy save via upsert_rollout_auto_advance_policy/4 — never ruleset publish chain"
    - ":advance_rollout Authorizer.authorize/4 for can_save? and save handler"
    - "Protected-env CR callout informational only; policy save still allowed"

key-files:
  created: []
  modified:
    - rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
    - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
    - rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs

key-decisions:
  - "Form visible only when can_save? and mode not in unavailable/blocked_health"
  - "Empty hidden rule_key falls back to rollout_rule_key assign (Elixir \"\" is truthy)"
  - "DenyAdvanceRolloutPolicy denies :advance_rollout only — not :publish_ruleset"

patterns-established:
  - "validate_auto_advance_policy/1 mirrors Phase 61 enabled-field requirements client-side"
  - "seed_auto_advance_policy!/2 helper for rollouts LiveView contract tests"

requirements-completed: [ADM-04]

duration: 25min
completed: 2026-05-27
---

# Phase 63 Plan 02: Policy Form Events And Capability Gates Summary

**Rollouts page saves auto-advance policy through direct upsert gated on `:advance_rollout`, with prerequisite-disabled modes and protected-env callout that does not block save.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-27T20:31:00Z
- **Completed:** 2026-05-27T20:56:03Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Wired interactive auto-advance form with `phx-submit="save_auto_advance_policy"`, capability explanation, and readonly fields for blocked modes.
- Added `validate_auto_advance` / `save_auto_advance_policy` handlers with param parsing, server validation, and `authorize_advance_rollout/1`.
- Added LiveView tests for capability denial, protected-env callout + save, and direct upsert persistence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire auto-advance form in panel and parse params** - `e95cb51` (feat)
2. **Task 2: Implement save_auto_advance_policy with :advance_rollout gate** - `e6a38f6` (feat)
3. **Task 3: Capability denial and protected-env callout tests** - `a657ca1` (test)

**Plan metadata:** `617fe5b` (docs: complete plan)

## Files Created/Modified

- `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex` - form markup, capability_explanation, conditional visibility
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex` - handlers, parsers, validation, can_save? mode gate
- `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs` - `@auto_advance_capability`, `@auto_advance_protected`, `@auto_advance_save`

## Decisions Made

- `can_save?` requires both `:advance_rollout` authorization and mode outside `[:unavailable, :blocked_health]`.
- Hidden `rule_key` uses `auto_advance_rule_key/2` helper because empty string is truthy in Elixir `||`.
- Protected-env test uses `ProtectedAdvancePolicy` with CR required for `:advance_rollout` on prod only.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **63-03**: extend `guardrail_automation_event?/1` for `rollout.advance` and timeline/intervention labeling (AUD-04).
- ADM-04 write path is live; full contract matrix remains for 63-04.

## Self-Check: PASSED

- Form uses `phx-submit="save_auto_advance_policy"` — PASS
- Form fields: enabled, observation_window_seconds, next_stage, next_percentage — PASS
- `grep persist_rollout|phx-click="publish" rollout_components.ex` — PASS (no matches)
- `mix compile --warnings-as-errors` in rulestead_admin — PASS
- `rollouts.ex` contains `handle_event("save_auto_advance_policy"` — PASS
- `rollouts.ex` contains `authorize_advance_rollout` — PASS
- `rollouts.ex` contains `Authorizer.authorize(actor, :advance_rollout` — PASS
- Save not gated on `capabilities.execute?` (only publish button uses execute?) — PASS
- `@tag :auto_advance_save` submits form and asserts persistence — PASS
- `@tag :auto_advance_capability` and `@tag :auto_advance_protected` — PASS (3/3 tags green)
- No `rulestead/lib/` changes in 63-02 commits — PASS

---
*Phase: 63-mounted-auto-advance-workflows*
*Completed: 2026-05-27*

---
phase: 51-mounted-guardrail-workflow
fixed_at: 2026-05-27T07:15:29Z
review_path: .planning/phases/51-mounted-guardrail-workflow/51-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 51: Code Review Fix Report

**Fixed at:** 2026-05-27T07:15:29Z
**Source review:** .planning/phases/51-mounted-guardrail-workflow/51-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: Raw Guardrail Metadata Allowlist Exposes Nested Provider Payloads

**Files modified:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`, `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs`
**Commit:** 7db1b48
**Applied fix:** Replaced broad `guardrail` and `guardrail.evidence` redaction prefixes with explicit scalar guardrail evidence fields, then seeded nested provider payload metadata in rollout and timeline tests to assert the secret value is redacted.

### CR-02: Timeline and Rollout Views Use Raw URL Environment Instead of Resolved Session Scope

**Files modified:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`, `rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs`
**Commit:** 7a74baf
**Applied fix:** Changed rollout and timeline `handle_params/3` to load data from `socket.assigns.current_environment.key`, which is resolved by mounted session scope, and added restricted-session tests proving `?env=prod` cannot bypass a staging-only mounted session.

### CR-03: Router Serializes Entire Plug Session Into LiveView Session

**Files modified:** `rulestead_admin/lib/rulestead_admin/router.ex`, `rulestead_admin/test/rulestead_admin/router_test.exs`
**Commit:** e721388
**Applied fix:** Restricted `RulesteadAdmin.Router.live_session/3` to mounted-admin session keys plus `policy` and `mount_path`, with a router test proving unrelated host session keys are excluded.

### WR-01: Preview Button Rendered Without a Rollout Rule

**Files modified:** `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`
**Commit:** b51795b
**Applied fix:** Hid the preview action when no rollout rule is available and asserted the mounted workflow remains visible without exposing the preview action.

### WR-02: Direct Preview Event Crashed Without a Rollout Rule

**Files modified:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`
**Commit:** bc93b03
**Applied fix:** Added a server-side guard for direct `"preview"` events when the rollout page is read-only or has no rollout rule, with regression coverage for direct event dispatch.

### CR-04: Dynamic Atom Creation in Rollout Serialization

**Files modified:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs`
**Commit:** 128ef55
**Applied fix:** Replaced `String.to_atom/1` with a bounded enum allowlist for known strategy and guardrail strings, converted constant-built atom lookups to literal atoms, and added a regression test that prevents `String.to_atom` from returning to the rollout LiveView.

## Skipped Issues

None.

## Verification

- `mix test test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs test/rulestead_admin/router_test.exs` passed: 20 tests, 0 failures.
- Final code review status: clean / pass.

---

_Fixed: 2026-05-27T07:15:29Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_

---
phase: 07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction
reviewed: 2026-04-24T08:56:58Z
depth: standard
files_reviewed: 37
files_reviewed_list:
  - rulestead/lib/rulestead.ex
  - rulestead/lib/rulestead/admin/authorizer.ex
  - rulestead/lib/rulestead/admin/redaction.ex
  - rulestead/lib/rulestead/audit_event.ex
  - rulestead/lib/rulestead/fake.ex
  - rulestead/lib/rulestead/store.ex
  - rulestead/lib/rulestead/store/command.ex
  - rulestead/lib/rulestead/store/ecto.ex
  - rulestead/lib/rulestead/credo/no_eval_outside_context.ex
  - rulestead/lib/rulestead/credo/no_mutation_outside_multi.ex
  - rulestead/lib/rulestead/credo/no_raw_traits_in_logger.ex
  - rulestead/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex
  - rulestead/lib/rulestead/credo/no_socket_captured_in_async.ex
  - rulestead/test/rulestead/admin_security_contract_test.exs
  - rulestead/test/rulestead/admin_audit_kill_switch_test.exs
  - rulestead/test/rulestead/credo_checks_test.exs
  - rulestead_admin/lib/rulestead_admin/router.ex
  - rulestead_admin/lib/rulestead_admin/live/session.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex
  - rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex
  - rulestead_admin/lib/rulestead_admin/components/operator_components.ex
  - rulestead_admin/lib/rulestead_admin/components/audit_components.ex
  - rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
  - rulestead_admin/lib/rulestead_admin/components/simulate_components.ex
  - rulestead_admin/lib/rulestead_admin/components/shell.ex
  - rulestead_admin/test/rulestead_admin/router_test.exs
  - rulestead_admin/test/rulestead_admin/live/session_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/simulate_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/kill_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs
  - rulestead_admin/test/rulestead_admin/live/audit_live/index_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs
findings:
  critical: 4
  warning: 4
  info: 0
  total: 8
status: issues_found
---
# Phase 07: Code Review Report

**Reviewed:** 2026-04-24T08:56:58Z
**Depth:** standard
**Files Reviewed:** 37
**Status:** issues_found

## Critical Issues

### CR-01: Host Policy Denials Can Be Bypassed By Built-In Fallback Roles

**File:** `rulestead/lib/rulestead/admin/authorizer.ex:49-53`
**Issue:** `policy.can?/4 || fallback_allow?/3` means an explicit host-policy denial is not final. Any actor carrying one of the baked-in fallback roles is still allowed through, which violates the Phase 7 contract that host auth owns authorization decisions and creates a real authorization bypass.
**Fix:**
```elixir
defp allowed?(actor, action, resource, environment_key) do
  case policy_module() do
    nil -> fallback_allow?(actor, action, environment_key)
    policy -> policy.can?(actor, action, resource, environment_key)
  end
rescue
  _error -> false
end
```

### CR-02: Several Admin Mutations Still Bypass Phase 7 Authorization And Redaction

**File:** `rulestead/lib/rulestead.ex:105-171`
**Issue:** `save_draft_ruleset/1`, `publish_ruleset/1`, and `archive_flag/1` still call `run_store/3` directly inside telemetry spans instead of going through `admin_write/2`. Those entrypoints therefore skip Phase 7 authorization, denied-audit handling, and metadata redaction even though they remain public mutation verbs.
**Fix:** Route these verbs through `admin_write/2` the same way `create_flag/1`, `update_flag/1`, `engage_kill_switch/1`, and `release_kill_switch/1` do, then add regression tests that deny each mutation through `Rulestead.Admin.Policy`.

### CR-03: Detail/Kill Pages Forge Auditor Privileges To Read Audit Data

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:196-205`, `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex:229-245`
**Issue:** Both pages call `Rulestead.list_audit_events/1` with synthetic actors (`%{roles: [:auditor]}`) instead of the current session actor. That bypasses the host policy for audit reads and can expose audit reasons to users the host intended to restrict.
**Fix:** Use `socket.assigns.current_actor` for these reads and treat unauthorized audit access as a missing optional detail:
```elixir
case Rulestead.list_audit_events(flag_key: ..., environment_key: ..., actor: socket.assigns.current_actor) do
  {:ok, page} -> ...
  {:error, %Rulestead.Error{type: :unauthorized}} -> nil
end
```

### CR-04: Phase 07 Credo Checks Break `rulestead_admin` Compilation

**File:** `rulestead/lib/rulestead/credo/no_raw_traits_in_telemetry_meta.ex:1-2`, `rulestead/lib/rulestead/credo/no_raw_traits_in_logger.ex:1-2`, `rulestead/lib/rulestead/credo/no_mutation_outside_multi.ex:1-2`, `rulestead/lib/rulestead/credo/no_socket_captured_in_async.ex:1-2`, `rulestead/lib/rulestead/credo/no_eval_outside_context.ex:1-2`
**Issue:** These modules live under `lib/` and unconditionally `use Credo.Check`. When `rulestead_admin` compiles `rulestead` as a dependency, `Credo.Check` is not available, so the admin package fails to compile before its Phase 07 tests can even run.
**Fix:** Move the custom checks out of the runtime compile path or guard them behind a dev-only loader. For example, compile them only in dev/test support paths, or wrap definition behind `if Code.ensure_loaded?(Credo.Check) do ... end`.

## Warnings

### WR-01: Successful `create_flag`, `update_flag`, And `save_draft_ruleset` Writes Still Skip The Audit Ledger

**File:** `rulestead/lib/rulestead/store/ecto.ex:62-166`, `rulestead/lib/rulestead/fake.ex:248-322`
**Issue:** The Phase 07 contract says admin mutations should append to one append-only ledger, but these code paths return success without adding any audit event in either adapter. `publish_ruleset/1` and `archive_flag/1` do audit; these do not.
**Fix:** Add audit append logic for these successful mutations in both adapters and extend contract tests beyond kill-switch-only coverage.

### WR-02: Denied Audit Persistence Exists Only For Kill-Switch Operations

**File:** `rulestead/lib/rulestead.ex:700-718`
**Issue:** `maybe_persist_denied_mutation/3` handles only `:engage_kill_switch` and `:release_kill_switch`. Denied `create_flag`, `update_flag`, `save_draft_ruleset`, `publish_ruleset`, `archive_flag`, and `rollback_audit_event` requests are returned as errors but never become audit-visible rows, which contradicts the Phase 07 denied-action promise.
**Fix:** Generalize denied-command handling across all admin mutations and teach the adapters to persist deny-only rows for every public Phase 7 write verb.

### WR-03: Global Audit Filters Are Applied After The 50-Row Fetch Limit

**File:** `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex:118-130`, `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex:165-170`
**Issue:** The page fetches the first 50 events from `Rulestead.list_audit_events/1` and only then filters by actor, mutation, and date range in-memory. Matching older events are silently excluded if they fall outside the initial 50-row slice, so the UI does not actually implement the advertised global filtering behavior.
**Fix:** Push actor/mutation/date filtering into the store command/query layer before limiting, or remove the premature limit until server-side filtering exists.

### WR-04: Phase 07 LiveViews Hardcode `/admin/flags` Instead Of Using The Mounted Base Path

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:24-64`, `rulestead_admin/lib/rulestead_admin/live/flag_live/simulate.ex:63-64`, `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex:144-145,552`, `rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex:30,49,62,181`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex:29,48-49,206`, `rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex:17,269`
**Issue:** The router macro supports arbitrary mount paths, but the Phase 07 LiveViews generate links and current paths with hardcoded `/admin/flags...` strings. Any host app mounting the admin UI somewhere else will get broken links, patches, and cross-page navigation.
**Fix:** Build every route from `socket.assigns.rulestead_admin_mount_path` or centralize this in `RulesteadAdmin.Live.Session.current_path/3`.

## Summary

Phase 07 landed most of the intended surfaces, and the dedicated audit route fix in `c23dffc` correctly restores `/audit` ahead of `/:key`. The main regressions are in authorization and integration boundaries: host-policy denials are still bypassable, several public admin mutations still skip the Phase 7 auth/redaction seam, audit data is read with forged auditor identities on two screens, and the new Credo modules break sibling-package compilation.

Verification:

- `cd rulestead && mix test test/rulestead/admin_security_contract_test.exs test/rulestead/admin_audit_kill_switch_test.exs` ✅
- `cd rulestead_admin && mix test test/rulestead_admin/router_test.exs test/rulestead_admin/live/session_test.exs test/rulestead_admin/live/flag_live/kill_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs test/rulestead_admin/live/audit_live/index_test.exs test/rulestead_admin/live/flag_live/phase7_accessibility_test.exs` ❌ failed during dependency compilation because `rulestead/lib/rulestead/credo/*.ex` requires `Credo.Check` on the runtime compile path.

---

_Reviewed: 2026-04-24T08:56:58Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

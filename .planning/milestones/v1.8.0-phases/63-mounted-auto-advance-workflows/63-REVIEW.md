---
phase: 63-mounted-auto-advance-workflows
reviewed: 2026-05-27T21:10:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex
  - rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues
---

# Phase 63: Code Review Report

**Reviewed:** 2026-05-27T21:10:00Z  
**Depth:** standard  
**Files Reviewed:** 5  
**Status:** issues

## Summary

Phase 63 is presentation-only admin work: mounted `FlagLive.Rollouts` exposes auto-advance policy configuration, fail-closed mode copy (ADM-04), and timeline/intervention labeling that distinguishes `guardrail_automation` `rollout.advance` from manual actions (AUD-04). No `rulestead/lib/` changes.

Review focused on authorization gates (`:advance_rollout` vs publish `execute?`), fail-closed copy, redaction allow-lists, mode derivation precedence, and audit labeling correctness. Compile and tagged contract tests pass.

**Security assessment:** Save path correctly authorizes `:advance_rollout` and does not route through ruleset publish. Protected-env callout is informational only (matches D-05). Two warnings remain around error handling and client-supplied `rule_key` pinning.

**Quality assessment:** Implementation meets phase goals and contract tests; warnings are fixable without scope creep.

---

## Findings

### WR-01 — Policy fetch errors are silently treated as “no policy”

**Severity:** warning  
**Requirement ref:** ADM-04 (load path)  
**Files:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`

```549:554:rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  defp fetch_auto_advance_policy(flag_key, env, rollout_rule_key) do
    case Rulestead.fetch_rollout_auto_advance_policy(flag_key, env, rollout_rule_key) do
      {:ok, %{policy: policy}} -> policy
      {:ok, policy} when is_map(policy) -> policy
      {:error, error} -> if auto_advance_policy_not_found?(error), do: nil, else: nil
    end
  end
```

Both branches of the `{:error, _}` clause return `nil`. Only `rollout_auto_advance_policy_not_found` was specified in plan/research; store outages, permission denials, or invalid-command errors collapse to an empty policy and `:ready`/`:config_incomplete` UI without surfacing `error_message`.

**Impact:** Operators may see misleading auto-advance state during transient failures; harder to diagnose at 3am.

**Recommendation:** Return `nil` only for `rollout_auto_advance_policy_not_found`; propagate other errors via `assign(:error_message, …)` or a dedicated `@auto_advance_load_error` assign on `load_page/3`.

---

### WR-02 — Save handler trusts client-supplied `rule_key`

**Severity:** warning  
**Requirement ref:** ADM-04 (write path)  
**Files:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/lib/rulestead_admin/components/rollout_components.ex`

`save_auto_advance_policy` parses `auto_advance[rule_key]` from the form and only backfills when `blank?/1` is true. `ensure_auto_advance_rule_key/2` does not override a non-empty tampered value. Authorization is flag-scoped (`resource_key: flag_key`, action `:advance_rollout`), not tied to the mounted rollout rule.

**Impact:** An actor with flag-level advance permission could upsert auto-advance policy for a different rule on the same flag by editing the hidden field (CSRF-resistant LiveView session, but still an in-session privilege expansion).

**Recommendation:** Always set `rule_key` from `socket.assigns.rollout_rule_key` in the save handler (drop client value), or validate `attrs.rule_key == rollout_rule_key` before upsert.

---

### IN-01 — Duplicated automation labeling helpers across LiveViews

**Severity:** info  
**Requirement ref:** AUD-04  
**Files:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`

`guardrail_automation_event?/1`, `automatic_rollout_advance_summary/3`, `advance_target_from_rules/1`, and related helpers are copy-pasted between rollouts and timeline. Drift risk if one surface is updated without the other.

**Recommendation:** Extract a small `RulesteadAdmin.Audit.RolloutAdvanceLabeling` module (or shared private module imported by both LiveViews) in a follow-up hygiene pass.

---

### IN-02 — Duplicate redaction allow-path entries

**Severity:** info  
**Files:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex`

`intervention_redacted_metadata/1` and `redacted_metadata/1` list `"links.scheduled_execution_id"` twice in the allow list. Harmless but noisy for reviewers extending paths.

**Recommendation:** Deduplicate allow lists when next touching redaction.

---

### IN-03 — `derive_auto_advance_mode/5` matches only atom guardrail states

**Severity:** info  
**Files:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`

`:blocked_health` triggers only when `guardrail_status.state in [:held, :pending_data, :rollback_triggered]`. `RolloutComponents.state_body/1` accepts string variants; if a store ever returns string `decision_state`, blocked mode would not engage while panel copy might still describe a bad state.

**Impact:** Low today — Fake/Ecto payloads use atom `decision_state` via `GuardrailDecision` / in-memory structs.

**Recommendation:** Normalize with `to_existing_atom/1` or include string equivalents in the guard, matching `state_body/1` parity.

---

## Verified Behaviors

| Requirement | Verified |
|-------------|----------|
| ADM-04 panel + modes | `auto_advance_panel/1` six modes; banned fleet/metrics phrases refuted in tests |
| ADM-04 policy save | Direct `upsert_rollout_auto_advance_policy/4`; gated on `:advance_rollout`, not `capabilities.execute?` |
| ADM-04 fail-closed copy | `:unavailable`, `:blocked_health`, protected-env callout without blocking save |
| AUD-04 automation label | `rollout.advance` + `source: guardrail_automation` → "Automatic rollout advance" + `AuditComponents` Automatic badge |
| AUD-04 manual distinction | Non-automation `rollout.advance` → "Manual rollout action" in timeline |
| AUD-04 redaction | Explicit nested allow paths; provider secrets `[REDACTED]`; no `auto_advance.*` wildcards |
| Phase boundary | No core package changes in phase commits |

---

## Test Evidence

```bash
cd rulestead_admin && mix compile --warnings-as-errors          # exit 0
cd rulestead_admin && mix test \
  test/rulestead_admin/live/flag_live/rollouts_test.exs \
  test/rulestead_admin/live/flag_live/timeline_test.exs \
  --only auto_advance                                           # 10 tests, 0 failures
```

---

_Reviewed: 2026-05-27T21:10:00Z_  
_Reviewer: Claude (gsd-code-reviewer)_  
_Depth: standard_

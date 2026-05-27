---
phase: 51-mounted-guardrail-workflow
reviewed: 2026-05-27T06:55:35Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - rulestead_admin/lib/rulestead_admin/components/audit_components.ex
  - rulestead_admin/lib/rulestead_admin/components/rollout_components.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex
  - rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex
  - rulestead_admin/lib/rulestead_admin/live/session.ex
  - rulestead_admin/lib/rulestead_admin/router.ex
  - rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs
  - rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 51: Code Review Report

**Reviewed:** 2026-05-27T06:55:35Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the mounted guardrail workflow, per-flag timeline, router/session changes, and associated LiveView tests. The new guardrail surfaces are aligned with the Phase 51 scope, but three security issues need fixes before this should be considered safe: raw guardrail metadata is over-allowed, environment selection can bypass the resolved mounted session scope, and the router now serializes the entire Plug session into the LiveView session.

## Critical Issues

### CR-01: Raw Guardrail Metadata Allowlist Exposes Nested Provider Payloads

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex:457`

**Issue:** `intervention_redacted_metadata/1` allows `"guardrail"` and `"guardrail.evidence"` before rendering `inspect(@entry.raw, pretty: true)` in `AuditComponents.timeline_row/1`. The shared redactor treats allowlist entries as prefixes, so allowing `"guardrail"` permits every nested key under guardrail metadata, including provider-specific metadata carried by `SignalFact.metadata/1`. The tests only refute `raw_provider_payload` without seeding provider metadata, so this leak is not covered.

**Fix:**
```elixir
allow: [
  "before.status",
  "before.kill_switch_variant_key",
  "before.rules",
  "after.status",
  "after.kill_switch_variant_key",
  "after.rules",
  "diff.rules",
  "guardrail.signal_key",
  "guardrail.environment_key",
  "guardrail.tenant_key",
  "guardrail.status",
  "guardrail.reason",
  "guardrail.threshold_operator",
  "guardrail.threshold_value",
  "guardrail.observed_value",
  "guardrail.freshness_window_seconds",
  "guardrail.sample_size",
  "guardrail.min_sample_size",
  "guardrail.evaluated_at",
  "links.guardrail_decision_id",
  "links.stable_guardrail_decision_id",
  "rollback_of_event_id",
  "links.inverse_event_type",
  "source",
  "request_id"
]
```

Apply the same narrowed allowlist in `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex:175`, and add a test that seeds `metadata: %{raw_provider_payload: "secret"}` inside a guardrail signal fact and asserts the raw detail shows `[REDACTED]` or omits the nested provider key.

### CR-02: Timeline and Rollout Views Use Raw URL Environment Instead of Resolved Session Scope

**File:** `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex:53`

**Issue:** `handle_params/3` reads `env` directly from the URI and passes it to `load_page/3`, while `Session.on_mount/4` already resolves the requested environment against `rulestead_admin_environments`. If a mounted admin session only exposes `dev` but the URL contains `?env=prod`, `Session.resolve/3` falls back to the allowed default, but this LiveView still fetches and mutates against `prod`. The same pattern exists in `rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex:26`. This is an environment authorization gap for mounted host apps that rely on the session environment list to constrain scope.

**Fix:**
```elixir
def handle_params(%{"key" => flag_key}, _uri, socket) do
  env = socket.assigns.current_environment.key
  base_path = build_base_path(socket, flag_key)

  socket =
    socket
    |> assign(:flag_key, flag_key)
    |> assign(:current_path, Session.current_path(socket, base_path))
    |> assign(:env_links, Session.env_links(socket, base_path))
    |> load_page(flag_key, env)

  {:noreply, socket}
end
```

Make the same change in the timeline LiveView, then add tests where `rulestead_admin_environments` omits `prod`, the URL requests `?env=prod`, and the page remains on the allowed fallback environment without showing prod-only data.

### CR-03: Router Serializes Entire Plug Session Into LiveView Session

**File:** `rulestead_admin/lib/rulestead_admin/router.ex:50`

**Issue:** `live_session/3` merges the entire Plug session into the LiveView session. LiveView session data is serialized into the client-side LiveView token, so host applications that store unrelated session values, internal tokens, return URLs, or other sensitive context in the Plug session will now expose them to the mounted admin UI session payload. The router only needs a small allowlist of admin session keys plus `policy` and `mount_path`.

**Fix:**
```elixir
def live_session(conn, path, policy) do
  session = Plug.Conn.get_session(conn)

  session
  |> Map.take([
    "current_actor",
    "rulestead_admin_environments",
    "rulestead_admin_last_env",
    "rulestead_admin_tenants",
    "rulestead_admin_last_tenant",
    "rulestead_admin_default_tenant"
  ])
  |> Map.merge(%{
    "policy" => policy,
    "mount_path" => path
  })
end
```

Add a router/session test that puts an unrelated secret-like key in the Plug session and asserts `RulesteadAdmin.Router.live_session/3` does not include it.

---

_Reviewed: 2026-05-27T06:55:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

# Phase 51: Mounted Guardrail Workflow - Research

**Researched:** 2026-05-27 [VERIFIED: system date]  
**Domain:** Mounted Phoenix LiveView workflow presentation for guarded rollout status and audit evidence [VERIFIED: ROADMAP.md, REQUIREMENTS.md, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex]  
**Confidence:** HIGH [VERIFIED: local repo inspection, Phase 49/50 artifacts, Hex package metadata, official Phoenix LiveView docs]

<user_constraints>
## User Constraints

### Phase Boundary
- Phase 51 must surface guardrail health, thresholds, and intervention reasons inside the mounted rollout experience without implying standalone-admin or fleet-observability scope. [VERIFIED: ROADMAP.md]
- Phase 51 depends on Phase 50 and should plan against the pushed `fetch_guardrail_status`, durable decision records, and audit-linked automatic intervention events. [VERIFIED: ROADMAP.md, .planning/phases/50-guarded-decision-engine-audit/50-01-SUMMARY.md]
- Phase 51 must satisfy `ADM-01`: mounted rollout screens show per-stage guardrail status, thresholds, freshness, and intervention reasons inside the existing workflow without implying standalone admin support or a built-in observability dashboard. [VERIFIED: REQUIREMENTS.md]

### Project Instructions
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: AGENTS.md, CLAUDE.md]
- Keep Phase 8-only docs absent until the roadmap says they ship: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: AGENTS.md, CLAUDE.md]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: AGENTS.md, CLAUDE.md]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: AGENTS.md, CLAUDE.md]
- Make the smallest coherent change that satisfies the active plan, avoid speculative future features, and preserve reproducibility plus CI readability. [VERIFIED: AGENTS.md]

### Out Of Scope
- Rulestead-owned metrics ingestion, storage, dashboards, anomaly detection, provider adapters, auto-advance, fleet-wide observability, and standalone admin behavior are out of scope. [VERIFIED: REQUIREMENTS.md, ROADMAP.md, 49-CONTEXT.md, 50-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | Mounted rollout screens show per-stage guardrail status, thresholds, freshness, and intervention reasons inside the existing workflow without implying standalone admin support or a built-in observability dashboard. [VERIFIED: REQUIREMENTS.md] | Use `Rulestead.fetch_guardrail_status/3` for read-only status, `Rulestead.list_audit_events/1` for intervention timeline rows, and `RulesteadAdmin.Components.RolloutComponents` / `AuditComponents` for bounded mounted presentation. [VERIFIED: rulestead/lib/rulestead.ex, rulestead/lib/rulestead/store/command.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex] |
</phase_requirements>

## Summary

Phase 51 should be planned as a mounted-admin presentation phase in `rulestead_admin`, backed by existing core status and audit read paths in `rulestead`. [VERIFIED: ROADMAP.md, 50-01-SUMMARY.md, rulestead/lib/rulestead.ex] The core decision truth already exists as durable `guardrail_decisions` records with states `healthy`, `pending_data`, `held`, and `rollback_triggered`; the LiveView must consume and explain that truth rather than recomputing it. [VERIFIED: rulestead/lib/rulestead/guardrail_decision.ex, rulestead/lib/rulestead/guardrails/decision.ex, 50-CONTEXT.md]

The primary implementation surface is `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, with reusable display helpers in `RulesteadAdmin.Components.RolloutComponents` and timeline wording in `AuditComponents` / `FlagLive.Timeline`. [VERIFIED: codebase grep] The mounted rollout page currently adjusts rollout percentage, previews samples, and displays rule order plus variant weights; it does not yet fetch guardrail status, render guardrail definitions, or preserve `rollout.guardrails` when serializing a rollout for draft/publish edits. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead/ruleset/rollout.ex]

**Primary recommendation:** Extend the existing rollout LiveView with a read-only guardrail status panel and a small intervention timeline excerpt, preserve authored guardrail embeds during percentage saves, and route all status copy from Phase 49/50 normalized status, evidence, and audit metadata. [VERIFIED: REQUIREMENTS.md, 49-PATTERNS.md, 50-01-SUMMARY.md, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guardrail decision truth | API / Backend | Database / Storage | `rulestead` owns `evaluate_guarded_rollout`, `fetch_guardrail_status`, and `guardrail_decisions`; Phase 50 explicitly says LiveView must not own decision truth. [VERIFIED: rulestead/lib/rulestead.ex, rulestead/lib/rulestead/guardrail_decision.ex, 50-CONTEXT.md] |
| Mounted rollout guardrail status display | Frontend Server (SSR) | API / Backend | `rulestead_admin` LiveViews render mounted operator workflow surfaces and should consume core status reads. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, prompts/rulestead-admin-ux-and-operator-ia.md] |
| Intervention timeline distinction | Frontend Server (SSR) | API / Backend | Audit rows are durable core truth, while mounted timeline rows render operator summaries, actor/source labels, and redacted detail. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex, rulestead/lib/rulestead/audit_event.ex] |
| Missing-data and fail-closed explanation | Frontend Server (SSR) | API / Backend | Core provides normalized reasons such as `stale`, `insufficient_sample`, `provider_missing`, and `unsupported_scope`; mounted admin should translate those into bounded copy. [VERIFIED: rulestead/lib/rulestead/guardrails/signal_fact.ex, rulestead/lib/rulestead/store/command.ex] |
| Host signal/provider ownership | Host App / API | API / Backend | Host apps own signal providers and observability data; mounted admin must not fetch metrics directly or imply Rulestead owns dashboards. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md, prompts/rulestead-security-privacy-and-threat-model.md] |

## Project Constraints (from CLAUDE.md and AGENTS.md)

- `.planning/` is the active source of truth for roadmap and phase state. [VERIFIED: CLAUDE.md, AGENTS.md]
- `prompts/` are the pattern and policy reference set. [VERIFIED: CLAUDE.md, AGENTS.md]
- The sibling-package layout must be preserved. [VERIFIED: CLAUDE.md, AGENTS.md]
- `rulestead_admin` remains a mounted companion surface and must not be moved into a standalone control plane or early publish posture. [VERIFIED: CLAUDE.md, AGENTS.md]
- Narrow, auditable changes are preferred. [VERIFIED: CLAUDE.md, AGENTS.md]
- Scripts-first CI surfaces are preferred when workflow logic becomes non-trivial. [VERIFIED: CLAUDE.md]
- No project-local `.claude/skills` or `.agents/skills` were found. [VERIFIED: `find .claude/skills .agents/skills -name SKILL.md`]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | locked `1.1.30`; config `~> 1.1`; latest stable line includes `1.1.30` and `1.2.0-rc.2` is an RC. [VERIFIED: `mix hex.info phoenix_live_view`, `rulestead_admin/mix.exs`] | Mounted rollout page lifecycle, event handling, and server-rendered UI diffs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | The admin package already uses LiveView for flag rollouts, timelines, audit, and detail screens. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex] |
| Phoenix.Component | shipped through Phoenix LiveView `1.1.30`. [VERIFIED: `mix deps`, official docs] | Reusable guardrail status, stage, and timeline display components. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Existing `RolloutComponents` and `AuditComponents` use function components with `attr/3`, so Phase 51 should extend that pattern. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/rollout_components.ex, rulestead_admin/lib/rulestead_admin/components/audit_components.ex] |
| Rulestead core APIs | repo-local package path dependency from `rulestead_admin` to `../rulestead`. [VERIFIED: rulestead_admin/mix.exs] | Read flag detail, guardrail status, and audit events from core. [VERIFIED: rulestead/lib/rulestead.ex] | The linked-version two-package design requires mounted admin to consume core semantics, not duplicate them. [VERIFIED: AGENTS.md, 49-CONTEXT.md, 50-CONTEXT.md] |
| ExUnit + Phoenix.LiveViewTest | Elixir `1.19.5`; LiveViewTest from Phoenix LiveView `1.1.30`. [VERIFIED: `elixir --version`, `mix deps`] | Route-backed mounted workflow tests for status panels, fail-closed copy, and timeline distinctions. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] | Existing admin tests use `live/2`, `form/3`, `render_change/1`, `element/2`, and `render_click/1` against mounted routes. [VERIFIED: rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs, rulestead_admin/test/rulestead_admin/live/flag_live/timeline_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto / Ecto SQL | locked `3.13.5`; core config `~> 3.13`; Hex latest `3.14.0` on 2026-05-19. [VERIFIED: `mix hex.info ecto`, rulestead/mix.exs] | Core guardrail decision records and status payloads. [VERIFIED: rulestead/lib/rulestead/guardrail_decision.ex, rulestead/lib/rulestead/store/ecto.ex] | Use only through existing core APIs in Phase 51 unless tests need Ecto adapter coverage. [VERIFIED: 50-01-SUMMARY.md] |
| Rulestead.Fake | repo-local test adapter. [VERIFIED: rulestead/lib/rulestead/fake.ex] | Fast mounted LiveView tests with guardrail decisions, audit rows, and status reads. [VERIFIED: rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs, rulestead/lib/rulestead/fake.ex] | Use as the primary admin test adapter because current mounted admin tests already configure `Application.put_env(:rulestead, :store, Rulestead.Fake)`. [VERIFIED: rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `fetch_guardrail_status` read path [VERIFIED: rulestead/lib/rulestead.ex] | Direct Ecto queries from `rulestead_admin` [ASSUMED] | Direct queries would violate the package boundary and couple mounted UI to core persistence internals. [VERIFIED: AGENTS.md, 50-CONTEXT.md] |
| Existing per-flag rollout and timeline pages [VERIFIED: codebase grep] | New `/admin/guardrails` dashboard [ASSUMED] | A new dashboard would imply fleet-observability or standalone-admin scope, which is out of bounds. [VERIFIED: ROADMAP.md, REQUIREMENTS.md] |
| `RolloutComponents` / `AuditComponents` extensions [VERIFIED: codebase grep] | One-off inline HEEx blocks only [ASSUMED] | Inline-only rendering would duplicate status/copy logic and make timeline/status consistency harder to test. [VERIFIED: existing component pattern in `rollout_components.ex` and `audit_components.ex`] |

**Installation:** No new dependency is recommended for Phase 51. [VERIFIED: rulestead_admin/mix.exs, `mix deps`]

```bash
cd rulestead_admin && mix deps.get
```

**Version verification:** `mix hex.info phoenix_live_view`, `mix hex.info ecto`, `elixir --version`, and `mix deps` were run on 2026-05-27. [VERIFIED: terminal output]

## Architecture Patterns

### System Architecture Diagram

```text
Mounted route: /admin/flags/:key/rollouts?env=prod
        |
        v
FlagLive.Rollouts.handle_params/3 resolves mounted env + flag key
        |
        v
Rulestead.fetch_flag/2 loads authored rollout state
        |
        +--> no rollout rule -> existing empty/error state
        |
        +--> rollout rule exists
                 |
                 +--> Rulestead.fetch_guardrail_status(flag, env, rule_key: rule.key)
                 |        |
                 |        +--> {:ok, status} -> render decision state, freshness, thresholds, reasons
                 |        |
                 |        +--> {:error, not found} -> render "No guardrail decision recorded yet" / missing prerequisite copy
                 |
                 +--> Rulestead.list_audit_events(flag_key: flag, environment_key: env)
                          |
                          +--> filter rollout.guardrail_* and manual rollout/ruleset events
                          |
                          v
                  render same mounted workflow timeline excerpt
                  distinguishing actor/source/manual vs automatic
```

The plan should keep this as a read path added to the existing mounted rollout workflow, not as a new metrics collection path. [VERIFIED: ROADMAP.md, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead.ex]

### Recommended Project Structure

```text
rulestead_admin/lib/rulestead_admin/
├── live/flag_live/rollouts.ex           # load status + timeline excerpts; preserve guardrails on saves
├── live/flag_live/timeline.ex           # improve guardrail automatic-event titles/summaries if needed
└── components/
    ├── rollout_components.ex            # guardrail status, definitions, freshness, threshold panels
    └── audit_components.ex              # automatic/manual intervention row wording

rulestead_admin/test/rulestead_admin/live/flag_live/
├── rollouts_test.exs                    # mounted status, missing data, threshold/freshness proof
└── timeline_test.exs                    # automatic vs manual guardrail event distinction if not covered inline
```

This structure extends existing mounted admin files rather than adding a standalone guardrail surface. [VERIFIED: codebase grep, ROADMAP.md]

### Pattern 1: Load Guardrail Status As Derived Operational Truth
**What:** Add `:guardrail_status` and `:guardrail_status_error` assigns in `FlagLive.Rollouts`, populated by `Rulestead.fetch_guardrail_status/3` using `flag_key`, `environment_key`, and the resolved rollout rule key. [VERIFIED: rulestead/lib/rulestead.ex, rulestead/lib/rulestead/store/command.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex]

**When to use:** Use this whenever the rollout page has a rollout rule; render a bounded fallback when the status read returns not found. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex, rulestead/lib/rulestead/fake.ex]

**Example:**
```elixir
# Source: repo APIs in rulestead/lib/rulestead.ex and current load_page/3 shape.
defp load_guardrail_status(flag_key, env, nil), do: {:missing, "No rollout rule is available."}

defp load_guardrail_status(flag_key, env, rule_key) do
  case Rulestead.fetch_guardrail_status(flag_key, env, rule_key: rule_key) do
    {:ok, status} -> {:ok, status}
    {:error, _error} -> {:missing, "No guardrail decision has been recorded for this stage yet."}
  end
end
```

### Pattern 2: Render Status Copy From Normalized Decision/Evidence Fields
**What:** Translate `decision.decision_state`, `decision.decision_reason`, `decision.guardrail_evidence["evidence"]`, and monitoring-window timestamps into compact operator labels. [VERIFIED: rulestead/lib/rulestead/guardrail_decision.ex, rulestead/lib/rulestead/store/ecto.ex, rulestead/lib/rulestead/store/command.ex]

**When to use:** Use this in a new `RolloutComponents.guardrail_status/1` component and keep raw maps behind disclosure only if needed. [VERIFIED: existing component pattern in rulestead_admin/lib/rulestead_admin/components/rollout_components.ex]

**Example:**
```elixir
# Source: Rulestead.GuardrailDecision.serialize/1 and SignalFact.metadata/1 payloads.
%{
  state: decision.decision_state,
  reason: decision.decision_reason,
  threshold: evidence["threshold_operator"] && "#{evidence["threshold_operator"]} #{evidence["threshold_value"]}",
  observed: evidence["observed_value"],
  freshness: evidence["freshness_window_seconds"],
  sample: "#{evidence["sample_size"] || "unknown"} / #{evidence["min_sample_size"] || "unknown"}"
}
```

### Pattern 3: Preserve Authored Guardrails During Percentage Edits
**What:** Extend `serialize_rollout/1` in `FlagLive.Rollouts` to include `guardrails`, preserving each guardrail's signal, threshold, freshness, sample-size, and scope fields. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/guardrail.ex]

**When to use:** Use this before any status rendering work ships, because the current rollout save path rewrites rollout attrs with only `bucket_by`, `percentage`, and `salt`. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex]

**Example:**
```elixir
# Source: current serialize_rollout/1 plus Rulestead.Ruleset.Guardrail fields.
defp serialize_rollout(rollout) do
  %{
    bucket_by: normalize_strategy(field(rollout, :bucket_by)),
    percentage: field(rollout, :percentage, 0),
    salt: field(rollout, :salt),
    guardrails: Enum.map(field(rollout, :guardrails, []), &serialize_guardrail/1)
  }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Enum.into(%{})
end
```

### Pattern 4: Reuse Audit Timeline Mechanics For Manual vs Automatic Distinction
**What:** Let the rollout page show a short timeline excerpt by reading audit events and filtering event types such as `rollout.guardrail_held`, `rollout.guardrail_rollback`, `rollout.guardrail_evaluated`, `ruleset.publish`, and manual rollout changes. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex, rulestead/lib/rulestead/fake.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex]

**When to use:** Use this to satisfy the "same timeline and stage detail surfaces" criterion without building a new dashboard. [VERIFIED: ROADMAP.md]

**Example:**
```elixir
# Source: existing Rulestead.list_audit_events/1 usage in FlagLive.Timeline.
with {:ok, page} <- Rulestead.list_audit_events(flag_key: flag_key, environment_key: env, actor: actor) do
  Enum.filter(page.entries, &String.starts_with?(&1.event_type, "rollout.guardrail"))
end
```

### Anti-Patterns to Avoid
- **LiveView decision reducer:** Do not evaluate signal facts or decide healthy/held/rollback in `rulestead_admin`. [VERIFIED: 50-CONTEXT.md]
- **Standalone guardrail dashboard:** Do not add fleet-wide guardrail or observability pages in Phase 51. [VERIFIED: ROADMAP.md, REQUIREMENTS.md]
- **Metrics-provider UI:** Do not render provider-specific dashboards or raw provider payloads. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-telemetry-observability-and-audit.md]
- **Health-by-absence:** Do not show missing status as healthy; render missing decision/provider/signal prerequisites explicitly. [VERIFIED: REQUIREMENTS.md, rulestead/lib/rulestead/guardrails/decision.ex]
- **Guardrail embed loss:** Do not publish percentage edits that drop existing `rollout.guardrails`. [VERIFIED: current `serialize_rollout/1` omits guardrails; rulestead/lib/rulestead/ruleset/rollout.ex supports guardrails]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Guardrail decision evaluation | UI-side reducer over signal facts [ASSUMED] | `Rulestead.fetch_guardrail_status/3` backed by Phase 50 decision records. [VERIFIED: rulestead/lib/rulestead.ex, rulestead/lib/rulestead/store/ecto.ex] | Core already owns explicit fail-closed states and rollback/hold semantics. [VERIFIED: 50-01-SUMMARY.md] |
| Timeline/audit storage | New mounted-admin event store [ASSUMED] | `Rulestead.list_audit_events/1` and existing audit row components. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex, rulestead_admin/lib/rulestead_admin/components/audit_components.ex] | Audit is durable core truth and mounted UI already projects it into timeline rows. [VERIFIED: prompts/rulestead-telemetry-observability-and-audit.md] |
| Status component system | New UI framework or JS widget [ASSUMED] | Phoenix function components with `attr/3`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] | Existing admin package uses Phoenix components and HEEx, and no new dependency is needed. [VERIFIED: rulestead_admin/lib/rulestead_admin/components/rollout_components.ex] |
| Async/manual client polling | Browser-side metrics polling [ASSUMED] | Server-side LiveView assigns loaded during `handle_params/3`; optionally `assign_async/3` only if reads become slow. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Status reads are repo-local admin reads today, and Phase 51 should not create a metrics polling surface. [VERIFIED: rulestead/lib/rulestead.ex, REQUIREMENTS.md] |

**Key insight:** Phase 51 is an explanation layer over already-recorded operational truth; the highest-risk implementation bug is losing authored guardrails during rollout edits or implying missing status means healthy. [VERIFIED: current code inspection, REQUIREMENTS.md]

## Common Pitfalls

### Pitfall 1: Dropping guardrail definitions during rollout percentage saves
**What goes wrong:** A rollout with authored `guardrails` is saved from the mounted rollout page and the serialized rollout loses the guardrail embeds. [VERIFIED: current `serialize_rollout/1` omits `guardrails`; `Rollout` embeds `guardrails`]
**Why it happens:** The page predates Phase 49 and serializes only bucket, percentage, and salt. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, 49-01-SUMMARY.md]
**How to avoid:** Add `serialize_guardrail/1` and a regression test that draft save preserves `rollout.guardrails`. [VERIFIED: rulestead/lib/rulestead/ruleset/guardrail.ex]
**Warning signs:** Tests assert only percentage/variant weights after save and do not assert guardrails. [VERIFIED: rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs]

### Pitfall 2: Treating "no status row" as healthy
**What goes wrong:** A stage without a Phase 50 decision row appears green or complete. [VERIFIED: REQUIREMENTS.md forbids this behavior]
**Why it happens:** `fetch_guardrail_status` returns an error when no status was found, and naive UI code may hide the panel. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex, rulestead/lib/rulestead/fake.ex]
**How to avoid:** Render explicit missing-data copy explaining that no guardrail decision or host signal has been recorded for the stage yet. [VERIFIED: REQUIREMENTS.md]
**Warning signs:** Empty guardrail panel, green default status, or "No issues" wording without evidence. [ASSUMED]

### Pitfall 3: Blurring manual and automatic actions
**What goes wrong:** Automatic hold/rollback rows look like human rollout edits. [VERIFIED: AUD-02 in REQUIREMENTS.md, 50-CONTEXT.md]
**Why it happens:** Existing timeline summary humanizes event strings generically and only special-cases kill switches, audit rollback, and ruleset publish. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex, rulestead_admin/lib/rulestead_admin/live/audit_live/index.ex]
**How to avoid:** Add explicit titles and summaries for `rollout.guardrail_held`, `rollout.guardrail_rollback`, and `rollout.guardrail_evaluated`, including `actor_type=system` or `source=guardrail_automation` when present. [VERIFIED: 50-CONTEXT.md, rulestead/lib/rulestead/store/ecto.ex]
**Warning signs:** Timeline rows titled only "Rollout guardrail held" with no automatic/source/remediation distinction. [ASSUMED]

### Pitfall 4: Leaking raw provider data or broad observability claims
**What goes wrong:** The page starts showing raw metrics payloads, provider names, or dashboard-like charts. [VERIFIED: out-of-scope docs]
**Why it happens:** Guardrail evidence includes threshold/observed/freshness fields, which can tempt expansion into analytics UI. [ASSUMED]
**How to avoid:** Render only bounded evidence normalized by `SignalFact.metadata/1` and `normalize_guardrail_metadata/1`. [VERIFIED: rulestead/lib/rulestead/guardrails/signal_fact.ex, rulestead/lib/rulestead/store/command.ex]
**Warning signs:** Provider-specific branches or charting dependencies in `rulestead_admin`. [ASSUMED]

## Code Examples

### Guardrail Status Component Shape
```elixir
# Source: Phoenix.Component attr docs and existing RolloutComponents style.
attr(:status, :map, default: nil)
attr(:missing_reason, :string, default: nil)

def guardrail_status(assigns) do
  ~H"""
  <section class="rs-card" aria-label="Guardrail status">
    <h2>Guardrail status</h2>
    <p :if={@missing_reason} role="status"><%= @missing_reason %></p>
    <div :if={@status}>
      <p>Decision: <strong><%= humanize(@status.decision.decision_state) %></strong></p>
      <p>Reason: <%= @status.decision.decision_reason %></p>
    </div>
  </section>
  """
end
```

### Audit Title Special-Casing
```elixir
# Source: current title_for/1 pattern in FlagLive.Timeline and AuditLive.Index.
defp title_for(%{event_type: "rollout.guardrail_held"}), do: "Automatic guardrail hold"
defp title_for(%{event_type: "rollout.guardrail_rollback"}), do: "Automatic guardrail rollback"
defp title_for(%{event_type: "rollout.guardrail_evaluated"}), do: "Guardrail evaluated"
```

### Guardrail Preservation Test Intent
```elixir
# Source: current RolloutsTest draft-save pattern.
saved_html =
  view
  |> element("button[phx-click='save_draft']")
  |> render_click()

assert saved_html =~ "Draft saved for Production"
assert [%{signal_key: "checkout_error_rate"}] = rollout_rule.rollout.guardrails
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Rollout UI displayed percentage, preview, rule order, and variant weights only. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex] | Rollout UI must also display guardrail status, thresholds, freshness, and intervention reasons from core decision/audit truth. [VERIFIED: REQUIREMENTS.md, ROADMAP.md] | Phase 51 / v1.5.0. [VERIFIED: ROADMAP.md] | Planner should extend existing mounted workflow instead of creating a new product surface. [VERIFIED: AGENTS.md, ROADMAP.md] |
| Phase 49 authored guardrails were configuration only. [VERIFIED: 49-CONTEXT.md] | Phase 50 added durable operational decision state and status reads. [VERIFIED: 50-01-SUMMARY.md] | Phase 50 commit `c4dd3fb`. [VERIFIED: 50-01-SUMMARY.md, STATE.md] | Phase 51 can render current status without adding decision logic. [VERIFIED: 50-01-SUMMARY.md] |
| Generic audit timeline humanization covered kill switches, audit rollback, and ruleset publish. [VERIFIED: timeline/index code] | Guardrail events need automatic/manual wording and bounded evidence summaries. [VERIFIED: REQUIREMENTS.md, 50-CONTEXT.md] | Phase 51. [VERIFIED: ROADMAP.md] | Timeline copy and filters need targeted additions. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Experiment LiveView's `guardrail_warning` is not the Phase 49/50 guardrail contract and should not be reused as rollout guardrail truth. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/experiment_live/show.ex, 49-CONTEXT.md, 50-CONTEXT.md]
- Existing rollout serialization that omits `guardrails` is outdated for guarded rollout authored state. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead/ruleset/rollout.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Direct Ecto queries from `rulestead_admin` would violate intended package boundaries. [ASSUMED] | Alternatives / Don't Hand-Roll | If accepted project policy allowed direct queries, the plan could choose a lower-level read path, but it would still be less aligned with existing API usage. |
| A2 | One-off inline HEEx would make consistency harder than component extension. [ASSUMED] | Alternatives | If the team prefers inline code for tiny panels, component extraction could be deferred, but repeated status/timeline copy would need careful test coverage. |
| A3 | Provider-specific branches or charting dependencies are warning signs of scope drift. [ASSUMED] | Common Pitfalls | If a future decision explicitly permits provider-specific UI, this warning would need revision, but current Phase 51 excludes it. |

## Open Questions (RESOLVED)

1. **Should `fetch_guardrail_status` be called for only the current rollout rule or for every stage-like audit/status record?**
   - What we know: `FetchGuardrailStatus` accepts optional `rule_key` and `stage`, and current rollout UI resolves one rollout rule. [VERIFIED: rulestead/lib/rulestead/store/command.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex]
   - What's unclear: The mounted page does not currently model multiple named rollout stages; Phase 50 status records have a `stage` string. [VERIFIED: rulestead/lib/rulestead/guardrail_decision.ex]
   - RESOLVED: Plan for the current rollout rule only, using `rule_key: field(rollout_rule, :key)` and rendering the returned `stage` when present. Do not fetch every stage-like audit/status record and do not invent a stage-management UI in Phase 51. [VERIFIED: ROADMAP.md, 51-CONTEXT.md]

2. **Should global audit filters add guardrail event options in Phase 51 or only per-flag surfaces?**
   - What we know: ADM-01 says mounted rollout screens and the same timeline/stage detail surfaces, not a global audit dashboard expansion. [VERIFIED: REQUIREMENTS.md]
   - What's unclear: Operators may expect global audit mutation dropdown to include automatic guardrail rows once per-flag rows exist. [ASSUMED]
   - RESOLVED: Add guardrail event wording to per-flag rollout and per-flag timeline surfaces only. Do not add global audit filter options in Phase 51; that would broaden the mounted workflow beyond ADM-01 and can be reconsidered in a later audit UX phase if operator evidence warrants it. [VERIFIED: ROADMAP.md, REQUIREMENTS.md, 51-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix tests and LiveView compile | yes [VERIFIED: `elixir --version`] | 1.19.5 / OTP 28 [VERIFIED: terminal output] | CI matrix also covers supported versions. [VERIFIED: .github/workflows/ci.yml via Phase 49 research] |
| Mix | Dependency and test commands | yes [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: terminal output] | None needed. [VERIFIED: local command] |
| Phoenix LiveView | Mounted admin UI | yes [VERIFIED: `mix deps`] | 1.1.30 [VERIFIED: `mix deps`, `mix hex.info phoenix_live_view`] | None recommended. [VERIFIED: rulestead_admin/mix.exs] |
| Rulestead.Fake | Mounted admin tests | yes [VERIFIED: codebase grep] | repo-local [VERIFIED: rulestead/lib/rulestead/fake.ex] | Ecto adapter tests can supplement core behavior if needed. [VERIFIED: rulestead/test/rulestead/guarded_rollout_test.exs] |

**Missing dependencies with no fallback:** None found. [VERIFIED: local commands]  
**Missing dependencies with fallback:** None found. [VERIFIED: local commands]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest, Phoenix LiveView `1.1.30`. [VERIFIED: `mix deps`, official docs] |
| Config file | Standard Mix test setup in each package; admin tests use `RulesteadAdmin.ConnCase`. [VERIFIED: rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs] |
| Quick run command | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs test/rulestead_admin/live/flag_live/timeline_test.exs` [VERIFIED: existing files] |
| Full suite command | `cd /Users/jon/projects/rulestead/rulestead_admin && mix test` plus `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/guarded_rollout_test.exs test/rulestead/guardrails/decision_test.exs` [VERIFIED: existing files] |

### Phase Requirements To Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ADM-01 | Rollout page shows latest guardrail decision state, threshold, freshness, sample, and reason. [VERIFIED: REQUIREMENTS.md] | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes, extend existing file [VERIFIED: file exists] |
| ADM-01 | Missing status/provider/signal data renders fail-closed explanatory copy rather than healthy copy. [VERIFIED: REQUIREMENTS.md] | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes, extend existing file [VERIFIED: file exists] |
| ADM-01 | Automatic guardrail hold/rollback events are distinguishable from manual publish/rollout actions in timeline surfaces. [VERIFIED: REQUIREMENTS.md] | LiveView integration | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/timeline_test.exs` | yes, extend existing file [VERIFIED: file exists] |
| ADM-01 | Mounted rollout percentage saves preserve authored guardrail definitions. [VERIFIED: current code risk, Phase 49 contract] | LiveView integration / regression | `cd rulestead_admin && mix test test/rulestead_admin/live/flag_live/rollouts_test.exs` | yes, extend existing file [VERIFIED: file exists] |

### Sampling Rate
- **Per task commit:** Run the admin quick command above. [VERIFIED: existing test structure]
- **Per wave merge:** Run `cd rulestead_admin && mix test` and the Phase 50 core guarded rollout tests. [VERIFIED: Phase 50 plan verification]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json nyquist_validation true]

### Wave 0 Gaps
- [ ] Add seeded guardrail definitions to `rollouts_test.exs` fixture data so status and preservation tests exercise real `rollout.guardrails`. [VERIFIED: existing fixture lacks guardrails]
- [ ] Add helper assertions for automatic guardrail audit rows in `timeline_test.exs` or shared admin test support. [VERIFIED: existing timeline tests cover kill switch/audit rollback only]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct new auth system [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] | Host-owned session and actor context remain unchanged. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V3 Session Management | no direct new session state [VERIFIED: prompt threat model] | Existing mounted LiveView session plumbing remains host-owned. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex, prompt threat model] |
| V4 Access Control | yes [VERIFIED: mounted admin policy posture] | Keep status reads behind existing admin LiveView policy/session envelope; mutations stay governed in core. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead/admin/policy.ex] |
| V5 Input Validation | yes [VERIFIED: LiveView uses params/events] | Normalize query params, use existing command structs, and do not trust client-provided status. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead/lib/rulestead/store/command.ex] |
| V6 Cryptography | no new crypto [VERIFIED: no new secret/signature work in scope] | Do not add custom crypto; no provider credentials or secrets in mounted UI. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V7 Error Handling and Logging | yes [VERIFIED: fail-closed missing-data requirement] | Missing status/provider/signal reads must render bounded explanation without exposing raw provider payloads. [VERIFIED: REQUIREMENTS.md, rulestead/lib/rulestead/store/command.ex] |
| V14 Configuration | yes [VERIFIED: host-owned seam] | Do not add provider credentials or dashboard config to `rulestead_admin`. [VERIFIED: 49-CONTEXT.md, prompt threat model] |

### Known Threat Patterns for Mounted Guardrail Workflow

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| UI implies a missing decision is healthy | Tampering / Safety integrity [ASSUMED STRIDE mapping] | Explicit missing-data/fail-closed copy and tests. [VERIFIED: REQUIREMENTS.md] |
| Raw provider evidence leaks into mounted UI | Information Disclosure | Render only normalized guardrail metadata and redacted audit metadata. [VERIFIED: rulestead/lib/rulestead/store/command.ex, rulestead_admin/lib/rulestead_admin/live/flag_live/timeline.ex] |
| Automatic action appears human-originated | Repudiation | Show system/source provenance from audit metadata and event type. [VERIFIED: 50-CONTEXT.md, rulestead/lib/rulestead/store/ecto.ex] |
| Client-supplied route params select hidden tenant/env data | Elevation of Privilege / Information Disclosure [ASSUMED STRIDE mapping] | Keep using mounted session environment and existing admin read commands with actor context. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex, rulestead_admin/lib/rulestead_admin/live/session.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/REQUIREMENTS.md` - ADM-01, guarded rollout scope, proof posture, out-of-scope surfaces. [VERIFIED]
- `.planning/ROADMAP.md` - Phase 51 goal, dependencies, success criteria, and milestone boundary. [VERIFIED]
- `.planning/STATE.md` - Phase 49/50 completion and Phase 51 readiness. [VERIFIED]
- `.planning/phases/49-guardrail-signal-contract/49-CONTEXT.md`, `49-RESEARCH.md`, `49-PATTERNS.md` - host-owned signal seam, authored guardrail contract, normalized evidence. [VERIFIED]
- `.planning/phases/50-guarded-decision-engine-audit/50-CONTEXT.md`, `50-01-PLAN.md`, `50-01-SUMMARY.md` - decision states, audit envelope, status read path, and Phase 51 readiness. [VERIFIED]
- `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/guardrail_decision.ex`, `rulestead/lib/rulestead/guardrails/decision.ex`, `rulestead/lib/rulestead/store/command.ex`, `rulestead/lib/rulestead/store/ecto.ex`, `rulestead/lib/rulestead/fake.ex` - core status, decision, and audit data paths. [VERIFIED]
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex`, `timeline.ex`, `audit_live/index.ex`, `components/rollout_components.ex`, `components/audit_components.ex` - mounted rollout and timeline surfaces. [VERIFIED]
- Official Phoenix LiveView docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html, https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html, https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html. [CITED]

### Secondary (MEDIUM confidence)
- Hex package metadata from `mix hex.info phoenix_live_view` and `mix hex.info ecto`. [VERIFIED: terminal output]
- Prompt anchors: `prompts/rulestead-admin-ux-and-operator-ia.md`, `prompts/rulestead-security-privacy-and-threat-model.md`, `prompts/rulestead-telemetry-observability-and-audit.md`. [VERIFIED]

### Tertiary (LOW confidence)
- Assumptions listed in the Assumptions Log only. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions, constraints, and docs were verified locally or through official HexDocs. [VERIFIED]
- Architecture: HIGH - direct Phase 49/50 artifacts and mounted LiveView code define the integration path. [VERIFIED]
- Pitfalls: HIGH for guardrail embed loss and missing-data behavior, MEDIUM for UI consistency assumptions. [VERIFIED, ASSUMED as tagged]

**Research date:** 2026-05-27 [VERIFIED: system date]  
**Valid until:** 2026-06-26 for local architecture and package versions; revisit earlier if Phoenix LiveView `1.2` becomes the locked dependency. [ASSUMED]

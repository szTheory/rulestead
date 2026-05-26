# Phase 49: Guardrail Signal Contract - Research

**Researched:** 2026-05-26 [VERIFIED: current date]
**Domain:** Guarded rollout contract design in Elixir/Ecto with host-owned signal seams [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md]
**Confidence:** HIGH [VERIFIED: codebase grep, official Ecto docs, repo config]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Host-owned signal seam
- **D-01:** Phase 49 introduces a host-provided guardrail signal seam only. Rulestead consumes normalized signal facts; it does not fetch metrics directly, own provider adapters, or store observability truth.
- **D-02:** Supported signal integration must follow the existing host-owned seam posture used elsewhere in the repo: the host app owns provider wiring, identity, environment access, and any upstream credentials.
- **D-03:** Missing or unsupported providers must fail closed with explicit bounded reasons instead of implying healthy rollout state.

### Authored-state contract
- **D-04:** Guardrail definitions attach to rollout authored state as explicit configuration, not as ambient runtime-only metadata and not as mutable health state hidden outside the authored contract.
- **D-05:** Each guardrail definition should carry stable authored fields for signal identity, threshold semantics, freshness requirements, minimum sample-size requirements, and scope expectations so later decision logic can stay deterministic.
- **D-06:** Phase 49 should preserve the existing explicit draft/publish and authored-state discipline rather than introducing a side-channel contract for rollout safety data.

### Signal status normalization
- **D-07:** Phase 49 should lock a bounded normalized signal vocabulary that distinguishes healthy data from fail-closed cases such as missing provider support, stale data, insufficient sample size, or otherwise unsupported queries.
- **D-08:** Threshold semantics must stay explicit in the contract. Later phases should evaluate normalized facts against authored thresholds rather than infer health from provider-specific error strings or implicit defaults.
- **D-09:** Weak or incomplete signal data is never equivalent to healthy data in the contract; later automation must inherit this fail-closed posture directly from Phase 49.

### Explicit environment and tenant scope
- **D-10:** Every signal query contract must preserve explicit environment scope and tenant scope when present, consistent with the repo’s existing explicit-scope posture.
- **D-11:** Scope provenance and related metadata should reuse the existing bounded normalization style used by command and audit metadata rather than inventing a second scope dialect for guardrails.
- **D-12:** Phase 49 must not rely on ambient runtime/session state to infer where a signal applies. Guardrail scope stays explicit at the contract seam.

### Governance, audit, and package-boundary discipline
- **D-13:** Phase 49 defines contract semantics only. It must not pre-build Phase 50 decision execution or Phase 51 mounted rollout UI behavior beyond the bounded reason vocabulary those phases will need.
- **D-14:** Guardrail contract design must stay compatible with the existing governed mutation and audit envelope so later automatic hold or rollback actions can record exact scope, breached signal identity, and bounded reasons without a second audit model.
- **D-15:** The sibling-package release shape remains unchanged: `rulestead` owns the core signal contract and `rulestead_admin` remains a mounted companion surface that will consume, not redefine, these semantics later.

### the agent's Discretion
- Exact module and struct names for the guardrail signal seam, provided the seam remains host-owned and explicit.
- Exact field names and enum labels for normalized signal facts, provided the vocabulary stays bounded and fail-closed.
- Exact authored-state nesting shape for rollout guardrail definitions, provided it composes with existing authored rollout state and preserves explicit scope.

### Deferred Ideas (OUT OF SCOPE)
- Rulestead-owned metrics ingestion, storage, dashboards, or anomaly detection
- Automatic stage advancement based on healthy guardrails
- Fleet-wide observability or standalone admin behavior for rollout health
- Provider-specific UI modeling in Phase 49 beyond bounded reason vocabulary
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ROL-01 | Operators can attach one or more host-supplied guardrail signals to a staged rollout with explicit threshold, freshness, sample-size, environment, and tenant semantics without making Rulestead fetch or own observability data directly. [VERIFIED: REQUIREMENTS.md] | Use typed Ecto embeds for authored guardrails, a host-provided signal behaviour for runtime facts, explicit environment/tenant fields on the query contract, and bounded enum vocabularies for thresholds and fail-closed status. [VERIFIED: codebase grep; CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html; https://hexdocs.pm/ecto/Ecto.Enum.html] |
</phase_requirements>

## Summary

Phase 49 should be planned as a pure contract phase inside `rulestead`, not as a decision-engine phase and not as an observability integration phase. The smallest coherent implementation is: add typed authored guardrail embeds to the existing rollout authored state, add a host-owned signal behaviour plus normalized query/fact structs, and reuse existing scope/audit normalization patterns already present in `Rulestead.Context`, `Rulestead.Store.Command.GovernanceSupport`, and `Rulestead.AuditEvent`. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/context.ex, rulestead/lib/rulestead/store/command.ex, rulestead/lib/rulestead/audit_event.ex, rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex]

The repo already uses Ecto embeds and enums for authored state, and Ecto’s current docs explicitly support `embeds_many/3`, `embeds_one/3`, `cast_embed/3`, `on_replace`, and bounded enum fields as the normal way to model nested validated data. That makes a typed embedded guardrail contract the standard fit here, while ad-hoc maps or provider-specific payload blobs would cut across existing project conventions and create avoidable validation drift. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/ruleset/rollout.ex; CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html; https://hexdocs.pm/ecto/Ecto.Enum.html]

The main planning risk is not technical feasibility; it is accidentally widening scope. If the plan keeps Phase 49 bounded to authored contract, normalized runtime fact vocabulary, explicit scope propagation, and audit-compatible metadata, the phase is straightforward. If it drifts into provider adapters, rollout decisions, automatic hold/rollback execution, or mounted UI semantics, it will trespass into Phases 50-51 and break the milestone split already locked in the roadmap. [VERIFIED: ROADMAP.md, 49-CONTEXT.md]

**Primary recommendation:** Put `guardrails` directly under the existing rollout authored embed, model them with Ecto embedded schemas and enums, and add a host-supplied `SignalProvider` seam that returns normalized fail-closed `SignalFact` structs with explicit environment and tenant scope. [VERIFIED: rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/context.ex, rulestead/lib/rulestead/store/command.ex; CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guardrail authored configuration | API / Backend | Database / Storage | Authored rollout state already lives in Ecto schemas and embeds under `rulestead`, with draft/publish validation in changesets and persistence in the store layer. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/ruleset/rollout.ex] |
| Signal query seam | API / Backend | Browser / Client | The host app owns provider wiring and credentials; `rulestead` should expose a behaviour/struct seam, not fetch metrics from UI or browser code. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-host-app-integration-seam.md, prompts/rulestead-security-privacy-and-threat-model.md] |
| Environment and tenant scope propagation | API / Backend | Frontend Server (SSR) | The canonical scope carriers are `Rulestead.Context`, command metadata, and mounted session resolution, all of which are explicit and server-owned today. [VERIFIED: rulestead/lib/rulestead/context.ex, rulestead/lib/rulestead/store/command.ex, rulestead_admin/lib/rulestead_admin/live/session.ex] |
| Guardrail fact normalization | API / Backend | — | Phase 49 must normalize provider truth into a bounded vocabulary before later phases evaluate decisions. That normalization belongs in core contract code, not UI presentation code. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md] |
| Audit-compatible evidence shape | API / Backend | Database / Storage | Audit metadata is already normalized and bounded in `Rulestead.AuditEvent`; future guardrail evidence should plug into that same envelope. [VERIFIED: rulestead/lib/rulestead/audit_event.ex, 49-CONTEXT.md] |
| Mounted rollout consumption | Frontend Server (SSR) | API / Backend | `rulestead_admin` already consumes core rollout semantics from mounted LiveViews and should continue consuming, not redefining, this contract in Phase 51. [VERIFIED: 49-CONTEXT.md, rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: CLAUDE.md]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: CLAUDE.md]
- `rulestead_admin` is intentionally a guarded stub until later phases; do not introduce early publish flows that bypass that rule. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes. [VERIFIED: CLAUDE.md]
- Keep root docs honest about the current phase. [VERIFIED: CLAUDE.md]
- Use scripts-first CI surfaces where workflow logic gets non-trivial. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Ecto` via `ecto_sql` | repo constraint `~> 3.13`; locked `ecto 3.13.5`; latest `3.14.0` published 2026-05-19 [VERIFIED: rulestead/mix.exs, mix hex.info ecto, https://hexdocs.pm/ecto/changelog.html] | Typed authored-state embeds, changesets, and enum-backed vocabularies. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html; https://hexdocs.pm/ecto/Ecto.Enum.html] | The repo already models authored rule state with `embeds_many`, `embeds_one`, `cast_embed`, and `Ecto.Enum`; extending that pattern for guardrails keeps validation and serialization consistent. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/ruleset/rollout.ex] |
| Existing core seam modules | repo code, no new dependency [VERIFIED: codebase grep] | `Rulestead.Context` for explicit scope, `Command.GovernanceSupport` for bounded provenance normalization, `AuditEvent.metadata/1` for durable evidence metadata. [VERIFIED: rulestead/lib/rulestead/context.ex, rulestead/lib/rulestead/store/command.ex, rulestead/lib/rulestead/audit_event.ex] | These are the already-shipped contract surfaces for explicit environment/tenant scope and normalized metadata; Phase 49 should reuse them instead of inventing a parallel dialect. [VERIFIED: 49-CONTEXT.md, 29-CONTEXT.md] |
| ExUnit | bundled with Elixir 1.19.5 locally [VERIFIED: elixir --version, mix --version] | Contract tests for authored guardrails, signal fact normalization, and scope propagation. [VERIFIED: codebase grep] | The repo already relies on targeted ExUnit contract tests for changesets, commands, promotion, and mounted routes, so Phase 49 should follow that proof style. [VERIFIED: rulestead/test/rulestead/ruleset_validation_test.exs, rulestead/test/rulestead/store/command_test.exs, rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix LiveViewTest` | repo constraint `~> 1.1`; installed `1.1.x`; latest stable line seen `1.1.30` on 2026-05-05 [VERIFIED: rulestead_admin/mix.exs, mix hex.info phoenix_live_view] | Later mounted consumer tests for Phase 51 to prove the UI consumes the core contract without redefining it. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] | Use for later route-backed mounted rollout status tests, not for Phase 49 core contract implementation itself. [VERIFIED: ROADMAP.md, rulestead_admin/test/rulestead_admin/live/flag_live/rollouts_test.exs] |
| CI matrix with PostgreSQL service | CI runs Elixir `1.17.3/OTP 26.2.5` and `1.19.2/OTP 28.4.3` plus Postgres 15 service [VERIFIED: .github/workflows/ci.yml] | Full suite verification across core/admin packages. [VERIFIED: .github/workflows/ci.yml] | Use for phase gate and regression coverage after targeted contract tests pass locally. [VERIFIED: .github/workflows/ci.yml] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Typed Ecto embeds for guardrail authored state [VERIFIED: repo pattern] | Ad-hoc nested maps in `ruleset.metadata` or rule `value` [ASSUMED] | Ad-hoc maps would bypass the repo’s current changeset validation style, weaken enum boundedness, and make later audit/serialization drift more likely. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex] |
| Host-owned signal behaviour in `rulestead` [VERIFIED: 49-CONTEXT.md] | Provider adapters owned by `rulestead` [VERIFIED: deferred/out-of-scope docs] | Provider adapters would widen package boundaries, pull credentials into core, and violate the locked host-owned observability boundary. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md, prompts/rulestead-host-app-integration-seam.md] |
| Bounded enums and explicit status structs [VERIFIED: repo pattern] | Freeform provider error strings as durable truth [ASSUMED] | Freeform strings would be harder to validate, harder to audit, and too unstable for later deterministic decision logic. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/audit_event.ex] |

**Installation:** No new package is needed for the recommended implementation; Phase 49 should reuse the existing dependency set. [VERIFIED: rulestead/mix.exs]

```bash
cd rulestead && mix deps.get
```

**Version verification:** Verified in this session with `mix hex.info ecto` and `mix hex.info phoenix_live_view`. [VERIFIED: terminal commands run 2026-05-26]

## Architecture Patterns

### System Architecture Diagram

```text
Operator edits rollout rule
        |
        v
Draft/publish authored ruleset changeset
(`Ruleset` -> `Rule` -> `Rollout` -> `Guardrails`)
        |
        v
Persisted authored contract in `rulestead`
        |
        v
Later runtime decision path builds explicit `SignalQuery`
(signal identity + threshold contract + environment_key + tenant_key)
        |
        v
Host-provided `SignalProvider` callback
        |
        +--> provider unsupported / query unsupported -> normalized fail-closed `SignalFact`
        |
        +--> signal returned but stale / undersampled -> normalized fail-closed `SignalFact`
        |
        +--> signal returned and current -> normalized `SignalFact`
        |
        v
Phase 50 decision engine compares authored thresholds to normalized facts
        |
        v
Existing governance/audit envelope records bounded evidence and scope
```

The conceptual flow above matches the locked milestone split: Phase 49 owns authored contract and normalization seam only; Phase 50 consumes that contract to make decisions; Phase 51 renders those decisions in mounted UI. [VERIFIED: ROADMAP.md, REQUIREMENTS.md, 49-CONTEXT.md]

### Recommended Project Structure
```text
rulestead/lib/rulestead/
├── rollout/
│   ├── signal_provider.ex      # host-owned behaviour
│   ├── signal_query.ex         # explicit runtime query struct
│   └── signal_fact.ex          # bounded normalized runtime fact struct
├── ruleset/
│   ├── guardrail.ex            # authored guardrail embed
│   ├── guardrail_threshold.ex  # authored threshold embed or helper
│   └── rollout.ex              # add embeds_many :guardrails
└── store/
    └── command.ex              # reuse provenance normalization helpers
```

This structure recommendation is aligned with current repo boundaries but the exact module names remain discretionary. The important constraint is separation between authored embeds under `ruleset/` and runtime seam types under `rollout/`. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/rule.ex; ASSUMED]

### Pattern 1: Embed Guardrails Inside Existing Rollout Authored State
**What:** Add `embeds_many :guardrails` to the existing rollout embed so signal requirements travel with rollout authored truth, draft/publish review, and changeset validation. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/rule.ex]

**When to use:** Use this for every staged rollout rule that can be guarded; do not create a side table or detached runtime-only store for guardrail definitions. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Schema.html
# Adapted to mirror existing `Rulestead.Ruleset.Rule` / `Rollout` patterns.
embedded_schema do
  field :bucket_by, Ecto.Enum, values: [:subject, :account, :tenant, :session]
  field :percentage, :integer
  field :salt, :string

  embeds_many :guardrails, Guardrail, on_replace: :delete
end

def changeset(rollout, attrs) do
  rollout
  |> cast(attrs, [:bucket_by, :percentage, :salt])
  |> cast_embed(:guardrails, with: &Guardrail.changeset/2)
end
```

The `on_replace` and `cast_embed` pattern matches current Ecto guidance and the repo’s existing authored-state code. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex; CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html]

### Pattern 2: Keep Threshold Semantics Fully Authored
**What:** Each guardrail definition should carry its own signal identity, comparator, threshold value, freshness SLA, minimum sample size, and explicit scope expectations as validated fields, not inferred defaults. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md]

**When to use:** Use this for every guardrail definition stored in rollout state, even when the host can derive some fields from its provider configuration. [VERIFIED: 49-CONTEXT.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Enum.html
embedded_schema do
  field :signal_key, :string
  field :comparator, Ecto.Enum, values: [:lt, :lte, :gt, :gte]
  field :threshold_value, :float
  field :max_age_seconds, :integer
  field :min_sample_size, :integer
  field :scope_mode, Ecto.Enum, values: [:environment, :environment_and_tenant]
end
```

The exact enum set is a planning decision, but the bounded-enum pattern itself is already the repo standard and is supported directly by Ecto. [VERIFIED: rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/flag.ex; CITED: https://hexdocs.pm/ecto/Ecto.Enum.html; ASSUMED]

### Pattern 3: Normalize Host Facts Before Any Later Decision Logic
**What:** Put provider-specific wiring behind a host-owned behaviour and make `rulestead` work only with explicit `SignalQuery` and bounded `SignalFact` structs. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-host-app-integration-seam.md]

**When to use:** Use this for all runtime reads of rollout safety signals; do not let provider adapters leak error strings or raw payloads into core decision logic. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-telemetry-observability-and-audit.md]

**Example:**
```elixir
# Source: prompts/rulestead-host-app-integration-seam.md
# Adapted to the repo's existing host-owned seam style.
defmodule Rulestead.Rollout.SignalProvider do
  @callback fetch(Rulestead.Rollout.SignalQuery.t()) ::
              {:ok, Rulestead.Rollout.SignalFact.t()} | {:error, term()}
end
```

The behaviour return can still be normalized at the seam boundary so later phases only see bounded `SignalFact` statuses and reasons. That keeps host ownership of provider details while preserving core determinism. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-security-privacy-and-threat-model.md; ASSUMED]

### Pattern 4: Reuse Existing Scope and Provenance Vocabulary
**What:** Carry `environment_key`, optional `tenant_key`, and a bounded provenance shape derived from `Command.GovernanceSupport` and `AuditEvent.metadata/1` instead of inventing a second scope representation. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/store/command.ex, rulestead/lib/rulestead/audit_event.ex]

**When to use:** Use this in signal query structs, normalized signal facts, and any future audit evidence payloads. [VERIFIED: 49-CONTEXT.md, 29-CONTEXT.md]

**Example:**
```elixir
# Source: rulestead/lib/rulestead/store/command.ex
%{
  tenant_key: tenant_key,
  tenant: %{
    tenant_key: tenant_key,
    scope_source: "explicit",
    validation: %{evidence: "same_tenant_guard", status: "passed"}
  }
}
```

The exact fields above are already normalized today for tenant provenance and should remain the canonical bounded vocabulary. [VERIFIED: rulestead/lib/rulestead/store/command.ex, 29-CONTEXT.md]

### Anti-Patterns to Avoid
- **Raw provider payload persistence:** Do not store provider responses or freeform upstream errors in authored state, audit truth, or stable runtime facts. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-telemetry-observability-and-audit.md, rulestead/lib/rulestead/audit_event.ex]
- **Ambient scope inference:** Do not infer environment or tenant from current session or mounted UI state at evaluation time; require them in the contract seam. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/context.ex, rulestead_admin/lib/rulestead_admin/live/session.ex]
- **Health-by-absence:** Do not treat missing provider support, missing samples, or stale data as healthy. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md]
- **Phase leakage:** Do not build hold/rollback execution, stage windows, or mounted UI semantics in this phase. [VERIFIED: ROADMAP.md, 49-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Nested authored contract validation | Ad-hoc map walkers and manual required-field checks [ASSUMED] | Ecto `embedded_schema`, `cast_embed`, and `Ecto.Enum`. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html; https://hexdocs.pm/ecto/Ecto.Enum.html] | Ecto already handles nested embed lifecycle, bounded enums, and list replacement semantics; the repo uses this pattern heavily today. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex] |
| Scope provenance vocabulary | New custom guardrail scope JSON shape [ASSUMED] | `Command.GovernanceSupport.normalize_tenant_provenance/1` and `with_tenant_provenance/3`. [VERIFIED: rulestead/lib/rulestead/store/command.ex] | Reusing the existing bounded provenance shape avoids a second dialect for tenant/environment truth. [VERIFIED: 29-CONTEXT.md, 49-CONTEXT.md] |
| Durable evidence normalization | A second audit serializer for guardrails [ASSUMED] | `Rulestead.AuditEvent.metadata/1`. [VERIFIED: rulestead/lib/rulestead/audit_event.ex] | The repo already normalizes/redacts bounded metadata here; future guardrail evidence should extend this envelope, not fork it. [VERIFIED: rulestead/lib/rulestead/audit_event.ex, 49-CONTEXT.md] |
| Metrics/provider integration | Core-owned adapters, HTTP clients, credentials, or dashboards [VERIFIED: out-of-scope docs] | Host-owned behaviour configured by the host app. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-host-app-integration-seam.md] | This preserves the locked product boundary and keeps observability truth outside `rulestead`. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md] |

**Key insight:** The hard part of this phase is not fetching a metric; it is freezing a stable contract that later decisions, audit rows, and mounted UI can all trust. Existing Ecto embeds plus current scope/audit helpers are already the right machinery for that job. [VERIFIED: codebase grep; CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html]

## Common Pitfalls

### Pitfall 1: Attaching guardrails outside authored rollout state
**What goes wrong:** Guardrails end up in command metadata, transient runtime config, or a side table that draft/publish review does not clearly own. [VERIFIED: 49-CONTEXT.md]
**Why it happens:** It is tempting to treat rollout safety as “runtime health metadata” instead of authored rollout intent. [ASSUMED]
**How to avoid:** Add guardrails to the existing rollout embed and validate them in the same authored-state changeset path. [VERIFIED: rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/ruleset/rule.ex]
**Warning signs:** Review diffs show rollout changes without guardrail config, or guardrails exist only in runtime config. [ASSUMED]

### Pitfall 2: Letting provider-specific errors become product truth
**What goes wrong:** Later phases have to parse arbitrary strings like `"Datadog query failed"` or `"missing series"` to decide if a rollout is healthy. [ASSUMED]
**Why it happens:** The host seam returns raw provider results and normalization is deferred. [ASSUMED]
**How to avoid:** Normalize all outcomes into a bounded `SignalFact` status/reason vocabulary at the seam boundary. [VERIFIED: 49-CONTEXT.md]
**Warning signs:** Status enums are absent, or tests assert on raw provider message text. [ASSUMED]

### Pitfall 3: Implicit environment or tenant scope
**What goes wrong:** Signal reads silently target the wrong environment or tenant because runtime/session state is assumed rather than carried explicitly. [VERIFIED: 49-CONTEXT.md, 29-CONTEXT.md]
**Why it happens:** Mounted UI state and runtime context are conflated. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex, rulestead/lib/rulestead/context.ex]
**How to avoid:** Require `environment_key` and optional `tenant_key` on the query seam and reuse bounded provenance metadata. [VERIFIED: rulestead/lib/rulestead/context.ex, rulestead/lib/rulestead/store/command.ex]
**Warning signs:** Helper APIs only accept `flag_key` or route params without explicit scope structs. [ASSUMED]

### Pitfall 4: Planning Phase 50 work into Phase 49
**What goes wrong:** The phase grows a decision engine, monitoring windows, or UI status rendering instead of only defining the contract. [VERIFIED: ROADMAP.md]
**Why it happens:** Contract design exposes the needs of later phases, and it is easy to start implementing consumers early. [ASSUMED]
**How to avoid:** Lock only authored fields, query/fact structs, enum vocabularies, and contract tests; defer all action semantics to Phase 50 and display semantics to Phase 51. [VERIFIED: ROADMAP.md, REQUIREMENTS.md]
**Warning signs:** New modules emit `held`/`rollback_triggered` decisions or LiveView copy lands in this phase. [VERIFIED: ROADMAP.md]

## Code Examples

Verified patterns from official sources and current repo conventions:

### Authored Guardrail Embed
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Schema.html
# Shape adapted to current repo patterns in rulestead/lib/rulestead/ruleset/rule.ex
defmodule Rulestead.Ruleset.Guardrail do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :signal_key, :string
    field :comparator, Ecto.Enum, values: [:lt, :lte, :gt, :gte]
    field :threshold_value, :float
    field :max_age_seconds, :integer
    field :min_sample_size, :integer
  end

  def changeset(guardrail, attrs) do
    guardrail
    |> cast(attrs, [:signal_key, :comparator, :threshold_value, :max_age_seconds, :min_sample_size])
    |> validate_required([:signal_key, :comparator, :threshold_value, :max_age_seconds])
  end
end
```

### Nested Rollout Casting
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html
# Pattern mirrored from rulestead/lib/rulestead/ruleset.ex and rule.ex
def changeset(rollout, attrs) do
  rollout
  |> cast(attrs, [:bucket_by, :percentage, :salt])
  |> cast_embed(:guardrails, with: &Guardrail.changeset/2)
end
```

### Mounted LiveView Contract Consumption Later
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
# Use later in Phase 51 to prove mounted screens consume the core contract.
{:ok, view, _html} = live(conn, "/admin/flags/checkout-redesign/rollouts?env=prod")
assert render(view) =~ "Guardrail"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Store nested rollout safety config as loose maps or metadata blobs [ASSUMED] | Model nested contract state with `embedded_schema`, `embeds_one/3`, `embeds_many/3`, and `cast_embed/3`. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html; https://hexdocs.pm/ecto/Ecto.Changeset.html] | Ecto documents this as the standard current pattern; repo already uses it in shipped authored state. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex] | Lower validation drift and cleaner persistence semantics for nested authored state. [VERIFIED: repo code] |
| Hide enum semantics in strings or implicit conventions [ASSUMED] | Use `Ecto.Enum` for bounded authored vocabularies and helper introspection. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] | Present in current Ecto docs and already used across the repo. [VERIFIED: rulestead/lib/rulestead/ruleset/rollout.ex, rulestead/lib/rulestead/flag.ex, rulestead/lib/rulestead/audit_event.ex] | Keeps comparators, statuses, and scope modes bounded and inspectable. [VERIFIED: repo code] |
| Let admin or provider adapters own rollout health semantics [ASSUMED] | Keep provider wiring host-owned and make core consume normalized facts. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-host-app-integration-seam.md] | Locked for this milestone on 2026-05-26 in Phase 49 context and requirements. [VERIFIED: 49-CONTEXT.md, REQUIREMENTS.md] | Preserves sibling-package boundaries and avoids observability-product drift. [VERIFIED: ROADMAP.md, 49-CONTEXT.md] |

**Deprecated/outdated:**
- Treating weak or missing signal data as equivalent to healthy rollout state is explicitly disallowed for this milestone. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md]
- Rulestead-owned metrics ingestion, dashboards, or provider adapters are explicitly out of scope for this phase and milestone. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The minimal authored comparator set for Phase 49 should start with scalar comparators such as `:lt`, `:lte`, `:gt`, and `:gte`. [ASSUMED] | Architecture Patterns / Code Examples | The planner might over- or under-scope threshold semantics, causing rework in Phase 50 if baseline or ratio comparators are required immediately. |
| A2 | `guardrails` should live directly under the existing `Rollout` embed rather than at `Rule` or `Ruleset` top level. [ASSUMED] | Recommended Project Structure / Primary recommendation | The implementation could require a small refactor if planning decides stage or rule semantics need a different nesting point. |
| A3 | The host seam should be a behaviour callback returning normalized fact structs after seam-boundary normalization. [ASSUMED] | Pattern 3 | A different seam shape such as a function module or MFA could be chosen, which would alter task breakdown but not the milestone boundary. |

## Open Questions

1. **What is the smallest comparator vocabulary that satisfies `ROL-01` without leaking Phase 50- or `ROL-05`-style baseline logic?** [VERIFIED: REQUIREMENTS.md]
   - What we know: explicit threshold semantics are required now, while baseline/cohort comparison is deferred to `ROL-05`. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md]
   - What's unclear: whether Phase 49 needs only scalar threshold comparisons or also “delta from baseline” placeholders in the authored contract. [ASSUMED]
   - Recommendation: lock Phase 49 to scalar threshold comparators only unless a specific host integration already requires baseline placeholders. [ASSUMED]

2. **Should normalized fail-closed status be one field or split into `status` plus `reason`?** [VERIFIED: 49-CONTEXT.md]
   - What we know: the vocabulary must distinguish healthy, stale, unsupported, and insufficient-sample style outcomes. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md]
   - What's unclear: whether `status: :unhealthy` with rich `reason` is enough, or if `status` itself should include fail-closed detail such as `:pending_data` or `:unsupported_provider`. [ASSUMED]
   - Recommendation: keep both a coarse status and a bounded reason so Phase 50 decisions and Phase 51 copy can evolve independently without reparsing strings. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core compile and ExUnit contract tests | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: terminal command] | — |
| Mix | Build, test, and doc tooling | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: terminal command] | — |
| Node.js | CI integration lane and companion proof surfaces | ✓ [VERIFIED: `node --version`] | 22.14.0 [VERIFIED: terminal command] | Skip integration lane for Phase 49 local quick runs. [VERIFIED: .github/workflows/ci.yml] |
| npm | CI/demo JS tooling | ✓ [VERIFIED: `npm --version`] | 11.1.0 [VERIFIED: terminal command] | Skip JS/demo proof for core contract iteration. [VERIFIED: .github/workflows/ci.yml] |
| Docker | Demo/integration parity and some full-stack verification paths | ✓ [VERIFIED: `docker --version`] | 29.4.1 [VERIFIED: terminal command] | Use targeted Mix tests for Phase 49 while iterating. [VERIFIED: .github/workflows/ci.yml] |
| PostgreSQL CLI | Full DB-backed suite/debugging | ✓ [VERIFIED: `psql --version`] | 14.17 [VERIFIED: terminal command] | CI provides Postgres 15 service; Phase 49 quick tests can stay pure/unit scoped. [VERIFIED: .github/workflows/ci.yml] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment probe commands]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment probe commands]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.x locally; CI matrix includes Elixir 1.17.3 and 1.19.2. [VERIFIED: elixir --version, .github/workflows/ci.yml] |
| Config file | none detected; repo uses package-local `mix test` plus support helpers under `test/support`. [VERIFIED: codebase grep] |
| Quick run command | `cd rulestead && mix test test/rulestead/ruleset_validation_test.exs test/rulestead/store/command_test.exs test/rulestead/context_test.exs` [VERIFIED: file existence] |
| Full suite command | `scripts/ci/test.sh` [VERIFIED: .github/workflows/ci.yml, scripts/ci/test.sh references] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ROL-01 | Author rollout guardrails with explicit signal, threshold, freshness, sample-size, environment, and tenant semantics, without core-owned observability fetching. [VERIFIED: REQUIREMENTS.md] | unit + contract | `cd rulestead && mix test test/rulestead/rollout/guardrail_contract_test.exs test/rulestead/rollout/signal_provider_contract_test.exs test/rulestead/store/command_guardrail_scope_test.exs -x` [ASSUMED] | ❌ Wave 0 [VERIFIED: `rg --files` output shows these files do not exist] |

### Sampling Rate
- **Per task commit:** `cd rulestead && mix test test/rulestead/ruleset_validation_test.exs test/rulestead/store/command_test.exs test/rulestead/context_test.exs` [VERIFIED: file existence]
- **Per wave merge:** `scripts/ci/test.sh` [VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json enables `nyquist_validation`]

### Wave 0 Gaps
- [ ] `rulestead/test/rulestead/rollout/guardrail_contract_test.exs` — covers authored embed validation and bounded enum semantics for `ROL-01`. [ASSUMED]
- [ ] `rulestead/test/rulestead/rollout/signal_provider_contract_test.exs` — covers fail-closed normalized fact vocabulary and host-owned seam behavior for `ROL-01`. [ASSUMED]
- [ ] `rulestead/test/rulestead/store/command_guardrail_scope_test.exs` — covers tenant/environment provenance reuse and explicit scope carriage for `ROL-01`. [ASSUMED]
- [ ] Optional later-phase reminder only: mounted consumer tests belong in Phase 51, not Phase 49. [VERIFIED: ROADMAP.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: prompt anchors and phase scope] | Host app continues to own identity and credentials. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md, prompts/rulestead-host-app-integration-seam.md] |
| V3 Session Management | no [VERIFIED: phase scope] | Mounted session resolution already exists but Phase 49 should not add session semantics. [VERIFIED: rulestead_admin/lib/rulestead_admin/live/session.ex, ROADMAP.md] |
| V4 Access Control | yes [VERIFIED: explicit environment/tenant scope requirements] | Explicit environment/tenant scope on the signal seam and fail-closed behavior on unsupported scope. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md, 29-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: authored contract phase] | Ecto changesets, `cast_embed`, numeric validation, and `Ecto.Enum` bounded vocabularies. [VERIFIED: rulestead/lib/rulestead/ruleset.ex, rulestead/lib/rulestead/ruleset/rule.ex, rulestead/lib/rulestead/ruleset/rollout.ex; CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html; https://hexdocs.pm/ecto/Ecto.Enum.html] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new crypto should be introduced; provider credentials remain host-owned and out of core. [VERIFIED: 49-CONTEXT.md, prompts/rulestead-security-privacy-and-threat-model.md] |

### Known Threat Patterns for Elixir/Ecto Host-Seam Guardrails

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Provider credentials leaking into core or audit metadata | Information Disclosure | Keep provider wiring host-owned and persist only normalized fact/status data plus bounded provenance. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/audit_event.ex, prompts/rulestead-security-privacy-and-threat-model.md] |
| Cross-tenant or cross-environment signal bleed | Elevation of Privilege / Tampering | Require explicit `environment_key` and optional `tenant_key`; reuse bounded provenance validation and fail closed on mismatch or widening. [VERIFIED: REQUIREMENTS.md, 29-CONTEXT.md, rulestead/lib/rulestead/store/command.ex] |
| Forged “healthy” state from weak or stale data | Tampering | Normalize freshness and sample-size status explicitly and never equate missing or weak data with healthy state. [VERIFIED: REQUIREMENTS.md, 49-CONTEXT.md] |
| Raw provider error strings becoming durable control-plane truth | Repudiation / Integrity | Map runtime/provider failures into bounded enums and reasons before later audit or decision code consumes them. [VERIFIED: 49-CONTEXT.md, rulestead/lib/rulestead/audit_event.ex; ASSUMED] |

## Sources

### Primary (HIGH confidence)
- Context7 `/websites/hexdocs_pm_ecto` - verified Ecto embed and changeset patterns through `ctx7` CLI lookup. [VERIFIED: `npx --yes ctx7@latest library/doc`]
- https://hexdocs.pm/ecto/Ecto.Schema.html - checked `embedded_schema`, `embeds_many/3`, `embeds_one/3`, `on_replace`, and embed primary-key behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html]
- https://hexdocs.pm/ecto/Ecto.Changeset.html - checked `cast_embed/3` requirements and options. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
- https://hexdocs.pm/ecto/Ecto.Enum.html - checked bounded enum and embed serialization guidance. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html]
- https://hexdocs.pm/ecto/embedded-schemas.html - checked current embedded-schema usage guidance. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html]
- https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html - checked current LiveView testing surface for later mounted-contract consumption. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- Local repo code: `rulestead/lib/rulestead/context.ex`, `store/command.ex`, `audit_event.ex`, `ruleset.ex`, `ruleset/rule.ex`, `ruleset/rollout.ex`, `evaluator.ex`, `promotion/apply.ex`, `rulestead_admin/live/session.ex`, `rulestead_admin/live/flag_live/rollouts.ex`. [VERIFIED: codebase grep and file reads]
- Local planning docs: `49-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, `PROJECT.md`, `CLAUDE.md`, prior phase contexts 07/23/29/41. [VERIFIED: file reads]

### Secondary (MEDIUM confidence)
- `mix hex.info ecto` - verified repo-locked Ecto version and current upstream release metadata. [VERIFIED: terminal command]
- `mix hex.info phoenix_live_view` - verified current LiveView release metadata for test-surface planning. [VERIFIED: terminal command]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research avoided unverified web-only claims]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing repo patterns and official Ecto docs point to one clear implementation style with no need for a new dependency. [VERIFIED: rulestead/mix.exs, repo code, Ecto docs]
- Architecture: HIGH - the milestone split, package boundaries, and prior phase contexts all agree that Phase 49 owns contract semantics only. [VERIFIED: ROADMAP.md, REQUIREMENTS.md, 49-CONTEXT.md, prior phase contexts]
- Pitfalls: MEDIUM - the fail-closed and scope pitfalls are well-supported by repo context, while some warning-sign examples are inference from adjacent patterns. [VERIFIED: repo docs and code; ASSUMED where noted]

**Research date:** 2026-05-26 [VERIFIED: current date]
**Valid until:** 2026-06-25 for repo-internal architecture and 2026-06-02 for upstream package-version metadata. [ASSUMED]

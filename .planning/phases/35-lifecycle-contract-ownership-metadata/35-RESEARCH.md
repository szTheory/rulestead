# Phase 35: Lifecycle Contract & Ownership Metadata - Research

**Researched:** 2026-05-23
**Domain:** Elixir/Ecto authored metadata contracts for ownership, lifecycle intent, and bounded audit summaries
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Product shape and milestone discipline
- **D-01:** Phase 35 is a contract-and-metadata phase, not a lifecycle automation phase. It must tighten authored truth and audit semantics without widening the sibling-package release model or moving lifecycle logic into the runtime evaluator.
- **D-02:** Downstream planning should favor one coherent recommendation-heavy implementation path unless a choice would materially change public contract, security/governance posture, milestone scope, or release shape.

### Ownership contract
- **D-03:** Replace the current “freeform owner label as truth” posture with a **bounded host-owned owner reference contract**. Durable truth should be a stable opaque owner reference, not a mutable display string.
- **D-04:** The ownership shape should support at least:
  - a canonical opaque reference such as `owner_ref`
  - a bounded owner kind such as `person`, `team`, or `service`
  - an optional display snapshot for admin readability and exports
- **D-05:** `owner_ref` is the stable value used for filtering, audit continuity, and lifecycle accountability. Any stored display label is advisory only and must not become identity truth.
- **D-06:** Rulestead must not create a user/team directory, must not foreign-key into host tables, and must not require live owner resolution on read or runtime evaluation paths.
- **D-07:** Mounted admin should be able to consume a host-supplied owner picker / validation seam when available, but the core contract must still permit explicit manual entry of the opaque owner reference so the library remains host-friendly.
- **D-08:** Ownership metadata belongs on authored-state, audit, and mounted-admin surfaces only. It is not part of runtime flag evaluation semantics.

### Lifecycle defaults and authored intent
- **D-09:** Lifecycle defaults should be **admin-only suggestions with explicit operator override**, not hidden automatic decisions and not runtime evaluator behavior.
- **D-10:** Persisted lifecycle truth remains explicit authored metadata. Phase 35 should not store computed statuses such as `potentially_stale`, `stale`, `ready_to_archive`, or similar machine opinions as canonical database truth.
- **D-11:** Add a bounded lifecycle-default policy seam for create/edit flows that returns a suggestion, rationale, and whether the operator overrode it.
- **D-12:** Recommended default posture by flag type is:
  - `release`, `experiment`, `migration` → suggest expiring
  - `kill_switch`, `operational`, `permission` → suggest permanent
  - `remote_config` → require explicit operator posture rather than applying a silent default
- **D-13:** Suggested review horizons may be host-configurable, but defaults must stay advisory and previewable. They must never imply auto-archive or false precision.
- **D-14:** Flag type may shape lifecycle suggestions, but it must not become lifecycle truth by itself.

### Projection boundary
- **D-15:** Rulestead should use a **partially normalized authored contract plus derived projections**:
  - authored state stores explicit human-authored lifecycle and ownership facts
  - mounted-admin and reporting surfaces derive lifecycle guidance from those facts plus later evidence signals
- **D-16:** `Rulestead.Admin.Lifecycle` or an equivalent shared projector remains the seam for derived operator guidance. Read models should explain lifecycle posture from authored facts rather than persisting machine status.
- **D-17:** Derived lifecycle guidance must stay independent from the runtime hot path. Evaluation should not depend on cleanup posture, stale classification, owner resolution, or archive-readiness projections.
- **D-18:** Phase 35 must not introduce a projection-refresh subsystem, background recompute job, generated-column scheme, or trigger-based persistence for computed lifecycle states.

### Audit and history shape
- **D-19:** Keep the existing generic audit envelope (`before` / `after` / `diff` / `links` / `context`) as the detailed immutable record.
- **D-20:** Add **bounded first-class transition summaries** for ownership and lifecycle changes inside audit metadata so operators can filter and understand these changes without parsing arbitrary diffs.
- **D-21:** Ownership/lifecycle audit summaries should follow the same design language as existing bounded tenant provenance:
  - enum-heavy, normalized, privacy-bounded
  - generated centrally
  - stable across Ecto, fake, governance, replay, and scheduled execution paths
- **D-22:** Diff remains the canonical detailed change record. Transition summaries are compact queryable hints, not a second competing source of truth.
- **D-23:** Phase 35 must not introduce bespoke per-event audit schema sprawl for every lifecycle mutation. One stable envelope plus bounded summaries is the preferred model.

### Backward-compatibility and operator trust
- **D-24:** Existing freeform owner strings should be treated as compatibility input during migration and normalization, not as the long-term contract.
- **D-25:** Archive and cleanup remain explicit operator actions. Nothing in Phase 35 should imply automatic archival from defaults, owner metadata, or advisory lifecycle projections.

### the agent's Discretion
- Exact module names for owner-contract normalization and lifecycle-default suggestion seams
- Exact field names for ownership metadata, provided there is one canonical opaque reference, one bounded kind, and optional display snapshot semantics
- Exact audit metadata nesting for ownership/lifecycle transition summaries, provided the envelope remains stable and bounded
- Exact mounted-admin copy and control layout for showing suggested lifecycle defaults and override state

### Deferred Ideas (OUT OF SCOPE)
- Full archive-readiness scoring from evaluation evidence and code references — Phase 36
- Mounted-admin lifecycle workbench, filters, and cleanup actions — Phase 37
- Standalone owner directory, host-table associations, or cross-tenant/global ownership dashboards
- Persisted computed lifecycle state or projection-refresh infrastructure
- Auto-archive, auto-cleanup, or any hidden lifecycle mutation based on heuristics
- Broad bespoke audit event schemas per lifecycle action
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-01 | Flags expose first-class ownership and lifecycle metadata that remain explicit across authored-state reads, writes, audit events, and mounted-admin presentation without creating a Rulestead-owned identity directory. | Persist authored ownership and lifecycle facts on `flags`, normalize them through shared command/audit seams, and keep mounted-admin read models derived from authored facts instead of runtime or host-coupled identity lookups. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3] |
</phase_requirements>

## Summary

Phase 35 should stay inside the existing authored-state and audit architecture: replace the current single `owner` string contract with bounded authored ownership metadata, add authored lifecycle intent metadata plus an advisory default seam for admin forms, and keep `Rulestead.Admin.Lifecycle` as the derived projector rather than persisting computed stale/archive-readiness states. The current code already separates authored truth (`Rulestead.Flag`), derived lifecycle projection (`Rulestead.Admin.Lifecycle`), and bounded audit normalization (`Rulestead.AuditEvent.metadata/1`), so the phase should extend those seams instead of introducing a new subsystem. [VERIFIED: codebase grep]

The most implementation-ready fit is an Ecto-authored contract that stores one bounded ownership object and one bounded lifecycle object on `flags`, validates them with Ecto enums/embeds, normalizes legacy `owner` strings into the new shape during migration and command construction, and emits compact audit summaries for ownership/lifecycle transitions inside the existing metadata envelope. Ecto’s embedded schemas and `cast_embed/3` are built for structured nested data with changeset validation, which matches this phase better than ad hoc JSON maps or new relational tables. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3] [VERIFIED: codebase grep]

The derived guidance seam should remain read-only and off the hot path. Ownership lookups, lifecycle default suggestions, and audit summaries belong to authoring/admin/audit flows only; runtime evaluation must not consult them. That posture matches Phase 35 context, the current runtime-vs-admin separation in the repo, and the prompt anchors that keep audit durable, telemetry separate, and admin mutations explicit and previewable. [VERIFIED: codebase grep] [VERIFIED: repo docs]

**Primary recommendation:** Use authored `ownership` and `lifecycle` embeds on `flags`, keep `owner_ref` as the filter/audit key, treat display labels as snapshots only, derive operator guidance in `Rulestead.Admin.Lifecycle`, and add bounded audit transition summaries inside the existing metadata envelope. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Authored ownership contract (`owner_ref`, bounded kind, display snapshot) | Database / Storage | API / Backend | Durable truth belongs on the `flags` authored record; command builders and changesets should normalize it before persistence. [VERIFIED: codebase grep] |
| Advisory lifecycle default suggestion seam | API / Backend | Frontend Server (SSR/LiveView) | Suggestions should be computed centrally for create/edit flows, then rendered in LiveView forms with explicit override state. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html] |
| Derived lifecycle/admin projection | API / Backend | Frontend Server (SSR/LiveView) | `Rulestead.Admin.Lifecycle` already owns derived operator guidance and should remain the shared read-model seam. [VERIFIED: codebase grep] |
| Ownership/lifecycle audit transition summaries | API / Backend | Database / Storage | Summary generation should be centralized in command/audit normalization, then persisted in the append-only audit ledger for query and export. [VERIFIED: codebase grep] |
| Runtime evaluation path isolation | API / Backend | — | The evaluator must stay independent from owner resolution, cleanup posture, and archive-readiness logic. [VERIFIED: repo docs] [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the active source of truth for roadmap and phase execution state. [VERIFIED: codebase grep]
- Treat `prompts/` as the pattern and policy reference set. [VERIFIED: codebase grep]
- Preserve the sibling-package layout; do not collapse work into a single package shape. [VERIFIED: codebase grep]
- Do not create Phase 8-only docs early: `guides/api_stability.md`, `guides/cheatsheet.cheatmd`, and `guides/flows/extending-rulestead.md`. [VERIFIED: codebase grep]
- `rulestead_admin` remains a guarded sibling package; do not introduce standalone publish flow drift. [VERIFIED: codebase grep]
- Prefer narrow, auditable changes and keep root docs honest about the current phase. [VERIFIED: codebase grep]
- Use scripts-first CI surfaces when workflow logic becomes non-trivial. [VERIFIED: codebase grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` / `ecto_sql` | `3.13.5` (published 2025-11-09) | Persist authored ownership/lifecycle metadata with schema validation, embeds, and migrations. | The repo already uses Ecto authoring tables and changesets, and Ecto embedded schemas plus `cast_embed/3` support bounded nested data without adding host-coupled tables. [VERIFIED: codebase grep] [VERIFIED: hex.pm API] [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3] |
| PostgreSQL | Local env `14.17`; current docs `18` | Store authored flag rows and append-only audit metadata. | Existing `flags` and `audit_events` tables already use Postgres maps/JSONB and append-only triggers; expression indexes and JSONB indexing keep bounded audit summaries queryable without bespoke event tables. [VERIFIED: codebase grep] [CITED: https://www.postgresql.org/docs/current/indexes-expressional.html] [CITED: https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING] |
| `phoenix_live_view` | `1.1.28` (published 2026-03-27) | Render create/edit metadata forms and derived detail projections in mounted admin. | The current authoring and detail flows already live in LiveView; form bindings are the correct seam for suggestion + override UX in this phase. [VERIFIED: codebase grep] [VERIFIED: hex.pm API] [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix` | `1.8.5` (published 2026-03-05) | Mounted admin routing and component/form integration. | Reuse for admin route params, policy state, and owner-picker/suggestion rendering; no new framework surface is needed. [VERIFIED: codebase grep] [VERIFIED: hex.pm API] |
| `plug` | `1.19.1` in lockfile | Host-owned integration seam for admin mount/session boundaries. | Use only if Phase 35 needs a host callback or picker plug contract; do not move owner resolution into runtime request handling. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Authored embeds on `flags` | New relational owner tables and FKs | Rejected because Phase 35 explicitly forbids a Rulestead-owned identity directory and host-table coupling. [VERIFIED: repo docs] |
| Derived lifecycle guidance in `Rulestead.Admin.Lifecycle` | Persisted computed lifecycle states on `flags` | Rejected because the phase locks derived status out of durable truth and out of the runtime hot path. [VERIFIED: repo docs] [VERIFIED: codebase grep] |
| Bounded audit summaries inside `metadata` | Bespoke audit table per lifecycle event | Rejected because the repo already uses a generic append-only audit envelope with bounded metadata normalizers. [VERIFIED: codebase grep] |

**Installation:**
```bash
# No new Hex dependencies are recommended for Phase 35.
cd rulestead && mix deps.get
cd ../rulestead_admin && mix deps.get
```

**Version verification:** The current repo lockfiles pin `ecto`/`ecto_sql` `3.13.5`, `phoenix` `1.8.5`, `phoenix_live_view` `1.1.28`, and `plug` `1.19.1`; Hex package publish timestamps were verified via `https://hex.pm/api/packages/<name>`. [VERIFIED: codebase grep] [VERIFIED: hex.pm API]

## Architecture Patterns

### System Architecture Diagram

```text
Mounted admin form
  -> host picker seam or manual owner_ref entry
  -> lifecycle default suggester(flag_type, current_attrs)
  -> command normalizer
  -> Flag changeset / cast_embed
  -> flags row (authored ownership + lifecycle facts)
  -> audit summary builder
  -> audit_events.metadata {before, after, diff, ownership_transition, lifecycle_transition}
  -> read model fetch
  -> Rulestead.Admin.Lifecycle projector
  -> mounted admin detail / list filters

Runtime evaluation
  -> snapshot / evaluator
  -> does NOT read owner metadata, lifecycle defaults, or audit summaries
```

The current code already isolates runtime evaluation from admin lifecycle projection and audit normalization, so Phase 35 should preserve that split. [VERIFIED: codebase grep]

### Recommended Project Structure
```text
rulestead/lib/rulestead/
├── flag.ex                      # top-level schema owns embeds/fields
├── flag/
│   ├── ownership.ex             # embedded_schema + normalization helpers
│   └── lifecycle_metadata.ex    # embedded_schema + authored lifecycle facts
├── admin/
│   ├── lifecycle.ex             # derived projector stays here
│   └── lifecycle_defaults.ex    # advisory suggestion seam for create/edit
├── store/
│   └── command.ex               # shared normalization + compatibility input handling
└── audit_event.ex               # bounded ownership/lifecycle transition summaries
```

This structure matches the repo’s current split between schema, command normalization, admin projection, and audit metadata without widening package boundaries. [VERIFIED: codebase grep]

### Pattern 1: Authored Ownership As Bounded Embedded Metadata
**What:** Persist ownership as a bounded authored object with `owner_ref`, bounded `owner_kind`, and optional `owner_display`, while continuing to accept legacy freeform owner labels as compatibility input during normalization. [VERIFIED: repo docs] [CITED: https://hexdocs.pm/ecto/embedded-schemas.html]

**When to use:** Use for all create/update/read flows that need ownership accountability, filtering, admin display, export, or audit continuity. Do not use it in runtime evaluation. [VERIFIED: repo docs] [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/embedded-schemas.html
defmodule Rulestead.Flag.Ownership do
  use Ecto.Schema
  import Ecto.Changeset

  @kinds [:person, :team, :service]

  embedded_schema do
    field :owner_ref, :string
    field :owner_kind, Ecto.Enum, values: @kinds
    field :owner_display, :string
  end

  def changeset(ownership, attrs) do
    ownership
    |> cast(attrs, [:owner_ref, :owner_kind, :owner_display])
    |> update_change(:owner_ref, &normalize_string/1)
    |> update_change(:owner_display, &normalize_string/1)
    |> validate_required([:owner_ref, :owner_kind])
    |> validate_length(:owner_ref, min: 1, max: 255)
    |> validate_length(:owner_display, max: 255)
  end
end
```

### Pattern 2: Authored Lifecycle Facts Plus Advisory Defaults
**What:** Persist only authored lifecycle facts such as `expected_expiration`, `permanent`, `review_by`, `default_source`, and `default_overridden?`, while computing default suggestions in a dedicated policy module used by admin create/edit flows. [VERIFIED: repo docs] [VERIFIED: codebase grep]

**When to use:** Use on form initialization and on type changes in mounted admin. Suggestions should be previewed, explainable, and explicitly overrideable. [VERIFIED: repo docs] [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html]

**Example:**
```elixir
# Source: phase context + current admin form seam
def suggest(flag_type) do
  case flag_type do
    type when type in [:release, :experiment, :migration] ->
      %{mode: :expiring, rationale: :type_default, suggested_review_days: 30}

    type when type in [:kill_switch, :operational, :permission] ->
      %{mode: :permanent, rationale: :type_default, suggested_review_days: nil}

    :remote_config ->
      %{mode: :explicit_choice_required, rationale: :ambiguous_long_lived_shape}
  end
end
```

### Pattern 3: Bounded Audit Transition Summaries Inside The Existing Envelope
**What:** Keep `before`/`after`/`diff` as canonical audit detail, then add compact summary blocks such as `ownership_transition` and `lifecycle_transition` with bounded enums and normalized values for filtering and timeline comprehension. [VERIFIED: repo docs] [VERIFIED: codebase grep]

**When to use:** Use on every ownership or lifecycle mutation path in Ecto and fake adapters, including governed and scheduled execution paths, so summaries stay adapter-parity-safe. [VERIFIED: repo docs] [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: current audit envelope in rulestead/lib/rulestead/audit_event.ex
%{
  "ownership_transition" => %{
    "changed" => true,
    "previous_ref" => "team-growth",
    "current_ref" => "team-platform",
    "current_kind" => "team"
  },
  "lifecycle_transition" => %{
    "mode_from" => "expiring",
    "mode_to" => "permanent",
    "default_source" => "type_default",
    "overridden" => true
  }
}
```

### Anti-Patterns to Avoid
- **Freeform owner string as durable truth:** The current `owner` string is fine as compatibility input, but not as the long-term identity contract because labels drift and are hard to query safely. [VERIFIED: repo docs] [VERIFIED: codebase grep]
- **Persisted machine lifecycle status:** Do not add `stale`, `potentially_stale`, or `ready_to_archive` columns to `flags`; those are projections for later phases. [VERIFIED: repo docs]
- **Runtime owner resolution:** Do not read host user/team tables or remote APIs from evaluation or snapshot refresh paths. [VERIFIED: repo docs]
- **Diff-only audit filtering:** Do not make operators parse arbitrary diffs to answer “who owns this” or “did lifecycle mode change”; add bounded summaries instead. [VERIFIED: repo docs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Structured nested metadata validation | Open-ended `map` fields with manual string-key validation | Ecto `embedded_schema` + `cast_embed/3` | Ecto already provides nested changeset validation, explicit field contracts, and embed casting semantics. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3] |
| Owner identity system | Rulestead-owned directory, foreign keys into host auth tables, live resolution service | Opaque `owner_ref` + bounded kind + optional display snapshot | The milestone explicitly forbids host identity coupling and runtime owner resolution. [VERIFIED: repo docs] |
| Persisted lifecycle opinions | Columns for stale/archive-readiness machine status | Authored lifecycle facts + derived projector | Phase 35 only owns contract truth, not lifecycle automation. [VERIFIED: repo docs] |
| Audit query model | Separate audit schema per lifecycle action | Existing append-only audit envelope plus bounded summary blocks and indexes | The repo already centralizes audit normalization and append-only persistence. [VERIFIED: codebase grep] |

**Key insight:** The repo already has the right seams; the phase should deepen the contract, not widen the architecture. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating `owner_display` As Identity Truth
**What goes wrong:** Filters, audit continuity, and ownership history break when teams rename themselves or operators reword labels. [VERIFIED: repo docs]
**Why it happens:** Display strings feel convenient, and the current code still uses a single `owner` field everywhere. [VERIFIED: codebase grep]
**How to avoid:** Filter and audit on `owner_ref`; keep `owner_display` snapshot-only and optional. [VERIFIED: repo docs]
**Warning signs:** Query code trims or compares labels directly, or audit summaries only carry display text. [VERIFIED: codebase grep]

### Pitfall 2: Letting Flag Type Become Persisted Lifecycle Truth
**What goes wrong:** `remote_config` and similar flags get forced into the wrong lifetime posture, and later cleanup phases inherit false facts. [VERIFIED: repo docs]
**Why it happens:** Type-based defaults are useful, but they are only suggestions. [VERIFIED: repo docs]
**How to avoid:** Store authored lifecycle facts plus `default_source`/`overridden?`; never infer durable truth from type alone. [VERIFIED: repo docs]
**Warning signs:** Schema writes happen without operator choice for `remote_config`, or there is no persisted override marker. [VERIFIED: repo docs]

### Pitfall 3: Putting Lifecycle Guidance On The Runtime Path
**What goes wrong:** Snapshot/evaluator code starts depending on admin-only metadata, which risks latency and coupling. [VERIFIED: repo docs]
**Why it happens:** It is tempting to reuse lifecycle objects everywhere once they exist on `flags`. [ASSUMED]
**How to avoid:** Restrict lifecycle guidance reads to authoring, list/detail, and audit/reporting code paths. [VERIFIED: repo docs] [VERIFIED: codebase grep]
**Warning signs:** Runtime tests or snapshot builders start reading ownership/lifecycle embeds or audit metadata. [VERIFIED: codebase grep]

### Pitfall 4: Making Audit Summaries A Second Source Of Truth
**What goes wrong:** Summary drift appears between `diff` and summary fields, and adapter parity becomes fragile. [VERIFIED: repo docs]
**Why it happens:** Teams sometimes hand-build summary blocks per callsite. [ASSUMED]
**How to avoid:** Generate summaries centrally from normalized `before`/`after` data in the audit builder. [VERIFIED: codebase grep]
**Warning signs:** Ecto and fake adapters emit different summary shapes or only some write paths produce summaries. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources:

### Embedded Authored Metadata
```elixir
# Source: https://hexdocs.pm/ecto/embedded-schemas.html
schema "flags" do
  embeds_one :ownership, Rulestead.Flag.Ownership, on_replace: :update
  embeds_one :lifecycle, Rulestead.Flag.LifecycleMetadata, on_replace: :update
  field :archived_at, :utc_datetime_usec
  timestamps(type: :utc_datetime_usec)
end
```

### Changeset Casting For Nested Admin Writes
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3
flag
|> cast(attrs, [:description, :tags, :archived_at])
|> cast_embed(:ownership, required: true)
|> cast_embed(:lifecycle, required: true)
```

### LiveView Form Binding For Suggestion + Override UI
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/form-bindings.html
<.form for={@form} phx-change="validate" phx-submit="save">
  <.input field={@form[:owner_ref]} type="text" />
  <.input field={@form[:owner_kind]} type="select" options={@owner_kind_options} />
  <.input field={@form[:review_by]} type="date" />
  <.input field={@form[:default_overridden]} type="checkbox" />
</.form>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Freeform `owner` label as truth | Opaque `owner_ref` as truth, bounded `owner_kind`, optional `owner_display` snapshot | Phase 35 recommendation for `v1.2.0` | Keeps host identity ownership opaque, queryable, and stable across label drift. [VERIFIED: repo docs] |
| `expected_expiration` + `permanent` only, with stale projection mixed into admin classifier | Authored lifecycle facts plus explicit default-source/override metadata, with stale/archive-readiness still derived later | Phase 35 recommendation | Preserves clean authored truth while leaving scoring/guidance to later phases. [VERIFIED: repo docs] [VERIFIED: codebase grep] |
| Diff-only ownership/lifecycle interpretation | Diff remains canonical, but bounded transition summaries make filters and audits queryable | Phase 35 recommendation | Improves operator comprehension without spawning new audit tables. [VERIFIED: repo docs] [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Legacy freeform owner labels as the sole contract: keep only as compatibility input and export/display fallback during migration. [VERIFIED: repo docs] [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Centralized audit-summary generation can reuse the same normalization shape across direct, governed, replay, and scheduled paths with no additional persisted envelope changes beyond `metadata`. [ASSUMED] | Architecture Patterns | Medium: planner may under-scope adapter-specific work if some write paths bypass the shared audit builder. |
| A2 | The repo can add `ownership` and `lifecycle` embeds to `flags` without breaking existing public read payloads if compatibility fields are preserved during transition. [ASSUMED] | Summary | Medium: planner may need an explicit facade-compatibility task if external payload consumers depend on `flag.owner`. |

## Open Questions (RESOLVED)

1. **Should `owner_kind` permit a transitional `:unknown` value during migration?**
   - What we know: The phase requires a bounded kind, but legacy `owner` strings do not encode kind today. [VERIFIED: repo docs] [VERIFIED: codebase grep]
   - What's unclear: Whether migration should force host apps to classify all existing owners immediately. [ASSUMED]
   - **Resolved:** Do not add a long-term `:unknown` enum to the canonical contract. Phase 35 may tolerate missing kind data only as a migration/backfill compatibility state for legacy rows, but new writes and mounted-admin edits must require one bounded kind from `person | team | service`. If a host seam can classify existing rows during migration, use that input; otherwise preserve the migrated row with compatibility read behavior until an operator or host supplies a valid bounded kind. [RESOLVED]

2. **How long should the facade preserve the legacy `owner` field in read payloads?**
   - What we know: Current form, detail, list, and tests all still use `owner` directly. [VERIFIED: codebase grep]
   - What's unclear: Whether any external consumers beyond the mounted admin depend on it. [ASSUMED]
   - **Resolved:** Preserve `flag.owner` through Phase 35 as a compatibility read projection derived from the normalized ownership contract (`owner_display || owner_ref`) and as migration/normalization input only. New writes, filters, audit summaries, and mounted-admin authoring must prefer `owner_ref`, `owner_kind`, and optional display snapshot immediately. Revisit removal only after downstream phases prove all read surfaces and any external consumers against the normalized contract. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Core package changes, tests, migrations | ✓ | Elixir `1.19.5`, Mix `1.19.5` | — [VERIFIED: local command] |
| Erlang/OTP | Build and test runtime | ✓ | `28` | — [VERIFIED: local command] |
| PostgreSQL CLI | Migration/test verification | ✓ | `14.17` | Repo tests can still run through configured DB service if local CLI is unused. [VERIFIED: local command] |
| Docker | Optional integration verification | ✓ | `29.4.1` | Skip container-based checks for Phase 35 if targeted ExUnit coverage is sufficient. [VERIFIED: local command] |
| Node / npm | Admin package tooling and any JS-side checks | ✓ | Node `22.14.0`, npm `11.1.0` | — [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` / OTP `28` [VERIFIED: codebase grep] [VERIFIED: local command] |
| Config file | [rulestead/test/test_helper.exs](/Users/jon/projects/rulestead/rulestead/test/test_helper.exs), [rulestead_admin/test/test_helper.exs](/Users/jon/projects/rulestead/rulestead_admin/test/test_helper.exs) [VERIFIED: codebase grep] |
| Quick run command | `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/admin_contract_test.exs test/rulestead/store_ecto_admin_test.exs test/rulestead/audit_event_governance_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-01 | Authored ownership metadata persists and round-trips through create/update/fetch/list | integration + contract | `cd rulestead && mix test test/rulestead/store_ecto_admin_test.exs test/rulestead/admin_contract_test.exs` | ✅ [VERIFIED: codebase grep] |
| LIF-01 | Advisory lifecycle defaults stay authored/overrideable and do not become runtime truth | unit + LiveView | `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs && cd ../rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs` | ❌ Wave 0 for exact default/override coverage [VERIFIED: codebase grep] |
| LIF-01 | Ownership/lifecycle audit summaries are emitted centrally and adapter-parity-safe | unit + contract | `cd rulestead && mix test test/rulestead/audit_event_governance_test.exs test/rulestead/store/fake_contract_test.exs test/rulestead/store/ecto_contract_test.exs` | ❌ Wave 0 for new summary assertions [VERIFIED: codebase grep] |
| LIF-01 | Legacy freeform owner labels normalize compatibly during migration and command input handling | migration + unit | `cd rulestead && mix test test/rulestead/store/command_test.exs` | ❌ Wave 0 for legacy-owner normalization [VERIFIED: codebase grep] |

### Sampling Rate
- **Per task commit:** `cd rulestead && mix test test/rulestead/admin_lifecycle_test.exs test/rulestead/store_ecto_admin_test.exs` [VERIFIED: codebase grep]
- **Per wave merge:** `cd rulestead && mix test && cd ../rulestead_admin && mix test` [VERIFIED: codebase grep]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps
- [ ] `rulestead/test/rulestead/flag_ownership_metadata_test.exs` — authored embed validation and compatibility normalization coverage. [ASSUMED]
- [ ] `rulestead/test/rulestead/audit_event_lifecycle_summary_test.exs` — bounded ownership/lifecycle summary generation. [ASSUMED]
- [ ] `rulestead_admin/test/rulestead_admin/live/flag_live/form_test.exs` expansion — suggestion rationale and override UX assertions. [VERIFIED: codebase grep] [ASSUMED]
- [ ] `rulestead/test/rulestead/store/command_test.exs` expansion — legacy `owner` input normalization into new metadata contract. [VERIFIED: codebase grep] [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host app remains the identity authority; Phase 35 must not introduce its own identity directory. [VERIFIED: repo docs] |
| V3 Session Management | no | Mounted admin session posture is unchanged in this phase. [VERIFIED: repo docs] |
| V4 Access Control | yes | Reuse existing mounted-admin policy seam for create/edit mutations and owner-picker integration. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Validate ownership and lifecycle embeds through Ecto changesets and bounded enums. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html] [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html] |
| V6 Cryptography | no | No new crypto surface is needed for Phase 35; existing audit integrity posture remains unchanged. [VERIFIED: repo docs] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Host identity coupling through foreign keys or live lookups | Elevation of Privilege / Information Disclosure | Keep `owner_ref` opaque, host-owned, and non-resolved on runtime/read hot paths. [VERIFIED: repo docs] |
| Audit metadata over-collection | Information Disclosure | Persist bounded enums and snapshots only; do not store host session blobs or arbitrary directory data. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
| Hidden lifecycle automation | Tampering | Keep defaults advisory, require explicit operator override, and never auto-archive. [VERIFIED: repo docs] |
| Diff/summary drift in audit trails | Repudiation | Generate bounded summaries centrally from normalized before/after state inside the append-only audit flow. [VERIFIED: codebase grep] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- `rulestead/lib/rulestead/flag.ex` - current authored flag schema still uses freeform `owner`, `expected_expiration`, and `permanent`. [VERIFIED: codebase grep]
- `rulestead/lib/rulestead/admin/lifecycle.ex` - derived lifecycle guidance already lives in a dedicated admin projector. [VERIFIED: codebase grep]
- `rulestead/lib/rulestead/audit_event.ex` - audit metadata envelope and bounded normalization seam. [VERIFIED: codebase grep]
- `rulestead/lib/rulestead/store/command.ex` - existing normalization patterns and bounded tenant provenance design language. [VERIFIED: codebase grep]
- `rulestead/lib/rulestead/store/ecto.ex` - create/update/list/detail/audit integration points and current owner filtering/history behavior. [VERIFIED: codebase grep]
- `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` and `show.ex` - current mounted-admin authoring/detail seams. [VERIFIED: codebase grep]
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-CONTEXT.md` - locked scope and constraints for Phase 35. [VERIFIED: codebase grep]
- `https://hexdocs.pm/ecto/embedded-schemas.html` - official Ecto embedded schema guidance. [CITED: https://hexdocs.pm/ecto/embedded-schemas.html]
- `https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3` - official nested embed casting guidance. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html#cast_embed/3]
- `https://hexdocs.pm/ecto/Ecto.Enum.html` - official bounded enum support. [CITED: https://hexdocs.pm/ecto/Ecto.Enum.html]
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` - official LiveView form binding guidance. [CITED: https://hexdocs.pm/phoenix_live_view/form-bindings.html]
- `https://www.postgresql.org/docs/current/indexes-expressional.html` - official expression index guidance. [CITED: https://www.postgresql.org/docs/current/indexes-expressional.html]
- `https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING` - official JSONB indexing guidance. [CITED: https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING]
- `https://hex.pm/api/packages/ecto`, `https://hex.pm/api/packages/phoenix`, `https://hex.pm/api/packages/phoenix_live_view` - current package versions and publish dates. [VERIFIED: hex.pm API]

### Secondary (MEDIUM confidence)
- `prompts/rulestead-engineering-dna-from-prior-libs.md` - prior-lib recommendation patterns around polymorphic ownership and audit discipline. [VERIFIED: repo docs]
- `prompts/rulestead-telemetry-observability-and-audit.md` - append-only audit and admin mutation posture. [VERIFIED: repo docs]
- `prompts/rulestead-host-app-integration-seam.md`, `prompts/rulestead-security-privacy-and-threat-model.md`, `prompts/rulestead-admin-ux-and-operator-ia.md` - host-owned seam, privacy bounds, and preview/confirm/audit UX expectations. [VERIFIED: repo docs]

### Tertiary (LOW confidence)
- None. [VERIFIED: this research pass]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new library choice is required, versions were verified from lockfiles and Hex API, and the recommended approach stays inside official Ecto/Phoenix/Postgres capabilities. [VERIFIED: codebase grep] [VERIFIED: hex.pm API] [CITED: https://hexdocs.pm/ecto/embedded-schemas.html]
- Architecture: HIGH - the recommendation extends existing repo seams (`Flag`, `Admin.Lifecycle`, `AuditEvent`, `Store.Command`, `Store.Ecto`) and follows locked Phase 35 decisions. [VERIFIED: codebase grep] [VERIFIED: repo docs]
- Pitfalls: MEDIUM - most are strongly implied by repo constraints and current code shape, but some adapter-drift and compatibility risk details remain assumption-backed until implementation proves every path. [VERIFIED: codebase grep] [ASSUMED]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22

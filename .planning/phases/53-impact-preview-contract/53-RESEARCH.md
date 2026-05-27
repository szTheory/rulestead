# Phase 53: Impact Preview Contract - Research

**Researched:** 2026-05-27 [VERIFIED: gsd-sdk init.phase-op 53]
**Domain:** Elixir/Ecto reusable audience impact-preview contracts, stale-resistant mutation confirmation, runtime snapshot determinism, audit evidence [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
**Confidence:** HIGH for repo-local architecture and test strategy; MEDIUM for exact new API names until planning locks them [VERIFIED: repo grep; ASSUMED]

## User Constraints

- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: AGENTS.md]
- Keep Phase 8-only docs absent until the roadmap says they ship. [VERIFIED: AGENTS.md]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: AGENTS.md]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: AGENTS.md]
- Make the smallest coherent change that satisfies the active plan. [VERIFIED: AGENTS.md]
- Avoid speculative features from future phases. [VERIFIED: AGENTS.md]
- Preserve reproducibility and CI readability. [VERIFIED: AGENTS.md]
- Current phase is Phase 53: Impact Preview Contract, with requirements IMP-01 through IMP-04. [VERIFIED: .planning/STATE.md; .planning/ROADMAP.md]
- Phase 53 depends on Phase 52, but `.planning/phases/52-compilation-safety-contract/52-CONTEXT.md` and `52-SUMMARY.md` were not present in this checkout. [VERIFIED: shell test -f]
- Runtime evaluation must not perform live database, mounted-admin, host identity, or observability lookups to resolve audience references. [VERIFIED: .planning/ROADMAP.md; .planning/REQUIREMENTS.md]
- Previews must be authored-state and explicit-sample based, and must not imply Rulestead owns identity, tenant catalog, observability, or authoritative affected-user counts. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md]

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| IMP-01 | Operators can request a reusable audience impact preview that reports environment scope, tenant scope, referenced flags/rulesets, active rollout or lifecycle context, preview basis, uncertainty, and redacted sample evidence without claiming Rulestead owns identity or observability truth. [VERIFIED: .planning/REQUIREMENTS.md] | Add a core preview module and store command that derive referenced flags/rulesets from authored state and explicit samples, using existing redaction and lifecycle/rollout payload patterns. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/admin/redaction.ex; rulestead/lib/rulestead/store/ecto.ex] |
| IMP-02 | Audience edits, archive/delete attempts, and protected shared-targeting mutations require a stale-resistant preview token or fingerprint before apply, and stale, missing, archived, incompatible, or tenant-mismatched references fail closed with actionable reasons. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the compare-token/fingerprint pattern from promotion and manifest import, but scope it to audience mutation preview basis and affected-reference summary. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex] |
| IMP-03 | Runtime snapshots continue to compile reusable audience definitions for local deterministic evaluation, and runtime evaluation never performs live database, mounted-admin, host identity, or observability lookups to resolve audience references. [VERIFIED: .planning/REQUIREMENTS.md] | Runtime snapshots are currently payload binaries built at publish time, and evaluator code only consumes in-memory flag payload and normalized context; Phase 53 should extend snapshot payloads with compiled audience definitions rather than runtime reads. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/runtime/snapshot.ex; rulestead/lib/rulestead/evaluator.ex] |
| IMP-04 | Audit events for accepted, blocked, or denied audience mutations include preview fingerprint, affected-reference summary, actor, reason, environment scope, tenant scope, and support-safe evidence needed to reconstruct the decision. [VERIFIED: .planning/REQUIREMENTS.md] | Existing audit rows carry actor, reason, result, environment key, metadata, tenant provenance, and denied-write evidence; Phase 53 should add audience mutation event types and structured metadata fields. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead/test/rulestead/admin_security_contract_test.exs] |

</phase_requirements>

## Summary

Phase 53 should be planned as a core contract phase in `rulestead`, not a mounted-admin UI phase. [VERIFIED: .planning/REQUIREMENTS.md; .planning/research/STACK.md] The repo already has reusable `Audience` rows, `segment_match` rules with `audience_key`, promotion compare fingerprints, manifest dependency blockers, runtime snapshot payloads, audit events, admin authorization, and redaction helpers. [VERIFIED: rulestead/lib/rulestead/audience.ex; rulestead/lib/rulestead/ruleset/rule.ex; rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/runtime/snapshot.ex; rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/admin/redaction.ex]

The main gap is that audiences are currently listable but not first-class mutable resources in the public/store command surface. [VERIFIED: rulestead/lib/rulestead/store.ex; rulestead/lib/rulestead/store/command.ex; rulestead/lib/rulestead.ex] Planning should add audience preview/apply commands, a pure impact-preview contract module, Ecto/Fake adapter implementations, fail-closed validation, snapshot compilation of audience definitions, and audit evidence. [VERIFIED: repo grep; ASSUMED] Do not plan standalone admin publishing, new observability backends, host identity lookups, graph libraries, or authoritative population counts. [VERIFIED: AGENTS.md; .planning/REQUIREMENTS.md; .planning/research/STACK.md]

**Primary recommendation:** Implement `Rulestead.Targeting.ImpactPreview` and audience mutation store commands that reuse `Compare.fingerprint/1`-style stale resistance, then wire Ecto/Fake adapters, runtime snapshot compilation, and audit tests before any UI work. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; .planning/research/STACK.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Audience impact preview semantics | API / Backend (`rulestead`) | Database / Storage | Core owns authored-state semantics, preview fingerprints, dependency summaries, redaction basis, and fail-closed errors. [VERIFIED: .planning/REQUIREMENTS.md; .planning/research/STACK.md] |
| Preview confirmation before audience mutation | API / Backend (`rulestead`) | Database / Storage | Mutations already flow through store commands, authorization, Ecto.Multi, and audit rows. [VERIFIED: rulestead/lib/rulestead.ex; rulestead/lib/rulestead/store/ecto.ex] |
| Runtime audience resolution | API / Backend runtime snapshot/evaluator | CDN / Static none | Evaluation currently consumes compiled in-memory snapshot data, so audience definitions must be compiled into snapshots and resolved locally. [VERIFIED: rulestead/lib/rulestead/runtime/snapshot.ex; rulestead/lib/rulestead/evaluator.ex] |
| Audit reconstruction | Database / Storage | API / Backend (`rulestead`) | Audit rows persist actor, result, metadata, tenant evidence, and correlation fields; new audience evidence belongs in the same ledger. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; rulestead/lib/rulestead/store/ecto.ex] |
| Mounted operator presentation | Browser / Client via `rulestead_admin` | API / Backend | Phase 53 should expose core truth; mounted UI rendering is Phase 55 per roadmap. [VERIFIED: .planning/ROADMAP.md] |

## Project Constraints (from AGENTS.md)

- Rulestead is a sibling-package monorepo with `rulestead/` and `rulestead_admin/`. [VERIFIED: AGENTS.md]
- `.planning/` and `prompts/` are ground truth inputs for roadmap, state, requirements, and engineering DNA. [VERIFIED: AGENTS.md]
- Phase 53 work must stay within the Phase 53 boundary and avoid future-phase features. [VERIFIED: AGENTS.md; .planning/ROADMAP.md]
- Do not publish or prepare `rulestead_admin`; keep the linked-version, two-package model intact. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 installed; project constraint `~> 1.17` | Core domain modules, command structs, ExUnit tests | Existing package is Elixir and declares `elixir: "~> 1.17"`. [VERIFIED: elixir --version; mix --version; rulestead/mix.exs] |
| Ecto / Ecto SQL | locked `ecto_sql 3.13.5`, `ecto 3.13.5` | Transactional audience mutation, audit insert, snapshot publish | Existing store adapter uses Ecto schemas, queries, and `Ecto.Multi`; official Ecto docs define `Ecto.Multi` as grouping Repo operations for transactions and introspection. [VERIFIED: mix deps; rulestead/lib/rulestead/store/ecto.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Postgrex | locked `0.22.2` | Ecto Postgres adapter in tests/reference store | Existing Repo/test setup uses Ecto SQL and Postgrex. [VERIFIED: mix deps; rulestead/test/test_helper.exs] |
| Jason | locked `1.4.5` | Manifest/import/export JSON contracts | Existing manifest modules normalize JSON-compatible maps and package depends on Jason. [VERIFIED: mix deps; rulestead/lib/rulestead/manifest/export.ex] |
| Telemetry | locked `1.4.2` | Preview/audit-adjacent operational events | Existing store/runtime code emits `[:rulestead, :runtime, :snapshot, :published]` and release tests lock telemetry event naming. [VERIFIED: mix deps; rulestead/lib/rulestead/store/ecto.ex; rulestead/test/rulestead/release_contract_test.exs] |
| StreamData / ExUnit | StreamData locked `1.1.2`; ExUnit from Elixir | Determinism/property tests | Existing test suite already includes property-style tests and StreamData dependency. [VERIFIED: mix deps; rulestead/test/rulestead/evaluator_property_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix LiveView | not a `rulestead` dependency in this package; prior milestone research says admin uses LiveView 1.1.30 | Mounted preview UI later | Phase 53 should not implement mounted UI; Phase 55 can use LiveView async primitives if needed. [VERIFIED: rulestead/mix.exs; .planning/research/STACK.md; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Redix | locked `1.5.3` | Redis snapshot distribution | Do not use for preview truth; Redis adapter only fetches snapshots and rejects admin mutation callbacks as unsupported. [VERIFIED: mix deps; rulestead/lib/rulestead/store/redis.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Core pure module plus Ecto/Fake commands | Mounted LiveView computes impact | Wrong tier: UI would own domain semantics and tests would miss non-UI mutation paths. [VERIFIED: .planning/research/STACK.md; .planning/ROADMAP.md] |
| `Compare.fingerprint/1`-style deterministic hashes | Random opaque DB-stored tokens only | Random tokens prove possession but not semantic freshness unless tied to preview basis; existing compare tokens bind source/target fingerprints and dependency closure. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| Store/query reference inventory | Ad hoc scan of all ruleset JSON on every preview | Existing research recommends indexed/domain-owned dependency truth because repeated JSON scans are brittle and expensive for operator screens. [VERIFIED: .planning/research/STACK.md] |
| Runtime DB lookup for audience definition | Live lookup by `audience_key` during evaluation | Violates IMP-03 and the runtime snapshot design. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/runtime/snapshot.ex] |

**Installation:** No new dependency is recommended for Phase 53. [VERIFIED: .planning/research/STACK.md; rulestead/mix.exs]

```bash
cd rulestead
mix deps.get
```

**Version verification:** Versions above were verified with `mix deps`, `elixir --version`, and `mix --version` on 2026-05-27. [VERIFIED: shell commands]

## Architecture Patterns

### System Architecture Diagram

```text
Operator/Core caller
  -> Rulestead.preview_audience_impact(command)
    -> Admin policy/read authorization
    -> Authored audience + referencing flags/rulesets query
    -> ImpactPreview.build(before_definition, after_definition, explicit_samples)
      -> Redact sample evidence
      -> Compute affected-reference summary
      -> Compute preview fingerprint/token from scope + before/after + references + samples
    <- Preview payload with uncertainty and blockers

Operator/Core caller
  -> Rulestead.apply_audience_mutation(command with preview_fingerprint/token)
    -> Admin write authorization
    -> Rebuild current preview basis
    -> Decision: token/fingerprint fresh?
      -> no: denied/blocked audit + fail-closed error
      -> yes: Ecto.Multi / Fake transaction
        -> update/archive/delete audience authored state
        -> insert audit event with preview fingerprint + affected references
        -> publish runtime snapshot with compiled audience definitions
    <- accepted/blocked/denied result

Runtime evaluate(flag_key, context)
  -> Runtime.Cache / Runtime.Snapshot compiled payload
  -> Evaluator resolves segment_match from snapshot-local audience definitions
  -> Result/debug trace
```

All runtime data flow must terminate at the compiled snapshot and context; it must not branch to Ecto, `rulestead_admin`, host identity, or observability providers. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/runtime/snapshot.ex; rulestead/lib/rulestead/evaluator.ex]

### Recommended Project Structure

```text
rulestead/lib/rulestead/
├── targeting/
│   ├── impact_preview.ex       # pure preview contract, fingerprint, redaction, uncertainty
│   └── audience_dependencies.ex # affected-reference discovery and summary helpers
├── store/command.ex            # PreviewAudienceImpact / ApplyAudienceMutation / ArchiveAudience commands
├── store.ex                    # new store callbacks
├── store/ecto.ex               # transactional Ecto implementation and audit writes
├── fake.ex                     # Fake adapter parity for contract tests
├── runtime/snapshot.ex         # compiled audience definitions schema validation
├── evaluator.ex                # snapshot-local segment_match resolution
└── audit_event.ex              # metadata normalization for preview/audience evidence

rulestead/test/rulestead/
├── targeting/impact_preview_test.exs
├── store/audience_impact_contract_test.exs
├── store/ecto_audience_impact_contract_test.exs
├── runtime/audience_snapshot_test.exs
└── audience_mutation_audit_test.exs
```

This structure follows the existing split between pure domain helpers, command structs, `Store` callbacks, `Store.Ecto`, `Fake`, runtime compilation, and contract tests. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/store/command.ex; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/fake.ex; rulestead/test/rulestead/store/compare_contract_test.exs]

### Pattern 1: Preview Fingerprint Mirrors Promotion Compare

**What:** Build a deterministic token from schema version, environment scope, tenant scope, audience key, before definition fingerprint, after definition fingerprint, affected-reference keys, explicit sample digest, and preview basis. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; ASSUMED]

**When to use:** Use for every audience edit, archive/delete attempt, and protected shared-targeting mutation. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: rulestead/lib/rulestead/promotion/compare.ex
def preview_fingerprint(attrs) do
  token_payload = %{
    schema_version: @schema_version,
    environment_key: normalize_string(attrs[:environment_key]),
    tenant_key: normalize_string(attrs[:tenant_key]),
    audience_key: normalize_string(attrs[:audience_key]),
    before_fingerprint: fingerprint(attrs[:before_definition]),
    after_fingerprint: fingerprint(attrs[:after_definition]),
    affected_reference_keys: normalize_string_list(attrs[:affected_reference_keys]),
    sample_fingerprint: fingerprint(attrs[:redacted_samples] || [])
  }

  "audprev_" <> hash_term(token_payload)
end
```

The exact module/function names are planning recommendations, but the hashing convention is already used by `Rulestead.Promotion.Compare`. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; ASSUMED]

### Pattern 2: Transactional Apply with Audit

**What:** Use the existing `Ecto.Multi` shape: revalidate current state, perform mutation, insert audit event, and publish/update snapshot in one store operation. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**When to use:** Use when an audience mutation has a fresh preview token and no blockers. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: rulestead/lib/rulestead/store/ecto.ex and Ecto.Multi docs
Multi.new()
|> Multi.run(:preview, fn repo, _changes ->
  build_current_audience_preview(repo, command)
end)
|> Multi.run(:staleness, fn _repo, %{preview: preview} ->
  validate_preview_token(command.preview_token, preview.preview_token)
end)
|> Multi.update(:audience, Audience.changeset(audience, command.attrs))
|> Multi.insert(:audit_event, audience_audit_changeset(command, preview))
|> Multi.run(:runtime_snapshot, fn repo, _changes ->
  insert_runtime_snapshot(repo, environment, DateTime.utc_now())
end)
|> Repo.transact()
```

The repo currently uses `Repo.transact()` with `Ecto.Multi` for publish, archive, promotion, manifest import, and audit operations. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]

### Pattern 3: Snapshot-Local Runtime Resolution

**What:** Compile audience definitions into the runtime snapshot payload and have `Evaluator` resolve `segment_match` rules from that payload only. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/evaluator.ex]

**When to use:** Required for IMP-03 and for deterministic evaluation proof. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: current snapshot payload builder in rulestead/lib/rulestead/store/ecto.ex
%{
  schema_version: @snapshot_schema_version + 1,
  environment_key: environment.key,
  generated_at: now(),
  audiences: compiled_audience_definitions,
  flags: flags
}
```

Current snapshots include `schema_version`, `environment_key`, `generated_at`, and `flags`; Phase 53 should add an `audiences` map only if runtime evaluator support lands in the same phase. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; ASSUMED]

### Anti-Patterns to Avoid

- **UI-owned impact math:** Mounted admin should render core truth, not compute affected references or token freshness. [VERIFIED: .planning/research/STACK.md]
- **Live audience DB lookup in evaluator:** Runtime must remain snapshot-local and deterministic. [VERIFIED: .planning/REQUIREMENTS.md]
- **False population precision:** Preview should label explicit sample evidence and uncertainty instead of claiming total affected users. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md]
- **Token that ignores tenant/environment scope:** Same audience key across scopes must not confirm a mutation in the wrong environment or tenant. [VERIFIED: .planning/REQUIREMENTS.md]
- **Telemetry as audit:** Telemetry can be lossy; audit is durable evidence. [VERIFIED: prompts/rulestead-telemetry-observability-and-audit.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transaction orchestration | Custom partial transaction state machine | `Ecto.Multi` and existing `Repo.transact()` pattern | Existing store writes already use Multi and audit in one envelope. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Redaction | New recursive scrubber in preview module | `Rulestead.Admin.Redaction` plus `AuditEvent.metadata/1` context scrubbing | Repo already has allowlist-driven admin redaction and audit context sensitive-key dropping. [VERIFIED: rulestead/lib/rulestead/admin/redaction.ex; rulestead/lib/rulestead/audit_event.ex] |
| Staleness hashing | New token algorithm unrelated to promotion | `Compare.fingerprint/1` / `compare_token/1` pattern copied into audience preview domain | Existing compare token binds scope, dependencies, and fingerprints. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| Dependency findings | Free-form strings only | Existing finding map shape with severity/class/code/message/metadata | Promotion and manifest already expose blocker/warning/info findings. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/result.ex] |
| Runtime audience resolution | Database, mounted-admin, host identity, or observability lookup | Compiled snapshot audience map | Required by IMP-03. [VERIFIED: .planning/REQUIREMENTS.md] |
| Authoritative affected-user counts | Metrics ingestion or identity graph | Explicit redacted sample evidence plus uncertainty labels | Host owns identity and observability truth. [VERIFIED: .planning/STATE.md; prompts/rulestead-security-privacy-and-threat-model.md] |

**Key insight:** The deceptively hard part is not rendering a preview; it is making the preview basis, apply freshness, runtime snapshot content, and audit evidence all describe the same scoped authored state. [VERIFIED: .planning/REQUIREMENTS.md; .planning/research/STACK.md]

## Common Pitfalls

### Pitfall 1: Preview Token Not Bound to Scope
**What goes wrong:** A token generated for staging, a different tenant, or a prior reference set accidentally confirms a production/shared mutation. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Token payload omits environment, tenant, dependency closure, or before/after fingerprints. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex]
**How to avoid:** Include environment key, tenant key, audience key, affected references, before/after fingerprints, preview basis, and sample digest in the token payload. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; ASSUMED]
**Warning signs:** Tests only assert token exists, not that it changes when scope or references change. [ASSUMED]

### Pitfall 2: Runtime Still Treats `segment_match` as a Plain Forced Value
**What goes wrong:** Audience definitions appear to be compiled, but runtime evaluator still ignores audience definition criteria and matches segment rules solely on inline conditions. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**Why it happens:** Existing `Evaluator` treats `:segment_match` like `:forced_value` after evaluating rule conditions. [VERIFIED: rulestead/lib/rulestead/evaluator.ex]
**How to avoid:** Plan explicit evaluator tests where a `segment_match` rule references a compiled audience definition and match/miss changes when context changes. [VERIFIED: rulestead/test/support/store_fixtures.ex; ASSUMED]
**Warning signs:** Snapshot contains `audiences`, but evaluator tests pass without changing any audience criteria. [ASSUMED]

### Pitfall 3: Audit Evidence Is Too Sparse
**What goes wrong:** Support can see an audience was changed but cannot reconstruct why it was accepted, blocked, or denied. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Existing `audit_metadata/3` for standard flag operations only allowlists a small set of command metadata fields. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex]
**How to avoid:** Add audience-specific audit metadata normalization for preview fingerprint, affected-reference summary, explicit scope, redacted sample evidence, blocker findings, and reason. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; ASSUMED]
**Warning signs:** Tests assert row count/event type but not metadata keys. [VERIFIED: rulestead/test/rulestead/admin_security_contract_test.exs]

### Pitfall 4: Preview Claims Zero Impact When Evidence Is Missing
**What goes wrong:** Operators read missing sample data or hidden references as no blast radius. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Preview payload does not distinguish authored-reference impact from explicit-sample impact. [VERIFIED: .planning/REQUIREMENTS.md; .planning/STATE.md]
**How to avoid:** Include `preview_basis`, `uncertainty`, `sample_evidence.status`, and findings for unavailable/hidden evidence. [VERIFIED: .planning/REQUIREMENTS.md; ASSUMED]
**Warning signs:** Preview payload has only counts and no basis/uncertainty fields. [ASSUMED]

### Pitfall 5: Redis Adapter Accidentally Becomes a Mutation Surface
**What goes wrong:** A runtime snapshot adapter is asked to apply audience mutations. [VERIFIED: rulestead/lib/rulestead/store/redis.ex]
**Why it happens:** Store callback additions are not explicitly unsupported in Redis. [VERIFIED: rulestead/lib/rulestead/store/redis.ex]
**How to avoid:** Add new callbacks to `Store.Redis` unsupported list if the behavior expands. [VERIFIED: rulestead/lib/rulestead/store/redis.ex; ASSUMED]
**Warning signs:** `Rulestead.Store.Redis` fails behavior compilation after callbacks are added. [ASSUMED]

## Code Examples

### Existing Compare Token Shape

```elixir
# Source: rulestead/lib/rulestead/promotion/compare.ex
token_payload = %{
  schema_version: @schema_version,
  source_environment_key: normalize_string(attrs[:source_environment_key]),
  target_environment_key: normalize_string(attrs[:target_environment_key]),
  tenant_key: normalize_string(attrs[:tenant_key]),
  compared_flag_keys: normalize_string_list(attrs[:compared_flag_keys]),
  dependency_closure_keys: normalize_string_list(attrs[:dependency_closure_keys]),
  source_fingerprint: attrs[:source_fingerprint],
  target_fingerprint: attrs[:target_fingerprint]
}
```

Use this as the model for audience preview freshness, replacing source/target environment compare fields with audience mutation basis fields. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; ASSUMED]

### Existing Audit Metadata Normalization

```elixir
# Source: rulestead/lib/rulestead/audit_event.ex
%{
  "before" => before,
  "after" => after_map,
  "diff" => diff,
  "links" => normalize_map(attrs[:links]),
  "context" => context
}
|> maybe_put("tenant", tenant)
|> maybe_put("request_id", attrs[:request_id])
```

Audience mutation audit should extend this metadata style rather than store opaque preview blobs. [VERIFIED: rulestead/lib/rulestead/audit_event.ex; ASSUMED]

### Existing Runtime Snapshot Payload

```elixir
# Source: rulestead/lib/rulestead/store/ecto.ex
%{
  schema_version: @snapshot_schema_version,
  environment_key: environment.key,
  generated_at: now(),
  flags: flags
}
```

Phase 53 should bump the snapshot schema if it adds compiled audience definitions used by runtime evaluation. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; ASSUMED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `segment_match` rules carry an `audience_key` but runtime evaluation treats segment rules like forced values after inline condition checks. [VERIFIED: rulestead/lib/rulestead/ruleset/rule.ex; rulestead/lib/rulestead/evaluator.ex] | Compile audience definitions into snapshots and resolve locally in evaluator. [VERIFIED: .planning/REQUIREMENTS.md; ASSUMED] | Phase 53 planning target. [VERIFIED: .planning/ROADMAP.md] | Required to satisfy IMP-03 and avoid live lookup drift. [VERIFIED: .planning/REQUIREMENTS.md] |
| Promotion/manifest have dependency/staleness contracts; audience mutation does not. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; rulestead/lib/rulestead/manifest/import.ex; rulestead/lib/rulestead/store.ex] | Audience mutation preview/apply should become a first-class store contract. [ASSUMED] | Phase 53 planning target. [VERIFIED: .planning/ROADMAP.md] | Required for IMP-01, IMP-02, and IMP-04. [VERIFIED: .planning/REQUIREMENTS.md] |
| Audit rows exist for flag/ruleset/kill-switch/governance operations. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex; rulestead/lib/rulestead/audit_event.ex] | Add accepted/blocked/denied audience mutation audit rows with preview evidence. [ASSUMED] | Phase 53 planning target. [VERIFIED: .planning/ROADMAP.md] | Support can reconstruct audience decisions. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:** Do not plan runtime live DB lookups, standalone admin workflows, graph visualizers, or authoritative affected-user counts for this phase. [VERIFIED: .planning/REQUIREMENTS.md; .planning/research/STACK.md; AGENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | New public/store API names such as `preview_audience_impact` and `apply_audience_mutation` are recommendations, not existing names. | Summary, Project Structure, Patterns | Planner may need to choose different names to match API stability conventions. |
| A2 | Snapshot schema should be bumped if compiled audience definitions are added. | Pattern 3, Code Examples | If a prior phase already reserved schema semantics elsewhere, planner must align with that artifact. |
| A3 | Audience mutation should be implemented in Phase 53 rather than deferred to a later UI phase. | Summary, State of the Art | If user intended only a contract document, implementation plan would be too broad. |
| A4 | An indexed audience reference table is probably needed for scalable dependency queries, but Phase 53 may use a pure derived query if planning keeps scope smaller. | Standard Stack, Don't Hand-Roll | Over-planning a migration could exceed smallest coherent change. |

## Open Questions (RESOLVED)

1. **Should Phase 53 include a database migration for audience reference inventory, or defer normalized inventory to Phase 54?** [RESOLVED]
   - Decision: Phase 53 does not include a reference-index migration unless implementation later proves one is essential for correctness. Plans assume affected references are derived from authored flag/ruleset state with pure helpers and adapter-local queries. [VERIFIED: 53-01-PLAN.md; 53-04-PLAN.md]
   - Rationale: Phase 54 explicitly owns dependency truth and promotion safety, while Phase 53 needs a preview/audit contract over current authored state. This avoids duplicating Phase 54 normalized inventory work. [VERIFIED: .planning/ROADMAP.md]

2. **What exact audience mutation operations are in scope: edit, archive, delete, or all three?** [RESOLVED]
   - Decision: Edit and archive are implemented operations. Delete attempts are represented in the command/preview contract but fail closed with an unsupported/actionable error unless existing product code already exposes a delete primitive. [VERIFIED: 53-03-PLAN.md; 53-04-PLAN.md]
   - Rationale: Requirements name archive/delete attempts, but the current audience schema has `archived_at` and no public delete command. Fail-closed unsupported delete behavior satisfies the safety contract without inventing destructive semantics. [VERIFIED: rulestead/lib/rulestead/audience.ex; rulestead/lib/rulestead/store.ex]

3. **How should explicit sample evidence be supplied?** [RESOLVED]
   - Decision: Sample evidence is caller-supplied through explicit `samples` fields on preview commands only. Samples are redacted with existing `Rulestead.Admin.Redaction` and/or `Rulestead.AuditEvent.metadata/1` scrubbing patterns before appearing in preview or audit payloads. [VERIFIED: 53-01-PLAN.md; 53-03-PLAN.md; 53-04-PLAN.md]
   - Rationale: Rulestead must not own identity or observability truth. Missing samples degrade to authored-reference-only uncertainty rather than zero-impact claims. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/test core package | yes | 1.19.5 | Project supports `~> 1.17`; use installed runtime. [VERIFIED: elixir --version; rulestead/mix.exs] |
| Mix | Dependency/test commands | yes | 1.19.5 | None needed. [VERIFIED: mix --version] |
| Ecto/Postgrex deps | Ecto contract tests | yes in deps | `ecto_sql 3.13.5`, `postgrex 0.22.2` | Fake adapter tests can cover pure command behavior if DB unavailable. [VERIFIED: mix deps; rulestead/test/test_helper.exs] |
| Redis/Redix | Runtime snapshot adapter tests only | dependency present | `redix 1.5.3` | Do not require Redis for Phase 53 contract tests. [VERIFIED: mix deps; rulestead/lib/rulestead/store/redis.ex] |

**Missing dependencies with no fallback:** None found for planning Phase 53. [VERIFIED: shell probes]

**Missing dependencies with fallback:** Live Phoenix admin runtime is not a `rulestead` package dependency; Phase 53 should stay core and leave mounted UI to Phase 55. [VERIFIED: rulestead/mix.exs; .planning/ROADMAP.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit from installed Elixir 1.19.5; StreamData locked 1.1.2 for property tests. [VERIFIED: elixir --version; mix deps] |
| Config file | `rulestead/test/test_helper.exs` starts ExUnit, Repo sandbox, Fake store, and default admin policy. [VERIFIED: rulestead/test/test_helper.exs] |
| Quick run command | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs test/rulestead/store/audience_impact_contract_test.exs` [ASSUMED] |
| Full suite command | `cd rulestead && mix test` [VERIFIED: existing Mix project/test layout] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| IMP-01 | Preview reports environment/tenant scope, referenced flags/rulesets, rollout/lifecycle context, preview basis, uncertainty, and redacted sample evidence. [VERIFIED: .planning/REQUIREMENTS.md] | unit + contract | `cd rulestead && mix test test/rulestead/targeting/impact_preview_test.exs` | No, Wave 0. [VERIFIED: find rulestead/test] |
| IMP-02 | Apply fails closed without fresh preview fingerprint/token and blocks stale/missing/archived/incompatible/tenant-mismatched references. [VERIFIED: .planning/REQUIREMENTS.md] | store adapter contract | `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs` | No, Wave 0. [VERIFIED: find rulestead/test] |
| IMP-03 | Runtime evaluator resolves audience references from compiled snapshot only and does not perform live store/admin/host/observability lookups. [VERIFIED: .planning/REQUIREMENTS.md] | runtime/unit + regression | `cd rulestead && mix test test/rulestead/runtime/audience_snapshot_test.exs test/rulestead/evaluator_test.exs` | `evaluator_test.exs` exists; audience snapshot test does not. [VERIFIED: find rulestead/test] |
| IMP-04 | Accepted, blocked, and denied mutations write reconstructable audit evidence with preview fingerprint, affected-reference summary, actor, reason, env, tenant, and support-safe evidence. [VERIFIED: .planning/REQUIREMENTS.md] | audit contract | `cd rulestead && mix test test/rulestead/audience_mutation_audit_test.exs test/rulestead/admin_security_contract_test.exs` | New audit test missing; admin security test exists. [VERIFIED: find rulestead/test] |

### Sampling Rate

- **Per task commit:** Run the narrow test for the changed area plus `cd rulestead && mix compile --warnings-as-errors`. [ASSUMED]
- **Per wave merge:** Run `cd rulestead && mix test test/rulestead/store/audience_impact_contract_test.exs test/rulestead/store/ecto_audience_impact_contract_test.exs test/rulestead/runtime/audience_snapshot_test.exs`. [ASSUMED]
- **Phase gate:** Run `cd rulestead && mix test`; include release-contract tests if public API/store callback lists change. [VERIFIED: rulestead/test/rulestead/release_contract_test.exs]

### Wave 0 Gaps

- [ ] `rulestead/test/rulestead/targeting/impact_preview_test.exs` - covers IMP-01 preview payload shape, redaction, uncertainty, stable ordering. [ASSUMED]
- [ ] `rulestead/test/rulestead/store/audience_impact_contract_test.exs` - shared Fake/Ecto behavior for preview/apply freshness. [ASSUMED]
- [ ] `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs` - Ecto transaction/audit/snapshot specifics. [ASSUMED]
- [ ] `rulestead/test/rulestead/runtime/audience_snapshot_test.exs` - snapshot-local compiled audience resolution. [ASSUMED]
- [ ] `rulestead/test/rulestead/audience_mutation_audit_test.exs` - accepted/blocked/denied audit reconstruction. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct implementation | Host owns identity/session; Rulestead consumes host-supplied actors. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V3 Session Management | no direct implementation | Do not accept raw sessions or sockets in preview evidence. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md; rulestead/lib/rulestead/audit_event.ex] |
| V4 Access Control | yes | Use existing `Rulestead.Admin.Policy`/`Admin.Authorizer` write authorization and denied audit pattern. [VERIFIED: rulestead/lib/rulestead.ex; rulestead/test/rulestead/admin_security_contract_test.exs] |
| V5 Input Validation | yes | Use Ecto changesets, command normalization, and fail-closed `Rulestead.Error` results. [VERIFIED: rulestead/lib/rulestead/audience.ex; rulestead/lib/rulestead/store/command.ex; rulestead/lib/rulestead/store/ecto.ex] |
| V6 Cryptography | yes for fingerprints | Use `:crypto.hash(:sha256, term)` pattern already present; do not hand-roll crypto. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| V9 Communications | no direct implementation | No new network boundary recommended. [VERIFIED: .planning/research/STACK.md] |
| V10 Malicious Code | yes in flag/audience values | Keep preview evidence redacted and do not execute authored values as code. [VERIFIED: prompts/rulestead-security-privacy-and-threat-model.md] |
| V12 Files/Resources | no direct implementation | No file upload or filesystem preview dependency. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for Phase 53

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale preview replay after audience references changed | Tampering | Bind fingerprint/token to current audience definition and affected-reference closure; revalidate at apply. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex; .planning/REQUIREMENTS.md] |
| Cross-tenant or cross-environment confirmation | Elevation of privilege | Include explicit tenant/environment scope in preview and apply command; fail closed on mismatch. [VERIFIED: .planning/REQUIREMENTS.md] |
| PII leakage through sample evidence | Information disclosure | Redact samples before preview/audit/telemetry using allowlist and audit metadata scrubbers. [VERIFIED: rulestead/lib/rulestead/admin/redaction.ex; rulestead/lib/rulestead/audit_event.ex] |
| Runtime lookup drift | Tampering / Repudiation | Resolve audiences from compiled snapshot only; tests should use a store stub that raises if runtime calls back into storage. [VERIFIED: .planning/REQUIREMENTS.md; rulestead/lib/rulestead/runtime/snapshot.ex] |
| Denied mutation without evidence | Repudiation | Existing denied admin writes append audit rows; audience denial should follow the same pattern with result `:denied`. [VERIFIED: rulestead/test/rulestead/admin_security_contract_test.exs; rulestead/lib/rulestead/audit_event.ex] |
| False precision in affected users | Information disclosure / Repudiation | Label preview basis and uncertainty; do not claim Rulestead-owned identity or observability counts. [VERIFIED: .planning/STATE.md; .planning/REQUIREMENTS.md] |

## Concrete Files Likely To Need Planning

| File | Why |
|------|-----|
| `rulestead/lib/rulestead/store/command.ex` | Add audience preview/apply/archive command structs with actor, reason, metadata, scope, samples, and preview token/fingerprint fields. [VERIFIED: existing command pattern] |
| `rulestead/lib/rulestead/store.ex` | Add store callbacks for preview and mutation apply; update behavior implementers. [VERIFIED: existing Store callbacks] |
| `rulestead/lib/rulestead.ex` | Add public facade functions and route through `admin_read`/`admin_write` authorization. [VERIFIED: existing public facade pattern] |
| `rulestead/lib/rulestead/store/ecto.ex` | Implement Ecto preview query, apply transaction, fail-closed blockers, audit rows, and snapshot publish. [VERIFIED: existing Ecto adapter] |
| `rulestead/lib/rulestead/fake.ex` | Keep Fake adapter parity for contract tests. [VERIFIED: existing Fake adapter] |
| `rulestead/lib/rulestead/store/redis.ex` | Mark new admin mutation callbacks unsupported if `Store` behavior expands. [VERIFIED: existing unsupported callback list] |
| `rulestead/lib/rulestead/targeting/impact_preview.ex` | New pure contract module for preview payload/fingerprint. [ASSUMED] |
| `rulestead/lib/rulestead/targeting/audience_dependencies.ex` | New pure/query helper for affected references and stable summaries. [ASSUMED] |
| `rulestead/lib/rulestead/runtime/snapshot.ex` | Validate compiled audience definitions in runtime snapshots. [VERIFIED: existing snapshot compiler] |
| `rulestead/lib/rulestead/evaluator.ex` | Resolve `segment_match` against compiled audience definitions and emit structured trace. [VERIFIED: current segment behavior] |
| `rulestead/lib/rulestead/audit_event.ex` | Normalize preview/audience metadata for support reconstruction. [VERIFIED: existing audit metadata normalizer] |
| `rulestead/test/rulestead/release_contract_test.exs` | Update locked public exports/store callbacks if API changes. [VERIFIED: existing release contract] |

## Sources

### Primary (HIGH confidence)

- `.planning/STATE.md` - current phase, milestone decisions, preview/runtime constraints. [VERIFIED: file read]
- `.planning/ROADMAP.md` - Phase 53 goal, dependencies, success criteria, phase boundaries. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - IMP-01 through IMP-04 and out-of-scope constraints. [VERIFIED: file read]
- `AGENTS.md` - project execution constraints and linked sibling-package model. [VERIFIED: file read]
- `prompts/rulestead-security-privacy-and-threat-model.md` - host-owned identity, redaction, fail-closed security posture. [VERIFIED: file read]
- `prompts/rulestead-telemetry-observability-and-audit.md` - audit-vs-telemetry split and event discipline. [VERIFIED: file read]
- `prompts/rulestead-admin-ux-and-operator-ia.md` - preview/confirm/audit UX principle and mounted-admin boundary. [VERIFIED: file read]
- `prompts/rulestead-host-app-integration-seam.md` - host-owned auth/layout and mounted admin seam. [VERIFIED: file read]
- `.planning/research/STACK.md` - v1.6.0 stack recommendation against new external libraries. [VERIFIED: file read]
- `rulestead/lib/rulestead/audience.ex` - audience schema and archive field. [VERIFIED: file read]
- `rulestead/lib/rulestead/ruleset/rule.ex` - `segment_match` and `audience_key` validation. [VERIFIED: file read]
- `rulestead/lib/rulestead/promotion/compare.ex` - fingerprint, compare token, dependency closure, finding shape. [VERIFIED: file read]
- `rulestead/lib/rulestead/manifest/import.ex` - plan token/fingerprint validation and dependency blockers. [VERIFIED: rg/open]
- `rulestead/lib/rulestead/store/ecto.ex` - Ecto transaction, snapshot, audience list, audit implementation. [VERIFIED: file read]
- `rulestead/lib/rulestead/fake.ex` - Fake store audience and snapshot parity. [VERIFIED: file read]
- `rulestead/lib/rulestead/runtime/snapshot.ex` - runtime snapshot compilation. [VERIFIED: file read]
- `rulestead/lib/rulestead/evaluator.ex` - current runtime evaluation behavior. [VERIFIED: file read]
- `rulestead/lib/rulestead/audit_event.ex` - audit metadata and serialization. [VERIFIED: file read]
- `rulestead/test/test_helper.exs` and `rulestead/test/support/repo_case.ex` - test setup. [VERIFIED: file read]
- Ecto `Ecto.Multi` official docs - transactional grouping/introspection semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Phoenix LiveView official docs - async assign/stream/cancel semantics for later mounted UI context. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Secondary (MEDIUM confidence)

- None used as authoritative sources. [VERIFIED: research log]

### Tertiary (LOW confidence)

- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - package versions and dependencies verified locally; no new dependency recommended. [VERIFIED: mix deps; rulestead/mix.exs; .planning/research/STACK.md]
- Architecture: HIGH - phase requirements and existing core/store/runtime/audit patterns are clear. [VERIFIED: .planning/REQUIREMENTS.md; repo reads]
- Pitfalls: HIGH for runtime/audit/staleness risks, MEDIUM for exact migration/indexing choice. [VERIFIED: repo reads; ASSUMED]

**Research date:** 2026-05-27 [VERIFIED: current_date]
**Valid until:** 2026-06-26 for repo-local findings; re-check dependency versions before implementation if package upgrades occur. [ASSUMED]

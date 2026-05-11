# Phase 4: Snapshot Cache, Runtime Refresh, Telemetry, Explain Wiring - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** 5 parallel advisor passes across runtime shape, refresh model, backup policy, diagnostics/explain, and telemetry contract

<domain>
## Phase Boundary

Ship the operational runtime layer on top of the Phase 3 pure evaluator: compiled snapshots in ETS, explicit runtime lookup APIs, refresh/distribution, stale-serving behavior, optional bootstrap backup, and the Phase 4 telemetry/diagnostics surface. This phase makes evaluation fast and resilient in a real Phoenix app without changing the Phase 3 authored-payload contract or leaking future Phase 5-7 host/admin scope into the runtime core.

**In scope:**
- Compiled `Rulestead.Runtime.Snapshot` representation for hot-path evaluation
- Explicit snapshot-backed runtime lookup API over flag keys + environment snapshots
- ETS cache per environment with refresh orchestration
- PubSub refresh wake-ups plus polling reconciliation fallback
- Startup/degraded-mode behavior and optional disk bootstrap backup
- `Rulestead.diagnostics/0` plus Phase 4 explain/runtime metadata wiring
- Public telemetry wrapper and the runtime/store/admin-coarse event catalog Phase 4 truly owns

**Out of scope (explicitly deferred):**
- Plug/LiveView/Oban host integration entrypoints and installer wiring (Phase 5)
- Admin UI simulation pages, diagnostics pages, and operator workflows (Phases 6-7)
- Fine-grained admin/impression/exposure/webhook telemetry families (Phases 6-8)
- Phase 7 redaction Credo checks, though Phase 4 fields must still be redacted-by-design
- Full API-stability guide publication and cheatsheet lock-in (Phase 8)

</domain>

<decisions>
## Implementation Decisions

### Runtime Shape
- **D-01:** Preserve the Phase 3 root evaluator surface exactly as the pure authored-payload contract. `Rulestead.evaluate/3`, `enabled?/2`, `get_value/3`, `get_variant/2`, and `explain/2` remain payload-first and never perform runtime lookup, store I/O, process startup, or cache reads.
- **D-02:** Add a separate explicit runtime façade for snapshot-backed keyed evaluation. Phase 4 introduces `Rulestead.Runtime.evaluate/3`, `enabled?/2`, `get_value/3`, `get_variant/2`, `explain/2`, and `diagnostics/0`.
- **D-03:** Forbid same-arity union dispatch between payload and key forms. A caller should never need to guess whether a function is pure or runtime-backed based on the shape of the first argument.
- **D-04:** Runtime APIs evaluate only against already-applied local snapshots (ETS, optional disk bootstrap). They never hit the authoring store on the hot path.
- **D-05:** Phase 5 Plug/LiveView/Oban helpers target the runtime façade, not store fetches and not the payload-first evaluator.

### Snapshot and Cache Model
- **D-06:** Compile one immutable runtime snapshot per environment into ETS, keyed by `flag_key`, using `:read_concurrency` and local-per-node ownership.
- **D-07:** Treat cache coherence as a local-cache problem, not distributed consensus. Each node owns its own ETS snapshot set and converges by version, not by shared mutable state.
- **D-08:** Snapshot apply is monotonic and idempotent. Older or duplicate snapshot versions are ignored; a failed fetch/compile/apply never replaces a known-good snapshot.
- **D-09:** `Rulestead.Result.cache_age_ms` is filled only by the runtime façade. The pure Phase 3 evaluator remains agnostic to runtime freshness.

### Refresh Model
- **D-10:** Refresh uses a hybrid model: Phoenix.PubSub is the low-latency wake-up path, and polling is the correctness backstop.
- **D-11:** PubSub messages carry only bounded invalidation metadata such as environment key and snapshot version. Never broadcast full snapshots over PubSub.
- **D-12:** Each node fetches and compiles newer snapshots locally after a wake-up or poll detects a higher version.
- **D-13:** Default reconcile poll interval is `15_000ms`, configurable within a `5_000..60_000ms` range, with jitter to avoid synchronized polling across nodes.
- **D-14:** Store/read refresh failures back off exponentially with jitter and reset after success. Recommended ceiling: `1s -> 2s -> 4s -> 8s -> 16s -> 30s max`.
- **D-15:** If a valid snapshot already exists, runtime APIs serve stale last-known-good data during refresh/store/PubSub failures and emit telemetry for stale usage and refresh failure.
- **D-16:** If no snapshot exists yet, the runtime boots in documented degraded mode and serves the empty/default outcome until first successful refresh rather than crashing or blocking on host-app start order.

### Startup and Backup Policy
- **D-17:** Disk backup is a bootstrap aid, not a second runtime database or history system.
- **D-18:** Backup is disabled by default in v0.1.0.
- **D-19:** If enabled, Phase 4 supports exactly one backup backend: a versioned flat file containing the compiled runtime snapshot for each environment.
- **D-20:** Backup format is `magic header + format version + metadata + term binary + checksum`, decoded with safe term decoding plus explicit version validation.
- **D-21:** Writes use temp file + sync/datasync + atomic rename. Keep exactly one previous generation for rollback/recovery.
- **D-22:** Boot loads backup opportunistically before the first refresh. Corrupt backups are quarantined and reported via telemetry; they never crash startup.
- **D-23:** Backup write failures must not poison an already-successful in-memory apply.

### Diagnostics and Explain Wiring
- **D-24:** Keep `Rulestead.Result.debug_trace` as the Phase 3 evaluation-only substrate. Do not merge runtime/cache/process internals into that structure.
- **D-25:** Add a separate runtime diagnostics envelope with bounded redacted facts such as `snapshot_version`, `applied_at`, `cache_age_ms`, `refresh_status`, `stale_used?`, `source`, `disk_backup_status`, node identity, and sanitized error codes.
- **D-26:** `Rulestead.diagnostics/0` returns a machine-readable runtime summary oriented around environments and node-local runtime state, not unbounded per-flag dumps.
- **D-27:** Runtime `explain/2` composes the Phase 3 evaluation trace plus the runtime diagnostics envelope into human-readable prose and a structured safe payload for future admin/simulation use.
- **D-28:** Explain/diagnostics output must never include raw `attributes`, raw actor payloads, raw targeting identifiers, request structs, filesystem paths, process names, or arbitrary cache contents.
- **D-29:** Runtime failures annotate explain output; they do not overwrite the factual evaluation outcome.

### Telemetry Contract
- **D-30:** Phase 4 locks a staged middle-ground telemetry contract: small but complete for runtime/store/admin-coarse events already in scope, additive for future phases.
- **D-31:** All public runtime/store/admin-coarse operations use `Rulestead.Telemetry.span/3` over `:telemetry.span/3`.
- **D-32:** Phase 4 public event catalog is limited to:
  - `[:rulestead, :eval, :decide, :start|:stop|:exception]`
  - `[:rulestead, :runtime, :cache, :hit|:miss|:refresh|:stale_used]`
  - `[:rulestead, :runtime, :snapshot, :published|:applied]`
  - `[:rulestead, :store, :read|:write, :start|:stop|:exception]`
  - `[:rulestead, :admin, :mutation, :start|:stop|:exception]`
- **D-33:** Stable shared metadata spine is: `flag_key`, `flag_type`, `environment`, `snapshot_version`, `cache_age_ms`, `reason`, `has_targeting_key?`, and `matched_rule_count`, with domain-specific additions documented per event.
- **D-34:** Terminal `:stop` and `:exception` metadata repeats the stable context handlers need. Handlers must tolerate additive keys, missing optional keys, and unknown reason atoms.
- **D-35:** No raw values, raw attributes, actor payloads, conn/socket/job structs, secrets, or free-form payloads in telemetry metadata. Redact at emission, not downstream.
- **D-36:** Future fine-grained admin/impression/exposure/ops/webhook events remain reserved for additive Phase 6-8 expansion and are not part of the locked Phase 4 surface.

### the agent's Discretion
- Exact module split under `Rulestead.Runtime.*`, provided the explicit runtime/pure API boundary stays intact
- Exact internal ETS table layout and snapshot compilation helpers
- Exact telemetry measurement key set beyond the locked metadata spine, as long as it is coherent and bounded
- Exact human-readable explain prose formatting, provided it renders the locked evaluation/runtime facts above

</decisions>

<specifics>
## Specific Ideas

- Emulate the best operational lesson from FunWithFlags, LaunchDarkly, and Unleash: local cached evaluation must stay available when the control plane is unhealthy, but the runtime boundary should be explicit and honest about statefulness.
- Use PubSub to say “refresh now,” not to ship runtime state.
- Treat persisted backup as last-known-good bootstrap state, not as an embedded database.
- Keep diagnostics operator-rich but calm: enough data to answer “what snapshot did this node use and how stale was it?” without turning the API into an internal state dump.
- Keep telemetry and explain aligned with future admin UX, but only freeze the event families that Phase 4 can actually verify and support.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Locked Requirements
- `.planning/ROADMAP.md` — Phase 4 goal, scope, success criteria, and dependency boundary with Phases 3, 5, and 6
- `.planning/PROJECT.md` — non-negotiables: pure evaluator, snapshot-backed local evaluation, calm operator UX, no PII in telemetry/logs/audit
- `.planning/REQUIREMENTS.md` — source of truth for `STORE-02..06`, `TEL-01`, `TEL-02`, and `TEL-04`
- `.planning/STATE.md` — confirms current focus is Phase 4 after Phase 3 completion

### Prior Locked Decisions
- `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md` — immutable ruleset publishing, store separation, and authoring/runtime boundary
- `.planning/phases/03-context-rules-deterministic-bucketing-pure-evaluator/03-CONTEXT.md` — payload-first evaluation contract, debug trace boundary, deterministic bucketing, and Phase 4 diagnostic deferrals

### Product and Domain Direction
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns/events for `flag`, `snapshot`, `refresh`, `propagate`, `diagnostics`, and telemetry naming
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — converged guidance for telemetry spans, fake-first testing posture, optional deps, and explicit runtime seams
- `prompts/rulestead-telemetry-observability-and-audit.md` — long-horizon event-catalog design and telemetry principles; use as the future design reserve, not a wholesale Phase 4 lock
- `prompts/rulestead-security-privacy-and-threat-model.md` — redaction-at-emission, no raw traits in telemetry/debug surfaces, startup/runtime threat posture
- `prompts/rulestead-host-app-integration-seam.md` — expected config keys and the eventual Phase 5 runtime seam consumers
- `prompts/rulestead-testing-and-e2e-strategy.md` — stale-serving, missed-refresh, and runtime outage cases that Phase 4 must make testable
- `prompts/rulestead-admin-ux-and-operator-ia.md` — future operator-facing explain/diagnostics expectations; informs what structured runtime data should exist without dragging Phase 6 UI into scope

### Existing Runtime Surface
- `rulestead/lib/rulestead.ex` — current root payload-first API and narrow Phase 3 telemetry behavior
- `rulestead/lib/rulestead/evaluator.ex` — pure evaluator contract that Phase 4 must not pollute with runtime state
- `rulestead/lib/rulestead/result.ex` — current `Result` struct including `cache_age_ms` placeholder and `debug_trace` boundary
- `rulestead/lib/rulestead/explainer.ex` — Phase 3 human explain renderer that Phase 4 should enrich without turning into the source of truth
- `rulestead/lib/rulestead/store.ex` and `rulestead/lib/rulestead/store/ecto.ex` — store boundary the refresh loop reads from, without turning runtime evaluation into row-by-row store access
- `rulestead/lib/rulestead/fake.ex` — fake adapter/runtime control seam that future Phase 4 tests can extend

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead/lib/rulestead.ex` — already separates public store APIs from pure evaluation helpers; extend by adding a sibling runtime namespace rather than mutating existing semantics
- `rulestead/lib/rulestead/evaluator.ex` — the Phase 3 rule walker can remain the execution engine once snapshots compile back into the authored payload shape or an equivalent compiled form
- `rulestead/lib/rulestead/result.ex` — reserves `cache_age_ms`, which gives Phase 4 a clean place to project runtime freshness without redesigning the result contract
- `rulestead/lib/rulestead/fake.ex` and `rulestead/lib/rulestead/fake/control.ex` — already provide state inspection and time control patterns that can inform refresh/backup tests

### Established Patterns
- Public APIs are explicit, bang/non-bang aware, and typed around `%Rulestead.Error{}`; Phase 4 should preserve that discipline instead of adding magic global lookups
- Prior phases prefer immutable versioned documents and compile-time/changeset validation over permissive runtime ambiguity
- The repo’s planning DNA treats telemetry names and metadata as public API and expects bounded, testable contracts

### Integration Points
- Runtime refresh should read published ruleset state through the existing store boundary, compile it into a runtime snapshot, and expose only the compiled output to evaluation
- Phase 5 host-app seams should consume `Rulestead.Runtime.*`, not reinvent their own cache or lookup path
- Future admin explain/simulation surfaces can consume the structured diagnostics envelope if Phase 4 keeps it bounded and redacted now

</code_context>

<deferred>
## Deferred Ideas

- Store-driven notification adapters such as Postgres `LISTEN/NOTIFY` as a future optional optimization
- DETS or `:disk_log` snapshot persistence, unless a later phase proves keyed persistence or snapshot history is required
- Fine-grained admin telemetry families, impression/exposure events, webhook events, and OTel bridge surface
- Rich `/admin/diagnostics` UI, per-flag operator drilldowns, and replay-against-historical-snapshot tooling
- Public API stability write-up and cheatsheet publication of the telemetry/runtime surface

</deferred>

---

*Phase: 04-snapshot-cache-runtime-refresh-telemetry-explain-wiring*
*Context gathered: 2026-04-23*

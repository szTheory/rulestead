# Phase 20: PubSub Distributed Invalidation - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 20 delivers distributed invalidation for runtime snapshots so nodes converge quickly after flag/ruleset mutations without turning request-time evaluation into a polling-only system. This phase is about cache invalidation transport and refresh behavior only.

**In scope:**
- Broadcasting invalidation notices when a new runtime snapshot is published
- Waking connected runtime nodes so they refresh local ETS state immediately
- Supporting `Phoenix.PubSub` as the first-class transport path
- Preserving degraded-mode and polling/backoff reconciliation behavior
- Keeping the seam usable outside strict Phoenix endpoint ownership

**Out of scope:**
- Infrastructure health UI and operator diagnostics beyond the minimum telemetry needed for invalidation behavior
- Fine-grained patch streams or delta-application protocols
- Redis-only transport as the default invalidation backbone
- Reworking Phase 19’s snapshot distribution architecture

</domain>

<decisions>
## Implementation Decisions

### Invalidation payload shape
- **D-20-01:** Phase 20 invalidation payloads are versioned notices, not state replication. The correctness contract is a minimal payload containing `environment_key` and `snapshot_version`.
- **D-20-02:** The snapshot store remains authoritative. Receivers treat invalidation notices as advisory wake-ups and must re-fetch the latest snapshot before applying anything locally.
- **D-20-03:** Optional forward-compatible metadata such as `published_at`, `source_node`, or `changed_flag_keys` is allowed later, but such fields are advisory only and must not become required for correctness in Phase 20.
- **D-20-04:** Phase 20 will not implement fine-grained delta application, replay, sequencing, or partial ETS mutation semantics.

### Runtime invalidation behavior
- **D-20-05:** On receipt of an invalidation notice with a newer `snapshot_version`, the runtime triggers an immediate best-effort refresh through the existing `Rulestead.Runtime.Refresh` GenServer flow.
- **D-20-06:** Rulestead never pre-evicts ETS on invalidation receipt. The runtime keeps serving the last-known-good snapshot until a newer compiled snapshot is successfully applied.
- **D-20-07:** Missed, duplicated, and out-of-order invalidation notices are expected non-fatal conditions. Polling/backoff remains the mandatory reconciliation path for repair.
- **D-20-08:** Version comparison remains monotonic and local. Nodes ignore invalidation notices whose `snapshot_version` is not newer than the currently applied version.

### Transport seam
- **D-20-09:** Phase 20 introduces a formal runtime notifier seam rather than leaving distributed invalidation as direct `Phoenix.PubSub` calls inside refresh code.
- **D-20-10:** `Rulestead.Runtime.Notifier.PhoenixPubSub` is the default and only built-in transport in Phase 20.
- **D-20-11:** Rulestead will not ship direct Redis PubSub transport in Phase 20. Hosts that want Redis-backed fanout should use `Phoenix.PubSub.Redis` underneath the same notifier seam.
- **D-20-12:** Invalidation transport remains hint-based, not a second data plane. PubSub is an event bus for convergence, not the source of runtime truth.

### Host integration posture
- **D-20-13:** The host app owns PubSub infrastructure. Rulestead consumes a configured PubSub server when provided and falls back to polling/backoff when not configured.
- **D-20-14:** `Rulestead.Application` does not start or own a default PubSub child in Phase 20.
- **D-20-15:** Runtime PubSub resolution must be explicit and deterministic. There is no runtime autodetection of host PubSub servers.
- **D-20-16:** Installer-time detection is allowed only to scaffold explicit host config. Detect for setup, not for runtime behavior.
- **D-20-17:** Invalidation broadcasts originate from core `rulestead` snapshot-publish success paths, not from `rulestead_admin`, so the contract remains valid for non-admin mutation paths and pure runtime hosts.

### Telemetry and observability
- **D-20-18:** Phase 20 must emit explicit invalidation telemetry distinct from polling refresh telemetry.
- **D-20-19:** At minimum, telemetry should make it possible to distinguish `invalidation_received`, `invalidation_ignored`, `refresh_triggered_from_invalidation`, and `refresh_failed_after_invalidation`.

### the agent's Discretion
- Exact notifier module split, provided the contract stays narrow and explicit
- Exact invalidation message struct vs map shape, provided the stable fields are `environment_key` and `snapshot_version`
- Exact coalescing/debouncing strategy for duplicate invalidation bursts, provided monotonic version semantics and stale-serving behavior remain intact
- Exact telemetry event naming under the existing `[:rulestead, ...]` namespace, provided invalidation vs refresh outcomes remain distinguishable
- Exact installer wiring details for Phoenix vs pure Plug hosts, provided runtime ownership remains explicit and host-owned

</decisions>

<specifics>
## Specific Ideas

- Treat PubSub invalidation as “wake up and reconcile now,” not “the transport message is the new state.”
- Preserve the Phase 19 mental model: local evaluation from ETS, centralized snapshot distribution, stale last-known-good on failures.
- Favor a boring, explicit host seam over runtime magic. Phoenix hosts should typically pass their existing `pubsub_server`; pure Plug hosts can still start `{Phoenix.PubSub, name: MyApp.PubSub}` directly.
- Keep the door open for optional advisory metadata later, but do not let Phase 20 drift into patch-stream complexity.
- User preference for this project: shift recommendation work left by default. Planning should treat these decisions as locked unless a future phase raises a genuinely high-impact product or operational tradeoff.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — current milestone posture, linked-version sibling-package constraints, and host-integration philosophy
- `.planning/STATE.md` — active milestone and explicit Phase 20 requirement focus
- `.planning/milestones/v0.5.0-ROADMAP.md` — Phase 20 goal, success criteria, and dependency on Phase 19
- `.planning/milestones/v0.5.0-REQUIREMENTS.md` — `INV-01` and `INV-02`

### Prior locked decisions
- `.planning/phases/19-redis-storage-and-caching-adapter/19-CONTEXT.md` — Redis as read-only snapshot distribution layer, not the mutation source of truth
- `.planning/phases/19-redis-storage-and-caching-adapter/19-PATTERNS.md` — existing Redis publisher and runtime refresh analogs
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — prior locked project preference to ask fewer decision questions and shift recommendation work left

### Product, architecture, and ecosystem direction
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — explicit seams, host-owned infra posture, library ergonomics, and CI/testing discipline
- `prompts/rulestead-host-app-integration-seam.md` — explicit-over-magic host wiring philosophy
- `prompts/rulestead-testing-and-e2e-strategy.md` — runtime, cluster, degraded-mode, and repair-path testing expectations
- `prompts/rulestead-telemetry-observability-and-audit.md` — telemetry namespace and event-contract guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — library API and config ergonomics
- `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — current ecosystem posture around Phoenix.PubSub, Redis usage, and idiomatic transport choices

### Existing code and contracts
- `rulestead/lib/rulestead/application.ex` — current supervised children and explicit non-ownership of PubSub
- `rulestead/lib/rulestead/runtime/config.ex` — runtime snapshot config and current PubSub topic default
- `rulestead/lib/rulestead/runtime/supervisor.ex` — runtime worker injection seam for `:pubsub`
- `rulestead/lib/rulestead/runtime/refresh.ex` — current refresh worker behavior, PubSub subscription path, and version-gated wake-up logic
- `rulestead/lib/rulestead/runtime/cache.ex` — monotonic snapshot application and stale-state handling
- `rulestead/lib/rulestead/redis.ex` — Redis connection/config seam
- `rulestead/lib/rulestead/redis/publisher.ex` — current snapshot publication flow
- `rulestead/lib/rulestead/fake/control.ex` — existing invalidation test helper shape
- `rulestead/test/rulestead/runtime/refresh_test.exs` — local invalidation, polling reconciliation, and degraded-mode runtime expectations
- `rulestead/test/rulestead/runtime/cluster_refresh_test.exs` — multi-node convergence expectations
- `rulestead/test/fixtures/install_golden/tree/config/config.exs` — current Phoenix host config shape with `pubsub_server`

### External ecosystem references
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` — standalone PubSub service and adapter model
- `https://openfeature.dev/specification/sections/events/` — provider event semantics (`READY`, `ERROR`, `STALE`, `CONFIGURATION_CHANGED`) as advisory state-change signals
- `https://launchdarkly.com/docs/home/getting-started/architecture` — push-first local-cache architecture with fallback to cached/default state
- `https://docs.getunleash.io/sdks` — local in-memory evaluation with polling/repair model

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Runtime.Refresh` already contains the right worker shape for serialized refresh side effects and version-aware PubSub wake-ups.
- `Rulestead.Runtime.Cache.apply/2` already enforces monotonic application, making duplicate and out-of-order notices safe.
- `Rulestead.Redis.Publisher` already establishes the control-plane pattern of reacting to snapshot publication events and pushing authoritative compiled snapshots into Redis.
- `Rulestead.Fake.Control.publish!/3` and the runtime refresh tests already provide a usable testing vocabulary for Phase 20 invalidation paths.

### Established Patterns
- The runtime hot path reads from local ETS and avoids request-time store reads.
- Snapshot publication is a control-plane event; runtime refresh is a separate, supervised reconciliation loop.
- Host integration prefers explicit config and host-owned infrastructure over autodetection or hidden side effects.
- Degraded mode preserves last-known-good state instead of failing closed on transient refresh/store issues.

### Integration Points
- Successful snapshot publication should emit/broadcast invalidation from core `rulestead` paths close to the authoritative publish event, not from UI code.
- The runtime supervisor/config seam should carry notifier and PubSub config into per-environment refresh workers.
- Installer and docs should scaffold explicit host wiring for Phoenix apps while documenting the pure Plug path for directly supervised `Phoenix.PubSub`.
- Telemetry additions must align with the existing `[:rulestead, ...]` contract and remain distinct from generic polling refresh events.

</code_context>

<deferred>
## Deferred Ideas

- Direct Redis PubSub, NATS, or other non-Phoenix built-in transport adapters
- Fine-grained delta/patch invalidation protocols with replay and sequencing
- Partial ETS refresh keyed by `changed_flag_keys`
- Rich infrastructure observability UI and operator health surfaces for Phase 21
- Runtime autodetection heuristics for host PubSub or umbrella endpoint topology

</deferred>

---

*Phase: 20-pubsub-distributed-invalidation*
*Context gathered: 2026-05-17*

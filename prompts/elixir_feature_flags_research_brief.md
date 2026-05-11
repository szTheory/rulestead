# Elixir Feature Flags / Experimentation OSS Research Brief

**Purpose:** A research-grade analysis document for designing a next-generation Elixir feature flag and experimentation library for Phoenix / Plug / Ecto systems. This is written to be used as a human design brief **and** as an LLM context document for implementation work.

**Working thesis:** The Elixir ecosystem has a good base for **boolean runtime toggles** (most notably FunWithFlags), but it still lacks an Elixir-native, batteries-included library/platform with strong support for **multivariate values, experimentation, governance, auditability, scheduled changes, environment separation, explainability, lifecycle cleanup, and operational ergonomics**. The opportunity is not just “more gates.” It is to deliver an Elixir-first system that feels natural to Phoenix teams, scales operationally, and avoids the footguns that other ecosystems already discovered the hard way.

---

## 1. Executive summary

### The gap
Today, the clearest Elixir-native feature-flag option is **FunWithFlags**, which is strong for classic runtime boolean flags with actor/group/percentage targeting, Ecto/Redis persistence, ETS caching, and optional UI. It is a good OSS library, but it is intentionally centered on boolean toggles and a relatively compact model. It does not aim to be a full feature-management / experimentation platform.

At the same time, Elixir teams often solve the “next layer up” by:
- embedding FunWithFlags and accepting its scope,
- wiring to an external platform like Unleash,
- building in-house ad hoc systems,
- or avoiding serious experimentation / progressive delivery altogether.

That leaves a genuine product and ecosystem gap for:
- **multivariate flags / remote config values**,
- **experiments and variant assignment**,
- **audit trails and approvals**,
- **scheduled rollouts / scheduled changes**,
- **projects / environments / namespaces / tenancy**,
- **explainability (“why did this evaluate this way?”)**,
- **flag lifecycle management and stale-flag cleanup**,
- **telemetry / tracing / impressions / analytics integration**,
- **operator tooling and intuitive admin UX**.

### Core recommendation
Build the project as **two clearly separated products inside one codebase**:

1. **Runtime evaluator**  
   A small, fast, pure, embeddable Elixir library that performs local evaluation with great ergonomics, deterministic assignment, telemetry, and request/job context propagation.

2. **Control plane / admin system**  
   An optional Phoenix-powered management layer for CRUD, audit, approvals, scheduling, simulation, explainability, environment management, and contributor/operator workflows.

This separation is one of the strongest repeated lessons from mature systems. Evaluation must stay fast, local, deterministic, and failure-resistant. Authoring/governance can be richer and slower.

### What “best in class” means here
For this project, “best in class” should mean:

- Feels idiomatic in **Elixir / Phoenix / Plug / LiveView / Ecto / Oban**.
- Great for **small teams** on day 1, but with a path to **serious operations** later.
- Strong **explainability** and **simulation**, not just evaluation.
- Strong **lifecycle hygiene** so flags do not become permanent debt.
- Great **telemetry and tracing** out of the box.
- Great **testing helpers** and deterministic local development.
- Great **operational safety**: local evaluation, cache/invalidation resilience, clear failure modes, environment isolation.
- Great **contributor DX**: predictable architecture, clean module boundaries, local docker stack, CI, fixtures, docs, examples.
- Intuitive **admin UI** that makes the hard things legible: precedence, targeting, variants, schedules, approvals, audit, stale-state, and “why.”

### Strategic product stance
Do **not** start by competing head-on with LaunchDarkly as a full hosted platform.

Do start by becoming:
- the **best Elixir-native feature-management runtime**,
- the **best self-hostable Phoenix-first control plane**,
- and the easiest OSS path for teams that want **serious feature management without leaving the BEAM ecosystem**.

---

## 2. What exists today in Elixir / Erlang

## 2.1 FunWithFlags: what it does well

FunWithFlags is the current flagship Elixir-native library. Its strengths are substantial:

- Simple OTP application with a straightforward API.
- Supports **boolean**, **actor**, **group**, **percentage-of-actors**, and **percentage-of-time** gates.
- Works with **Redis or relational DB persistence** and an **ETS local cache**.
- Supports **PubSub-based cache busting** for multi-node sync.
- Has a separate optional **UI Plug** that can be mounted into Phoenix/Plug apps.
- Includes **Telemetry instrumentation**.
- Supports custom persistence adapters and Ecto scenarios such as multi-tenancy.

This is already a very respectable baseline. It proves that:
- Elixir users value low-latency local evaluation.
- ETS + persistent backing store is attractive.
- Plug/Phoenix embeddability matters.
- “simple API first” is the correct starting point.

## 2.2 FunWithFlags: key limitations / lessons

The gap is not that FunWithFlags is “bad.” The gap is that it is not trying to be the thing you want to build.

### 1) Boolean-centric model
FunWithFlags is fundamentally framed around boolean flags and gates. That is excellent for release toggles and kill switches, but not enough for:
- multivariate value delivery,
- remote config,
- typed values,
- experiments,
- parameterized rollouts.

### 2) Precedence complexity grows quickly
FunWithFlags uses a fixed priority model:
- Actors > Groups > Boolean > Percentage
- disabled group precedence over enabled group when conflicts exist

This is workable, but precedence systems get cognitively expensive fast. Mature systems repeatedly invest in simulation/explain/debug UIs because users struggle to reason about rule interactions.

### 3) Cache / invalidation / startup-order complexity is real
FunWithFlags explicitly documents:
- ETS cache + PubSub invalidation,
- optional TTL fallback,
- the ability to disable cache,
- and startup race conditions if notification processes depend on host-owned processes such as Phoenix.PubSub.

There are also public issue/forum threads showing:
- startup-order brittleness around Phoenix.PubSub subscription timing,
- retries that “break really easily” in some app/test setups,
- and user confusion in tests around async timing and shared runtime behavior.

These are not niche problems. They are exactly the kind of issues a next-gen library should design out from the beginning.

### 4) UI scope is intentionally narrow
FunWithFlags.UI is a useful control panel Plug, but:
- security/auth is left to the host,
- it is not a full governance surface,
- it does not aim to solve approvals, audit, lifecycle, simulation, scheduling, or experimentation.

### 5) Maintenance / ecosystem continuity matters
A public fork (“fork_with_flags”) exists partly because the original was perceived as not actively maintained and because downstream users wanted unmerged changes (including SQLite-related support). Even if the original remains useful, this is an ecosystem signal:
- feature-flag infrastructure becomes central very quickly,
- teams want confidence in maintenance,
- and “core infra OSS” needs a strong stewardship story.

### Bottom line
FunWithFlags teaches that the **runtime shape** is good, but the **product scope** is incomplete for modern product-led SaaS needs.

---

## 3. Elixir ecosystem lesson: many teams route to external platforms

The Elixir `unleash` ecosystem is also telling.

There are Elixir clients around **Unleash**, including support for:
- `enabled?`,
- `get_variant`,
- Plug integration,
- ETS cache,
- repo polling / backup state,
- telemetry events,
- and request/process-tree propagation of context, overrides, and impressions.

This is important because it shows where sophisticated Elixir teams go when they outgrow simple booleans:
- they do not stop needing feature flags,
- they adopt a richer external control plane,
- and then they re-import those capabilities into Elixir clients.

The implication: the missing piece is not desire. It is the lack of a strong native control plane + runtime package in the Elixir ecosystem.

---

## 4. Lessons from mature systems in other ecosystems

This section extracts **portable lessons**, not vendor worship.

## 4.1 Unleash: model lifecycle and governance as first-class concepts

Unleash contributes several strong ideas:

### A. Unified flag identity across environments
A flag is a single logical entity, while activation strategies, rollout percentages, and variants can differ by environment.

**Lesson:** Treat metadata and behavior separately.
- flag identity and intent are global-ish,
- environment behavior is environment-specific.

### B. Stickiness matters
Unleash emphasizes **stickiness** so the same user repeatedly gets the same experience, and variants become random per request if context is missing.

**Lesson:** Stable targeting keys are non-negotiable for rollouts and experiments.

### C. Lifecycle state matters
Unleash explicitly models **active / potentially stale / stale** and automatically marks flags as potentially stale after an expected lifetime.

**Lesson:** Lifecycle cannot be a docs-only concern. It should be in the product model.

### D. Event timeline / history matters
Unleash’s event timeline gives recent change visibility for debugging.

**Lesson:** Operators need “what changed recently?” almost as much as they need “what is the value now?”

### E. Environment-specific permissions matter
Unleash supports role/permission differences by environment.

**Lesson:** Governance is often environment-sensitive, especially for production.

### F. Experiments belong near flagging but not inside the same simple abstraction
Unleash variants are linked to activation strategies, which helps bridge rollout and multivariate delivery without collapsing everything into one boolean toggle.

**Lesson:** Experiments should sit adjacent to flagging, not be bolted on as an afterthought.

## 4.2 GrowthBook: explainability and simulation are product-defining

GrowthBook is especially strong on the “developer/operator comprehension” side.

### A. Rules evaluated top-to-bottom, first match wins
This is simpler than some precedence systems because it matches familiar rule-engine intuition.

**Tradeoff:** Easier to reason about than multi-dimensional gate precedence, but rule ordering becomes extremely important.

### B. Multiple rule types under one mental model
GrowthBook distinguishes:
- forced value,
- percentage rollout,
- experiment,
- safe rollout.

**Lesson:** Users understand purpose-specific rules better than a grab bag of gate mechanics.

### C. Simulation and archetypes are a huge usability win
GrowthBook has a simulation page and saved archetypes for testing common user profiles.

**Lesson:** One of the best investments you can make is a “show me what happens for this user/account/context” workflow.

### D. Debug logging / DevTools matter
Their browser DevTools expose:
- current values,
- overrides,
- why a rule matched,
- and what attributes influenced evaluation.

**Lesson:** “Why?” tooling is not polish. It is essential.

### E. Sticky bucketing and experimentation tradeoffs
GrowthBook discusses sticky bucketing and also notes that in some bandit contexts stickiness reduces the ability to move users quickly to better-performing variants.

**Lesson:** There is no one perfect assignment model. You must be explicit about tradeoffs:
- UX consistency,
- causal validity,
- adaptive optimization,
- and reassignment behavior.

## 4.3 Flipper: excellent OSS ergonomics, but serious capabilities live in the control plane

Flipper is a very useful comparison because FunWithFlags was inspired by it.

### Great ideas
- Great OSS ergonomics for app developers.
- Clean actor/group/percentage mental model.
- Lots of adapters.
- Strong emphasis on local evaluation and app safety.
- Cloud product adds what serious teams eventually need: environments, permissions, audit history, rollbacks, telemetry, webhooks.

### Important lesson
The Flipper docs explicitly say:
- **do not use percentage of time** for slow rollout because the same actor can get different answers on later calls;
- use **percentage of actors** for stable rollouts.

This is one of the clearest examples of a feature-flag footgun that should be made hard to misuse.

### Additional lesson from production extension work
A 2026 Evil Martians write-up on extending Flipper highlights:
- teams wanted **human-friendly actor identifiers** in the UI,
- hash-based percentage assignment is operationally elegant but **not directly queryable** for “who is in the cohort?” unless you recompute for each user,
- instrumentation hooks were useful for “first seen enabled” analytics events.

**Portable lessons:**
- UI-friendly identifiers matter.
- stateless hashing is excellent for runtime, but painful for downstream analytics if you need explicit cohort lists.
- instrumentation hooks create extension power without contaminating the core evaluator.

## 4.4 Django Waffle: testing and request-centric overrides are important

Waffle is older but still insightful:

- It distinguishes flags/switches/samples.
- It has explicit request/querystring/cookie override mechanics.
- It documents evaluation order.
- It discusses test helpers because flags create nondeterminism.

**Lesson:** Testing ergonomics should be first-class:
- force values in tests,
- exercise both paths,
- and make request-scoped overrides possible in development/e2e.

## 4.5 Flagsmith: remote config + identity/segment model + admin governance

Flagsmith offers strong lessons around:
- booleans plus multivariate / remote config values,
- project / environment organization,
- identities and segments,
- audit logs,
- scheduled flags / change requests,
- real-time update tradeoffs,
- privacy-sensitive identity handling via transient traits.

Important lessons:
- multivariate bucketing needs stable identities (or persistent anonymous ids),
- real-time update systems still often require a follow-up fetch for actual state,
- precedence across overlapping segments can be hard to reason about,
- users ask for stronger “lock/override” semantics than some systems provide.

**Lesson:** You must design precedence and override semantics explicitly enough that users do not have to “learn by surprise.”

## 4.6 Flipt: ops/devops story can itself be a differentiator

Flipt is especially interesting for deployment and self-hosting lessons:

- namespaces and environments for isolation,
- audit sinks,
- Prometheus metrics by default,
- OTLP/Jaeger/Zipkin options,
- multiple storage backends,
- Git-backed storage,
- declarative/Git-native workflows in v2,
- branching / merge proposals / commit signing / GitHub Actions.

**Portable lessons:**
- The deployment story can be a product feature.
- Self-hosted users care deeply about:
  - storage backends,
  - observability,
  - authn/authz,
  - GitOps,
  - verifiable audit trails.
- “No external dependencies” and “easy binary/docker story” are meaningful adoption levers.

## 4.7 LaunchDarkly: governance patterns are not luxury features

LaunchDarkly contributes several lessons even if you do not copy the product scope:

- change history / rollback,
- approvals,
- required approvals for environments,
- scheduled changes,
- progressive rollout tooling,
- lifecycle / code references / flag retirement guidance.

One particularly important detail: their docs recommend dedicated progressive rollout features because a customer’s variation changes only once over the course of rollout. That is a subtle but important operator UX principle.

**Lesson:** governance and rollout mechanics should minimize surprise for end users, not just give admins knobs.

## 4.8 OpenFeature: the abstraction boundary is worth stealing

OpenFeature’s strongest lessons are conceptual:

- separate **provider abstraction** from evaluation API,
- hooks with lifecycle stages (`before`, `after`, `error`, `finally`),
- evaluation context as a first-class object,
- domains / transaction context / tracking / events,
- observability guidance for OpenTelemetry.

This maps extremely well to Elixir.

**Portable lessons:**
- define a strong internal provider/adapter boundary,
- make hooks/middleware extension a first-class concept,
- treat context propagation explicitly,
- and design telemetry in a way that can map cleanly to OpenTelemetry semantics later.

---

## 5. Cross-ecosystem patterns: what the best systems consistently do

Across ecosystems, the strongest systems converge on the following ideas:

## 5.1 Separate authoring from evaluation
Control plane concerns:
- CRUD
- approvals
- audit
- scheduling
- lifecycle
- UI
- permissions

Runtime concerns:
- fast local evaluation
- deterministic assignment
- cache resilience
- context propagation
- telemetry

Trying to solve these in one undifferentiated module leads to architectural confusion.

## 5.2 Prefer deterministic assignment over per-request randomness
Stable hashing / sticky bucketing is the standard good default for:
- gradual rollouts,
- experiments,
- multivariate delivery.

Per-request randomness is useful in narrow cases (sampling, dark traffic), but it is a bad default for user-facing rollouts.

## 5.3 Explainability is a core feature, not a support tool
Mature products keep adding:
- debug logs,
- simulation pages,
- archetypes,
- timeline/history,
- diff views,
- audit trails,
- “why did this match?” output.

That is because precedence and targeting rules become support burdens quickly.

## 5.4 Lifecycle needs product support
Research and product docs converge on the same lesson: stale flags become technical debt unless:
- ownership exists,
- expiration exists,
- stale state is surfaced,
- and cleanup automation exists.

## 5.5 Rule systems need an intentionally teachable mental model
Users struggle when:
- precedence is too implicit,
- overlapping segments conflict,
- rules reorder unexpectedly,
- or the same flag behaves differently depending on missing context.

The product has to make its model legible.

## 5.6 Good feature flagging is partly an observability product
Operators need:
- metrics,
- traces,
- evaluation reasons,
- impression/event hooks,
- recent-change visibility,
- and environment drift detection.

## 5.7 The best self-hosted systems invest in delivery ergonomics
Strong self-hosted tools consistently care about:
- Docker,
- GitOps,
- CI integration,
- import/export,
- backup,
- remote config/state sync,
- low external dependency count,
- robust auth and secrets handling.

---

## 6. Main footguns and complaints you should design around

This is the highest-value section for product design.

## 6.1 Footgun: “percentage of time” used for user-facing rollout
**Problem:** Same user sees different answers across calls.  
**Seen in:** Flipper docs, FunWithFlags model.

**Design response:**
- treat time-based randomization as an advanced mode,
- warn loudly in docs/UI,
- label it for dark launches / sampling / chaos / shadow behavior,
- make sticky actor-based rollout the default wizard path.

## 6.2 Footgun: missing targeting key causes random or invalid assignment
**Problem:** Without a stable target key, variant assignment becomes random per request or provider behavior becomes unpredictable.

**Design response:**
- define `targeting_key` as a first-class required field for sticky rollouts/experiments,
- emit warnings/telemetry when stickiness-capable rules are evaluated without one,
- optionally fail closed in strict mode.

## 6.3 Footgun: precedence confusion
**Problem:** Multiple groups/segments/overrides interact in surprising ways.

**Design response:**
- expose evaluation traces,
- support simulation by archetype and live context,
- choose a simple rule model,
- and document conflict semantics in plain English.

## 6.4 Footgun: stale-flag debt
**Problem:** Teams intend to clean up later and do not.

**Design response:**
- classify flag types,
- assign expected lifetimes at creation,
- require owner/team,
- surface stale / potentially stale in UI and telemetry,
- provide GitHub issue / webhook / codegen / codemod hooks,
- and optionally ship static-analysis helpers for code references.

## 6.5 Footgun: environments drift from each other in unsafe ways
**Problem:** dev/staging/prod behavior diverges without intention.

**Design response:**
- model environments explicitly,
- support controlled copying/branching/promotions,
- expose diffs,
- preserve a single flag identity with per-environment behavior,
- and make production privileges stricter.

## 6.6 Footgun: cache invalidation and propagation issues
**Problem:** stale values, sync lag, race conditions, startup-order problems.

**Design response:**
- keep evaluator pure and cacheable,
- make stores/notification mechanisms pluggable,
- use explicit startup contracts,
- avoid hard dependence on host-owned processes starting in a particular order,
- provide a clear degraded mode,
- expose cache age/version in debug endpoints.

## 6.7 Footgun: testing nondeterminism
**Problem:** async tests, shared runtime state, and random assignment create flaky tests.

**Design response:**
- built-in deterministic test mode,
- context managers/helpers/macros to force flag values,
- sandbox-friendly store adapters,
- seeded bucketing helpers,
- easy “assert both branches” patterns,
- and documented testing recipes for ExUnit, LiveView, integration tests, and browser E2E.

## 6.8 Footgun: UI not usable by support/product/ops people
**Problem:** library APIs are fine, but the admin UX is inscrutable.

**Design response:**
- prioritize the UX for non-authors:
  - “what is on right now?”
  - “why?”
  - “who changed it?”
  - “what is scheduled?”
  - “is this stale?”
  - “can I safely roll it back?”

## 6.9 Footgun: privacy and PII leakage in context/impression logging
**Problem:** identifiers and traits leak into logs, audit, analytics.

**Design response:**
- separate public metadata vs secure traits,
- support transient context fields,
- allow attribute allowlists/denylists,
- redact by default in logs,
- and make impression tracking configurable.

## 6.10 Footgun: experimentation bolted onto flagging without analytics design
**Problem:** variants exist but there is no measurement loop.

**Design response:**
- model impressions and exposure events,
- support tracking hooks,
- make analytics integration explicit,
- avoid pretending “multivariate flag” automatically equals “experiment.”

---

## 7. Product principles for the new Elixir library

## 7.1 Principle: local, pure, deterministic evaluation
The evaluator should be:
- fast,
- pure from the caller’s perspective,
- deterministic for a given flag definition + context,
- and easy to reason about independently of storage or UI.

## 7.2 Principle: explicit context object
Do not rely on ad hoc keyword arguments everywhere.

Have an explicit context struct, something like:

- `subject_key`
- `subject_kind`
- `tenant_key`
- `environment`
- `attributes`
- `request_id`
- `session_id`
- `groups` (optional computed)
- `metadata`
- `strict?`

This should be creatable from:
- Plug conn,
- Phoenix socket / LiveView,
- Oban job,
- CLI process,
- raw maps.

## 7.3 Principle: value-first, not boolean-first
Represent flags as “value resolvers” where booleans are just one typed case.

Support:
- boolean
- string
- integer
- float
- JSON / map
- atom-like enumerated variants only if carefully designed

Then layer semantic categories on top:
- release flag
- experiment
- kill switch
- permission / entitlement
- remote config
- operational throttle
- migration flag

## 7.4 Principle: one mental model for rules
Strong recommendation: prefer a **rule list** model over scattered gate precedence.

Each rule:
- has conditions,
- optional segment references,
- a rollout/bucketing strategy,
- a resulting value/variant,
- a reason label,
- and metadata.

Then:
- rules are evaluated in order,
- first match wins,
- default value applies if none match.

This is easier to teach, easier to simulate, and easier to explain than a pile of partially interacting gates.

## 7.5 Principle: extension points belong in hooks
Provide hook points roughly analogous to OpenFeature:
- before evaluation
- after evaluation
- on error
- finally

Use them for:
- telemetry
- tracing
- impression logging
- custom validations
- local overrides
- analytics integration
- test behavior

## 7.6 Principle: runtime package must not force the full platform
A user should be able to adopt:
- runtime only,
- runtime + Ecto store,
- runtime + Phoenix admin UI,
- runtime + OpenFeature bridge,
- runtime + external analytics hooks,
- or all of the above.

---

## 8. Recommended bounded contexts (DDD-friendly)

Because feature flags are a cross-cutting concern, bounded contexts matter a lot.

## 8.1 Evaluation Runtime
**Purpose:** resolve values quickly and deterministically in application code.

**Owns:**
- evaluation API
- evaluation context
- bucketing/stickiness
- rule engine
- hooks
- telemetry events
- local cache representation
- evaluator reason trace

**Does not own:**
- admin workflows
- approval workflows
- dashboards
- analytics computation
- code references

## 8.2 Control Plane / Governance
**Purpose:** manage the state and lifecycle of flags.

**Owns:**
- flags
- environments
- namespaces/projects
- ownership
- approvals
- change requests
- schedules
- audit log
- archival / stale state
- permissions

## 8.3 Delivery / Distribution
**Purpose:** move authored state to evaluators.

**Owns:**
- store adapters
- polling
- pubsub/invalidation
- streaming updates
- payload snapshots
- versioning / ETags / checksums
- backup state

## 8.4 Experimentation / Insights
**Purpose:** connect assignment to outcome measurement.

**Owns:**
- variants
- impressions/exposures
- holdouts
- track events
- conversion/event hooks
- sample-ratio mismatch detection if you go that far later
- guardrail metrics in future phases

## 8.5 Admin UX
**Purpose:** make the system understandable and operable.

**Owns:**
- flag list/search/filter
- detail page
- targeting editor
- simulation/playground
- audit/timeline view
- schedule/approval view
- stale cleanup workflows
- docs/help affordances

This decomposition lets you keep the runtime crisp while still building a serious product surface.

---

## 9. Domain language: recommended nouns, verbs, events, and concepts

This matters a lot. A library becomes usable when the language is crisp.

## 9.1 Core nouns
- **Flag** — a named runtime decision point.
- **Variant** — one possible returned value in a multivariate flag.
- **Default value** — fallback if no rules match.
- **Rule** — an ordered targeting/evaluation unit.
- **Condition** — attribute/group predicate inside a rule.
- **Segment** — reusable targeting definition.
- **Context** — data supplied at evaluation time.
- **Targeting key** — stable identifier used for stickiness/bucketing.
- **Environment** — isolated runtime config space (dev/staging/prod/etc.).
- **Project** — organizational boundary above environments.
- **Namespace** — optional domain/team/app partition within a project or environment.
- **Owner** — team/person responsible for lifecycle.
- **Lifecycle state** — active / potentially stale / stale / archived.
- **Impression / exposure** — evaluation that actually exposed a flag/variant to a subject.
- **Audit event** — a recorded administrative change.
- **Change request** — a proposed governed change.
- **Scheduled change** — a future state mutation.
- **Approval** — a required signoff before certain changes.
- **Snapshot** — a versioned payload for local evaluation.
- **Reason / trace** — structured explanation for a resolution.

## 9.2 Useful verbs
- evaluate
- resolve
- explain
- simulate
- target
- enable
- disable
- assign
- roll out
- promote
- schedule
- approve
- reject
- archive
- stale
- retire
- import
- export
- propagate
- sync
- override
- track
- expose
- diff

## 9.3 Useful event names
Prefer `noun:verb` or clear telemetry tuples.

Examples:
- `flag:created`
- `flag:updated`
- `flag:archived`
- `flag:stale_marked`
- `rule:created`
- `rule:reordered`
- `variant:assigned`
- `schedule:created`
- `change_request:submitted`
- `approval:granted`
- `approval:rejected`
- `evaluation:resolved`
- `evaluation:error`
- `impression:recorded`
- `snapshot:published`
- `cache:refreshed`
- `cache:miss`
- `cache:stale_used`

## 9.4 Recommended user-facing terminology choices
Prefer:
- **value** instead of “payload”
- **rule** instead of “gate” for the new system
- **simulate** instead of “dry run”
- **explain** / **why this matched**
- **targeting key** instead of just “id”
- **lifecycle** instead of vague “status”
- **owner** and **expiration** at creation time

---

## 10. Personas and jobs to be done

## 10.1 Application developer
**JTBD:** “Ship code safely, hide incomplete work, and write readable code.”

Needs:
- simple API
- test helpers
- deterministic local behavior
- docs/examples
- clear fallback behavior
- low cognitive overhead

## 10.2 Tech lead / staff engineer
**JTBD:** “Make rollout patterns safe and standard across teams.”

Needs:
- conventions
- environment governance
- ownership/lifecycle
- auditability
- good module boundaries
- extension points
- migration/cleanup support

## 10.3 Product manager / growth
**JTBD:** “Expose variants to the right audiences and learn from outcomes.”

Needs:
- experiments / variants
- segments
- scheduling
- preview/simulation
- human-readable UI
- safe approvals
- basic analytics hooks

## 10.4 Support / success / operations
**JTBD:** “Turn something on/off for a specific customer and know what changed.”

Needs:
- entity/account targeting
- human-friendly identifiers
- history
- explanation
- safe role boundaries
- maybe temporary overrides with expiration

## 10.5 SRE / DevOps / platform engineer
**JTBD:** “Run this reliably, self-host it, debug drift, and understand failures.”

Needs:
- local evaluation
- explicit cache/refresh behavior
- metrics/traces/logs
- backups/export
- health checks
- low dependency count
- Docker/Kubernetes story
- production-safe defaults

## 10.6 OSS contributor
**JTBD:** “Understand the codebase quickly and contribute safely.”

Needs:
- clean architecture
- devcontainer/docker compose
- fixtures
- e2e tests
- labeled roadmap
- ADRs / design docs
- stable interfaces and behaviors

---

## 11. Recommended architecture for an Elixir-first solution

## 11.1 Package structure
Recommended multi-package or umbrella-like split:

- `feature_flags_core`
  - pure evaluator
  - value model
  - rules
  - variants
  - hashing/stickiness
  - hooks
  - telemetry schema

- `feature_flags_store`
  - persistence behaviors
  - Ecto adapter
  - snapshot serialization
  - optional Redis adapter
  - import/export

- `feature_flags_runtime`
  - cache
  - refresh workers
  - pubsub / polling / streaming
  - process-tree / request propagation
  - Plug / LiveView / Oban integrations

- `feature_flags_admin`
  - Phoenix UI
  - REST / GraphQL / JSON API (if desired)
  - audit/change requests/scheduling
  - auth/authz integration points

- `feature_flags_openfeature` (optional)
  - provider bridge
  - OpenFeature-compatible hooks/context mapping

This gives users a small adoption gradient and keeps the internals legible.

## 11.2 Core evaluation model
At runtime, resolve a value using:
1. snapshot version
2. ordered rules
3. targeting context
4. deterministic bucketing where needed
5. result object containing:
   - value
   - variant key (if any)
   - reason
   - matched rule id
   - flag metadata
   - snapshot version
   - trace (optional / debug mode)

### Recommended result shape
Not just `true/false`.

Prefer something like:
- `value`
- `enabled?`
- `variant`
- `reason`
- `matched_rule`
- `flag_key`
- `flag_version`
- `cache_age_ms`
- `debug_trace` (optional)

Then provide convenience wrappers:
- `enabled?/2`
- `get_boolean/3`
- `get_string/3`
- `get_json/3`
- `get_variant/2`
- `explain/2`

## 11.3 Storage and sync
### Recommendation
Use **snapshot-based local evaluation** as the long-term architecture.

Why:
- evaluator remains fast and store-independent,
- easier to debug/version,
- easy to persist backup state,
- easier to stream/poll/ETag,
- easier to diff environments.

Support:
- Ecto-backed authoring store
- generated runtime snapshot payloads
- ETS in-memory compiled snapshot cache
- optional disk backup
- PubSub / polling / webhooks / streaming for refresh

### Important note
This is better than making runtime evaluation directly dependent on row-by-row DB reads or complex live joins.

## 11.4 Bucketing / stickiness
Use deterministic hashing with:
- `flag_key`
- `rule_key`
- `salt`
- `targeting_key`
- maybe optional `bucket_by` attribute

Support:
- subject-level bucketing
- account/company-level bucketing
- tenant-level bucketing
- session-level fallback only when explicitly allowed

Design requirements:
- stable as rollout increases
- configurable salt/versioning
- migration path if hashing algorithm changes
- explainable in debug output

## 11.5 Context propagation
This is a major Elixir opportunity.

Steal from the strong ideas in the Elixir Unleash client:
- request/process-tree propagation,
- Plug extraction,
- scoped impressions.

Recommended support:
- Plug helper to build and assign context
- LiveView hook to extend context
- Oban middleware to attach context to jobs
- gRPC / Finch / Req / HTTP propagation helpers (later)
- process-tree storage or explicit context passing; if process-tree, be disciplined and transparent

This is extremely valuable for Phoenix applications.

---

## 12. API design recommendations (Elixir ergonomics)

## 12.1 Keep the simple path extremely simple
Examples of a good top-level UX:

```elixir
if Flags.enabled?(:new_checkout, context) do
  ...
end

color =
  Flags.get_string(:checkout_button_color, "blue", context)

variant =
  Flags.get_variant(:checkout_experiment, context)

explanation =
  Flags.explain(:checkout_experiment, context)
```

## 12.2 Use explicit context builders
```elixir
context =
  Flags.Context.new(
    targeting_key: "user:123",
    subject: current_user,
    tenant_key: account.id,
    attributes: %{
      plan: account.plan,
      country: conn.assigns.country,
      staff?: current_user.staff?
    }
  )
```

And framework helpers:
```elixir
context = Flags.Phoenix.context_from_conn(conn)
context = Flags.LiveView.context_from_socket(socket)
context = Flags.Oban.context_from_job(job)
```

## 12.3 Avoid overly magical protocols for everything
FunWithFlags’ Actor/Group protocols are elegant, but for a broader system:
- prefer explicit context normalization,
- then optionally allow protocols/extensions to enrich context.

Protocols are great, but the system should stay inspectable and predictable even without them.

## 12.4 Make “explain” a first-class API
This is one of the most important recommendations.

```elixir
{:ok, result} = Flags.explain(:new_checkout, context)
```

Return a readable structure:
- matched rule
- conditions passed/failed
- bucket calculation summary
- default fallback reason
- snapshot version
- environment
- stale data status if relevant

## 12.5 Make strictness configurable
Examples:
- missing targeting key on experiment rule
- type mismatch in remote config value
- missing segment reference
- stale snapshot
- unknown flag

Support modes:
- permissive
- warn
- strict/fail

---

## 13. Telemetry, tracing, and observability recommendations

This is an area where an Elixir-native library can be exceptional.

## 13.1 Telemetry-first event schema
Emit stable Telemetry events for:
- evaluation start/stop/error
- cache hit/miss/refresh
- snapshot publish/apply
- impression/exposure
- mutation events in admin
- schedule trigger
- approval outcome

Suggested event names:
- `[:flags, :evaluation, :stop]`
- `[:flags, :evaluation, :exception]`
- `[:flags, :cache, :hit]`
- `[:flags, :cache, :miss]`
- `[:flags, :cache, :refresh, :stop]`
- `[:flags, :impression, :recorded]`
- `[:flags, :admin, :mutation]`

Measurements:
- duration
- cache_age_ms
- payload_size_bytes
- matched_rule_count
- trace_enabled?

Metadata:
- flag_key
- flag_type
- variant
- reason
- environment
- namespace
- owner
- stale_state
- has_targeting_key?
- provider/store
- snapshot_version

## 13.2 OpenTelemetry alignment
OpenFeature’s observability guidance is useful:
- span events are low overhead but require active spans,
- log/event-based approaches may be more future-aligned,
- standalone span-per-evaluation can be too expensive.

Recommendation:
- emit Telemetry first,
- provide optional OTel adapters/hooks,
- prefer span events or logs over mandatory extra spans,
- and make all high-cardinality fields configurable/redactable.

## 13.3 Impression and tracking model
Support:
- raw evaluation telemetry
- optional impression recording only when the value was actually used/exposed
- tracking hooks for analytics/conversion events

Do not make people pay the full analytics tax by default.

## 13.4 Debug surfaces
Expose:
- `/health` and maybe `/flags/diagnostics` in admin/runtime modes
- snapshot version and age
- refresh status
- cache stats
- recent changes
- evaluation playground

---

## 14. Admin UI: what “great” should look like

The admin UI is not just a dashboard. It is the system’s teachability layer.

## 14.1 Core pages
### A. Flag index
Show:
- key
- type
- owner
- lifecycle state
- environments
- stale/potentially stale
- last changed
- scheduled changes
- tags

### B. Flag detail
Show:
- description and intent
- type and category
- default value
- ordered rules
- per-environment status
- current schedule
- audit timeline
- code references (later)
- simulation/playground
- recent impression counts (optional)

### C. Simulation / playground
This is mandatory.
Enter:
- targeting key
- account/user info
- traits
- environment
- namespace

Return:
- value / variant
- matched rule
- why
- bucket result
- trace
- related segment matches

### D. Timeline / audit
Show:
- who changed what
- before/after diff
- environment
- approval context
- rollback affordance
- linked change request

### E. Lifecycle view
Show:
- potentially stale / stale
- owner
- expiration
- created_at / last_seen_at
- cleanup status
- generated issues / PR hooks (if configured)

## 14.2 UX principles
- Human-first language.
- Always show the **effective value** and **why**.
- Make rule order and precedence visually obvious.
- Minimize hidden behavior.
- Make production changes feel deliberate.
- Keep support-friendly entity targeting easy.
- Use clear danger states for broad production changes.

## 14.3 AI assistance ideas
A “great admin AI” can be useful, but do not make correctness depend on it.

Good AI uses:
- “Explain this flag’s rollout in plain English.”
- “What changed in production this morning?”
- “Simulate this flag for enterprise EU customers.”
- “Suggest cleanup candidates.”
- “Generate rollout plan from 5% to 100%.”

Bad AI uses:
- silently mutating production config,
- inventing segments/rules,
- hiding exact diff details.

AI should be a thin layer over a highly legible underlying model.

---

## 15. Security, auth, privacy, and compliance considerations

## 15.1 Do not hardcode auth assumptions
The admin package should integrate cleanly with:
- Phoenix auth stacks,
- reverse proxies,
- SSO/OIDC,
- plug-based authn/authz.

Provide behaviors/hooks, not a giant auth opinion.

## 15.2 Environment-sensitive authorization
At minimum, allow:
- read-only viewers
- editors for non-prod
- controlled editors / approvers for prod

## 15.3 Sensitive context handling
Support:
- secure attributes
- redacted logging
- impression field allowlists
- ephemeral/transient traits
- privacy mode for evaluation traces

## 15.4 Server-side only flags
This should be explicit in the model if you later support client-side SDK payloads.

---

## 16. Testing strategy recommendations

This is a major adoption lever in Elixir.

## 16.1 Unit tests
Provide helpers:
- `with_flag/3`
- `put_flag/3`
- `clear_flags/0`
- fixed-seed bucketing
- strict assertions around explain traces

## 16.2 Phoenix / LiveView tests
Provide:
- conn helpers
- socket helpers
- context injection helpers

## 16.3 Integration tests
Support:
- temporary store adapters
- sandbox-friendly Ecto usage
- deterministic snapshots
- process isolation

## 16.4 E2E/browser tests
Provide:
- query/header override support in dev/test only
- explicit test-only override mode
- admin fixture generators
- docker-compose local stack for Playwright/Cypress-like flows

## 16.5 What to test in the library itself
- rule ordering
- segment overlap
- sticky bucketing stability
- rollout percentage migration
- snapshot versioning
- cache refresh behavior
- pubsub/polling races
- schedule execution
- approval gating
- import/export round trips
- telemetry contract stability

---

## 17. CI/CD, release engineering, contributor DX

The OSS contributor story is part of the product.

## 17.1 Local development
Provide:
- `docker compose up` for local dependencies if any
- one-command bootstrap
- seeded demo data
- sample Phoenix host app
- dev docs for common flows

If possible, keep the default local path runnable with:
- no external dependencies for the pure runtime package,
- optional dependencies only for admin/store modes.

## 17.2 CI
Recommended GitHub Actions matrix:
- Elixir/OTP matrix
- formatter
- credo
- dialyzer
- unit tests
- integration tests by adapter
- UI tests
- docs build
- package smoke tests

## 17.3 Release process
- SemVer
- changelog discipline
- compatibility matrix
- upgrade guides
- feature flags for experimental features in the library itself if needed

## 17.4 Contributor docs
Ship:
- architecture overview
- ADRs
- glossary
- event schema docs
- extension guide
- adapter guide
- test harness guide
- “good first issue” curation

## 17.5 Demo and reference apps
Have at least:
- minimal runtime-only app
- Phoenix + admin UI app
- multi-node example
- experiment/variant demo
- Oban propagation demo

---

## 18. Concrete product decisions I recommend

## 18.1 Build booleans and multivariate values from the same core
Do not bolt multivariate on later.

## 18.2 Prefer ordered rules over implicit gate priority
It will make simulation, docs, and UI better.

## 18.3 Make explainability a first-class capability from day 1
This is not optional.

## 18.4 Make lifecycle metadata mandatory at creation
Require:
- owner/team
- flag category
- intended expiration or “permanent”
- description of business/technical purpose

## 18.5 Treat experimentation as adjacent, but not mandatory
Have variants + impressions + tracking hooks in the core design.
Do not require a built-in statistics engine in v1.

## 18.6 Separate snapshot evaluation from authoring persistence
This will pay off across performance, clarity, and deployment.

## 18.7 Build Plug/Phoenix/LiveView/Oban ergonomics early
This is where the Elixir-native advantage is real.

## 18.8 Telemetry should be excellent before analytics is ambitious
A clean event model beats a half-baked built-in experiment dashboard.

## 18.9 Make self-hosting pleasant
Strong Docker, health checks, logs, metrics, import/export, and backups are worth real adoption.

## 18.10 Keep the codebase boring in the best way
Use explicit boundaries, behaviors, small modules, and testable pure functions.
This project should feel easy to extend and easy to audit.

---

## 19. What NOT to do

- Do not make DB reads the default runtime evaluation path.
- Do not hide precedence rules in clever magic.
- Do not make experiments require an analytics warehouse on day 1.
- Do not default to per-request randomness for user-facing features.
- Do not make the admin UI a thin CRUD shell without simulation/explain.
- Do not rely on undocumented process dictionary magic everywhere.
- Do not let flags be created without owner/lifecycle metadata.
- Do not mix host-app auth assumptions deep into the core library.
- Do not make contributor setup painful.

---

## 20. Suggested phased roadmap

## Phase 1 — serious OSS runtime
Deliver:
- local evaluator
- booleans + multivariate values
- ordered rules
- deterministic bucketing
- ETS compiled snapshot cache
- Ecto store adapter
- Plug/Phoenix/LiveView helpers
- telemetry
- explain API
- test helpers

This alone would already be meaningful.

## Phase 2 — governance/admin foundation
Deliver:
- Phoenix admin UI
- environments/projects/namespaces
- audit log
- owner/lifecycle fields
- stale/potentially stale states
- simulation/playground
- scheduling
- import/export

## Phase 3 — production governance
Deliver:
- approvals/change requests
- environment-sensitive permissions
- webhooks
- rollout templates
- recent-change timeline
- better diagnostics pages

## Phase 4 — experimentation / ecosystem leverage
Deliver:
- variant impressions/exposure hooks
- tracking hooks
- OpenFeature bridge
- code references / cleanup support
- GitHub integration for stale-flag cleanup workflows

---

## 21. Proposed differentiators for this Elixir project

If you want this to become the obvious answer in the ecosystem, here are the real differentiators:

### 1) Phoenix-native explainability
Best-in-class simulation and “why did this happen?” for BEAM apps.

### 2) Request/job propagation done right
First-class context flow for Plug, LiveView, Oban, and later gRPC.

### 3) Runtime + control plane split
Tiny embeddable runtime; optional powerful admin/governance package.

### 4) Lifecycle hygiene as product doctrine
Owner, expiration, stale state, cleanup workflow from day 1.

### 5) Telemetry and OTel friendliness
Beautiful Telemetry events and easy OTel hooks.

### 6) Great self-hosting
Easy Docker, health, observability, export/import, backups.

### 7) Great contributor story
Readable internals, documented contracts, extensible adapters.

---

## 22. A concrete “north star” product statement

> Build the feature-management library Elixir teams wish they already had:  
> fast local evaluation, rich multivariate targeting, first-class explainability, strong Phoenix ergonomics, strong telemetry, strong lifecycle hygiene, and an intuitive self-hosted admin plane that makes safe rollout and cleanup feel normal instead of heroic.

---

## 23. Source-backed research notes (compressed)

This section summarizes the most important evidence behind the recommendations.

### Elixir / FunWithFlags / Unleash
- FunWithFlags provides two-level storage, ETS local cache, Redis/relational DB persistence, PubSub cache invalidation, optional UI Plug, and Telemetry.
- FunWithFlags gate priority is actor > group > boolean > percentage, and disabled group gates win over enabled group gates in conflicts.
- FunWithFlags docs explicitly mention startup race conditions when it depends on host-owned processes like Phoenix.PubSub, and public issues/forum discussions show users encountering startup/test confusion.
- The separate UI package intentionally leaves auth/security to the host.
- Elixir Unleash clients demonstrate demand for richer control planes from Elixir apps and contribute strong ideas around context propagation, variants, impressions, and telemetry.

### Unleash
- Unleash’s unified flag model separates core flag identity from environment-specific configuration.
- Stickiness guarantees stable experiences for the same user; missing context makes multi-variant assignment random per request.
- Unleash models active / potentially stale / stale and automatically marks flags as potentially stale after expected lifetime.
- Event timelines, audit-ish event streams, and environment-sensitive permissions are first-class.

### GrowthBook
- Rules are ordered top-to-bottom and first match wins.
- Rule types cleanly distinguish force/rollout/experiment/safe rollout.
- Simulation and archetypes are first-class.
- DevTools expose current values, overrides, debug logs, and relevant attributes.

### Flipper
- Great OSS ergonomics and local evaluation model.
- Docs explicitly warn not to use percentage-of-time for user-facing slow rollouts.
- Cloud product adds environments, audit history, permissions, rollbacks, telemetry.
- Production extension work highlights the importance of human-friendly actor identifiers and instrumentation hooks.

### Flagsmith
- Supports boolean + multivariate values, identities, segments, audit logs, scheduled changes/change requests.
- Real-time update events still require clients to re-fetch actual state.
- Overlapping segment precedence can be cognitively difficult.
- Identity-backed multivariate assignment needs stable identity.

### Flipt
- Strong self-hosting story: metrics, tracing, audit sinks, multiple storage backends, Git-native v2, environment isolation, branching, merge proposals, commit signing, GitHub Actions.
- Shows that “ops ergonomics” can be a serious differentiator for OSS adoption.

### LaunchDarkly
- Strong governance lessons: approvals, change history/rollback, scheduled changes, progressive rollout workflows, lifecycle guidance.
- Valuable reminder that governance features are not just enterprise fluff; they reduce production mistakes and cleanup failures.

### OpenFeature
- Strong conceptual split between evaluation API and provider.
- Hooks and evaluation context are excellent abstractions.
- Tracking and observability guidance map well onto Elixir Telemetry + OTel designs.

### Research / process
- Research literature consistently identifies stale-flag cleanup as a major issue and recommends automated processes/policies.
- Feature flags reduce branching/merge pain, but they are not free: they add complexity and require discipline around testing, interactions, and cleanup.

---

## 24. Final recommendation

If you are serious about closing this ecosystem gap, I would define the project around these promises:

1. **Elixir-first runtime ergonomics**  
   Tiny API, pure evaluator, fast local snapshots, Telemetry, Plug/Phoenix/LiveView/Oban integrations.

2. **Value-based feature management**  
   Booleans, variants, and remote config under one coherent model.

3. **Explainability everywhere**  
   Simulation, traces, rule reasoning, recent-change visibility.

4. **Lifecycle hygiene by design**  
   Owner, expiration, stale state, cleanup workflow.

5. **Self-hostable governance**  
   Audit, scheduling, approvals later, environment isolation, sane auth hooks.

6. **Boring-to-maintain internals**  
   Crisp boundaries, behaviors, tests, docs, examples, contributor-friendly code.

If you get those right, you will not just build “another flag library.” You will likely create the default answer for serious Phoenix teams.

---

## 25. Suggested initial module sketch

```text
Flags
Flags.Context
Flags.Result
Flags.Rule
Flags.Condition
Flags.Variant
Flags.Explain

Flags.Runtime
Flags.Runtime.Cache
Flags.Runtime.Snapshot
Flags.Runtime.Refresh
Flags.Runtime.Hooks
Flags.Runtime.Telemetry

Flags.Store
Flags.Store.Ecto
Flags.Store.Redis   # optional
Flags.Store.Export
Flags.Store.Import

Flags.Phoenix
Flags.Phoenix.Plug
Flags.Phoenix.LiveView
Flags.Oban

Flags.Admin
Flags.Admin.Audit
Flags.Admin.Schedule
Flags.Admin.Approvals   # later
Flags.Admin.Policy
Flags.Admin.UI
```

---

## 26. Suggested first ADRs (architecture decision records)

Write these very early:

1. **Why ordered rules instead of gate precedence**
2. **Why snapshot-based local evaluation**
3. **How targeting keys and stickiness work**
4. **How Telemetry events are versioned**
5. **What counts as a flag type and lifecycle policy**
6. **How environments/projects/namespaces are modeled**
7. **How context propagation works in Plug/LiveView/Oban**
8. **What “strict mode” does**
9. **What the admin package depends on vs core**
10. **How privacy/redaction works for context and impressions**

---

## 27. Minimal v1 acceptance criteria

A good v1 should let a Phoenix team:

- create boolean and multivariate flags,
- target by ordered rules with attributes and reusable segments,
- evaluate locally in application code,
- get deterministic bucketing with targeting keys,
- inspect why a decision happened,
- run an embedded admin UI,
- see audit history,
- schedule simple changes,
- use Telemetry,
- test deterministically,
- and operate it locally with Docker plus docs in under 15 minutes.

If you can do that with clean code and good docs, you will already have moved the Elixir ecosystem meaningfully forward.

---

## 28. Primary source list

Below is the main body of source material used to derive this brief. Titles are kept concise so this section can also act as a reading list for follow-up work.

### Elixir ecosystem
- FunWithFlags README and docs
- FunWithFlags.UI README
- FunWithFlags GitHub issues about Phoenix.PubSub startup/retries
- ElixirForum discussion on FunWithFlags async test behavior
- fork_with_flags README
- Unleash HexDocs / package docs for Elixir client and propagation

### Feature-flag platforms / docs
- Unleash docs: organization model, events, stickiness, variants, technical debt
- GrowthBook docs: rules, simulation/archetypes, DevTools, webhooks
- Flipper docs: percentage of time, percentage of actors, cloud intro
- Evil Martians article on extending Flipper
- Flagsmith docs: audit logs, scheduled flags, real-time updates, FAQ
- Flipt docs: configuration, observability, auditing, v2 introduction
- LaunchDarkly docs: change history, approvals, scheduled changes, lifecycle guidance
- OpenFeature docs/spec: evaluation API, context, hooks, tracking, observability appendix
- Django Waffle docs

### Research / broader practice
- Martin Fowler on Feature Toggles / carrying cost
- Meinicke et al., “Exploring Differences and Commonalities between Feature Flags and Configuration Options”
- Empirical paper on adoption effects / merge effort and complexity tradeoffs

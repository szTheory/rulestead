# Phase 3: Context, Rules, Deterministic Bucketing, Pure Evaluator - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** 5 parallel advisor passes across all major evaluator gray areas, then one coherent synthesis

<domain>
## Phase Boundary

**Goal:** Ship the pure, fast, deterministic runtime evaluator that resolves booleans, values, and variants from an in-memory ruleset with first-match-wins semantics, deterministic bucketing, explicit context, and first-class explainability.

**In scope:**
- `Rulestead.Context` runtime input model and builder semantics
- Pure evaluation APIs: `enabled?/2`, `get_value/3`, `get_variant/2`, `evaluate/3`, `explain/2`
- `Rulestead.Result` shape and Phase 3 explain/debug surface
- Rule predicate semantics for `equals`, `in`, `not_in`, `gt`, `lt`, `gte`, `lte`, `regex`, `exists`
- Reusable audience/segment references during evaluation
- Deterministic bucketing and variant assignment
- Property-testable determinism and precedence invariants

**Out of scope (explicitly deferred):**
- Snapshot versioning, cache age, stale snapshot handling, ETS runtime cache, PubSub refresh, disk backup (Phase 4)
- Plug/LiveView/Oban context extraction helpers and process propagation (Phase 5)
- Admin rule-builder UX, simulation UI, operator-facing explain pages (Phases 6-7)
- OpenFeature provider parity, typed getter family expansion, multi-kind context modeling beyond current Phase 3 needs (future phase if justified)

</domain>

<decisions>
## Implementation Decisions

### Context Model
- **D-01:** Canonical runtime shape is `%Rulestead.Context{actor, targeting_key, tenant_key, environment, attributes, request_id, session_id, strict?}`.
- **D-02:** `actor` is the canonical noun everywhere in runtime/docs/code. `subject` is not part of the public struct.
- **D-03:** `targeting_key` remains a first-class field distinct from `actor`; when absent, `Context.new/1` may default it from `actor.key`, but evaluator logic must treat the normalized struct as authoritative.
- **D-04:** `tenant_key` and `environment` stay top-level rather than being buried inside `attributes`.
- **D-05:** If compatibility smoothing is needed, `Context.new(subject: ...)` may be accepted as a temporary input alias only, normalized immediately to `actor`, and never documented as canonical.

### Evaluation Surface
- **D-06:** Phase 3 locks one explicit in-memory public input contract: the first argument to `evaluate/3`, `enabled?/2`, `get_value/3`, `get_variant/2`, and `explain/2` is the authored flag payload already loaded in memory for evaluation, i.e. the active flag state document carrying the active ruleset. Bare `flag_key` lookup, hidden store fetches, ad hoc lookup opts, and Phase 4 runtime snapshot registries are out of scope for Phase 3.
- **D-07:** `evaluate/3` is the canonical evaluator over that in-memory flag payload and normalized context. It returns `{:ok, %Rulestead.Result{}} | {:error, %Rulestead.Error{}}`; `evaluate!/3` raises the same `%Rulestead.Error{}` on the error path.
- **D-08:** `enabled?/2`, `get_value/3`, `get_variant/2`, and `explain/2` are thin non-bang projections over the same `evaluate/3` result path, not separate evaluation systems. Their public contracts are `{:ok, boolean} | {:error, %Rulestead.Error{}}`, `{:ok, value} | {:error, %Rulestead.Error{}}`, `{:ok, variant_key | nil} | {:error, %Rulestead.Error{}}`, and `{:ok, human_readable_trace} | {:error, %Rulestead.Error{}}` respectively.
- **D-09:** `get_value/3` requires an explicit default in the third argument and uses that default only on successful evaluation paths where no rule matches or the flag value is otherwise absent for the requested projection. Strict-mode evaluator errors are returned unchanged, not converted into fail-closed defaults.
- **D-10:** Raw map/keyword context input may still be normalized through `Rulestead.Context.new/1`, but Phase 3 does not add extra public opts or alternate arities to evaluation helpers beyond the locked signatures above. Defer typed getter families such as `get_boolean` / `get_string` / `get_integer` / `get_float` / `get_map` until after Phase 3 usage proves they are worth locking as public API.

### Condition Semantics
- **D-11:** Support nested attribute paths in Phase 3, but only for map traversal. Use one stable persisted syntax: dot-separated path strings compiled internally to path segments.
- **D-12:** Do not support array indexing, wildcards, or nested boolean expression trees in Phase 3.
- **D-13:** Normalize condition payloads by operator:
  - scalar payload for `equals`, `gt`, `lt`, `gte`, `lte`
  - homogeneous list payload for `in`, `not_in`
  - `%{pattern: binary, options: binary}` payload for `regex`
  - no payload for `exists`
- **D-14:** Comparison semantics are strict:
  - `equals`: same-type equality, except integer/float may compare within the numeric lane
  - `gt`, `lt`, `gte`, `lte`: numbers only, no string-to-number coercion
  - `in`, `not_in`: same-type membership only, no coercion
  - `regex`: binaries only; validate/compile at save or snapshot-compile time; no implicit case folding
  - `exists`: true only when the path resolves to a non-`nil` value
- **D-15:** Missing attributes are deterministic non-matches:
  - `exists` returns `false`
  - all other operators return non-match with explain/debug reason `:missing_attribute`
- **D-16:** Unsupported comparison/type mismatches should be rejected during changeset/compile when possible. If malformed persisted data reaches runtime, evaluation returns deterministic non-match plus explicit trace reason, and strict mode escalates to fail-closed structured error behavior.

### Bucketing and Stickiness
- **D-17:** Use `hash_version: 1` and deterministic `:sha256` hashing over a canonical iodata shape including namespace, `flag_key`, `rule_key`, effective salt, and resolved targeting value.
- **D-18:** Convert the first 8 bytes of the digest to an unsigned integer and `rem(10_000)`, producing buckets in `0..9999`.
- **D-19:** Keep authored percentages/weights at `0..100`, but compile them internally to basis points (`pct * 100`) so bucket precision and API stability remain compatible.
- **D-20:** Use two hash namespaces:
  - `rollout` for exposure inclusion
  - `variant` for variant assignment
  This prevents already-exposed users from reshuffling variants when rollout percentage increases.
- **D-21:** Salt layering is additive, not replacement-based. Effective salt composition must include ruleset salt, optional rule rollout salt, `bucket_by`, and namespace.
- **D-22:** Resolve `bucket_by` only from normalized scalar context fields:
  - `:subject` -> `context.targeting_key`
  - `:account` -> `context.attributes[:account_key] || context.attributes["account_key"] || context.attributes[:account_id] || context.attributes["account_id"]`
  - `:tenant` -> `context.tenant_key`
  - `:session` -> `context.session_id`
- **D-23:** The evaluator must not inspect arbitrary `context.actor` data for bucketing. Builders may normalize into scalar fields, but the evaluator stays explicit and explainable.
- **D-24:** Missing required identity on sticky rules:
  - normal mode: emit warning/debug reason and treat the rule as non-applicable, continuing to later rules/default
  - strict mode: emit warning/debug reason and return `{:error, %Rulestead.Error{type: :missing_targeting_key}}` immediately from non-bang evaluation APIs; `evaluate!/3` raises the same typed error
- **D-24a:** To preserve Phase 3 purity while satisfying EVAL-07, the evaluator records the missing-sticky-identity warning fact in the result/trace, and the public API wrapper emits one direct sanitized telemetry warning event from that fact in permissive mode. This does not introduce the Phase 4 telemetry wrapper or event catalog.
- **D-25:** No implicit fallback chain (`subject -> tenant -> session -> random`). Session stickiness only happens when a rule explicitly chooses `bucket_by: :session`.

### Explainability and Result Shape
- **D-26:** `Rulestead.Result.reason` stays compact and stable as a closed reason enum style surface, e.g. `:rule_match`, `:default`, `:targeting_key_missing`, `:flag_off`, `:error`.
- **D-27:** `Rulestead.Result.debug_trace` is the stable machine-readable explain contract. It is optional, structured, and intended for tests, tooling, and future admin UI.
- **D-28:** `Rulestead.explain/2` returns a human-readable explanation rendered from the same evaluation facts as `debug_trace`. The prose is for humans, not parsing.
- **D-29:** Phase 3 `debug_trace` includes only evaluation facts:
  - matched rule identity/order
  - condition pass/fail entries
  - referenced audience/segment hits
  - bucketing inputs actually used, bucket result, and variant/range decision
  - fallback/default path
  - strictness-related outcomes
- **D-30:** Phase 3 `debug_trace` explicitly excludes Phase 4 diagnostics such as snapshot version, cache age, stale-state, and telemetry payload details.

### Testing and Contract Discipline
- **D-31:** Property tests own determinism, precedence, and explain/evaluate consistency. Invalid condition/type states should be minimized by compile-time validation rather than explored at runtime.
- **D-32:** Tests split by contract:
  - property/contract tests on `debug_trace`
  - renderer/snapshot-style tests for `explain/2`
  - invariant: `explain/2` must describe the same outcome as `evaluate/3`

### the agent's Discretion
- Exact internal module layout for evaluator/compiler/bucket helpers
- Whether `actor` is a plain map/struct-friendly field or a dedicated lightweight struct internally, provided the public context contract above remains intact
- Exact trace nesting/field names, provided the locked content boundary above is preserved
- Exact warning/error atom names, provided they remain compact, typed, and coherent with `%Rulestead.Error{}`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 3 goal, scope, success criteria, and dependency boundary with Phases 4 and 5
- `.planning/REQUIREMENTS.md` — source of truth for `EVAL-01..09`, `CTX-01`, `RULE-01..04`, and `TEST-04`
- `.planning/PROJECT.md` — non-negotiables: pure evaluator, deterministic assignment, explainability, explicit context, least-surprise DX
- `.planning/STATE.md` — confirms current milestone/focus and sequencing

### Prior Locked Decisions
- `.planning/phases/01-repo-bootstrap/01-CONTEXT.md` — inherited package/release/CI constraints that Phase 3 must preserve
- `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md` — locked store/error/ruleset persistence decisions that Phase 3 must build on

### Product and Domain Direction
- `prompts/elixir_feature_flags_research_brief.md` — local evaluation, deterministic bucketing, strict mode, explainability, and rollout footguns
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns, especially `Flag`, `Rule`, `Condition`, `Audience`, `Context`, `Actor`, `Targeting key`
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — API ergonomics, fake-first testing posture, and explicit public contract discipline
- `prompts/rulestead-testing-and-e2e-strategy.md` — property-test expectations, Fake semantics, and explain/evaluate invariants

### Existing Runtime Surface
- `rulestead/lib/rulestead.ex` — current public API stub and bang/non-bang conventions to extend coherently
- `rulestead/lib/rulestead/ruleset.ex` — current ruleset persistence shape
- `rulestead/lib/rulestead/ruleset/rule.ex` — current strategy/variant/rollout embedding and validations
- `rulestead/lib/rulestead/ruleset/condition.ex` — current condition persistence shape that Phase 3 will tighten semantically
- `rulestead/lib/rulestead/ruleset/rollout.ex` — current `bucket_by` and percentage authoring model
- `rulestead/lib/rulestead/ruleset/variant.ex` — current variant shape and weight validation
- `rulestead/lib/rulestead/fake.ex` — fake adapter contract and future evaluator integration seam

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead/lib/rulestead.ex` — already establishes the public root surface and bang/non-bang convention that Phase 3 evaluator APIs should extend
- `rulestead/lib/rulestead/ruleset/*.ex` — embedded ruleset document model already exists and should be compiled/evaluated rather than replaced with a new authoring shape
- `rulestead/lib/rulestead/fake.ex` — the fake store is the right Phase 3 test harness for evaluator/property tests and later test helpers
- `rulestead/test/support/store_contract_case.ex` and `rulestead/test/support/store_fixtures.ex` — existing shared-test posture can be extended for evaluator contract coverage

### Established Patterns
- Public runtime APIs return stable structs/tuples and reserve bang variants for raising equivalents
- Explicit domain nouns matter; Phase 2 already locked key-first store behavior and immutable ruleset publishing
- The project prefers compile-time/changeset validation over permissive runtime ambiguity

### Integration Points
- `Rulestead.Store.fetch_flag/3` payload shape will feed evaluator compilation/loading
- Future Phase 4 snapshot compiler can reuse the same normalized condition and bucketing decisions without semantic changes
- Future Phase 5 builders should normalize host-framework data into the locked `Rulestead.Context` shape above, not invent alternate context models

</code_context>

<specifics>
## Specific Ideas

- Treat `targeting_key` as an explicit bucketing override, not as a synonym for actor.
- Keep the evaluator strict and explainable rather than preserving loose Phase 2 `:map` payloads for convenience.
- Make rollout inclusion and variant assignment separate deterministic steps so expanding rollout percentages does not reshuffle already-exposed users.
- Keep `debug_trace` factual and machine-readable; keep `explain/2` human-readable and renderer-based.
- Optimize for the Phase 3 runtime contract that future admin UX will consume, not for the easiest short-term implementation.

</specifics>

<deferred>
## Deferred Ideas

- Typed getter family (`get_boolean`, `get_string`, etc.) — defer until real usage shows they are worth locking
- Rich multi-kind context modeling beyond current `actor` + scalar keys — defer until a future interoperability phase requires it
- Array-path selectors, wildcards, or expression-tree conditions — defer until a later phase proves the admin/runtime complexity is justified
- Phase 4 diagnostics in trace output (`snapshot_version`, `cache_age_ms`, stale-state) — intentionally deferred to the runtime/snapshot phase
- General telemetry wrapper/catalog work beyond the narrow missing-sticky-identity warning event in D-24a — intentionally deferred to the runtime/telemetry phase
- Admin/operator-facing trace presentation model — defer to simulation/admin phases; Phase 3 only locks the factual trace substrate

</deferred>

---

*Phase: 03-context-rules-deterministic-bucketing-pure-evaluator*
*Context gathered: 2026-04-23*

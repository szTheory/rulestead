# Phase 3: Context, Rules, Deterministic Bucketing, Pure Evaluator - Discussion Log

**Date:** 2026-04-23
**Mode:** One-shot advisor synthesis
**Selection:** User selected all major gray areas and explicitly requested subagent-backed research, tradeoff analysis, and a coherent recommendation set without iterative back-and-forth.

## Areas Discussed

### 1. Context Shape and Naming
**Options considered:**
- Flat hybrid context with `actor` + `targeting_key`
- Nested actor-first context
- OpenFeature-minimal context with actor/tenant folded into attributes
- Legacy subject-centric flat context

**Selected direction:**
- Flat hybrid context with canonical `%Rulestead.Context{actor, targeting_key, tenant_key, environment, attributes, request_id, session_id, strict?}`

**Why it won:**
- Best fit for the field guide and project language
- Most idiomatic for Phoenix/Plug/Oban builders later
- Preserves explicit evaluator fields without over-modeling
- Avoids shipping `subject` as a public core noun

### 2. Value Representation and Getter Semantics
**Options considered:**
- Strict value-first core with boolean convenience and typed getters deferred
- Boolean-special-cased public UX
- OpenFeature-style typed getters now
- Result-first hard errors on convenience misuse

**Selected direction:**
- Strict value-first core, with `evaluate/3` canonical and convenience APIs as projections

**Why it won:**
- Keeps one coherent mental model
- Best aligns with `%Rulestead.Result{}` and `explain/2`
- Avoids premature API expansion
- Preserves good DX without splitting runtime semantics into multiple systems

### 3. Condition Language Details
**Options considered:**
- Flat keys + opaque map payload + permissive coercion
- Flat keys + normalized typed payloads
- Nested paths + opaque map payload
- Nested paths + normalized typed payloads + strict comparisons

**Selected direction:**
- Nested paths with operator-specific normalized payloads and strict comparisons

**Why it won:**
- Strongest explainability and property-test surface
- Better future admin UX than fake-flat keys or loose payload maps
- Matches realistic context shapes from Phoenix/Plug/Oban apps
- Avoids coercion footguns and ambiguous runtime behavior

### 4. Bucketing and Sticky Assignment
**Options considered:**
- Coarse 0..99 bucket with fallback chain and possible randomness
- Context-kind + bucket-attribute model
- Single-stage SHA-256 / 10k bucket
- Two-stage SHA-256 / 10k bucket with layered salts and explicit identities

**Selected direction:**
- Two-stage SHA-256 / 10k buckets, layered salts, explicit `bucket_by`, no hidden fallback

**Why it won:**
- Preserves determinism and explainability
- Avoids reshuffling assigned variants when rollout percentage grows
- Fits pure Elixir runtime and snapshot/test reuse well
- Makes operator semantics explicit instead of magical

### 5. Explain / Debug Trace Shape
**Options considered:**
- Human-only explain string
- Flat metadata map plus explain string
- Structured core trace in `debug_trace` plus human renderer in `explain/2`
- Rich operator-facing public trace object now

**Selected direction:**
- Structured machine-readable core trace in `Result.debug_trace`, human-readable renderer in `Rulestead.explain/2`

**Why it won:**
- Best long-term base for Phase 7 simulation UI
- Keeps testing and API contracts clean
- Avoids freezing UI/presentation concerns into the runtime too early
- Lets Phase 4 diagnostics arrive later without muddying Phase 3 explain semantics

## Coherence Notes

The final recommendation set was intentionally normalized into one architecture:

- explicit `actor` + `targeting_key` context shape
- value-first evaluation API
- strict typed condition semantics
- deterministic explicit bucketing
- structured factual trace with renderer-based human explanation

These choices reinforce each other. None require hidden evaluator state, ambient context, permissive coercion, or UI-shaped runtime contracts.

## Deferred Follow-Ups

- Typed getter family after real usage validates the need
- Richer context kinds if future interoperability requires them
- More expressive condition grammar only if later admin/runtime value clearly outweighs complexity
- Runtime diagnostics fields in trace after Phase 4 ships

---

> Decisions are captured in `03-CONTEXT.md` — this log preserves the alternatives considered and why the selected direction won.

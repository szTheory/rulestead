# Phase 26: API Lockdown & Documentation Perfection - Research

**Researched:** `date`
**Domain:** Elixir documentation, Dialyzer typing, and ExDoc configuration
**Confidence:** HIGH

## Summary
The goal of Phase 26 is to lock down the public API boundary by hiding internal modules, ensuring exhaustive type specifications to pass Dialyzer cleanly, and providing a cohesive ExDoc experience complete with guides and migration paths.

**Primary recommendation:** Use `@moduledoc false` pervasively for all non-public modules, add a `.dialyzer_ignore.exs` file if there are external task dependencies, ensure HexDocs `mix.exs` is explicitly organized with `groups_for_modules` and `groups_for_extras`, and create a `guides/recipes/migrating-from-funwithflags.md` guide that maps "gates" to "rules".

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- All internal modules must be strictly marked with `@moduledoc false` to establish a clear public API boundary.
- Public API functions must have comprehensive type specifications.
- The project must pass Dialyzer with zero warnings.
- Hexdocs must include complete module documentation, architecture guides, and deployment recipes.
- A migration guide for FunWithFlags users must be available in the documentation.

### the agent's Discretion
None explicitly stated, but execution details of ExDoc structure and the exact content of the migration guide fall here.

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| API-01 | All internal modules are strictly marked with `@moduledoc false` to establish a clear public API boundary. | The facade and explicitly shared structs are public. All implementation modules (e.g. `Manifest.*`, `Store.Command.*`) must get `@moduledoc false`. |
| API-02 | Public API functions have comprehensive type specifications, and the project passes Dialyzer with zero warnings. | Dialyzer currently reports 118 warnings, primarily around `Ecto.Multi` ops, missing return type specs in `Rulestead.Config`, and unused Mix task commands. We will provide a strict typing pass. |
| DOC-01 | Hexdocs includes complete module documentation, architecture guides, and deployment recipes. | Configure `groups_for_extras` and `groups_for_modules` in `mix.exs` to logically separate Introductions, Flows, and Recipes. |
| DOC-02 | A migration guide for FunWithFlags users is available in the documentation. | Add a new file `guides/recipes/migrating-from-funwithflags.md` that maps boolean toggles, actor mappings, and UI changes to Rulestead's model. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Documentation Generation | HexDocs (ex_doc) | — | Standard Elixir packaging tool; organizes markdown files and module docs. |
| Type Checking | Dialyzer / Dialyxir | — | Erlang/Elixir standard for static analysis and type warnings. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ex_doc | ~> 0.38 | Hex documentation | The only supported tool for Elixir docs. |
| dialyxir | ~> 1.4 | Dialyzer integration | Elixir standard tool for interacting with the Erlang Dialyzer tool. |

**Installation:**
Already present in `mix.exs`.

## Dialyzer Resolution Strategy
The current output of `mix dialyzer` yields 118 warnings. The most prominent are:
1. `call_without_opaque` on `Ecto.Multi.run` inside `Rulestead.Store.Ecto`. This requires properly typing the arguments or updating the `dialyzer` configuration.
2. `missing_range` on `Rulestead.Config.validate!/1` returning `map()` but documented as `Keyword.t()`.
3. `pattern_match` failing in `Rulestead.ex:1527` where `when _ :: map() === nil` occurs.
4. Missing HTTP client (`:inets` / `:httpc`) for mix tasks (e.g., `verify.release_parity.ex`).
**Solution**: Fix `Ecto.Multi` type definitions where possible, correct local types (like in `Rulestead.Config`), and define a `.dialyzer_ignore.exs` file to mask warnings for Mix tasks using undocumented/missing remote apps (`:inets`) if they aren't part of the core runtime.

## Architecture Patterns

### Moduledoc Hiding & Groups
Instead of an unstructured module list, `Rulestead` will enforce a strict public API by explicitly declaring groups in `mix.exs`. Any module not belonging to the public API will receive a `@moduledoc false` directive.

```elixir
defp docs do
  [
    groups_for_modules: [
      "Public API": [
        Rulestead,
        Rulestead.Ruleset,
        Rulestead.Rule,
        Rulestead.Flag,
        Rulestead.Result,
        Rulestead.Error
      ],
      "Store Adapters": [
        Rulestead.Store.Ecto,
        Rulestead.Store.Redis
      ],
      "Extensibility": [
        Rulestead.Store,
        Rulestead.Runtime.Snapshot,
        Rulestead.Tenancy
      ]
    ],
    groups_for_extras: [
      "Introduction": ~r"guides/introduction/",
      "Flows": ~r"guides/flows/",
      "Recipes": ~r"guides/recipes/"
    ]
  ]
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Grouping modules | A custom index file | `groups_for_modules` | ExDoc has built-in grouping. |
| Hiding internals | Undocumented functions | `@moduledoc false` and `@doc false` | Explicit omission removes modules entirely from Hexdocs index. |

## Common Pitfalls

### Pitfall 1: Leaking Internal Modules
**What goes wrong:** Modules like `Rulestead.Manifest.Render` show up in Hexdocs, confusing users about the API surface.
**Why it happens:** Missing `@moduledoc false` in the module definition.
**How to avoid:** Aggressive checking across any `defmodule` inside `lib/` and applying `@moduledoc false` unless it's explicitly public.

### Pitfall 2: FunWithFlags Conceptual Leak
**What goes wrong:** Reusing terms like "gate" or "priority" in the migration guide.
**Why it happens:** FunWithFlags heavily relies on actor/group/boolean gates.
**How to avoid:** Explicitly state the terminology shift: "Gates" are "Rules", "Priority" is "Ordered Evaluation".

## FunWithFlags Migration Path

To migrate from FunWithFlags, developers need a step-by-step map matching operations to Rulestead's paradigm:

| FunWithFlags Concept | Rulestead Equivalent | Notes |
|----------------------|----------------------|-------|
| `FunWithFlags.enabled?(:flag)` | `Rulestead.enabled?(flag_payload, context)` | Rulestead requires explicit context rather than relying on a global actor struct context. |
| `FunWithFlags.enable(:flag)` | `Rulestead.publish_ruleset(...)` | Mutations in Rulestead use ChangeRequests or direct Publish commands for auditability. |
| Boolean Gate | Rule without conditions | Returns a literal boolean. |
| Actor Gate | Condition checking ID | e.g. `{"user_id", :in, ["123"]}`. |
| Group Gate | Condition checking role | e.g. `{"role", :eq, "admin"}` explicitly passed in context. |
| Percentage Gate | Rollout Rule | Deterministic bucketing based on an attribute (e.g. `user_id`). |

**New Document**: Create `guides/recipes/migrating-from-funwithflags.md` integrating the above table and code snippets for transition. Add it to `mix.exs` `extras` list under `guides/recipes/migrating-from-funwithflags.md`.
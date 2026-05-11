# Phase 2: Data Model, Error Model, Ecto Store, Fake Adapter - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** 3 parallel subagents across all 6 gray areas, synthesized into one cohesive recommendation set

<domain>
## Phase Boundary

**Goal:** Ecto schemas for every rulestead domain concept, typed error model locked as public API, and both real (Ecto/Postgres) and fake (in-memory) store adapters behind a clean `Rulestead.Store` behavior. Migrations ship via a minimal `mix rulestead.install` that only writes migrations + config. Full host-app integration remains Phase 5.

**In scope:**
- Domain schemas for `Flag`, `Environment`, `Ruleset`, `Rule`, `Condition`, `Segment`/`Audience`, `Variant`, `Rollout`, `AuditEvent`
- Postgres migrations with UUID defaults, partial unique indexes, soft-delete columns where appropriate
- Single flag identity with per-environment behavior
- Public error contract for non-bang/bang API pairs
- `Rulestead.Store` behavior + `Rulestead.Store.Ecto`
- `Rulestead.Fake` as the contract-faithful in-memory adapter
- Minimal `mix rulestead.install` for migrations + config only
- ExUnit/Ecto sandbox scaffolding for Phase 2+ tests

**Out of scope (explicitly deferred):**
- Pure evaluator and bucketing logic (Phase 3)
- Snapshot publication, ETS runtime cache, PubSub refresh, disk backup (Phase 4)
- Plug/LiveView/Oban integration, router/endpoint/app wiring, full installer, golden-diff host-app integration (Phase 5)
- Admin UI authoring flows, environment tabs, rule editor, lifecycle UX (Phase 6)
- Audit timeline UI, simulation, rollout controls, kill switch UI, security hardening (Phase 7)

</domain>

<decisions>
## Implementation Decisions

### Environment Modeling
- **D-01:** Model **one canonical `Flag` identity** plus **explicit environment-scoped behavior rows**. Use relational tables for `flags`, `environments`, and `flag_environments`; do **not** duplicate flags per environment and do **not** store all env behavior in one JSON blob.
- **D-02:** `flags` owns global identity and lifecycle fields: `key`, `description`, `flag_type`, `value_type`, `default_value`, `owner`, `expected_expiration`, tags, archive state.
- **D-03:** `flag_environments` is the per-environment anchor for active behavior. It holds `flag_id`, `environment_id`, `active_ruleset_id`, env status fields, and future env-specific state such as kill switch pointers. Enforce uniqueness on `(flag_id, environment_id)`.
- **D-04:** Keep `Environment` explicit as first-class schema/table from Phase 2. Conventional seeds are `development`, `staging`, `production`, `test`, but the model must support host-defined environment keys.

### Ruleset Persistence Shape
- **D-05:** Use a **hybrid persistence model**:
  - Relational tables for `Flag`, `Environment`, `FlagEnvironment`, `Ruleset`, `Audience`/`Segment`, and `AuditEvent`
  - Embedded schemas stored as JSONB inside `rulesets` for the owned ordered rule graph: `Rule`, `Condition`, `Variant`, and per-rule rollout/bucketing config
- **D-06:** `Ruleset` is the versioned publishing unit. Rule trees are owned by one ruleset version, loaded together, diffed together, and published together. Do **not** fully normalize rules/conditions/variants into standalone tables.
- **D-07:** Published rulesets are immutable. Publishing activates a new ruleset version for a `flag_environment`; it does not mutate the currently active rule tree in place.
- **D-08:** `Audience`/`Segment` remains relational and reusable. Embedded rules reference reusable audiences by stable key or ID; do **not** embed audience definitions into every ruleset document.
- **D-09:** The boundary rule is:
  - Normalize entities with independent identity/lifecycle/reuse/constraint needs
  - Embed ordered owned data that is versioned as a document

### Public Store Contract
- **D-10:** `Rulestead.Store` is a **domain-command, key-first behavior**, not an `Ecto.Repo`-style CRUD abstraction. Public selectors should be `flag_key` and `environment_key`; internal UUIDs stay private to schemas, migrations, and FKs.
- **D-11:** Store callbacks should model domain transitions such as fetch, save draft, publish, archive, and list. Avoid `get_by_id`, generic `insert/update/delete`, or APIs that imply runtime snapshot publication in Phase 2.
- **D-12:** All non-bang public store-facing APIs return `{:ok, value} | {:error, %Rulestead.Error{}}`. Never return `nil` for misses in the public contract.
- **D-13:** Keep authoring-store publication separate from runtime snapshot publication. Phase 2 ends at publishing an immutable ruleset/version and flipping the active pointer; Phase 4 translates that into runtime snapshots.

### Error API Detail
- **D-14:** Lock **one concrete public `%Rulestead.Error{}` struct** as the stable error envelope for both return tuples and raised exceptions. Non-bang APIs return `{:error, %Rulestead.Error{}}`; bang APIs raise that same struct.
- **D-15:** `Rulestead.Error` must include:
  - `:domain` for coarse family (`:evaluation | :ruleset | :kill_switch | :config | :store | :auth`)
  - `:type` as a **closed set of exact leaf atoms**
  - `:message`
  - `:metadata` as a safe scalar whitelist
  - `:details` as a flat aggregate list
  - `:cause` for raw underlying exception/changeset/term
  - optional `:plug_status`
- **D-16:** Exclude `:cause` from `Jason.Encoder`. Raw changesets, exceptions, traits, payloads, or request params must never leak through JSON encoding.
- **D-17:** Exact leaf atoms are part of the public contract. Prefer atoms like `:flag_not_found`, `:environment_not_found`, `:repo_not_configured`, `:repo_ambiguous`, `:variant_weights_invalid`, `:store_unavailable` over generic atoms like `:invalid` or `:not_found`.
- **D-18:** Keep typed families (`Rulestead.StoreError`, `Rulestead.ConfigError`, etc.) as constructor/helper namespaces if desired, but the public wire/runtime contract remains one `%Rulestead.Error{}` shape, not nested public sub-error trees.

### Fake Adapter Fidelity
- **D-19:** `Rulestead.Fake` must implement the same semantic contract as `Rulestead.Store.Ecto`: same selectors, same validations, same publish boundaries, same error taxonomy, same unhappy-path behavior.
- **D-20:** Extra test affordances are allowed, but they live outside the public behavior in clearly test-only modules such as `Rulestead.TestHelpers` and `Rulestead.Fake.Control`. Do **not** widen `Rulestead.Store` with fake-only callbacks.
- **D-21:** Write one shared adapter contract suite and run it against both adapters. Contract tests must cover not only happy paths but also duplicate keys, invalid rulesets, weight-sum failures, publish/version conflicts, not-found, and archived/read-only behavior.
- **D-22:** The fake should support the project’s release-gate posture without becoming a second public authoring API. Helper APIs such as `with_flag/3`, `put_flag/3`, `clear_flags/0`, `seed_bucket/3`, time advance, or evaluation recording belong to test-support modules, not the store behavior itself.

### Minimal Installer Slice
- **D-23:** Phase 2 `mix rulestead.install` is a **minimal Ecto installer** only. It may:
  - resolve or require a repo
  - write migrations
  - write `config/rulestead.exs`
  - add `import_config "rulestead.exs"` to `config/config.exs` if absent
- **D-24:** If exactly one repo is configured, installer may use it. If multiple repos exist, require `--repo MyApp.Repo`. If no repo is configured, fail with a typed config error.
- **D-25:** Phase 2 installer must be idempotent. Re-running it should emit only skip/already-present lines where applicable.
- **D-26:** Phase 2 installer must **not** modify `router.ex`, `endpoint.ex`, `application.ex`, Oban config, PubSub wiring, admin mounts, auth policy modules, or other Phase 5 host-app integration surfaces. It must not auto-run migrations.

### the agent's Discretion
- Exact schema module filenames and internal namespace layout under `lib/rulestead/`
- Whether reusable targeting entity is surfaced as `Audience`, `Segment`, or both, as long as user-facing language stays aligned with the field guide
- Exact `Rulestead.Store` callback names, provided they preserve the domain-command/key-first shape
- Exact seed/bootstrap strategy for default environments in tests vs installer output
- Whether draft-save flows use `Ecto.Multi` or `Repo.transact/1` in a given path, provided publish/audit pointer flips remain transactional

</decisions>

<specifics>
## Specific Ideas

- Emulate the **Unleash** lesson: one flag identity, environment-specific behavior.
- Emulate the **GrowthBook** lesson: rules are an ordered self-contained document that is easy to diff, explain, and later simulate.
- Emulate the best of **Elixir/Ecto** ergonomics:
  - explicit non-bang/bang API pairs
  - one stable public error struct
  - generation separate from execution
  - relational data for independently managed entities, embeds for owned nested documents
- Preserve a future-friendly admin model:
  - one flag detail page
  - environment tabs
  - immutable versioned rulesets
  - active pointer flip on publish
- Preserve a future-friendly runtime model:
  - one self-contained ruleset document per flag/environment
  - no need for row-by-row hot-path joins when Phase 4 compiles snapshots

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked constraints
- `.planning/ROADMAP.md` — Phase 2 scope, success criteria, dependency boundaries, and the explicit split between Phase 2 installer work and Phase 5 host-app integration
- `.planning/PROJECT.md` — product goals, key decisions, personas, and the requirement that the evaluator remain pure and snapshot-backed
- `.planning/REQUIREMENTS.md` — source of truth for STORE-01/07, ERR-01..04, and the ADMIN-08 schema split
- `.planning/phases/01-repo-bootstrap/01-CONTEXT.md` — inherited repo/package/release constraints that Phase 2 must preserve

### Product/domain direction
- `prompts/elixir_feature_flags_research_brief.md` — unified flag identity across environments, lifecycle/gov lessons, drift footguns, and broader market lessons from Unleash/GrowthBook/Flipper/FunWithFlags
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns and banned terms; especially `Flag`, `Environment`, `Ruleset`, `Rule`, `Condition`, `Variant`, `Audience`, `flag_key`, and `flag_id`

### Engineering and testing DNA
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — error-model convergence, fake-adapter strategy, extension seam guidance, and package-level engineering patterns to preserve
- `prompts/rulestead-testing-and-e2e-strategy.md` — fake-as-release-gate posture, contract-testing expectations, sandbox guidance, and future test-helper surface

### Ecto/Phoenix implementation guidance
- `prompts/ecto-best-practices-deep-research.md` — Ecto schema/changeset/transaction discipline and practical tradeoffs relevant to relational vs embedded boundaries
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — library/system-design guidance for Elixir/Phoenix ecosystems
- `prompts/elixir-best-practices-deep-research.md` — API ergonomics, exception/return-shape discipline, and maintainability guidance for public Elixir libraries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `rulestead/mix.exs` — already establishes the core package boundary, docs shape, and Dialyzer/test expectations that Phase 2 code must fit within
- `rulestead/lib/rulestead.ex` — current root public module; Phase 2 public APIs should extend this surface without breaking the minimal reflection contract
- `rulestead/test/test_helper.exs` — current ExUnit bootstrap point; this is where Ecto sandbox/manual mode scaffolding will land
- `rulestead_admin/` stub package — confirms that Phase 2 must not sneak in admin publish/setup work; only schema groundwork for later admin phases belongs here

### Established Patterns
- Sibling-package monorepo is locked from Phase 1; all Phase 2 code lives in `rulestead/`, not in `rulestead_admin/`
- Public API discipline from Phase 1 favors explicit package boundaries, warning-free docs, strict CI, and reproducible local scripts
- Installer and admin seams are intentionally deferred; any Phase 2 implementation that requires router/endpoint/app supervision edits is violating the roadmap

### Integration Points
- `rulestead/priv/repo/migrations/` — library-owned migrations that Phase 2 defines and the installer writes into host apps
- `lib/mix/tasks/rulestead.install.ex` — future Phase 2 minimal installer entrypoint
- `rulestead/test/` — shared adapter contract tests and fake/ecto parity tests should anchor here
- Future runtime/evaluator phases depend on Phase 2 storing one coherent authoring document per `flag_environment`

</code_context>

<deferred>
## Deferred Ideas

- Full host-app integration (`router.ex`, `endpoint.ex`, `application.ex`, Oban, admin mount, auth policy generation) — Phase 5
- Golden-diff installer tree and broad host-app fixture verification — Phase 5
- Snapshot publication APIs and runtime cache invalidation mechanics — Phase 4
- Kill switch runtime/admin semantics beyond placeholder schema affordances — Phase 7
- Environment diff/copy/promotion workflows and prod-specific authorization behavior — later admin/security phases

</deferred>

---

*Phase: 02-data-model-error-model-ecto-store-fake-adapter*
*Context gathered: 2026-04-23*

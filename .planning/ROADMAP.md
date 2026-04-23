# Roadmap: Rulestead

**Milestone:** v0.1.0 — first polished Hex release
**Theme:** Batteries-included Elixir-native feature flags + admin UI with lifecycle hygiene
**Requirements covered:** 74 total across 13 categories (EVAL, CTX, STORE, RULE, TEL, ADMIN, INST, LIFE, TEST, SEC, ERR, REL, DOC)
**Phases:** 8
**Parallelization:** Phases 5 and 6 run in parallel (both depend on Phase 4, neither on each other)
**Granularity:** Standard

---

## Phase 1 — Repo Bootstrap, CI, Release Engineering Foundation

**Goal:** Working sibling-package skeleton (`rulestead` + `rulestead_admin`) with CI lanes green, linked-versions release-please configured, and documentation scaffolding in place. No evaluation logic yet — this is the foundation every subsequent phase builds on.

**Requirements (9):** REL-01, REL-02, REL-05, DOC-01, DOC-02, DOC-03, plus partial REL-06 scaffold (to be finalized in Phase 8)

**Scope:**
- Sibling package layout: `rulestead/` (core) + `rulestead_admin/` (LiveView UI) with monorepo root
- `mix.exs` pair with linked-versions `release-please-config.json` + `release-please-manifest.json`
- Hex package metadata, `package.files` whitelist, MIT license
- `.formatter.exs` imports `:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug`
- `.credo.exs` with strict mode (custom checks added Phase 7)
- CI workflows: lint lane (format / compile-warnings-as-errors / credo strict / `mix docs --warnings-as-errors` / `mix hex.audit` / `mix compile --no-optional-deps`), test matrix (1.17/26.x + 1.19/28.x with Postgres 15+ service container + healthcheck), integration placeholder
- Path filters (skip CI on docs-only changes), concurrency group with `cancel-in-progress`, SHA-pinned actions with trailing version comments
- Root files: README.md (60-second overview + 15-min quickstart skeleton), LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, MAINTAINING.md, CLAUDE.md, AGENTS.md
- ExDoc config with 3-folder guides split (`introduction/`, `flows/`, `recipes/`) + skeleton pages
- PR title lint (conventional commits) via `amannn/action-semantic-pull-request@v5`
- `scripts/ci/*.sh` pattern: every non-trivial CI step in a locally-runnable shell script

**Success criteria:**
1. `mix deps.get && mix compile --warnings-as-errors` green for both packages
2. `mix credo --strict` passes on empty skeleton
3. `mix docs` produces warning-free HTML output
4. CI workflow succeeds on a PR from a clean branch
5. Release-please opens a v0.1.0 PR on merge to main (dry-run; no actual publish yet)

**Plans:** 7 plans

Plans:
- [ ] `01-01-PLAN.md` — Shared repo tooling, local Postgres bootstrap, and linked-versions release metadata
- [ ] `01-02-PLAN.md` — `rulestead/` core package skeleton, metadata, and empty-surface tests
- [ ] `01-03-PLAN.md` — `rulestead_admin/` sibling package skeleton with guarded router stub
- [ ] `01-04-PLAN.md` — Root README, contributor/security/legal docs, maintainer runbook, and agent instructions
- [ ] `01-05-PLAN.md` — GitHub Actions workflows for CI, release-please, publish fallback, PR-title lint, and dependency review
- [ ] `01-06-PLAN.md` — GitHub metadata files and locally runnable `scripts/ci/*.sh` workflow helpers
- [ ] `01-07-PLAN.md` — ExDoc configuration plus `guides/` introduction/flows/recipes scaffolding

**Dependencies:** none
**Depends on:** —

---

## Phase 2 — Data Model, Error Model, Ecto Store, Fake Adapter

**Goal:** Ecto schemas for every rulestead domain concept, typed error model locked as public API, and both real (Ecto/Postgres) and fake (in-memory) store adapters behind a clean `Rulestead.Store` behavior. Migrations ship via a minimal `mix rulestead.install` that just writes migrations + config (full installer in Phase 5).

**Requirements (9):** STORE-01, STORE-07, ERR-01, ERR-02, ERR-03, ERR-04, ADMIN-08 (environments schema only — UI in Phase 6)

Note: `ADMIN-08` splits — schema + data model here; UI behavior in Phase 6 (tracked as one requirement, verified in Phase 6).

**Scope:**
- Ecto schemas: `Flag`, `Environment`, `Ruleset`, `Rule`, `Condition`, `Segment`, `Variant`, `Rollout`, `AuditEvent`
- Postgres migrations with partial unique indexes, `gen_random_uuid()` defaults, soft-delete columns
- Single flag identity with per-environment behavior (research brief §4.1 A)
- Root `Rulestead.Error` struct with closed `:type` atom + typed sub-errors (`EvaluationError`, `RulesetError`, `KillSwitchError`, `ConfigError`, `StoreError`, `AuthError`)
- `:cause` field excluded from `Jason.Encoder` via custom derive
- Paired `evaluate/3` + `evaluate!/3` stub conventions documented
- `Rulestead.Store` behavior (`list_flags/1`, `get_flag/2`, `put_flag/2`, `delete_flag/2`, `list_rules/2`, `put_rule/2`, `publish_snapshot/1`, etc.)
- `Rulestead.Store.Ecto` default adapter
- `Rulestead.Fake` in-memory adapter (ETS-backed, time-advanceable cache, no Postgres required)
- `mix rulestead.install` minimal slice: migration generator + config block + Ecto store wiring (idempotent; full Plug/router/Oban integration in Phase 5)
- ExUnit Ecto sandbox `mode: :manual` scaffolding in `test/test_helper.exs`

**Success criteria:**
1. Fresh Phoenix app + `mix rulestead.install` + `mix ecto.migrate` produces clean schema
2. `Rulestead.Fake` round-trips every `Rulestead.Store` operation without Postgres
3. `Rulestead.Error` structs pattern-match by `:type` atom in tests
4. Error structs encode to JSON without leaking `:cause` payload
5. Both real and fake stores pass an identical behavior-contract test suite

**Dependencies:** Phase 1 (package skeleton + CI)
**Depends on:** 1

---

## Phase 3 — Context, Rules, Deterministic Bucketing, Pure Evaluator

**Goal:** The pure, fast, deterministic runtime evaluator that is the heart of rulestead. `Rulestead.enabled?`, `get_value`, `get_variant`, `evaluate`, and `explain` all work against an in-memory ruleset. First-match-wins, deterministic bucketing, structured `Result` output. Property tests lock determinism invariants.

**Requirements (19):** EVAL-01, EVAL-02, EVAL-03, EVAL-04, EVAL-05, EVAL-06, EVAL-07, EVAL-08, EVAL-09, CTX-01, RULE-01, RULE-02, RULE-03, RULE-04, TEST-04

**Scope:**
- `Rulestead.Context` struct + builder with fields: `targeting_key`, `subject`, `tenant_key`, `environment`, `attributes`, `request_id`, `session_id`, `strict?`
- Public API: `Rulestead.enabled?/2`, `Rulestead.get_value/3`, `Rulestead.get_variant/2`, `Rulestead.evaluate/3`, `Rulestead.explain/2`
- `Rulestead.Result` struct: `value`, `enabled?`, `variant`, `reason`, `matched_rule`, `flag_key`, `flag_version`, `cache_age_ms`, optional `debug_trace`
- Condition predicates: `equals`, `in`, `not_in`, `gt`, `lt`, `gte`, `lte`, `regex`, `exists`
- Segments as reusable condition bundles referenced from rules
- Variants with stable keys + rollout weights validated to sum to 100
- Deterministic bucketing: stable hash of `(flag_key, rule_key, salt, targeting_key)` → 0..99 bucket; weights map bucket → variant
- Selectable bucketing strategy per rule: `:subject` / `:account` / `:tenant` / `:session`
- First-match-wins ordered evaluation; default value if no rule matches
- Missing-targeting-key behavior: telemetry warning in permissive mode; `Rulestead.Error{type: :missing_targeting_key}` in strict mode
- `explain/2` output: matched rule, each condition passed/failed, bucket value + variant chosen, reason label, snapshot version, environment
- StreamData property tests: same `(flag_key, rule_key, salt, targeting_key)` → same bucket across 10k runs; weight sums; rule ordering invariants

**Success criteria:**
1. 10k-run StreamData property test passes for bucketing determinism
2. `Rulestead.explain/2` returns a structured trace that names the matched rule or explains why no rule matched
3. `Rulestead.enabled?("flag", ctx)` is pure — zero I/O, no process-dictionary reads
4. Strict mode raises a typed error on missing `targeting_key` for sticky rules
5. Variant weights that don't sum to 100 fail at save time with a `Rulestead.RulesetError`

**Dependencies:** Phase 2 (schemas + Store behavior so evaluator reads from a uniform source)
**Depends on:** 2

---

## Phase 4 — Snapshot Cache, Runtime Refresh, Telemetry, Explain Wiring

**Goal:** Make the evaluator fast and operationally robust. Snapshot-based local evaluation with ETS cache, Phoenix.PubSub refresh, polling fallback, disk backup, startup resilience. `Rulestead.Telemetry.span/3` wraps every public operation and emits the versioned event catalog.

**Requirements (9):** STORE-02, STORE-03, STORE-04, STORE-05, STORE-06, TEL-01, TEL-02, TEL-04

Note: `TEL-03` (no-PII enforcement via Credo check) lands in Phase 7 with the rest of the security/redaction work.

**Scope:**
- Snapshot serialization: versioned binary payload (`:erlang.term_to_binary` + magic header + version byte)
- `Rulestead.Runtime.Snapshot` — compiled in-memory representation optimized for hot-path evaluation
- ETS table per-environment with `:read_concurrency`; cache entries keyed by flag_key
- `Rulestead.Runtime.Refresh` GenServer: Phoenix.PubSub subscription for change notifications; polling fallback with configurable interval; exponential backoff on store errors
- Startup contract: evaluator serves last known snapshot (disk backup or empty) until first refresh succeeds; documented degraded mode; never hard-depends on host-app-owned process start order
- Optional disk backup via `:dets` or flat file; loaded on boot before first refresh
- Cache age + snapshot version exposed in `Rulestead.diagnostics/0` and `Rulestead.explain/2` output
- `Rulestead.Telemetry.span/3` wrapper around `:telemetry.span/3`
- Event catalog: `[:rulestead, :eval, :decide, :start|:stop|:exception]`, `[:rulestead, :runtime, :cache, :hit|:miss|:refresh|:stale_used]`, `[:rulestead, :runtime, :snapshot, :published|:applied]`, `[:rulestead, :admin, :mutation, :start|:stop]`, `[:rulestead, :store, :read|:write, :start|:stop|:exception]`
- Telemetry metadata includes `flag_key`, `flag_type`, `environment`, `reason`, `snapshot_version`, `cache_age_ms`, `has_targeting_key?`, `matched_rule_count` — never raw attributes
- Telemetry handlers tolerate any reason atom and meta shape (documented in event catalog)
- `guides/flows/telemetry.md` ships with the full event catalog

**Success criteria:**
1. Evaluator reads from ETS-compiled snapshot — zero DB queries on hot path (verified by telemetry span count in integration test)
2. Killing the store connection does NOT crash the evaluator; it serves stale snapshot and emits `cache:stale_used` telemetry
3. Snapshot refresh round-trip (admin write → PubSub → all nodes refreshed) completes in <500ms in a 2-node test cluster
4. Disk backup restores evaluator on boot without control-plane connectivity
5. `mix test --include telemetry` verifies every documented event fires with the documented metadata shape

**Dependencies:** Phase 3 (pure evaluator to wrap in snapshot cache)
**Depends on:** 3

---

## Phase 5 — Host-App Seams: Plug, LiveView, Oban, Installer, Test Helpers

**Goal:** Everything an app dev (Alex) needs to use rulestead in a Phoenix app. Plug middleware puts Context on conn assigns, LiveView helper eager-assigns flags, Oban middleware propagates Context to jobs, `mix rulestead.install` writes router mounts + middleware hooks, golden-diff test locks installer output byte-for-byte, test macros make flag-aware tests trivial.

**Requirements (10):** CTX-02, CTX-03, CTX-04, CTX-05, INST-01 (full), INST-02, INST-03, INST-04, INST-05, INST-06, TEST-01, TEST-02, TEST-03, TEST-05

Note: `INST-01` appears here (full installer) — Phase 2 shipped the narrow migration-generator slice.

**Scope:**
- `Rulestead.Plug` — puts `Rulestead.Context` on `conn.assigns[:rulestead_context]`; extracts targeting_key from session / cookie / header per host config
- `Rulestead.Phoenix.context_from_conn/1` + `Rulestead.LiveView.context_from_socket/1` + `Rulestead.Oban.context_from_job/1`
- `Rulestead.LiveView.assign_flags/2` — batched flag resolution into socket assigns
- `Rulestead.Oban.Middleware` — attaches Context at enqueue; reads Context in worker
- Process-tree propagation documented in `guides/recipes/context-propagation.md` (explicit opt-in, not ambient)
- Full `mix rulestead.install` generator:
  - Writes migrations (from Phase 2)
  - Injects `plug Rulestead.Plug` into `endpoint.ex`
  - Mounts admin at `/admin/flags` in `router.ex` (behind host-supplied policy)
  - Adds `Rulestead.Oban.Middleware` to Oban config if Oban detected
  - Writes `config/rulestead.exs` with NimbleOptions-validated defaults
- Idempotent installer: second run emits only "already injected / skipping" lines
- Golden-diff test (sigra pattern):
  - `test/fixtures/install_golden/tree/` + `STDOUT.txt`
  - Test spawns `mix phx.new <tmp>` via `System.cmd`, injects `{:rulestead, path: "..", override: true}`, runs `mix rulestead.install --yes`, captures stdout
  - Normalizes migration timestamps (`TIMESTAMP_` prefix replacement) before comparing
  - `@moduletag :golden`, `@moduletag timeout: 300_000`
- Paired idempotency test: running install twice emits only "skipping" output
- Test helpers (documented + exported):
  - `with_flag/3` — macro setting flag for block scope
  - `put_flag/3` — set flag for remainder of test
  - `clear_flags/0` — reset Fake store
  - `seed_bucket/3` — pin variant assignment for specific targeting_key
  - `assert_flag_evaluated/2` — telemetry-backed assertion

**Success criteria:**
1. Fresh `mix phx.new demo && cd demo && mix rulestead.install --yes && mix ecto.migrate && mix phx.server` produces a running app with `/admin/flags` mounted and `Rulestead.Plug` active
2. Golden-diff test passes byte-for-byte (after timestamp normalization)
3. Running `mix rulestead.install` twice emits only skip lines; no file modifications
4. `with_flag "foo", true do ... end` inside an ExUnit test makes `Rulestead.enabled?("foo", _)` return `true` for the block
5. Oban worker with `use Rulestead.Oban.Worker` reads Context from job args without boilerplate

**Dependencies:** Phase 4 (snapshot cache) — evaluator must be production-ready before wiring host-app integrations
**Depends on:** 4
**Parallel with:** Phase 6

---

## Phase 6 — Admin UI: Flag List, Detail, Rule Editor, Environments, Lifecycle

**Goal:** First half of the admin UI. Operators can browse flags, see rules and audit timeline per flag, create/edit/reorder rules, switch environments, and see lifecycle state (owner, expiration, stale markers). This is where personas Priya (PM/Operator) and Sam (Support) get their core JTBD coverage.

**Requirements (10):** ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-08 (UI surface), ADMIN-10, LIFE-01, LIFE-02, LIFE-03, LIFE-04

**Scope:**
- `rulestead_admin` Phoenix LiveView package (sibling to `rulestead`)
- Router mount macro: `Rulestead.Admin.Router.admin_routes(policy: MyApp.FlagsPolicy)`
- `Rulestead.Admin.Policy` behavior: `can?(actor, action, resource, env) :: boolean`
- Flag list LiveView:
  - Search by key, filter by environment / lifecycle state / owner / tags
  - Columns: key, type, owner, lifecycle state (badge), environments (dots), last changed, stale/potentially-stale indicator, scheduled changes indicator (empty until Phase 7/v0.2)
  - Pagination, keyboard nav
- Flag detail LiveView:
  - Description + intent, type, default value
  - Ordered rules list with drag-reorder, inline variant weights
  - Per-environment status tabs
  - Audit timeline placeholder (full wiring in Phase 7)
- Rule editor LiveView:
  - Create / edit / reorder / archive
  - Condition builder (attribute / operator / value)
  - Variant weight editor with sum-to-100 validation (live preview)
  - Segment picker for reusable conditions
- Environment selector (dev/staging/prod) — persistent per-user preference
- Environment schema wiring: single flag identity, per-env behavior table joins
- Lifecycle fields on flag form: owner (required), expected_expiration (required — date or "permanent"), description, tags
- Stale detection: configurable age threshold (default 90 days) + `last_evaluated_at` population from evaluator telemetry → stale/potentially-stale classification surfaced in list + detail
- Archived flags read-only in UI; excluded from evaluation by store filter
- Admin UI follows brand: mineral/dark neutrals + controlled blue + restrained ember accent; Sora headings + Inter body + IBM Plex Mono for keys/IDs
- Accessibility: WCAG AA contrast, keyboard nav on all interactive elements, `aria-*` on dynamic content

**Success criteria:**
1. Operator can create a flag with owner + expected_expiration via UI; save is rejected if either is missing
2. Operator can add a rule with 3 variants and save; weight-sum validation is live and blocks save at 99 or 101
3. Operator can reorder rules via drag-and-drop; order persists and affects evaluation
4. Flag list filters by lifecycle state; potentially-stale flags display a visible warning badge
5. Archived flag is excluded from `Rulestead.enabled?` evaluation in integration test
6. Axe-core accessibility scan passes on flag list, detail, and rule editor pages

**Dependencies:** Phase 4 (snapshot-published changes round-trip to evaluator), Phase 2 (Environment + lifecycle schema fields)
**Depends on:** 4
**Parallel with:** Phase 5

---

## Phase 7 — Admin UI: Simulation, Rollouts, Kill Switch, Audit, Security & Redaction

**Goal:** Second half of the admin UI. The high-value operator surfaces that make rulestead stand out: simulation/explain, rollout controls, bookmarkable kill switch, full audit timeline. Plus the security envelope that makes the library safe to deploy: `Rulestead.Admin.Policy` integration, env-sensitive authz, redaction Credo checks, secure traits. This is where personas Shiori (SRE) and Tova (Tech Lead) get their core JTBD coverage.

**Requirements (8):** ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-09, SEC-01, SEC-02, SEC-03, SEC-04, TEL-03

**Scope:**
- Simulation / explain LiveView:
  - Form: targeting_key + trait attributes (key/value rows) + environment selector
  - Submit → renders `Rulestead.explain/2` output: matched rule (or "no match, default returned"), conditions passed/failed per rule, bucket calculation, reason label, snapshot version, cache age
  - Saveable archetypes (common user profiles) — list + "apply" button
  - "Copy as test fixture" button exports Context as Elixir literal for paste into ExUnit tests
- Rollout controls:
  - Percentage editor with visual rule-ordering preview
  - "Next step" suggestions (e.g., 5% → 25% → 50% → 100% with sticky bucketing stable)
  - Preview panel: simulate for 1000 random targeting_keys, show assignment distribution vs intended weights
  - Optimistic UI with revert on server rejection
- Kill switch:
  - Per flag per environment
  - Bookmarkable URL (`/admin/flags/:key/kill?env=prod`)
  - One-click with confirmation modal ("Type the flag key to confirm")
  - Reverts to default value; emits `[:rulestead, :admin, :kill_switch, :activated]` telemetry + audit event
  - Visible banner on detail page while active; one-click restore
- Audit timeline LiveView:
  - Full who-changed-what per flag per environment
  - Before/after diff with syntax highlighting for rule JSON
  - Linked actor (via `Rulestead.ActorResolver` behavior — host supplies)
  - Rollback affordance: "Restore to this version" button (writes inverse change, doesn't erase history)
  - Filter by actor, environment, date range, mutation type
- `Rulestead.Admin.Policy` full integration:
  - Every LiveView action calls `Policy.can?(actor, action, resource, env)` before mutation
  - Env-sensitive defaults: read-only for viewers; non-prod edit for engineers; prod edit gated per host config
  - `Rulestead.Error{type: :unauthorized}` raised on deny
- Secure traits / attribute allowlists:
  - `config :rulestead, :telemetry_metadata_allowlist, [...]`
  - Attributes not on allowlist are replaced with `:redacted` in telemetry meta
  - Audit rows redact trait values by default; configurable per-trait sensitivity
- Custom Credo checks (`requires:` block in `.credo.exs`):
  - `Rulestead.Credo.NoRawTraitsInTelemetryMeta` — flags literal `:email`, `:ip`, `:user_agent`, `:phone`, `:name` in telemetry meta maps
  - `Rulestead.Credo.NoRawTraitsInLogger` — same for `Logger.metadata/1`
  - `Rulestead.Credo.NoEvalOutsideContext` — `evaluate/3` must route through `Rulestead.Evaluations` context
  - `Rulestead.Credo.NoUnscopedTenantQueryInLib` — `Repo` queries must pass through `Rulestead.Tenancy.scope/2` (v0.2 full; v0.1 stub + check in place)
  - `Rulestead.Credo.NoMutationOutsideMulti` — writes to rulestead tables must be inside an `Ecto.Multi` that also writes an `AuditEvent`
  - `Rulestead.Credo.NoSocketCapturedInAsync` — LiveView `start_async` / `assign_async` closures may not capture `socket`

**Success criteria:**
1. Operator enters a targeting_key + traits + env on simulation page; gets back matched rule name + bucket value + trace within 100ms
2. Kill switch URL is bookmarkable and works across browser restarts; activating it immediately flips evaluator to default value on all nodes (<500ms via PubSub)
3. Audit timeline shows a before/after diff for a rule reorder with exact rule positions
4. A PR that adds `:email` as a key in a telemetry meta map is rejected by `mix credo --strict` in CI
5. An unauthorized prod-edit attempt returns a typed `Rulestead.AuthError` and is logged to audit with `action: :denied`
6. Axe-core accessibility scan passes on simulation, rollout, kill switch, and audit pages

**Dependencies:** Phase 4 (telemetry), Phase 6 (admin scaffolding + Policy behavior)
**Depends on:** 6

---

## Phase 8 — Docs, API Stability, Cheatsheet, Post-Publish Verify, v0.1.0 Release

**Goal:** Ship it. Every guide written, `api_stability.md` locked, cheatsheet polished, extending guide documents every behavior, post-publish verification trio in place with daily drift cron, v0.1.0 tagged and published to Hex.

**Requirements (7):** REL-03, REL-04, REL-06 (full), DOC-04, DOC-05, DOC-06

**Scope:**
- 3-folder guides fully authored:
  - `introduction/installation.md`, `introduction/getting-started.md`, `introduction/upgrading.md`
  - `flows/evaluation.md`, `flows/rulesets.md`, `flows/rollout.md`, `flows/admin-ui.md`, `flows/explainability.md`, `flows/multi-env.md`
  - `recipes/testing.md`, `recipes/telemetry.md`, `recipes/ecto-conventions.md`, `recipes/oban-background-jobs.md`, `recipes/deployment.md`, `recipes/context-propagation.md`
- `CONVENTIONS.md` discipline layer: determinism rules, precedence semantics, tenancy scoping, testing conventions, PII redaction rules — paired with enforcement in custom Credo checks
- `guides/cheatsheet.cheatmd` — one-page ExDoc cheatmd-format quick reference (API surface, common recipes)
- `api_stability.md` (lattice_stripe pattern):
  - Enumerate locked public modules (no `@moduledoc false`)
  - Enumerate `@doc`-annotated function arities
  - Enumerate public struct fields (`Rulestead.Context`, `Rulestead.Result`, `Rulestead.Error` and sub-errors)
  - Enumerate error `:type` atoms (closed set)
  - Enumerate telemetry event names + metadata keys (closed set)
  - Enumerate NimbleOptions schema keys for `config :rulestead`
  - Call out NOT public (`lib/rulestead/runtime/*`, `lib/rulestead/admin/live/*`)
  - Deviation register: any intentional convention break with justification + issue pointer
- `guides/flows/extending-rulestead.md` — recipe for every public behavior: `Rulestead.Store`, `Rulestead.RuleEngine`, `Rulestead.EvaluationCache`, `Rulestead.AuditStore`, `Rulestead.ActorResolver`, `Rulestead.Admin.Policy`
- Post-publish verification trio (scrypath pattern — ported verbatim):
  - `mix verify.workspace_clean` — `git status --porcelain` scoped to `package.files ++ ["test"]`; no escape-hatch flag
  - `mix verify.release_publish <version>` — polls Hex for tarball (10×15s budget), spins up `mix new rulestead_consumer`, depends on published version, compiles, checks versioned HexDocs URL reachability
  - `mix verify.release_parity <version>` — diffs `lib/ + guides/ + docs/` between git tag and Hex tarball; exit codes `0 = parity`, `2 = drift`, `1 = runtime error`; pure `compute/2` split out for ExUnit testability
- Daily drift cron (`verify-published-release.yml` at `17 6 * * *`):
  - Re-runs `verify.release_publish` + `verify.release_parity` against latest Hex version
  - Single rolling GitHub issue via `JasonEtco/create-an-issue@v2` with `update_existing: true, search_existing: open`
  - Labels: `area:release`, `severity:drift`
- Dependabot patch-only auto-merge for GitHub Actions + mix deps
- Manual `publish-hex.yml` workflow_dispatch fallback with `inputs.tag` + `inputs.release_version`
- `mix rulestead.install` golden-diff test passes against final v0.1.0 shape
- v0.1.0 release-please PR merged; tag pushed; `publish-hex.yml` triggered; post-publish verify green; HexDocs reachable at versioned URL

**Success criteria:**
1. `mix docs --warnings-as-errors` green with full guides authored
2. `api_stability.md` is referenced from README and CHANGELOG; every locked surface in the doc has a corresponding test that imports it
3. `mix verify.workspace_clean && mix verify.release_publish 0.1.0 && mix verify.release_parity 0.1.0` all return exit 0 after publish
4. `rulestead` and `rulestead_admin` are both visible at `hex.pm/packages/rulestead` and `hex.pm/packages/rulestead_admin`
5. A brand-new `mix new consumer && mix add :rulestead` installs cleanly and the README quickstart works end-to-end against published Hex package (not path dep)
6. Daily drift cron runs and opens the rolling issue only on actual drift

**Dependencies:** Phases 5 + 6 + 7 all complete
**Depends on:** 5, 6, 7

---

## Phase Dependency Graph

```
Phase 1 (bootstrap)
   ↓
Phase 2 (data + store + errors)
   ↓
Phase 3 (evaluator)
   ↓
Phase 4 (cache + telemetry)
   ↓
  ├─→ Phase 5 (seams + installer)  ─┐
  └─→ Phase 6 (admin UI part 1)  ───┤
                                     ↓
                              Phase 7 (admin UI part 2 + security)
                                     ↓
                              Phase 8 (docs + release)
```

**Parallelization opportunity:** Phases 5 and 6 run concurrently after Phase 4 completes. Phase 7 joins both tracks back together.

---

## Coverage Audit

| Category | Count | Phases |
|---|---|---|
| EVAL (evaluation) | 9 | 3 |
| CTX (context) | 5 | 3 (CTX-01), 5 (CTX-02..05) |
| STORE (store/snapshots) | 7 | 2 (STORE-01, 07), 4 (STORE-02..06) |
| RULE (rules/variants) | 4 | 3 |
| TEL (telemetry) | 4 | 4 (TEL-01, 02, 04), 7 (TEL-03) |
| ADMIN (admin UI) | 10 | 6 (01, 02, 03, 08, 10), 7 (04, 05, 06, 07, 09) |
| INST (installer) | 6 | 2 (INST-01 partial — tracked in 5 for full), 5 (INST-01..06) |
| LIFE (lifecycle) | 4 | 6 |
| TEST (test helpers) | 5 | 3 (TEST-04), 5 (TEST-01, 02, 03, 05) |
| SEC (security/privacy) | 4 | 7 |
| ERR (error model) | 4 | 2 |
| REL (release engineering) | 6 | 1 (REL-01, 02, 05), 8 (REL-03, 04, 06) |
| DOC (documentation) | 6 | 1 (DOC-01, 02, 03), 8 (DOC-04, 05, 06) |
| **Total** | **74** | **8 phases** |

All 74 requirements mapped. Zero unmapped. ✓

---

*Roadmap created: 2026-04-23*
*Last updated: 2026-04-23 after initial creation*

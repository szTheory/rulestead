# Rulestead

## What This Is

Rulestead is a batteries-included, Elixir-native feature-flag and experimentation library for Phoenix, Plug, Ecto, LiveView, and Oban apps, shipped as sibling Hex packages (`rulestead` core + `rulestead_admin` LiveView UI). It closes the gap between FunWithFlags (boolean-only) and external platforms like LaunchDarkly/Unleash/Flagsmith, delivering multivariate values, ordered rules, deterministic bucketing, first-class explainability, lifecycle hygiene, and an intuitive self-hosted admin plane — all without leaving the BEAM ecosystem. OSS (MIT), Hex-published, also used in Jon's own SaaS.

## Core Value

**Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.**

Everything else can fail; this cannot. If the runtime evaluator isn't fast, pure, deterministic, and explainable, nothing else matters.

## Requirements

### Validated

(None yet — ship to validate.)

### Active (v0.1.0 — first polished Hex release)

**Core runtime**
- [ ] **EVAL-01**: App code can evaluate a boolean flag via `Rulestead.enabled?/2` with a Context or Plug conn
- [ ] **EVAL-02**: App code can resolve a multivariate value via `Rulestead.get_value/3` (typed: boolean/string/integer/float/map)
- [ ] **EVAL-03**: App code can get an assigned variant via `Rulestead.get_variant/2`
- [ ] **EVAL-04**: Evaluator returns a structured `Rulestead.Result` (value, variant, reason, matched_rule, flag_key, flag_version, cache_age_ms, optional debug_trace)
- [ ] **EVAL-05**: Rules are evaluated in order, first-match-wins; default value applies if none match
- [ ] **EVAL-06**: Bucketing is deterministic from `(flag_key, rule_key, salt, targeting_key)` — same inputs → same bucket across 10k property-test runs
- [ ] **EVAL-07**: Missing `targeting_key` on sticky rules emits a telemetry warning and (in strict mode) fails closed
- [ ] **EVAL-08**: `Rulestead.explain/2` returns a human-readable trace (matched rule, conditions passed/failed, bucket calc, reason, snapshot version, environment)
- [ ] **EVAL-09**: Evaluator is pure from the caller's perspective — no I/O, no process dictionary surprises

**Context & propagation**
- [ ] **CTX-01**: Explicit `Rulestead.Context` struct builder with `targeting_key`, `subject`, `tenant_key`, `environment`, `attributes`, `request_id`, `session_id`, `strict?`
- [ ] **CTX-02**: `Rulestead.Phoenix.context_from_conn/1` builds Context from a Plug.Conn
- [ ] **CTX-03**: `Rulestead.LiveView.context_from_socket/1` builds Context from a LiveView socket
- [ ] **CTX-04**: `Rulestead.Oban.context_from_job/1` builds Context from an Oban job; middleware attaches context at enqueue
- [ ] **CTX-05**: Process-tree context propagation is documented and scoped (no ambient magic)

**Store & snapshots**
- [ ] **STORE-01**: Ecto-backed authoring store with Postgres migrations shipped via `mix rulestead.install`
- [ ] **STORE-02**: Snapshot serialization (versioned binary payload) published on write
- [ ] **STORE-03**: ETS compiled snapshot cache in runtime package with Phoenix.PubSub refresh + polling fallback
- [ ] **STORE-04**: Cache age and snapshot version exposed in debug/diagnostics output
- [ ] **STORE-05**: Startup is resilient — no hard dependency on host-app-owned process start order; documented degraded mode
- [ ] **STORE-06**: Optional disk backup for evaluator restart without control-plane connectivity
- [ ] **STORE-07**: `Rulestead.Fake` in-memory adapter for tests (time-advanceable cache, no Postgres required)

**Rules & segments**
- [ ] **RULE-01**: Rule conditions support attribute predicates (equals, in, not_in, gt/lt, regex, exists)
- [ ] **RULE-02**: Segments are reusable targeting definitions referenced by rules
- [ ] **RULE-03**: Variants carry stable keys + rollout weights that sum to 100% (validated at save)
- [ ] **RULE-04**: Bucketing strategy is selectable per rule (subject / account / tenant / session)

**Telemetry & observability**
- [ ] **TEL-01**: `Rulestead.Telemetry.span/3` wrapper emits `[:rulestead, domain, resource, action, :start|:stop|:exception]` for every public operation
- [ ] **TEL-02**: Event catalog documented in `guides/flows/telemetry.md`; events versioned as part of public API
- [ ] **TEL-03**: No PII / secrets / raw payloads in telemetry meta — enforced by custom Credo check (`NoRawTraitsInTelemetryMeta`)
- [ ] **TEL-04**: Telemetry handlers never raise; tolerate any reason atom and meta shape

**Admin UI (rulestead_admin)**
- [ ] **ADMIN-01**: Flag list page with search/filter (by key, environment, lifecycle state, owner, stale status, tags)
- [ ] **ADMIN-02**: Flag detail page with description, type, default value, ordered rules, per-env status, audit timeline
- [ ] **ADMIN-03**: Rule editor (create/edit/reorder/delete rules; add conditions; assign variant weights)
- [ ] **ADMIN-04**: Simulation / "explain" page — operator enters targeting_key + traits + environment, sees value/variant/matched rule/trace
- [ ] **ADMIN-05**: Rollout controls — percentage rollout editor with rule ordering preview
- [ ] **ADMIN-06**: Kill switch — bookmarkable one-click disable per flag per environment with confirmation
- [ ] **ADMIN-07**: Audit timeline — who changed what, before/after diff, environment, linked to actor
- [ ] **ADMIN-08**: Environments model — dev/staging/prod with per-env behavior on a single flag identity; prod privileges stricter
- [ ] **ADMIN-09**: Lifecycle view — owner, expected expiration, stale / potentially-stale markers, last changed
- [ ] **ADMIN-10**: Admin mounts into host Phoenix app via a single line in `router.ex`; authorization delegates to `Rulestead.Admin.Policy` behavior supplied by host

**Installer & host-app seam**
- [ ] **INST-01**: `mix rulestead.install` generates migrations, config, endpoint Plug, and router mount
- [ ] **INST-02**: Installer is idempotent — second run emits "already injected / skipping" lines only
- [ ] **INST-03**: Golden-diff test: fresh `mix phx.new` + install produces byte-identical tree/stdout fixture (sigra pattern)
- [ ] **INST-04**: Plug integration — `plug Rulestead.Plug` in endpoint puts Context on conn assigns
- [ ] **INST-05**: LiveView helper — `Rulestead.LiveView.assign_flags/2` for eager flag assignment
- [ ] **INST-06**: Oban middleware — `Rulestead.Oban.Middleware` attaches Context to jobs at enqueue

**Lifecycle hygiene**
- [ ] **LIFE-01**: Creating a flag requires `owner` (team/person) and `expected_expiration` (or explicit "permanent")
- [ ] **LIFE-02**: Lifecycle state surfaced in flag list (active / potentially_stale / stale / archived)
- [ ] **LIFE-03**: Potentially-stale detection based on configurable age threshold + last_evaluated_at
- [ ] **LIFE-04**: Archived flags are read-only and excluded from evaluation

**Testing ergonomics**
- [ ] **TEST-01**: `with_flag/3` test macro forces a flag value for the duration of a block
- [ ] **TEST-02**: `put_flag/3` and `clear_flags/0` helpers for setup/teardown
- [ ] **TEST-03**: `seed_bucket/3` helper for deterministic variant assignment in tests
- [ ] **TEST-04**: StreamData property tests for bucketing determinism (same inputs → same bucket across 10k runs)
- [ ] **TEST-05**: Ecto sandbox `mode: :manual` compatibility; all merge-blocking tests use Fake adapter

**Security & privacy**
- [ ] **SEC-01**: `Rulestead.Admin.Policy` behavior — host supplies authorization; library makes no auth assumptions
- [ ] **SEC-02**: Environment-sensitive authorization — read-only / non-prod editor / prod editor roles supported
- [ ] **SEC-03**: Secure traits / redacted logging — attribute allowlists; PII never enters telemetry or audit by default
- [ ] **SEC-04**: Custom Credo check (`NoRawTraitsInLogger`) enforces redaction discipline

**Error model**
- [ ] **ERR-01**: Root `Rulestead.Error` struct with closed-atom `:type` field
- [ ] **ERR-02**: Typed sub-errors (`EvaluationError`, `RulesetError`, `KillSwitchError`, `ConfigError`, `StoreError`, `AuthError`)
- [ ] **ERR-03**: `:cause` field excluded from Jason.Encoder to prevent payload leakage in audit rows
- [ ] **ERR-04**: Paired `evaluate/3` (non-raising) + `evaluate!/3` (raising) for every public verb

**Release engineering**
- [ ] **REL-01**: Hex package published at `rulestead` and `rulestead_admin` with linked-versions release-please
- [ ] **REL-02**: Conventional commits + PR title lint gate
- [ ] **REL-03**: Post-publish verification trio: `mix verify.workspace_clean`, `mix verify.release_publish`, `mix verify.release_parity` (scrypath pattern)
- [ ] **REL-04**: Daily drift cron with rolling GitHub issue (JasonEtco/create-an-issue, `update_existing: true`)
- [ ] **REL-05**: CI matrix: Elixir 1.17/OTP 26.x and 1.19/OTP 28.x; Postgres 15+ service container
- [ ] **REL-06**: `api_stability.md` enumerates locked public surface (modules, functions, struct fields, error types, telemetry events, NimbleOptions schema keys)

**Documentation**
- [ ] **DOC-01**: README quickstart targets Alex (App Dev) — 60-second overview, 15-min quickstart
- [ ] **DOC-02**: Guides split into `introduction/` (installation, getting-started, upgrading), `flows/` (per-use-case), `recipes/` (testing, telemetry, deployment)
- [ ] **DOC-03**: `mix docs --warnings-as-errors` as CI gate
- [ ] **DOC-04**: `CONVENTIONS.md` codifies discipline layer (determinism, precedence, tenancy, testing)
- [ ] **DOC-05**: Cheatsheet (`guides/cheatsheet.cheatmd`) — one-page API surface
- [ ] **DOC-06**: Extending guide — documented behaviors: `Rulestead.Store`, `Rulestead.RuleEngine`, `Rulestead.EvaluationCache`, `Rulestead.AuditStore`, `Rulestead.ActorResolver`, `Rulestead.Admin.Policy`

### Out of Scope (v0.1.0) — Tracked for Future Roadmap

Deferred to v0.2+ (not building now, but explicitly captured so we don't lose track).

**v0.2 — Governance & Operator Confidence**
- Approvals / change requests (dual-control for prod changes)
- Scheduled changes (future-dated toggles with preview)
- Webhooks (outbound notifications on flag mutations)
- Multi-tenant scoping behavior (`Rulestead.Tenancy` + `SingleTenant` no-op default, mailglass pattern)
- OpenTelemetry bridge (opt-in behind `Code.ensure_loaded?` guard)
- Import/export beyond JSON snapshots (YAML, git-native storage)
- Code references / stale-flag cleanup automation (GitHub issue hooks, codemod helpers)
- Enhanced diagnostics page (`/flags/diagnostics` with cache stats, refresh status, recent changes)

**v0.3 — Experimentation & Ecosystem**
- Variant impressions / exposure event hooks (beyond basic telemetry)
- Tracking hooks for analytics/conversion events
- OpenFeature provider bridge
- Redis store adapter
- Multi-node sharded cache / streaming deltas (SSE/WS)
- Sample-ratio-mismatch detection
- Bandit / adaptive experimentation (later — requires stats engine)

**v0.4+ — Platform Leverage**
- Client-side SDK payloads (server-side-only remains default)
- GraphQL / REST public API (beyond mountable LiveView admin)
- Guardrail metrics / automated rollback on SLO breach
- Git-backed authoring store (Flipt-style branching / merge proposals)
- AI assistance in admin UI (explain-a-rollout-in-plain-English, cleanup suggestions)

### Permanently Out of Scope (by design)

| Feature | Why excluded |
|---|---|
| Hosted SaaS offering | Rulestead is self-hostable OSS; no competing-with-LaunchDarkly product |
| Built-in statistics engine for experiments | Expose impression/tracking hooks; analytics computation belongs in user's warehouse |
| Deep bundled auth stack | Host-app supplies `Rulestead.Admin.Policy`; keep auth assumptions out of the library |
| Per-request randomness as default for user-facing rollouts | Flipper/FunWithFlags footgun; sticky actor bucketing is the default |
| Ambient process-dictionary context magic | Explicit Context struct; optional process-tree helpers with documented scope only |
| DB-row-by-row runtime evaluation | Always snapshot + ETS cache; evaluator never hits Postgres on hot path |
| Mobile-native SDKs (iOS/Android) | Phoenix-native is the positioning; mobile clients are v1.x+ if at all |

## Context

**Domain:** Elixir/Phoenix ecosystem has a real gap between FunWithFlags (good but boolean-only, narrow scope, maintenance concerns per public fork) and external platforms (Unleash, LaunchDarkly, Flagsmith, Flipt, GrowthBook). The research brief in `prompts/elixir_feature_flags_research_brief.md` documents this gap comprehensively (1720 lines, §1 gap analysis through §28 source list).

**Engineering DNA:** All patterns are ported verbatim from 7 prior shipped Elixir OSS libraries — `accrue`, `scrypath`, `lattice_stripe`, `sigra`, `mailglass`, `lockspire`, `threadline`. Documented in `prompts/rulestead-engineering-dna-from-prior-libs.md`. Convergence rule: 5-of-7 or more = adopt without debate (§2 of that doc).

**Personas (design targets):** Documented in `prompts/rulestead-personas-jtbd-and-onboarding.md`.
- **Alex** — App Dev: 15-min quickstart, test-first, low cognitive overhead
- **Tova** — Tech Lead: safe staged rollouts, conventions, extension points
- **Priya** — PM/Operator: simple-mode admin, human-readable UI, safe approvals
- **Sam** — Support: explain-a-decision, entity targeting, history
- **Shiori** — SRE: bookmarkable kill switch, health/diagnostics, low dependency count
- **Omar** — OSS Contributor: clean behaviors, readable internals, extension guide

**Brand:** Calm, infrastructure-grade, Elixir-native, explainable, steady under operational pressure. Tagline direction: "Runtime decisions, made clear." Color posture: mineral/dark neutrals + controlled blue + restrained ember accent. Type stack: Sora + Inter + IBM Plex Mono. Visual metaphor: paths/layers/topology — never literal flags or phoenix mascots. Full brand book: `prompts/rulestead-brand-book.md`.

**Prior art / footguns consulted:** FunWithFlags (baseline shape, startup-order brittleness), Flipper (percentage-of-time warning), Unleash (lifecycle state model), GrowthBook (simulation/archetypes), Flagsmith (multivariate + identity/segment), Flipt (self-hosting story), LaunchDarkly (governance patterns), OpenFeature (abstraction boundary). Full lessons in research brief §4.

## Constraints

- **Tech stack**: Elixir 1.17+/OTP 26+; target matrix 1.17/26.x and 1.19/28.x. Phoenix 1.7+, Ecto 3.11+, LiveView 1.0+. Postgres 15+. — Matches prior-lib DNA; no ecosystem surprises.
- **License**: MIT. — Standard across Jon's OSS lineage; maximum adoption.
- **Packaging**: Sibling packages from day 1 (`rulestead` + `rulestead_admin`) with linked-versions release-please. — Accrue/mailglass precedent; keeps admin optional without single-tarball bloat.
- **Runtime purity**: Evaluator must be pure — no I/O, no DB reads on hot path, no ambient context magic. — Research brief §7.1; cache + snapshot pattern non-negotiable.
- **Public API stability**: `api_stability.md` enumerates locked surface from v0.1.0; deprecations require major-version bump (pre-1.0: new public modules/functions = minor bump, not patch). — lattice_stripe precedent.
- **Hex publishing**: `package.files` whitelist (never auto-include whole repo); never include `test/example/`, `*_ops/`, `.planning/`, `prompts/`. — engineering DNA §2.1.
- **Zero required host-app dependencies beyond Phoenix/Ecto/LiveView**: Oban / OpenTelemetry / Redis are all optional. — Adoption gradient (research brief §7.6).
- **No PII in telemetry, logs, or audit meta by default**: Enforced by custom Credo checks. — Research brief §15.3; lockspire precedent.
- **Host-app owns auth**: `Rulestead.Admin.Policy` behavior; library ships no auth stack. — Research brief §15.1.

## Key Decisions

| Decision | Rationale | Outcome |
|---|---|---|
| Sibling packages (`rulestead` + `rulestead_admin`) from day 1 | Matches accrue/mailglass DNA; clean Hex separation; admin stays optional; linked-versions release-please keeps them in lockstep | — Pending (validate at v0.1.0 publish) |
| Ordered rules, first-match-wins (not gate precedence) | Teachable, simulatable, explainable. Research brief §5.5 + GrowthBook precedent. Avoids FunWithFlags precedence-confusion footgun | — Pending |
| Snapshot-based local evaluation (ETS cache; never DB reads on hot path) | Fast, store-independent, versionable, diffable, restart-resilient. Research brief §11.3 | — Pending |
| Deterministic bucketing from `(flag_key, rule_key, salt, targeting_key)` | Stable rollout, migratable hash algo, explainable in debug output. Research brief §11.4 | — Pending |
| Skip research agents; import `prompts/` anchor docs as the research layer | User has already produced research-grade material (1720-line brief + 7-lib DNA synthesis); re-deriving would waste tokens and dilute signal | — Pending |
| v0.1.0 includes admin UI (ambitious v1 scope) | Without admin, personas Priya/Sam/Shiori have zero JTBD coverage; the library is not "batteries-included" without it. Research brief §27 v1 acceptance criteria explicitly requires embedded admin | — Pending |
| Defer approvals / scheduled changes / webhooks to v0.2 governance milestone | Research brief §20 phases 2-3 split; protects v0.1 timeline | — Pending |
| `Rulestead.Fake` adapter as release-gate target | mailglass pattern: merge-blocking tests use Fake; real-Postgres is advisory (nightly). Keeps CI fast and deterministic | — Pending |
| Custom Credo checks for domain rules from v0.1 | Enforce determinism, tenancy scoping, PII hygiene mechanically — not by review | — Pending |
| Golden-diff installer test | sigra pattern ported wholesale; catches installer regressions byte-for-byte | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — promote v0.2+ items to Active if milestone cadence allows
4. Update Context with current state

---
*Last updated: 2026-04-23 after initialization*

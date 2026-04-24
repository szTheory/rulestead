# Requirements: Rulestead

**Defined:** 2026-04-23
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1 Requirements (v0.1.0 — first polished Hex release)

### Evaluation (EVAL)

- [ ] **EVAL-01**: App code can evaluate a boolean flag via `Rulestead.enabled?/2` by passing an in-memory authored flag payload as the first argument and a `Rulestead.Context` or map/keyword input normalized by `Rulestead.Context.new/1` as the second; the non-bang call returns `{:ok, boolean}` or `{:error, %Rulestead.Error{}}`
- [ ] **EVAL-02**: App code can resolve a multivariate value via `Rulestead.get_value/3` by passing the in-memory authored flag payload first, context second, and an explicit default third; the non-bang call returns `{:ok, value}` or `{:error, %Rulestead.Error{}}` (typed: boolean/string/integer/float/map)
- [ ] **EVAL-03**: App code can get an assigned variant via `Rulestead.get_variant/2` by passing the in-memory authored flag payload first and context second; the non-bang call returns `{:ok, variant_key | nil}` or `{:error, %Rulestead.Error{}}`
- [ ] **EVAL-04**: Evaluator returns a structured `Rulestead.Result` (value, variant, reason, matched_rule, flag_key, flag_version, cache_age_ms, optional debug_trace)
- [ ] **EVAL-05**: Rules are evaluated in order, first-match-wins; default value applies if none match
- [ ] **EVAL-06**: Bucketing is deterministic from `(flag_key, rule_key, salt, targeting_key)` — same inputs → same bucket across 10k property-test runs
- [ ] **EVAL-07**: Missing `targeting_key` on sticky rules emits one sanitized telemetry warning in permissive mode and returns `{:error, %Rulestead.Error{type: :missing_targeting_key}}` from non-bang evaluation APIs in strict mode
- [ ] **EVAL-08**: `Rulestead.explain/2` accepts the in-memory authored flag payload first and context second, and returns `{:ok, human_readable_trace}` or `{:error, %Rulestead.Error{}}`
- [ ] **EVAL-09**: Evaluator is pure — no I/O, no DB reads on hot path, no ambient process-dictionary surprises

### Context & Propagation (CTX)

- [ ] **CTX-01**: Explicit `Rulestead.Context` struct builder (`actor`, `targeting_key`, `tenant_key`, `environment`, `attributes`, `request_id`, `session_id`, `strict?`), with `subject` accepted only as an input alias during normalization if needed
- [ ] **CTX-02**: `Rulestead.Phoenix.context_from_conn/1` builds Context from a Plug.Conn
- [ ] **CTX-03**: `Rulestead.LiveView.context_from_socket/1` builds Context from a LiveView socket
- [ ] **CTX-04**: `Rulestead.Oban.context_from_job/1` + Oban middleware attaches Context at enqueue
- [ ] **CTX-05**: Process-tree context propagation is documented and scoped (no ambient magic)

### Store & Snapshots (STORE)

- [x] **STORE-01**: Ecto-backed authoring store with Postgres migrations shipped via `mix rulestead.install`
- [ ] **STORE-02**: Snapshot serialization (versioned binary payload) published on write
- [ ] **STORE-03**: ETS compiled snapshot cache with Phoenix.PubSub refresh + polling fallback
- [ ] **STORE-04**: Cache age and snapshot version exposed in debug/diagnostics output
- [ ] **STORE-05**: Startup resilient — no hard dependency on host-app process start order; documented degraded mode
- [ ] **STORE-06**: Optional disk backup for evaluator restart without control-plane connectivity
- [ ] **STORE-07**: `Rulestead.Fake` in-memory adapter for tests (time-advanceable cache, no Postgres required)

### Rules & Variants (RULE)

- [ ] **RULE-01**: Rule conditions support attribute predicates (equals, in, not_in, gt/lt, regex, exists)
- [ ] **RULE-02**: Segments are reusable targeting definitions referenced by rules
- [ ] **RULE-03**: Variants carry stable keys + rollout weights that sum to 100% (validated at save)
- [ ] **RULE-04**: Bucketing strategy selectable per rule (subject / account / tenant / session)

### Telemetry (TEL)

- [ ] **TEL-01**: `Rulestead.Telemetry.span/3` wrapper emits `[:rulestead, domain, resource, action, :start|:stop|:exception]` spans for every public operation
- [ ] **TEL-02**: Event catalog documented in `guides/flows/telemetry.md`; events versioned as public API
- [x] **TEL-03**: No PII / secrets / raw payloads in telemetry meta — enforced by custom Credo check `NoRawTraitsInTelemetryMeta`
- [ ] **TEL-04**: Telemetry handlers never raise; tolerate any reason atom and meta shape

### Admin UI (ADMIN — rulestead_admin package)

- [ ] **ADMIN-01**: Flag list page with search/filter (key, environment, lifecycle state, owner, stale status, tags)
- [ ] **ADMIN-02**: Flag detail page — description, type, default value, ordered rules, per-env status, audit timeline
- [ ] **ADMIN-03**: Rule editor — create/edit/reorder/delete rules; add conditions; assign variant weights
- [ ] **ADMIN-04**: Simulation / "explain" page — operator enters targeting_key + traits + env, sees value/variant/matched rule/trace
- [x] **ADMIN-05**: Rollout controls — percentage rollout editor with rule ordering preview
- [ ] **ADMIN-06**: Kill switch — bookmarkable one-click disable per flag per environment with confirmation
- [ ] **ADMIN-07**: Audit timeline — who changed what, before/after diff, environment, linked actor
- [x] **ADMIN-08**: Environments model — dev/staging/prod with per-env behavior on a single flag identity; prod stricter
- [ ] **ADMIN-09**: Lifecycle view — owner, expected expiration, stale / potentially-stale markers, last changed
- [ ] **ADMIN-10**: Admin mounts via single line in `router.ex`; authorization delegates to `Rulestead.Admin.Policy` behavior supplied by host

### Installer & Host-App Seam (INST)

- [ ] **INST-01**: `mix rulestead.install` generates migrations, config, endpoint Plug, router mount
- [ ] **INST-02**: Installer is idempotent — second run emits "already injected / skipping" only
- [ ] **INST-03**: Golden-diff test: fresh `mix phx.new` + install → byte-identical tree/stdout fixture (sigra pattern)
- [ ] **INST-04**: `plug Rulestead.Plug` in endpoint puts Context on conn assigns
- [ ] **INST-05**: `Rulestead.LiveView.assign_flags/2` helper for eager flag assignment
- [ ] **INST-06**: `Rulestead.Oban.Middleware` attaches Context to jobs at enqueue

### Lifecycle Hygiene (LIFE)

- [ ] **LIFE-01**: Creating a flag requires `owner` (team/person) and `expected_expiration` (or explicit "permanent")
- [ ] **LIFE-02**: Lifecycle state surfaced in flag list (active / potentially_stale / stale / archived)
- [ ] **LIFE-03**: Potentially-stale detection based on configurable age threshold + last_evaluated_at
- [ ] **LIFE-04**: Archived flags are read-only and excluded from evaluation

### Testing Ergonomics (TEST)

- [ ] **TEST-01**: `with_flag/3` test macro forces a flag value for the duration of a block
- [ ] **TEST-02**: `put_flag/3` and `clear_flags/0` helpers for setup/teardown
- [ ] **TEST-03**: `seed_bucket/3` helper for deterministic variant assignment in tests
- [ ] **TEST-04**: StreamData property tests for bucketing determinism (same inputs → same bucket, 10k runs)
- [ ] **TEST-05**: Ecto sandbox `mode: :manual` compatibility; all merge-blocking tests use Fake adapter

### Security & Privacy (SEC)

- [ ] **SEC-01**: `Rulestead.Admin.Policy` behavior — host supplies authorization; library ships no auth assumptions
- [ ] **SEC-02**: Environment-sensitive authorization — read-only / non-prod editor / prod editor roles
- [x] **SEC-03**: Secure traits / redacted logging — attribute allowlists; PII never enters telemetry or audit by default
- [x] **SEC-04**: Custom Credo check `NoRawTraitsInLogger` enforces redaction discipline

### Error Model (ERR)

- [ ] **ERR-01**: Root `Rulestead.Error` struct with closed-atom `:type` field
- [ ] **ERR-02**: Typed sub-errors (`EvaluationError`, `RulesetError`, `KillSwitchError`, `ConfigError`, `StoreError`, `AuthError`)
- [ ] **ERR-03**: `:cause` field excluded from `Jason.Encoder` to prevent payload leakage in audit rows
- [ ] **ERR-04**: Paired `evaluate/3` (non-raising) + `evaluate!/3` (raising) for every public verb

### Release Engineering (REL)

- [ ] **REL-01**: Hex publishes `rulestead` + `rulestead_admin` with linked-versions release-please
- [ ] **REL-02**: Conventional commits + PR title lint gate
- [ ] **REL-03**: Post-publish verification trio: `mix verify.workspace_clean`, `mix verify.release_publish`, `mix verify.release_parity`
- [ ] **REL-04**: Daily drift cron with rolling GitHub issue (`update_existing: true`)
- [ ] **REL-05**: CI matrix — Elixir 1.17/OTP 26.x and 1.19/OTP 28.x; Postgres 15+ service container
- [ ] **REL-06**: `api_stability.md` enumerates locked public surface (modules, functions, struct fields, error types, telemetry events, NimbleOptions schema keys)

### Documentation (DOC)

- [ ] **DOC-01**: README quickstart targets Alex — 60-second overview, 15-min quickstart
- [ ] **DOC-02**: Guides split: `introduction/` (installation, getting-started, upgrading), `flows/` (per-use-case), `recipes/` (testing, telemetry, deployment)
- [ ] **DOC-03**: `mix docs --warnings-as-errors` as CI gate
- [ ] **DOC-04**: `CONVENTIONS.md` codifies discipline layer (determinism, precedence, tenancy, testing)
- [ ] **DOC-05**: Cheatsheet (`guides/cheatsheet.cheatmd`) — one-page API surface
- [ ] **DOC-06**: Extending guide documents public behaviors (`Rulestead.Store`, `Rulestead.RuleEngine`, `Rulestead.EvaluationCache`, `Rulestead.AuditStore`, `Rulestead.ActorResolver`, `Rulestead.Admin.Policy`)

---

## v2 Requirements (Governance & Operator Confidence)

Tracked but not in current roadmap. Surface for promotion at v0.2 kickoff.

### Governance (GOV)

- **GOV-01**: Approvals / change requests — dual-control for prod changes
- **GOV-02**: Scheduled changes — future-dated toggles with preview
- **GOV-03**: Webhooks — outbound notifications on flag mutations
- **GOV-04**: Enhanced diagnostics page (`/flags/diagnostics` with cache stats, refresh status, recent changes)

### Multi-Tenancy & Observability (MTO)

- **MTO-01**: `Rulestead.Tenancy` behavior + `SingleTenant` no-op default (mailglass pattern)
- **MTO-02**: Optional `Oban.TenancyMiddleware`
- **MTO-03**: OpenTelemetry bridge (opt-in behind `Code.ensure_loaded?(OpenTelemetry)` guard)

### Portability (PORT)

- **PORT-01**: Import/export beyond JSON snapshots (YAML, git-native storage)
- **PORT-02**: Code references / stale-flag cleanup automation (GitHub issue hooks, codemod helpers)

---

## v3 Requirements (Experimentation & Ecosystem)

### Experimentation (EXP)

- **EXP-01**: Variant impressions / exposure event hooks (beyond basic telemetry)
- **EXP-02**: Tracking hooks for analytics/conversion events
- **EXP-03**: Sample-ratio-mismatch detection

### Ecosystem (ECO)

- **ECO-01**: OpenFeature provider bridge
- **ECO-02**: Redis store adapter
- **ECO-03**: Multi-node sharded cache / streaming deltas (SSE/WS)

---

## Out of Scope (permanently, by design)

| Feature | Reason |
|---------|--------|
| Hosted SaaS offering | Rulestead is self-hostable OSS; no competing-with-LaunchDarkly product |
| Built-in statistics engine for experiments | Expose impression/tracking hooks only; analytics computation lives in user's warehouse |
| Bundled auth stack | Host supplies `Rulestead.Admin.Policy`; keep auth assumptions out of the library |
| Per-request randomness as default for user-facing rollouts | Flipper/FunWithFlags footgun; sticky actor bucketing is the default |
| Ambient process-dictionary context magic | Explicit Context struct required; optional process-tree helpers with documented scope only |
| DB-row-by-row runtime evaluation | Always snapshot + ETS cache; evaluator never hits Postgres on hot path |
| Mobile-native SDKs (iOS/Android) | Phoenix-native positioning; mobile clients not a v1.x goal |
| Gate-priority precedence model | Chose ordered rules / first-match-wins instead (research brief §5.5, §7.4) |
| Percentage-of-time as a first-class rollout type | Hidden as advanced/dark-launch mode; sticky actor-based is the default wizard path |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| EVAL-01..09 | Phase 3 | Pending |
| CTX-01 | Phase 3 | Pending |
| CTX-02..05 | Phase 5 | Pending |
| STORE-01 | Phase 2 | Complete |
| STORE-07 | Phase 2 | Pending |
| STORE-02..06 | Phase 4 | Complete |
| RULE-01..04 | Phase 3 | Pending |
| TEL-01, TEL-02, TEL-04 | Phase 4 | Complete |
| TEL-03 | Phase 7 | Pending |
| ADMIN-08 (schema) | Phase 2 | Complete |
| ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-08 (UI), ADMIN-10 | Phase 6 | Pending |
| ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-09 | Phase 7 | Pending |
| INST-01..06 | Phase 5 | Pending |
| LIFE-01..04 | Phase 6 | Pending |
| TEST-04 | Phase 3 | Pending |
| TEST-01, TEST-02, TEST-03, TEST-05 | Phase 5 | Pending |
| SEC-01..04 | Phase 7 | Pending |
| ERR-01..04 | Phase 2 | Pending |
| REL-01, REL-02, REL-05 | Phase 1 | Pending |
| REL-03, REL-04, REL-06 | Phase 8 | Pending |
| DOC-01, DOC-02, DOC-03 | Phase 1 | Pending |
| DOC-04, DOC-05, DOC-06 | Phase 8 | Pending |

**Coverage:**
- v1 requirements: 74 total (EVAL:9, CTX:5, STORE:7, RULE:4, TEL:4, ADMIN:10, INST:6, LIFE:4, TEST:5, SEC:4, ERR:4, REL:6, DOC:6)
- Mapped to phases: 74
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-23*
*Last updated: 2026-04-23 after initial definition*

# Rulestead Engineering DNA — Inherited from Prior Elixir/Phoenix Libs

> **Purpose:** Master context doc for a fresh LLM seeding a new GSD project for `rulestead` (Elixir-native feature-flags + experimentation + remote-config platform with mountable Phoenix LiveView admin). Every pattern here has already been paid for in another Jon repo.
>
> **Source corpus:** Seven prior Elixir/Phoenix OSS libs, all shipped or nearly shipped, all GSD-planned:
> - `accrue` — Stripe-native billing toolkit (`accrue` + `accrue_admin`, monorepo, v1.0+ shipped, 42 phases, 8 milestones)
> - `scrypath` — Ecto-native search indexing (single package + optional `scrypath_ops/` companion, v0.3.4 live on Hex, 70 phases, 17 shipped milestones)
> - `lattice_stripe` — Production Stripe SDK (single package, v1.1 live on Hex, 37 phases, consumed by `accrue`)
> - `sigra` — Phoenix auth library w/ mountable admin LiveViews (single package + `test/example/` host, v0.2, 59 shipped phases)
> - `mailglass` — Phoenix-native email framework (sibling `mailglass` + `mailglass_admin`, v0.1 in flight, DNA-synthesized from all 4 above)
> - `lockspire` — OAuth/OIDC server embedded in Phoenix (single package, in discovery, 12 topical synthesis docs drafted pre-implementation)
> - `threadline` — Audit logging for Elixir/Phoenix/Ecto (single package, v0.1-dev, trigger-backed capture pattern)
>
> **How to read this doc:** §1 is confidence calibration. §2 is convergent DNA (4-of-7 = port verbatim). §3 is the divergent menu (pick per use case). §4 translates everything to flag-domain primitives. §5 is the concrete v0.1 starter skeleton. §6 is the gotcha list. §7 is the opinionated GSD seed plan. §8 is the source map for deeper digs. §9 is the ranked TL;DR. §10 points at the topical deep-dive docs in this prompts folder.

---

## 1. Provenance & confidence calibration

| Source project | Maturity | Strongest contribution to rulestead |
|---|---|---|
| `accrue` | v1.0+ shipped, 42 phases, multi-package monorepo | Sibling-package shape (`rulestead` + `rulestead_admin`), linked-versions release-please config, append-only event ledger, polymorphic ownership, browser/UAT CI lanes (`accrue_admin_browser.yml`, `accrue_host_uat.yml`), phase-numbered CI gate chain |
| `scrypath` | v0.3.4 live on Hex, 70 phases | **Richest planning discipline**, post-publish verification trio (`verify.workspace_clean` + `verify.release_publish` + `verify.release_parity`), daily drift cron with rolling GitHub issue, doc-contract tests, separate-app companion (`scrypath_ops/`) pattern, milestone-audit YAML frontmatter template |
| `lattice_stripe` | v1.1 live on Hex, downstream-consumed | Cleanest `api_stability.md` contract (public surface enumeration), pluggable-behaviour trio pattern (Transport / Json / RetryStrategy with `@moduledoc false` default adapter), Stripe-spec drift monitor (`drift.yml` weekly), Dependabot auto-merge patch-only, PR-title semantic-commit gate, cheatsheet guide (`cheatsheet.cheatmd`) |
| `sigra` | v0.2, mature Phoenix integration | **Mountable LiveView admin pattern** (the single closest precedent for rulestead's flag-admin UI), feature-walker installer architecture (`Sigra.Install.Feature` behaviour + `Runner` + central `MigrationTimestamps`), **golden-diff installer tests** under `test/fixtures/install_golden/{tree,STDOUT.txt}`, Playwright-on-GitHub-Pages daily demo, host-owned admin policy behaviour (`Sigra.Admin.Policy`), 3-folder guides split (`introduction/flows/recipes`), `CONVENTIONS.md` discipline layer with custom Credo checks |
| `mailglass` | most-recent DNA synthesis, Phoenix-native | **Master DNA template** (the 9-section skeleton this doc follows), Premailex/render-pipeline seam patterns apply as evaluator-pipeline seams, Fake-adapter-as-release-gate pattern, multi-tenant scope pattern (`Mailglass.Tenancy` behaviour + `SingleTenant` default no-op + optional `Oban.TenancyMiddleware`), idempotency-key partial unique index, optional-deps gateway (`OptionalDeps.{Oban,OpenTelemetry,...}`) |
| `lockspire` | richest topical split (12 prompts) | **Topical-split doc template** (this whole folder's shape), host-app integration seam doc pattern, security-posture-as-charter, operator-admin IA and workflows, LiveView field guide with 15 LLM-ready build rules, Ecto-in-production rules (513 lines), domain-language field guide pattern, market-gap/positioning structure |
| `threadline` | v0.1-dev | **Append-only by absence of write path** (trigger-backed capture, no app-level insert), PgBouncer-safe actor GUC bridge (`set_config(..., true)` scoped to transaction), three-layer separation (capture / semantics / exploration), `ActorRef` as a custom Ecto type, `verify.*` alias naming discipline |

**Confidence rules:**
- **5-of-7 or more convergence** → adopt without debate.
- **3-of-7 to 4-of-7** → adopt unless rulestead has a specific reason not to.
- **2-of-7 with diverging reasoning** → menu choice; §3 explains the trade-off.
- **1-of-7** → only port if the precedent is the closest match (e.g., sigra's mountable LiveViews for the admin UI; scrypath's post-publish verification spine).

---

## 2. Convergent DNA — port verbatim

These patterns appear in **5+ of 7** prior libs. They are not opinions — they are the validated default. Skipping any of them means re-paying a cost already paid.

### 2.1 Repo, package, and version metadata

- **Single source of truth for version**: `@version` module attribute at top of `mix.exs`, referenced in `docs: [source_ref: "v#{@version}"]` and `release-please-manifest.json`. Never hand-edit version in two places.
- **Hex package whitelist files explicitly** in `mix.exs`:  
  `files: ~w(lib priv guides .formatter.exs mix.exs README* LICENSE* CHANGELOG*)`  
  Never auto-include the whole repo. Never include `test/example/`, `*_ops/` companion apps, `.planning/`, or `prompts/`. Add a comment above the whitelist saying what is forbidden and why.
- **Hex package metadata table**: `name`, `description`, `licenses: ["MIT"]`, `links: %{"GitHub" => @source_url, "HexDocs" => ..., "Changelog" => ..., "Guides" => ...}`. The Changelog link is the most-used by adopters in practice.
- **`.formatter.exs`** is intentionally minimal: an `inputs:` glob plus the deps (`:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug`) whose macros need formatting. No custom rules. Include `.formatter.exs` itself in `package.files` so `import_deps: [:rulestead]` works downstream.
- **Project root files** (always present): `README.md`, `CHANGELOG.md`, `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `MAINTAINING.md` (release runbook — accrue/sigra pattern — secret setup, branch protection settings, recovery decision tree). `CLAUDE.md` and `AGENTS.md` as dual entry points.
- **Module namespacing**: root module (`Rulestead`) is the public surface (reflection + orchestration + error types). Internal modules use `@moduledoc false` to lock the public API. Every module either has a full `@moduledoc` (public) or `@moduledoc false` (internal) — no ambiguous middle state.
- **`CONVENTIONS.md`** (sigra pattern): codify the discipline layer — flag-evaluation determinism rules, rule-precedence semantics, tenancy scoping, testing conventions. Pair with custom Credo checks that enforce each convention mechanically.

### 2.2 CI/CD lane structure

Every project converges on this lane shape:

| Lane | Purpose | Blocks merge? |
|---|---|---|
| **Lint** | `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix docs --warnings-as-errors`, `mix hex.audit`, `mix compile --no-optional-deps --warnings-as-errors` | yes |
| **Test matrix** | `mix test --warnings-as-errors` across multiple Elixir/OTP cells (minimum: 1.17/26.x, 1.19/28.x). Postgres 15+ service container with healthcheck. | yes |
| **Integration / golden** | Real-service or generated-host-app proof (`stripe-mock`-style, fresh `mix rulestead.install` byte-identical golden diff, host-app smoke) | yes for paths that touch it |
| **Installer path-gate** | Shell `git diff --name-only origin/${base}...HEAD \| grep -qE '^priv/templates/rulestead\.install/\|^lib/rulestead/install/'` — only run expensive fixture harness when installer surfaces change | yes (conditional) |
| **Release-please** | Auto-bump version + CHANGELOG on `main` | n/a (opens a PR) |
| **Publish-Hex** | Triggers on tag from release-please merge | n/a (release-time only) |
| **Post-publish verify** | Polls Hex for tarball visibility, compiles a throwaway consumer app, checks HexDocs reachability, runs parity diff between git tag and Hex tarball | not for that PR — runs on publish + daily cron |

Specifics that every project shares:
- **Concurrency group** with `cancel-in-progress: true` to kill stale CI runs on force-push.
- **Path filters** to skip CI on `.md` / `.planning/` / `prompts/` / `guides/` only changes when nothing in `lib/` changed.
- **Caching layers** keyed by `mix.lock` hash: `deps/`, `_build/`, dialyzer PLT (split restore→build-if-miss→save), `~/.hex` registry, Node npm cache for Playwright.
- **Postgres service container** in any job needing Ecto, with healthcheck `--health-interval=10s --health-timeout=5s`. Credentials via env vars.
- **Secrets** (`HEX_API_KEY`, `RELEASE_PLEASE_TOKEN`) only as GHA secrets. Never echoed, never in logs, never in the workflow file.
- **Least privilege**: `permissions: contents: read` at workflow top; jobs that need `id-token: write` or `pull-requests: write` opt in explicitly.
- **SHA-pinned third-party actions with trailing version comments** (sigra pattern): `uses: actions/checkout@de0fac2e...  # v6.0.2`. Dependabot `github-actions` ecosystem handles churn.
- **Job-id contract comment** at top of each workflow file: "Stable YAML `jobs:` keys relied on by docs, `act`, and branch protection." `name:` is allowed to evolve; `id:` is immutable.
- **Scripts-first CI surface** (accrue/sigra pattern): every non-trivial CI step is a `scripts/ci/*.sh` with `set -euo pipefail`, and both invocations (`GITHUB_WORKSPACE:-$(pwd)`) work. Locally reproducible by design. Never bury logic in inline YAML `run:` blocks longer than ~6 lines.

Full details → `rulestead-release-engineering-and-ci.md`.

### 2.3 Release & versioning

**Conventional Commits + Release Please + scrypath's post-publish verification spine is the universal default.** Specifics:

- Commit format: `type(scope): subject`. Types: `feat | fix | docs | test | refactor | chore | perf | style`. Scope is usually a phase tag (`feat(eval-04-02): ...`) or a component (`fix(admin): ...`).
- `feat:` → minor bump. `fix:` → patch bump. Breaking change footer (`BREAKING CHANGE:`) → major. (Pre-1.0, the universal rule: new public modules/functions = minor bump, NOT patch. Patches are doc/internal only.)
- `release-please-manifest.json` is single source of truth for last-published version.
- **Single-package release-please config** for rulestead v0.x (start lean; switch to linked-versions multi-package only if `rulestead_admin` is split into a sibling package). Tags: `v0.1.0`, not component-prefixed.
- **Manual publish fallback** (`publish-hex.yml` with `workflow_dispatch`): re-runs the same gate chain keyed to `inputs.tag` and `inputs.release_version`. Dry-run validation + version verification before publishing — for the day Release Please breaks.
- **Post-publish verification** (scrypath pattern — port the trio verbatim):
  - `mix verify.workspace_clean` — `git status --porcelain` scoped to `package.files ++ ["test"]`. No escape-hatch flag.
  - `mix verify.release_publish <version>` — polls Hex for tarball (10×15s = 150s budget), spins up `mix new rulestead_consumer`, rewrites `mix.exs` to depend on the just-published version, compiles, checks versioned HexDocs URL reachability with `curl -IfsS`.
  - `mix verify.release_parity <version>` — diffs `lib/ + guides/ + docs/` between git tag and Hex tarball. **Three exit codes**: `0 = parity`, `2 = drift (POSIX intentional failure)`, `1 = runtime error`. Pure `compute/2` split out for ExUnit testability.
- **Daily drift cron** (`verify-published-release.yml` at `17 6 * * *`): re-runs `verify.release_publish` + `verify.release_parity` against the latest Hex version. Files a **single rolling GitHub issue** (`JasonEtco/create-an-issue@v2` with `update_existing: true, search_existing: open`) labeled `area:release`, `severity:drift`.
- **PR title lint** (lattice_stripe pattern — `amannn/action-semantic-pull-request@v5`): enforces conventional commits on the squash-merge title. Without this, Release Please degrades silently.
- **Dependabot patch-only auto-merge** (lattice_stripe pattern): `if: github.actor == 'dependabot[bot]'` + `update-type == 'version-update:semver-patch'` → `gh pr merge --auto --squash`. Minor/major still require manual review.
- **CHANGELOG format**: Keep-a-Changelog style. Release Please owns released sections; contributors write Unreleased entries by hand only when auto-generation needs help.

### 2.4 Error model (the single most important convergent pattern)

All 5+ libs use the same shape:

- **One root error struct** (`Rulestead.Error`) with a closed-atom `:type` field, documented in `api_stability.md`.
- **Typed sub-errors** (`Rulestead.EvaluationError`, `Rulestead.RulesetError`, `Rulestead.KillSwitchError`, `Rulestead.ConfigError`, `Rulestead.StoreError`, `Rulestead.AuthError`) — each carrying `:type` ∈ a closed atom set.
- **Pattern-match by struct**, never by message string. `:type` is stable; `:message` is human-readable and may evolve.
- **`:cause` field** on every error, holding the originating exception or raw response. **Excluded from `Jason.Encoder`** so audit logs don't accidentally leak payloads.
- **Raw-body / cause passthrough** — if the error comes from an adapter (store, HTTP, JSON decode), preserve the original in a `:raw` or `:cause` field for debugging without widening the stable contract.
- **Paired functions**: non-raising `evaluate/3 → {:ok, result} | {:error, %Rulestead.EvaluationError{}}` and raising `evaluate!/3 → result | raise` — both documented, both tested.

This triangle (**error struct + typed sub-errors + closed `:type` atom**) is the operational backbone for telemetry meta, audit ledger rows, and host-app pattern matching. Lock it on day 1.

### 2.5 Telemetry — span pattern with 4-level event names

- **Telemetry wrapper module** (`Rulestead.Telemetry.span/3`) delegating to `:telemetry.span/3`. Every public operation emits a span.
- **Event naming**: `[:rulestead, :domain, :resource, :action, :start | :stop | :exception]` — 4 levels before the suffix. Example: `[:rulestead, :eval, :decide, :stop]`, `[:rulestead, :admin, :ruleset, :published]`.
- **`:start / :stop / :exception` trilogy** on every span. `:start` carries `system_time`, `:stop` carries `duration`, `:exception` carries `kind`, `reason`, `stacktrace`.
- **No PII / secrets / raw payloads** in telemetry meta. Counts, statuses, IDs, digests, latencies only. Use `:crypto.hash(:sha256, actor_id)` when correlation is needed without identification.
- **Never raise from telemetry handlers** — the library's handlers must tolerate any reason atom, any meta shape. Document this in the event catalog.
- **Telemetry events are API** — listed in `api_stability.md`, versioned as part of the public contract. Deprecations go through a major bump.
- **Optional OpenTelemetry bridge** behind `Code.ensure_loaded?(OpenTelemetry)` guard. Ship as opt-in helper, not default.

Full event catalog → `rulestead-telemetry-observability-and-audit.md`.

### 2.6 Testing (ExUnit + Mox + Fake adapter)

- **Ecto sandbox** in `test/test_helper.exs`, `use Ecto.Adapters.SQL.Sandbox, repo: Rulestead.Repo, mode: :manual`.
- **Fake adapter as the release-gate target** (mailglass pattern): `Rulestead.Fake` is an in-memory flag store + evaluator + time-advanceable cache. Every merge-blocking test uses it. Real-Postgres and real-SDK integration tests are advisory (nightly / `workflow_dispatch`).
- **Mox for behaviour contracts** — `Rulestead.StoreMock`, `Rulestead.ActorResolverMock`, `Rulestead.RuleEngineMock` — for unit tests that verify interaction patterns.
- **StreamData property tests** for deterministic bucketing (same `(flag_key, actor_id)` → same bucket across 10k runs), ruleset precedence invariants, idempotency-key convergence.
- **Golden-diff installer test** (sigra pattern — port wholesale):
  - Fixture tree under `test/fixtures/install_golden/{tree,STDOUT.txt}`.
  - Test sets up fresh `mix phx.new <tmp>` via `System.cmd`, injects `{:rulestead, path: "..", override: true}`, runs `mix rulestead.install ...`, captures stdout.
  - Normalizes migration timestamps (`TIMESTAMP_` prefix replacement) before comparing.
  - `@moduletag :golden`, `@moduletag timeout: 300_000` (5-min module budget).
  - Paired idempotency test: running `mix rulestead.install` twice emits only "already injected" / "skipping" lines.
- **Doc-contract tests** (scrypath pattern): read README / CONTRIBUTING / guides / workflow YAML / Mix task source into module attrs and assert shared constants + anchors line up. At minimum: README config example matches `lib/rulestead/config.ex` NimbleOptions schema; CI workflow job names match CONTRIBUTING citations.
- **Test helpers as API**: `with_flag/3`, `put_flag/3`, `clear_flags/0`, `seed_bucket/2`, `assert_flag_evaluated/2` — documented, exported, covered by their own tests.

Full testing doc → `rulestead-testing-and-e2e-strategy.md`.

### 2.7 Documentation contracts

- **ExDoc config**: `source_url`, `homepage_url`, `main: "getting-started"`, grouped extras, `source_ref: "v#{@version}"`, `skip_undefined_reference_warnings_on` with a narrow predicate (accrue pattern — `String.starts_with?(ref, "lib/")`) so internal cross-link churn doesn't silence user-facing warnings.
- **`mix docs --warnings-as-errors` as a CI gate** — no warnings allowed.
- **3-folder guides split** (sigra pattern — superior to flat `guides/` dump):
  - `guides/introduction/` — `installation.md`, `getting-started.md`, `upgrading.md`.
  - `guides/flows/` — one guide per primary use case (`evaluation.md`, `rulesets.md`, `rollout.md`, `admin-ui.md`, `sdk.md`, `manifest-sync.md`, `multi-tenant.md`, `audit.md`).
  - `guides/recipes/` — `testing.md`, `telemetry.md`, `ecto-conventions.md`, `sigra-integration.md`, `mailglass-integration.md`, `accrue-integration.md`, `oban-background-rollouts.md`, `deployment.md`.
- **Cheatsheet** (lattice_stripe pattern): `guides/cheatsheet.cheatmd` — ExDoc's `cheatmd` format renders as a quick-reference panel. One-page at-a-glance API surface.
- **`api_stability.md`** (lattice_stripe pattern) as a first-class guide. Enumerate locked public surface (modules without `@moduledoc false`, `@doc`-annotated function arities, struct fields, error-struct `:type` atoms, telemetry event names + metadata keys, NimbleOptions schema keys). Enumerate NOT public (`@moduledoc false` internals, `lib/rulestead/` submodules). Call out deliberate rule-break deviations with a one-line justification + issue/phase pointer.
- **Extending guide** (lattice_stripe pattern): one `guides/flows/extending-rulestead.md` that recipes every public behaviour (`Rulestead.Store`, `Rulestead.RuleEngine`, `Rulestead.EvaluationCache`, `Rulestead.AuditStore`, `Rulestead.ActorResolver`, `Rulestead.Auth`).

### 2.8 Custom Credo checks for domain rules

Every mature prior lib ships a `.credo.exs` `requires:` block that loads project-local checks. Rulestead should ship these from v0.1:

- `Rulestead.Credo.NoEvalOutsideContext` — all `evaluate/3` calls must go through `Rulestead.Evaluations` context (so telemetry + audit + caching are guaranteed).
- `Rulestead.Credo.NoUnscopedTenantQueryInLib` — `Repo` queries on `rulestead_*` tables must pass through `Rulestead.Tenancy.scope/2`.
- `Rulestead.Credo.NoRawTraitsInTelemetryMeta` — flag literal trait-ish keys (`:email`, `:ip`, `:user_agent`, `:phone`, `:name`) in telemetry meta maps.
- `Rulestead.Credo.NoRawTraitsInLogger` — same for `Logger.metadata/1` calls.
- `Rulestead.Credo.NoMutationOutsideMulti` — every write to `rulestead_flags`, `rulestead_rulesets`, `rulestead_rollouts`, `rulestead_audiences` must be inside an `Ecto.Multi` that also writes a `rulestead_events` audit row.
- `Rulestead.Credo.NoSocketCapturedInAsync` — scan LiveView modules for `start_async` / `assign_async` / `stream_async` closures that reference the `socket` variable (lockspire LiveView §6 footgun).

### 2.9 GSD planning structure

`.planning/` skeleton (GSD v1), mirror accrue/sigra/scrypath discipline:

- `PROJECT.md` — seven top-level sections: What This Is / Core Value / Current milestone / Last shipped milestone / Planning window / Requirements (Validated / Active / Recently completed / Out of Scope) / Context & Key Decisions table.
- `ROADMAP.md` — milestone list with version + theme + requirement prefix, archived entries linked into `milestones/vX.Y-{ROADMAP,REQUIREMENTS}.md`.
- `REQUIREMENTS.md` — live requirement set, keyed by tagged IDs (`EVAL-NN`, `RULE-NN`, `ADMIN-NN`, `AUD-NN`, `ROLL-NN`, `INTRO-NN`, `SDK-NN`, `TENANT-NN`, `INT-NN`, `STAB-NN`). IDs survive into commit scopes, CI job comments, test names.
- `phases/NN-slug-kebab-case/` — per-phase dir. Files: `NN-CONTEXT.md`, `NN-RESEARCH.md`, `NN-DISCUSSION-LOG.md`, `NN-PATTERNS.md`, `NN-XX-PLAN.md`, `NN-XX-SUMMARY.md`, `NN-VERIFICATION.md`, `NN-VALIDATION.md`, `NN-REVIEW.md`, optional `NN-UI-SPEC.md`, `NN-HUMAN-UAT.md`, `deferred-items.md`.
- `milestones/vX.Y-MILESTONE-AUDIT.md` — YAML frontmatter (`status: passed | passed_with_advisories | tech_debt | failed`, `scores:`, `gaps:`, `tech_debt:`, `nyquist:`), body sections per scrypath template. Non-blocking advisories recorded verbatim, do not gate archive.
- `seeds/SEED-NNN-*.md` (sigra pattern) — forward-looking ideas that surface at the right milestone (auto-promoting parking lot).
- `research/` — STACK.md + deep-dive notes, feeds `CLAUDE.md` fenced blocks.
- **Per-phase `mix verify.phase<NN>` tasks**, never a kitchen-sink verifier. Phase NN fails alone. Threadline DNA: *"Verification is a product surface. Prefer named entrypoints (`mix verify.*`, `mix ci.*` aliases) that contributors and CI cite verbatim."*

### 2.10 Git hygiene

- **Squash-merge culture**: contributors write messy commits on feature branches; maintainer cleans the squash title (the only commit that becomes `main` history). PR title lint enforces conventional-commit form.
- **Branch protection**: required status checks quoted verbatim by `name:` (not YAML key) in `MAINTAINING.md`. Pin to lane name strings so renames are deliberate.
- **`.gitignore`** excludes `_build/`, `deps/`, `.elixir_ls/`, `erl_crash.dump`, `tmp/`, `.planning/state-manifest.json`-style ephemerals.

---

## 3. Divergent patterns — pick per use case

### 3.1 Single package vs sibling packages

| Project | Choice |
|---|---|
| accrue | `accrue` + `accrue_admin` (linked-versions) |
| mailglass | `mailglass` + `mailglass_admin` (+ `mailglass_inbound` planned) |
| sigra | Single package; admin LiveViews live under `lib/sigra/admin/` |
| scrypath | Single package + `scrypath_ops/` *internal* companion (never on Hex) |
| lattice_stripe | Single package |
| lockspire | Single package planned |
| threadline | Single package |

**Rulestead recommendation: sibling packages.** Start with `rulestead` (core + eval + store + audit + SDK) + `rulestead_admin` (LiveView dashboard). Rationale:

- Adopters who only want eval (server-side gating, no admin UI) don't carry `phoenix_live_view` + CSS/JS bundle weight.
- Admin UI churn happens on its own release cadence without bumping the evaluator for every dashboard polish.
- Linked-versions release-please config keeps them in lockstep when an eval change forces an admin change.
- Port accrue's `ACCRUE_ADMIN_HEX_RELEASE=1` env-swap trick: admin's `mix.exs` depends on `{:rulestead, path: "../rulestead"}` in dev/CI and `{:rulestead, "~> #{@version}"}` in the publish job.
- Admin ships `priv/static/*.{css,js}` prebuilt in the Hex tarball so adopters don't need esbuild.

### 3.2 Generators / installers

| Project | Choice |
|---|---|
| accrue | `mix accrue.install` + `mix accrue_admin.install`, macro-based router injection (`accrue_admin "/billing"` one-liner) |
| sigra | `mix sigra.install`, paste-scopes-into-host-router installer injection |
| mailglass | `mix mailglass.install`, feature-walker architecture planned |
| scrypath | `mix scrypath.install` (generates host schema/context) |
| others | generator planned |

**Rulestead recommendation: feature-walker architecture (sigra shape) + mountable macro for admin (accrue_admin shape).**

- `Rulestead.Install.Feature` behaviour with 5 callbacks: `enabled?/1`, `files/1`, `injections/1`, `migrations/1`, `post_instructions/2`.
- `@features = [Features.Core, Features.Admin, Features.Oban, Features.OpenTelemetry]`.
- `Rulestead.Install.Runner` orchestrates, allocates migration timestamps centrally via `Rulestead.Install.MigrationTimestamps.allocate/2`, overlays pre-existing on-disk timestamps for re-run idempotency.
- Template override seam: `priv/templates/rulestead.install/...` in host app's own priv dir wins over library's templates (sigra `Runner.find_template/1`).
- Features **must not reference each other** — `Features.Core` never mentions `Features.Admin`. `--no-admin` produces a compiling app with no orphan admin code.
- Mountable admin router: one-line `rulestead_admin "/flags"` macro in host router, with `session: {Rulestead.Admin.Router, :__session__, [session_keys, mount_path]}`. Dev-only routes behind compile-time `allow_live_reload: Mix.env() != :prod`.
- Idempotent reruns write `.rulestead_conflict_*` sidecars (mailglass pattern) instead of clobbering.

### 3.3 Host-app auth integration

| Project | Choice |
|---|---|
| sigra | Host-owned `Sigra.Admin.Policy` behaviour with `platform_admin?/1` + `admin_org_ids/1` |
| accrue | Auth adapter behaviour + sigra auto-detection |
| lockspire | `AccountResolver` behaviour as singular primary seam |
| mailglass | Planned: `Mailglass.Auth` adapter + sigra auto-detect |

**Rulestead recommendation: `Rulestead.ActorResolver` behaviour as the singular primary seam**, with auto-detection of sigra / accrue / mailglass / custom auth. Callbacks:

- `current_actor(conn_or_socket) :: {:ok, %Rulestead.Actor{}} | :anonymous`
- `enrich_traits(actor, required_traits) :: %Rulestead.Actor{}` (lazy trait hydration)
- `bucketing_key(actor, opts) :: String.t()` (stable identity for deterministic rollout, different from actor id when host needs cross-session stickiness)

`Rulestead.Admin.Policy` is a separate, narrower behaviour for admin-UI authorization — `platform_admin?/1`, `can_edit_flag?/2`, `can_engage_killswitch?/2`. Generated as a stub into `lib/<app>/rulestead_admin_policy.ex`. No default inference from signup order, email domain, or anything else hidden.

Host integration seam full doc → `rulestead-host-app-integration-seam.md`.

### 3.4 Optional dependencies

| Project | Pattern |
|---|---|
| All | `optional: true` in `mix.exs` deps + `Code.ensure_loaded?(Mod)` guard + `@compile {:no_warn_undefined, [Mod]}` in `elixirc_options` + `MyLib.OptionalDeps.Mod.available?/0` helper |

**Rulestead recommendation: adopt verbatim.** Rulestead's optional deps:

- `{:oban, "~> 2.21", optional: true}` — scheduled rollout advances, stale-flag alerts.
- `{:opentelemetry, "~> 1.0", optional: true}` — OTel bridge for telemetry events.
- `{:sigra, "~> 0.2", optional: true}` — auto-actor-resolver adapter.
- `{:mailglass, "~> 0.1", optional: true}` — auto-notify-operators adapter (flag stale alerts).
- `{:accrue, "~> 1.0", optional: true}` — billing-tier-aware audience auto-resolver.
- `{:phoenix_live_view, "~> 1.0", optional: true}` in core `rulestead`; hard dep in `rulestead_admin`.

### 3.5 Test fake vs Mox

| Project | Choice |
|---|---|
| mailglass | `Mailglass.Adapter.Fake` as the release-gate target |
| sigra | Mox-heavy |
| accrue | Fake processor + Mox for specific boundaries |

**Rulestead recommendation: Fake adapter + Mox for behaviour contracts.** `Rulestead.Fake` is the merge-blocking test target (in-memory flag store, deterministic bucketing, time-advanceable cache, trait-injectable actor resolver). Mox covers behaviour-contract verification where interaction order matters. Real-Postgres integration tests are advisory.

### 3.6 Append-only event ledger

| Project | Pattern |
|---|---|
| accrue | `accrue_events` append-only table |
| mailglass | `mailglass_events` + Postgres SQLSTATE 45A01 trigger on UPDATE/DELETE + partial unique on `idempotency_key` |
| threadline | Trigger-backed capture, no app-level insert path, PgBouncer-safe actor GUC bridge |

**Rulestead recommendation: adopt mailglass's shape with threadline's write-discipline.** `rulestead_events` table (see §4.3 schema), Postgres trigger raises on UPDATE/DELETE, partial unique index on `idempotency_key WHERE NOT NULL`, every mutation in `Ecto.Multi` that also writes the event row. Actor correlation via `set_config('rulestead.actor_ref', $1::text, true)` inside the transaction (PgBouncer transaction-pool-safe). Trigger **reads** the GUC via `current_setting(..., true)` (missing-ok); trigger **never writes** the GUC.

### 3.7 Polymorphic ownership

| Project | Pattern |
|---|---|
| mailglass | `owner_type VARCHAR + owner_id VARCHAR`, no FK, every adopter-facing aggregate |
| accrue | Same polymorphic shape |
| sigra | Real FKs to host `users` / `organizations` |

**Rulestead recommendation: polymorphic.** `rulestead_flags`, `rulestead_rulesets`, `rulestead_audiences` all carry `owner_type, owner_id, tenant_id` with no FK. Host chooses `"User"`, `"Organization"`, `"Team"`, `"Workspace"`, `"SingleTenant"` — rulestead doesn't care. `Rulestead.Tenancy.scope/2` normalizes per-host. Indexed `(owner_type, owner_id)` + `(tenant_id)` for query locality.

### 3.8 Ecto identifiers & timestamps

- **UUIDv7 binary_id PKs** everywhere (`@primary_key {:id, :binary_id, autogenerate: true}`, `@foreign_key_type :binary_id`). v7 is time-sortable for better index locality.
- **`timestamps(type: :utc_datetime_usec)`** — microsecond precision for audit-log ordering.
- **Migration convention**: `@primary_key false`; then `add :id, :binary_id, primary_key: true`. Comment on `@known_fields` module attribute so lattice_stripe-style drift checks can introspect.

### 3.9 Dialyzer

**Adopt split restore→build-if-miss→save PLT cache recipe** from accrue. Strict mode (`flags: [:error_handling, :extra_return, :missing_return]`). `plt_local_path: "priv/plts"`. Dialyzer as a required CI gate.

### 3.10 ExDoc landing page

Split `README.md` (GitHub-facing, onboarding-focused) from `guides/introduction/getting-started.md` (ExDoc-facing, concept-focused). README is the 60-second pitch; getting-started is the 15-minute walkthrough. Both linked from HexDocs.

---

## 4. Rulestead-specific translation

### 4.1 Public API surface (suggested v0.1 shape)

```elixir
# Core evaluation
Rulestead.enabled?(:new_checkout, context) :: boolean()
Rulestead.evaluate(:new_checkout, context) :: {:ok, %Rulestead.Result{}} | {:error, %Rulestead.EvaluationError{}}
Rulestead.evaluate!(:new_checkout, context) :: %Rulestead.Result{} | raise
Rulestead.get_boolean(:new_checkout, default :: boolean(), context) :: boolean()
Rulestead.get_string(:checkout_button_color, "blue", context) :: String.t()
Rulestead.get_json(:checkout_config, %{}, context) :: map()
Rulestead.get_variant(:checkout_experiment, context) :: atom() | nil
Rulestead.explain(:new_checkout, context) :: %Rulestead.Result{debug_trace: [...]}

# Context construction
Rulestead.Context.new(opts) :: %Rulestead.Context{}
Rulestead.Context.from_conn(conn) :: %Rulestead.Context{}   # Plug helper
Rulestead.Context.from_socket(socket) :: %Rulestead.Context{}   # LiveView helper
Rulestead.Context.from_job(job) :: %Rulestead.Context{}   # Oban helper

# Admin context (server-side only, requires Rulestead.Admin.Policy)
Rulestead.Flags.create_flag(attrs, actor) :: {:ok, flag} | {:error, changeset}
Rulestead.Rulesets.publish(flag, ruleset_attrs, actor) :: {:ok, ruleset} | {:error, changeset}
Rulestead.Rollouts.advance(flag, new_pct, actor, opts) :: {:ok, rollout} | {:error, ...}
Rulestead.KillSwitch.engage(flag, actor, reason) :: {:ok, flag}
Rulestead.Audit.timeline(subject, opts) :: [%Rulestead.Event{}]
```

### 4.2 Behaviours (extension seams — narrow, 1–3 callbacks each)

- `Rulestead.Store` — flag/ruleset/audience/rollout persistence. Default: `Rulestead.Store.Ecto`. Swap via config.
- `Rulestead.RuleEngine` — rule evaluation. Default: `Rulestead.RuleEngine.Default` (ordered first-match-wins over declared rule types: `:forced_value | :percentage_rollout | :variant | :segment_match`).
- `Rulestead.EvaluationCache` — per-node cache. Default: `Rulestead.EvaluationCache.ETS`. Alternates: `.PersistentTerm` (read-mostly, long-lived manifests), `.Redis` (shared across nodes for cold-start avoidance).
- `Rulestead.AuditStore` — audit event sink. Default: `Rulestead.AuditStore.Ecto` (writes to `rulestead_events`). Alternate: `.S3Append` for compliance-heavy adopters.
- `Rulestead.ActorResolver` — host-owned actor resolution (see §3.3). **Implemented by host**, no default.
- `Rulestead.Admin.Policy` — host-owned admin authorization (see §3.3). **Implemented by host**, stub generated.
- `Rulestead.Hooks` — before/after/error/finally lifecycle hooks (OpenFeature-inspired). For custom telemetry, analytics integration, PII scrubbing, local overrides.

All behaviours are documented in `api_stability.md` and have a `@moduledoc false` default adapter pair (lattice_stripe pattern).

### 4.3 Schemas (first-pass, multi-tenant-safe)

```elixir
schema "rulestead_flags" do
  field :key, :string                           # "new_checkout" (not a secret)
  field :description, :string
  field :flag_type, Ecto.Enum, values: [:release, :experiment, :kill_switch, :permission, :remote_config, :operational, :migration]
  field :value_type, Ecto.Enum, values: [:boolean, :string, :integer, :float, :json, :variant]
  field :default_value, :map
  field :variants, {:array, :map}, default: []  # [%{key: :control, value: %{}, weight: 0.5}]
  field :status, Ecto.Enum, values: [:draft, :active, :archived, :killswitched], default: :draft
  field :owner_type, :string                    # "User" | "Team" | "System"
  field :owner_id, :string
  field :tenant_id, :string                     # nil for SingleTenant
  field :expected_lifetime_days, :integer       # nil = permanent
  field :stale_at, :utc_datetime_usec           # computed; powers lifecycle view
  field :last_evaluated_at, :utc_datetime_usec
  field :lock_version, :integer, default: 1
  timestamps(type: :utc_datetime_usec)
end

schema "rulestead_rulesets" do
  belongs_to :flag, Rulestead.Flag
  field :version, :integer
  field :status, Ecto.Enum, values: [:draft, :active, :retired]
  field :rules, {:array, :map}              # JSONB: ordered list of %{conditions, strategy, value, reason}
  field :salt, :string                      # bucketing salt; migration path if algo changes
  field :published_by, :string
  field :published_at, :utc_datetime_usec
  timestamps(type: :utc_datetime_usec)
end
# Partial unique index on (flag_id) WHERE status = 'active' — exactly one active ruleset per flag.

schema "rulestead_audiences" do
  field :key, :string                       # "enterprise_eu" (not a secret)
  field :description, :string
  field :definition, :map                   # trait-based predicate OR explicit_list
  field :owner_type, :string
  field :owner_id, :string
  field :tenant_id, :string
  timestamps(type: :utc_datetime_usec)
end

schema "rulestead_rollouts" do
  belongs_to :flag, Rulestead.Flag
  belongs_to :ruleset, Rulestead.Ruleset
  field :percentage, :decimal, precision: 5, scale: 2
  field :bucketing_key, :string             # e.g. "actor.id" or "actor.tenant_id"
  field :status, Ecto.Enum, values: [:held, :advancing, :complete, :rolled_back]
  field :schedule, :map                     # optional: %{at, steps: [%{pct, at}]}
  timestamps(type: :utc_datetime_usec)
end

schema "rulestead_events" do
  field :type, :string                      # "flag.created" | "ruleset.published" | "rollout.advanced" | "killswitch.engaged" | ...
  field :subject_type, :string              # "Flag" | "Ruleset" | "Audience" | "Rollout"
  field :subject_id, :binary_id
  field :actor_type, :string                # "User" | "System" | "SDK" | "CLI"
  field :actor_id, :string
  field :tenant_id, :string
  field :result, Ecto.Enum, values: [:ok, :denied, :error]
  field :payload, :map                      # JSONB: before/after diff, redacted
  field :correlation_id, :string
  field :idempotency_key, :string
  field :occurred_at, :utc_datetime_usec
  timestamps(type: :utc_datetime_usec, updated_at: false)
end
# Partial unique on (idempotency_key) WHERE idempotency_key IS NOT NULL.
# Trigger BEFORE UPDATE OR DELETE raises SQLSTATE 45A01.
# Indexed on (subject_type, subject_id, occurred_at DESC), (tenant_id, occurred_at DESC).
```

Full Ecto rules → `rulestead-host-app-integration-seam.md` §schemas.

### 4.4 Mountable admin LiveView (sibling `rulestead_admin` package)

- One-line host mount: `rulestead_admin "/flags"` in host router.
- `session: {Rulestead.Admin.Router, :__session__, [session_keys, mount_path]}` threads brand, theme, CSP nonce through LiveView session payload.
- `on_mount` composition: `{<app>_web.UserAuth, :ensure_authenticated}` (host) + `{Rulestead.LiveView.AdminScope, [policy: <app>.RulesteadAdminPolicy]}` (library).
- Dev-only routes (`/dev/eval-playground`, `/dev/simulate`) behind compile-time `allow_live_reload: Mix.env() != :prod`.
- Core LiveViews: `FlagIndexLive`, `FlagShowLive` (tabs: Overview / Rulesets / Rollout / Audiences / Timeline / Evaluations), `RulesetEditorLive`, `RolloutControlLive`, `AudienceIndexLive`, `AudienceShowLive`, `ExplainLive` (answer "why did flag X return Y for actor Z?"), `SimulateLive` (preview proposed ruleset change), `AuditTimelineLive`, `KillSwitchPanelLive`, `SettingsLive`.

Full admin UX → `rulestead-admin-ux-and-operator-ia.md`.

### 4.5 Manifest sync plug (flag-as-code adopters)

Rulestead analog of mailglass's webhook plug: `Rulestead.Router.rulestead_manifest_webhook "/sync", source: :github`. Raw-body caching for signature verification. Normalizes any inbound change source (GitHub webhook, GitLab, S3 upload, CLI push) into `%Rulestead.ChangeEvent{}` before hitting the admin mutation path — so audit/event-ledger/explain all work identically regardless of who/what changed a flag.

Full manifest sync → covered in the `rulestead-host-app-integration-seam.md` guide.

### 4.6 Telemetry events (concrete catalog)

See full table in `rulestead-telemetry-observability-and-audit.md`. Highest-value events:

- `[:rulestead, :eval, :decide, :start | :stop | :exception]` — every evaluation.
- `[:rulestead, :eval, :cache, :miss | :invalidate]` — cache behavior.
- `[:rulestead, :admin, :flag, :created | :updated | :archived]`
- `[:rulestead, :admin, :ruleset, :published | :reverted | :simulated]`
- `[:rulestead, :admin, :rollout, :advanced | :held | :rolled_back]`
- `[:rulestead, :admin, :killswitch, :engaged | :released]`
- `[:rulestead, :ops, :import, :applied]`, `[:rulestead, :ops, :export, :generated]`

Operators wire `[:rulestead, :ops, *]` and `[:rulestead, :admin, :killswitch, *]` for paging alerts. Dashboards wire the full tree.

### 4.7 Hooks for extensibility

OpenFeature-inspired lifecycle hooks. `Rulestead.Hooks` behaviour with 4 callbacks:

- `before_evaluation(context) :: {:ok, context} | {:error, reason}`
- `after_evaluation(context, result) :: :ok`
- `on_error(context, error) :: :ok`
- `finally(context, result_or_error) :: :ok`

Use cases: telemetry, tracing (OTel bridge), impression logging (downsampled), custom validations, local dev overrides, analytics-vendor integration, PII scrubbing, test-mode forcing.

---

## 5. Project skeleton — the v0.1 starter shape

```
rulestead/                                # repo root
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── release-parity-drift.md        # scrypath-style rolling-issue template
│   ├── workflows/
│   │   ├── ci.yml                         # lint + test matrix + integration + installer-goldens
│   │   ├── release-please.yml             # release-please + publish + post-publish verify
│   │   ├── publish-hex.yml                # workflow_dispatch manual recovery
│   │   ├── verify-published-release.yml   # daily drift cron
│   │   ├── pr-title.yml                   # conventional-commit PR title lint
│   │   ├── dependabot-automerge.yml       # patch-only auto-merge
│   │   └── playwright-github-pages.yml    # (later) admin demo site
│   └── dependabot.yml
├── .formatter.exs                         # minimal, deps-only
├── .credo.exs                             # requires: project-local checks
├── .tool-versions                         # elixir + erlang + node pins
├── .gitignore
├── AGENTS.md                              # LLM entry point (references CLAUDE.md blocks)
├── CLAUDE.md                              # GSD fenced blocks; mirrors AGENTS.md
├── CONVENTIONS.md                         # discipline layer — flag determinism, tenancy scoping
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md                        # toolchain floor, local Postgres docker, CI commands
├── MAINTAINING.md                         # release runbook, branch protection strings
├── SECURITY.md                            # threat model summary + disclosure policy
├── LICENSE                                # MIT
├── README.md                              # 60-sec pitch, badges, install, quick example
├── CHANGELOG.md                           # keep-a-changelog, release-please-owned
├── release-please-config.json             # linked-versions for rulestead + rulestead_admin
├── .release-please-manifest.json
├── docker-compose.yml                     # local Postgres
├── scripts/
│   ├── ci/
│   │   ├── install-smoke.sh
│   │   ├── install-matrix-local.sh
│   │   ├── installer-milestone-audit.sh
│   │   ├── verify-release-publish.sh
│   │   ├── verify-release-parity.sh
│   │   └── admin-artifact-bundle-contract.sh
│   ├── maintainers/
│   │   └── planning-audit-hygiene.sh
│   └── uat/
│       ├── up.sh
│       └── down.sh
├── prompts/                               # LLM context (this folder)
├── .planning/                             # GSD artifacts
├── guides/
│   ├── introduction/
│   │   ├── installation.md
│   │   ├── getting-started.md
│   │   └── upgrading.md
│   ├── flows/
│   │   ├── evaluation.md
│   │   ├── rulesets.md
│   │   ├── rollout.md
│   │   ├── admin-ui.md
│   │   ├── sdk.md
│   │   ├── manifest-sync.md
│   │   ├── multi-tenant.md
│   │   ├── audit.md
│   │   └── extending-rulestead.md
│   ├── recipes/
│   │   ├── testing.md
│   │   ├── telemetry.md
│   │   ├── ecto-conventions.md
│   │   ├── sigra-integration.md
│   │   ├── mailglass-integration.md
│   │   ├── accrue-integration.md
│   │   ├── oban-background-rollouts.md
│   │   └── deployment.md
│   ├── api_stability.md
│   └── cheatsheet.cheatmd
├── lib/
│   ├── rulestead.ex                       # public root module
│   ├── rulestead/
│   │   ├── application.ex                 # supervision tree
│   │   ├── config.ex                      # NimbleOptions schema + :persistent_term cache
│   │   ├── context.ex                     # %Rulestead.Context{}
│   │   ├── result.ex                      # %Rulestead.Result{}
│   │   ├── error.ex                       # error struct hierarchy
│   │   ├── actor.ex                       # %Rulestead.Actor{}
│   │   ├── telemetry.ex                   # span wrapper + event catalog
│   │   ├── tenancy.ex                     # behaviour + helpers
│   │   ├── tenancy/
│   │   │   └── single_tenant.ex           # default no-op resolver
│   │   ├── actor_resolver.ex              # behaviour
│   │   ├── store.ex                       # behaviour
│   │   ├── store/
│   │   │   └── ecto.ex                    # @moduledoc false default
│   │   ├── rule_engine.ex                 # behaviour
│   │   ├── rule_engine/
│   │   │   └── default.ex                 # @moduledoc false default
│   │   ├── evaluation_cache.ex            # behaviour
│   │   ├── evaluation_cache/
│   │   │   ├── ets.ex                     # @moduledoc false default
│   │   │   └── persistent_term.ex
│   │   ├── audit_store.ex                 # behaviour
│   │   ├── audit_store/
│   │   │   └── ecto.ex                    # @moduledoc false default
│   │   ├── hooks.ex                       # behaviour
│   │   ├── bucket.ex                      # deterministic hashing
│   │   ├── flags.ex                       # context fn: create, update, archive, killswitch
│   │   ├── flag.ex                        # schema
│   │   ├── rulesets.ex                    # context fn
│   │   ├── ruleset.ex                     # schema
│   │   ├── audiences.ex                   # context fn
│   │   ├── audience.ex                    # schema
│   │   ├── rollouts.ex                    # context fn
│   │   ├── rollout.ex                     # schema
│   │   ├── evaluations.ex                 # context fn: evaluate/3, explain/2, simulate/2
│   │   ├── audit.ex                       # context fn: timeline/2, export/2
│   │   ├── event.ex                       # schema
│   │   ├── repo.ex                        # transact/1 facade
│   │   ├── idempotency_key.ex             # sanitized keys
│   │   ├── fake.ex                        # in-memory test adapter
│   │   ├── optional_deps/
│   │   │   ├── oban.ex
│   │   │   ├── open_telemetry.ex
│   │   │   ├── sigra.ex
│   │   │   ├── mailglass.ex
│   │   │   └── accrue.ex
│   │   ├── credo/                         # custom Credo checks
│   │   │   ├── no_eval_outside_context.ex
│   │   │   ├── no_unscoped_tenant_query_in_lib.ex
│   │   │   ├── no_raw_traits_in_telemetry_meta.ex
│   │   │   ├── no_mutation_outside_multi.ex
│   │   │   └── no_socket_captured_in_async.ex
│   │   ├── plug.ex                        # Rulestead.Plug — context from conn
│   │   ├── live_view/
│   │   │   ├── actor_scope.ex             # on_mount hook
│   │   │   └── admin_scope.ex             # on_mount hook (in rulestead_admin)
│   │   ├── oban/
│   │   │   ├── tenancy_middleware.ex
│   │   │   └── rollout_advance_worker.ex
│   │   ├── install/
│   │   │   ├── feature.ex                 # behaviour
│   │   │   ├── runner.ex
│   │   │   ├── injection.ex
│   │   │   ├── injector.ex
│   │   │   ├── migration_timestamps.ex
│   │   │   ├── report.ex
│   │   │   └── features/
│   │   │       ├── core.ex
│   │   │       ├── admin.ex
│   │   │       ├── oban.ex
│   │   │       └── open_telemetry.ex
│   │   └── mix/
│   │       └── tasks/
│   │           ├── rulestead.install.ex
│   │           ├── rulestead.doctor.ex    # config + connectivity sanity check
│   │           ├── verify.workspace_clean.ex
│   │           ├── verify.release_publish.ex
│   │           ├── verify.release_parity.ex
│   │           ├── rulestead.check_drift.ex  # optional: flag-as-code manifest drift
│   │           └── rulestead.export.ex
├── priv/
│   ├── repo/migrations/                   # library-owned migrations (installable via mix task)
│   └── templates/rulestead.install/
├── test/
│   ├── test_helper.exs                    # Ecto.Sandbox, Mox start, Fake setup
│   ├── support/
│   │   ├── data_case.ex
│   │   ├── conn_case.ex
│   │   ├── install_fixture.ex             # sigra-style setup_tmp_app/1
│   │   └── flag_helpers.ex                # with_flag/3, put_flag/3, seed_bucket/2
│   ├── fixtures/install_golden/
│   │   ├── tree/                          # byte-identical expected output
│   │   └── STDOUT.txt
│   ├── rulestead/                         # unit tests per module
│   ├── rulestead_web/                     # Plug + LiveView tests
│   └── example/                           # test/example/ Phoenix host subproject
│       ├── mix.exs
│       ├── lib/
│       ├── priv/
│       └── priv/playwright/               # Playwright suite
└── rulestead_admin/                       # sibling Hex package
    ├── mix.exs                            # depends on path: "../rulestead" in dev; "~> @version" in publish
    ├── .formatter.exs
    ├── CHANGELOG.md
    ├── README.md
    ├── lib/
    │   └── rulestead_admin/
    │       ├── router.ex                  # defmacro rulestead_admin(path, opts)
    │       ├── endpoint.ex                # test-only
    │       ├── layouts.ex
    │       ├── assets.ex                  # hashed CSS/JS serving
    │       ├── live/
    │       │   ├── flag_index_live.ex
    │       │   ├── flag_show_live.ex
    │       │   ├── ruleset_editor_live.ex
    │       │   ├── rollout_control_live.ex
    │       │   ├── audience_index_live.ex
    │       │   ├── audience_show_live.ex
    │       │   ├── explain_live.ex
    │       │   ├── simulate_live.ex
    │       │   ├── audit_timeline_live.ex
    │       │   ├── killswitch_panel_live.ex
    │       │   └── settings_live.ex
    │       └── components/
    ├── priv/static/                       # prebuilt CSS/JS, shipped in Hex tarball
    ├── assets/
    │   ├── package.json
    │   ├── js/
    │   └── css/
    └── test/
```

---

## 6. Anti-patterns / gotchas (paid for in someone's commit history)

Each item here was paid for in another repo's git log. Don't repay them.

1. **Don't make DB reads the default runtime evaluation path.** Eval must hit ETS (or persistent_term), not `Repo.all`. Store writes populate the cache via PubSub; evaluation never joins.
2. **Don't use `percentage of time` for user-facing rollout.** Same user gets different answers across calls. Default to sticky actor-based bucketing. Label time-based as advanced (dark launches / sampling / chaos only).
3. **Don't skip the `targeting_key` requirement for stickiness-capable rules.** Missing `targeting_key` → random per request. Warn loudly; optionally fail-closed in strict mode.
4. **Don't raise from telemetry handlers.** Handlers tolerate any reason, any meta. Document in event catalog.
5. **Don't put secrets / PII / raw payloads in telemetry meta or Logger.metadata.** Counts / digests / IDs / latencies only. Custom Credo check enforces.
6. **Don't auto-include the whole repo in `package.files`.** Whitelist explicitly. Comment the forbidden paths.
7. **Don't include `test/example/` or `prompts/` or `.planning/` in Hex tarballs.** Accidentally shipping them doubles package size and leaks internal docs.
8. **Don't let flags be created without owner + expected_lifetime.** Stale-flag debt is real. Require metadata at creation.
9. **Don't mutate/delete `rulestead_events`.** Postgres trigger raises SQLSTATE 45A01. This is a feature, not a bug.
10. **Don't mix `.planning/` state into library commits.** Path filters in CI exclude `.planning/` / `prompts/` / `guides/` from triggering lint/test; but never commit `.planning/state-manifest.json` — it's ephemeral.
11. **Don't rely on undocumented process dictionary magic everywhere.** Explicit context structs first; process-dict is a convenience layer only.
12. **Don't mix host-app auth assumptions deep into the core library.** Use the `Rulestead.ActorResolver` + `Rulestead.Admin.Policy` seams. No defaults inferred from signup order / email domain / anything hidden.
13. **Don't skip `@compile {:no_warn_undefined, [...]}` for optional deps.** Downstream `mix compile --warnings-as-errors` will break. Test the no-optional-deps path in CI: `mix compile --no-optional-deps --warnings-as-errors`.
14. **Don't let `test_load_filters` drift when you add a `test/example/` subproject.** Mix 1.19 will emit duplicate-compilation warnings; the golden fixture tree will pollute the main test suite.
15. **Don't capture `socket` in `start_async` / `assign_async` / `stream_async` closures.** Reconnect-safe async patterns only. Custom Credo check catches this.
16. **Don't let `REQUIREMENTS.md` drift from `ROADMAP.md`.** Milestone-audit gates catch it post-hoc; fix during phase close, not "next session."
17. **Don't ship an evaluator that joins multiple tables per eval.** Flag, ruleset, audience, rollout all load from a single in-memory snapshot; Postgres is only authoring truth.
18. **Don't hand-write the `@version` in two places.** Module attribute in `mix.exs` is the single source; `docs.source_ref`, `release-please-manifest.json`, READMEs reference it.
19. **Don't `mix hex.publish` locally on a whim.** Always through release-please or the manual-dispatch `publish-hex.yml` workflow — both run `verify.workspace_clean` + dry-run first.
20. **Don't treat the admin LiveView as the only write path.** HTTP API, CLI, SDK push, manifest-sync webhook — all four normalize into the same `%Rulestead.ChangeEvent{}` shape and all four emit audit rows. One source of truth for "what changed."

---

## 7. The opinionated GSD seed plan

### 7.1 Milestone plan

| Milestone | Phases | Theme | Req prefix |
|---|---|---|---|
| v0.1 | 1–6 | **Core eval foundation** — snapshot storage, deterministic bucketing, boolean + multivariate, Plug/LiveView/Oban context builders, telemetry spans, Fake adapter, first golden-path guide | `EVAL-NN` |
| v0.2 | 7–11 | **Ruleset domain** — ordered-rules engine, segments/audiences, first-match-wins precedence, rule editor-ready data shape, `explain/2`, simulate pure function | `RULE-NN` |
| v0.3 | 12–17 | **Admin LiveView v0** — `rulestead_admin` sibling package, mountable macro, FlagIndex + FlagShow + RulesetEditor + AuditTimeline, installer feature for admin, golden-diff test | `ADMIN-NN` |
| v0.4 | 18–21 | **Audiences + cohorts** — trait-based predicates, explicit-list audiences, preview membership count, AudienceIndex + AudienceShow LiveViews | `AUD-NN` |
| v0.5 | 22–26 | **Rollout mechanics + kill switch** — stepped rollout, scheduled advance (Oban), emergency kill, RolloutControl LiveView, KillSwitchPanel LiveView | `ROLL-NN` |
| v0.6 | 27–31 | **Audit + explain + simulate** — append-only event ledger, immutability trigger, ExplainLive, SimulateLive (stream_async sample deltas), rolling audit-drift cron | `INTRO-NN` |
| v0.7 | 32–36 | **SDK + HTTP eval API + manifest sync** — `GET /rulestead/evaluate/:flag_key`, ETag-based manifest sync, GitHub/GitLab webhook manifest import, CLI push | `SDK-NN` |
| v0.8 | 37–40 | **Multi-tenancy hardening** — `Rulestead.Tenancy` behaviour + SingleTenant default, org-scoped admin policy, per-tenant bucketing keys, tenancy middleware for Oban | `TENANT-NN` |
| v0.9 | 41–44 | **Integrations** — sigra actor-resolver adapter, mailglass operator-alert adapter, accrue billing-tier audience adapter, Oban stale-flag cleanup job | `INT-NN` |
| v0.10 | 45–49 | **Docs + trust spine** — full guides, api_stability.md, release-parity cron green for 14 consecutive days, doc-contract tests, browser UAT lane on GitHub Pages, three-persona launch bar | `DOC-NN`, `PROOF-NN` |
| v1.0 | 50–54 | **Stability** — breaking-change audit, compat matrix, upgrade guide from 0.x, conformance test vectors (bucketing parity with anchor vectors), full threat-model review | `STAB-NN` |

### 7.2 Per-phase artifact checklist

- `NN-CONTEXT.md` — why this phase exists, inputs from prior phase, open questions
- `NN-RESEARCH.md` — evidence gathered (prior art, alternatives considered)
- `NN-DISCUSSION-LOG.md` — Q&A during planning
- `NN-PATTERNS.md` — reusable patterns surfaced (feed back into CONVENTIONS.md if load-bearing)
- `NN-XX-PLAN.md` — per-sub-plan detail
- `NN-XX-SUMMARY.md` — post-execute summary for each sub-plan
- `NN-VERIFICATION.md` — how this phase's work was verified (tests passing, golden diff green, etc.)
- `NN-VALIDATION.md` — Nyquist validation (does the work hold up under edge cases?)
- `NN-REVIEW.md` — code-review output
- `NN-UI-SPEC.md` — for LiveView / admin phases
- `NN-HUMAN-UAT.md` — human walkthrough checklist
- `mix verify.phase<NN>` alias — CI calls this, never a kitchen-sink verifier

### 7.3 Backlog discipline (A/B/C/D tiers)

- **A — merge-blocking**: must ship before milestone archive.
- **B — strong-want**: can defer to next milestone with owner + ETA + trigger-to-pull-in.
- **C — nice-to-have**: deferred into `.planning/seeds/` with explicit auto-promote trigger.
- **D — won't-do**: moved to PROJECT.md "Out of Scope" with one-line reason.

No silent deferrals. Every deferred item has owner + trigger-to-reopen.

---

## 8. Source map — where to look in each prior repo

| Pattern | Best reference |
|---|---|
| Sibling-package release-please config | `accrue/release-please-config.json` + `accrue/release-please-manifest.json` |
| `ACCRUE_ADMIN_HEX_RELEASE` env-swap | `accrue_admin/mix.exs` (`accrue_dep/0` switch) |
| Lockstep fallback in release-please.yml | `accrue/.github/workflows/release-please.yml` (`write_release_outputs` bash) |
| Post-publish verify trio | `scrypath/lib/mix/tasks/verify.{workspace_clean,release_publish,release_parity}.ex` |
| Daily drift cron | `scrypath/.github/workflows/verify-published-release.yml` |
| Rolling GitHub issue | `scrypath/.github/ISSUE_TEMPLATE/release-parity-drift.md` + `JasonEtco/create-an-issue@v2` step |
| api_stability.md | `lattice_stripe/guides/api_stability.md` |
| Behaviour + `@moduledoc false` default adapter pair | `lattice_stripe/lib/lattice_stripe/retry_strategy.ex` (+ `.Default`) |
| Stripe-spec drift monitor | `lattice_stripe/.github/workflows/drift.yml` + `lib/lattice_stripe/drift.ex` |
| Dependabot patch-only auto-merge | `lattice_stripe/.github/workflows/dependabot-automerge.yml` |
| PR title lint | `lattice_stripe/.github/workflows/pr-title.yml` |
| Mountable LiveView admin — paste-scopes-into-host-router | `sigra/priv/templates/sigra.install/admin/router_injection.ex` + `sigra/lib/sigra/admin/live/*.ex` |
| Mountable LiveView admin — macro-in-host-router | `accrue_admin/lib/accrue_admin/router.ex` (`defmacro accrue_admin/2`) |
| Feature-walker installer | `sigra/lib/sigra/install/feature.ex` + `runner.ex` + `mix/tasks/sigra.install.ex` |
| Golden-diff installer test | `sigra/test/sigra/install/golden_diff_test.exs` + `test/fixtures/install_golden/` |
| Playwright-on-GitHub-Pages | `sigra/.github/workflows/playwright-github-pages.yml` + `scripts/ci/{assemble,ensure}-*.sh` |
| Host-owned admin policy behaviour | `sigra/lib/sigra/admin/policy.ex` |
| 3-folder guides split | `sigra/guides/{introduction,flows,recipes}/` + `sigra/mix.exs` `groups_for_extras` |
| CONVENTIONS.md discipline layer | `sigra/CONVENTIONS.md` |
| Custom Credo checks | `sigra/lib/sigra/credo/no_unscoped_org_query_in_lib.ex` |
| Append-only event ledger + immutability trigger | `mailglass/priv/repo/migrations/*_mailglass_events.exs` + `lib/mailglass/events.ex` |
| Polymorphic ownership (`owner_type + owner_id`) | `mailglass/lib/mailglass/*.ex` schemas |
| Optional-deps gateway pattern | `mailglass/lib/mailglass/optional_deps/*.ex` |
| Fake-adapter-as-release-gate | `mailglass/lib/mailglass/adapter/fake.ex` + test mentions |
| Tenancy behaviour + SingleTenant default | `mailglass/lib/mailglass/tenancy.ex` + `tenancy/single_tenant.ex` |
| Host-app integration seam doc shape | `lockspire/prompts/lockspire-host-app-integration-seam.md` |
| Operator admin IA + workflows doc shape | `lockspire/prompts/lockspire-operator-admin-ia-and-workflows.md` |
| LiveView LLM-ready build rules (15) | `lockspire/prompts/lockspire-operator-ux-liveview.md` §18 |
| Ecto-in-production rules | `lockspire/prompts/lockspire-ecto-token-and-audit-model.md` |
| Domain-language field guide | `lockspire/prompts/lockspire-auth-domain-language-field-guide.md` |
| Market-gap / positioning doc | `lockspire/prompts/lockspire-market-gap-and-positioning.md` |
| Trigger-backed capture, no app-level insert | `threadline/lib/threadline/capture/trigger_sql.ex` + `audit_change.ex` |
| PgBouncer-safe actor GUC bridge | `threadline/lib/threadline/plug.ex` + `trigger_sql.ex` |
| Three-layer separation (capture/semantics/exploration) | `threadline/lib/threadline/{capture,semantics}/*.ex` |
| `verify.*` alias naming discipline | `threadline/mix.exs` aliases block |
| MILESTONE-AUDIT.md YAML frontmatter template | `scrypath/.planning/v1.0-MILESTONE-AUDIT.md` |
| Per-phase artifact set | any `scrypath/.planning/phases/NN-*/` or `accrue/.planning/phases/NN-*/` |

---

## 9. TL;DR — the 10 must-port wins, ranked

1. **Error model triangle** — `Rulestead.Error` root + typed sub-errors + closed `:type` atom + `:cause` excluded from `Jason.Encoder`. Lock on day 1.
2. **Telemetry span + 4-level event names + `:start/:stop/:exception` trilogy + no-PII rule**. Events are API surface.
3. **Append-only event ledger with Postgres immutability trigger + `Ecto.Multi`-wrapped mutations**. Every admin change writes an event row in the same transaction. Nothing mutates without audit.
4. **Post-publish verification spine** — `verify.workspace_clean` + `verify.release_publish` + `verify.release_parity` + daily drift cron + rolling GitHub issue. Three exit codes.
5. **`api_stability.md` as first-class contract** — public surface enumerated, non-public explicitly named, pluggable behaviours called out.
6. **Sibling packages** — `rulestead` + `rulestead_admin` with linked-versions release-please. Admin can iterate without re-publishing eval.
7. **Feature-walker installer + golden-diff test fixture** — byte-identical expected tree + STDOUT capture + paired idempotency test. Path-gated CI job. Templates override-able by host.
8. **Mountable admin LiveView with one-line macro** — `rulestead_admin "/flags"` in host router, session threading via `{Router, :__session__, ...}`, host-owned `Rulestead.Admin.Policy` behaviour for authz.
9. **Conventional Commits + Release Please + PR title lint + Dependabot patch-only auto-merge** — release automation that degrades gracefully, manual-dispatch fallback workflow for the day automation breaks.
10. **GSD discipline** — milestone-first `PROJECT.md`, per-phase artifact set, `verify.phase<NN>` aliases, MILESTONE-AUDIT.md with YAML frontmatter, seeds as auto-promoting parking lot, A/B/C/D backlog tiers, no silent deferrals.

These are not opinions. They are **7 different OSS Elixir libs, shipped to Hex or nearly so, converging on the same answers.** The DNA is the convergence.

---

## 10. Topical deep-dive docs in this prompts folder

When a phase needs deeper context, load the relevant topical doc:

- `rulestead-domain-language-field-guide.md` — nouns, verbs, events, canonical vocabulary, anti-terms. **Read first** — every other doc references these names.
- `rulestead-host-app-integration-seam.md` — owns/host-owns matrix, `Rulestead.ActorResolver` primary seam, generator philosophy, UI boundary.
- `rulestead-release-engineering-and-ci.md` — workflow-by-workflow reference, caching recipe, Postgres service block, secrets posture, release-please config.
- `rulestead-testing-and-e2e-strategy.md` — ExUnit layout, Fake adapter, Mox for behaviours, golden-diff installer test, StreamData property tests, Playwright host-app smoke.
- `rulestead-admin-ux-and-operator-ia.md` — sibling admin package layout, per-screen expectations, explain/simulate/timeline trio, LiveView LLM-ready rules.
- `rulestead-telemetry-observability-and-audit.md` — full event catalog, audit ledger schema, OTel bridge, redaction rules, debug surfaces.
- `rulestead-security-privacy-and-threat-model.md` — STRIDE pass, threat surfaces by endpoint, release-blocking security checks, non-goals for v1.
- `rulestead-personas-jtbd-and-onboarding.md` — 6 personas, golden paths, 15-minute local-demo acceptance.

Anchor docs (hand-written by the human, not generated):

- `elixir_feature_flags_research_brief.md` — the master 1720-line research brief on the feature-flags product space. Source of truth for product direction.
- `rulestead-brand-book.md` — voice, tone, messaging, color, typography, visual metaphors.
- `The 2026 Phoenix-Elixir ecosystem map for senior engineers.md` — current Elixir/Phoenix ecosystem baseline.

Canonical deep research (cross-project, shared verbatim across all Jon's libs):

- `elixir-best-practices-deep-research.md`
- `ecto-best-practices-deep-research.md`
- `phoenix-best-practices-deep-research.md`
- `phoenix-live-view-best-practices-deep-research.md`
- `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `elixir-opensource-libs-best-practices-deep-research.md`
- `elixir-oss-lib-ci-cd-best-practices-deep-research.md`

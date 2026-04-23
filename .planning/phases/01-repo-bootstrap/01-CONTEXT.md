# Phase 1: Repo Bootstrap, CI, Release Engineering Foundation — Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Research mode:** 4 parallel subagents across 6 gray areas + ecosystem survey (accrue, mailglass, sigra, Oban, Phoenix, Ecto, Tesla, Bandit, FunWithFlags, Flipper, Unleash, Flipt, GrowthBook, Flagsmith)

<domain>
## Phase Boundary

**Goal:** Working sibling-package skeleton (`rulestead` + `rulestead_admin`) with CI lanes green, linked-versions release-please configured, and documentation scaffolding in place. No evaluation logic yet — this is the foundation every subsequent phase builds on.

**In scope:**
- Repo structure (sibling-package monorepo with root `.github/`, docs, scripts)
- `.github/workflows/` (7 workflow files, see decisions)
- `mix.exs` pair with linked-versions release-please config
- Hex package metadata, `package.files` whitelist, MIT license
- `.formatter.exs`, `.credo.exs` (strict, custom checks deferred to Phase 7)
- `.tool-versions` pinning strict Elixir/OTP versions
- ExUnit test scaffolding (both packages compile + test green on empty skeleton)
- Root docs: README (real), CHANGELOG (Keep-a-Changelog seed), LICENSE (MIT), CONTRIBUTING (full), CODE_OF_CONDUCT (Contributor Covenant 2.1), SECURITY (full), MAINTAINING (full — release runbook + branch protection), CLAUDE.md, AGENTS.md
- Guides IA scaffolding (minimal stubs so ExDoc `mix docs --warnings-as-errors` green; real writing deferred to Phase 8 or to phase that ships the feature)
- `scripts/ci/*.sh` skeletons for non-trivial CI steps

**Out of scope (explicitly deferred):**
- Installer code, `mix rulestead.install` (Phase 5)
- `installer_path_gate` / `installer_golden` CI jobs (Phase 5)
- `verify-published-release.yml` daily drift cron (Phase 8 — added in same PR as first Hex publish)
- `CONVENTIONS.md`, `guides/cheatsheet.cheatmd`, `guides/api_stability.md`, `guides/flows/extending-rulestead.md` (Phase 8 — document locked public surface)
- Custom Credo checks (Phase 7)
- Any library code — schemas, evaluator, admin UI, telemetry (Phases 2–7)
- Merging any release-please PR (deferred to Phase 8; PR stays open and advisory during Phases 1–7)

</domain>

<decisions>
## Implementation Decisions

### D-01: Monorepo Layout — True Sibling Directories from Day 1

Two sibling Mix projects from commit 1:

```
rulestead/                          # repo root
├── .github/                        # workflows + issue templates (monorepo-level)
├── .tool-versions                  # shared
├── .formatter.exs                  # shared (root orchestrator only imports :phoenix, :ecto, :phoenix_live_view, :plug)
├── .credo.exs                      # shared (strict mode)
├── CLAUDE.md, AGENTS.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, MAINTAINING.md, LICENSE, README.md
├── CHANGELOG.md                    # NOT at root — each sibling has its own (see D-02)
├── release-please-config.json      # linked-versions manifest (D-02)
├── .release-please-manifest.json
├── docker-compose.yml              # local Postgres
├── scripts/ci/*.sh
├── prompts/                        # LLM context (already exists)
├── .planning/                      # GSD artifacts (already exists)
├── guides/                         # unified guides for both packages (ExDoc consumes from rulestead/mix.exs)
├── rulestead/                      # core package
│   ├── mix.exs                     # own @version attribute, own package.files, own deps
│   ├── lib/
│   ├── priv/
│   ├── test/
│   ├── CHANGELOG.md                # package-specific, release-please-owned
│   └── .formatter.exs              # minimal, imports :rulestead after Phase 1 formatter lands
└── rulestead_admin/                # admin LiveView package
    ├── mix.exs                     # own @version (lockstep with core via linked-versions), env-swap dep on core
    ├── lib/rulestead_admin.ex      # @moduledoc false skeleton
    ├── lib/rulestead_admin/router.ex  # stub rulestead_admin/2 macro that raises "v0.1.0+ only"
    ├── priv/
    ├── test/
    └── CHANGELOG.md                # package-specific, release-please-owned
```

**Rationale:**
- **Matches PROJECT.md key decision verbatim** ("Sibling packages from day 1 with linked-versions release-please").
- **Mirrors accrue's shipped pattern** (same author, already shipped this exact shape at v1.0+; `accrue_admin-v0.1.2` is currently latest tag). Rulestead is the second iteration, not the first.
- **Zero layout migration later** — Phase 1 builds the exact shape Phase 8 releases.
- Engineering DNA §5 starter skeleton shows single-`lib/`, but that was an ambiguous sketch; PROJECT.md + ROADMAP Phase 1 scope are the authoritative later decision.
- **Rejected alternatives:** single-package-then-split (forces mid-milestone refactor of `package.files`, tag namespace, CHANGELOG paths, every import path); Mix umbrella (not used by any analogous Elixir lib — Oban+oban_web, ash+ash_admin, phoenix+phoenix_live_dashboard all use separate/sibling repos, never umbrella).

### D-02: Release-Please Config — Linked-Versions Multi-Package from Day 1

`release-please-config.json` shape:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-component-in-tag": true,
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "plugins": [
    {"type": "linked-versions", "groupName": "rulestead-monorepo",
     "components": ["rulestead", "rulestead_admin"]}
  ],
  "packages": {
    "rulestead":       {"component": "rulestead",       "release-type": "elixir", "package-name": "rulestead",       "changelog-path": "rulestead/CHANGELOG.md",       "include-component-in-tag": true},
    "rulestead_admin": {"component": "rulestead_admin", "release-type": "elixir", "package-name": "rulestead_admin", "changelog-path": "rulestead_admin/CHANGELOG.md", "include-component-in-tag": true}
  }
}
```

Tags will be: `rulestead-v0.1.0` and `rulestead_admin-v0.1.0`.

**Port accrue's `release-please.yml` verbatim**, including the **lockstep-fallback bash block** that re-emits `release_created=true` for the admin package when both manifest versions match (handles the "admin has no qualifying commits since last release" edge case — release-please upstream bug googleapis/release-please#1360).

**Rationale:**
- **No tag-namespace migration later** — switching from single-package `v0.1.0` to linked-versions `rulestead-v0.1.0` in Phase 6 would break ExDoc `source_ref`, existing tag history, and create a CHANGELOG discontinuity. Pay the small Phase 1 tax, skip the big Phase 6 scar.
- Known release-please linked-versions bugs (googleapis/release-please#1750 `includeComponentInTag=false`, #2707 node-workspace plugin, #1456 group-pull-request-title-pattern) **do not apply** — we set `include-component-in-tag: true`, we use `elixir` release-type (no workspace plugin exists), we avoid group title patterns.
- **Release PRs stay unmerged during Phases 1–7.** The first release PR merge is in Phase 8 when admin has real UI. This is documented in MAINTAINING.md (see D-06).
- Anchor doc `rulestead-release-engineering-and-ci.md` §3.1 recommended "start lean, switch later" — that advice is **superseded** by PROJECT.md's explicit key-decision lock-in and by accrue's proven lockstep-fallback pattern. Update anchor doc to reflect this decision (see deferred note D-20).

### D-03: `rulestead_admin` Phase 1 Content — Skeleton-but-Never-Published-Until-Phase-8

`rulestead_admin/` directory exists from commit 1 with:
- Valid `mix.exs` including `@version` shared via a top-level `VERSION` file or duplicated constant synchronized by release-please
- `lib/rulestead_admin.ex` with `@moduledoc false` + version reflection
- `lib/rulestead_admin/router.ex` stub exporting a `rulestead_admin/2` macro that raises `ArgumentError, "rulestead_admin: admin UI ships in Phases 6–7 of v0.1.0; track progress at <ROADMAP URL>"` when invoked
- Env-swap dep per accrue pattern:
  ```elixir
  defp rulestead_dep do
    if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
      {:rulestead, "~> #{@version}"}
    else
      {:rulestead, path: "../rulestead"}
    end
  end
  ```
  CI sets `RULESTEAD_ADMIN_HEX_RELEASE: "1"` only in the admin publish job.
- `package.files` whitelist excludes `test/example/`, `.planning/`, `prompts/`, `rulestead/` — see D-05.
- Own `.formatter.exs` that will import `:rulestead` after core publishes a formatter (Phase 2+).

**Admin is NEVER published to Hex until Phase 8.** Defensive guard in `publish-hex.yml`: the admin publish step checks that `rulestead_admin/lib/rulestead_admin/router.ex` contains the real `defmacro rulestead_admin` implementation (not the stub that raises). Without that guard, a misrouted release PR merge could publish the stub package to Hex — which **would violate Hex.pm Code of Conduct** (explicit prohibition on "publishing an empty package to 'reserve' a name").

**Rationale:**
- Sibling directory must exist to support the sibling layout (D-01) — `cd rulestead_admin && mix test` must work for every contributor from day 1.
- Never publishing until real content exists keeps us clean with Hex CoC.
- Env-swap solves the chicken-and-egg (admin can't `{:rulestead, "~> 0.1"}` before core is published to Hex).
- **Rejected alternatives:** publishing empty admin at v0.1.0 (Hex CoC violation); no admin directory until Phase 6 (breaks D-01 layout intent, forces mid-milestone retrofit).

### D-04: CI Workflow Surface — 7 Files Day 1 (modified "Option C")

Day-1 `.github/workflows/` contents:

| Workflow | Purpose | Phase 1 state |
|---|---|---|
| `ci.yml` | Lint + test matrix + `release_gate` aggregator | Real. Jobs: `lint`, `test` (matrix 1.17/26.x + 1.19/28.x), `integration-placeholder` (just `echo "placeholder"`), `release_gate` (aggregates). NO `installer_path_gate` / `installer_golden` — those land in Phase 5. |
| `release-please.yml` | Linked-versions release PR opener | Real. Triggers on `push: main` + `workflow_dispatch`. Opens v0.1.0 PR on merge #1. PR is **not merged** until Phase 8. |
| `publish-hex.yml` | Manual recovery publish path | Real. `workflow_dispatch` only — inert until invoked. Guards admin publish with `router.ex` content check (see D-03). |
| `pr-title.yml` | Conventional-commit PR title lint | Real. **Start with `pull_request` trigger** (not `pull_request_target`) — we're solo-maintainer at Phase 1; switch to `pull_request_target` + locked-down `permissions: pull-requests: read` + no-checkout discipline when opening to external contributors (Phase 8-adjacent). |
| `dependabot-automerge.yml` | Patch-only auto-merge | Real. Fires only on `github.actor == 'dependabot[bot]'`. |
| `dependency-review.yml` | GitHub dep-review action on PRs | Real. Near-zero cost; works on empty repo. |
| `actionlint.yml` | reviewdog + actionlint on workflow changes | Real. Path-filtered on `.github/workflows/**`. |

**Deferred:**
- `installer_path_gate` + `installer_golden` jobs inside `ci.yml` → Phase 5 (when installer exists)
- `verify-published-release.yml` daily drift cron → Phase 8 (same PR as first publish — so its first run verifies the fresh tarball instead of emitting "not yet published — skipping" daily for 2 months)
- `playwright-github-pages.yml` admin demo site → post-v0.5 per anchor doc

**Supporting files:**
- `.github/dependabot.yml` with `mix` + `github-actions` ecosystems, weekly cadence, patch-group
- `.github/ISSUE_TEMPLATE/` (bug_report.md, feature_request.md, release-parity-drift.md)
- `.github/pull_request_template.md` (conventional commit reminder + checklist)
- `.github/CODEOWNERS` (maintainer handle)

**Rationale:**
- Seven files is in range with Tesla (5), Bandit (7), Phoenix LiveView (5). Oban/Ecto/Broadway ship with 1 — but Dashbit's culture is uniquely minimal; rulestead's batteries-included + release-engineering-heavy posture justifies more surface.
- **No false-green workflows** — every day-1 workflow runs and gates something real.
- `release-please.yml` from day 1 avoids the known bootstrap pain (manifest backfill, CHANGELOG retrofit, `GITHUB_TOKEN` re-run discovery, conventional-commit silently-corrupting-commit-history problem).
- `release_gate` aggregator pattern means **later phases grow `ci.yml`'s `needs:` array freely with zero branch-protection ripples** — the single most load-bearing stability property.

**Critical footgun avoidance:**
- **Workflow-level `paths-ignore` + required status checks = permanent pending** (GitHub docs warn this explicitly). Use **job-level `if:` conditionals with `dorny/paths-filter@v3`** for anything feeding `release_gate`, not workflow-level `paths-ignore`. The `.planning/**` path-ignore in anchor doc §2.1 is SAFE at workflow level only if `release_gate` never reports status on skipped workflows — audit this before going green.
- **Release-please + default `GITHUB_TOKEN` = CI doesn't re-run on the release PR** (GitHub-documented limitation). Phase 1 choice: accept this and document "manually re-run CI on release PR" in MAINTAINING.md. Escalate to a fine-grained PAT (`RELEASE_PLEASE_TOKEN` scoped `contents:write, pull-requests:write`) in Phase 8 if manual re-run becomes painful.
- **Release Please bootstrap:** seed `.release-please-manifest.json` with `{"rulestead": "0.0.0", "rulestead_admin": "0.0.0"}` AND include `Release-As: 0.1.0` footer in the bootstrap commit. Default start is `v1.0.0` if neither is set.

### D-05: `.tool-versions` and `mix.exs` Fragments

**`.tool-versions` (repo root):**

```
elixir 1.19.2-otp-28
erlang 28.1.2
```

Use `erlef/setup-beam@v1` with `version-file: .tool-versions` + `version-type: strict` everywhere. **Pinning strict patch versions is mandatory** because Dialyzer PLT cache keys depend on exact OTP version (silent bumps trigger full PLT rebuilds).

Test matrix cells in `ci.yml` hardcode the two support tiers:
- `elixir: "1.17.3", otp: "26.2.5", support: required`
- `elixir: "1.19.2", otp: "28.1.2", support: required`

**`rulestead/mix.exs` `package/0` whitelist:**

```elixir
files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
# MUST never contain: test/example/, prompts/, .planning/, rulestead_admin/ (sibling), scripts/, docker-compose.yml
```

**`rulestead_admin/mix.exs` `package/0` whitelist:**

```elixir
files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
# MUST never contain: test/example/, prompts/, .planning/, rulestead/ (sibling core)
```

**CI check:** `mix hex.publish --dry-run` in each package, then `grep -q "rulestead_admin/" tarball.tar.gz && exit 1` (core) + `grep -q "^rulestead/" tarball.tar.gz && exit 1` (admin) to catch accidental cross-contamination.

### D-06: Dialyzer Configuration — Single-Cell, Lint Job, Trimmed Flags

**Enable Dialyzer at Phase 1, but diverge from anchor doc §2.4 / §10 in three ways:**

1. **Move `mix dialyzer` OUT of the `test` matrix and INTO the `lint` job.** Single-cell (newest: 1.19.2/28.1.2). Saves ~2 CI min per PR with near-zero signal loss (OTP-26-only regressions are rare and caught by `test` matrix anyway).

2. **`mix.exs` `dialyzer/0` function:**

   ```elixir
   defp dialyzer do
     [
       plt_local_path: "priv/plts",
       plt_core_path: "priv/plts",
       plt_add_apps: [:ex_unit, :mix, :eex],
       flags: [:error_handling, :extra_return, :missing_return],
       ignore_warnings: ".dialyzer_ignore.exs",
       list_unused_filters: true
     ]
   end
   ```

   Deltas vs. anchor doc:
   - **Added `plt_core_path: "priv/plts"`** — without it, Erlang/Elixir core PLT lives in `$MIX_HOME` and isn't covered by the `priv/plts` cache key (the single most common "my cache isn't working" bug).
   - **Dropped `:iex`** from `plt_add_apps` (YAGNI — no current use site; re-add on warning).
   - **Dropped `:underspecs`** from `flags` — notoriously noisy on greenfield libs; OTP team guidance treats it as a quality ratchet, not a baseline. Reintroduce at v0.5 once `api_stability.md` surface is locked (tracked as future requirement).
   - **Added `ignore_warnings: ".dialyzer_ignore.exs"`** + empty ignore file committed at repo root.
   - **Added `list_unused_filters: true`** — fails CI when an ignore pattern no longer matches, keeping the ignore file honest.

3. **Deps:** `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}`. Verify it's absent from `mix hex.build --unpack` output during Phase 1 CI.

4. **CI step** (inside `lint` job, after `mix hex.audit`): split `actions/cache/restore@v4` → build-if-miss → `actions/cache/save@v4 if: always()` pattern. Cache key: `${{ runner.os }}-otp28.1.2-elixir1.19.2-plt-${{ hashFiles('**/mix.lock') }}` with `restore-keys` fallback on `${os}-otp-elixir-plt-`. Run: `mix dialyzer --format github --format dialyxir`.

5. **Dialyzer is a blocking gate via the `lint` job** (which is a required check via `release_gate`). **Do NOT add a separate `dialyzer` required check in branch protection** — keep the aggregator pattern.

**Rationale:**
- Oban runs Dialyzer on one cell (`if: ${{ matrix.lint }}`) — this is the exact pattern to copy. Phoenix, Ecto, Broadway run no Dialyzer at all (Dashbit house style); Tesla runs on one pinned older cell; Bandit runs advisory-with-auto-evict; Absinthe runs on every cell (the outlier).
- **Retrofit risk at Phase 8 is real** — landing Dialyzer on thousands of LOC all at once historically means hundreds of warnings dropped, "fix all warnings or turn off strict," and 2–3 extra days to ship.
- At Phase 1 with zero lib code, Dialyzer provides ~zero signal. But it **proves the pipeline works** before real code arrives in Phase 2 (schemas, error structs, `Rulestead.Fake`).
- Omar (OSS contributor persona) expects Dialyzer on any serious Elixir library — one green `lint / dialyzer` check per PR satisfies that expectation.

### D-07: Documentation Skeleton Depth — "C-Plus" (root full, README full, guides thin, Phase-8 docs deferred)

**Write in full at Phase 1** (~12–14 hours total):

| File | Phase 1 state |
|---|---|
| `README.md` | **Full** — real 60-second pitch, real 15-minute quickstart against intended v0.1 API, `⚠️ Pre-release` banner naming current phase, persona map, feature highlights, sibling-package callout, brand footer. Shape documented in this CONTEXT.md §Specific Ideas. |
| `CONTRIBUTING.md` | Full — toolchain floor, docker-compose, `mix ci.all`, conventional commits, PR shape, squash-merge culture, CoC pointer |
| `MAINTAINING.md` | Full — secret setup list, **branch protection required-checks table** (see D-08), release runbook (release-please flow), recovery tree for `publish-hex.yml`, "never merge release PR mid-milestone" discipline note |
| `SECURITY.md` | Full — disclosure email, supported-versions policy ("Pre-1.0 — no backports"), threat-model summary link |
| `CODE_OF_CONDUCT.md` | Full — Contributor Covenant 2.1 verbatim |
| `LICENSE` | Full — MIT verbatim |
| `CLAUDE.md` | Full — GSD fenced blocks, pointers to `prompts/`, intent statement |
| `AGENTS.md` | Full — mirrors CLAUDE.md |
| `CHANGELOG.md` (per-package, 2 files) | Keep-a-Changelog header + `## [Unreleased]` section only. Release-please owns subsequent edits. |

**Thin-but-real stubs** (3–20 min each, must pass `mix docs --warnings-as-errors`):

| File | Phase 1 state |
|---|---|
| `guides/introduction/installation.md` | 2-paragraph stub: "what this will cover" + "Current status: Phase 1 foundation; see README for pre-release quickstart" + roadmap link |
| `guides/introduction/getting-started.md` | "Coming in v0.1.0; the pre-release quickstart lives in [README](../../README.md)" + 1-paragraph preview |
| `guides/introduction/upgrading.md` | "No prior versions to upgrade from; this page becomes the upgrade guide at v0.2.0" |
| `guides/flows/{evaluation,rulesets,rollout,admin-ui,explainability,multi-env}.md` | Each: `# Title\n\nDocumented in v0.1.0 (Phase N ships the feature; this guide lands in Phase 8). See [ROADMAP](...).` |
| `guides/recipes/{testing,telemetry,ecto-conventions,oban-background-jobs,deployment,context-propagation}.md` | Same placeholder shape |

**Deferred to Phase 8 — DO NOT CREATE AS FILES:**

- `CONVENTIONS.md` — documents locked rules enforced by custom Credo checks (Phase 7)
- `guides/cheatsheet.cheatmd` — one-page API surface; only meaningful once surface is locked
- `guides/api_stability.md` — explicitly names locked public modules + what's internal; can't name non-existent things
- `guides/flows/extending-rulestead.md` — one recipe per public behaviour; behaviours ship in Phases 2–7

**ExDoc config (in `rulestead/mix.exs`):**
- `main: "readme"` (not `"getting-started"` per anchor doc — README is the canonical Phase 1 front door; switch to `"getting-started"` in Phase 8)
- `extras:` lists every non-placeholder guide; skip pure placeholders or include them with `filename:` overrides
- `skip_undefined_reference_warnings_on: &String.starts_with?(&1, "lib/")` (anchor doc pattern — narrow predicate, not wildcard)
- `source_ref: "v#{@version}"`

**Rationale:**
- Root docs are **policy docs** (not feature docs) — they describe repo lifecycle, not library behavior. Writing them at Phase 1 costs nothing and signals seriousness to Omar (OSS contributor) who may arrive at any commit.
- README written against intended API is **Readme-Driven Development** (Preston-Werner 2010, uncontroversial OSS doctrine). Banner solves the honesty question. The one cascade cost (Phases 2–7 may tune the API, requiring README edits) is worth the pressure-test value.
- Phase-8-only docs document **the locked public surface** — creating them as stubs at Phase 1 either produces empty-looking broken docs OR speculative content that drifts through six phases. Both are worse than silence.
- Guide stubs keep ExDoc IA locked and CI green at minimum content cost; real writing lands when the thing being documented is built.

### D-08: Branch Protection Settings (main)

Document verbatim in `MAINTAINING.md` §"Branch protection settings" so it's recoverable if the GitHub UI is nuked:

- **Required status checks:**
  - `release_gate` (aggregates `lint`, `test`, `integration-placeholder` from `ci.yml`)
  - `Validate PR title` (amannn/action-semantic-pull-request job name)
  - `dependency-review` (from `dependency-review.yml`)
  - **NOT** `actionlint` (path-filtered; would go Pending on non-workflow PRs — keep advisory until a skip-but-require pattern is solved)
- **Require branches to be up-to-date before merging:** off (slows Dependabot auto-merge with no correctness benefit at low PR volume)
- **Require a pull request before merging:** on, 0 approvals required (solo-maintainer; enables `gh pr merge --auto` for Dependabot)
- **Require linear history:** on (squash-merge + conventional commits)
- **Require signed commits:** off (defer to v1.0 per anchor doc §13)
- **Do not allow bypassing the above settings:** on
- **Allow force pushes:** off
- **Allow deletions:** off
- **Require conversation resolution before merging:** off

### D-09: Package & Package-Level Formatter + Credo Strategy

- **Root `.formatter.exs`** imports `:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug`. Input glob covers `{mix,.formatter}.exs` + `{config,lib,test,priv/repo/migrations}/**/*.{ex,exs}` across both packages.
- **`rulestead/.formatter.exs`** is minimal (imports above deps). After Phase 2 ships formatter-relevant macros, core exports them so `rulestead_admin/.formatter.exs` and downstream host apps can `import_deps: [:rulestead]`.
- **`rulestead_admin/.formatter.exs`** imports `:rulestead` (when core ships a formatter — Phase 2+) plus `:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug`.
- **`.credo.exs`** at repo root with `strict` enabled and `requires: []` (empty — custom checks ship in Phase 7). Mix aliases ensure `mix credo --strict` runs against both packages via `mix credo --strict` from each package's subdir (or a root `credo.all` alias).

### D-10: Integration Placeholder Job

`ci.yml` contains an `integration-placeholder` job with a single step `run: echo "integration placeholder; real integration lands in Phase 5"`. This keeps `release_gate.needs:` stable from Phase 1 → Phase 5 (when the real integration suite lands and replaces the placeholder). Stability of `release_gate`'s `needs:` array is worth more than one saved UI check-row.

### Claude's Discretion

- Exact wording of `MAINTAINING.md` release runbook and `CONTRIBUTING.md` section ordering (follow accrue's structure as template).
- Exact `README.md` prose — shape documented in `<specifics>` below, but Claude has room on adjectives/examples within brand constraints (calm, infrastructure-grade, no "blazing"/"cutting-edge"/unnecessary adjectives).
- `scripts/ci/*.sh` skeletons that aren't needed until later phases — create empty + documented or defer entirely per Claude's read.
- `.github/ISSUE_TEMPLATE/` wording (bug_report, feature_request) — use GSD/community defaults.
- Exact badge list in README (build status from GitHub Actions, Hex package badge grayed until publish, license, Elixir version, OpenSSF scorecard optional).
- Whether to add `test/support/readme_code_compile_test.exs` stub at Phase 1 (tagged `@moduletag :pending`) to lock the doc-contract discipline early, or defer to Phase 5 when `test/example/` lands. Recommended: defer — Phase 1 has no library code to compile from README yet.

### Folded Todos

None — no pending todos exist yet (project was just initialized).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents (researcher, planner, executor) MUST read these before planning or implementing.**

### Release engineering & CI (primary references for this phase)

- `prompts/rulestead-release-engineering-and-ci.md` — **MUST READ.** Full CI/release workflow spec. §2.1-§2.7 (ci.yml), §3 (release-please.yml), §4 (publish-hex.yml), §5 (verify-published-release.yml — Phase 8), §6 (pr-title.yml), §7-§8 (Dependabot), §10 (mix.exs fragments), §11 (caching), §13 (branch protection), §14 (scripts/ci inventory), §16 (anti-patterns). **NOTE:** §3.1 recommends single-package release-please — this is **superseded** by D-02 (linked-versions from day 1). Anchor doc edit pending (see D-20 deferred).
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — **MUST READ.** §2.1 (repo metadata), §2.2 (CI lanes), §2.3 (release/versioning), §2.4 (error model), §2.5 (telemetry — Phase 4), §2.6 (testing — Phases 2/3/5), §2.7 (doc contracts), §5 (starter skeleton — note this shows single-`lib/`; D-01 uses sibling dirs per PROJECT.md key decision), §6 (gotchas).
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir CI/CD best-practices survey including release-please multi-package lessons.

### Project-level

- `.planning/PROJECT.md` — Key Decisions table (sibling packages + linked-versions locked in), Constraints (licensing, whitelist, zero-host-deps, no-PII).
- `.planning/REQUIREMENTS.md` — Phase 1 maps to REL-01, REL-02, REL-05, DOC-01, DOC-02, DOC-03 (+ partial REL-06 scaffold).
- `.planning/ROADMAP.md` — Phase 1 goal, scope, success criteria, dependencies.

### Secondary (useful for context even if not directly in Phase 1 scope)

- `prompts/rulestead-engineering-dna-from-prior-libs.md` §3 (divergent menu) and §7 (GSD seed plan).
- `prompts/elixir-best-practices-deep-research.md` — general Elixir library idioms.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS library packaging.
- `prompts/elixir_feature_flags_research_brief.md` §7.1 (runtime purity — informs mix.exs no_warn_undefined list).
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — Alex (15-min quickstart drives README shape), Omar (CONTRIBUTING quality), Shiori + Tova (MAINTAINING audience).
- `prompts/rulestead-brand-book.md` — voice + typography for README/guides (calm, infrastructure-grade).

### External (fetched during research)

- Hex.pm Code of Conduct: https://hex.pm/policies/codeofconduct (empty package squatting prohibition — load-bearing for D-03).
- googleapis/release-please known issues: #1360 (empty-commits), #1456 (group title pattern), #1750 (include-component-in-tag), #2707 (workspace plugin) — documented workarounds in D-02.
- Oban CI pattern: `.github/workflows/ci.yml` single-cell Dialyzer gate — template for D-06.
- Tesla CI pattern: 5 workflow files including release-please.yml — template for D-04.
- accrue repo (same author, shipped) — verbatim source for release-please linked-versions + lockstep-fallback bash.

</canonical_refs>

<code_context>
## Existing Code Insights

**This is a greenfield project — there is no existing code.** Phase 1 creates the repository from scratch.

### Reusable assets
- None in the repository. **BUT** the engineering DNA from 7 prior author-shipped Elixir libs is the "reusable asset" pool. Every pattern ports in verbatim per §2 of the engineering-dna doc (5-of-7 convergence rule).

### Established patterns
- None local. Canonical patterns come from `prompts/` anchor docs (release-eng, engineering-dna, etc.).

### Integration points
- None at Phase 1. Integration with host Phoenix apps happens in Phase 5 (installer). Admin UI mount happens in Phase 6 (LiveView shipping).

</code_context>

<specifics>
## Specific Ideas

### README Phase 1 shape (drop-in template)

```markdown
# Rulestead

> **Runtime decisions, made clear.**
> Batteries-included Elixir-native feature flags, experimentation, and
> remote config — with a mountable Phoenix LiveView admin.

<!-- badges: build / hex.pm / hexdocs / license — grayed until first publish -->

> ⚠️ **Pre-release.** v0.1.0 is in active development (Phase 1 of 8). The
> quickstart below describes the target API for v0.1.0 and will ship as
> tested against published Hex tarballs in Phase 8. Track progress in
> [ROADMAP](.planning/ROADMAP.md). First external feedback welcome via
> GitHub Issues.

## What this is (60 seconds)

Rulestead gives Elixir apps typed feature flags, staged rollouts, and a
built-in LiveView admin with explainability baked in. Every decision is
deterministic, auditable, and explainable — no black-box evaluation, no
mystery config drift, no 3am "why did this flip?" panic. Designed for
teams who already trust Postgres, Ecto, Phoenix, and Oban, and want
flags to feel like one more Phoenix primitive instead of a sub-project.

## Who it's for

- **App Dev** — `Rulestead.enabled?("checkout_v2", conn)` in 15 minutes.
- **Tech Lead** — staged rollouts + simulate-before-publish + audit.
- **PM / Operator** — simple-mode admin UI, no terminal required.
- **Support** — permalinked "why did user X see Y?" explain pages.
- **SRE** — bookmarkable kill switch, health endpoint, signed audit bundles.
- **OSS Contributor** — narrow behaviours, shared test suites, fast CI.

## 15-minute quickstart

    # 1. Add to mix.exs
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}    # optional — mountable LiveView admin

    # 2. Install
    mix deps.get
    mix rulestead.install            # idempotent; --yes skips prompts
    mix ecto.migrate

    # 3. Use it
    if Rulestead.enabled?("checkout_v2", conn) do
      render_v2(conn)
    else
      render_v1(conn)
    end

    # 4. Admin UI (optional) in your router
    import Rulestead.Admin.Router
    rulestead_admin "/admin/flags",
      policy: MyApp.RulesteadAdminPolicy

    # 5. Toggle from CLI or UI
    mix rulestead.set_flag checkout_v2 true --env dev

For the full walkthrough with Context builders, variants, testing, and
LiveView helpers, see [Getting Started](guides/introduction/getting-started.md).

## Feature highlights

- **Typed flags** — boolean, string, integer, float, JSON, variant.
- **Deterministic bucketing** — same `(flag_key, actor_id)` → same bucket.
- **Explainability** — `Rulestead.explain/2` returns a structured trace.
- **Mountable admin** — one-line LiveView mount in your Phoenix router.
- **Pluggable** — swap Store, RuleEngine, EvaluationCache, AuditStore, ActorResolver.
- **Audit by default** — every mutation writes an append-only event row.
- **Test-first** — in-memory Fake adapter; no Postgres required for tests.
- **Telemetry everywhere** — span wrapper + versioned 4-level event names.
- **Optional deps** — Oban, OpenTelemetry optional.

## Install / Documentation / Sibling packages / Status / Why "rulestead"? / License

[standard sections with working links to stub guides + ROADMAP + brand book]
```

### accrue patterns to port verbatim

- `release-please.yml` lockstep-fallback bash block (detects `release_created=false` for admin when both manifest versions match; forcibly re-emits output).
- `RULESTEAD_ADMIN_HEX_RELEASE=1` env-swap in `rulestead_admin/mix.exs` deps function.
- `.github/ISSUE_TEMPLATE/release-parity-drift.md` (wait until Phase 8 drift-cron lands).
- `scripts/ci/*.sh` header pattern: `set -euo pipefail` + `RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"` preamble.
- Job-id contract comment at top of each workflow file.

### Oban CI pattern to port

- Single-cell Dialyzer gate: `if: ${{ matrix.lint }}` — Phase 1 translation: put dialyzer in the `lint` job, not the test matrix.
- Minimum plausible Dialyzer flag set: `[:error_handling, :extra_return, :missing_return]`.

### Tesla CI pattern to port

- `release-please.yml` from release-please migration day 1 — proof this isn't overkill for a Hex-published library.

</specifics>

<deferred>
## Deferred Ideas

Captured here so they don't get lost, but not acted on in Phase 1.

### Deferred to later phases in v0.1.0

- **D-11:** `installer_path_gate` + `installer_golden` CI jobs → Phase 5 (added when installer code ships).
- **D-12:** `verify-published-release.yml` daily drift cron → Phase 8 (same PR as first Hex publish).
- **D-13:** Custom Credo checks (`NoRawTraitsInTelemetryMeta`, `NoRawTraitsInLogger`, `NoEvalOutsideContext`, `NoUnscopedTenantQueryInLib`, `NoMutationOutsideMulti`, `NoSocketCapturedInAsync`) → Phase 7.
- **D-14:** `CONVENTIONS.md`, `guides/cheatsheet.cheatmd`, `guides/api_stability.md`, `guides/flows/extending-rulestead.md` → Phase 8.
- **D-15:** `test/support/readme_code_compile_test.exs` (doc-contract test that README code blocks compile) → Phase 5, when `test/example/` host skeleton lands.
- **D-16:** Real guide content for `guides/flows/*` and `guides/recipes/*` → Phase 8 (stubs only at Phase 1).
- **D-17:** `playwright-github-pages.yml` admin demo site → post-v0.5.
- **D-18:** Switch `pr-title.yml` from `pull_request` to `pull_request_target` trigger → Phase 8-adjacent (when opening to external contributors). Maintain no-checkout discipline + `permissions: pull-requests: read`.
- **D-19:** Escalate from default `GITHUB_TOKEN` to fine-grained `RELEASE_PLEASE_TOKEN` PAT → Phase 8 if manual CI re-run on release PR becomes painful.

### Deferred to v0.2+ (governance milestone, post-v0.1.0)

- **D-20:** Update `prompts/rulestead-release-engineering-and-ci.md` §3.1 to reflect that rulestead shipped linked-versions from day 1 (not "start lean"). This is a doc-drift fix, not a code change. Can be done in Phase 8 alongside other doc polish.
- **D-21:** Reintroduce Dialyzer `:underspecs` flag at v0.5 as a quality ratchet (after `api_stability.md` surface is locked and `@spec` discipline is mature).
- **D-22:** Bandit-style PLT stale-cache auto-eviction + retry in `lint` job → v0.3+ when a real PLT-corruption incident happens. Until then, manual `gh cache delete` is a 30-second recovery. Note the pattern in MAINTAINING.md.

### Scope creep caught during discussion (not Phase 1)

- None — discussion stayed within phase scope.

### Reviewed Todos (not folded)

None — no pending todos existed at discussion time.

</deferred>

---

*Phase: 01-repo-bootstrap*
*Context gathered: 2026-04-23*

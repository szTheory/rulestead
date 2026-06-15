# Phase 119 CI/CD Audit

Phase 119 records evidence and recommendations only. It does not edit workflow behavior, test behavior, release trust posture, product runtime APIs, schemas, `rulestead_admin` publish posture, browser baseline strategy, or test inclusion. It also does not introduce workflow-level path filters for required PR checks, tag-only publish trust, local publish shortcuts, weaker workflow permissions, weaker action pinning, unchecked Hex secret exposure, ExUnit async/sharding changes, checked-in pixel baselines, FleetDesk product rebranding, or Phase 8-only docs.

Requirements covered by this audit: CIDX-01, CIDX-02, and CIDX-03.

Evidence conventions:

- `[VERIFIED: path-or-command]` means the claim is backed by a repo file, local command, or live CLI/API command named in the tag.
- `[CITED: official-doc-url]` means the claim relies on official external documentation.
- `[ASSUMED: reason]` means the claim is an explicit assumption because live evidence was unavailable or not defensible from the current sample.

## Executive Recommendation

Pending final classification. The current working recommendation is to preserve the always-triggered `ci.yml` plus aggregate `release_gate` baseline while Phase 119 records static workflow inventory, live GitHub state, local Mix diagnostics, cache/PLT posture, and test/check classification before Phases 120-123 change behavior. [VERIFIED: .planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md]

## Evidence Collection

| Evidence Type | Source | Status |
|---------------|--------|--------|
| Phase scope and decisions | `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` | collected |
| Roadmap and requirements | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` | collected |
| Workflow definitions | `.github/workflows/*.yml` | collected |
| Script-first CI surfaces | `scripts/ci/*.sh`, `scripts/demo/*.sh` | collected |
| Live GitHub workflow list | `gh workflow list --repo szTheory/rulestead --all --json name,path,state,id` | collected |
| Live branch protection | `gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks` | collected |
| Live CI run timing | `gh run list --repo szTheory/rulestead --workflow ci.yml --limit 20 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch` | pending detailed analysis |
| Local Mix diagnostics | D-11 command set | pending |

## Workflow and Job Inventory

Live workflow state was collected with:

```bash
gh workflow list --repo szTheory/rulestead --all --json name,path,state,id
```

Result summary: all checked-in workflow files are active; GitHub also reports the dynamic `Dependabot Updates` workflow. [VERIFIED: gh workflow list --repo szTheory/rulestead --all --json name,path,state,id]

| File | Workflow name | Live ID | Triggers | Permissions | Concurrency | Jobs | Role |
|------|---------------|---------|----------|-------------|-------------|------|------|
| `.github/workflows/actionlint.yml` | `actionlint` | `265354684` | `pull_request` | `contents: read`, `pull-requests: write` | none | `actionlint` | advisory workflow syntax signal; not documented as required because path-filtered checks can sit pending |
| `.github/workflows/ci.yml` | `ci` | `265354303` | `push`, `pull_request`, `workflow_dispatch` | `contents: read`, `actions: read`, `checks: read` | `ci-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `openfeature-companion`, `mounted-proof`, `release_gate` | merge-blocking aggregate baseline through `release_gate` |
| `.github/workflows/dependency-review.yml` | `dependency-review` | `265354683` | `pull_request` | `contents: read` | none | `dependency-review` | documented required dependency supply-chain check |
| `.github/workflows/dependabot-automerge.yml` | `dependabot-automerge` | `265354685` | `pull_request` | `pull-requests: write`, `contents: write` | none | `auto-merge` | dependency automation |
| `.github/workflows/pr-title.yml` | `Validate PR title` | `265354686` | `pull_request` | `contents: read`, `pull-requests: read` | none | `validate-pr-title` | documented required release-note hygiene check |
| `.github/workflows/release-please.yml` | `release-please` | `265354302` | `push`, `workflow_dispatch` | `contents: write`, `pull-requests: write`, `issues: write`, `actions: write` | `release-please-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `release-please`, `dispatch-release-pr-ci`, `dispatch-publish` | release intent automation |
| `.github/workflows/release-pr-ci.yml` | `release-pr-ci` | `284980013` | `push`, `workflow_dispatch` | `contents: read`, `actions: write` | `release-pr-ci-${{ github.ref }}`, cancel in progress | `dispatch-ci` | release PR CI dispatch |
| `.github/workflows/release-pr-automerge.yml` | `release-pr-automerge` | `286030394` | `workflow_run`, `workflow_dispatch` | `contents: write`, `pull-requests: write`, `actions: write` | none | `automerge` | release PR automation |
| `.github/workflows/publish-hex.yml` | `publish-hex` | `274861464` | `workflow_dispatch` | `contents: read`, `actions: read`; handoff job adds `issues: write` | none | `preflight`, `gate-ci-green`, `approval`, `publish-core`, `publish-admin`, `handoff-post-publish` | protected release-only Hex publish |
| `.github/workflows/verify-published-release.yml` | `verify-published-release` | `274861466` | `schedule`, `workflow_dispatch` | `contents: read`, `issues: write` | `verify-published-release-${{ github.workflow }}-${{ github.ref }}`, cancel in progress | `verify-published-release` | post-publish proof and scheduled release hygiene |
| `.github/workflows/repo-hygiene.yml` | `repo-hygiene` | `286030395` | `schedule`, `workflow_dispatch` | `contents: read`, `issues: write` | none | `hygiene-check` | scheduled hygiene |

`ci.yml` stable job IDs are explicitly documented in the file comment and present in YAML: `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, `openfeature-companion`, `mounted-proof`, and `release_gate`. [VERIFIED: .github/workflows/ci.yml]

`ci.yml` runner and service baseline:

- All jobs use `ubuntu-24.04`.
- `test` matrix axes are Elixir `1.17.3` / OTP `26.2.5` and Elixir `1.19.2` / OTP `28.4.3`.
- `test` and `adopter-contract` use a Postgres 15 service with `MIX_ENV=test`.
- `lint`, `test`, `adopter-contract`, `openfeature-companion`, and `mounted-proof` use Mix dependency/build caches.
- `lint` restores and saves `rulestead/priv/plts` with `actions/cache/restore` and `actions/cache/save`. [VERIFIED: .github/workflows/ci.yml]

## Required-Check Semantics

Live branch-protection state was collected with:

```bash
gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks
```

Exact output on 2026-06-15:

```json
{"message":"Branch not protected","documentation_url":"https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection","status":"404"}
gh: Branch not protected (HTTP 404)
```

documented-vs-live finding: `MAINTAINING.md` documents required checks (`release_gate`, `Validate PR title`, and `dependency-review`) and explicitly excludes path-filtered `actionlint`; the live GitHub API currently returns `Branch not protected`. This is external mutable repository state, not YAML source truth, so Phase 119 records it and makes no settings change. [VERIFIED: MAINTAINING.md; VERIFIED: gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks]

Required-check pending trap: workflow-level path filters must not be recommended for required PR checks. Path selectivity belongs inside always-reporting workflows or behind an aggregate required check. [VERIFIED: .planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md; CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

Aggregate gate baseline: `release_gate.needs` currently includes `changes`, `lint`, `test`, `integration-placeholder`, `adopter-contract`, and `mounted-proof`. The `openfeature-companion` job exists as a path-gated proof job, and openfeature-companion is absent from current release_gate.needs. Do not change `ci.yml` in Phase 119; carry this as a Phase 120 required-check semantics finding. [VERIFIED: .github/workflows/ci.yml]

## Critical Path and Metrics Baseline

Live run sample was collected with:

```bash
gh run list --repo szTheory/rulestead --workflow ci.yml --limit 20 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch
gh run view &lt;run-id&gt; --repo szTheory/rulestead --json jobs,createdAt,updatedAt,conclusion,event,workflowName
```

Representative recent `ci.yml` sample:

| run ID | event | branch | conclusion | wall-clock | longest job | likely critical path |
|--------|-------|--------|------------|------------|-------------|----------------------|
| `27542317576` | `pull_request` | `dependabot/hex/rulestead_admin/a11y_audit-0.4.0` | success | 5m18s | `test (1.17.3 / OTP 26.2.5)` at 4m43s | matrix `test`, then `release_gate` |
| `27471122598` | `push` | `main` | success | 5m04s | `test (1.17.3 / OTP 26.2.5)` at 4m38s | matrix `test`, then `release_gate` |
| `27471186416` | `workflow_dispatch` | `release-please--branches--main` | failure | 4m46s | `test (1.19.2 / OTP 28.4.3)` at 4m03s; failing `test (1.17.3 / OTP 26.2.5)` at 3m12s | failing matrix `test`, then failed `release_gate` |

The 20-run sample includes `pull_request`, `push`, and `workflow_dispatch` runs across dependabot, main, release branch, and feature branch contexts. The sample is enough to identify the current critical path, but not enough to claim a defensible p95 across event types and branch classes, so: p95 target unavailable from current sample. [VERIFIED: gh run list --repo szTheory/rulestead --workflow ci.yml --limit 20 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch]

duplicated work hypotheses:

- `lint`, `test`, `adopter-contract`, `mounted-proof`, and `openfeature-companion` each restore Mix deps/build caches and run overlapping package setup.
- `scripts/ci/local.sh` calls `scripts/ci/test.sh` scopes after `cd rulestead && mix ci`, so local full runs intentionally duplicate some test/lint work to preserve simple reproduction.
- `adopter-contract` runs `RULESTEAD_TEST_SCOPE=post_ga_band_closure`, while the default `scripts/ci/test.sh` scope also routes through post-GA proof. This is a likely duplication candidate for Phase 121 classification, not a Phase 119 deletion.
- `openfeature-companion` and `mounted-proof` are path-gated jobs; their current skipped status can hide proof-bar timing from many recent PR samples.

Runner and scheduling observations:

- All `ci.yml` jobs use `ubuntu-24.04`.
- Matrix axes are Elixir `1.17.3` / OTP `26.2.5` and Elixir `1.19.2` / OTP `28.4.3`.
- Postgres service usage appears in the `test` and `adopter-contract` jobs via `postgres:15`.
- `release_gate` itself is cheap, but it waits on the matrix and proof jobs; the effective critical path is currently the slowest matrix/proof job plus aggregate-gate scheduling.

## Cache and Dialyzer PLT Posture

Cache inventory from `.github/workflows/ci.yml`:

| Job | Action | Path | Key | restore-keys | Scope and posture |
|-----|--------|------|-----|--------------|-------------------|
| `lint` | `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/deps`, `rulestead/_build` | `${{ runner.os }}-lint-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | `${{ runner.os }}-lint-mix-` | Includes OS, lockfiles, `.tool-versions`; no explicit `MIX_ENV` in key, likely safe for lint scope but should stay under Phase 120 attention. |
| `lint` | `actions/cache/restore@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/priv/plts` | `${{ runner.os }}-plt-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | none | PLT cache includes OS and lock/tool versions, but not explicit OTP/Elixir/MIX_ENV/package scope beyond `.tool-versions`; correctness-safe enough for current strict lint lane, worth Phase 120 attention before broader PLT moves. |
| `lint` | `actions/cache/save@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/priv/plts` | `${{ runner.os }}-plt-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | n/a | Save runs `if: always()` to preserve PLT cache even when Dialyzer fails. |
| `test` | `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/deps`, `rulestead/_build/test`, `rulestead_admin/deps`, `rulestead_admin/_build/test` | `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-${{ hashFiles('**/mix.lock') }}` | `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-`, `${{ runner.os }}-mix-` | Matrix-specific primary key is correctness-safe; broad `${{ runner.os }}-mix-` restore breadth needs Phase 120 attention. |
| `adopter-contract` | `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/deps`, `rulestead/_build/test`, `rulestead_admin/deps`, `rulestead_admin/_build/test` | `${{ runner.os }}-adopter-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | `${{ runner.os }}-adopter-mix-` | Package scope is explicit in paths; `.tool-versions` carries Elixir/OTP; `MIX_ENV=test` is in job env but not key. |
| `openfeature-companion` | `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `open_feature_rulestead/deps`, `open_feature_rulestead/_build/test` | `${{ runner.os }}-openfeature-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | `${{ runner.os }}-openfeature-mix-` | Companion-package scoped cache; `MIX_ENV=test` is in env but not key. |
| `mounted-proof` | `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` | `rulestead/deps`, `rulestead/_build/test`, `rulestead_admin/deps`, `rulestead_admin/_build/test` | `${{ runner.os }}-mounted-mix-${{ hashFiles('**/mix.lock', '.tool-versions') }}` | `${{ runner.os }}-mounted-mix-` | Proof-bar scoped cache; `MIX_ENV=test` is in env but not key. |

Cache recommendation posture: keep existing keys during Phase 119; Phase 120 should tighten any restore breadth only where the key remains correctness-safe across OS, Elixir, OTP, lockfile, `.tool-versions`, `MIX_ENV`, and package scope. [VERIFIED: .github/workflows/ci.yml]

## Mix, ExUnit, Dialyzer, and Xref Diagnostics

Local CPU/scheduler baseline:

- `getconf _NPROCESSORS_ONLN || sysctl -n hw.ncpu || true` exit status 0: `18`
- `cd rulestead && elixir -e 'IO.puts(System.schedulers_online())'` exit status 0: `18`
- `erl -noshell -eval 'io:format("~p~n", [erlang:system_info(schedulers_online)]), halt().'` exit status 0: `18`

D-11 command results:

| Command | exit status | elapsed | Key output |
|---------|-------------|---------|------------|
| `cd rulestead && mix test --warnings-as-errors --slowest 25` | 2 | `real 42.35s` | 587 tests, 8 properties, 1 failure. slowest test: `test admin consumer fixture compiles against published Hex packages` in `Rulestead.Mix.Tasks.VerifyReleasePublishTest`, about 27.95s. A focused rerun of that location passed in 20.8s with 0 failures. |
| `cd rulestead && mix test --warnings-as-errors --slowest-modules 25` | 2 | `real 41.31s` | 587 tests, 8 properties, 1 failure. slowest modules: `Rulestead.Mix.Tasks.VerifyReleasePublishTest` about 27.89s, then `Rulestead.RolloutAutoAdvanceOrchestrationContractTest` about 1.61s, `Rulestead.Store.EctoAudienceImpactContractTest` about 1.43s. |
| `cd rulestead && mix test --profile-require time` | 0 | `real 2.77s` | There are no tests to run; profile-require compiled 192 test modules, with examples including `test/rulestead/store/audience_impact_contract_test.exs` at 432ms, `test/rulestead/audience_mutation_audit_test.exs` at 430ms, and `test/rulestead/telemetry_test.exs` at 416ms. |
| `cd rulestead && mix compile.elixir --force --profile time` | 0 shell capture with compiler errors printed | `real 1.41s` first run; confirmed with tail capture | compile profile shows `lib/rulestead/store/command.ex` at 465ms and multiple dependency waits. Command prints errors such as `module Ecto.Schema is not loaded` and `module Ecto.Query is not loaded`; record as environment/task-specific diagnostic behavior, not a Phase 119 fix. |
| `cd rulestead && mix xref graph --format cycles --label compile-connected` | 0 | `real 4.60s` | One compile-connected cycle of length 47, centered on `lib/rulestead.ex`, governance/guardrails/manifest/runtime/store modules, and `lib/rulestead/ruleset/guardrail.ex (compile)`. |
| `cd rulestead && mix xref graph --format stats --label compile-connected` | 0 | `real 4.55s` | Tracked files: 172 nodes; compile dependencies: 5 edges; exports dependencies: 62 edges; runtime dependencies: 341 edges; cycles: 1. |
| `cd rulestead && mix xref graph --label compile-connected` | 0 | `real 0.38s` | `lib/rulestead/ruleset/guardrail.ex -> lib/rulestead/guardrails/query.ex (compile)`. |

Phase 121 async/sharding recommendations require proof that candidate modules avoid global app env mutation, DB ownership hazards, ports, filesystem or shared process state, logger or telemetry capture, fake-store resets, Ecto sandbox hazards, and LiveView process ownership issues. No test files, workflow YAML, Dialyzer configuration, ExUnit async flags, or proof scope scripts were modified for this diagnostic baseline.

Verification note: the diagnostic section intentionally records nonzero or noisy command output as baseline evidence; it does not remediate the full-suite sample failure, compile-elixir dependency-loading errors, or compile-connected xref cycle in Phase 119.

## Test and Check Classification Matrix

Pending D-03 classification.

## Rerun Command Catalog

Script-first reruns stay the contributor-facing abstraction. [VERIFIED: scripts/ci/contributor.sh; VERIFIED: scripts/ci/local.sh; VERIFIED: scripts/ci/test.sh; VERIFIED: MAINTAINING.md]

| Surface | Exact local rerun command | Boundary protected |
|---------|---------------------------|--------------------|
| Fast contributor loop | `bash scripts/ci/contributor.sh` | Common pre-push checks without slow proof scopes |
| Full local monorepo gate | `bash scripts/ci/local.sh` | Lint, tests, adopter, mounted, and OpenFeature proof scopes |
| Faster maintainer iteration | `bash scripts/ci/local.sh --fast` | Lint plus core package test loop while skipping mounted/OpenFeature companion scopes |
| Core package gate | `cd rulestead && mix ci` | Core package format, compile, Credo, tests, and docs |
| Adopter contract | `cd rulestead && mix verify.adopter` | Post-GA adopter contract proof |
| Mounted admin companion proof | `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` | Mounted companion router/session/admin boundary |
| OpenFeature companion proof | `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` | OpenFeature provider compatibility boundary |
| Post-GA band closure | `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh` | Release/adopter/docs proof superset |
| FleetDesk demo proof | `bash scripts/demo/verify.sh` | Compose-backed browser/demo adoption proof |
| Post-publish verification | `bash scripts/ci/verify_published_release.sh <version>` | Published Hex package installability and linked-version proof |

Additional supported `RULESTEAD_TEST_SCOPE` values from `scripts/ci/test.sh`: `all`, `guarded_rollout_foundations`, `reusable_targeting_deepening`, `blast_radius_governance`, `guarded_rollout_auto_advance`, `host_preview_evidence`, and `install_journey`. [VERIFIED: scripts/ci/test.sh]

`scripts/ci/lint.sh` quality signals:

- `format`: `mix format --check-formatted`
- compile `warnings-as-errors`: `mix compile --warnings-as-errors`
- `Credo` strict: `mix credo --strict`
- docs `warnings-as-errors`: `mix docs --warnings-as-errors`
- `Hex audit`: `mix hex.audit`
- no-optional-deps compile: `mix compile --no-optional-deps --warnings-as-errors`
- package whitelist: package guard in the core Mix lane and release preflight surfaces
- `Dialyzer`: `mix dialyzer --format github`
- synced pair: `scripts/check_synced_pair.py`
- brand tokens: `scripts/check_brand_tokens.py`
- tokens CSS: `scripts/check_tokens_css.py`
- contrast: `scripts/check_contrast.py`
- `brandbook HTML`: `scripts/check_brandbook_html.py`
- logo assets: `scripts/check_logo_assets.py`
- admin foundations: admin foundation guard chain inherited from prior milestones
- design-system evidence: `scripts/check_design_system_evidence.py`

## Failure Categories and Maintainer Microcopy

Failure guidance should preserve the mounted-proof pattern already present in `scripts/ci/test.sh`:

| Slot | Meaning | Example wording pattern |
|------|---------|-------------------------|
| `what failed` | Name the failed scope or category first | `mounted_admin_contract failure category: <category>` |
| `boundary it protects` | Explain the support/release/adopter boundary | `Expected support boundary: mounted companion only; host app owns the router/session prerequisite contract.` |
| `exact rerun command` | Give a copyable command | `Rerun: RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` |
| `likely remediation` | Point to the likely repair domain, not a generic retry | Inspect contract regression output for resolver, governance, mounted workflow, or dependency drift depending on category |
| `when to stop rather than bypass` | Tell maintainers when the signal is release-trust relevant | Stop before bypass when the failure protects adopter, release, mounted companion, OpenFeature, or post-publish trust |

The microcopy posture is scripts-first and fail-closed: make failure categories actionable, but do not encourage bypassing protected proof bars just because they are slow. [VERIFIED: scripts/ci/test.sh; VERIFIED: MAINTAINING.md]

## Release and Supply-Chain Trust

Release and supply-chain trust surfaces are speed surfaces and security findings:

- Action pinning: workflow actions are pinned to full SHA values in `ci.yml` and release workflows, with comments naming upstream versions. Keep by default. [VERIFIED: .github/workflows/ci.yml]
- Least-privilege permissions: most workflows use narrow `contents: read`; release automation deliberately uses write permissions where it opens PRs, dispatches workflows, or writes handoff issues. Keep unless Phase 120 can narrow without breaking release flow. [VERIFIED: .github/workflows/*.yml]
- `dependency-review`: active PR workflow and documented required check. Keep. [VERIFIED: .github/workflows/dependency-review.yml; VERIFIED: MAINTAINING.md]
- Dependabot coverage: dynamic `Dependabot Updates` workflow is active and `.github/dependabot.yml` is part of dependency automation posture. [VERIFIED: gh workflow list --repo szTheory/rulestead --all --json name,path,state,id; VERIFIED: .github/dependabot.yml]
- `publish-hex`: protected release-only workflow with protected `hex-publish` environment, `HEX_API_KEY` exposure only inside the publish boundary, preflight, `gate-ci-green`, core-before-admin publish order, admin publish guard, and handoff to post-publish verification. Keep by default. [VERIFIED: .github/workflows/publish-hex.yml]
- Linked release posture: core-before-admin order preserves the linked-version sibling-package design; Phase 119 must not prepare standalone admin publishing. [VERIFIED: MAINTAINING.md; VERIFIED: AGENTS.md]
- Post-publish proof: `verify-published-release` and `bash scripts/ci/verify_published_release.sh <version>` remain release-trust gates, not optional speed targets. [VERIFIED: .github/workflows/verify-published-release.yml; VERIFIED: scripts/ci/verify_published_release.sh]
- Secret boundary: `HEX_API_KEY` is named only as a secret identifier; no secret value was printed or requested.

## Browser, Demo, and Integration Evidence

Pending browser/demo/integration evidence findings.

## No-Go and Rollback Guardrails

No Phase 119 recommendation may:

- Reduce release-gate trust without equivalent evidence.
- Break the linked-version sibling-package release design.
- Prepare `rulestead_admin` for standalone publishing.
- Replace generated browser artifacts with checked-in pixel baselines.
- Hide browser flakes behind blind retries.
- Delete or demote slow checks solely because they are slow.
- Move path selectivity to workflow-level filters for required PR checks.
- Change product runtime APIs, schemas, product UI, brand, or the design system.

## Handoff Notes for Phases 120-123

Pending evidence-backed handoff bullets.

## Sources

| Source | Role |
|--------|------|
| `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` | Phase decisions D-01 through D-21 |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-RESEARCH.md` | Research baseline and official/comparable pattern notes |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-PATTERNS.md` | Required audit pattern map |
| `.planning/phases/119-baseline-expert-audit-0-plans/119-VALIDATION.md` | Validation strategy |
| `.planning/ROADMAP.md` | Phase sequence and success criteria |
| `.planning/REQUIREMENTS.md` | CIDX-01, CIDX-02, CIDX-03 |
| `.github/workflows/*.yml` | Workflow definitions |
| `scripts/ci/*.sh`, `scripts/demo/*.sh` | Script-first CI and proof commands |
| `MAINTAINING.md` | Documented branch-protection and release posture |

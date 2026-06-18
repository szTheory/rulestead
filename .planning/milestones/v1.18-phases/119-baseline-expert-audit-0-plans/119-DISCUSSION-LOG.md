# Phase 119: Baseline + Expert Audit - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-15
**Phase:** 119-baseline-expert-audit-0-plans
**Mode:** assumptions
**Areas analyzed:** Audit shape, workflow topology, release and supply chain, Mix/ExUnit/Dialyzer, browser/demo/integration evidence, contributor DX

## Assumptions Presented

### Audit Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 119 should create one integrated `119-CI-CD-AUDIT.md`, not split docs. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, user request for one-shot coherent recommendations |
| The audit should classify checks as `keep`, `optimize`, `move`, `quarantine/fix`, or `delete/rewrite`. | Confident | `.planning/ROADMAP.md` Phase 119 success criteria, `CIDX-03` |
| The artifact should become the decision ledger for Phases 120-123. | Confident | `.planning/STATE.md` strict sequence 119 -> 120 -> 121 -> 122 -> 123 |

### Workflow Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve an always-triggered `ci.yml` with a single required aggregate `release_gate` unless audit proves a better replacement. | Likely | `.github/workflows/ci.yml`, `MAINTAINING.md`, GitHub required-check behavior docs |
| Avoid workflow-level path filters for required checks; keep selectivity inside always-reporting workflows. | Confident | GitHub workflow syntax and required-check troubleshooting docs |
| Explicitly audit whether `openfeature-companion` should be included in the aggregate release gate. | Likely | `.github/workflows/ci.yml`, `.planning/PROJECT.md` preserved OpenFeature proof bar |

### Release and Supply Chain

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve Release Please, protected Hex publish, linked sibling package ordering, and post-publish verification. | Confident | `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/verify-published-release.yml`, `.planning/PROJECT.md` |
| Do not introduce local publish shortcuts, tag-only publish trust, or admin standalone publish preparation. | Confident | `MAINTAINING.md`, `.planning/REQUIREMENTS.md` out-of-scope table, AGENTS.md |
| Audit action pinning, permissions, dependency review, Dependabot, Hex preflight, and cache restore breadth as trust surfaces. | Confident | `.github/workflows/*.yml`, `scripts/ci/lint.sh`, supply-chain prompt guidance |

### Mix, ExUnit, Dialyzer, and Ecto

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 119 should run or prescribe Mix diagnostics before tuning tests. | Confident | `.planning/ROADMAP.md` success criteria, Mix/ExUnit official docs |
| Do not flip async, shard, demote Dialyzer, delete slow tests, or rewrite proof scopes in Phase 119. | Confident | `.planning/REQUIREMENTS.md` out-of-scope constraints, `scripts/ci/test.sh`, `scripts/ci/lint.sh` |
| Async expansion later must respect Elixir/Phoenix/Ecto shared-state hazards. | Confident | ExUnit, Ecto Sandbox, Phoenix testing docs; repo scan showing app env, sandbox, process, filesystem, and browser/global state hazards |

### Browser, Demo, Integration, and UI Evidence

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Classify browser/demo/integration proof by value and determinism, not runtime alone. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `scripts/demo/verify.sh`, Playwright prompt guidance |
| Do not hide flake behind blind retries; prefer artifacts and root-cause fixes or explicit quarantine. | Confident | Playwright retry/CI docs, `.planning/ROADMAP.md` Phase 122 criteria |
| Generated screenshots/reports remain ignored artifacts, not checked-in pixel baselines. | Confident | `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `prompts/rulestead-testing-and-e2e-strategy.md` |

### Contributor DX

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep scripts-first CI as the least-surprising contributor abstraction. | Confident | `scripts/ci/local.sh`, `scripts/ci/contributor.sh`, `scripts/ci/test.sh`, `MAINTAINING.md`, release-engineering prompt |
| Failure output should say what failed, what boundary it protects, exact rerun command, likely remediation, and when to stop. | Likely | `scripts/ci/test.sh`, user emphasis on DX and user friendliness, personas/JTBD prompt |
| Prefer simple local reproduction over clever CI topology. | Confident | `.planning/REQUIREMENTS.md` out-of-scope constraints, Mix/ExUnit docs, GitHub Actions docs |

## Corrections Made

No corrections - all assumptions were confirmed by the user's `1` response after review.

## Subagent Research Summary

### Workflow topology, cache, release, and supply chain

| Option | Pros | Cons / Footguns | Selected |
|--------|------|-----------------|----------|
| Always-triggered CI with job-level gating and aggregate `release_gate` | Avoids pending required-check traps, keeps one branch-protection contract, supports docs-only/admin/OpenFeature selectivity | Aggregate must be carefully maintained as jobs are renamed or added | Yes |
| Workflow-level `paths`/`paths-ignore` on required workflows | YAML appears simpler and may skip more work | Skipped workflows can leave required checks pending; branch protection becomes brittle | No |
| Require every individual job/matrix entry | Fine-grained visibility | Branch protection churn, skipped job confusion, harder contributor mental model | No |
| Weaken release/publish checks for speed | Faster publish path | Violates linked-package and post-publish proof model | No |

### Mix, ExUnit, Dialyzer, and test value

| Option | Pros | Cons / Footguns | Selected |
|--------|------|-----------------|----------|
| Baseline diagnostics first, no behavior changes in Phase 119 | Evidence-backed later changes, protects proof bars, idiomatic Elixir audit posture | No immediate speedup | Yes |
| Flip many tests to `async: true` immediately | Possible wall-clock gain | Unsafe with app env, DB sandbox ownership, fake stores, filesystem, logger/telemetry, LiveView/process state | No |
| Broad partitioning now | Potential parallelism | DB/schema isolation and rerun complexity can exceed value | No |
| Demote Dialyzer or expensive proof by default | Faster CI | Hidden correctness/release risk | No |

### Browser, demo, integration, and UI evidence

| Option | Pros | Cons / Footguns | Selected |
|--------|------|-----------------|----------|
| Audit taxonomy first, defer fixes to Phase 122 | Preserves proof value while identifying real flake/root causes | No immediate runtime reduction | Yes |
| Full Compose + Playwright on every PR | Strongest confidence | Expensive and vulnerable to readiness/port/artifact flake | Maybe later only if evidence justifies |
| Scheduled/release/manual full proof plus minimal PR sentinel | Better PR runtime and determinism | Requires proof-equivalence argument before demotion | Later-phase candidate |
| Blind retries | Masks intermittent failures | Can hide regressions and conflicts with root-cause requirement | No |

### Contributor DX and audit artifact design

| Option | Pros | Cons / Footguns | Selected |
|--------|------|-----------------|----------|
| One integrated audit with rerun commands and failure categories | Best planning handoff and maintainer experience | Longer artifact to write carefully | Yes |
| Separate topical audit docs | Easier per-domain ownership | Higher chance of inconsistent recommendations | No |
| More machine-generated reports without curation | Richer raw data | Can bury actionability and slow CI | No for Phase 119 |

## External Research

- GitHub Actions workflow syntax and path filter behavior: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- GitHub required-check troubleshooting and skipped workflow behavior: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
- GitHub job condition skipped-success behavior: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions
- GitHub dependency caching guidance: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching
- GitHub secure use guidance: https://docs.github.com/en/actions/reference/security/secure-use
- GitHub job summaries and workflow commands: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands
- GitHub artifacts: https://docs.github.com/en/actions/tutorials/store-and-share-data
- Mix test diagnostics and partitioning: https://hexdocs.pm/mix/Mix.Tasks.Test.html
- ExUnit async and test semantics: https://hexdocs.pm/ex_unit/ExUnit.html
- Mix xref graph diagnostics: https://hexdocs.pm/mix/Mix.Tasks.Xref.html
- Mix compile profiling: https://hexdocs.pm/mix/main/Mix.Tasks.Compile.Elixir.html
- Ecto SQL Sandbox: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
- Dialyxir GitHub Actions guidance: https://hexdocs.pm/dialyxir/github_actions.html
- Phoenix testing: https://hexdocs.pm/phoenix/testing.html
- Playwright CI: https://playwright.dev/docs/ci
- Playwright retries: https://playwright.dev/docs/test-retries
- Playwright screenshots and artifacts: https://playwright.dev/docs/screenshots
- Playwright configuration and snapshots: https://playwright.dev/docs/test-configuration and https://playwright.dev/docs/test-snapshots
- Docker Compose readiness: https://docs.docker.com/compose/how-tos/startup-order/
- `actions/setup-node` cache behavior: https://github.com/actions/setup-node

## Deferred Ideas

- Implement workflow topology/cache changes in Phase 120.
- Implement ExUnit/test-value/Dialyzer changes in Phase 121.
- Implement browser/demo/integration determinism changes in Phase 122.
- Implement contributor docs, closeout metrics, and rollback docs in Phase 123.
- Consider larger runners, broad sharding, richer reports, and browser binary caching only after Phase 119 evidence.

---

*Phase: 119-baseline-expert-audit-0-plans*
*Discussion log generated: 2026-06-15*

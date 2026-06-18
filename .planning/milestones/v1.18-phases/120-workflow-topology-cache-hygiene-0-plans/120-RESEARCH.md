# Phase 120: Workflow Topology + Cache Hygiene - Research

**Researched:** 2026-06-16
**Domain:** GitHub Actions CI topology, required-check semantics, Mix/PLT cache correctness, scripts-first observability, release/supply-chain preservation (Elixir sibling-package monorepo)
**Confidence:** HIGH (all edit targets verified against live source; required-check semantics cited to GitHub docs; one CONTEXT drift flagged)

## Summary

Phase 120 is a narrow, correctness-first CI/CD reliability pass on a single primary file (`.github/workflows/ci.yml`, 332 lines) plus documentation reconciliation in `MAINTAINING.md`. Every decision D-01..D-12 is already locked in CONTEXT.md and grounded in the Phase 119 audit; the planner does not re-decide anything. The job is to turn locked decisions into exact, auditable YAML/doc edits and to prove each edit without a live merge.

All edit targets were verified against current source. The CONTEXT line-number references are accurate (release_gate at `ci.yml:294-332`, cross-lane fallback at `ci.yml:175-177`, Evaluate gate at `ci.yml:307-332`, mounted-proof transform at `ci.yml:321-323`). **One drift: CONTEXT and the audit say "three separate `mix.lock` files (core/admin/open_feature)"; there are actually FOUR** — `examples/demo/backend/mix.lock` also exists and is globbed by every `hashFiles('**/mix.lock')` key. This strengthens (does not weaken) D-06: the repo-wide glob causes cross-package over-invalidation, including from demo-backend lock churn that no CI lane builds.

`actionlint` 1.7.12 is installed locally — this is the central validation tool. The entire phase can be proven offline: `actionlint` validates YAML topology and bash-in-`run` syntax; `scripts/ci/release_gate.sh` is a pure argument-normalizer that can be unit-exercised directly; cache-key correctness is a static-reasoning property over key components; and `MAINTAINING.md`/`gh api` docs-only changes are verified by reading the documented triad against the live workflow names. No live merge, no `gh api` write, and no Hex publish is required or permitted.

**Primary recommendation:** Make the smallest correctness-safe edits — wire `openfeature-companion` into `release_gate` mirroring the existing mounted-proof transform (D-03), remove the one cross-lane `${{ runner.os }}-mix-` restore key (D-05), scope only the lint + PLT keys to `rulestead/mix.lock` (D-06, correctness-safe because lint builds only `rulestead/`), add `$GITHUB_STEP_SUMMARY` observability reusing existing `MATRIX_ELIXIR`/`MATRIX_OTP` (D-08), and reconcile `MAINTAINING.md` docs-only (D-07, D-11). Validate every step with `actionlint` + a `release_gate.sh` arg-matrix test before claiming green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Always-on required gate | CI orchestration (`release_gate` aggregate) | `changes` job outputs | Branch protection requires ONE always-reporting check; selectivity lives in job `if:` + the aggregate's skipped→success transform, never workflow-level path filters (D-01/D-02) |
| Path selectivity / docs-only skip | `changes` job (`dorny/paths-filter`) | per-job `if:` conditions | Filter outputs drive job `if:` and the aggregate transform; keeps required check from sitting Pending (GitHub required-check trap) |
| Companion proof relevance gating | `openfeature-companion` / `mounted-proof` job `if:` | `release_gate` transform | Job runs only when its paths change; aggregate treats `skipped` as `success` only when not relevant (D-03 mirrors D-existing mounted pattern) |
| Mix deps/build cache | per-lane `actions/cache` | `hashFiles` + restore-keys | Each lane owns a lane-scoped key; correctness over sharing (D-04/D-05/D-06) |
| Dialyzer PLT cache | `lint` job (`actions/cache/restore`→build→`save if: always()`) | — | CI owns warm PLT; PLTs gitignored locally; key must stay correctness-safe before any move (Phase 121 owns Dialyzer placement) |
| Release trust / publish | `publish-hex.yml` (protected env) | `ci.yml` `gate-ci-green` upstream | PRESERVE-ONLY in Phase 120; no edits to trust posture (D-09) |
| Branch-protection truth | `MAINTAINING.md` docs | live `gh api` (out of scope) | Docs-only reconciliation; no live settings write this milestone (D-11) |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Required-Check Semantics**
- **D-01:** Keep `ci.yml` always-triggered (no workflow-level `paths:`/`paths-ignore:`). Preserve single `release_gate` aggregate (`if: always()` + `needs:` fan-in) as the only branch-protection-required gate. Evidence: `ci.yml:6-16` triggers, `ci.yml:294-332` release_gate, `ci.yml:28-88` changes job, audit D-04/D-05.
- **D-02:** Fix selectivity inside the aggregate, not at workflow level. Use `changes`-job outputs + "skipped means success only when not relevant" transform. Never recommend workflow-level path filters for required checks (Pending traps). Evidence: `ci.yml:315-323`, audit D-05, GitHub docs.

**OpenFeature Companion Gate**
- **D-03 (wire in):** Add `openfeature-companion` to `release_gate.needs`, merge-blocking only when companion-relevant, advisory (skipped→success) otherwise. Intended shape:
  - `ci.yml:296-302`: add `- openfeature-companion` to `release_gate.needs`.
  - `ci.yml:307-332` (Evaluate gate): add `openfeature_result="${{ needs['openfeature-companion'].result }}"`; add transform `if [[ "${{ needs.changes.outputs.openfeature-companion }}" != "true" && "${openfeature_result}" == "skipped" ]]; then openfeature_result="success"; fi`; pass `"openfeature-companion=${openfeature_result}"` into `scripts/ci/release_gate.sh`.
  - No change to `scripts/ci/release_gate.sh` (already fails any non-`success` pair, `release_gate.sh:29-37`).
  - Scope guard: MAINTAINING.md keeps framing that this proof is merge-blocking only for the Elixir provider package contract, not browser/demo glue, publish choreography, or unrelated surfaces. Evidence: audit D-06; `ci.yml:238-261`; `ci.yml:321-323`; MAINTAINING.md OpenFeature proof boundary.

**Cache Hygiene**
- **D-04 (correctness first):** Tighten restore breadth only where the primary key stays correctness-safe across OS, Elixir, OTP, lockfile, `.tool-versions`, `MIX_ENV`, package scope. Never optimize sharing at the expense of correctness.
- **D-05:** Remove the cross-lane `${{ runner.os }}-mix-` fallback restore key in the `test` matrix job (`ci.yml:175-177`); keep the matrix-scoped `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-` restore key. Prevents restoring `_build` compiled for an incompatible OTP/Elixir lane.
- **D-06:** Scope each cache key's `hashFiles` to lockfiles the lane actually builds, not repo-wide `**/mix.lock`, where correctness-safe. Concretely: lint and Dialyzer PLT build only `rulestead/` (`ci.yml:103-124`), so scope their keys to `rulestead/mix.lock` + `.tool-versions`. Treat per-package scoping for `test`/`adopter`/`mounted` keys as "tighten where correctness-safe"; defer any change that risks under-invalidation. Evidence: separate `mix.lock` files; audit cache table.
- **D-07:** Document a one-line cache-busting rule per cache (which key component change forces a rebuild) in `MAINTAINING.md` or workflow comments.

**Cache/Version Observability**
- **D-08 (lightweight, scripts-first):** Add log/summary output (no new reporting system): echo Elixir/OTP/tool versions, cache hit/miss, copy-pasteable local reproduction command for failed lanes. Prefer `$GITHUB_STEP_SUMMARY` and existing `scripts/ci/*`. Evidence: success criterion #3; scripts-first preference.

**Release and Supply Chain**
- **D-09 (preserve, do not weaken):** Keep full release-trust topology: green CI on tagged SHA (`gate-ci-green`), protected `hex-publish` env approval before `HEX_API_KEY`, core-before-admin publish order, admin publish guard, post-publish verification. Evidence: `publish-hex.yml`, `scripts/ci/verify_published_release.sh`, `scripts/ci/admin_publish_guard.sh`, MAINTAINING.md, audit D-08.
- **D-10 (preserve, do not weaken):** Keep full-SHA action pinning, least-privilege workflow permissions, Dependabot coverage, dependency-review, secret boundaries at least as strict as baseline. Evidence: `.github/workflows/*.yml` SHA pins, `.github/dependabot.yml`, audit D-09/D-10, CIDX-09.

**Branch-Protection Reconciliation**
- **D-11 (docs only):** `main` returns `Branch not protected` (404) live, despite MAINTAINING.md documenting a required-check triad. Phase 120 reconciles documentation only: state exact intended protection settings in `MAINTAINING.md` (required checks = `release_gate`, `Validate PR title`, `dependency-review`; `actionlint` excluded as path-filtered) and note manual application required. No `gh api` writes. Evidence: audit D-04 live 404; MAINTAINING.md:32-52.

**Scope Boundary**
- **D-12:** Phase 120 touches ONLY workflow topology, cache keys/restore behavior, required-check aggregation, release/supply-chain posture (preserve), practical job output, MAINTAINING.md required-check reconciliation. NOT ExUnit async/sharding (121), browser/Playwright/demo determinism (122), contributor-command/closeout docs (123), product runtime APIs/schemas, admin publish posture.

### Claude's Discretion
- Exact YAML phrasing, comment wording, and location of busting-rule docs (workflow comments vs MAINTAINING.md), provided every decision above is honored.
- Low-cost log/summary lines beyond the minimum when they strengthen failure triage without changing behavior.
- Sequencing changes into one or more plans, as long as the `release_gate` aggregate stays green at every commit.

### Deferred Ideas (OUT OF SCOPE)
- Live branch protection via `gh api` / repo-settings writes (D-11 documents intended settings for manual application).
- ExUnit async, test partitioning, oversized-module splits, Dialyzer placement → Phase 121.
- Browser/demo/integration/Playwright determinism and generated-evidence behavior → Phase 122.
- Contributor-facing command docs, closeout metrics, rollback documentation → Phase 123.
- Larger runners, broad test sharding, richer reports, browser-binary caching → later phases unless evidence justifies.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CIDX-04 | PR gates remain trustworthy and deterministic while high-value adopter, release, mounted companion, and OpenFeature proof bars stay preserved. | D-01/D-02/D-03 mechanics below: always-on `release_gate`, skipped→success transform semantics (verified `ci.yml:303-323`), and the exact openfeature-companion wiring shape. GitHub required-check trap documented + cited so the planner avoids workflow-level path filters. |
| CIDX-07 | Maintainer can verify cache keys, restore keys, Dialyzer PLT handling, and cache observability are correctness-safe and documented. | Full cache inventory with verified line numbers + correctness analysis (D-04/D-05/D-06), the FOUR-mix.lock over-invalidation finding, busting-rule doc template (D-07), and `$GITHUB_STEP_SUMMARY` observability pattern (D-08). |
| CIDX-09 | Release and supply-chain posture remains at least as strict as the current baseline: pinned actions, minimal permissions, gated Hex publish, post-publish proof. | Preserve-only inventory (D-09/D-10): SHA-pinned actions, `permissions:` blocks, protected `hex-publish` env, `gate-ci-green`, core-before-admin order, admin guard, post-publish verify — all verified present. "Do NOT change" list provided so plans can assert no regression. |
</phase_requirements>

## Standard Stack

No new packages are installed in this phase. It edits existing GitHub Actions YAML, bash CI scripts, and Markdown. The "stack" is the existing pinned action set plus local validation tools.

### Validation / tooling (already present)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| `actionlint` | 1.7.12 (local, homebrew) | Static lint of workflow YAML + embedded bash | [VERIFIED: `actionlint --version`] Primary offline validation gate for every `ci.yml` edit |
| `actions/checkout` | SHA `df4cb1c069e1874edd31b4311f1884172cec0e10` # v6.0.3 | Repo checkout | [VERIFIED: ci.yml] Do not re-pin |
| `erlef/setup-beam` | SHA `8251c48667b97e88a0a24ec512f5b72a039fcea7` # v1 | Elixir/OTP toolchain | [VERIFIED: ci.yml] |
| `actions/cache` (+`/restore`,`/save`) | SHA `27d5ce7f107fe9357f9df03efb73ab90386fccae` # v5.0.5 | Mix/PLT caching | [VERIFIED: ci.yml] The action under correctness scrutiny |
| `dorny/paths-filter` | SHA `6852f92c20ea7fd3b0c25de3b5112db3a98da050` # v3 | `changes` job path detection | [VERIFIED: ci.yml] |
| `actions/setup-node` | SHA `48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e` # v6.4.0 | integration-placeholder Node | [VERIFIED: ci.yml] |

**Package Legitimacy Audit:** N/A — no packages installed. This phase only edits checked-in YAML/bash/Markdown using already-pinned actions and a locally-installed `actionlint`. No registry installs.

## Architecture Patterns

### System: required-check aggregation data flow

```
PR / push event (always triggers ci.yml — NO workflow-level path filter)
        |
        v
  [changes job] --dorny/paths-filter--> outputs: docs-only, openfeature-companion, mounted-proof
        |
        +--> lint        (if: docs-only != true)
        +--> test matrix  (if: docs-only != true)   2 lanes: 1.17.3/OTP26, 1.19.2/OTP28
        +--> integration-placeholder (if: docs-only != true)
        +--> adopter-contract (always eligible)
        +--> openfeature-companion (if: openfeature-companion == 'true')   <-- D-03 wires into gate
        +--> mounted-proof (if: mounted-proof == 'true')
        |
        v
  [release_gate]  needs: ALL above + changes;  if: always()   <-- single required check
        |
        | Evaluate gate (bash):
        |   read each needs.<job>.result
        |   docs-only==true  -> skipped lint/test/integration treated as success
        |   mounted-proof not relevant + skipped -> success      (existing pattern, ci.yml:321-323)
        |   [D-03 ADD] openfeature not relevant + skipped -> success
        v
  scripts/ci/release_gate.sh --skip-phase7 "job=result"...
        |
        v  fails on ANY non-success pair (release_gate.sh:33-36)  ->  gate red/green
```

File-to-implementation map is in the Component Responsibilities below; the diagram is conceptual flow only.

### Component responsibilities (verified line numbers)

| Component | File:lines | Responsibility | Phase-120 action |
|-----------|-----------|----------------|------------------|
| Triggers | `ci.yml:6-16` | push/PR/workflow_dispatch on `main`; NO `paths:` | PRESERVE (D-01) |
| `concurrency` | `ci.yml:18-20` | cancel-in-progress per ref | PRESERVE |
| `permissions` | `ci.yml:22-25` | `contents/actions/checks: read` | PRESERVE (D-10) |
| `changes` job | `ci.yml:28-88` | emits `docs-only`, `openfeature-companion`, `mounted-proof` | PRESERVE; reuse existing `openfeature-companion` output (D-03) |
| `lint` cache | `ci.yml:103-111` | key `${{ runner.os }}-lint-mix-${{ hashFiles('**/mix.lock','.tool-versions') }}` over `rulestead/deps`,`rulestead/_build` | SCOPE to `rulestead/mix.lock` (D-06) |
| `lint` PLT restore/save | `ci.yml:112-124` | key `${{ runner.os }}-plt-${{ hashFiles('**/mix.lock','.tool-versions') }}`; save `if: always()` | SCOPE to `rulestead/mix.lock` (D-06); keep save-always |
| `test` matrix | `ci.yml:126-179` | 2-lane matrix; env exports `MATRIX_ELIXIR`/`MATRIX_OTP` (158-159) | observability reuses these (D-08) |
| `test` cache restore-keys | `ci.yml:174-177` | key matrix-scoped; restore-keys include cross-lane `${{ runner.os }}-mix-` (line 177) | REMOVE line 177 (D-05); keep line 176 |
| `adopter-contract` cache | `ci.yml:224-234` | `${{ runner.os }}-adopter-mix-${{ hashFiles('**/mix.lock','.tool-versions') }}` | "tighten where correctness-safe"; DEFAULT = leave (builds both packages) |
| `openfeature-companion` job | `ci.yml:238-261` | `if: openfeature-companion=='true'`; cache `**/mix.lock` but builds only `open_feature_rulestead/` | gate wiring (D-03); cache scoping is discretionary tighten |
| `mounted-proof` job | `ci.yml:263-292` | `if: mounted-proof=='true'`; builds both core+admin | gate transform precedent to mirror |
| `release_gate.needs` | `ci.yml:296-302` | changes,lint,test,integration,adopter,mounted | ADD `- openfeature-companion` (D-03) |
| Evaluate gate | `ci.yml:307-323` | reads results; docs-only + mounted transforms | ADD openfeature result var + transform (D-03) |
| release_gate.sh call | `ci.yml:325-332` | passes job=result pairs | ADD `"openfeature-companion=${openfeature_result}"` (D-03) |

### Pattern 1: not-relevant → success transform (the D-03 template)

The exact existing pattern to mirror, verified at `ci.yml:321-323`:

```bash
# Source: .github/workflows/ci.yml:321-323 [VERIFIED]
if [[ "${{ needs.changes.outputs.mounted-proof }}" != "true" && "${mounted_proof_result}" == "skipped" ]]; then
  mounted_proof_result="success"
fi
```

D-03 mirror (planner writes; shape locked in CONTEXT):
```bash
openfeature_result="${{ needs['openfeature-companion'].result }}"
if [[ "${{ needs.changes.outputs.openfeature-companion }}" != "true" && "${openfeature_result}" == "skipped" ]]; then
  openfeature_result="success"
fi
```
Then add `"openfeature-companion=${openfeature_result}"` as a final argument to the `scripts/ci/release_gate.sh` call (after the `mounted-proof` pair at line 332). The `--skip-phase7` flag and existing pairs stay unchanged.

**Why this is safe:** `release_gate.sh` (verified `:29-37`) loops over arbitrary `job=result` pairs and `exit 1`s on any value `!= success`. Adding a pair needs no script change. When openfeature paths DID change, the job runs and reports `success`/`failure` normally (merge-blocking). When they did not change, the job is `skipped` and the transform rewrites it to `success` so the required gate never sits on a false-fail. This is identical risk profile to the mounted-proof precedent that already ships.

### Pattern 2: cache restore-key narrowing (D-05)

Current `test` job restore-keys (`ci.yml:175-177`):
```yaml
restore-keys: |
  ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-   # KEEP (line 176)
  ${{ runner.os }}-mix-                                          # REMOVE (line 177)
```
The matrix-scoped restore-key (176) only restores `_build`/`deps` compiled for the SAME OTP/Elixir lane. The broad `${{ runner.os }}-mix-` (177) can restore artifacts compiled under the OTHER lane's OTP/Elixir — beam files are not portable across OTP majors (26 vs 28 here), risking stale/incompatible `_build` reuse. Removing it forces a clean rebuild on a cold matrix-scoped cache, which is the known-good outcome (D-04 "prefer a known-good rebuild over a possibly-stale restore").

### Pattern 3: hashFiles scope narrowing (D-06)

The lint lane and its PLT build ONLY `rulestead/` (verified: `scripts/ci/lint.sh:6` does `cd "${RULESTEAD_REPO}/rulestead"`; cache `path:` is `rulestead/deps`,`rulestead/_build` only). Yet their keys hash `**/mix.lock` — globbing all FOUR lockfiles. Scoping to `rulestead/mix.lock` is correctness-safe because no other package's deps affect the lint/PLT build:
```yaml
key: ${{ runner.os }}-lint-mix-${{ hashFiles('rulestead/mix.lock', '.tool-versions') }}
key: ${{ runner.os }}-plt-${{ hashFiles('rulestead/mix.lock', '.tool-versions') }}
```
**Do NOT** narrow `test`/`adopter`/`mounted` keys to `rulestead/mix.lock` — those lanes build `rulestead_admin` too, so they must keep both lockfiles in scope (e.g. `hashFiles('rulestead/mix.lock','rulestead_admin/mix.lock','.tool-versions')`) OR keep `**/mix.lock`. The safe default per CONTEXT is to leave them unless a precise per-package scope is provably correct; over-narrowing here causes under-invalidation (a real bug class). `openfeature-companion` builds only `open_feature_rulestead/` — its key MAY be narrowed to `open_feature_rulestead/mix.lock` as a correctness-safe discretionary tighten.

### Pattern 4: scripts-first $GITHUB_STEP_SUMMARY observability (D-08)

`scripts/ci/test.sh` already reads `MATRIX_ELIXIR`/`MATRIX_OTP` and echoes a lane banner (`test.sh:5-6,500-502`). `lint.sh` and `test.sh` already emit detailed failure microcopy + exact rerun commands (the mounted/reusable/governance `print_*_failure_guidance` functions). D-08 adds, where practical:
- Version echo: Elixir/OTP/tool versions (reuse `MATRIX_ELIXIR`/`MATRIX_OTP`; `mix --version` / `elixir --version`).
- Cache posture: GitHub's `actions/cache` exposes `cache-hit` as a step output (`steps.<id>.outputs.cache-hit`); surface it by giving the cache step an `id:` and echoing into `$GITHUB_STEP_SUMMARY`.
- Copy-pasteable rerun line for the failed lane (already partially present in script microcopy; add the matrix-specific command into the summary).

Prefer writing summary lines from the existing `scripts/ci/*.sh` (scripts-first) or via a thin `echo "..." >> "$GITHUB_STEP_SUMMARY"` workflow step. No new reporting infrastructure.

### Anti-patterns to avoid
- **Workflow-level `paths:`/`paths-ignore:` on `ci.yml`** — would make the required `release_gate` never report on filtered PRs, leaving the check Pending forever (the documented GitHub trap). D-01 forbids; keep selectivity in job `if:` + aggregate transform.
- **Making `actionlint` a required check** — it triggers only on `pull_request` with `paths: .github/workflows/**` (verified `actionlint.yml`), so it sits Pending on every non-workflow PR. MAINTAINING.md already excludes it; keep that.
- **Over-narrowing multi-package cache keys** — narrowing `test`/`mounted`/`adopter` to a single lockfile causes under-invalidation when the other sibling package's lock changes. Correctness beats sharing (D-04).
- **Re-pinning or version-bumping actions** — out of scope and risks weakening the SHA-pin posture (D-10). Leave all pins.
- **Touching `publish-hex.yml` / `verify-published-release.yml` / `dependabot.yml`** — preserve-only (D-09/D-10).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Required-check selectivity | Workflow-level path filters; custom merge-blocking logic | Existing `release_gate` aggregate + `changes` outputs + skipped→success transform | Already shipped, audited, and avoids the Pending trap |
| Aggregate pass/fail decision | New gate-evaluation script | `scripts/ci/release_gate.sh` (already validates arbitrary `job=result` pairs) | D-03 needs zero script change |
| Cache hit reporting | Custom cache-state tracking | `actions/cache` `cache-hit` step output | Built into the action |
| Workflow YAML validation | Manual review only | `actionlint 1.7.12` (installed) | Catches bash + expression + schema errors offline |
| Version reporting in CI | New tooling | `$GITHUB_STEP_SUMMARY` + existing `MATRIX_ELIXIR`/`MATRIX_OTP` + `mix/elixir --version` | Scripts-first, no infra |

**Key insight:** This phase's correct posture is *minimal edits to a working, audited system*. The biggest risk is over-engineering — adding filters, scripts, or scope changes that introduce a regression. Every decision is already constrained to mirror an existing proven pattern.

## Runtime State Inventory

This is a CI-config + docs phase. The only "runtime state" that matters is GitHub-side mutable repo state, not stored application data.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — phase edits no databases, schemas, or stored records. Verified: D-12 scope excludes product runtime APIs/schemas. | None |
| Live service config | **GitHub branch-protection on `main` currently returns `Branch not protected` (404)** — live state diverges from MAINTAINING.md's documented triad. [VERIFIED: audit `gh api .../branches/main/protection/required_status_checks`]. D-11 scopes this to DOCS ONLY this milestone. | Docs reconciliation in MAINTAINING.md; NO `gh api` write (deferred). A maintainer applies settings manually later. |
| OS-registered state | None — no schedulers, daemons, or registered processes embed phase strings. | None |
| Secrets/env vars | `HEX_API_KEY` referenced only inside `publish-hex.yml` publish jobs (preserve-only). No secret renamed or touched. `MATRIX_ELIXIR`/`MATRIX_OTP` are workflow env, reused not renamed (D-08). | None — preserve |
| Build artifacts | CI Mix caches + Dialyzer PLT cache are the build artifacts. Cache-KEY changes (D-05/D-06) intentionally invalidate old cache entries on first run after merge — this is the desired one-time rebuild, not a bug. No local egg-info/compiled-binary equivalents. | Expect one cold-cache CI run per changed lane after merge; this is correct behavior. |

**The canonical question (after all files updated, what still has old state cached/registered):** The GitHub Actions cache store will hold entries under the OLD keys; they simply go unreferenced and expire under GitHub's 7-day eviction. No manual cache purge needed — new keys naturally miss-then-save. Branch protection remains documentation-only divergent until a maintainer applies it (intentionally deferred).

## Common Pitfalls

### Pitfall 1: CONTEXT/audit say "three mix.lock files" — there are FOUR
**What goes wrong:** A plan that scopes `**/mix.lock` reasoning to only core/admin/open_feature misses `examples/demo/backend/mix.lock`.
**Why it happens:** CONTEXT D-06 and the audit cache table both say "three separate `mix.lock` files (core/admin/open_feature)".
**Reality:** [VERIFIED: `find . -name mix.lock -not -path '*/deps/*'`] Four lockfiles exist: `rulestead/mix.lock` (28 lines), `rulestead_admin/mix.lock` (34), `open_feature_rulestead/mix.lock` (16), `examples/demo/backend/mix.lock` (37). All four are content-distinct (`diff -q` confirms core≠admin).
**Impact:** This *strengthens* D-06 — every `hashFiles('**/mix.lock')` key is busted by demo-backend lock churn that NO CI lane builds. Scoping lint/PLT to `rulestead/mix.lock` removes three irrelevant lockfiles from those keys, not two.
**How to avoid:** Plan against four lockfiles. The lint/PLT scoping (D-06) is unambiguously correctness-safe regardless.

### Pitfall 2: required-check Pending trap
**What goes wrong:** Adding workflow-level `paths:` to make CI "skip faster" makes the required `release_gate` never report on filtered PRs → PR stuck on a Pending required check forever.
**Why it happens:** GitHub treats a required status check that never reports as perpetually Pending; path-filtered workflows that don't run produce no check.
**How to avoid:** Keep `ci.yml` always-triggered; selectivity stays in job `if:` + aggregate transform (D-01/D-02). [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]
**Warning signs:** Any plan diff that adds `paths:` or `paths-ignore:` at the `on:` level of `ci.yml`.

### Pitfall 3: over-narrowing multi-package cache keys (under-invalidation)
**What goes wrong:** Scoping `test`/`mounted`/`adopter` keys to `rulestead/mix.lock` only; then a `rulestead_admin/mix.lock` bump restores a stale cache built before the bump → wrong deps, silent.
**Why it happens:** D-06's lint example is correctness-safe (lint builds only core), but these lanes build BOTH sibling packages.
**How to avoid:** Only narrow keys for lanes that build a single package (lint/PLT → `rulestead/`; openfeature → `open_feature_rulestead/`). Multi-package lanes keep both locks (or `**/mix.lock`). CONTEXT explicitly defers under-invalidation-risky changes.

### Pitfall 4: skipped vs success result strings
**What goes wrong:** Mis-typing the openfeature result var or the `needs[...]` accessor breaks the gate transform silently (treats a real skip as failure or vice-versa).
**Why it happens:** Job id `openfeature-companion` contains a hyphen, so it MUST use bracket syntax `needs['openfeature-companion'].result` and `needs.changes.outputs.openfeature-companion`, exactly like the existing `needs['mounted-proof']` (`ci.yml:313,321`) and `needs['integration-placeholder']` (`ci.yml:311`).
**How to avoid:** Copy the bracket form from the verified `mounted-proof` lines. Validate with `actionlint`, which flags expression/context errors.

### Pitfall 5: editing the immutable job-id contract
**What goes wrong:** Renaming a `jobs:` key breaks docs, `act`, and branch protection.
**Why it happens:** `ci.yml:1-3` declares the job ids as an immutable contract: `changes, lint, test, integration-placeholder, adopter-contract, openfeature-companion, mounted-proof, release_gate`.
**How to avoid:** D-03 ADDS a reference to the existing `openfeature-companion` id; it does not rename anything. Keep all `id:` strings; `name:` strings may evolve.

## Code Examples

### Verifying a release_gate.sh argument matrix offline (no live merge)
```bash
# Source: scripts/ci/release_gate.sh:24-37 [VERIFIED]
# Pure normalizer: succeeds only if ALL job=result pairs are "success".
# Prove the new openfeature pair behaves correctly without GitHub:

# all success -> exits 0 (gate green)
bash scripts/ci/release_gate.sh --skip-phase7 \
  changes=success lint=success test=success \
  integration-placeholder=success adopter-contract=success \
  mounted-proof=success openfeature-companion=success
echo "exit: $?"   # expect 0

# a transformed skip already rewritten to success -> 0
# a genuine failure -> non-zero with named job
bash scripts/ci/release_gate.sh --skip-phase7 openfeature-companion=failure ; echo "exit: $?"  # expect 1
```
`--skip-phase7` (verified `:19-22`) skips the admin slice rerun so this runs instantly with no deps.

### Validating the edited workflow offline
```bash
# Source: actionlint 1.7.12 [VERIFIED installed]
actionlint .github/workflows/ci.yml
# Validates YAML schema, ${{ }} expression contexts (needs.*, steps.*),
# and embedded bash via shellcheck. Zero output = pass.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Path-filtered required workflows | Always-on workflow + aggregate required gate with skipped→success transform | GitHub required-check guidance (stable) | Phase 120 follows current best practice; no change needed |
| `actions/cache` v3/v4 generic keys | v5.0.5 with tightly-scoped keys + `cache-hit` output | action v5 line | Repo already on v5.0.5 SHA-pinned; D-05/D-06 tighten keys |
| Broad `**/mix.lock` hashing | Lane-scoped lockfile hashing where the lane builds one package | this phase (D-06) | Reduces spurious cache invalidation |

**Deprecated/outdated:** Nothing in this phase relies on deprecated actions. All actions are current SHA-pinned versions.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub Actions cache store evicts unreferenced entries on its standard ~7-day policy, so old-key entries need no manual purge after D-05/D-06. | Runtime State Inventory | LOW — even if retained, old keys are simply unreferenced; worst case is slightly more cache storage, no correctness impact. [ASSUMED] (GitHub cache eviction policy from training; not re-verified live this session) |
| A2 | `examples/demo/backend/mix.lock` is not built by any `ci.yml` lane (only `scripts/demo/*` paths build it). | Pitfall 1 / D-06 | LOW — verified no `ci.yml` cache `path:` references the demo backend; if a future lane adds it, scoping reasoning would need revisiting. Backed by reading all cache `path:` blocks. |

**Note:** The four-vs-three mix.lock count is `[VERIFIED]`, not assumed (`find` output). It is logged as a CONTEXT drift in Pitfall 1, not an assumption.

## Open Questions

1. **Should `adopter-contract` and `test`/`mounted` keys be scoped to the two built lockfiles (`rulestead/mix.lock` + `rulestead_admin/mix.lock`) instead of `**/mix.lock`?**
   - What we know: These lanes build both sibling packages, so both locks are correctness-relevant; the demo backend + openfeature locks are not. Narrowing to the two-lock set would be correctness-safe AND remove spurious busting.
   - What's unclear: CONTEXT D-06 says "treat per-package scoping for test/adopter/mounted as 'tighten where correctness-safe'; defer any change that risks under-invalidation." A two-lock scope is arguably correctness-safe, but a single-lock scope is NOT.
   - Recommendation: SAFE to narrow these to `hashFiles('rulestead/mix.lock','rulestead_admin/mix.lock','.tool-versions')` (explicitly enumerate both built locks). This honors D-06 without under-invalidation risk. If the planner prefers maximum caution, leaving `**/mix.lock` is also compliant. Either is defensible; the planner has discretion (D-06 + Planner Discretion).

2. **Where to place the per-cache busting-rule docs (D-07): MAINTAINING.md vs inline workflow comments?**
   - What we know: MAINTAINING.md already has a "CI caching" section (`:54-63`) that is the natural home; the job-id-contract comment block at `ci.yml:1-3` shows inline comments are an established pattern too.
   - Recommendation: Planner discretion (explicitly granted). A short table in MAINTAINING.md "CI caching" plus a one-line comment above each cache key is the most discoverable; either alone satisfies D-07.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `actionlint` | Validating ci.yml edits offline (Validation Architecture) | ✓ | 1.7.12 (homebrew) | `docker run rhysd/actionlint` or the PR `actionlint` check on a workflow-path PR |
| `bash` | Running `release_gate.sh`/`test.sh`/`lint.sh` locally | ✓ | system | — |
| `git` | repo ops | ✓ | system | — |
| `gh` (read-only) | Confirming live branch-protection 404 for D-11 docs (read, never write) | ✓ (used in audit) | — | Audit already captured the 404; re-query optional, NOT required |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None blocking — full Elixir/Mix toolchain and Postgres are only needed to run the actual test lanes, which is NOT required to validate this phase's edits (validation is `actionlint` + `release_gate.sh` arg tests + static cache-key reasoning + doc review).

## Validation Architecture

> nyquist_validation treated as enabled (no `.planning/config.json` override read; default = on).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None traditional — this phase is validated by static workflow linting + shell-script behavior assertions + doc-vs-source reconciliation. The repo's ExUnit/`mix test` suite is NOT the proof surface for CI-YAML edits. |
| Config file | `.github/workflows/ci.yml` (the artifact under test); `actionlint` has no config file (uses defaults) |
| Quick run command | `actionlint .github/workflows/ci.yml` |
| Full suite command | `actionlint .github/workflows/*.yml && bash scripts/ci/release_gate.sh --skip-phase7 <pairs...>` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CIDX-04 | Edited `ci.yml` is valid YAML + valid expression contexts after D-03 wiring | static lint | `actionlint .github/workflows/ci.yml` | ✅ (tool present) |
| CIDX-04 | `release_gate.sh` fails iff any pair (incl. new `openfeature-companion`) is non-success | unit (shell) | `bash scripts/ci/release_gate.sh --skip-phase7 ...success... ; echo $?` (expect 0) and with one `=failure` (expect 1) | ✅ (script present) |
| CIDX-04 | openfeature skipped→success transform only when not relevant | reasoning + manual trace of `ci.yml:307-323` edited block | code review against the mounted-proof precedent (`:321-323`) | ✅ N/A automated; trace required |
| CIDX-07 | All cache keys remain correctness-safe (OS/OTP/Elixir/lock/.tool-versions/scope) | static reasoning over key components | review each `key:`/`restore-keys:` against the built `path:` for that lane | ✅ inventory in this doc |
| CIDX-07 | Each cache has a documented busting rule | doc presence check | `grep -A30 'CI caching' MAINTAINING.md` shows per-cache rule (after D-07 edit) | ✅ (MAINTAINING.md present) |
| CIDX-07 | Observability emits versions + cache posture + rerun command | run-step inspection / `$GITHUB_STEP_SUMMARY` lines present in diff | review added summary lines; optionally run `scripts/ci/test.sh` locally | ✅ scripts present |
| CIDX-09 | No regression in pins/permissions/publish gating/post-publish | diff assertion (no changes to protected surfaces) | `git diff --name-only` must NOT include `publish-hex.yml`, `verify-published-release.yml`, `dependabot.yml`; SHA pins in `ci.yml` unchanged | ✅ |

### Sampling Rate
- **Per task commit:** `actionlint .github/workflows/ci.yml` (sub-second).
- **Per wave merge:** `actionlint .github/workflows/*.yml` + `release_gate.sh` arg-matrix (success-all and one-failure cases).
- **Phase gate:** all of the above green + `git diff` confirms no protected-surface (D-09/D-10) regression + MAINTAINING.md triad reconciled before `/gsd:verify-work`.

### Wave 0 Gaps
- None requiring new test infrastructure. `actionlint` is installed; `release_gate.sh` is directly executable with `--skip-phase7`. Optional: a tiny shell snippet in the plan that runs the success-all and one-failure `release_gate.sh` invocations as an explicit verification step (no new file strictly required).
- If a maintainer wants the openfeature wiring proved against a real skipped run, that requires a live PR — out of scope for offline validation; the script unit-behavior + actionlint + pattern-mirror is the accepted proof per the phase's no-live-merge posture.

## Security Domain

> `security_enforcement` treated as enabled (no explicit `false`). This phase is supply-chain-preservation-heavy (CIDX-09), so the relevant controls are SLSA/supply-chain, not app-layer ASVS.

### Applicable ASVS-equivalent categories

| Category | Applies | Standard Control (current baseline — PRESERVE) |
|----------|---------|-----------------------------------------------|
| V1 Architecture / supply chain | yes | Full-SHA action pinning on every `uses:` [VERIFIED ci.yml]; least-privilege `permissions:` per workflow |
| V6 Cryptography / secrets | yes | `HEX_API_KEY` exposed only inside `publish-hex.yml` publish jobs behind protected `hex-publish` environment approval [VERIFIED publish-hex.yml:169-170,185,219] |
| V5 Input validation | n/a | No user input surface in this phase |
| Release integrity | yes | `gate-ci-green` requires green CI on tagged SHA; core-before-admin order (`publish-admin needs publish-core`); `admin_publish_guard.sh`; post-publish `verify_published_release.sh` [VERIFIED publish-hex.yml] |

### Known threat patterns for GitHub Actions CI

| Pattern | STRIDE | Standard Mitigation (status) |
|---------|--------|------------------------------|
| Mutable action tags (supply-chain tampering) | Tampering | Full-SHA pins — PRESERVE, do not convert to tags (D-10) |
| Over-privileged `GITHUB_TOKEN` | Elevation of Privilege | Narrow `permissions:` blocks — PRESERVE; do not broaden (D-10) |
| Secret exfiltration via untrusted PR | Information Disclosure | `HEX_API_KEY` gated behind protected environment; never in `ci.yml` — PRESERVE (D-09) |
| Tag-only / local publish trust | Spoofing | `gate-ci-green` on tagged SHA + protected approval — PRESERVE (D-09) |
| Required-check bypass via Pending trap | (availability/trust) | Always-on aggregate gate, no path filters — ENFORCE (D-01/D-02) |

**Net:** Phase 120 adds NO new attack surface. The security task is *non-regression*: assert via `git diff` that no protected workflow, pin, permission, or secret boundary weakened.

## Sources

### Primary (HIGH confidence)
- `.github/workflows/ci.yml` (full read, 332 lines) — every edit target, verified line numbers
- `.github/workflows/publish-hex.yml` (grep of trust anchors) — preserve-only surfaces (D-09)
- `.github/workflows/actionlint.yml`, `pr-title.yml`, `dependency-review.yml` (read) — path-filter + triad reconciliation (D-11)
- `scripts/ci/release_gate.sh` (full read) — confirms no script change for D-03
- `scripts/ci/test.sh`, `scripts/ci/lint.sh` (full read) — observability hooks + single-package lint scope (D-06/D-08)
- `MAINTAINING.md` (full read) — branch-protection doc (`:32-52`), CI caching section (`:54-63`), proof-bar boundaries
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` (full read) — decision ledger, cache table, live 404 evidence
- `find . -name mix.lock` + `diff -q` + `head` — FOUR distinct lockfiles (CONTEXT drift)
- `actionlint --version` — 1.7.12 installed (validation tool)
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` — Phase 120 success criteria, CIDX-04/07/09

### Secondary (MEDIUM confidence)
- `.github/dependabot.yml` (partial read) — Dependabot coverage preserve-only (D-10)

### Tertiary (LOW confidence)
- GitHub required-status-check Pending-trap behavior — cited to official docs (carried from audit): https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks

## Metadata

**Confidence breakdown:**
- Edit targets / line numbers: HIGH — every target read directly from current source; CONTEXT line refs confirmed accurate.
- Required-check semantics (D-03 safety): HIGH — mirrors a shipped pattern (`ci.yml:321-323`); `release_gate.sh` behavior read directly.
- Cache correctness: HIGH — lane build scopes verified against cache `path:` blocks; four-lockfile finding verified.
- Release/supply-chain preserve list: HIGH — trust anchors verified in `publish-hex.yml`.
- Live branch-protection state: MEDIUM — relies on audit's 2026-06-15 `gh api` 404 capture; D-11 is docs-only so freshness is non-blocking.

**CONTEXT drift flagged:** "three mix.lock files" → actually FOUR (adds `examples/demo/backend/mix.lock`). Strengthens D-06; does not invalidate any decision.

**Research date:** 2026-06-16
**Valid until:** 2026-07-16 (stable CI surface; re-verify only if `ci.yml` or lockfile set changes)

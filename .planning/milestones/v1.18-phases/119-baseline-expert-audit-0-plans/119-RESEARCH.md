# Phase 119: Baseline + Expert Audit - Research

**Researched:** 2026-06-15
**Domain:** GitHub Actions CI/CD audit, Elixir/Mix/ExUnit diagnostics, release engineering, supply-chain posture, contributor DX
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Audit Shape
- **D-01:** Produce one integrated `119-CI-CD-AUDIT.md`, not split topical docs. It should be the decision ledger for Phases 120-123.
- **D-02:** Structure the audit around: executive recommendation, workflow/job inventory, required-check semantics, critical path and metrics baseline, cache/PLT posture, test/check classification matrix, rerun command catalog, failure categories with maintainer microcopy, no-go/rollback guardrails, and handoff notes.
- **D-03:** Use `keep`, `optimize`, `move`, `quarantine/fix`, and `delete/rewrite` as the classification vocabulary for major checks and test categories. Every non-keep recommendation needs evidence.

### Workflow Topology
- **D-04:** Treat the current always-triggered `ci.yml` plus single aggregate `release_gate` as the baseline to preserve unless Phase 119 proves a safer replacement.
- **D-05:** Do not recommend workflow-level path filters for required PR checks. Path selectivity belongs inside always-reporting workflows or behind an aggregate required check to avoid pending/skipped-check traps.
- **D-06:** Phase 119 should explicitly audit whether `openfeature-companion` belongs in the required `release_gate` dependency list, because it is path-gated today but protects a named proof bar.
- **D-07:** Keep actionlint/repo hygiene/dependency/release workflows in the inventory even when they are not branch-protection required checks; the audit should explain which signals block merges, which are advisory, and which protect release posture.

### Release and Supply Chain
- **D-08:** Preserve the linked-version sibling-package release design: Release Please creates the release intent, `publish-hex` remains protected, core publishes before admin, and post-publish verification remains a blocker.
- **D-09:** Do not introduce local publish shortcuts, admin standalone publish preparation, tag-only publish trust, weaker permissions, weaker action pinning, or unchecked Hex secret exposure.
- **D-10:** Phase 119 should inspect action pinning, workflow permissions, dependency review, Dependabot coverage, Hex package preflight, cache restore breadth, and post-publish proof as release-trust surfaces, not just speed surfaces.

### Mix, ExUnit, Dialyzer, and Ecto
- **D-11:** Baseline before tuning. Record `mix test --warnings-as-errors --slowest 25`, `mix test --warnings-as-errors --slowest-modules 25`, `mix test --profile-require time`, `mix compile.elixir --force --profile time`, xref cycle/connected-graph outputs, and scheduler count.
- **D-12:** Do not flip `async: true`, shard tests, demote Dialyzer, delete slow tests, or rewrite proof scopes in Phase 119. Later changes must be based on measured slow modules, unsafe shared-state inventory, and rerun simplicity.
- **D-13:** Treat Elixir/Phoenix/Ecto idioms as constraints: ExUnit async only for modules free of global app env mutation, DB ownership hazards, ports, filesystem/shared process state, logger/telemetry capture, or fake-store resets; Ecto sandbox and LiveView process ownership remain first-class correctness concerns.
- **D-14:** Keep Dialyzer as a trust gate unless Phase 119 proves a safe move with equivalent release confidence. Any PLT/cache recommendation must use correctness-safe keys across Elixir, OTP, OS, lockfiles, MIX_ENV, and package scope.

### Browser, Demo, Integration, and UI Evidence
- **D-15:** Audit browser/demo/integration proof by value and determinism, not runtime alone. Preserve high-value mounted admin, OpenFeature, adopter, demo, and release proof bars unless a narrower equivalent catches the same bug class.
- **D-16:** Do not hide flaky browser behavior behind blind retries. Flag the current Playwright `trace: on-first-retry` with `retries: 0` mismatch and prefer failure screenshots/reports/artifacts plus root-cause fixes or explicit quarantine.
- **D-17:** Keep generated browser screenshots and reports as ignored artifacts, not checked-in pixel baselines. Current brandbook/design-system artifacts win over older prompt references when they differ.
- **D-18:** Keep FleetDesk host-branded in evidence and examples. Do not turn CI/CD work into product UI, brand, or design-system expansion.

### Contributor DX and Failure Triage
- **D-19:** Keep scripts-first CI as the contributor-facing abstraction. Workflow YAML should call understandable repo scripts where practical; failure output should point to exact local rerun commands.
- **D-20:** Use maintainer-friendly failure microcopy: what failed, what boundary it protects, exact rerun command, likely remediation, and when to stop rather than bypass.
- **D-21:** Prefer simple, reproducible local loops over clever CI topology. Broader partitioning, larger runners, richer reports, and browser binary caching remain future or later-phase options until Phase 119 evidence justifies them.

### the agent's Discretion
- The planner may choose the exact table layout and ordering inside `119-CI-CD-AUDIT.md` if all required audit categories remain present.
- The planner may add additional low-cost diagnostic commands when they strengthen the baseline without changing behavior.
- The planner may group similar low-signal checks together for readability, but must keep enough detail for Phase 120-123 implementation choices.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Implementing workflow topology or cache changes is Phase 120.
- Changing ExUnit async, test partitioning, test value cleanup, or Dialyzer placement is Phase 121.
- Fixing/quarantining browser/demo flake sources or changing Playwright evidence behavior is Phase 122.
- Updating contributor-facing docs and closeout metrics is Phase 123.
- Larger runners, broad test partitioning, richer reports, and browser binary caching remain future/later-phase options unless Phase 119 evidence justifies them.
</user_constraints>

<phase_requirements>
## Phase Requirements

No explicit requirement ID list was supplied by the orchestrator. The phase scope maps to roadmap requirements CIDX-01, CIDX-02, and CIDX-03 from `.planning/REQUIREMENTS.md`. [VERIFIED: `.planning/REQUIREMENTS.md`]
</phase_requirements>

## Summary

Phase 119 should produce a single evidence-backed `119-CI-CD-AUDIT.md` and should not edit workflow behavior, test behavior, release trust, product runtime APIs, schemas, or package publish posture. [VERIFIED: `119-CONTEXT.md`] The audit must combine static repo inventory, live GitHub Actions metadata, and local Mix/ExUnit diagnostics so later phases can optimize from measurements rather than intuition. [VERIFIED: `.planning/ROADMAP.md`, `.github/workflows/ci.yml`, `mix help test`]

The current CI baseline is GitHub Actions with an always-triggered `ci.yml`, job-level docs/path selectivity, and a required-style aggregate `release_gate`; current live GitHub API inspection reports `main` branch protection as absent, which conflicts with `MAINTAINING.md` branch-protection documentation and must be captured as a docs-vs-live finding. [VERIFIED: `.github/workflows/ci.yml`, `MAINTAINING.md`, `gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks`]

**Primary recommendation:** Plan Phase 119 as one documentation/audit plan that inventories every workflow/script/proof bar, collects recent run/job timings through `gh`, runs the locked Mix diagnostics, classifies checks with the locked vocabulary, and writes no behavior-changing code. [VERIFIED: `119-CONTEXT.md`, `gh run list`, `mix help test`]

## Project Constraints (from AGENTS.md)

- Rulestead is a sibling-package monorepo with `rulestead/` and `rulestead_admin/`. [VERIFIED: `AGENTS.md`]
- `.planning/` and `prompts/` are ground truth inputs for roadmap, state, requirements, phase context, anchor docs, and inherited engineering DNA. [VERIFIED: `AGENTS.md`]
- Respect the current phase boundary from `.planning/ROADMAP.md`. [VERIFIED: `AGENTS.md`]
- Keep Phase 8-only docs absent until the roadmap says they ship. [VERIFIED: `AGENTS.md`]
- Do not publish or prepare to publish the `rulestead_admin` stub. [VERIFIED: `AGENTS.md`]
- Keep edits aligned with the linked-version, two-package release design. [VERIFIED: `AGENTS.md`]
- Before `/gsd-execute-phase`, Cursor should select Auto so bulk implementation subagents inherit Auto. [VERIFIED: `AGENTS.md`]
- Make the smallest coherent change, avoid speculative future-phase features, and preserve reproducibility and CI readability. [VERIFIED: `AGENTS.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Workflow/job inventory | CI/CD | Repository scripts | Workflow YAML owns triggers, job graph, permissions, caches, and branch-check naming; scripts provide executable lane bodies. [VERIFIED: `.github/workflows/ci.yml`, `scripts/ci/*.sh`] |
| Required-check semantics | CI/CD | GitHub repository settings | Required checks are enforced by GitHub branch protection, while YAML determines whether statuses exist, skip, or aggregate. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks] |
| Mix/ExUnit diagnostics | Elixir package | CI/CD | `mix test`, `mix compile.elixir`, and `mix xref` expose the measurements; CI only schedules and records them. [VERIFIED: `mix help test`, `mix help compile.elixir`, `mix help xref`] |
| Cache/PLT posture | CI/CD | Elixir package | GitHub Actions cache keys restore/save dependency and PLT directories; Dialyxir/Mix configuration determines whether restored PLTs are valid. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching; CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Release trust | CI/CD | Hex/package scripts | Release Please, `publish-hex`, protected environment approval, preflight scripts, and post-publish verification form the trust chain. [VERIFIED: `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`, `.github/workflows/verify-published-release.yml`, `MAINTAINING.md`] |
| Browser/demo proof | Demo runtime | CI/CD | Docker Compose, Next.js/Playwright, and demo scripts produce proof artifacts; CI invokes them and records status. [VERIFIED: `scripts/demo/verify.sh`, `examples/demo/frontend/playwright.config.ts`] |
| Contributor rerun DX | Repository scripts | Documentation | The project already exposes script-first local commands, and Phase 119 should catalog exact reruns and failure microcopy. [VERIFIED: `scripts/ci/local.sh`, `scripts/ci/contributor.sh`, `MAINTAINING.md`] |

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GitHub Actions | Hosted service | CI/CD workflow execution, branch checks, release workflows, scheduled hygiene | Existing project platform and official source for required-check, cache, permissions, concurrency, and summary semantics. [VERIFIED: `.github/workflows/*.yml`; CITED: https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions] |
| `gh` CLI | 2.94.0 local | Live workflow/run/job inventory and branch-protection API checks | Authenticated locally with `repo` and `workflow` scopes, so the audit can collect live metadata. [VERIFIED: `gh --version`, `gh auth status`] |
| Elixir/Mix | Local 1.19.5; CI matrix 1.17.3/1.19.2 | Test, compile, xref, docs, package and release diagnostics | Existing package toolchain; local version is suitable for diagnostics, while CI matrix versions remain the workflow truth. [VERIFIED: `elixir --version`, `.tool-versions`, `.github/workflows/ci.yml`] |
| Erlang/OTP | Local 28; CI matrix 26.2.5/28.4.3 | BEAM runtime and scheduler baseline | Scheduler count and OTP version affect ExUnit parallelism, compile behavior, and PLT validity. [VERIFIED: `erl`, `.github/workflows/ci.yml`] |
| Dialyxir/Dialyzer | `~> 1.4` | Type analysis and PLT cache surface | Existing `lint.sh` trust gate; Dialyxir documents CI PLT cache behavior. [VERIFIED: `rulestead/mix.exs`, `scripts/ci/lint.sh`; CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Playwright | `@playwright/test` `^1.56.1` | Browser/demo evidence | Existing demo proof runner; current config has `trace: "on-first-retry"` and `retries: 0`, which means trace capture will not happen without a retry. [VERIFIED: `examples/demo/frontend/package.json`, `examples/demo/frontend/playwright.config.ts`; CITED: https://playwright.dev/docs/trace-viewer] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Docker Compose | Docker 29.5.2 local | Compose-backed FleetDesk/browser proof | Required to reproduce `scripts/demo/verify.sh` and classify integration runtime/determinism. [VERIFIED: `docker --version`, `scripts/demo/verify.sh`] |
| Node/npm | Node 22.14.0 local; CI uses Node 22 | Frontend dependency install and Playwright execution | Use for demo/frontend inventory and Playwright proof timing. [VERIFIED: `node --version`, `.github/workflows/ci.yml`] |
| `jq`/`yq` | Local CLIs | JSON/YAML summarization | Use for deterministic audit tables from GitHub API and workflow YAML. [VERIFIED: local `command -v jq yq`] |
| `rg` | Local CLI | Fast source inventory | Use for scripts/test-scope/workflow surface discovery. [VERIFIED: local `command -v rg`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Live `gh` API inventory | Static YAML-only audit | Static-only misses live branch protection and recent run timing; use static YAML as source-of-truth for definitions and `gh` for live state. [VERIFIED: `.github/workflows/*.yml`, `gh run list`] |
| Single `119-CI-CD-AUDIT.md` | Split audit docs | Split docs contradict the locked phase decision and make Phases 120-123 harder to trace. [VERIFIED: `119-CONTEXT.md`] |
| GitHub UI manual timing | `gh run list`/`gh run view --json jobs` | Manual UI timing is harder to reproduce; `gh` output can be pasted into the audit. [VERIFIED: `gh run view 27542317576 --json jobs`] |

**Installation:** No external package installation is required for Phase 119 research or planning; use existing repo tools and local CLIs. [VERIFIED: local environment audit]

## Architecture Patterns

### System Architecture Diagram

```text
Repo sources + live GitHub metadata
        |
        v
Static inventory: workflows, job IDs, triggers, permissions, caches, scripts
        |
        +--> Branch/check semantics audit
        |       |
        |       v
        |   required vs advisory vs release-only signals
        |
        +--> Metrics baseline
        |       |
        |       v
        |   recent run/job timings + critical path + cache posture
        |
        +--> Mix diagnostics
        |       |
        |       v
        |   slowest tests/modules + require profile + compile profile + xref + schedulers
        |
        +--> Test/check classification
                |
                v
        keep / optimize / move / quarantine-fix / delete-rewrite
                |
                v
        119-CI-CD-AUDIT.md -> evidence for Phases 120, 121, 122, 123
```

### Recommended Project Structure

```text
.planning/phases/119-baseline-expert-audit-0-plans/
├── 119-CONTEXT.md       # locked decisions from discuss phase [VERIFIED: repo]
├── 119-RESEARCH.md      # planner-facing research artifact [VERIFIED: current phase]
└── 119-CI-CD-AUDIT.md   # implementation output; single audit ledger [VERIFIED: 119-CONTEXT.md]
```

### Pattern 1: Static Plus Live Inventory

**What:** Inventory workflow definitions from `.github/workflows/*.yml`, then verify live workflow state, recent runs, job timings, and branch protection through `gh`. [VERIFIED: `.github/workflows/*.yml`, `gh workflow list`, `gh run list`]

**When to use:** Always for Phase 119; static YAML and live GitHub settings can drift. [VERIFIED: `MAINTAINING.md`, live branch-protection API 404]

**Example:**

```bash
gh workflow list --repo szTheory/rulestead --all --json name,path,state,id
gh run list --repo szTheory/rulestead --workflow ci.yml --limit 10 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch
gh run view <run-id> --repo szTheory/rulestead --json jobs,createdAt,updatedAt,conclusion,event,workflowName
gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks
```

Source: GitHub CLI live repo access and GitHub REST branch-protection endpoint. [VERIFIED: `gh` commands; CITED: https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection]

### Pattern 2: Always-Reporting Aggregate Gate

**What:** Keep required-check selectivity inside jobs or an aggregate check, not at workflow trigger level. [VERIFIED: `119-CONTEXT.md`; CITED: GitHub required-check troubleshooting docs]

**When to use:** Any path-selective proof bar that may be required or semantically blocking. [VERIFIED: `.github/workflows/ci.yml`]

**Example:**

```yaml
release_gate:
  needs:
    - changes
    - lint
    - test
    - integration-placeholder
    - adopter-contract
    - mounted-proof
  if: always()
```

Source: existing `ci.yml`; GitHub documents that workflow-level path filtering can leave required checks pending, while skipped jobs can report success. [VERIFIED: `.github/workflows/ci.yml`; CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

### Pattern 3: Baseline Before Tuning

**What:** Run diagnostic commands first and treat their output as the basis for later optimization plans. [VERIFIED: `119-CONTEXT.md`]

**When to use:** Any recommendation to optimize, move, quarantine, or delete/rewrite a check. [VERIFIED: `119-CONTEXT.md`]

**Example:**

```bash
cd rulestead
mix test --warnings-as-errors --slowest 25
mix test --warnings-as-errors --slowest-modules 25
mix test --profile-require time
mix compile.elixir --force --profile time
mix xref graph --format cycles --label compile-connected
mix xref graph --format stats --label compile-connected
erl -noshell -eval 'io:format("~p~n", [erlang:system_info(schedulers_online)]), halt().'
```

Source: locked phase decision and local Mix task help. [VERIFIED: `119-CONTEXT.md`, `mix help test`, `mix help compile.elixir`, `mix help xref`]

### Anti-Patterns to Avoid

- **Workflow-level path filters on required checks:** They can leave a PR blocked with a pending required check. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]
- **Retrying browser failures blindly:** Current Playwright config has no retries, so `on-first-retry` traces will not be produced; retries also belong to a later determinism phase unless evidence justifies them. [VERIFIED: `examples/demo/frontend/playwright.config.ts`; CITED: https://playwright.dev/docs/trace-viewer]
- **Classifying by runtime alone:** Slow but high-value release/adopter/mounted/OpenFeature proof bars are preserved unless a narrower equivalent catches the same bug class. [VERIFIED: `119-CONTEXT.md`]
- **Changing ExUnit async/sharding in the audit phase:** Phase 119 gathers evidence only; async/partitioning moves are Phase 121. [VERIFIED: `119-CONTEXT.md`, `.planning/ROADMAP.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workflow/run inventory | Custom scraper over Actions HTML | `gh workflow list`, `gh run list`, `gh run view --json` | Official CLI/API output is reproducible and scriptable. [VERIFIED: local `gh` commands] |
| Cache semantics | Custom cache restore logic | `actions/cache`, `actions/cache/restore`, `actions/cache/save` | GitHub cache has documented key and restore-key semantics. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching] |
| PLT cache policy | Ad hoc PLT copying | Dialyxir documented PLT caching pattern | Dialyxir documents split restore/save to preserve cache even when Dialyzer fails. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Mix timing | Custom test runner | `mix test --slowest`, `--slowest-modules`, `--profile-require`, `mix compile.elixir --profile time` | Mix already exposes the diagnostic dimensions needed for this phase. [VERIFIED: `mix help test`, `mix help compile.elixir`] |
| Workflow summaries | Custom external dashboard | `$GITHUB_STEP_SUMMARY` where later phases add reporting | GitHub Actions job summaries are built into workflow runs. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands] |

**Key insight:** Phase 119 should measure and classify existing trust surfaces, not create new orchestration machinery. [VERIFIED: `119-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Static Docs Disagree With Live GitHub Settings

**What goes wrong:** `MAINTAINING.md` can document required checks while the GitHub API reports no branch protection on `main`. [VERIFIED: `MAINTAINING.md`, live `gh api`]

**Why it happens:** Branch protection is external repository state, not version-controlled YAML. [CITED: https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection]

**How to avoid:** Include both documented branch protection and live API results in `119-CI-CD-AUDIT.md`. [VERIFIED: `MAINTAINING.md`, `gh api`]

**Warning signs:** Required-check tables copied from docs without `gh api` evidence. [VERIFIED: local research finding]

### Pitfall 2: Path-Gated Proof Bar Missing From Aggregate Gate

**What goes wrong:** A path-gated proof can be visible and valuable but not actually gate merges unless the aggregate job depends on and normalizes it. [VERIFIED: `.github/workflows/ci.yml`]

**Why it happens:** Job-level `if` conditions skip jobs; aggregation must decide whether skipped means acceptable for the changed paths. [CITED: https://docs.github.com/actions/using-jobs/using-jobs-in-a-workflow]

**How to avoid:** Audit `release_gate.needs` and normalization logic, including the locked question of whether `openfeature-companion` belongs in the dependency list. [VERIFIED: `119-CONTEXT.md`, `.github/workflows/ci.yml`]

**Warning signs:** A named proof bar exists in `scripts/ci/test.sh` and `MAINTAINING.md` but is absent from `release_gate.needs`. [VERIFIED: `.github/workflows/ci.yml`, `scripts/ci/test.sh`, `MAINTAINING.md`]

### Pitfall 3: Unsafe Cache Restore Breadth

**What goes wrong:** Broad restore keys can restore stale build or PLT artifacts across incompatible Elixir, OTP, OS, lockfile, environment, or package boundaries. [VERIFIED: `119-CONTEXT.md`; CITED: GitHub cache docs]

**Why it happens:** GitHub restore keys search prefix matches from most-specific to least-specific, so broad fallbacks can pull older caches. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching]

**How to avoid:** Audit every cache path/key/restore-key against package, OS, OTP, Elixir, `.tool-versions`, lockfile, and `MIX_ENV`. [VERIFIED: `.github/workflows/ci.yml`, `.tool-versions`]

**Warning signs:** Restore keys ending at `${{ runner.os }}-mix-` for package-specific build caches without an explicit risk note. [VERIFIED: `.github/workflows/ci.yml`]

### Pitfall 4: Misreading Playwright Trace Coverage

**What goes wrong:** The audit could claim trace artifacts exist for browser failures when current config only traces on first retry and retries are disabled. [VERIFIED: `examples/demo/frontend/playwright.config.ts`]

**Why it happens:** Playwright's `trace: "on-first-retry"` expects at least one retry in CI. [CITED: https://playwright.dev/docs/trace-viewer]

**How to avoid:** Record this as an evidence mismatch and defer behavior changes to Phase 122. [VERIFIED: `119-CONTEXT.md`, `.planning/ROADMAP.md`]

**Warning signs:** Failed browser runs with no trace zip despite `trace: "on-first-retry"`. [VERIFIED: `examples/demo/frontend/playwright.config.ts`; CITED: Playwright docs]

## Code Examples

### Recent CI Critical Path Collection

```bash
gh run list --repo szTheory/rulestead --workflow ci.yml --limit 10 \
  --json databaseId,conclusion,createdAt,updatedAt,event,headBranch

gh run view <run-id> --repo szTheory/rulestead \
  --json jobs,createdAt,updatedAt,conclusion,event,workflowName
```

Source: GitHub CLI against live repo. [VERIFIED: `gh run list`, `gh run view`]

### Required-Check Live Verification

```bash
gh api repos/szTheory/rulestead/branches/main/protection/required_status_checks
```

Source: GitHub REST branch protection API; current result during research was `Branch not protected` for `main`. [VERIFIED: live `gh api`; CITED: https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection]

### Mix Diagnostic Baseline

```bash
cd rulestead
mix test --warnings-as-errors --slowest 25
mix test --warnings-as-errors --slowest-modules 25
mix test --profile-require time
mix compile.elixir --force --profile time
mix xref graph --format cycles --label compile-connected
mix xref graph --format stats --label compile-connected
```

Source: Mix task help confirms these options exist in the local toolchain. [VERIFIED: `mix help test`, `mix help compile.elixir`, `mix help xref`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Required workflow with path filters | Always-reporting workflow or aggregate required check with job-level selectivity | Current GitHub docs as checked 2026-06-15 | Avoids PRs stuck on pending required checks. [CITED: GitHub required-check troubleshooting docs] |
| Tag-pinned third-party actions | Full-length SHA pinning with Dependabot updates | Current GitHub secure-use docs as checked 2026-06-15 | Improves supply-chain immutability while keeping update automation. [CITED: https://docs.github.com/en/actions/reference/security/secure-use; VERIFIED: `.github/dependabot.yml`] |
| Monolithic `actions/cache` only | Split restore/save for Dialyzer PLTs where failure should still preserve cache | Dialyxir GitHub Actions docs as checked 2026-06-15 | Avoids losing PLT cache when Dialyzer fails. [CITED: https://hexdocs.pm/dialyxir/github_actions.html] |
| Browser trace assumed present | Trace tied to retry policy and artifact retention | Playwright docs as checked 2026-06-15 | `trace: on-first-retry` needs retries; with `retries: 0`, failure evidence must come from other artifacts. [CITED: https://playwright.dev/docs/trace-viewer; VERIFIED: `playwright.config.ts`] |

**Deprecated/outdated:**
- Treating path-filtered workflows as safe required checks is outdated for this repo because GitHub documents the pending-check trap. [CITED: GitHub required-check troubleshooting docs]
- Treating Playwright `on-first-retry` as useful with zero retries is ineffective. [CITED: Playwright trace viewer docs; VERIFIED: `playwright.config.ts`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Comparable OSS examples in local prompt anchors remain directionally relevant to Rulestead even though they are not live upstream repositories checked in this session. [ASSUMED] | Summary / Sources | Planner may overweight inherited patterns; mitigate by requiring repo-specific evidence for every non-keep recommendation. |

## Open Questions (RESOLVED)

1. **Is live branch protection intentionally disabled?**
   - Resolution: Phase 119 treats live branch protection as audit evidence, not as a Phase 119 implementation decision. The audit must record the documented-vs-live state: `MAINTAINING.md` documents required checks, while research-time `gh api .../branches/main/protection/required_status_checks` returned `Branch not protected`. [VERIFIED: `MAINTAINING.md`, live `gh api`]
   - Planning implication: Phase 119 must not change repository settings or workflow behavior. Later phases may use the audit row to decide whether docs, branch protection, or required-check topology need alignment. [VERIFIED: `119-CONTEXT.md`, `.planning/ROADMAP.md`]

2. **Should `openfeature-companion` join `release_gate.needs` later?**
   - Resolution: `openfeature-companion` membership in `release_gate.needs` is a Phase 120 recommendation candidate, not a Phase 119 change. Phase 119 records that the proof bar exists and is path-gated while current `release_gate.needs` excludes it. [VERIFIED: `.github/workflows/ci.yml`, `scripts/ci/test.sh`, `119-CONTEXT.md`]
   - Planning implication: The Phase 119 audit must classify the current signal and hand off any topology recommendation to Phase 120 with evidence; it must not edit `ci.yml`. [VERIFIED: `.planning/ROADMAP.md`]

3. **How much live timing sample is enough?**
   - Resolution: Enough Phase 119 baseline evidence is a recent representative `ci.yml` run sample plus the locked local Mix diagnostic commands from D-11. A 10-20 run sample is preferred when available; if CI access is unavailable or the sample is too small or heterogeneous for p95, the audit must record the fallback and state `p95 target unavailable from current sample`. [VERIFIED: `gh run list`, `119-CONTEXT.md`]
   - Planning implication: Phase 119 can complete with representative live timing plus local diagnostics, provided unavailable CI metadata, sample limitations, and fallback evidence are explicit in `119-CI-CD-AUDIT.md`. [VERIFIED: `.planning/ROADMAP.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `gh` | Live workflow/run/protection audit | yes | 2.94.0 | Static YAML audit only, but lower confidence. [VERIFIED: local `gh --version`] |
| GitHub auth | Live repo API | yes | Token scopes include `repo`, `workflow` | Use unauthenticated public data where possible, but branch protection may be unavailable. [VERIFIED: `gh auth status`] |
| Elixir/Mix | Mix diagnostics | yes | Elixir/Mix 1.19.5 local | Use CI logs only, but locked local diagnostics would be incomplete. [VERIFIED: local `elixir --version`, `mix --version`] |
| Erlang/OTP | Scheduler and PLT context | yes | OTP 28 local | Use `.tool-versions`/CI matrix only. [VERIFIED: local `erl`, `.tool-versions`] |
| Docker | Demo/browser proof reproduction | yes | Docker 29.5.2 | Audit scripts statically if daemon unavailable. [VERIFIED: local `docker --version`] |
| Node/npm | Frontend/Playwright inventory | yes | Node 22.14.0, npm 11.1.0 | Static package/config audit only. [VERIFIED: local `node --version`, `npm --version`] |
| `jq`/`yq` | JSON/YAML table extraction | yes | local installed | Use manual parsing. [VERIFIED: local `command -v`] |

**Missing dependencies with no fallback:** None for planning/audit writing. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Context7 CLI is absent; official docs were checked through web search and local tool help instead. [VERIFIED: `command -v ctx7`; CITED: official docs URLs in Sources]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Documentation/audit phase; no new runtime test framework required. Existing validation sources are `gh`, static file inspection, and Mix diagnostics. [VERIFIED: `119-CONTEXT.md`] |
| Config file | Existing `.github/workflows/*.yml`, `rulestead/mix.exs`, `rulestead_admin/mix.exs`, `examples/demo/frontend/playwright.config.ts`. [VERIFIED: repo files] |
| Quick run command | `gh run list --repo szTheory/rulestead --workflow ci.yml --limit 10 --json databaseId,conclusion,createdAt,updatedAt,event,headBranch` [VERIFIED: local command] |
| Full suite command | No behavior suite is required for an audit-only doc; full verification is review of `119-CI-CD-AUDIT.md` against CIDX-01..03 and the locked decisions. [VERIFIED: `.planning/ROADMAP.md`, `119-CONTEXT.md`] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CIDX-01 | Workflow/job/step baseline covers PR, main, scheduled, release, dependency, and hygiene workflows. [VERIFIED: `.planning/REQUIREMENTS.md`] | static + live audit | `gh workflow list --repo szTheory/rulestead --all --json name,path,state,id` | yes, workflows exist. [VERIFIED: `.github/workflows/*.yml`] |
| CIDX-02 | Critical path, duplicated work, cache behavior, runner CPU use, and bottlenecks are visible. [VERIFIED: `.planning/REQUIREMENTS.md`] | live metrics + local diagnostics | `gh run view <run-id> --json jobs`; Mix diagnostic commands from D-11 | partial; audit file to be created in Phase 119. [VERIFIED: `119-CONTEXT.md`] |
| CIDX-03 | Major tests/checks classified as keep/optimize/move/quarantine-fix/delete-rewrite with evidence. [VERIFIED: `.planning/REQUIREMENTS.md`] | documentation review | Review `119-CI-CD-AUDIT.md` classification matrix | no, target file not yet created. [VERIFIED: phase directory] |

### Sampling Rate

- **Per task commit:** Re-run the static inventory commands and confirm `119-CI-CD-AUDIT.md` contains the required sections. [VERIFIED: `119-CONTEXT.md`]
- **Per wave merge:** Re-run live `gh run list`/`gh run view` samples if the audit took long enough for CI state to change. [VERIFIED: `gh run list`]
- **Phase gate:** `119-CI-CD-AUDIT.md` must map CIDX-01, CIDX-02, and CIDX-03 to evidence and must not include implementation changes. [VERIFIED: `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`]

### Wave 0 Gaps

- [ ] `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` - target audit artifact for CIDX-01..03. [VERIFIED: `119-CONTEXT.md`]
- [ ] Live branch-protection evidence capture - needed because repo settings are external state. [VERIFIED: live `gh api`]
- [ ] Recent CI job timing sample table - needed for CIDX-02. [VERIFIED: `gh run list`, `gh run view`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct product-auth change | Audit only; preserve existing release workflow trust boundaries. [VERIFIED: `119-CONTEXT.md`] |
| V3 Session Management | no direct session change | Not in phase scope. [VERIFIED: `.planning/ROADMAP.md`] |
| V4 Access Control | yes, for CI/release permissions | Least-privilege workflow permissions, protected Hex environment, no unchecked secret exposure. [VERIFIED: `.github/workflows/*.yml`, `119-CONTEXT.md`; CITED: GitHub secure-use docs] |
| V5 Input Validation | yes, for workflow inputs | Audit `workflow_dispatch` inputs and shell interpolation in release workflows. [VERIFIED: `.github/workflows/publish-hex.yml`, `.github/workflows/verify-published-release.yml`] |
| V6 Cryptography | yes, for supply-chain immutability | Full-SHA action pinning; no custom crypto. [VERIFIED: `.github/workflows/*.yml`; CITED: https://docs.github.com/en/actions/reference/security/secure-use] |

### Known Threat Patterns for GitHub Actions / Hex Release

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Third-party action tag takeover | Tampering | Pin third-party actions to full commit SHAs and let Dependabot update actions. [CITED: GitHub secure-use docs; VERIFIED: `.github/workflows/*.yml`, `.github/dependabot.yml`] |
| Overbroad `GITHUB_TOKEN` permissions | Elevation of privilege | Set minimal `permissions` per workflow/job. [CITED: GitHub secure-use docs; VERIFIED: `.github/workflows/*.yml`] |
| Secret exposure during publish | Information disclosure | Keep `HEX_API_KEY` limited to protected publish jobs after approval. [VERIFIED: `.github/workflows/publish-hex.yml`, `MAINTAINING.md`] |
| Publishing unverified or wrong sibling version | Tampering | Preserve preflight linked-version checks, core-before-admin publish order, and post-publish verification. [VERIFIED: `.github/workflows/publish-hex.yml`, `scripts/ci/verify_published_release.sh`, `MAINTAINING.md`] |
| Required check bypass or pending trap | Tampering/Repudiation | Use always-reporting aggregate `release_gate` and audit live branch protection. [VERIFIED: `.github/workflows/ci.yml`; CITED: GitHub required-check troubleshooting docs] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/119-baseline-expert-audit-0-plans/119-CONTEXT.md` - locked Phase 119 decisions, boundaries, deferred work. [VERIFIED: repo]
- `.planning/REQUIREMENTS.md` - CIDX-01, CIDX-02, CIDX-03 mapping to Phase 119. [VERIFIED: repo]
- `.planning/ROADMAP.md` - Phase 119 success criteria and Phase 120-123 dependency chain. [VERIFIED: repo]
- `.planning/STATE.md` - milestone state, release-trust boundary, prior decisions. [VERIFIED: repo]
- `AGENTS.md` - project constraints and monorepo frame. [VERIFIED: repo]
- `.github/workflows/*.yml`, `.github/dependabot.yml` - workflow/job/cache/permission/release definitions. [VERIFIED: repo]
- `scripts/ci/*.sh`, `scripts/demo/verify.sh` - scripts-first CI lane bodies and proof commands. [VERIFIED: repo]
- `rulestead/mix.exs`, `rulestead_admin/mix.exs`, `examples/demo/frontend/package.json`, `examples/demo/frontend/playwright.config.ts` - package/test/browser config. [VERIFIED: repo]
- `mix help test`, `mix help compile.elixir`, `mix help xref` - local Mix diagnostics and options. [VERIFIED: local tool help]
- GitHub Docs: workflow syntax, required-check troubleshooting, cache dependency reference, secure use, workflow commands, jobs/needs behavior, branch protection API. [CITED: https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions; CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching; CITED: https://docs.github.com/en/actions/reference/security/secure-use; CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands; CITED: https://docs.github.com/actions/using-jobs/using-jobs-in-a-workflow; CITED: https://docs.github.com/rest/branches/branch-protection#get-status-checks-protection]
- HexDocs: Mix test, Ecto SQL Sandbox, Dialyxir GitHub Actions. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html; CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html; CITED: https://hexdocs.pm/dialyxir/github_actions.html]
- Playwright docs: trace viewer / trace on retry behavior. [CITED: https://playwright.dev/docs/trace-viewer]

### Secondary (MEDIUM confidence)

- Local prompt anchors: `prompts/rulestead-release-engineering-and-ci.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `prompts/rulestead-engineering-dna-from-prior-libs.md`, `prompts/rulestead-testing-and-e2e-strategy.md`, `prompts/rulestead-security-privacy-and-threat-model.md`, `prompts/rulestead-personas-jtbd-and-onboarding.md`, `prompts/rulestead-telemetry-observability-and-audit.md`. These are project-owned guidance rather than external authoritative docs. [VERIFIED: repo]

### Tertiary (LOW confidence)

- Comparable OSS patterns referenced by local prompt anchors were not independently revalidated against their upstream repositories in this session. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing repo files, local CLI versions, and official docs verify the tools. [VERIFIED: repo files, local commands, official docs]
- Architecture: HIGH - phase is audit-only and existing CI/scripts define clear ownership boundaries. [VERIFIED: `119-CONTEXT.md`, `.github/workflows/*.yml`, `scripts/ci/*.sh`]
- Pitfalls: HIGH - required-check/path-filter, cache restore, action pinning, Dialyxir PLT, and Playwright trace behavior were verified from official docs or existing config. [CITED: official docs; VERIFIED: repo files]

**Research date:** 2026-06-15
**Valid until:** 2026-06-22 for live GitHub Actions settings and run metrics; 2026-07-15 for stable Mix/GitHub/Playwright documentation patterns unless dependencies or workflows change. [ASSUMED]

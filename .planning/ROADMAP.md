# Roadmap: Rulestead

## Milestones

- ◆ **v1.18 CI/CD Reliability** — Phases 119-123 (active)
- ✅ **v1.17 Admin Design System Stress Test** — Phases 113-118 (shipped 2026-06-15)

## Phases

<details open>
<summary>◆ v1.18 CI/CD Reliability (Phases 119-123) — ACTIVE</summary>

- [ ] Phase 119: Baseline + Expert Audit (0/? plans)
- [ ] Phase 120: Workflow Topology + Cache Hygiene (0/3 plans)
- [ ] Phase 121: Mix/ExUnit Performance + Test Value Cleanup (0/? plans)
- [ ] Phase 122: Browser/Demo/Integration Determinism (0/? plans)
- [ ] Phase 123: DX + Closeout Proof (0/? plans)

</details>

<details>
<summary>✅ v1.17 Admin Design System Stress Test (Phases 113-118) — SHIPPED 2026-06-15</summary>

- [x] Phase 113: Design-System Inventory + UI Matrix Contract (3/3 plans) — completed 2026-06-13
- [x] Phase 114: Repo-Native Component Matrix Harness (2/2 plans) — completed 2026-06-14
- [x] Phase 115: Foundations Hardening (3/3 plans) — completed 2026-06-14
- [x] Phase 116: Primitive + Composite Polish (4/4 plans) — completed 2026-06-14
- [x] Phase 117: Page Flow + IA Pass (4/4 plans) — completed 2026-06-14
- [x] Phase 118: Evidence + Idempotence Guardrails (3/3 plans) — completed 2026-06-14

</details>

## Phase Details

### Phase 119: Baseline + Expert Audit

**Goal:** Produce a repo-specific CI/CD performance, reliability, security, and DX baseline before changing behavior.

**Requirements:** CIDX-01, CIDX-02, CIDX-03

**Success criteria:**

1. `119-CI-CD-AUDIT.md` inventories every workflow, trigger, job, matrix, service, cache, required-check role, command, and quality signal.
2. The audit records current critical path, duplicated work, likely bottlenecks, cache posture, runner CPU use, and missing metrics.
3. Mix/ExUnit diagnostics record slowest tests, require-time profile, compile profile, xref cycle/connected graphs, and scheduler count.
4. Major checks and test categories are classified as keep, optimize, move, quarantine/fix, or delete/rewrite with evidence.
5. Official docs and comparable Elixir OSS workflow patterns are summarized only where they apply to this repo.

### Phase 120: Workflow Topology + Cache Hygiene

**Goal:** Implement low-risk workflow, cache, required-check, and release/supply-chain improvements proven by Phase 119.

**Requirements:** CIDX-04, CIDX-07, CIDX-09

**Success criteria:**

1. `ci.yml` keeps a trustworthy `release_gate` aggregate and avoids required-check pending traps for docs-only or path-gated jobs.
2. Mix/build, Dialyzer PLT, and any Node/Playwright caches use correctness-safe keys, restore keys, and documented busting rules.
3. CI logs or summaries show versions, cache posture, and local reproduction commands for failed lanes where practical.
4. Release workflows still require green CI on the tagged SHA, protected Hex approval, package preflight, and post-publish verification.
5. Action pinning, permissions, Dependabot coverage, and secret exposure remain at least as strict as the current baseline.

**Plans:** 1/3 plans executed

Plans:
**Wave 1**

- [x] 120-01-PLAN.md — Wire openfeature-companion into release_gate (D-03) + supply-chain non-regression (D-09/D-10)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 120-02-PLAN.md — Cache hygiene: remove cross-lane fallback (D-05), scope lint/PLT keys (D-06), scripts-first observability (D-08)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 120-03-PLAN.md — Docs reconciliation: per-cache busting rules (D-07) + branch-protection triad/404 note (D-11)

### Phase 121: Mix/ExUnit Performance + Test Value Cleanup

**Goal:** Improve core Elixir test/runtime efficiency without hiding risk or making local reproduction harder.

**Requirements:** CIDX-06

**Success criteria:**

1. ExUnit modules are marked `async: true` only when proven free of unsafe global state, DB ownership, ports, filesystem, logger, telemetry, or app-env mutation.
2. Oversized serialized modules are split only when profiling shows meaningful concurrency benefit.
3. Test partitioning is either explicitly rejected with evidence or implemented with isolated DB/schema behavior and simple rerun commands.
4. `scripts/ci/test.sh` remains understandable and provides actionable failure categories for maintained proof scopes.
5. Before/after slowest-test and wall-clock notes are recorded in the phase summary.

### Phase 122: Browser/Demo/Integration Determinism

**Goal:** Stabilize expensive browser, demo, integration, and generated-evidence paths while keeping high-value workflow proof.

**Requirements:** CIDX-05

**Success criteria:**

1. Playwright, demo, UI matrix, FleetDesk, and integration scripts are audited for fixed ports, sleeps, shared state, artifact leakage, and flaky readiness checks.
2. Known transient browser/test behavior is fixed at root cause or quarantined with a clear follow-up, not hidden behind blind retries.
3. Generated screenshots and browser artifacts remain ignored artifacts, not checked-in baselines.
4. Low-signal or redundant browser/demo checks are rewritten, demoted, or removed only with explicit evidence.
5. Browser/demo failure output includes exact URLs, commands, and artifact paths needed for local reproduction.

### Phase 123: DX + Closeout Proof

**Goal:** Close the milestone with simple contributor commands, measurable impact, and rollback-ready documentation.

**Requirements:** CIDX-08, CIDX-10

**Success criteria:**

1. `MAINTAINING.md` and any contributor-facing docs match the final fast loop, full local gate, CI rerun commands, and release proof posture.
2. A concise CI failure triage table covers lint, test, mounted proof, OpenFeature proof, demo/Playwright, release publish, post-publish drift, and repo hygiene.
3. `123-CI-CD-CLOSEOUT.md` records before/after PR wall-clock, p95 target if available, cache hit rate, top slow tests, flake notes, residual risks, and rollback notes.
4. Final verification includes targeted changed lanes plus the agreed local/CI gates from the requirements.
5. Requirements traceability and `STATE.md` are updated before milestone closeout.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 119. Baseline + Expert Audit | v1.18 | 3/3 | Complete   | 2026-06-15 |
| 120. Workflow Topology + Cache Hygiene | v1.18 | 1/3 | In Progress|  |
| 121. Mix/ExUnit Performance + Test Value Cleanup | v1.18 | 0/? | Pending | — |
| 122. Browser/Demo/Integration Determinism | v1.18 | 0/? | Pending | — |
| 123. DX + Closeout Proof | v1.18 | 0/? | Pending | — |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CIDX-01 | Phase 119 | Pending |
| CIDX-02 | Phase 119 | Pending |
| CIDX-03 | Phase 119 | Pending |
| CIDX-04 | Phase 120 | Pending |
| CIDX-05 | Phase 122 | Pending |
| CIDX-06 | Phase 121 | Pending |
| CIDX-07 | Phase 120 | Pending |
| CIDX-08 | Phase 123 | Pending |
| CIDX-09 | Phase 120 | Pending |
| CIDX-10 | Phase 123 | Pending |

**Coverage:**

- v1.18 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

# Requirements: Rulestead v1.18 CI/CD Reliability

**Defined:** 2026-06-15
**Core Value:** Phoenix teams can safely gate, roll out, and explain runtime decisions -- booleans, variants, and remote config -- with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.

## v1.18 Requirements

### Baseline and Audit

- [x] **CIDX-01**: Maintainer can review a current workflow/job/step baseline covering PR, main, scheduled, release, dependency, and hygiene workflows.
- [x] **CIDX-02**: Maintainer can see the CI critical path, duplicated work, cache behavior, runner CPU use, and likely bottlenecks with before/after targets.
- [x] **CIDX-03**: Maintainer can classify each major test and check category as keep, optimize, move, quarantine/fix, or delete/rewrite based on quality signal and determinism.

### Gate Quality and Test Value

- [x] **CIDX-04**: PR gates remain trustworthy and deterministic while high-value adopter, release, mounted companion, and OpenFeature proof bars stay preserved.
- [ ] **CIDX-05**: Maintainer can fix, demote, rewrite, or remove the lowest-signal redundant or flaky checks only when the audit records concrete evidence.
- [ ] **CIDX-06**: Mix, ExUnit, Dialyzer, Playwright, demo, and release workflows use runner time efficiently without fragile over-sharding or hidden correctness risk.

### Cache, Release, and Supply Chain

- [x] **CIDX-07**: Maintainer can verify cache keys, restore keys, Dialyzer PLT handling, and cache observability are correctness-safe and documented.
- [x] **CIDX-09**: Release and supply-chain posture remains at least as strict as the current baseline: pinned actions, minimal permissions, gated Hex publish, and post-publish proof.

### Contributor DX and Closeout

- [ ] **CIDX-08**: Contributor commands remain simple: fast local loop, full local gate, and clear rerun commands for failed CI jobs.
- [ ] **CIDX-10**: Maintainer can review final before/after impact, including PR wall-clock, p95 target if available, cache hit rate, top slow tests, flake notes, residual risks, and rollback notes.

## Future Requirements

Deferred until a later milestone or until Phase 119 proves they are worth the added complexity.

### CI Infrastructure

- **FUT-01**: Maintainer can use broader test partitioning across CI workers if measured suite time justifies DB/schema isolation and added workflow complexity.
- **FUT-02**: Maintainer can move to larger GitHub-hosted runners if measured queue/runtime economics justify the cost.
- **FUT-03**: Maintainer can publish richer test reports or coverage artifacts if they improve failure triage without slowing the PR gate materially.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Product runtime APIs, schemas, migrations, or authored-state changes | v1.18 is CI/CD reliability and maintainer workflow work, not a product capability milestone. |
| `rulestead_admin` standalone publish preparation | The linked-version sibling-package release design remains unchanged. |
| Hiding risk to make PRs look faster | Conservative signal-first optimization preserves release trust over cosmetic speed. |
| Broad visual-baseline or snapshot infrastructure | v1.17 intentionally used generated artifacts and deterministic assertions instead of checked-in pixel baselines. |
| Deleting slow tests solely because they are slow | Slow tests are optimized, demoted, or removed only after value and redundancy are documented. |
| Fragile over-sharding or complex CI orchestration | Runner CPU use should improve without making local reproduction or workflow YAML hard to reason about. |
| Untrusted network-dependent PR checks | Real external-service checks belong in scheduled, release, or explicitly trusted workflows unless already deterministic. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CIDX-01 | Phase 119 | Complete |
| CIDX-02 | Phase 119 | Complete |
| CIDX-03 | Phase 119 | Complete |
| CIDX-04 | Phase 120 | Complete |
| CIDX-05 | Phase 122 | Pending |
| CIDX-06 | Phase 121 | Pending |
| CIDX-07 | Phase 120 | Complete |
| CIDX-08 | Phase 123 | Pending |
| CIDX-09 | Phase 120 | Complete |
| CIDX-10 | Phase 123 | Pending |
| FUT-01 | Deferred | Future |
| FUT-02 | Deferred | Future |
| FUT-03 | Deferred | Future |

**Coverage:**
- v1.18 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0
- Future requirements deferred: 3

---
*Requirements defined: 2026-06-15*
*Last updated: 2026-06-15 after initial definition*

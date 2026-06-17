# Phase 120: Workflow Topology + Cache Hygiene - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-16 (resumed after token cutoff)
**Phase:** 120-workflow-topology-cache-hygiene-0-plans
**Mode:** assumptions
**Areas analyzed:** Required-check semantics, OpenFeature gate, cache hygiene, observability, release/supply-chain posture, branch-protection reconciliation, scope boundary

## Assumptions Presented

All assumptions were re-verified against the live repo (ci.yml, scripts/ci/*.sh, publish-hex.yml, MAINTAINING.md, ROADMAP, and 119-CI-CD-AUDIT.md) before being locked.

### Required-Check Semantics

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Keep `ci.yml` always-triggered; preserve `release_gate` as the single aggregate gate; fix skipped/path-gated semantics inside the aggregate, not via workflow-level path filters. | Likely | `ci.yml:6-16`, `ci.yml:294-332`, audit D-04/D-05, MAINTAINING.md required-check notes | Branch protection can stick on skipped/pending checks, or docs-only PRs appear falsely blocked. |
| Continue the "skipped means success only when not relevant" transform pattern for path-gated jobs. | Confident | `ci.yml:315-323`, GitHub required-status-checks docs | Path-gated jobs either always block or never block, breaking docs-only and admin-only flows. |

### OpenFeature Companion Gate

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Treat `openfeature-companion` as merge-blocking when relevant by wiring it into `release_gate.needs` with the mounted-proof not-relevant→success pattern. | Decided (was: Likely) | Audit D-06 (explicitly left open for Phase 120); `ci.yml:238-261`; `ci.yml:321-323`; MAINTAINING.md OpenFeature proof boundary | OpenFeature regressions pass the aggregate gate on companion-relevant changes. |

### Cache Hygiene

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Tighten Mix and PLT cache keys around correctness (OS, Elixir/OTP/tool versions, lockfiles, MIX_ENV, package scope); remove broad restore keys like `${{ runner.os }}-mix-` that cross incompatible lanes. | Likely | Audit cache table; `ci.yml:103-124, 166-177, 224-234, 251-259, 276-286` | CI reuses stale `_build`/deps/PLTs across incompatible runtime/package scopes, causing confusing failures or hidden drift. |
| Scope each cache key's `hashFiles` to the lockfiles a lane actually builds, where correctness-safe (lint/PLT → `rulestead/mix.lock`). | Likely | Three separate `mix.lock` files; `ci.yml:109,115,124` | Over-invalidation persists (harmless) — but if scoped too narrowly, a lane could under-invalidate; hence "tighten only where correctness-safe." |

### Observability

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Add lightweight cache/version observability to job logs/summaries rather than a new reporting system. | Likely | Success criterion #3; repo scripts-first output; `test.sh:500-501` already echoes matrix versions conditionally | Cache fixes are hard to debug later; contributors can't tell code vs env vs cache failures. |

### Release and Supply Chain

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Preserve release trust: green CI on tagged SHA, protected hex-publish approval before HEX_API_KEY, core-before-admin order, admin publish guard, post-publish verification. | Confident | `publish-hex.yml`, `scripts/ci/verify_published_release.sh`, `scripts/ci/admin_publish_guard.sh`, MAINTAINING.md, audit D-08 | Phase 120 could weaken the irreversible Hex publish boundary or imply standalone admin publish prep. |
| Do not weaken full-SHA action pinning, least-privilege permissions, Dependabot coverage, dependency review, or secret boundaries. | Confident | SHA-pinned workflow actions; `.github/dependabot.yml`; audit D-09/D-10 | CI gets faster-looking but less trustworthy, violating CIDX-09. |

### Scope Boundary

| Assumption | Confidence | Evidence | If wrong |
|------------|------------|----------|----------|
| Phase 120 touches only workflow topology, cache keys/restore, required-check aggregation, release/supply-chain posture, practical job output, and MAINTAINING.md required-check reconciliation. | Confident | ROADMAP phase split; CIDX-04/07/09; audit handoff notes | Phase 120 steals work from Phases 121-123 and makes verification harder. |

## Open Questions Resolved

Two items the Phase 119 audit explicitly left open were resolved with the maintainer during this resumed discussion (rather than auto-assumed):

| Question | Resolution | Rationale |
|----------|------------|-----------|
| Should `openfeature-companion` feed `release_gate.needs`, or stay advisory/path-gated? | **Wire into `release_gate.needs`** (merge-blocking when relevant, advisory otherwise). | Closes the gap where OpenFeature regressions could pass the aggregate gate on companion-relevant PRs; reuses the proven mounted-proof transform; keeps the proof's narrow contract scope. |
| The audit found `main` has no live branch protection (404) despite MAINTAINING.md documenting required checks. How far should Phase 120 go? | **Code/docs only; document the intended settings, no `gh api` writes.** | Enabling protection is an outward live repo-settings change; v1.18 keeps repo-settings mutation out of scope. Reconciling MAINTAINING.md keeps docs honest for manual application. |

## Corrections Made

- The prior chat framed the openfeature-companion wiring and the branch-protection gap as soft "likely" assumptions. The Phase 119 audit (D-04, D-06) had in fact left both as explicit Phase 120 decisions, so both were re-classified as open questions and resolved with the maintainer (see table above) rather than locked silently.
- All other assumptions were confirmed against the live repo without change.

## Subagent Research Summary

Three Explore passes verified the assumptions against current source.

| Area | Finding | Effect on decisions |
|------|---------|---------------------|
| Workflow topology | `ci.yml` is always-triggered (no workflow-level path filters); `release_gate` (`if: always()`) fans in `changes, lint, test, integration-placeholder, adopter-contract, mounted-proof`; `openfeature-companion` exists (path-gated) but is absent from `release_gate.needs`. | Confirms D-01/D-02; grounds D-03. |
| Cache keys | `test` job carries a cross-lane `${{ runner.os }}-mix-` fallback (`ci.yml:175-177`); lint/mounted/adopter/PLT keys hash repo-wide `**/mix.lock` despite three separate lockfiles; PLT cache lives only in lint. | Grounds D-05/D-06; bounds them to correctness-safe scope. |
| Release/supply chain | `publish-hex.yml` enforces `gate-ci-green` on tagged SHA, protected `hex-publish` environment, core-before-admin order, admin publish guard, and post-publish verification handoff; actions SHA-pinned. | Confirms D-09/D-10 as preserve-only. |
| Planning state | Phase 119 complete; `release_gate.sh:29-37` fails any non-`success` pair (no change needed for D-03); MAINTAINING.md:32-52 documents the required-check triad while the live API returns 404. | Grounds D-03 (no script change) and D-11 (docs-only reconciliation). |

## External Research

No new external research was required beyond the official/comparable-OSS research already captured in `119-CI-CD-AUDIT.md` and `119-DISCUSSION-LOG.md` (GitHub Actions workflow syntax, required-check troubleshooting, job-condition skipped-success behavior, dependency caching, job summaries, secure-use guidance). Phase 120 implements decisions already evidenced there.

## Deferred Ideas

- Enabling live branch protection via `gh api` / repo-settings writes — out of scope for v1.18 (D-11 documents intended settings only).
- ExUnit async/partitioning, oversized-module splits, Dialyzer placement — Phase 121.
- Browser/demo/integration/Playwright determinism and generated-evidence behavior — Phase 122.
- Contributor command docs, closeout metrics, rollback documentation — Phase 123.
- Larger runners, broad sharding, richer reports, browser-binary caching — later-phase options pending evidence.

---

*Phase: 120-workflow-topology-cache-hygiene-0-plans*
*Discussion log generated: 2026-06-16*

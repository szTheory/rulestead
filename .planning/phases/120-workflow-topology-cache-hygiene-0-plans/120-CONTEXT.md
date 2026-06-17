# Phase 120: Workflow Topology + Cache Hygiene - Context

**Gathered:** 2026-06-16 (assumptions mode, resumed)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 120 implements the low-risk workflow-topology, cache-hygiene, required-check, and release/supply-chain improvements that Phase 119 proved in `119-CI-CD-AUDIT.md`. It turns audit handoff items D-04 through D-10 into concrete, narrow changes to `.github/workflows/ci.yml`, cache keys, CI job output, and `MAINTAINING.md`.

This phase preserves the always-triggered CI plus single aggregate `release_gate` topology, the linked-version sibling-package release trust posture, and all supply-chain hardening. It does not change ExUnit async/sharding (Phase 121), browser/demo/Playwright determinism (Phase 122), contributor-command or closeout docs (Phase 123), product runtime APIs, schemas, or `rulestead_admin` publish posture. It performs no live GitHub repo-settings writes.

</domain>

<decisions>
## Implementation Decisions

### Required-Check Semantics
- **D-01 (Confirmed):** Keep `ci.yml` always-triggered (no workflow-level `paths:`/`paths-ignore:` filters). Preserve the single `release_gate` aggregate (`if: always()` + `needs:` fan-in) as the only branch-protection-required gate. Evidence: `ci.yml:6-16` (triggers), `ci.yml:294-332` (release_gate), `ci.yml:28-88` (changes job), audit D-04/D-05.
- **D-02 (Confirmed):** Fix selectivity inside the aggregate, not at the workflow level. Continue using `changes`-job outputs plus the "skipped means success only when not relevant" transform pattern. Never recommend workflow-level path filters for required checks (they create required-check Pending traps). Evidence: `ci.yml:315-323`, audit D-05, GitHub required-status-checks docs.

### OpenFeature Companion Gate (resolved open question)
- **D-03 (Decided — wire in):** Add `openfeature-companion` to `release_gate.needs` and treat it as merge-blocking only when companion-relevant, advisory (skipped→success) otherwise. Intended change shape for plan-phase:
  - `ci.yml:296-302`: add `- openfeature-companion` to `release_gate.needs`.
  - `ci.yml:307-332` (Evaluate gate step): add `openfeature_result="${{ needs['openfeature-companion'].result }}"`; add the not-relevant transform `if [[ "${{ needs.changes.outputs.openfeature-companion }}" != "true" && "${openfeature_result}" == "skipped" ]]; then openfeature_result="success"; fi`; pass `"openfeature-companion=${openfeature_result}"` into `scripts/ci/release_gate.sh`.
  - No change to `scripts/ci/release_gate.sh` — it already fails any non-`success` `job=result` pair (`release_gate.sh:29-37`).
  - Scope guard: keep MAINTAINING.md's framing that this proof is merge-blocking only for the companion contract it covers (the Elixir provider package), not browser/demo glue, publish choreography, or unrelated repo surfaces. Evidence: audit D-06; `ci.yml:238-261`; `ci.yml:321-323` (mounted-proof precedent); MAINTAINING.md OpenFeature proof boundary.

### Cache Hygiene
- **D-04 (Confirmed — correctness first):** Tighten restore breadth only where the primary key stays correctness-safe across OS, Elixir, OTP, lockfile, `.tool-versions`, `MIX_ENV`, and package scope. Do not optimize sharing at the expense of correctness.
- **D-05 (Confirmed):** Remove the cross-lane `${{ runner.os }}-mix-` fallback restore key in the `test` matrix job (`ci.yml:175-177`); keep the matrix-scoped `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-` restore key. This prevents restoring `_build` artifacts compiled for an incompatible OTP/Elixir lane.
- **D-06 (Confirmed):** Scope each cache key's `hashFiles` to the lockfiles that lane actually builds rather than the repo-wide `**/mix.lock`, where doing so stays correctness-safe. Concretely: lint and Dialyzer PLT build only `rulestead/` (`ci.yml:103-124`), so scope their keys to `rulestead/mix.lock` + `.tool-versions`. Treat per-package scoping for `test`/`adopter`/`mounted` keys as "tighten where correctness-safe"; defer any change that risks under-invalidation. Evidence: three separate `mix.lock` files (core/admin/open_feature); audit cache table.
- **D-07 (Confirmed):** Document a one-line cache-busting rule per cache (what key component change forces a rebuild) in `MAINTAINING.md` or workflow comments.

### Cache/Version Observability
- **D-08 (Confirmed — lightweight, scripts-first):** Add log/summary output (no new reporting system): echo Elixir/OTP/tool versions, cache hit/miss, and a copy-pasteable local reproduction command for failed lanes. Prefer `$GITHUB_STEP_SUMMARY` and existing `scripts/ci/*` over new infrastructure. Evidence: success criterion #3; repo scripts-first CI preference.

### Release and Supply Chain
- **D-09 (Confirmed — preserve, do not weaken):** Keep the full release-trust topology: green CI on the tagged SHA (`gate-ci-green`), protected `hex-publish` environment approval before `HEX_API_KEY`, core-before-admin publish order, admin publish guard, and post-publish verification. Evidence: `publish-hex.yml`, `scripts/ci/verify_published_release.sh`, `scripts/ci/admin_publish_guard.sh`, MAINTAINING.md, audit D-08.
- **D-10 (Confirmed — preserve, do not weaken):** Keep full-SHA action pinning, least-privilege workflow permissions, Dependabot coverage, dependency-review, and secret boundaries at least as strict as the current baseline. Evidence: `.github/workflows/*.yml` SHA pins, `.github/dependabot.yml`, audit D-09/D-10, CIDX-09.

### Branch-Protection Reconciliation (resolved open question)
- **D-11 (Decided — docs only):** The audit found `main` returns `Branch not protected` (404) live, despite MAINTAINING.md documenting a required-check triad. Phase 120 reconciles the documentation only: state the exact intended protection settings in `MAINTAINING.md` (required checks = `release_gate`, `Validate PR title`, `dependency-review`; `actionlint` excluded because it is path-filtered) and note they must be applied manually by a maintainer. No `gh api` writes to live repo settings in this milestone. Evidence: audit D-04 live 404; MAINTAINING.md:32-52.

### Scope Boundary
- **D-12 (Confirmed):** Phase 120 touches only workflow topology, cache keys/restore behavior, required-check aggregation, release/supply-chain posture (preserve), practical job output, and the MAINTAINING.md required-check reconciliation. It does not touch ExUnit async/sharding (121), browser/Playwright/demo determinism (122), contributor-command/closeout docs (123), product runtime APIs/schemas, or admin publish posture. Evidence: ROADMAP phases 120-123; CIDX-04/07/09; audit handoff notes.

### Planner Discretion
- The planner may choose exact YAML phrasing, comment wording, and the location of busting-rule docs (workflow comments vs MAINTAINING.md) provided every decision above is honored.
- The planner may add low-cost log/summary lines beyond the minimum when they strengthen failure triage without changing behavior.
- The planner may sequence the changes into one or more plans as long as the `release_gate` aggregate stays green at every commit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Ground Truth
- `.planning/phases/119-baseline-expert-audit-0-plans/119-CI-CD-AUDIT.md` - the decision ledger; source of D-04 through D-10 handoff items.
- `.planning/ROADMAP.md` - Phase 120 success criteria and the 121-123 scope boundary.
- `.planning/REQUIREMENTS.md` - CIDX-04, CIDX-07, CIDX-09 and out-of-scope constraints.
- `.planning/STATE.md` - strict phase sequence and release-trust boundary.

### Prompt Grounding
- `prompts/rulestead-release-engineering-and-ci.md` - scripts-first CI, pinned actions, post-publish verification, job-id contracts.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - Elixir OSS cache/workflow baseline.
- `prompts/rulestead-security-privacy-and-threat-model.md` - supply-chain hygiene, secret handling.

### CI/CD Surfaces (edited or cited)
- `.github/workflows/ci.yml` - topology, `changes` outputs, cache keys, `release_gate` aggregate (primary edit target).
- `.github/workflows/publish-hex.yml` - protected publish flow (preserve, do not edit trust posture).
- `.github/workflows/verify-published-release.yml`, `.github/dependabot.yml` - supply-chain surfaces (preserve).
- `scripts/ci/release_gate.sh` - aggregate normalizer (no change needed for D-03).
- `scripts/ci/test.sh`, `scripts/ci/lint.sh` - lane entry points for observability output.
- `MAINTAINING.md` - required-check docs (D-11) and cache-busting rules (D-07).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `changes` job (`ci.yml:28-88`) already emits `docs-only`, `openfeature-companion`, and `mounted-proof` outputs — D-03 reuses the existing `openfeature-companion` output, no new filter needed.
- The mounted-proof not-relevant→success transform (`ci.yml:321-323`) is the exact pattern D-03 mirrors for openfeature-companion.
- `scripts/ci/release_gate.sh` already validates arbitrary `job=result` pairs (`release_gate.sh:29-37`), so adding a pair requires no script change.

### Established Patterns
- One always-triggered `ci.yml`, one aggregate required `release_gate`; selectivity lives in job `if:` conditions, not workflow path filters.
- Caches are per-lane (lint, test-matrix, adopter, openfeature, mounted) with lane-scoped keys; the known smells are the cross-lane `${{ runner.os }}-mix-` fallback and repo-wide `**/mix.lock` hashing.
- Scripts-first CI: workflow YAML calls understandable repo scripts; failure output should point to exact local rerun commands.

### Integration Points
- D-03 ties the openfeature proof bar into the same branch-protection contract as mounted-proof while preserving its narrow contract scope.
- D-08 observability output should reuse `MATRIX_ELIXIR`/`MATRIX_OTP` env already passed into `test.sh` (`ci.yml:158-159`).
- D-11 keeps MAINTAINING.md honest about live branch protection without changing the live repo.

</code_context>

<specifics>
## Specific Ideas

- Two audit-flagged open questions were resolved with the maintainer during this resumed discussion: wire openfeature-companion into `release_gate.needs` (D-03), and handle the branch-protection 404 with docs only (D-11).
- Every cache change is correctness-first: tighten restore breadth and hash scope only where the primary key remains correctness-safe; prefer a known-good rebuild over a possibly-stale restore.
- Keep all release/supply-chain trust surfaces at least as strict as today; this phase must not look faster by being less trustworthy.

</specifics>

<deferred>
## Deferred Ideas

- Enabling live branch protection via `gh api` (or other repo-settings writes) is explicitly out of scope for v1.18; D-11 documents the intended settings for manual application.
- ExUnit async, test partitioning, oversized-module splits, and Dialyzer placement are Phase 121.
- Browser/demo/integration/Playwright determinism and generated-evidence behavior are Phase 122.
- Contributor-facing command docs, closeout metrics, and rollback documentation are Phase 123.
- Larger runners, broad test sharding, richer reports, and browser-binary caching remain later-phase options unless evidence justifies them.

</deferred>

---

*Phase: 120-workflow-topology-cache-hygiene-0-plans*
*Context gathered: 2026-06-16*

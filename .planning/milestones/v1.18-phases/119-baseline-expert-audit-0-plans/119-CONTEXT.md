# Phase 119: Baseline + Expert Audit - Context

**Gathered:** 2026-06-15 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 119 produces a repo-specific CI/CD performance, reliability, security, and DX baseline before behavior changes. It must deliver `119-CI-CD-AUDIT.md` with workflow/job/command inventory, critical-path and cache findings, Mix/ExUnit diagnostics, test/check classification, and applicable official/comparable-OSS research.

This phase does not change workflow behavior, product runtime APIs, schemas, release trust posture, `rulestead_admin` publish posture, browser baseline strategy, or test inclusion. Phases 120-123 use the Phase 119 audit as evidence for later changes.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning Ground Truth
- `.planning/PROJECT.md` - v1.18 goal, preserved release bars, project vision, linked-package context.
- `.planning/REQUIREMENTS.md` - CIDX-01 through CIDX-03 for Phase 119 and out-of-scope constraints.
- `.planning/STATE.md` - strict phase sequence, release-trust boundary, prior decisions.
- `.planning/ROADMAP.md` - Phase 119 success criteria and Phase 120-123 dependency chain.
- `.planning/METHODOLOGY.md` - recommendation-first, research-then-recommend, architect-default discussion posture.

### Prompt Grounding
- `prompts/rulestead-release-engineering-and-ci.md` - scripts-first CI, release workflow posture, pinned actions, post-publish verification, job-id contracts.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - Elixir OSS CI/CD comparisons and best-practice baseline.
- `prompts/rulestead-engineering-dna-from-prior-libs.md` - inherited engineering DNA for testing, release gates, path filters, and proof bars.
- `prompts/rulestead-testing-and-e2e-strategy.md` - testing pyramid, browser evidence posture, flake handling, and artifact strategy.
- `prompts/rulestead-security-privacy-and-threat-model.md` - fail-closed posture, supply-chain hygiene, secret handling, Hex audit.
- `prompts/rulestead-personas-jtbd-and-onboarding.md` - contributor, support, and SRE jobs-to-be-done for failure actionability.
- `prompts/rulestead-telemetry-observability-and-audit.md` - evidence, traceability, and failure explanation posture.
- `prompts/elixir-ecto-hexdocs-best-practices.md` - Elixir/Ecto/Phoenix library conventions and footguns.
- `prompts/elixir-phoenix-ecto-hexdocs-documentation-best-practices.md` - docs-as-contract and HexDocs expectations.

### Current CI/CD Surfaces
- `.github/workflows/ci.yml` - main PR gate topology, job conditions, path gating, `release_gate`.
- `.github/workflows/actionlint.yml` - workflow syntax validation.
- `.github/workflows/dependency-review.yml` - dependency review gate.
- `.github/workflows/dependabot-automerge.yml` - dependency automation posture.
- `.github/workflows/pr-title.yml` - Release Please/conventional title guard.
- `.github/workflows/release-please.yml` - release intent automation.
- `.github/workflows/release-pr-ci.yml` - release PR CI dispatch.
- `.github/workflows/publish-hex.yml` - protected Hex publish flow.
- `.github/workflows/verify-published-release.yml` - post-publish verification.
- `.github/workflows/repo-hygiene.yml` - repo hygiene signal.

### CI Scripts and Proof Commands
- `scripts/ci/lint.sh` - lint, docs, security, package, Dialyzer, brand/design guard spine.
- `scripts/ci/test.sh` - test scope dispatcher and phase proof categories.
- `scripts/ci/release_gate.sh` - aggregate release gate normalization.
- `scripts/ci/local.sh` - full local contributor/maintainer gate.
- `scripts/ci/contributor.sh` - fast contributor loop.
- `scripts/ci/integration_placeholder.sh` - integration bridge into demo verification.
- `scripts/demo/verify.sh` - Compose + Playwright demo proof.
- `rulestead/mix.exs` - core package aliases, dependencies, Dialyzer config, verify scopes.
- `rulestead_admin/mix.exs` - sibling package versioning and path/Hex dependency switch.
- `examples/demo/frontend/playwright.config.ts` - Playwright CI/runtime behavior.
- `examples/demo/frontend/package.json` - frontend test and dependency surface.
- `MAINTAINING.md` - documented branch protection, local gate, release runbook, and cache expectations.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/*.sh` already form a scripts-first CI spine. Phase 119 should inventory and classify these commands instead of replacing them.
- `scripts/demo/verify.sh` and `examples/demo/frontend` provide the Compose/browser proof path that Phase 119 must measure and classify.
- Existing proof scopes in `scripts/ci/test.sh` give natural classification units for adopter, mounted admin, OpenFeature, guarded rollout, host preview, install journey, and post-GA band checks.
- `MAINTAINING.md` already documents required checks and contributor commands; use it as both baseline and drift target.

### Established Patterns
- Rulestead uses conservative proof bars: release gate, post-publish verification, mounted companion proof, OpenFeature proof, adopter contract, and generated browser artifacts.
- The repo favors deterministic source guards and ignored generated evidence over broad checked-in visual baselines.
- The two-package release model is linked-version and release-workflow-owned; `rulestead_admin` remains an optional mounted companion, not an independently published surface.
- Project planning expects audit before behavior change and phase-by-phase traceability through `.planning/`.

### Integration Points
- Phase 119 output feeds Phase 120 workflow/cache changes, Phase 121 Mix/ExUnit/test-value changes, Phase 122 browser/demo determinism work, and Phase 123 DX/closeout docs.
- The audit should connect workflow jobs back to local scripts, branch-protection semantics, release proof, and maintainer rerun commands.
- The audit should connect Playwright/browser artifacts back to operator/support/SRE JTBD only where CI evidence ergonomics are involved; no product UI work is in scope.

</code_context>

<specifics>
## Specific Ideas

- User asked for one-shot expert recommendations with pros, cons, tradeoffs, examples, ecosystem idioms, lessons from successful libraries/apps, DX, UI/UX where applicable, and coherent architecture across the milestone.
- Apply expert lenses for software architecture, CI/CD, DevOps/SRE, Elixir/Phoenix/Ecto/Plug, release engineering, supply-chain security, contributor DX, and UI/UX evidence ergonomics.
- Use official docs and comparable OSS patterns only where they apply directly to this repo. Avoid importing fashionable CI complexity that weakens local reproduction or release confidence.
- Where prompts conflict with newer brandbook/design-system artifacts, prefer the newer repo artifact.

</specifics>

<deferred>
## Deferred Ideas

- Implementing workflow topology or cache changes is Phase 120.
- Changing ExUnit async, test partitioning, test value cleanup, or Dialyzer placement is Phase 121.
- Fixing/quarantining browser/demo flake sources or changing Playwright evidence behavior is Phase 122.
- Updating contributor-facing docs and closeout metrics is Phase 123.
- Larger runners, broad test partitioning, richer reports, and browser binary caching remain future/later-phase options unless Phase 119 evidence justifies them.

</deferred>

---

*Phase: 119-baseline-expert-audit-0-plans*
*Context gathered: 2026-06-15*

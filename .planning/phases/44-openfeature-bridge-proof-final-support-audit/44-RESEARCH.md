# Phase 44: OpenFeature Bridge Proof & Final Support Audit - Research

**Researched:** 2026-05-25
**Domain:** OpenFeature companion package truth, package-local proof posture, named CI surface, and milestone support-truth closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep `open_feature_rulestead` package-first, install-first, and clearly secondary to the runtime front door. [VERIFIED: 44-CONTEXT.md]
- Treat the Elixir provider package and the demo/browser bridge as distinct surfaces. The browser path stays host-owned and secondary. [VERIFIED: 44-CONTEXT.md] [VERIFIED: examples/demo/README.md]
- Add one named OpenFeature companion proof surface that is visible in repo scripts/CI, but do not widen the default core sibling-package gate or change the two-package release design. [VERIFIED: 44-CONTEXT.md] [VERIFIED: AGENTS.md]
- Close `OFE-01` with a runnable package-local proof path and finish milestone support-truth closure without productizing a broader browser bridge. [VERIFIED: roadmap] [VERIFIED: requirements]

### the agent's Discretion
- Exact proof-scope name, provided it stays explicit, companion-scoped, and different from the mounted-admin proof bar.
- Exact README section structure, provided the package explains setup, footguns, proof command, and the host-owned demo boundary clearly.
- Exact CI job shape, provided it exposes the proof surface by name without implying `open_feature_rulestead` is now a primary published sibling package.

### Deferred Ideas (OUT OF SCOPE)
- Publishing or preparing `open_feature_rulestead` as a third linked-version release package
- Turning the demo/browser path into the only or primary support contract
- New OpenFeature product capabilities, relay/proxy work, browser SDK productization, or widened admin/runtime scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OFE-01 | `open_feature_rulestead` has a runnable documented proof path that either passes in-repo verification or states its exact bounded support caveat honestly. | The provider package already has real Elixir tests and a small surface area; Phase 44 should convert that into an install-first README plus a named repo proof bar instead of claiming the demo alone is sufficient. [VERIFIED: open_feature_rulestead/README.md] [VERIFIED: provider_test.exs] |
| VER-01 | `rulestead` and `rulestead_admin` verification surfaces are green again, or any intentionally deferred failures are explicitly documented and bounded in release-facing truth. | Final milestone truth must add the OpenFeature companion proof bar without overwriting the existing bounded mounted-admin and release-publish bars. [VERIFIED: README.md] [VERIFIED: MAINTAINING.md] |
</phase_requirements>

## Project Constraints

- Respect the active Phase 44 boundary and keep Phase 8-only docs absent. [VERIFIED: AGENTS.md]
- Preserve the linked-version, two-package release design centered on `rulestead` and `rulestead_admin`. [VERIFIED: AGENTS.md] [VERIFIED: README.md] [VERIFIED: MAINTAINING.md]
- Make the smallest coherent closure change: package truth, named proof bar, then milestone support-truth reconciliation. [VERIFIED: AGENTS.md]

## Summary

The repo already contains a real OpenFeature provider package, but its public truth is weaker than the code. `open_feature_rulestead/lib/open_feature_rulestead/provider.ex` and the existing package tests prove a bounded Elixir provider contract today: explicit `environment_key` initialization, translation of OpenFeature context into `Rulestead.Context`, and scalar resolution metadata (`matched_rule`, `flag_version`, `cache_age_ms`). The current README does not teach that contract or give a package-local proof command. Instead, it points readers to the demo as the bounded proof path, which recreates exactly the support-truth drift Phase 44 is meant to close. [VERIFIED: provider.ex] [VERIFIED: provider_test.exs] [VERIFIED: 44-CONTEXT.md]

The best recommendation is to keep the proof posture layered. The package README should become the truth source for the Elixir provider package: install `open_feature` plus `open_feature_rulestead`, initialize the provider with an explicit environment key, document context and metadata boundaries, and give one obvious package-local proof command. The demo should remain documented, but only as a secondary host-owned browser/example path. That preserves least surprise for Hex readers and matches the project-wide companion-surface philosophy. [INFERENCE from verified evidence]

The repo also needs a named proof surface that maintainers and CI can cite verbatim. `scripts/ci/test.sh` already encodes named bounded scopes such as `mounted_admin_contract`; Phase 44 should reuse that pattern for an `openfeature_companion` scope rather than inventing a bespoke verifier. The current `ci.yml` only exposes `lint`, `test`, and the Phase 28 integration lane, so the OpenFeature proof is invisible in CI today. A path-gated or explicitly bounded job is the cleanest fit: visible by name, runnable locally, and not promoted into an always-on equal peer of the core sibling-package release bars. [VERIFIED: scripts/ci/test.sh] [VERIFIED: .github/workflows/ci.yml]

Final milestone truth should then be reconciled in one place. The root README's "Proof today" section currently names the demo, the mounted-admin proof bar, and the published-release checks, but says nothing concrete about a package-local OpenFeature proof path. The demo README already says the frontend bridge is a companion proof surface, which is directionally correct; it just needs to point back to the named package proof so the browser path is clearly secondary. The final support-truth closeout should update those docs and create a Phase 44 verification artifact that cites the exact OpenFeature companion command used to close `OFE-01`. [VERIFIED: README.md] [VERIFIED: examples/demo/README.md] [VERIFIED: MAINTAINING.md]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 44 | Why |
|---------|-----------------------------|-----|
| `open_feature_rulestead/README.md` | Become the package-first truth source for setup, footguns, proof command, and package-vs-demo boundary | This is the current public drift point. [VERIFIED: README.md] |
| `open_feature_rulestead/test/open_feature_rulestead/provider_test.exs` and `context_mapper_test.exs` | Back the documented provider contract with explicit proof of the package-local surface | The package already has the right narrow test surface. [VERIFIED: provider_test.exs] |
| `scripts/ci/test.sh` | Expose the OpenFeature companion proof by name for local and CI reruns | Existing mounted-admin scope is the direct analog. [VERIFIED: scripts/ci/test.sh] |
| `.github/workflows/ci.yml` | Surface the proof in CI without redefining the default release model | Current CI has no named OpenFeature companion lane. [VERIFIED: ci.yml] |
| `README.md`, `examples/demo/README.md`, `.planning/REQUIREMENTS.md`, `44-VERIFICATION.md` | Close the final support-truth and traceability gap | Phase 44 is the milestone-close truth pass. [VERIFIED: roadmap] [VERIFIED: requirements] |

## Standard Stack

### Source-of-truth code and docs
- `open_feature_rulestead/README.md`
- `open_feature_rulestead/mix.exs`
- `open_feature_rulestead/lib/open_feature_rulestead/provider.ex`
- `open_feature_rulestead/lib/open_feature_rulestead/context_mapper.ex`
- `open_feature_rulestead/test/open_feature_rulestead/provider_test.exs`
- `open_feature_rulestead/test/open_feature_rulestead/context_mapper_test.exs`
- `scripts/ci/test.sh`
- `.github/workflows/ci.yml`
- `README.md`
- `examples/demo/README.md`
- `MAINTAINING.md`

### Targeted proof commands
- `cd /Users/jon/projects/rulestead/open_feature_rulestead && mix test test/open_feature_rulestead/context_mapper_test.exs test/open_feature_rulestead/provider_test.exs`
- `RULESTEAD_TEST_SCOPE=openfeature_companion bash /Users/jon/projects/rulestead/scripts/ci/test.sh`

These are the narrowest commands that prove the package contract without turning the browser demo into the package contract. [INFERENCE from verified evidence]

## Recommended Shape

### Pattern 1: Package-first README, demo-second cross-link
Follow the same repo posture used in earlier support-truth phases: narrow sibling/companion README, broader root truth elsewhere, and explicit cross-links instead of blended storytelling. The OpenFeature package should explain the Elixir provider contract first, then link to the demo as a secondary example. [VERIFIED: 41-CONTEXT.md] [VERIFIED: README.md]

### Pattern 2: Named proof scope in `scripts/ci/test.sh`
Reuse the mounted-admin proof-bar pattern directly. A small named scope keeps commands stable across local reruns, CI jobs, and docs:

```sh
RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh
```

That scope should stay bounded to the package tests and avoid claiming browser/demo coverage. [VERIFIED: scripts/ci/test.sh]

### Pattern 3: CI visibility without release-model inflation
Expose the scope in CI by name, but gate it narrowly so unrelated PRs do not pay the cost and the branch-protection story does not suddenly imply a third primary package. Path-gated job plus skip-normalized `release_gate` handling is the best fit if workflow edits are needed. [INFERENCE from verified evidence]

### Pattern 4: Final support truth cites the same command the package docs teach
Root docs, demo docs, maintainer docs, and `44-VERIFICATION.md` should all point at the same named package proof surface. Support truth should never ask readers to infer proof from test files or planning history. [VERIFIED: README.md] [VERIFIED: MAINTAINING.md]

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| README overcorrects into a blended browser-bridge story | Keep package README focused on Elixir provider setup and clearly label the browser path as host-owned demo glue. |
| CI exposure accidentally makes OpenFeature look like a third primary release package | Keep the proof scope companion-named and bounded; do not route it through publish choreography or sibling-package release tags. |
| Package docs become stronger than the actual tests | Add or tighten provider/context mapper assertions around environment key, context mapping, and metadata footguns before claiming a runnable proof path. |
| Final milestone docs keep pointing to the demo as the only OpenFeature proof | Root/demo/support docs must be updated in the same phase so the support story lands coherently. |

## Recommended Slice Boundary

### Slice 1
Rewrite the OpenFeature package README around the real Elixir provider contract and strengthen package-local tests to match the documented setup path.

### Slice 2
Add a named `openfeature_companion` proof surface in repo scripts and CI/maintainer wiring without widening the two-package release design.

### Slice 3
Reconcile root/demo/milestone support truth and write the Phase 44 verification artifact that closes `OFE-01`.

## Confidence

- Architecture: HIGH - the provider package and bounded demo boundary already exist; the gap is truth and proof surfacing, not missing architecture. [VERIFIED: provider.ex] [VERIFIED: demo README]
- Verification: HIGH - the package-local proof surface is already small and deterministic. [VERIFIED: provider_test.exs]
- Scope control: HIGH - roadmap, AGENTS constraints, and Phase 44 context all align on bounded companion proof rather than release-model expansion. [VERIFIED: AGENTS.md] [VERIFIED: roadmap] [VERIFIED: 44-CONTEXT.md]

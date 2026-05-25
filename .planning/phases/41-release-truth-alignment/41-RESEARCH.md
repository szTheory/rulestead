# Phase 41: Release Truth Alignment - Research

**Researched:** 2026-05-24
**Domain:** Post-`v1.0.0` release-truth alignment across root/package docs, onboarding surfaces, companion proof language, and release-facing verification
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Phase boundary
- Phase 41 must align public-facing release language with the actual shipped posture without widening product scope, changing package versions, or changing the sibling-package release model. [VERIFIED: context] [VERIFIED: roadmap]
- The root README should say plainly that repo GA shipped in `v1.0.0` on 2026-05-21 while also making the current installable package line (`0.1.x`) explicit early enough to avoid surprise. [VERIFIED: context] [VERIFIED: project]
- Runtime-first onboarding remains the default path. `rulestead_admin` stays optional, mounted, Phoenix-host-specific, and not a standalone control-plane product. [VERIFIED: context] [VERIFIED: installation guide]
- Proof language must stay bounded to what the repo can actually support today: local demo proof plus `mix verify.release_publish <version>` and `mix verify.release_parity <version>` for published-consumer and tarball parity truth. [VERIFIED: context] [VERIFIED: maintaining] [VERIFIED: release prompt]
- Existing companion surfaces, `examples/demo/` and `open_feature_rulestead/`, should remain discoverable but secondary. Do not promote them to equal front-door status before later proof-closure phases. [VERIFIED: context]

### the agent's Discretion
- Exact section names for the root release note and bounded-proof callout, provided they remain early and explicit.
- Exact doc-link routing between root README, sibling READMEs, install/getting-started/upgrading, demo docs, and companion docs.
- Exact release-contract assertions, provided they lock the Phase 41 truth instead of the stale pre-GA wording.

### Deferred Ideas (OUT OF SCOPE)
- Package-version realignment to `1.x`
- New verification infrastructure beyond narrow release/doc contract checks
- Stronger OpenFeature bridge claims before Phase 44
- Any standalone `rulestead_admin` publishing or admin-product positioning
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Root and sibling package READMEs describe the shipped post-`v1.0.0` release posture, linked-version sibling-package model, and mounted-admin companion scope without stale pre-GA messaging. | Rewrite the root and sibling READMEs around one truthful split-front-door story: GA shipped at the repo level, current package install remains `0.1.x`, runtime is primary, mounted admin is optional, and companion surfaces stay bounded. [VERIFIED: requirements] [VERIFIED: current READMEs] |
| DOC-02 | Installation, onboarding, and support-facing docs explain the real current package, migration, demo, and verification posture without implying stronger proof than the repo currently provides. | Align installation/getting-started/upgrading plus companion docs and maintainer truth to the bounded proof posture, then lock it with release-facing doc-contract checks. [VERIFIED: requirements] [VERIFIED: guides] [VERIFIED: maintaining] |
</phase_requirements>

## Project Constraints

- Respect `.planning/ROADMAP.md` and stay inside Phase 41. [VERIFIED: AGENTS.md]
- Keep Phase 8-only docs absent. [VERIFIED: AGENTS.md]
- Preserve the linked-version sibling-package monorepo. [VERIFIED: AGENTS.md]
- Do not prepare `rulestead_admin` as a standalone published stub. [VERIFIED: AGENTS.md]

## Summary

The repo is internally inconsistent today in exactly the way Phase 41 anticipated. `README.md`, `rulestead/README.md`, and `rulestead_admin/README.md` still describe the first public Hex release as future work after `v0.6.0`, while `.planning/PROJECT.md` and `.planning/ROADMAP.md` record that `v1.0.0` shipped on 2026-05-21 and the package versions are already `0.1.0`. `guides/introduction/upgrading.md` already behaves like a shipped-package surface, so the public front door and the support docs currently disagree with each other. [VERIFIED: current READMEs] [VERIFIED: project] [VERIFIED: roadmap] [VERIFIED: mix.exs] [VERIFIED: upgrading guide]

The strongest implementation pattern is to keep one primary product story in the root README and keep sibling package READMEs narrow. The root should carry the explicit repo-GA vs package-line explanation once, then route readers into runtime-first onboarding, optional mounted-admin next steps, and a small bounded proof section. Package READMEs should use one short factual release note and point back to root/shared docs for the broader story rather than duplicating it. That matches the locked Phase 41 context and the already-established sibling-package doc topology. [VERIFIED: context] [VERIFIED: project] [VERIFIED: installation guide]

Phase 41 should also treat support truth as a machine-backed release surface, not freeform prose. The repo already has `Rulestead.ReleaseContractTest` asserting lifecycle-doc routing and `MAINTAINING.md` describing the post-publish verification trio. The phase should extend those guardrails so they enforce the new release story, bounded proof posture, and companion-surface language. That keeps future doc drift from reintroducing the pre-GA contradiction. [VERIFIED: release_contract_test] [VERIFIED: maintaining] [VERIFIED: release prompt]

The `open_feature_rulestead` and demo surfaces need only bounded discoverability in this phase. `examples/demo/README.md` already provides a concrete runnable proof path. `open_feature_rulestead/README.md` is currently skeletal, which is acceptable only if the root README and onboarding docs treat it as an optional companion bridge rather than a first-class primary path. Phase 41 can improve the README enough to state the bounded posture and route readers correctly without pretending the dedicated proof path is already closed. [VERIFIED: demo README] [VERIFIED: open_feature README] [VERIFIED: context]

**Primary recommendation:** plan one narrow execute wave with three tasks: 1) align the root and sibling READMEs around the explicit post-`v1.0.0` split-front-door story, 2) align installation/onboarding/companion/support docs around runtime-first onboarding and bounded proof truth, and 3) extend release-facing doc-contract tests plus maintainer guidance so the new story is enforced. [VERIFIED: context] [VERIFIED: current docs] [VERIFIED: release_contract_test]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 41 | Why |
|---------|-----------------------------|-----|
| `README.md` | Own the single explicit release-truth note, runtime-first quickstart, optional mounted-admin path, bounded proof section, and companion discoverability links | The root README is the public front door and should carry the broad story once. [VERIFIED: current README] |
| `rulestead/README.md` | Stay runtime-scoped, current-installable, and link back to root/shared docs for broader release posture | Package README should stay package-first, not become a second release note. [VERIFIED: context] |
| `rulestead_admin/README.md` | Keep the mounted companion contract explicit, optional, host-owned, and non-standalone while replacing stale future-release wording | This README is the main place drift could imply a standalone admin product. [VERIFIED: current admin README] |
| `guides/introduction/installation.md`, `guides/introduction/getting-started.md`, `guides/introduction/upgrading.md` | Align first-success path, current package line, and upgrade/support language with the shipped posture | These are the onboarding/support surfaces that adopters will compare against the READMEs. [VERIFIED: guides] |
| `examples/demo/README.md` and `open_feature_rulestead/README.md` | Stay secondary proof/companion surfaces with bounded language and correct routing | They should be discoverable without becoming first-class promises yet. [VERIFIED: context] |
| `rulestead/test/rulestead/release_contract_test.exs` and `MAINTAINING.md` | Lock the new release story and support-truth posture as a release-facing contract | This is the cheapest durable guardrail against future drift. [VERIFIED: release_contract_test] [VERIFIED: maintaining] |

## Standard Stack

### Current truth sources
- `.planning/PROJECT.md` and `.planning/ROADMAP.md` for the active post-`v1.0.0` story. [VERIFIED: project] [VERIFIED: roadmap]
- `rulestead/mix.exs`, `rulestead_admin/mix.exs`, and `open_feature_rulestead/mix.exs` for the real package version line (`0.1.0`). [VERIFIED: mix.exs]
- `guides/introduction/installation.md` for the already-correct runtime-only vs runtime-plus-admin split. [VERIFIED: installation guide]
- `examples/demo/README.md` for the concrete local proof path. [VERIFIED: demo README]
- `MAINTAINING.md` plus `scripts/ci/verify_published_release.sh` and Mix tasks for published-consumer and parity proof. [VERIFIED: maintaining] [VERIFIED: codebase grep]

### Verification seams to reuse
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs`
- `rg -n 'v1\\.0\\.0|2026-05-21|0\\.1\\.0|runtime-first|mounted companion|Proof today|verify\\.release_publish|verify\\.release_parity' README.md rulestead/README.md rulestead_admin/README.md guides/introduction/installation.md guides/introduction/getting-started.md guides/introduction/upgrading.md open_feature_rulestead/README.md examples/demo/README.md MAINTAINING.md`

These are sufficient for the phase because the work is documentation and contract alignment, not runtime behavior. [VERIFIED: release_contract_test] [VERIFIED: current docs]

## Recommended Shape

### Pattern 1: One explicit root release note, not three competing narratives
State the repo-level GA date and the current package line once in `README.md`, then keep package READMEs factual and link-oriented. [VERIFIED: context]

### Pattern 2: Runtime-first onboarding with immediate optional admin continuation
Do not lead with dual-package install as the only quickstart. Keep runtime-only first, then offer the mounted-admin path directly after as the Phoenix-host companion route. [VERIFIED: context] [VERIFIED: installation guide]

### Pattern 3: Bounded proof close to onboarding
Place a small “Proof today” or equivalent section near the release/install story, anchored to the demo path plus `verify.release_publish` and `verify.release_parity`. Avoid a giant verification matrix. [VERIFIED: context] [VERIFIED: maintaining]

### Pattern 4: Companion discoverability without companion inflation
Mention `examples/demo/` and `open_feature_rulestead/` intentionally, but label them as runnable proof path and optional bridge companion instead of equal entrypoints. [VERIFIED: context]

### Pattern 5: Doc truth enforced by tests
Extend `Rulestead.ReleaseContractTest` and maintainer guidance rather than relying on manual memory. [VERIFIED: release_contract_test]

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Root and sibling docs may still encode contradictory version stories after the rewrite | Task 1 should update all three README surfaces together and verify shared anchors explicitly. |
| Onboarding docs may accidentally imply stronger support than the repo proves today | Task 2 should bind install/getting-started/upgrading/demo/companion docs to the bounded proof posture and keep stronger claims deferred. |
| Future release edits may regress to pre-GA wording or overstate companion proof | Task 3 should expand the release contract test and maintainer checklist so doc drift fails fast. |

## Validation Architecture

Phase 41 should validate through one wave with three proof points:

1. README and package-surface integrity checks proving the explicit repo-GA date, current package-line truth, runtime-first path, and mounted-companion posture.
2. Onboarding/support-surface integrity checks proving installation/getting-started/upgrading/demo/open-feature docs all tell the same bounded proof story.
3. Release-contract tests proving the new story is machine-enforced, with `MAINTAINING.md` aligned to the same support-truth posture.

No UI-spec or browser automation is required. The dominant risks are misleading release truth and future drift, so narrow doc-contract verification is the right fit. [VERIFIED: context] [VERIFIED: release_contract_test]

## Recommended Slice Boundary

### Slice 1
Root and sibling READMEs adopt one truthful split-front-door release story.

### Slice 2
Onboarding, support, demo, and bridge docs align to runtime-first onboarding and bounded proof posture.

### Slice 3
Release-facing tests and maintainer guidance enforce the new story.

## Confidence

- Architecture: HIGH - the repo already has the right doc topology and verification seam; Phase 41 mainly needs alignment. [VERIFIED: project] [VERIFIED: release_contract_test]
- Verification: HIGH - `release_contract_test.exs` is a direct fit for this kind of doc contract. [VERIFIED: release_contract_test]
- Scope control: HIGH - the context explicitly limits this phase to release/support truth, not broader product changes. [VERIFIED: context]

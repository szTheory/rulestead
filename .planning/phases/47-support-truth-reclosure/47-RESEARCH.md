# Phase 47: Support Truth Reclosure - Research

**Researched:** 2026-05-26
**Domain:** Mounted companion support-truth reclosure across public docs, package contract docs, maintainer runbooks, and release-contract drift guards
**Confidence:** HIGH

<user_constraints>
## User Constraints

### Locked Decisions
- Preserve the linked-version, two-package monorepo model centered on `rulestead` plus optional mounted `rulestead_admin`. [VERIFIED: AGENTS.md] [VERIFIED: roadmap]
- Keep Phase 47 bounded to support-truth closure only; do not widen `rulestead_admin` into a standalone product and do not drag in future-phase work. [VERIFIED: AGENTS.md] [VERIFIED: 47-CONTEXT.md]
- Use the root-canonical, package-contract, maintainer-runbook split already locked in context. [VERIFIED: 47-CONTEXT.md]
- Keep public proof claims bounded to the named mounted companion command and the contract categories it proves, not an exhaustive suite inventory or a whole-admin guarantee. [VERIFIED: 47-CONTEXT.md]

### the agent's Discretion
- Exact section names and cross-link placement inside `README.md`, `rulestead_admin/README.md`, and `MAINTAINING.md`, provided the ownership split stays intact.
- Whether `rulestead/README.md` needs a touch-up for alignment or can remain unchanged after verification.
- Whether to place the strictest drift guards in `release_contract_test.exs` alone or also reinforce them in `verify_release_publish_test.exs`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Root, package, and maintainer-facing docs describe the exact mounted companion prerequisites, commands, fallback behavior, and sibling-package posture without implying standalone admin support or stronger proof than is actually runnable. | The current repo already has a green bounded proof command and the right doc surfaces, but those surfaces still drift on proof depth, fail-closed wording, and maintainer gate semantics. [VERIFIED: repo-local rerun 2026-05-26] [VERIFIED: README.md] [VERIFIED: rulestead_admin/README.md] [VERIFIED: MAINTAINING.md] [VERIFIED: release_contract_test.exs] |
</phase_requirements>

## Summary

The key temporal fact for Phase 47 is current: on **2026-05-26**, `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` passed in this workspace. That means Phase 47 should not reopen proof mechanics; it should close wording drift around a command that is already green and already exposed in CI. [VERIFIED: repo-local rerun 2026-05-26]

The current public and maintainer docs are directionally correct but still overfit earlier phase-state or implementation detail. `README.md` correctly names the mounted companion command, but it also enumerates the exact suite list. That is more detail than the public front door should own and is precisely the sort of drift the phase context warns against. [VERIFIED: README.md] [VERIFIED: 47-CONTEXT.md]

`rulestead_admin/README.md` is already the right surface for the mounted host contract: it documents `policy:`, host-owned session keys, `?env=` as canonical, and the bounded proof bar. The main gap is support-truth sharpness: Phase 47 should make fail-closed missing-prerequisite behavior and remembered-env fallback semantics more explicit, while keeping the package README narrowly focused on the host seam. [VERIFIED: rulestead_admin/README.md] [VERIFIED: rulestead_admin/live/session.ex contract references via 47-CONTEXT.md]

`MAINTAINING.md` is where the clearest operational drift remains. It still frames the mounted proof section as a Phase 43 artifact, still says `release_gate` aggregates only `lint`, `test`, and `integration-placeholder`, and still uses wording that implies broader or older gate semantics than the current CI file. The actual workflow now includes a named `mounted companion proof` job threaded into `release_gate` when mounted-proof-relevant paths change. Phase 47 should re-close that truth in maintainer docs and keep the wording evergreen rather than phase-numbered. [VERIFIED: MAINTAINING.md] [VERIFIED: .github/workflows/ci.yml]

The strongest implementation shape is therefore the roadmap's three-slice split. First, tighten the root and package docs so the public support story names the exact command and support boundary without over-specifying suite membership. Second, make the package docs explicit about missing prerequisites, fail-closed behavior, and fallback-only remembered env semantics. Third, extend the existing release-contract tests so these wording constraints become machine-checked and harder to drift. [INFERENCE from verified evidence]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 47 | Why |
|---------|-----------------------------|-----|
| `README.md` | Own the public support boundary, canonical mounted proof command, and link routing into package/runbook detail | It is the front door and should stay truthful but not operationally verbose. [VERIFIED: README.md] |
| `rulestead_admin/README.md` | Own the exact mounted host contract, prerequisite behavior, and fallback semantics | It already documents the mount seam and should become the canonical fail-closed contract surface. [VERIFIED: rulestead_admin/README.md] |
| `rulestead/README.md` | Stay aligned with the runtime-first posture without widening into mounted-companion detail | It is a supporting sibling surface, not the main support-truth owner. [VERIFIED: rulestead/README.md] |
| `MAINTAINING.md` | Own named CI/proof lane semantics, `release_gate` wording, rerun guidance, and low-drift suite detail if needed | This is the maintainer-only operational truth surface. [VERIFIED: MAINTAINING.md] [VERIFIED: .github/workflows/ci.yml] |
| `rulestead/test/rulestead/release_contract_test.exs` | Enforce bounded doc claims and keep root/package/maintainer wording aligned | It already guards release-truth drift and is the best place to extend this phase's contract. [VERIFIED: release_contract_test.exs] |
| `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` | Optionally reinforce published-consumer contract assumptions for mounted package wording | It already encodes the mount/session/env consumer contract. [VERIFIED: verify_release_publish_test.exs] |

## Standard Stack

### Source-of-truth docs, scripts, and tests
- `README.md`
- `rulestead/README.md`
- `rulestead_admin/README.md`
- `MAINTAINING.md`
- `.github/workflows/ci.yml`
- `scripts/ci/test.sh`
- `rulestead/test/rulestead/release_contract_test.exs`
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs`

### Targeted proof commands
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash /Users/jon/projects/rulestead/scripts/ci/test.sh`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/release_contract_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/verify_release_publish_test.exs`

These commands keep Phase 47 bounded to support truth: the mounted proof bar remains green, and the release-contract tests become the durable drift guard for doc claims. [VERIFIED: repo-local rerun 2026-05-26] [INFERENCE: validation shape]

## Recommended Shape

### Pattern 1: Public docs name the command and the contract category, not the entire suite list
The root README should say what the mounted proof command proves in human terms: session, mount, env, lifecycle, and permission behavior for the mounted companion. It should stop short of listing every test file or implying that every admin surface is proven.

### Pattern 2: Package docs own fail-closed prerequisite truth
The package README should be explicit that explicit `?env=` selection is canonical, remembered env/session state is fallback-only convenience, and missing host-owned prerequisites fail closed rather than silently degrading into unsupported behavior.

### Pattern 3: Maintainer docs own workflow/job specifics
`MAINTAINING.md` may name the `mounted companion proof` job and `release_gate`, and may retain exact suite membership if it is still useful there, but it should drop phase-number framing and match current CI semantics precisely.

### Pattern 4: Extend existing drift guards instead of inventing new ones
`release_contract_test.exs` already checks public release truth. The safest Phase 47 implementation extends that test to assert the new bounded-claim wording, fail-closed language, and current maintainer gate semantics.

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Root docs keep enumerating suite files and drift every time the verifier scope changes | Slice 1 should remove exact suite membership from public docs and assert only bounded proof categories there. |
| Package docs leave fallback semantics implicit and readers misread remembered env as a primary contract | Slice 2 should make explicit URL/env precedence and fallback-only semantics first-class wording. |
| Maintainer docs continue to describe stale gate semantics and phase-era proof posture | Slice 3 should update `MAINTAINING.md` against `.github/workflows/ci.yml` and add tests that guard the new wording. |
| Drift guards stay too weak and the docs regress again in later mounted-proof changes | Slice 3 should strengthen `release_contract_test.exs` around both required phrases and banned phrases. |

## Validation Architecture

Phase 47 should use three waves:

1. **Public support-truth closure**: tighten root and package-facing docs around the canonical command and support boundary.
2. **Mounted contract wording closure**: make prerequisite, fail-closed, and fallback semantics explicit in `rulestead_admin/README.md`.
3. **Drift-guard closure**: update `MAINTAINING.md` and extend release-contract tests so wording stays aligned with CI and the mounted proof contract.

## Recommended Slice Boundary

### Slice 1
Update root and sibling-package docs to point to one bounded mounted companion proof command and support boundary without public suite inventory drift.

### Slice 2
Publish explicit missing-prerequisite, fail-closed, and fallback-only truth for the mounted companion surface in the package contract docs.

### Slice 3
Extend maintainer wording and release-contract tests so mounted proof claims, job names, and `release_gate` semantics stay machine-checked.

## Confidence

- Verification: HIGH - the mounted companion proof command is green in this workspace on 2026-05-26. [VERIFIED: repo-local rerun 2026-05-26]
- Scope control: HIGH - roadmap, context, and AGENTS all point to a narrow docs/truth phase rather than new product behavior. [VERIFIED: roadmap] [VERIFIED: 47-CONTEXT.md] [VERIFIED: AGENTS.md]
- Implementation fit: HIGH - the repo already has the correct doc surfaces and an existing release-contract test suite that can absorb the new drift guards cleanly. [VERIFIED: README.md] [VERIFIED: rulestead_admin/README.md] [VERIFIED: MAINTAINING.md] [VERIFIED: release_contract_test.exs]

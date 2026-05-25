# Phase 41: Release Truth Alignment - Pattern Map

**Mapped:** 2026-05-24
**Files analyzed:** 11
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | root-doc | public front door | current file plus Phase 38 README routing pattern | role-match |
| `rulestead/README.md` | package-doc | runtime package contract | current file | exact |
| `rulestead_admin/README.md` | package-doc | mounted companion contract | current file plus Phase 38 admin-posture pattern | role-match |
| `guides/introduction/installation.md` | onboarding-doc | dependency and install path truth | current file | exact |
| `guides/introduction/getting-started.md` | onboarding-doc | first-success path | current file | exact |
| `guides/introduction/upgrading.md` | support-doc | release and compatibility posture | current file | exact |
| `examples/demo/README.md` | proof-doc | runnable demo truth | current file | exact |
| `open_feature_rulestead/README.md` | companion-doc | optional bridge posture | current file | exact |
| `MAINTAINING.md` | maintainer-doc | release verification truth | current file | exact |
| `rulestead/test/rulestead/release_contract_test.exs` | doc-contract test | machine-backed public-surface enforcement | current file | exact |
| `.planning/phases/41-release-truth-alignment/41-01-PLAN.md` | plan-doc | execution contract | `.planning/phases/38-lifecycle-docs-runbooks-verification/38-01-PLAN.md` | role-match |

## Pattern Assignments

### `README.md` (root-doc, public front door)

**Analog:** current root README structure plus Phase 38’s “one spine, many entry points” release-surface discipline

**Pattern**
- Keep the broad product story and quickstart at the root.
- Put the high-risk truth once, early, and route outward.
- Use short intentional cross-links instead of duplicating companion narratives.

**Why it matters for Phase 41**
- The root README is where the repo can explain “GA shipped at the repo level; current installable package line is `0.1.x`” without making every package README carry a full release memo.

### `rulestead/README.md` and `rulestead_admin/README.md` (package-docs)

**Analog:** current sibling package split plus Phase 38 mounted-companion posture

**Pattern**
- Keep package READMEs narrow and contract-oriented.
- Use one short release note and link back to shared docs for the broader story.
- Preserve the mounted companion boundary and host-owned seams explicitly.

**Why it matters for Phase 41**
- These files currently carry stale future-release wording and are the most likely place to drift into standalone-admin or duplicated-release-note posture.

### `installation.md`, `getting-started.md`, `upgrading.md` (onboarding/support docs)

**Analog:** current guide split under `guides/introduction/`

**Pattern**
- `installation.md` owns package-boundary choice.
- `getting-started.md` owns the first-success path.
- `upgrading.md` owns compatibility posture and release expectations.

**Why it matters for Phase 41**
- These guides must agree on the same shipped package truth or adopters will see conflicting answers depending on entrypoint.

### `examples/demo/README.md` and `open_feature_rulestead/README.md` (proof/companion docs)

**Analog:** current demo guide plus minimal companion README pattern

**Pattern**
- Demo docs should stay runnable and concrete.
- Companion bridge docs can be narrow, but the root docs should label them correctly.
- Secondary surfaces should be discoverable without becoming default onboarding paths.

**Why it matters for Phase 41**
- The demo is one of the few strong proof seams the repo has today; the bridge surface exists but is under-described, so its posture must remain bounded.

### `MAINTAINING.md` and `release_contract_test.exs` (guardrail surfaces)

**Analog:** current release-publish/parity guidance plus existing lifecycle doc-contract test pattern

**Pattern**
- Maintainer docs state the release-truth posture and the exact verification commands.
- `release_contract_test.exs` enforces public doc claims that should not drift silently.

**Why it matters for Phase 41**
- This phase’s main failure mode is future wording drift, not runtime regressions. The guardrail needs to live in tests and maintainers’ checklist.

## Shared Patterns

### One broad story, many narrow surfaces
The root owns the broad release story; package and companion docs stay narrow and factual.

### Runtime-first path, immediate optional admin continuation
The default install/onboarding path starts with `rulestead`, then offers `rulestead_admin` as the next Phoenix-host step when needed.

### Bounded proof over confidence theater
Docs should cite the demo and post-publish verification tasks as today’s proof seams and avoid implying broader closure.

### Tests for wording that changes support expectations
If a phrase materially changes what adopters think is shipped or supported, it belongs in a doc-contract assertion.

## Do Not Duplicate

- Do not repeat the full repo-GA versus package-line explanation in every package README.
- Do not promote `open_feature_rulestead` or the demo as equal first-choice install paths.
- Do not describe `rulestead_admin` as a standalone admin product.
- Do not leave support truth only in prose without a release-contract assertion.

## Minimal Planner Notes

- Use one execute plan with three tasks: root/package READMEs, onboarding/support/companion docs, then release-facing tests and maintainer guidance.
- Keep verification centered on `mix test test/rulestead/release_contract_test.exs` plus explicit `rg` checks across the touched doc surfaces.
- Require the final docs to surface `v1.0.0` on 2026-05-21, the current `0.1.0` package line, runtime-first onboarding, optional mounted admin, and bounded proof posture.

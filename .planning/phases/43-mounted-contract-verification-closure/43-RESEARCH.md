# Phase 43: Mounted Contract & Verification Closure - Research

**Researched:** 2026-05-25
**Domain:** Mounted-admin contract truth, lifecycle permission boundary, stale authored-state test repair, and cross-package verification closure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep `/cleanup`, `/cleanup/preview`, and `/cleanup/confirm` as supported route-backed workflow steps, while keeping the durable host-facing mounted contract narrower than every internal route detail. [VERIFIED: 43-CONTEXT.md] [VERIFIED: router/docs]
- Lock lifecycle permissions so `cleanup` remains readable to viewer-class operators, while `preview` and `confirm` require execute/admin capability. [VERIFIED: 43-CONTEXT.md] [VERIFIED: cleanup views]
- Treat the manual authored lifecycle/ownership payload as the merge-blocking proof boundary: `owner_ref`, `owner_kind`, `owner_display`, `lifecycle_mode`, and `review_by`. Convenience picker/defaulting behavior may keep bounded coverage but is not release truth. [VERIFIED: 43-CONTEXT.md] [VERIFIED: form_test]
- Require targeted full green for the mounted-admin lifecycle/admin-contract suites; use bounded caveats only if a non-targeted verification surface remains outside this phase boundary. [VERIFIED: 43-CONTEXT.md] [VERIFIED: roadmap]

### the agent's Discretion
- Exact docs wording that distinguishes stable mounted seam from supported route-backed workflow, provided the host-owned auth/session boundary stays explicit.
- Exact helper shape for replacing stale legacy test seeds, provided the new helper encodes the Phase 42 authored payload contract directly.
- Exact targeted verification command set, provided it covers mounted lifecycle queue, cleanup review, preview, confirm, mount seam, and the already-green manual form proof.

### Deferred Ideas (OUT OF SCOPE)
- New lifecycle capabilities, cleanup automation, or wider role-system redesign
- Broad `rulestead_admin` suite cleanup unrelated to lifecycle/admin-contract truth
- Standalone `rulestead_admin` release posture or any package-boundary widening
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | The mounted admin lifecycle form and permission contract expose one deliberate host-facing truth, with tests and docs aligned to the supported behavior. | Use the already-passing manual form contract as the authoring truth, then align route/docs language and permission tests around cleanup read access plus preview/confirm execute access. [VERIFIED: requirements] [VERIFIED: targeted rerun] |
| VER-01 | `rulestead` and `rulestead_admin` verification surfaces are green again, or any intentionally deferred failures are explicitly documented and bounded in release-facing truth. | Repair deterministic stale authored-state seeds in the lifecycle/admin-contract suites first, then rerun a narrow cross-package proof bar and document any residual non-lifecycle caveat honestly if one remains outside the phase target. [VERIFIED: requirements] [VERIFIED: targeted rerun] |
</phase_requirements>

## Project Constraints

- Stay inside the active Phase 43 boundary from `.planning/ROADMAP.md`; do not widen into Phase 44 OpenFeature work or standalone admin packaging. [VERIFIED: AGENTS.md] [VERIFIED: roadmap]
- Preserve the linked-version sibling-package model and mounted-companion posture. [VERIFIED: AGENTS.md] [VERIFIED: README/docs]
- Prefer the smallest coherent closure change set: fix contract drift, encode proof, and avoid speculative admin cleanups. [VERIFIED: AGENTS.md]

## Summary

The current repo evidence supports the Phase 43 thesis directly. The mounted-admin manual authoring contract is already green in `rulestead_admin/test/rulestead_admin/live/flag_live/form_test.exs`, but the queue and cleanup-family suites fail deterministically because their seeded flags still use pre-Phase-42 top-level fields such as `owner`, `permanent`, and `expected_expiration`. The failure mode is not flaky infrastructure or ambiguous product direction; it is authored-state drift between shipped code and stale mounted tests. [VERIFIED: targeted rerun] [VERIFIED: index/cleanup tests]

The mounted route surface itself is already implemented and coherent: `rulestead_admin/lib/rulestead_admin/router.ex` exposes `/cleanup`, `/cleanup/preview`, and `/cleanup/confirm`, while the LiveViews enforce the intended permission split. `Cleanup` checks `capabilities.read?`, and both `CleanupPreview` and `CleanupConfirm` require execute/admin capability. That means the dominant Phase 43 work is not inventing a new flow; it is clarifying which parts are stable host-facing seams in docs and mount tests, and bringing stale proof fixtures back into line with the shipped behavior. [VERIFIED: router.ex] [VERIFIED: cleanup views]

The docs already lean in the right direction but still need tighter wording. `guides/flows/admin-ui.md` and `guides/flows/flag-lifecycle.md` describe the lifecycle workflow, yet the distinction between the stable mounted seam (`rulestead_admin` mount, `policy:`, session inputs, `?env=`, `return_to`) and the supported route-backed cleanup workflow can be made more explicit. That gives Phase 43 a narrow documentation task: preserve the mounted-companion boundary, document cleanup -> preview -> confirm -> audit as the supported workflow, and avoid accidentally freezing every internal route detail as public API. [VERIFIED: docs] [VERIFIED: 43-CONTEXT.md]

The strongest implementation recommendation is therefore a three-part plan. First, tighten the public contract language and mount-seam proof. Second, repair the lifecycle/admin-contract test seeds and helpers so they encode the Phase 42 authored payload directly. Third, rerun a targeted cross-package verification bar and update any bounded release/support truth only if a residual non-lifecycle caveat remains outside the repaired target suites. This keeps the phase honest, merge-blocking, and deliberately narrow. [INFERENCE from verified evidence]

## Architectural Responsibility Map

| Surface | Responsibility in Phase 43 | Why |
|---------|-----------------------------|-----|
| `rulestead_admin/README.md`, `guides/flows/admin-ui.md`, `guides/flows/flag-lifecycle.md` | Clarify the mounted companion contract, stable seam, and supported cleanup workflow wording | Docs currently describe the flow but need a sharper stable-vs-supported distinction. [VERIFIED: docs] |
| `rulestead_admin/lib/rulestead_admin/router.ex` and `test/rulestead_admin/integration/admin_mount_test.exs` | Prove the public host seam keeps `?env=` and mounted cleanup review conventions without promising standalone behavior | Route exposure already exists; Phase 43 should lock the intended contract in proof. [VERIFIED: router/test] |
| `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`, `cleanup_test.exs`, `cleanup_preview_test.exs`, `cleanup_confirm_test.exs` | Replace stale top-level authored-state seeds with the embed-based manual contract and preserve the permission split | These suites are the deterministic failure cluster from the targeted rerun. [VERIFIED: targeted rerun] |
| `rulestead_admin/test/.../form_test.exs` | Stay as the reference truth for manual lifecycle/ownership authoring | It already passes and encodes the intended public authoring payload. [VERIFIED: targeted rerun] |
| `scripts/ci/test.sh` and release/support docs only if needed | Capture the repaired verification surface or bounded caveat explicitly | `VER-01` requires honest green or bounded truth, but only for the relevant cross-package verification seam. [VERIFIED: requirements] |

## Standard Stack

### Source-of-truth code and docs
- `rulestead_admin/lib/rulestead_admin/router.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_preview.ex`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_confirm.ex`
- `rulestead_admin/README.md`
- `guides/flows/admin-ui.md`
- `guides/flows/flag-lifecycle.md`

### Targeted proof commands
- `cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/live/flag_live/form_test.exs test/rulestead_admin/live/flag_live/index_test.exs test/rulestead_admin/live/flag_live/cleanup_test.exs test/rulestead_admin/live/flag_live/cleanup_preview_test.exs test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs test/rulestead_admin/integration/admin_mount_test.exs`
- `cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/admin_contract_test.exs test/rulestead/admin_lifecycle_test.exs`

These are the narrowest commands that cover the mounted lifecycle/admin contract truth without widening into unrelated admin or OpenFeature work. [VERIFIED: targeted rerun] [INFERENCE: scoped command set]

## Recommended Shape

### Pattern 1: Treat `form_test.exs` as the authoring contract analog
The form suite already proves the right payload shape. Reuse that contract in queue/cleanup fixtures instead of inventing another lifecycle seed vocabulary. [VERIFIED: targeted rerun]

### Pattern 2: Keep permission proof route-specific
`cleanup` should continue to prove read access for viewer-class actors, while `preview` and `confirm` continue to prove live redirect for unauthorized actors. This is already encoded by the LiveViews and should be asserted directly in tests. [VERIFIED: cleanup views/tests]

### Pattern 3: Separate stable seam proof from internal route implementation proof
Mount docs and `admin_mount_test.exs` should prove `policy:`, session keys, `?env=`, `return_to`, and cleanup route availability. They should not freeze socket assigns, internal helpers, or every nested route detail as public API. [VERIFIED: README/docs] [VERIFIED: router/test]

## Risks and Planning Implications

| Risk | Planning Implication |
|------|----------------------|
| Additional lifecycle/admin suites outside the initial target set still seed legacy top-level fields | The repair plan should allow one bounded follow-on sweep inside the same mounted lifecycle/admin surface, but avoid repo-wide stale-seed cleanup. |
| Docs overcorrect and imply `/cleanup/preview` or `/cleanup/confirm` are frozen forever as public API | Documentation tasks must preserve the “supported route-backed workflow” wording instead of promoting every internal step to stable API. |
| A residual `rulestead` verification failure remains after the mounted suites are green | Final verification tasks must either fix that targeted core contract issue or bound it explicitly in release/support truth rather than claiming ambiguous green. |

## Validation Architecture

Phase 43 should use three waves:

1. Docs and mount-seam truth: tighten wording and route-level integration proof.
2. Lifecycle/admin-contract seed repair: update queue/cleanup/preview/confirm suites to the Phase 42 authored payload and preserve the permission split.
3. Cross-package verification closure: rerun the narrow proof bar across `rulestead_admin` plus the core admin/lifecycle suites, then encode any residual bounded caveat only if it remains outside the repaired target.

## Recommended Slice Boundary

### Slice 1
Clarify the mounted companion contract and stable-vs-supported lifecycle workflow language in docs and mount tests.

### Slice 2
Repair stale lifecycle/admin test seeds and helper patterns so the targeted mounted suites go green again.

### Slice 3
Re-run the cross-package lifecycle/admin verification bar and reconcile any remaining bounded truth in CI or release-facing docs if needed.

## Confidence

- Architecture: HIGH - the route and permission structure already exists; the dominant gap is proof and wording drift. [VERIFIED: router/views/docs]
- Verification: HIGH - the failing suites are deterministic and localized to stale authored-state seeds. [VERIFIED: targeted rerun]
- Scope control: HIGH - the roadmap, requirements, and context all point to mounted contract closure rather than new product work. [VERIFIED: roadmap] [VERIFIED: requirements] [VERIFIED: 43-CONTEXT.md]

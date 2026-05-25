# Phase 43: Mounted Contract & Verification Closure - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning
**Source:** discuss-all synthesis with parallel advisor research, prompt-anchor review, mounted-admin code/test inspection, targeted verification reruns, and ecosystem reference checks

<domain>
## Phase Boundary

Close mounted-admin lifecycle and verification drift so the mounted companion exposes one deliberate host-facing contract and the sibling-package proof surface returns to honest green without widening product scope, changing the linked-version package model, or turning `rulestead_admin` into a standalone control plane.

**In scope:**
- mounted-admin lifecycle route/documentation truth
- mounted-admin lifecycle permission truth
- mounted-admin lifecycle authoring proof boundary
- targeted verification closure for mounted-admin lifecycle/admin contract drift
- bounded release/support-truth wording where proof scope must stay narrow

**Out of scope:**
- new lifecycle capabilities, new cleanup automation, or new admin product surfaces
- host-owned identity/directory expansion beyond the existing policy/session seams
- broad admin-wide green-everything cleanup unrelated to lifecycle/contract truth
- package-boundary changes or standalone `rulestead_admin` preparation

</domain>

<decisions>
## Implementation Decisions

### Recommendation-first collaboration posture
- **D-01:** Phase 43 should be planned and executed recommendation-first. Downstream agents should resolve ordinary tradeoffs in-agent after reading code, prior context, and prompt anchors, and should escalate only choices that materially change public contract, security/governance posture, package boundary, or milestone scope.
- **D-02:** Treat the project-level methodology as active Phase 43 input: read prompt anchors first, research before asking, and return one cohesive recommendation set across route contract, permissions, proof posture, and verification instead of reopening each local tradeoff independently.

### Mounted lifecycle route contract
- **D-03:** Keep `/cleanup`, `/cleanup/preview`, and `/cleanup/confirm` as **supported route-backed workflow steps**, but do **not** promote all three into the first-class stable mounted URL contract.
- **D-04:** The durable mounted contract remains:
  - mount seam via `rulestead_admin`
  - host-owned `policy:` and session inputs
  - canonical `?env=` selector
  - queue-preserving `return_to` behavior for lifecycle review flows
- **D-05:** Docs should describe `cleanup -> preview -> confirm -> audit` explicitly as the supported lifecycle workflow, while keeping the “stable mounted navigation layer” narrower than every internal route step.
- **D-06:** If future demand ever forces route-promotion, promote `/cleanup` before freezing `/cleanup/preview` or `/cleanup/confirm`; preview/confirm should remain the most flexible IA layer for now.

### Lifecycle permission boundary
- **D-07:** Lock the lifecycle permission split as:
  - `cleanup` is an advisory read/review surface and remains readable to viewer-class/read-only operators
  - `preview` is the first governed mutation surface and requires execute/admin-capable authorization
  - `confirm` is the final mutation surface and requires execute/admin-capable authorization
- **D-08:** Do not widen preview to viewer-readable status. That blurs the safe read path with the governed mutation path and weakens least-surprise security semantics.
- **D-09:** Do not restrict cleanup review to edit/execute/admin only. That would over-tighten advisory review, reduce support/on-call usefulness, and push hosts toward unnecessary privilege inflation.
- **D-10:** Preserve the host-owned auth seam. Phase 43 should clarify the public lifecycle capability boundary, not invent a new Rulestead-owned role model beyond the existing host policy contract.

### Mounted authoring proof boundary
- **D-11:** Phase 43 public proof should lock the **manual authored lifecycle/ownership contract** only:
  - `owner_ref`
  - `owner_kind`
  - `owner_display`
  - `lifecycle_mode`
  - `review_by`
- **D-12:** The optional owner picker, picker-driven prefill behavior, and lifecycle suggestion/defaulting are **convenience seams**, not public proof obligations. They may keep bounded regression coverage, but they are not release-truth requirements.
- **D-13:** Docs should state plainly that host apps may optionally prefill or validate owner/lifecycle inputs through mounted seams, but the stable guarantee is the authored payload shape that reaches core state.
- **D-14:** Do not let code-only convenience behavior silently become public API. If a mounted form behavior is not documented as public contract, Phase 43 should not elevate it into release-gating truth by accident.

### Verification closure posture
- **D-15:** Require **targeted full green** for the mounted-admin lifecycle/verification truth suites as the Phase 43 merge-blocking bar. Use bounded caveats only as short-lived working notes while fixing deterministic drift, not as the release posture.
- **D-16:** The Phase 43 verification target is the mounted companion lifecycle/admin contract surface specifically, not a vague “admin broadly looks healthy” standard and not a broad repo-wide unrelated cleanup pass.
- **D-17:** Current drift evidence indicates deterministic stale-test-shape failures after Phase 42, not flaky infra:
  - several mounted lifecycle tests still seed legacy authored fields such as `owner`, `permanent`, and `expected_expiration`
  - the newer manual authored contract proof already passes in the updated form suite
- **D-18:** Planning should treat stale test seeds and any adjacent lifecycle docs/tests using the pre-Phase-42 authored shape as first-class closure work, because that is exactly the contract drift Phase 43 exists to remove.
- **D-19:** Final release/support truth for `v1.3.0` should only claim “green” once the targeted mounted-admin lifecycle truth suites are green again and any remaining non-lifecycle caveats are explicitly verified and bounded.

### the agent's Discretion
- Exact wording used to distinguish “stable mounted contract” from “supported route-backed workflow”
- Exact test suite curation for the targeted Phase 43 truth bar, provided it remains lifecycle/admin-contract focused
- Exact docs placement for the manual-authored-contract note and convenience-seam caveat
- Exact regression-test split between merge-blocking contract tests and non-gating convenience tests

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“stable mount seam, explicit workflow seam”**, not “every mounted route is public API.”
- The winning lifecycle story is:
  - queue/read surface first
  - guarded preview second
  - explicit confirm third
  - audit-linked queue return last
- The best adjacent product lessons are:
  - LaunchDarkly: cleanup/archive should be explicit, warning-heavy, typed-confirmation-safe, and code-aware
  - Unleash: lifecycle/staleness should drive cleanup review, not hidden archive automation
  - Oban Web / Phoenix LiveDashboard: mounted Elixir operator tools should stabilize mount/access/filter seams more than every inner route detail
- The public mounted proof should stay centered on stable authored facts and host-owned seams, not on convenience UI behavior that happens to exist today.
- Current local evidence from 2026-05-25:
  - targeted core `rulestead` admin/security/release-contract checks passed
  - targeted `rulestead_admin` lifecycle suites failed primarily because test seeds still use stale legacy authored fields after the Phase 42 contract change
  - one separate local `rulestead` manifest-export failure was observed outside the mounted-admin lifecycle target and should be re-audited before any final milestone-wide “everything green” claim

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active milestone truth
- `.planning/ROADMAP.md` — Phase 43 goal, success criteria, and the “honest green or bounded truth” milestone framing
- `.planning/PROJECT.md` — `v1.3.0` support-truth rationale, sibling-package model, and mounted companion posture
- `.planning/REQUIREMENTS.md` — `ADM-01` and `VER-01` requirement definitions
- `.planning/STATE.md` — active milestone state, current proof-closure posture, and Phase 42 carryover
- `.planning/METHODOLOGY.md` — recommendation-first and research-then-recommend defaults that should govern Phase 43 decisions

### Prior locked decisions that still apply
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-CONTEXT.md` — authored ownership/lifecycle truth, host-owned owner seam, manual-entry contract, and convenience-suggestion boundary
- `.planning/phases/37-mounted-admin-lifecycle-workbench/37-CONTEXT.md` — canonical lifecycle workbench, route-backed lifecycle flow, exact owner-filter semantics, and queue-return posture
- `.planning/phases/38-lifecycle-docs-runbooks-verification/38-CONTEXT.md` — mounted companion docs strategy, lifecycle workflow narrative, and verification philosophy
- `.planning/phases/40-lifecycle-workbench-verification-state-reconciliation/40-CONTEXT.md` — recent lifecycle verification/state-reconciliation closure discipline
- `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` — mounted companion release posture, bounded proof language, and support-truth discipline
- `.planning/phases/42-runtime-contract-parity/42-CONTEXT.md` — Phase 42 authored-state contract changes that stale mounted tests now need to follow

### Prompt anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator IA, explicit mutation workflow, and calm review UX
- `prompts/rulestead-host-app-integration-seam.md` — host-owned auth/session seam and mounted-companion boundary
- `prompts/rulestead-security-privacy-and-threat-model.md` — default-deny admin mutation posture and environment-sensitive auth guidance
- `prompts/rulestead-testing-and-e2e-strategy.md` — release-gate proof philosophy and host/companion verification expectations
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package discipline, mounted companion patterns, and public-contract rigor
- `prompts/rulestead-domain-language-field-guide.md` — canonical lifecycle, owner, archive, and operator vocabulary
- `prompts/phoenix-live-view-best-practices-deep-research.md` — route-backed LiveView state, public-vs-internal UI seams, and test guidance

### Current public/doc surfaces to align
- `guides/flows/admin-ui.md` — current stable mounted navigation language and lifecycle workflow wording
- `guides/flows/flag-lifecycle.md` — canonical lifecycle narrative and preview/confirm/audit workflow
- `rulestead_admin/README.md` — mounted companion contract, host session inputs, and public-surface boundary
- `README.md` — root sibling-package posture and bounded support truth

### Current code and verification seams
- `rulestead_admin/lib/rulestead_admin/router.ex` — mounted route family and current lifecycle route exposure
- `rulestead_admin/lib/rulestead_admin/live/flag_live/form.ex` — manual authored contract, optional picker/defaulting behavior, and current form validation semantics
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` — lifecycle queue, `return_to`, and mounted filter contract
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` — advisory cleanup review boundary
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_preview.ex` — first governed mutation surface
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup_confirm.ex` — final archive confirmation surface
- `rulestead_admin/test/rulestead_admin/live/flag_live/form_test.exs` — updated manual authored contract proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` — currently stale lifecycle queue seed shape
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` — cleanup review semantics and stale legacy authored-state seeding
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` — preview permission semantics and stale legacy seeding
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` — confirm semantics, drift revalidation, and stale legacy seeding
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` — mounted host-facing route/env contract proof
- `scripts/ci/test.sh` — current sibling-package test gate shape

### Ecosystem references that informed the recommendation set
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` — `push_patch` / `push_navigate` / `handle_params/3` route-state idioms
- `https://oban.pro/docs/web/overview.html` — mounted operator-tool posture, read-only vs control split, and filter-first dashboard expectations
- `https://launchdarkly.com/docs/fed-docs/home/flags/archive` — explicit archive review, typed confirmation, and code-aware cleanup posture
- `https://docs.getunleash.io/concepts/feature-flags` — lifecycle stage model, cleanup guidance, and archive posture
- `https://docs.getunleash.io/concepts/technical-debt` — stale-flag cleanup framing and workflow lessons
- `https://docs.getunleash.io/concepts/rbac` — role separation and archive/control permission lessons

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The mounted lifecycle queue, cleanup review, preview, and confirm routes already exist with route-backed `env` and `return_to` semantics; Phase 43 is mostly about contract clarification and proof repair, not inventing a new flow.
- `FlagLive.Form` already embodies the correct manual authored shape and should be the reference truth for lifecycle/ownership authoring tests.
- `FlagLive.CleanupConfirm` already encodes the strongest safety semantics Phase 43 should preserve: reason capture, typed confirmation in production, and preview-state revalidation before mutation.
- `admin_mount_test.exs` already proves the mounted host seam pattern Phase 43 should continue to reinforce.

### Established Patterns
- Mounted admin favors route-backed, shareable workflow state rather than modal-only destructive flows.
- Host apps own authorization and identity; mounted admin consumes policy/session seams rather than defining an internal auth model.
- Public truth is intentionally narrower than internal LiveView/module implementation details.
- Release/support truth in this repo is enforced through named tests and verification tasks, not through prose alone.

### Integration Points
- Lifecycle contract docs should align with the existing router and route-backed LiveView flow rather than redesigning navigation.
- Phase 42’s embed-based authored contract should become the single seed shape across all mounted lifecycle tests.
- Release/support truth should connect docs, mounted tests, and CI gate expectations so the companion surface is either green or explicitly bounded.

</code_context>

<deferred>
## Deferred Ideas

- Promoting preview/confirm into the first-class stable mounted URL contract
- Broader admin-wide green-everything cleanup outside lifecycle/admin-contract truth
- New lifecycle automation, bulk cleanup/archive, or richer review-role semantics
- Standalone `rulestead_admin` product posture or any package-boundary widening

</deferred>

---

*Phase: 43-mounted-contract-verification-closure*
*Context gathered: 2026-05-25*

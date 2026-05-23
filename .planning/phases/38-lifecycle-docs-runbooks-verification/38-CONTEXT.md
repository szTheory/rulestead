# Phase 38: Lifecycle Docs, Runbooks, & Verification - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning
**Source:** discuss-all synthesis with subagent research, prior lifecycle phase context, prompt-anchor review, codebase inspection, and existing release/doc/test surface analysis

<domain>
## Phase Boundary

Document and verify the lifecycle system as one coherent “flag from birth to retirement” operator story for Phoenix teams, using the already-locked lifecycle, readiness, mounted-admin, CLI, and audit semantics from Phases 35-37 without widening product scope, changing package boundaries, or inventing a new control plane.

**In scope:**
- shared docs and runbooks that teach lifecycle authoring, triage, review, cleanup, and verification coherently
- least-surprise guidance for lifecycle defaults, host-owned ownership, and advisory archive-readiness
- release-surface verification that proves docs, CLI, and mounted-admin host seams stay aligned
- milestone closeout evidence for lifecycle workflows and support-truth coverage

**Out of scope:**
- new lifecycle product capabilities beyond documentation and verification
- standalone lifecycle docs site or standalone `rulestead_admin` product posture
- broad browser E2E expansion or UI-contract stabilization of internal DOM/CSS details
- new automation such as auto-archive, auto-cleanup, or policy engines hidden behind docs language

</domain>

<decisions>
## Implementation Decisions

### Product shape and recommendation posture
- **D-01:** Phase 38 should stay recommendation-first and cohesive. Downstream agents should not reopen routine doc-IA, wording, or verification tradeoffs unless a choice would materially change public contract, security/governance posture, package boundaries, or milestone scope.
- **D-02:** The lifecycle story must remain anchored in the linked-version sibling-package shape: `rulestead` owns the shared lifecycle docs surface, while `rulestead_admin` remains documented as the mounted companion rather than a standalone control plane.
- **D-03:** Docs must preserve the prior milestone truth: operators author facts, Rulestead computes guidance, and archive/cleanup actions stay explicit, previewable, and audited.

### Documentation shape
- **D-04:** Use a **hybrid docs shape**: one narrative “birth to retirement” lifecycle guide as the primary spine, plus focused reference/runbook satellites rather than either a single giant page or a scattered set of lightly linked updates.
- **D-05:** The primary lifecycle story should live in the shared root docs/guides surface, not in `rulestead_admin/README.md`, because the lifecycle workflow spans runtime guidance, mounted-admin review, CLI reporting, and release verification.
- **D-06:** The spine guide should stay narrative and operator-oriented. Focused satellites should carry exact host-facing details for mounted-admin workflow, CLI/reporting surface, testing/verification, and release/maintainer posture.
- **D-07:** Prefer extending the existing guide architecture rather than inventing a parallel doc taxonomy. Phase 38 should fit into the established `guides/introduction`, `guides/flows`, and `guides/recipes` structure plus existing README surfaces.
- **D-08:** Root and sibling READMEs should advertise the lifecycle story clearly enough that a new reader can discover the canonical guide without hunting through unrelated rollout or explainability docs.

### Runbook emphasis and narrative order
- **D-09:** The main runbook spine should be **triage/review first**, not authoring-first and not cleanup-first. The canonical daily operator workflow is the mounted-admin workbench plus CLI parity from Phase 36/37.
- **D-10:** The recommended lifecycle narrative order is:
  - brief authored-defaults and ownership framing
  - primary triage/review workflow in mounted admin plus read-only CLI
  - explicit archive/cleanup execution workflow with preview, reason, and audit linkage
  - ownership-handoff / unknown-owner exception handling
  - support/SRE lookup appendix using explainability, lifecycle evidence, and audit history
- **D-11:** Archive execution deserves its own dedicated chapter immediately after triage because it is the highest-safety mutation path, but it must not become the conceptual center of the lifecycle story.
- **D-12:** Ownership handoff and support/SRE workflows are important but secondary. They should be documented as exception/appendix flows, not as the primary day-to-day runbook.
- **D-13:** Admin and CLI must use one vocabulary for lifecycle, readiness, evidence quality, unknowns, blockers, and recommended next action. The docs should not create a second naming dialect.

### Guidance tone and DX posture
- **D-14:** Use a **layered tone**: strongly opinionated guidance for the default Phoenix path, with explicit reference sections for advanced or exceptional cases.
- **D-15:** The primary docs should recommend least-surprise defaults clearly:
  - host owns identity, actor/session semantics, and owner truth
  - lifecycle defaults are advisory scaffolding, not hidden policy
  - temporary flags should be reviewed and retired deliberately
  - permanent operational/permission posture is exceptional and should be explicit
  - archive-readiness is advisory evidence, not permission
- **D-16:** Advanced seams should still be documented plainly, not buried:
  - no-admin installs
  - host-owned customization points
  - mounted-admin companion boundaries
  - exception cases such as permanent operational flags, owner handoff, and missing evidence
- **D-17:** Do not use a neutral, encyclopedic tone for the main lifecycle guide. This milestone exists to teach a coherent lifecycle posture, and neutral docs would force users to reconstruct Rulestead’s intended operating model themselves.
- **D-18:** Do not over-compress the docs into a “one true workflow” that hides real extension seams. The docs must remain honest that Rulestead is a library with host-owned seams, not a SaaS platform with full policy control.

### Verification and closeout evidence
- **D-19:** Phase 38 should use a **release-surface verification backbone with narrow behavioral backstops**, not docs-only proof and not a large new browser matrix.
- **D-20:** Required verification layers should include:
  - release-surface contract checks across root README, sibling READMEs, shared guides, and maintainer/release docs
  - `mix rulestead.lifecycle` public contract tests for text output, JSON schema/version, filter semantics, and read-only guarantees
  - one mounted-admin host-flow contract layer that proves public route/env semantics and host-facing mount behavior without stabilizing internal DOM structure
  - milestone evidence artifacts that map `LIF-05` to exact tests/checks and recorded pass outputs
- **D-21:** Existing publish/parity verification tasks remain supporting evidence, but they are not sufficient on their own because they prove publish/install parity rather than lifecycle-doc and runbook coherence.
- **D-22:** Avoid browser-heavy E2E expansion in this phase unless a concrete uncovered lifecycle seam appears during planning. Phoenix/LiveView contract tests are the idiomatic default for the mounted package boundary here.
- **D-23:** Release-surface tests should verify only public/package-facing semantics. They must not accidentally freeze internal LiveView modules, socket assigns, CSS classes, or DOM selectors that the READMEs explicitly leave non-public.
- **D-24:** Milestone closeout evidence should be machine-backed and traceable to actual checks, not a hand-written narrative detached from test/task output.

### Cohesion guardrails
- **D-25:** Every Phase 38 doc and verification artifact should reinforce the same operator truth:
  - create with explicit ownership and lifecycle intent
  - review through one canonical queue/workbench
  - treat archive-readiness as evidence, not truth
  - mutate only through explicit preview/confirm/audit flows
  - preserve support and maintainer trust through stable release-facing documentation
- **D-26:** Planning should prefer reusing and tightening existing docs/tests rather than creating many new surfaces. The phase should feel like one coherent closeout pass over lifecycle truth, not a documentation sprawl milestone.

### the agent's Discretion
- Exact guide filenames and ExDoc grouping, provided the hybrid spine-plus-satellites structure remains intact
- Exact chapter and section titles, provided the runbook order and layered tone remain intact
- Exact release-surface test module split, provided verification stays focused on public seams and avoids internal DOM/API lock-in
- Exact milestone evidence artifact layout, provided `LIF-05` traceability to concrete checks remains explicit

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“one lifecycle story, many entrypoints”** rather than “a pile of lifecycle-related docs.”
- The likely winning doc shape is:
  - one new lifecycle spine guide in shared docs
  - focused updates to `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, and relevant existing guides such as admin UI, explainability, testing, and installation/getting-started surfaces
  - focused maintainer/release verification guidance rather than a new standalone QA subsystem
- The runbook should teach the operator motion as:
  - author intent
  - review queue
  - inspect evidence
  - preview cleanup
  - confirm with reason
  - retain audit/support truth
- Keep warning language explicit around the known footguns:
  - `archive_candidate` is not permission
  - unknown owner is not archive permission
  - deleting and recreating flag keys is dangerous
  - archived flags still require deliberate host-code cleanup discipline
- The repo already encodes the desired planning preference in `.planning/METHODOLOGY.md`: recommendation-heavy by default, escalate only for materially high-impact decisions. Phase 38 should reinforce that posture rather than adding a new workflow rule.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 38 goal, milestone framing, and explicit docs/runbooks/verification boundary
- `.planning/PROJECT.md` — `v1.2.0` rationale, lifecycle posture, sibling-package release design, and out-of-scope limits
- `.planning/REQUIREMENTS.md` — `LIF-05` plus adjacent lifecycle requirements that the docs must teach coherently
- `.planning/STATE.md` — current milestone position and active lifecycle milestone posture
- `.planning/METHODOLOGY.md` — recommendation-first and research-then-recommend lenses that should govern downstream planning

### Prior locked lifecycle decisions
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-CONTEXT.md` — authored ownership/lifecycle contract, host-owned owner refs, advisory defaults, and no persisted machine lifecycle truth
- `.planning/phases/36-archive-readiness-signals-cleanup-analysis/36-CONTEXT.md` — advisory archive-readiness model, CLI/reporting surface, and explicit uncertainty posture
- `.planning/phases/37-mounted-admin-lifecycle-workbench/37-CONTEXT.md` — one canonical mounted-admin workbench, preview/confirm/audit cleanup flow, and queue-first IA
- `.planning/phases/26-api-lockdown-and-documentation-perfection/26-CONTEXT.md` — prior documentation/release-contract discipline for a public Elixir library release line

### Prompt anchors
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — ExDoc/guide structure, sibling-package release discipline, release verification spine, and recommendation-first engineering DNA
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted-admin workflow posture, queue-first operator UX, and explicit preview/confirm/audit guidance
- `prompts/rulestead-release-engineering-and-ci.md` — release verification philosophy, docs as release surface, and publish/parity evidence posture
- `prompts/rulestead-testing-and-e2e-strategy.md` — test pyramid, Fake-first discipline, and caution against unnecessary browser-heavy proof
- `prompts/rulestead-host-app-integration-seam.md` — host-owned identity/layout posture and narrow mounted-admin contract expectations
- `prompts/rulestead-domain-language-field-guide.md` — canonical lifecycle, archive, ownership, and operator vocabulary
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — lifecycle docs consumers across app dev, operator, support, and SRE personas
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix web/domain boundaries, LiveView route/state patterns, and testing posture relevant to mounted-admin verification

### Existing docs and release surfaces
- `README.md` — root product front door and shared lifecycle discoverability entrypoint
- `rulestead/README.md` — runtime package entrypoint that should point readers into the lifecycle story without admin drift
- `rulestead_admin/README.md` — mounted-admin host contract and explicit non-standalone posture
- `guides/introduction/getting-started.md` — first-success path that may need lifecycle-story routing
- `guides/flows/admin-ui.md` — mounted-admin stable host-facing workflow guide
- `guides/flows/explainability.md` — support/operator explanation path that should connect to lifecycle evidence
- `guides/flows/evaluation.md` — runtime/evaluation framing that must stay coherent with lifecycle docs
- `guides/recipes/testing.md` — host-app test guidance and release-surface testing tone
- `guides/api_stability.md` — current public-surface contract discipline
- `rulestead/guides/README.md` — package tarball guide placeholder and shared-guides ownership hint

### Existing code and test seams
- `rulestead/lib/mix/tasks/rulestead.lifecycle.ex` — public lifecycle report task and CLI vocabulary
- `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs` — current lifecycle task contract coverage
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` — publish verification contract shape
- `rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs` — parity verification contract shape
- `rulestead/test/rulestead/release_contract_test.exs` — release-surface contract precedent
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` — mounted-admin public seam coverage precedent
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` — canonical lifecycle workbench route/filter surface
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — detail/lifecycle evidence presentation
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` — explicit cleanup review flow that docs and tests should describe, not reinvent

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix rulestead.lifecycle` already exists as the public read-only lifecycle/cleanup reporting seam and has contract tests worth extending rather than replacing.
- Root and sibling READMEs already encode the linked-package/public-surface split, so Phase 38 can tighten lifecycle discoverability without creating a third docs identity.
- `guides/flows/admin-ui.md`, `guides/flows/explainability.md`, `guides/recipes/testing.md`, and `guides/api_stability.md` already provide the surrounding doc satellites Phase 38 should reuse.
- Existing release verification tests and task contracts provide a strong precedent for treating docs and package behavior as publish-time surfaces.

### Established Patterns
- The repo prefers shared guides at the monorepo root, with sibling package READMEs staying narrow and host-contract focused.
- Public package contracts are intentionally explicit; internal LiveView implementation details are deliberately non-public.
- Verification culture already favors named Mix tasks and targeted ExUnit contract tests over vague manual QA or oversized browser matrices.
- Recommendation-heavy planning and least-surprise defaults are already established project methodology, not a new idea introduced by Phase 38.

### Integration Points
- Lifecycle narrative docs should connect root README and introduction surfaces to the new/updated lifecycle guide, then branch into admin UI, CLI, testing, and maintainer verification references.
- Release-surface verification should attach to existing contract-test and verify-task conventions rather than inventing a new verification subsystem.
- Mounted-admin lifecycle verification should test public mount/env semantics and queue/cleanup behavior through existing integration-style seams, not through DOM-heavy internal snapshots.

</code_context>

<deferred>
## Deferred Ideas

- Broader browser E2E expansion for lifecycle flows beyond the narrow public mounted-admin seam
- Standalone lifecycle control-plane documentation or separate admin product positioning
- New lifecycle product capabilities, automation, or policy engines beyond the already-locked Phase 35-37 semantics
- Global upstream changes to Codex/GSD defaults beyond the project-local methodology already recorded in `.planning/METHODOLOGY.md`

</deferred>

---

*Phase: 38-lifecycle-docs-runbooks-verification*
*Context gathered: 2026-05-23*

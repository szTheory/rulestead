# Phase 48: Final Verification & Archive Prep - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Source:** recommendation-first discuss synthesis with subagent-backed gray-area research, prompt-anchor review, prior milestone closeout evidence, and active planning-state inspection

<domain>
## Phase Boundary

Close `v1.4.0` by proving the repaired mounted companion support surface end to end, recording one formal verification artifact for the milestone, reconciling active planning truth against that evidence, and preparing a clean archive handoff to the next candidate without reopening product scope or widening the sibling-package posture.

**In scope:**
- fresh reruns of the bounded mounted companion proof surface and directly relevant support-truth checks
- one canonical Phase 48 verification artifact that closes milestone-wide requirement traceability
- active planning-doc updates that move the milestone to `ready_for_closeout` truth without overstating it as already archived/shipped
- lightweight next-milestone handoff truth for `v1.5.0`

**Out of scope:**
- broad full-repo regression sweeps as the public/milestone contract
- new browser/demo smoke bars or widened proof posture
- speculative `v1.5.0` spec, plans, or requirements work
- any package-boundary, rollout, targeting, or admin product-shape expansion

</domain>

<decisions>
## Implementation Decisions

### Verification breadth
- **D-01:** Phase 48 should use a **named proof-bar closeout bundle**, not a full-repo regression sweep and not a new browser/demo proof lane.
- **D-02:** The primary closeout proof remains `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` because it is the supported mounted companion contract bar adopters and maintainers are already told to trust.
- **D-03:** Add only directly relevant support-truth checks around that bar, especially release-contract and wording-drift checks that prove docs/scripts/CI still cite the same bounded mounted surface.
- **D-04:** Keep manual or host-app smoke paths advisory. They may inform maintainer confidence, but they do not redefine the Phase 48 merge/milestone contract.
- **D-05:** Do **not** treat “all admin tests green” as the closeout claim. The milestone closes a bounded mounted companion proof surface, not the entire future admin package.

### Evidence artifact shape
- **D-06:** Produce a single canonical `48-VERIFICATION.md` as the primary closeout artifact rather than splitting evidence across summaries or multiple loosely-coupled docs.
- **D-07:** `48-VERIFICATION.md` should stay index-style and evidence-backed: summarize commands, outcomes, and requirement closure; link to prior Phase 45-47 summaries and relevant earlier verification artifacts instead of pasting large raw logs.
- **D-08:** The artifact should include:
  - verdict/status frontmatter
  - milestone scope guard
  - canonical proof commands
  - observable truths
  - behavioral spot-checks
  - requirement coverage for `PKG-01`, `PKG-02`, `ADM-01`, `VER-01`, and `DOC-01`
  - artifact check / evidence map
  - gaps and archive handoff summary
- **D-09:** Do **not** add raw transcript annexes unless planning discovers a real audit/compliance need. They add noise and can blur the actual support contract.

### Traceability update posture
- **D-10:** Use an **evidence-first hybrid** sequence:
  - run the named proof bars
  - write `48-VERIFICATION.md`
  - update active planning truth to `ready_for_closeout` / satisfied-but-not-yet-archived
  - prepare milestone audit/closeout handoff
- **D-11:** Active planning docs must distinguish clearly between:
  - requirement satisfaction and milestone evidence closure
  - milestone archive/shipped completion
  Phase 48 should close the first and prepare the second.
- **D-12:** Do **not** defer active-doc updates until after archive. That leaves `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` knowingly stale during the most audit-sensitive moment.
- **D-13:** Do **not** update docs in a way that implies the milestone is already archived or that `v1.5.0` planning has begun in substance before standard closeout runs.

### Next-milestone handoff depth
- **D-14:** Refresh next-step truth at a **moderate** depth: enough that the repo clearly points to `v1.5.0 — Guarded Rollout Foundations` as the next recommended candidate, but not so much that Phase 48 starts pre-planning it.
- **D-15:** Update `ROADMAP.md`, `STATE.md`, `PROJECT.md`, and the milestone audit/closeout notes so they all agree on:
  - `v1.4.0` is ready for closeout once evidence lands
  - `v1.5.0` remains next
  - rollout guardrails stay host-supplied, auditable, fail-closed, and non-observability-expanding
- **D-16:** Do **not** create `v1.5.0` phase plans, specs, context docs, or refreshed requirement detail during Phase 48. That belongs to the next milestone’s own discuss/plan flow.

### Collaboration default for this repo
- **D-17:** Downstream planning for Phase 48 should stay recommendation-first and architect-oriented. The research here already narrows the viable options enough that no further user questionnaire is needed unless implementation uncovers a materially different public contract or closeout state.

### the agent's Discretion
- Exact selection of the directly relevant release-contract/support-truth test command set surrounding `mounted_admin_contract`, provided the proof bundle stays bounded and scripts-first.
- Exact wording and section ordering inside `48-VERIFICATION.md`, provided the artifact remains canonical, concise, and evidence-backed.
- Exact active-doc wording used to distinguish `ready_for_closeout` from archived/shipped, provided the status semantics remain explicit and consistent.

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“one bounded proof bundle, one canonical verification artifact, one truthful handoff.”**
- The winning Phase 48 story is:
  - rerun the named mounted companion proof bar
  - prove support-truth drift guards still match it
  - write one verification report that closes all `v1.4.0` requirements
  - update active planning truth to ready-for-closeout
  - point cleanly at `v1.5.0` without pre-planning it
- Ecosystem lessons to preserve:
  - Phoenix/LiveView proof should stay seam-oriented and route/mount/permission-focused
  - maintainers need one canonical rerun path, not a sprawling test matrix at closeout time
  - release/milestone docs should never imply a broader contract than the named proof bars actually certify

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone truth
- `.planning/ROADMAP.md` — Phase 48 goal, slices, and milestone guardrails
- `.planning/REQUIREMENTS.md` — `PKG-01`, `PKG-02`, `ADM-01`, `VER-01`, `DOC-01`, proof posture gate, and support-truth gate
- `.planning/PROJECT.md` — active milestone rationale, sibling-package posture, and next-milestone framing
- `.planning/STATE.md` — active planning position and expected closeout sequencing
- `.planning/MILESTONE-ARC.md` — next-candidate ranking and the guardrails around `v1.5.0`
- `.planning/METHODOLOGY.md` — recommendation-first, research-then-recommend, and architect-default discuss behavior

### Prior locked decisions that still apply
- `.planning/phases/46-mounted-proof-bar-restoration/46-CONTEXT.md` — bounded mounted proof-bar philosophy, CI lane semantics, and remediation posture
- `.planning/phases/47-support-truth-reclosure/47-CONTEXT.md` — root/package/maintainer support-truth split and mounted proof wording ownership
- `.planning/phases/43-mounted-contract-verification-closure/43-VERIFICATION.md` — strong analog for bounded mounted verification artifact shape
- `.planning/phases/39-lifecycle-contract-verification-closure/39-CONTEXT.md` and `.planning/phases/39-lifecycle-contract-verification-closure/39-VALIDATION.md` — “verification artifact first, traceability second” closeout discipline
- `.planning/v1.2.0-MILESTONE-AUDIT.md` — ready-for-closeout versus shipped/archive distinction

### Current proof and support surfaces
- `scripts/ci/test.sh` — canonical named mounted proof command and failure taxonomy
- `.github/workflows/ci.yml` — current mounted proof job and `release_gate` wiring
- `README.md` — public mounted proof/support statement
- `rulestead_admin/README.md` — exact mounted companion contract wording
- `MAINTAINING.md` — maintainer rerun/gate/runbook wording
- `rulestead/test/rulestead/release_contract_test.exs` — doc/support-truth contract checks
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs` — release-facing doc drift checks where mounted proof wording is already enforced

### Prompt anchors
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, named proof bars, release-gate philosophy
- `prompts/rulestead-testing-and-e2e-strategy.md` — bounded proof-surface philosophy and curated verifier posture
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package discipline, verification artifact style, and maintainer DX expectations
- `prompts/rulestead-host-app-integration-seam.md` — host-owned seam and mounted-contract philosophy
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — architect/operator expectations and low-surprise onboarding needs

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/test.sh` already centralizes the mounted proof scope and remediation messaging; Phase 48 should cite and rerun it rather than invent a new verification entrypoint.
- `rulestead/test/rulestead/release_contract_test.exs` already guards release/support wording; it is the natural support-truth companion check for the mounted proof bundle.
- Prior verification artifacts such as `43-VERIFICATION.md` provide a strong structural analog for a concise, evidence-backed closeout report.

### Established Patterns
- This repo treats named proof bars as product surfaces, not incidental maintainer habits.
- Verification artifacts are expected when requirement closure matters; summary-only claims are considered weaker and drift-prone.
- Planning truth is updated after evidence exists, with explicit distinction between satisfied/ready-for-closeout and archived/shipped.
- Companion surfaces stay bounded and support-truthful; manual smoke or broader demo paths remain secondary.

### Integration Points
- `48-VERIFICATION.md` is the integration point for proof results, requirement closure, and milestone handoff.
- `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` are the integration points for evidence-backed active truth updates after verification lands.
- Milestone audit and archive-prep artifacts are the integration points for handing off from `v1.4.0` to `v1.5.0` without starting next-milestone planning early.

</code_context>

<deferred>
## Deferred Ideas

- Converting manual host-app smoke into a new merge-blocking proof lane
- Broad full-repo closeout sweeps as the public milestone contract
- Any early `v1.5.0` spec, plan, or requirement drafting during Phase 48
- Any widening of the mounted companion support posture beyond the bounded named proof bar

</deferred>

---

*Phase: 48-final-verification-archive-prep*
*Context gathered: 2026-05-26*

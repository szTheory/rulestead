# Phase 60: Proof, Docs, And Support Truth - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.7 blast-radius governance with repo-local proof, release-contract drift guards, in-place doc updates, and quickstart API parity — without widening the linked sibling-package release model.

**In scope:** `mix verify.phase60` merge gate, `release_contract_test.exs` governance support-truth block, README/MAINTAINING/package README updates, in-place flow guide updates (admin-ui, multi-env), quickstart payload-first parity with `guides/flows/evaluation.md`, optional CI scope `blast_radius_governance`, phase verification artifact.

**Out of scope:** Core threshold/CR contract changes (Phases 57–58), mounted UX changes (Phase 59), new Phase 8-only docs (`api_stability.md`, etc.), standalone admin publish prep, observability-backed blast radius, host threshold profile UI, parallel governance workflow.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Merge gate composition (`mix verify.phase60`)
- **D-01:** Add `Mix.Tasks.Verify.Phase60` as the v1.7 merge gate using an **explicit flat test union** — phase56 core paths plus v1.7 delta paths. Do **not** call `verify.phase56` or other sub-tasks (same anti-duplication pattern as `verify.phase56.ex`).
- **Core union:** Retain all `@phase56_core_tests` from `verify.phase56.ex` plus governance delta:
  - `test/rulestead/governance/blast_radius_threshold_test.exs`
  - `test/rulestead/governance/audience_mutation_change_request_test.exs`
  - `test/rulestead/governance/audience_mutation_change_request_contract_test.exs`
  - `test/rulestead/governance/change_request_contract_test.exs`
  - `test/rulestead/admin_governance_policy_test.exs`
- **Admin union:** Retain phase56 `@admin_test_paths` plus governance delta from Phase 59 verification:
  - `test/rulestead_admin/components/governance_components_test.exs`
  - `test/rulestead_admin/live/governance_route_contract_test.exs`
  - `test/rulestead_admin/live/audience_live/governance_test.exs`
  - `test/rulestead_admin/live/audience_live/edit_confirm_governance_test.exs`
  - `test/rulestead_admin/live/change_request_live/show_test.exs`
  - Existing audience preview/confirm tests under `audience_live/` (edit/archive preview, archive confirm) remain included via directory glob or explicit paths.
- Register `verify.phase60` in `rulestead/mix.exs` `preferred_envs` alongside phase54–56.
- **Rationale:** VER-01 requires threshold + CR + stale-preview + fail-closed + audit proof in one maintainer command; phase56 alone does not cover v1.7 governance tests.

### D-02 — Release contract & support truth (VER-02)
- **D-02:** Extend `release_contract_test.exs` with a **“blast radius governance support truth stays bounded”** test block mirroring the v1.6 reusable-targeting block (~L338).
- Assert across root `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, and `MAINTAINING.md`:
  - `mix verify.phase60` present
  - Vocabulary: blast radius, threshold, protected environment, change request, fail closed, host-owned policy, preview basis / explicit samples
  - Package boundary: core owns domain + validation; admin owns mounted presentation; not standalone admin
  - `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh` in maintainer docs
- Reuse/extend existing `forbidden_phrases` lists — no observability-backed counts, no parallel governance workflow, no standalone admin, no auto-advance claims beyond deferred ROL-04.
- Root README **“Proof today”** adds v1.7 blast-radius governance entry **alongside** v1.6 `verify.phase56` (do not remove phase56).

### D-03 — In-place flow guide updates (VER-02)
- **D-03:** Update existing guides only — **no new top-level flow doc** unless planning discovers an unavoidable gap.
- **Primary targets:**
  - `guides/flows/admin-ui.md` — governed audience mutations in protected environments (preview → submit change request → review → execute); threshold breach vs indeterminate blocked states; host policy ownership.
  - `guides/flows/multi-env.md` — protected-environment threshold behavior, direct apply vs change-request routing, fail-closed on missing preview/dependency inputs.
- **Optional touch:** `guides/introduction/user-flows-and-jtbd.md` — one paragraph on blast-radius governance operator story if needed for cross-role mental model.
- Teach preview-basis limits (authored references + explicit samples only; no affected-user counts).

### D-04 — Quickstart API parity (VER-03)
- **D-04:** Make README and `guides/introduction/getting-started.md` **payload-first canonical**, consistent with `guides/flows/evaluation.md`.
- Primary quickstart example: build `%Rulestead.Context{}` explicitly and call `Rulestead.evaluate/3` (or `enabled?/get_value/2` with payload + context) — not conn-only as the first mental model.
- Add a short note that conn/plug-based helpers (`Rulestead.enabled?/2` on `%Plug.Conn{}`) are convenience wrappers when using the snapshot cache — valid but secondary to the explicit contract.
- `release_contract_test.exs` asserts key evaluation-guide phrases appear in README and getting-started (e.g., `Rulestead.evaluate/3`, explicit context, payload-first language).
- Linked-version sibling-package release model and mounted-admin posture remain unchanged in all touched docs.

### D-05 — CI scope, maintainer docs, and handoff (VER-03)
- **D-05:** Add `RULESTEAD_TEST_SCOPE=blast_radius_governance` to `scripts/ci/test.sh`:
  - New `run_blast_radius_governance/0` function calling `mix verify.phase60`
  - Failure guidance function mirroring `print_reusable_targeting_failure_guidance/0`
  - Update supported-scopes error message
- Add **“Blast Radius Governance Proof”** section to `MAINTAINING.md` describing bounded proof scope, rerun commands, and upstream handoff references.
- Produce `60-VERIFICATION.md` in phase dir; optional `60-HANDOFF-CHECKLIST.md` for maintainer release checklist.
- Reference upstream phase artifacts in MAINTAINING: `.planning/phases/57-blast-radius-threshold-contract/`, `58-change-request-integration/`, `59-mounted-governance-workflows/` (CONTEXT + VERIFICATION files).

### D-06 — Four-plan execution shape
- **D-06:** Mirror Phase 56 plan structure:
  - **60-01** — `mix verify.phase60` merge gate (VER-01)
  - **60-02** — `release_contract_test.exs` drift guards + README/MAINTAINING/package READMEs (VER-02)
  - **60-03** — in-place flow guide updates (VER-02)
  - **60-04** — CI scope, handoff checklist, verification artifact (VER-03)

### Claude's Discretion
- Exact forbidden-phrase additions beyond existing release_contract lists
- Whether user-flows-and-jtbd needs a governance paragraph
- Collapsible vs always-visible handoff checklist detail in MAINTAINING
- Exact release_contract assert string choices (as long as bounded support truth is enforced)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 60 goal, success criteria, VER-01–03
- `.planning/REQUIREMENTS.md` — VER-01, VER-02, VER-03; Proof Posture Gate; Support Truth Gate
- `.planning/milestones/v1.6.0-ROADMAP.md` — Phase 56 proof/docs pattern (template for 60)

### Prior phase context (frozen contracts — do not change)
- `.planning/phases/57-blast-radius-threshold-contract/57-CONTEXT.md` — threshold semantics, fail-closed, default profile
- `.planning/phases/58-change-request-integration/58-CONTEXT.md` — CR submit/execute envelope
- `.planning/phases/59-mounted-governance-workflows/59-CONTEXT.md` — mounted routing, copy, visibility tiers
- `.planning/phases/57-blast-radius-threshold-contract/57-VERIFICATION.md`
- `.planning/phases/58-change-request-integration/58-VERIFICATION.md`
- `.planning/phases/59-mounted-governance-workflows/59-VERIFICATION.md`

### Proof and release engineering anchors
- `rulestead/lib/mix/tasks/verify.phase56.ex` — merge gate union pattern (template)
- `rulestead/lib/mix/tasks/verify.phase55.ex` — admin test path pattern
- `rulestead/test/rulestead/release_contract_test.exs` — support-truth drift guards
- `scripts/ci/test.sh` — scoped CI proof bars
- `MAINTAINING.md` — maintainer proof sections
- `prompts/rulestead-release-engineering-and-ci.md` — per-phase verify tasks, scripts-first CI
- `prompts/rulestead-testing-and-e2e-strategy.md` — Fake merge gate, contract tests

### Docs and evaluation contract
- `guides/flows/evaluation.md` — payload-first canonical API (VER-03 source of truth)
- `guides/flows/admin-ui.md` — admin operator contract (extend for governance)
- `guides/flows/multi-env.md` — environment/protection semantics (extend)
- `guides/introduction/getting-started.md` — quickstart path (fix parity)
- `README.md`, `rulestead/README.md`, `rulestead_admin/README.md` — public support truth

### Product and security anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — preview → confirm → audit; governance suggestive not autopilot
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned Policy, fail-closed
- `prompts/rulestead-domain-language-field-guide.md` — audience, change request, environment vocabulary
- `prompts/rulestead-host-app-integration-seam.md` — mount path, host auth ownership

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.Phase56` — flat core union + admin subprocess pattern; copy structure for Phase60
- `release_contract_test.exs` — reusable-targeting and guarded-rollout support-truth blocks as templates
- `scripts/ci/test.sh` — `run_reusable_targeting_deepening/0`, failure guidance, scope switch
- Phase 57–59 test files already green — phase60 union selects them, does not rewrite contracts

### Established Patterns
- Per-phase verify task = explicit test path list, no kitchen-sink verifier
- Support truth enforced by release_contract string asserts + forbidden phrases
- Phase 56: 4 plans (gate → contract → guides → CI/handoff)
- Docs: in-place guide updates, no Phase 8-only public API docs early

### Integration Points
- `rulestead/mix.exs` — add `verify.phase60` preferred_env
- `scripts/ci/test.sh` — new scope case + runner
- Root/package READMEs + MAINTAINING — proof commands and bounded claims
- `guides/flows/admin-ui.md`, `multi-env.md`, `getting-started.md` — governance + quickstart parity

</code_context>

<specifics>
## Specific Ideas

- Mirror v1.6 Phase 56 closure shape exactly — this is the v1.7 capstone, not a feature phase.
- Quickstart fix is bundled here because ROADMAP explicitly calls “restore quickstart API parity” alongside governance proof.
- `verify.phase56` stays valid for v1.6 regression; `verify.phase60` is the superset v1.7 gate.

</specifics>

<deferred>
## Deferred Ideas

- Host-configurable threshold profiles UI (GOV-02-ext) — docs mention defer only, no UI in 60
- Propose CR with partial visibility — deferred in Phase 59 CONTEXT
- New standalone `guides/flows/governance.md` — prefer extending admin-ui + multi-env unless gap found during planning
- Auto-advance guarded rollouts (ROL-04) — v1.8.0 queue

</deferred>

---

*Phase: 60-proof-docs-and-support-truth*
*Context gathered: 2026-05-27*

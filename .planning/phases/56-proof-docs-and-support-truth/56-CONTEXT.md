# Phase 56: Proof, Docs, And Support Truth - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.6.0 reusable targeting deepening with repo-local proof, aligned public/package docs, release-contract drift guards, and support-truth wording — without adding new product capability or widening the linked sibling-package release model.

</domain>

<decisions>
## Implementation Decisions

### Phase proof gate (VER-01)
- **D-01:** Add `mix verify.phase56` as the single v1.6.0 merge gate. It runs Phase 54 core contract suites (via inclusion or delegation to the same test paths as `verify.phase54`), Phase 55 mounted workflow tests (same admin paths as `verify.phase55`), and Phase 53 gaps not yet in either gate — at minimum `impact_preview_test.exs` and `audience_mutation_audit_test.exs`, plus explain/audit carry-through coverage implied by VER-01.
- **D-02:** Keep `mix verify.phase54` and `mix verify.phase55` unchanged as phase-scoped gates; Phase 56 does not replace them.

### Support-truth drift guards (VER-02)
- **D-03:** Extend `release_contract_test.exs` with string assertions on root `README.md`, `MAINTAINING.md`, `rulestead/README.md`, and `rulestead_admin/README.md` for reusable-targeting scope: preview-basis limits, explicit tenant/environment semantics, host-owned identity/observability boundaries, and mounted-vs-core ownership — mirroring the existing `guarded_rollout_foundations` drift-guard pattern.
- **D-04:** Update in-place guides for operator/support truth — `guides/flows/rulesets.md`, `guides/flows/explainability.md`, `guides/flows/admin-ui.md`, and `guides/flows/multi-env.md` when compare/promotion scope is referenced — covering audience traces, preview → confirm → audit, dependency visibility, and preview-basis limits. Do not add new Phase 8-only guide artifacts.
- **D-05:** Preserve canonical external vocabulary: **Audience** in operator-facing copy; `segment` only as internal implementation vocabulary (per `PITFALLS.md` §15).

### CI proof scope and maintainer entrypoints
- **D-06:** Primary maintainer entrypoint is `cd rulestead && mix verify.phase56`. Optionally add `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening` to `scripts/ci/test.sh` (parallel to `guarded_rollout_foundations`) with README/MAINTAINING rerun citations; default CI `all` scope need not run phase56 until path-gated workflows warrant it.

### Linked sibling-package release model (VER-03)
- **D-07:** `rulestead` continues to own domain contracts, validation, snapshots, manifests, and audit evidence; `rulestead_admin` owns mounted presentation only. Release-contract tests must continue to assert no `RulesteadAdmin` references in core package files.
- **D-08:** No Phase 8-only docs (`guides/cheatsheet.cheatmd`, `guides/flows/extending-rulestead.md` expansion beyond current posture) and no standalone `rulestead_admin` publish prep in this phase.
- **D-09:** Document telemetry and audit events as admin/support signals only; host apps own metrics stores, baselines, dashboards, and identity resolution (per `PITFALLS.md` §17 and support-truth boundaries).

### Handoff and boundary contracts
- **D-10:** Phase 56 plans and docs must reference `55-HANDOFF-CHECKLIST.md` and `54-HANDOFF-CHECKLIST.md` as the mounted-vs-core boundary contracts; add `56-VERIFICATION.md` at phase close mirroring prior phase verification artifacts.

### Claude's Discretion
- Exact test file list inside `verify.phase56` beyond the minimum Phase 53 gaps named above.
- Precise forbidden-phrase and required-phrase sets in new `release_contract_test` assertions.
- Whether `reusable_targeting_deepening` CI scope ships in the first plan wave or follows after `mix verify.phase56` is green.
- `MixProject.cli/0` preferred-env wiring for `verify.phase56` (follow `verify.phase54` pattern).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 56 goal and success criteria
- `.planning/REQUIREMENTS.md` — VER-01, VER-02, VER-03
- `.planning/research/SUMMARY.md` — Phase 56 rationale and proof-closure pattern
- `.planning/research/PITFALLS.md` — Phase 56 pitfalls (terminology drift, package truth, telemetry claims)

### Upstream boundary contracts
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-HANDOFF-CHECKLIST.md`
- `.planning/phases/54-dependency-truth-and-promotion-safety/54-CONTEXT.md`
- `.planning/phases/55-mounted-operator-workflows/55-HANDOFF-CHECKLIST.md`
- `.planning/phases/55-mounted-operator-workflows/55-CONTEXT.md`
- `.planning/phases/55-mounted-operator-workflows/55-VERIFICATION.md`

### Proof and release patterns (prior milestones)
- `rulestead/lib/mix/tasks/verify.phase54.ex` — phase gate pattern
- `rulestead/lib/mix/tasks/verify.phase55.ex` — core + admin LiveView gate pattern
- `rulestead/test/rulestead/release_contract_test.exs` — support-truth drift guards
- `scripts/ci/test.sh` — `RULESTEAD_TEST_SCOPE` proof bars (`guarded_rollout_foundations`, `mounted_admin_contract`)
- `MAINTAINING.md` — maintainer proof commands and support boundaries

### Guides to align (in-place edits only)
- `guides/flows/rulesets.md` — reusable audiences
- `guides/flows/explainability.md` — explain traces and audience carry-through
- `guides/flows/admin-ui.md` — mounted operator workflows
- `guides/flows/multi-env.md` — tenant/environment scope for compare/promotion

### Engineering constraints
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, per-phase verify tasks
- `prompts/rulestead-telemetry-observability-and-audit.md` — no observability over-claims
- `AGENTS.md` — no Phase 8-only docs, no standalone admin publish prep

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.Phase54` / `Mix.Tasks.Verify.Phase55` — templates for `Mix.Tasks.Verify.Phase56`
- `Rulestead.ReleaseContractTest` — extend with v1.6 support-truth assertions (guarded-rollout block is the model)
- `scripts/ci/test.sh` — add optional `reusable_targeting_deepening` scope alongside existing proof bars
- Phase 53–55 contract tests already cover dependency inventory, impact preview, promotion/manifest blockers, and mounted LiveViews

### Established Patterns
- Per-phase `mix verify.phaseNN` never replaces prior phase gates; Phase 56 composes upward
- Support truth enforced by doc string matching in `release_contract_test.exs`, not manual spot-checks alone
- `rulestead/guides/README.md` points to monorepo root `guides/` — package docs stay thin pointers

### Integration Points
- `rulestead/mix.exs` `cli/0` preferred_envs for verify tasks
- Root `README.md` “Proof today” section — add v1.6 reusable-targeting entry when scope ships
- `55-HANDOFF-CHECKLIST.md` checkboxes — Phase 56 docs/plans reference as boundary source

</code_context>

<specifics>
## Specific Ideas

Assumptions confirmed without user corrections (assumptions mode, 2026-05-27).

</specifics>

<deferred>
## Deferred Ideas

- Hex version bump strategy for v1.6.0 closeout — release posture in `.planning/PROJECT.md`, not a Phase 56 implementation decision
- Full `mix test` in default CI for every doc-only PR — path-gated scopes remain acceptable per v1.5 pattern

</deferred>

---

*Phase: 56-proof-docs-and-support-truth*
*Context gathered: 2026-05-27*

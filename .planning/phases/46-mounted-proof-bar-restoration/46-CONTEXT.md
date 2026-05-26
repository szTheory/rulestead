# Phase 46: Mounted Proof Bar Restoration - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning
**Source:** recommendation-first discuss synthesis with subagent-backed gray-area research, prompt-anchor review, repo proof/CI inspection, and targeted mounted suite reruns

<domain>
## Phase Boundary

Restore the repo-root `mounted_admin_contract` proof surface so it matches the supported mounted companion contract again: a bounded, rerunnable proof bar that covers the mounted lifecycle route flow and permission semantics adopters are told to trust, exposes a named CI lane with explicit merge-blocking semantics, and fails with actionable setup-versus-regression guidance. This phase does **not** broaden `rulestead_admin` into a standalone product, does **not** turn the proof into a general demo bar, and does **not** reopen unrelated admin/UI scope.

</domain>

<decisions>
## Implementation Decisions

### Recommendation-first collaboration posture
- **D-01:** Phase 46 should be executed recommendation-first. Downstream agents should treat the research and prompt-anchor synthesis here as sufficient to lock ordinary tradeoffs without reopening them through user questionnaires.
- **D-02:** Prompt anchors are mandatory inputs for this phase, especially release/CI, testing, host-integration, admin/operator UX, and security seams. Planning should assume those docs have already narrowed the design space.

### Mounted proof bar breadth
- **D-03:** Restore `mounted_admin_contract` as a **curated mounted companion contract bar**, not the current seam-only bar and not a broad “all admin behavior” suite.
- **D-04:** The recommended repo-root `mounted_admin_contract` scope is:
  - `rulestead_admin/test/rulestead_admin/live/session_test.exs`
  - `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs`
  - `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`
  - `rulestead/test/rulestead/admin_contract_test.exs`
  - `rulestead/test/rulestead/admin_lifecycle_test.exs`
- **D-05:** Keep `flag_live/form_test.exs` out of the repo-root named mounted proof bar for now. The current public mounted contract is centered on mount/session/env/return-to/lifecycle review semantics, not the broader authoring form surface.
- **D-06:** The mounted proof bar should prove the **documented supported workflow** and permission split, specifically:
  - host-owned mount/session prerequisites
  - canonical `?env=` and mounted route behavior
  - lifecycle queue/review flow
  - `cleanup -> preview -> confirm -> audit/queue return` route-backed path
  - read-only vs execute/admin permission semantics
- **D-07:** Do not widen the named proof to unrelated mounted screens such as rules editing, rollout controls, kill switch screens, accessibility suites, or broader admin-wide UI surfaces. Those remain valuable package tests but are not the named Phase 46 contract bar.

### CI and merge-gate posture
- **D-08:** Add a dedicated named CI job for the mounted proof, analogous to the existing `openfeature companion proof` job, so maintainers and adopters can cite a stable lane by name.
- **D-09:** Gate that job at the **job level** from the existing `changes` detector rather than with workflow-level path filtering. This preserves correct GitHub required-check semantics and avoids pending-check drift.
- **D-10:** Thread the mounted proof job result into `release_gate` so the mounted proof becomes merge-blocking through the repo’s existing stable branch-protection contract instead of creating an entirely separate protection model.
- **D-11:** Path filtering for the mounted proof must include all shared seams that can break the contract, not just `rulestead_admin/**`. At minimum, planning should consider:
  - `rulestead_admin/**`
  - `rulestead/**` files that affect mounted contract/lifecycle proof
  - `scripts/ci/test.sh`
  - `.github/workflows/ci.yml`
  - maintainer/support-truth docs if CI is meant to track named proof claims there
- **D-12:** Keep manual host-app smoke paths advisory. The merge-blocking proof is the named bounded verifier lane; broader smoke runs should not be conflated with the contract bar.

### Failure remediation style
- **D-13:** Upgrade `mounted_admin_contract` failure output to **structured categorized remediation**, not terse command-only output and not automated setup/mutation behavior.
- **D-14:** The verifier should classify failures into a small, explicit taxonomy:
  - setup/prerequisite failure
  - mounted contract regression
  - unknown/unclassified failure that still falls through as regression-oriented output
- **D-15:** Failure output should print exact rerun/setup/docs commands and expected setup, while preserving the raw Mix/ExUnit failure output underneath. Wrapper context should add clarity, not hide the actual stacktrace.
- **D-16:** The verifier must stay check-only and reproducible. Do **not** auto-run `deps.get`, DB resets, or other prep steps inside the merge-blocking proof command itself.
- **D-17:** Remediation language must keep the support boundary explicit: mounted companion only, host-owned prerequisite contract, no implied standalone `rulestead_admin` usage.

### Local evidence that planning should treat as current truth
- **D-18:** Current repo-local evidence on 2026-05-25 shows the narrow Phase 45 seam bar passing while the broader lifecycle-route suites are red again. Planning should treat this as proof-semantic drift to repair, not as a reason to retreat to a seam-only contract.
- **D-19:** The failing suites currently cluster around mounted cleanup/preview/confirm access and redirect behavior, which means Phase 46 should prioritize route/permission contract alignment before polishing CI/document wording.
- **D-20:** Because these failures already exist in the route-backed lifecycle flow, docs, CI, and script wording must not overclaim the mounted contract surface until the curated bar is green again.

### the agent's Discretion
- Exact CI job name and `changes` output key, provided the mounted proof remains visible and stable by name.
- Exact shell formatting for remediation output, provided it remains categorized, grep-friendly, and preserves raw failing command output.
- Exact helper structure used inside `scripts/ci/test.sh` to keep the mounted proof scope maintainable.
- Exact doc phrasing used to distinguish the merge-blocking mounted proof bar from advisory smoke paths.

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“bounded mounted contract bar, not broad admin green.”**
- The winning Phase 46 story is:
  - repo-root `mounted_admin_contract` remains a named proof bar
  - the proof now covers the mounted lifecycle route flow and permission split that docs already describe
  - CI exposes that bar by name and feeds it into `release_gate`
  - failures tell adopters exactly whether setup is wrong or the contract regressed
- The strongest ecosystem lesson is that mounted companion proof should behave more like a **contract lane** than a general test suite:
  - Phoenix/LiveView mounted tools stabilize mount/auth/route semantics
  - Oban Web / LiveDashboard style seams emphasize mounted access policy and route-backed behavior
  - LaunchDarkly / Unleash style guidance favors a few high-value proof scenarios over an exploding matrix
- Current repo-local evidence from 2026-05-25:
  - `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` passes with the current narrow seam-only scope
  - the restored lifecycle-route candidate suites are currently red:
    - `cleanup_test.exs`
    - `cleanup_preview_test.exs`
    - `cleanup_confirm_test.exs`
  - those failures currently present as redirects back to `/admin/flags`, including permission/read-only mismatches and confirm-path drift

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone truth
- `.planning/ROADMAP.md` — Phase 46 goal, required slices, and bounded proof posture
- `.planning/REQUIREMENTS.md` — `ADM-01` and `VER-01`, plus the proof/support truth gates that define what this bar must mean
- `.planning/PROJECT.md` — active milestone rationale, sibling-package posture, and mounted-companion-only boundary
- `.planning/STATE.md` — current phase position and the note that Phase 46 is next after the Phase 45 prerequisite repair
- `.planning/METHODOLOGY.md` — recommendation-first and research-then-recommend defaults that should govern this phase

### Prior locked decisions that still apply
- `.planning/phases/43-mounted-contract-verification-closure/43-CONTEXT.md` — prior mounted lifecycle/admin contract posture, public mounted workflow semantics, and verification-closure discipline
- `.planning/phases/44-openfeature-bridge-proof-final-support-audit/44-CONTEXT.md` — named bounded proof-bar philosophy and CI lane naming posture for optional/companion surfaces
- `.planning/phases/45-companion-boot-package-boundary-truth/45-01-SUMMARY.md` — generated-host/package-boundary contract proof that underpins mounted truth
- `.planning/phases/45-companion-boot-package-boundary-truth/45-02-SUMMARY.md` — explicit runtime startup contract and optional-infra gate
- `.planning/phases/45-companion-boot-package-boundary-truth/45-03-SUMMARY.md` — fail-closed prerequisite handling and the current narrowed mounted proof wrapper

### Prompt anchors
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, named proof lanes, stable job-id contract, and release-gate philosophy
- `prompts/rulestead-testing-and-e2e-strategy.md` — bounded proof-surface philosophy, merge-blocking vs advisory verification, and test-lane curation
- `prompts/rulestead-host-app-integration-seam.md` — host-owned mount/session seam and explicit setup philosophy
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted workflow expectations and route-backed operator flow posture
- `prompts/rulestead-security-privacy-and-threat-model.md` — default-deny mutation posture and fail-closed behavior
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package discipline, CI lane structure, and mounted companion proof philosophy

### Current proof, CI, and doc surfaces
- `scripts/ci/test.sh` — current mounted proof wrapper and the place where proof scope/remediation output should be made explicit
- `.github/workflows/ci.yml` — current `changes`, `openfeature companion proof`, and `release_gate` wiring that Phase 46 should extend
- `README.md` — current root proof-language claims for `mounted_admin_contract`
- `MAINTAINING.md` — maintainer-facing mounted proof language and release-gate semantics
- `rulestead_admin/README.md` — package-local mounted companion contract wording

### Current code and test seams
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — prerequisite resolution, redirect behavior, env/tenant path helpers, and mounted policy state
- `rulestead_admin/test/rulestead_admin/live/session_test.exs` — fail-closed prerequisite proof
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` — mounted host seam and route/env contract proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` — lifecycle queue/filter/return-to mounted route behavior
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` — cleanup review/read-only semantics
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` — preview route and execute-capability semantics
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` — confirm/revalidation/typed-confirmation semantics
- `rulestead/test/rulestead/admin_contract_test.exs` — core admin contract surface
- `rulestead/test/rulestead/admin_lifecycle_test.exs` — lifecycle classification truth that the mounted flow depends on

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/ci/test.sh` already has named proof-scope routing and a proven pattern for bounded companion lanes via `openfeature_companion`; Phase 46 can extend this rather than invent a new verification entrypoint.
- `.github/workflows/ci.yml` already has a `changes` job with job-level outputs and a named companion proof job; the mounted proof can reuse the same structural pattern safely.
- `RulesteadAdmin.Live.Session` already centralizes mounted prerequisite resolution, mount-path normalization, env/tenant URL semantics, and redirect behavior; route/permission proof should stay anchored there rather than scattered across ad hoc helpers.

### Established Patterns
- This repo prefers named, scripts-first proof bars over hidden CI-only logic.
- Companion/package proof bars are supposed to stay bounded and explicitly documented by name.
- Mounted surfaces are host-owned and route-backed; auth/session/policy seams matter more than incidental UI details.
- Release/support truth is enforced by keeping docs, scripts, and CI descriptions aligned with one another.

### Integration Points
- `scripts/ci/test.sh` is the integration point for curating the mounted bar and adding categorized remediation output.
- `.github/workflows/ci.yml` is the integration point for a named mounted proof job and `release_gate` threading.
- `README.md`, `MAINTAINING.md`, and `rulestead_admin/README.md` will need Phase 47 follow-through once the mounted proof semantics are re-closed in code.
- The cleanup/preview/confirm tests are the immediate regression cluster that should drive Phase 46 execution order.

</code_context>

<deferred>
## Deferred Ideas

- Broadening the repo-root mounted proof to every admin route or every admin package test
- Re-expanding the named proof to include unrelated mounted authoring/UI surfaces such as `form_test`, `rules_test`, `kill_test`, or accessibility suites
- Any standalone `rulestead_admin` support posture
- Automatic setup/prep behavior inside the merge-blocking mounted verifier
- Broader admin UX redesign beyond the mounted proof/permission/support-truth closure

</deferred>

---

*Phase: 46-mounted-proof-bar-restoration*
*Context gathered: 2026-05-25*

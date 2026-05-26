# Phase 47: Support Truth Reclosure - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Source:** recommendation-first discuss synthesis with subagent-backed gray-area research, prompt-anchor review, live doc/CI inspection, and prior support-truth context

<domain>
## Phase Boundary

Re-close the root, package, and maintainer-facing support story for the repaired mounted companion surface so every doc surface names the same bounded product posture, prerequisite contract, proof command, and fallback semantics. This phase is about documentation and release-facing truth only. It does **not** widen `rulestead_admin` into a standalone product, does **not** add a new support guide taxonomy unless existing docs prove insufficient, and does **not** restate every CI implementation detail as public product contract.

</domain>

<decisions>
## Implementation Decisions

### Recommendation-first collaboration posture
- **D-01:** Phase 47 should be planned and executed recommendation-first. The research in this context already narrows the viable options enough that downstream agents should not reopen routine doc-IA or wording tradeoffs through more questionnaires.
- **D-02:** The repo-level default for discuss workflows should stay architect-oriented: research first, synthesize one coherent recommendation set, and escalate only the rare decisions that materially change scope, package boundary, public contract, or governance posture.

### Document ownership model
- **D-03:** Use a **root-canonical, package-contract, maintainer-runbook** split:
  - `README.md` owns the product story, runtime-first onboarding, sibling-package posture, and one bounded mounted-companion support/proof statement
  - `rulestead_admin/README.md` owns the exact host-mounted contract: install/mount seam, required host-owned inputs, missing-prerequisite behavior, and fallback semantics
  - `MAINTAINING.md` owns named CI/proof-lane semantics, merge-gate wording, rerun guidance, and drift-control/runbook details
- **D-04:** Do **not** mirror the same mounted support truth in full across all three docs. That duplication is the main drift footgun this phase should remove.
- **D-05:** Do **not** create a new “mounted companion contract” guide in Phase 47 unless planning discovers that the existing root/package/maintainer split cannot hold the needed truth cleanly. Current evidence suggests the existing surfaces are sufficient.

### Root README proof and support posture
- **D-06:** The root README should keep the mounted companion proof language at the **command plus contract-category** level, not the exact suite-membership level.
- **D-07:** Public root copy should name the canonical command:
  - `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`
  and explain that it proves the bounded mounted companion contract around session/mount/env/lifecycle/permission behavior.
- **D-08:** Root docs should **not** enumerate exact test files, CI job ids, or branch-protection semantics. Those are too brittle for the front door and already proved easy to drift.
- **D-09:** Root docs should **not** describe the mounted proof as “all admin behavior is green.” The support claim must stay explicitly narrower than the whole admin package.
- **D-10:** Root docs should keep the mounted companion highly discoverable, but still subordinate to the runtime-first quickstart and the sibling-package support boundary already locked in Phase 41.

### `rulestead_admin` package contract wording
- **D-11:** `rulestead_admin/README.md` should become the canonical place for the **exact mounted host contract**:
  - router macro usage
  - required `policy:` seam
  - required host session inputs
  - host-owned auth/identity/policy ownership
  - canonical `?env=` behavior
  - fallback behavior when URL scope is omitted
  - bounded fail-closed behavior when prerequisites are absent or unsupported
- **D-12:** Package-level fallback wording should be explicit that remembered env/session values are fallback-only conveniences, not alternate primary routing semantics. Explicit URL/env scope remains canonical.
- **D-13:** Package docs should describe missing prerequisites as **fail-closed mounted companion behavior**, not as mysterious redirects and not as package-owned auth behavior.
- **D-14:** Package docs should keep proof wording bounded: the named proof bar verifies the mounted companion contract it documents, not the entire future admin surface.
- **D-15:** `rulestead_admin/README.md` should not become a second root README or a second lifecycle guide. Keep it narrowly focused on the host integration seam.

### Maintainer gate and CI wording
- **D-16:** `MAINTAINING.md` should use a **command-first maintainer contract**:
  - the canonical local rerun command is `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh`
  - CI exposes the same proof as the named `mounted companion proof` job
  - merge blocking happens through `release_gate`
  - manual host-app smoke remains advisory
- **D-17:** Maintainer docs may name the current CI job and `release_gate`, but should avoid over-mirroring workflow internals such as full `needs` graphs or path-filter logic in prose unless required for a short appendix.
- **D-18:** Maintainer docs should remove stale phase-number framing for evergreen proof/runbook sections. The mounted proof bar is now part of the repo’s standing support posture, not a temporary “Phase 43” artifact.
- **D-19:** If exact suite membership is documented in maintainer docs, that list must be kept in the maintainer-only surface and aligned with `scripts/ci/test.sh`. It should not be copied into root public docs.
- **D-20:** Maintainer language should be explicit that the mounted proof is merge-blocking **via `release_gate` when mounted-proof-relevant paths change**, which is both operationally correct and less misleading than implying every named lane is independently required by branch protection.

### Cohesion and least-surprise defaults
- **D-21:** Across all doc surfaces, use one coherent story:
  - Rulestead is a two-package monorepo
  - `rulestead` is the primary runtime package
  - `rulestead_admin` is an optional mounted companion for Phoenix host apps
  - the mounted companion is supported through a bounded, named proof command
  - host apps own auth, policy, session truth, and mount wiring
- **D-22:** Prefer short public truth with strong link routing over exhaustive prose. Readers should find the right detail quickly, but they should not need maintainer docs to understand normal adopter-facing support boundaries.
- **D-23:** Wording should emphasize least surprise, explicit failure modes, and strong maintainer/adopter DX over exhaustive CI verbosity.

### the agent's Discretion
- Exact section titles and ordering inside `README.md`, `rulestead_admin/README.md`, and `MAINTAINING.md`, provided the ownership split above stays intact.
- Exact wording for the mounted proof category statement, provided it stays bounded to session/mount/env/lifecycle/permission semantics.
- Whether maintainer docs use a tiny “current workflow wiring” appendix, provided the main prose stays command-first and low-drift.

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“one front door, one mount contract, one maintainer runbook.”**
- The winning public posture is:
  - root README says what is supported and where to go next
  - package README says exactly how the mount seam works and fails
  - maintainer docs say how the proof lane and release gate enforce that truth
- The winning proof-language posture is:
  - public docs name the command and the contract categories it proves
  - maintainer docs own exact suite membership and gate semantics
  - CI/scripts remain the ultimate operational truth for reruns
- The winning fallback-language posture is:
  - explicit URL/env scope is canonical
  - remembered env/session values are fallback conveniences only
  - missing prerequisites fail closed with bounded mounted behavior

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Active milestone and phase truth
- `.planning/ROADMAP.md` — Phase 47 goal, slices, and support-truth boundary
- `.planning/REQUIREMENTS.md` — `DOC-01` plus proof/support truth gates that define success
- `.planning/PROJECT.md` — active milestone rationale, sibling-package posture, and support-truth constraints
- `.planning/STATE.md` — current milestone position and next-action framing for Phase 47
- `.planning/METHODOLOGY.md` — recommendation-first, research-then-recommend, and architect-default discuss lenses that should govern this phase

### Prior locked decisions that still apply
- `.planning/phases/41-release-truth-alignment/41-CONTEXT.md` — root-vs-package release-truth split, bounded public proof posture, and sibling-package guardrails
- `.planning/phases/45-companion-boot-package-boundary-truth/45-01-SUMMARY.md` — explicit generated-host mounted companion contract metadata
- `.planning/phases/45-companion-boot-package-boundary-truth/45-02-SUMMARY.md` — single startup contract and optional-infra gate
- `.planning/phases/45-companion-boot-package-boundary-truth/45-03-SUMMARY.md` — fail-closed mounted prerequisite handling and phase-scoped proof wrapper
- `.planning/phases/46-mounted-proof-bar-restoration/46-CONTEXT.md` — bounded mounted proof-bar philosophy, CI lane posture, and remediation semantics

### Current doc, script, and CI surfaces to align
- `README.md` — root proof/support statement and runtime-first front door
- `rulestead/README.md` — runtime package posture that should remain aligned but not widened
- `rulestead_admin/README.md` — mounted companion contract surface
- `MAINTAINING.md` — maintainer-facing proof/gate/runbook wording
- `.github/workflows/ci.yml` — named `mounted companion proof` job and `release_gate` wiring
- `scripts/ci/test.sh` — canonical mounted proof command behavior and failure guidance

### Current code and test seams that define truthful wording
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — mount prerequisite resolution, env fallback behavior, and fail-closed redirects
- `rulestead_admin/test/rulestead_admin/live/session_test.exs` — mounted prerequisite proof
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` — host seam and mounted route/env contract proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs` — mounted lifecycle queue/index path proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs` — cleanup review/read-only proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs` — preview route and execute-capability proof
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs` — confirm-path and typed-confirmation proof
- `rulestead/test/rulestead/admin_contract_test.exs` — core admin contract proof
- `rulestead/test/rulestead/admin_lifecycle_test.exs` — lifecycle classification truth behind mounted behavior

### Prompt anchors that should constrain wording and IA
- `prompts/rulestead-release-engineering-and-ci.md` — scripts-first CI, stable proof-lane naming, and release-gate philosophy
- `prompts/rulestead-host-app-integration-seam.md` — host-owned mount/session/policy seam and explicit setup philosophy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package docs discipline, scripts-first verification, and README/package/runbook layering
- `prompts/rulestead-testing-and-e2e-strategy.md` — bounded proof-surface philosophy and canonical named verifier posture
- `prompts/rulestead-admin-ux-and-operator-ia.md` — mounted operator workflow and least-surprise admin expectations
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — runtime-first onboarding, first-success path, and support-reader expectations
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed posture and host-owned security seam

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `README.md` already has the right front-door structure: runtime-first quickstart, optional mounted companion path, and a bounded proof section. Phase 47 should refine and de-drift it, not redesign it.
- `rulestead_admin/README.md` already contains the right surface area for the mount contract: install, router macro, `policy:`, session keys, URL semantics, and bounded proof language.
- `scripts/ci/test.sh` already centralizes the canonical proof command and categorized remediation output; docs should point to it rather than duplicate its operational detail broadly.
- `.github/workflows/ci.yml` already exposes the named `mounted companion proof` lane and threads it into `release_gate`; docs should describe that posture accurately rather than invent a new one.

### Established Patterns
- The repo prefers shared root guidance plus narrow package READMEs and a separate maintainer runbook.
- Public proof posture is intentionally bounded by named commands, not broad “the whole surface is green” claims.
- Mounted surfaces are host-owned and fail-closed when the host contract is missing.
- Scripts-first verification is a standing repo pattern; docs should name the command users run, not depend on CI-only knowledge.

### Integration Points
- Root README is the integration point for the overall mounted support statement and proof-command discoverability.
- `rulestead_admin/README.md` is the integration point for exact mount/prerequisite/fallback truth.
- `MAINTAINING.md` is the integration point for gate semantics, rerun/runbook guidance, and drift-control wording.
- `scripts/ci/test.sh` and `.github/workflows/ci.yml` are the operational truth sources that Phase 47 wording must match.

</code_context>

<deferred>
## Deferred Ideas

- A standalone mounted companion contract guide, if later phases discover the existing three-surface split cannot carry enough truth without bloat
- Generated doc-contract extraction for exact mounted-proof suite membership, if maintaining that list manually in maintainer docs proves too brittle
- Any widening of `rulestead_admin` into a standalone product or broader control-plane support story

</deferred>

---

*Phase: 47-support-truth-reclosure*
*Context gathered: 2026-05-26*

# Phase 41: Release Truth Alignment - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning
**Source:** discuss-all synthesis using subagent-backed gray-area research, prompt-anchor review, current repo/docs/package inspection, and project methodology lenses

<domain>
## Phase Boundary

Align the public-facing release story so root and sibling docs tell the same post-`v1.0.0` truth the repo can actually support today, without widening product scope, changing the linked-version sibling-package model, or implying stronger proof than current repo evidence warrants.

**In scope:**
- root and sibling README release posture
- install/onboarding doc posture
- demo, verification, and support-truth framing
- bounded treatment of companion proof surfaces already present in-repo

**Out of scope:**
- changing package versions or retagging the release line
- making `rulestead_admin` a standalone product
- claiming broader OpenFeature or admin proof than current phase/posterior phases support
- new product capabilities, new verification infrastructure, or broad doc-taxonomy redesign

</domain>

<decisions>
## Implementation Decisions

### Recommendation posture for this phase
- **D-01:** Phase 41 should be planned and implemented recommendation-first. Downstream agents should not reopen routine copy/IA tradeoffs unless a choice would materially change public contract, release model, package boundary, security/governance posture, or milestone scope.
- **D-02:** The repo’s existing `.planning/METHODOLOGY.md` already matches the user’s preferred collaboration style: synthesize more, ask less, and escalate only truly high-impact choices. Phase 41 should apply that lens directly rather than turning doc-shape choices back into questionnaires.

### Release headline and version story
- **D-03:** Use a **split-front-door release narrative**:
  - the root README should state once, clearly and early, that repo GA shipped in `v1.0.0` on 2026-05-21
  - the same root surface should state that the current installable linked package line is `0.1.x`
  - sibling package READMEs should stay package-first and carry only a short factual note pointing back to the root/upgrading release-posture explanation
- **D-04:** Do **not** repeat the full repo-vs-package explanation heavily in every package README. That would make the package fronts read like release notes instead of idiomatic package entrypoints.
- **D-05:** Do **not** hide the version split or defer it to a late upgrade section. Given the current repo tags and package versions, that would violate least surprise and recreate support-truth drift.
- **D-06:** Phase 41 must not widen into a version-line realignment project. The docs should reconcile the current truth; they should not block on a future `1.x` package strategy.

### Install path and onboarding shape
- **D-07:** The default quickstart should be **runtime-first**, with the mounted admin path presented immediately after as the optional Phoenix-host companion path.
- **D-08:** Keep the JTBD/path split in installation and onboarding docs:
  - runtime evaluation first-success path
  - runtime + mounted-admin path for Phoenix apps that need the operator UI
- **D-09:** The root quickstart should not lead with the full two-package install as the default. Doing so would overstate `rulestead_admin` as mandatory, front-load router/auth/browser concerns, and increase least-surprise/security footguns.
- **D-10:** Mounted admin must remain highly discoverable through immediate follow-on CTAs and cross-links, but still clearly optional and Phoenix-host-specific.

### Proof posture and support truth
- **D-11:** Use a **layered proof posture**:
  - recommendation-first landing copy up top
  - a bounded, explicit “Proof today” or equivalent section close to the release/install story
  - a small supporting appendix or referenced support-truth surface for exact proof seams
- **D-12:** The bounded proof statement should explicitly anchor current support truth to:
  - the local Compose-backed demo under `examples/demo/` as the primary runnable end-to-end proof
  - `mix verify.release_publish <version>` as published-consumer install + HexDocs reachability proof
  - `mix verify.release_parity <version>` as git-tag-to-Hex-tarball parity proof
- **D-13:** Anything outside those verified seams should be described as current guidance or companion surface posture, not implied as broader proven support.
- **D-14:** Do **not** use soft confidence language that buries caveats, and do **not** turn the README into a cold enterprise verification matrix. The winning posture is bounded honesty without making the product sound broken.

### Companion surfaces and discoverability
- **D-15:** Treat `open_feature_rulestead` and the local demo as **clearly secondary companion/proof surfaces** in Phase 41 front-door docs.
- **D-16:** The root README should mention these surfaces briefly and intentionally:
  - `examples/demo/` as the runnable proof path
  - `open_feature_rulestead/` as an optional companion bridge surface
  - details should live in their own READMEs/docs, not in the primary quickstart spine
- **D-17:** Do **not** promote `open_feature_rulestead` or the demo as equal first-class front-door entry paths yet. That would outrun the dedicated proof-closure work reserved for Phases 42-44.
- **D-18:** Do **not** omit these surfaces entirely. They already exist in-repo and should remain discoverable, but with bounded language that prevents expectation inflation.

### Sibling-package and mounted-companion guardrails
- **D-19:** All Phase 41 docs must reinforce the linked-version sibling-package model:
  - `rulestead` is the primary runtime package
  - `rulestead_admin` is the mounted companion package for Phoenix-hosted operator workflows
  - `open_feature_rulestead` is an optional companion bridge surface
- **D-20:** `rulestead_admin` copy must keep the mounted-companion contract explicit and avoid any standalone-control-plane tone.

### the agent's Discretion
- Exact section titles and wording for the release-posture note, provided the split-front-door story remains explicit
- Exact placement of the “Proof today” box or equivalent bounded-proof callout, provided it stays close enough to affect reader expectations early
- Exact CTA/link structure between root README, sibling READMEs, install docs, demo docs, and upgrading docs, provided runtime-first onboarding and companion discoverability remain intact

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“one primary product story, several bounded companion surfaces.”**
- The root README should behave like:
  - 60-second value pitch
  - one truthful release-posture note
  - runtime-first quickstart
  - optional mounted-admin next step
  - bounded proof section
  - secondary companion/proof links
- Package READMEs should behave like:
  - narrow package contract
  - current install snippet
  - one-line release-posture note
  - links back to the root/shared docs for the broader story
- The tone should stay calm and factual:
  - not defensive
  - not hypey
  - not ambiguous about what is and is not proven today
- If a future docs IA expansion is needed for more integrations/examples, that belongs after the current proof-closure phases rather than inside Phase 41.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active milestone truth
- `.planning/ROADMAP.md` — Phase 41 goal, success criteria, and milestone ordering
- `.planning/PROJECT.md` — current post-`v1.0.0` project posture, sibling-package model, and support-truth rationale
- `.planning/REQUIREMENTS.md` — `DOC-01` and `DOC-02` requirements for release-doc and install-truth alignment
- `.planning/STATE.md` — current milestone position and active support-truth closure posture
- `.planning/METHODOLOGY.md` — recommendation-first and research-then-recommend lenses that should govern planning

### Prior locked decisions that still apply
- `.planning/phases/26-api-lockdown-and-documentation-perfection/26-CONTEXT.md` — prior public-doc and release-surface discipline
- `.planning/phases/28-e2e-demo-environments-ga-release/28-CONTEXT.md` — demo boundary and proof intent
- `.planning/phases/37-mounted-admin-lifecycle-workbench/37-CONTEXT.md` — mounted companion posture and route-backed operator contract
- `.planning/phases/38-lifecycle-docs-runbooks-verification/38-CONTEXT.md` — sibling-package docs strategy, lifecycle discoverability, and release-surface verification philosophy
- `.planning/phases/40-lifecycle-workbench-verification-state-reconciliation/40-CONTEXT.md` — recent closure discipline and state-reconciliation posture

### Current public surfaces to align
- `README.md` — root front door and current stale pre-GA language
- `rulestead/README.md` — runtime package entrypoint
- `rulestead_admin/README.md` — mounted companion package entrypoint
- `open_feature_rulestead/README.md` — optional bridge surface currently under-described
- `guides/introduction/installation.md` — install path split that should inform README alignment
- `guides/introduction/getting-started.md` — first-success onboarding path
- `guides/introduction/upgrading.md` — release/version posture cross-link target
- `examples/demo/README.md` — runnable local demo proof path

### Current package/version truth
- `rulestead/mix.exs` — current `rulestead` package version and HexDocs/package metadata
- `rulestead_admin/mix.exs` — current `rulestead_admin` package version and linked-version dependency posture
- `open_feature_rulestead/mix.exs` — current bridge package version and metadata

### Prompt anchors
- `prompts/rulestead-release-engineering-and-ci.md` — release verification and post-publish truth posture
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — 15-minute onboarding, persona-first docs, and quickstart goals
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — README vs getting-started split, sibling-package norms, and release-surface discipline
- `prompts/rulestead-host-app-integration-seam.md` — runtime-first install seam and mounted-admin optionality
- `prompts/rulestead-domain-language-field-guide.md` — canonical terms for flag, runtime, rollout, and mounted admin
- `prompts/rulestead-testing-and-e2e-strategy.md` — demo/proof and verification expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The root README already contains the broad product front-door structure, quickstart, demo section, and versioning section; Phase 41 can tighten and reorder rather than inventing a new front door.
- `guides/introduction/installation.md` already has the correct split-path install IA: runtime-only vs runtime-plus-admin.
- `examples/demo/README.md` already provides a concrete proof path that public copy can reference honestly.
- `mix verify.release_publish` and `mix verify.release_parity` already exist as named release-truth verification seams in `rulestead`.

### Established Patterns
- The repo prefers shared root guides plus narrow sibling-package READMEs.
- Companion package posture is already bounded: `rulestead_admin` is mounted, host-owned, and non-standalone.
- Project methodology explicitly favors recommendation-heavy synthesis over repeated user questioning for ordinary decisions.
- Release credibility is treated as a public surface, not internal maintainer trivia.

### Integration Points
- Root README should carry the main release-truth and proof-truth narrative once.
- Sibling READMEs should point back to root/shared docs for broad release context while keeping their package-specific contract intact.
- Install and getting-started guides should be aligned so quickstart order, dependency snippets, and mounted-admin optionality all say the same thing.
- Demo and bridge docs should be reachable from the root, but clearly labeled as companion/proof surfaces.

</code_context>

<deferred>
## Deferred Ideas

- A broader integrations/examples index if companion surfaces multiply after Phase 44
- Any package-version realignment or `1.x` package-line strategy
- Any stronger OpenFeature bridge claims before Phase 44 closes its proof path

</deferred>

---

*Phase: 41-release-truth-alignment*
*Context gathered: 2026-05-24*

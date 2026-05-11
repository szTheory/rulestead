# Phase 8: Docs, API Stability, Cheatsheet, Post-Publish Verify, v0.1.0 Release - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning
**Research mode:** deep synthesis across five focused advisor passes plus ecosystem source review

<domain>
## Phase Boundary

Ship the first real `v0.1.0` release as a trustworthy Hex + HexDocs release for the linked sibling packages `rulestead` and `rulestead_admin`. Phase 8 finishes the public docs surface, locks the intentionally public API boundary, defines release verification and drift checks, and establishes the maintainer-facing publish choreography.

**In scope:**
- Finish and organize the docs front door, guides, cheatsheet, conventions, API stability doc, and extending guide
- Define what is and is not public API for both sibling packages
- Add the post-publish verification trio and daily drift automation
- Finalize the maintainer publish flow for the first real release
- Verify both published packages are usable in the ways the docs promise

**Out of scope (explicitly deferred):**
- Broad stabilization of internal `rulestead_admin` LiveView modules/components as public API
- Formalizing extension seams that are still roadmap ideas rather than shipped code
- Browser-heavy post-publish E2E as a blocking release gate
- Fully hands-off auto-publish with no human approval checkpoint
- Future governance/operator capabilities beyond what Phase 8 must document and release

</domain>

<decisions>
## Implementation Decisions

### API stability boundary
- **D-01:** `api_stability.md` locks the full intended public `rulestead` core surface plus a narrow, explicitly documented `rulestead_admin` host-integration contract.
- **D-02:** The admin contract is limited to the mount seam, `policy:` requirement, intentionally documented operator-facing URL/query conventions, and any other explicitly listed host-facing guarantees.
- **D-03:** `RulesteadAdmin.Live.*`, `RulesteadAdmin.Components.*`, socket assigns, DOM/CSS structure, and internal helper modules remain non-public even if visible in source.
- **D-04:** Phase 8 must state the boundary plainly: stable at the package boundary, flexible behind it.

### Extending guide posture
- **D-05:** The normative `guides/flows/extending-rulestead.md` body documents only shipped, supported extension seams in v0.1.0.
- **D-06:** Near-term roadmap seams that are not yet real code contracts (`Rulestead.RuleEngine`, `Rulestead.EvaluationCache`, `Rulestead.AuditStore`, `Rulestead.ActorResolver`) may appear only in a clearly labeled planned/experimental appendix.
- **D-07:** Planned seams must be labeled as excluded from `api_stability.md` until they ship as tested, documented, supported contracts.

### Release verification depth
- **D-08:** Phase 8 release verification must prove both sibling packages from published Hex artifacts, not only the core package.
- **D-09:** The blocking post-publish bar is: fresh `mix new` consumer proof for `rulestead` plus fresh `mix phx.new` published-smoke proof that `rulestead_admin` mounts and boots inside a host Phoenix app.
- **D-10:** Full browser-heavy or asset-heavy post-publish E2E is not the blocking v0.1.0 gate; keep that as non-blocking CI/drift coverage if added.

### Documentation front door
- **D-11:** The docs front door is Alex-first, but not Alex-only.
- **D-12:** The root README should lead with the 15-minute app-dev quickstart, then immediately route readers into three explicit paths: build with Rulestead, operate via Admin UI, extend Rulestead.
- **D-13:** `rulestead/README.md` stays runtime-first and minimal; `rulestead_admin/README.md` stays mount/auth/session-contract focused rather than duplicating the full root story.
- **D-14:** Operator/admin material belongs primarily in `guides/flows/admin-ui.md`, `guides/flows/explainability.md`, `guides/flows/rollout.md`, and `guides/flows/multi-env.md`.
- **D-15:** Contributor/extender confidence belongs primarily in `guides/flows/extending-rulestead.md`, `api_stability.md`, and `CONVENTIONS.md`, not above the first-success path.

### Release choreography
- **D-16:** The first real release should use semi-automated gated publish, not package-by-package hand-driving forever and not fully hands-off publish on merge.
- **D-17:** Merge the release-please PR, prepare the publish run automatically from the tagged commit, and require one explicit maintainer approval before exposing Hex publish credentials.
- **D-18:** Publish in ordered lockstep: `rulestead` first, then `rulestead_admin`, with dry-run and verification around the publish flow.
- **D-19:** Keep `publish-hex.yml` or an equivalent manual recovery path as a documented fallback if the gated path fails partway through.

### the agent's Discretion
- Exact shape and ordering of the docs navigation, provided the Alex-first front door and role-based path split remain clear
- Exact wording of the public/private API boundary, provided the admin internal modules remain clearly excluded
- Exact mechanics of the gated publish workflow, provided one explicit human approval remains before irreversible Hex publish
- Exact implementation split across Mix tasks, scripts, and workflows for the verification trio, provided both sibling packages are proven from published artifacts

</decisions>

<specifics>
## Specific Ideas

- Treat `rulestead_admin` like Phoenix LiveDashboard-style mountable UI: the public promise is the router seam and host integration contract, not internal LiveView module names.
- Keep v0.1.0 documentation calm and task-oriented. The root README should not become a sitemap or architecture essay.
- Make the release story easy to trust: one deliberate approval checkpoint, then ordered verified publish, then post-publish proof against the actual Hex packages.
- Keep extension docs honest. Avoid “future behavior tourism” where roadmap seam names accidentally become support promises.
- If a route or convention matters enough that breaking it would surprise operators or host apps, list it explicitly in `api_stability.md`; otherwise leave it internal.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope and Requirements
- `.planning/ROADMAP.md` — Phase 8 goal, scope, success criteria, and exact deliverables for docs, API stability, and release verification
- `.planning/PROJECT.md` — product positioning, sibling-package philosophy, calm operator posture, and public API stability expectations
- `.planning/REQUIREMENTS.md` — source of truth for `REL-03`, `REL-04`, `REL-06`, `DOC-04`, `DOC-05`, and `DOC-06`
- `.planning/STATE.md` — current project sequencing and the fact that release work follows prior runtime/admin phases

### Prior Locked Decisions
- `.planning/phases/01-repo-bootstrap/01-CONTEXT.md` — sibling-package, linked-version, CI, and release-please foundation decisions
- `.planning/phases/05-host-app-seams-plug-liveview-oban-installer-test-helpers/05-PATTERNS.md` — host-app seam patterns and install surface conventions that docs/release verification must reflect
- `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-CONTEXT.md` — admin environment/query-param model and operator surface boundaries
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — Phase 7 operator/admin route and security posture that Phase 8 docs must describe accurately without over-locking internals

### Existing Docs and Release Surface
- `README.md` — current root front door and quickstart posture
- `rulestead/README.md` — current package-local runtime README
- `rulestead_admin/README.md` — current package-local admin README and mount/session contract notes
- `guides/introduction/installation.md` — installation story
- `guides/introduction/getting-started.md` — first-success onboarding path
- `guides/introduction/upgrading.md` — upgrade posture for public API changes
- `guides/flows/evaluation.md` — core runtime usage path
- `guides/flows/rulesets.md` — authored ruleset concepts
- `guides/flows/rollout.md` — rollout/operator guidance
- `guides/flows/admin-ui.md` — admin package/operator guidance
- `guides/flows/explainability.md` — support/operator explain path
- `guides/flows/multi-env.md` — environment model
- `guides/flows/telemetry.md` — telemetry contract docs already treated as public
- `guides/recipes/testing.md` — test helper path that must match published package behavior
- `guides/recipes/telemetry.md` — application-level telemetry recipe
- `guides/recipes/ecto-conventions.md` — Ecto integration conventions
- `guides/recipes/oban-background-jobs.md` — Oban integration seam
- `guides/recipes/deployment.md` — deployment and release-adjacent guidance
- `guides/recipes/context-propagation.md` — explicit context propagation rules

### Existing Code and Contracts
- `rulestead/lib/rulestead.ex` — root public API candidate surface
- `rulestead/lib/rulestead/context.ex` — public context struct fields
- `rulestead/lib/rulestead/result.ex` — public result struct fields
- `rulestead/lib/rulestead/error.ex` — root error contract and typed error envelope
- `rulestead/lib/rulestead/store.ex` — concrete public behavior seam
- `rulestead/lib/rulestead/admin/policy.ex` — concrete admin policy behavior seam
- `rulestead_admin/lib/rulestead_admin/router.ex` — admin mount seam that should be treated as public
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — current internal session/env resolution implementation, useful for docs but not a public contract by default
- `rulestead/mix.exs` — ExDoc extras, package files, and Hex package metadata for the core package
- `rulestead_admin/mix.exs` — package files, docs setup, and publish-time dependency behavior for the admin package
- `rulestead/lib/mix/tasks/rulestead.install.ex` — install entrypoint that release verification/docs should reflect accurately

### Release Workflows and Scripts
- `.github/workflows/ci.yml` — current CI baseline
- `.github/workflows/release-please.yml` — release PR and tag generation flow
- `.github/workflows/publish-hex.yml` — existing publish fallback flow and current publish contract
- `scripts/ci/check_package_whitelist.sh` — publish artifact guardrail
- `scripts/ci/admin_publish_guard.sh` — explicit admin publish gate
- `scripts/ci/release_gate.sh` — CI gate shape
- `prompts/rulestead-release-engineering-and-ci.md` — release engineering reference and intended Phase 8 verification/drift posture

### Product and Persona Direction
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — persona-specific onboarding and docs priorities
- `prompts/rulestead-admin-ux-and-operator-ia.md` — admin/operator IA direction to preserve in docs wording and route promises
- `prompts/rulestead-brand-book.md` — voice and posture for docs copy
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — prior-lib patterns for release discipline, package boundaries, and public contract posture

### Ecosystem References
- `https://hexdocs.pm/elixir/1.18.0/library-guidelines.html` — official Elixir library guidance, especially dependency and CI discipline
- `https://hexdocs.pm/ex_doc/ExDoc.html` — ExDoc docs for extras and API reference behavior
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html` — Phoenix mountable UI seam pattern
- `https://hex.pm/docs/publish` — Hex publishing guidance and semantics
- `https://semver.org/` — public API and versioning baseline
- `https://docs.getunleash.io/concepts/feature-flags` — lifecycle/admin lessons from a successful flag platform
- `https://launchdarkly.com/docs/home/flags/list` — operator-facing list/filter/admin lessons from a successful flag platform

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The core package already exposes a meaningful public surface in `Rulestead`, `%Rulestead.Context{}`, `%Rulestead.Result{}`, `%Rulestead.Error{}`, `Rulestead.Store`, and `Rulestead.Admin.Policy`.
- `RulesteadAdmin.Router` already defines the real package boundary for host apps, which makes it the natural admin API-stability candidate.
- The existing workflow files and CI scripts already provide a usable release spine; Phase 8 should evolve them rather than replace them wholesale.
- `mix.exs` for both packages already wires ExDoc extras and package files closely enough that Phase 8 can lock them into explicit docs/release tests.

### Established Patterns
- The repo prefers explicit seams and explicit contracts over hidden magic.
- The codebase already uses `@moduledoc false` to mark internals; Phase 8 should respect that signal when deciding what becomes public API.
- The sibling-package design is intentional, not incidental. Docs, verification, and publish flow should reinforce that split instead of blurring it.
- The admin UI is a mountable package, not a standalone control-plane product. Documentation and verification should mirror Phoenix-style mounted-package ergonomics.

### Integration Points
- `api_stability.md` should derive directly from current public modules, docs, telemetry guides, and config schema rather than from speculative roadmap-only seams.
- Release verification should exercise both `mix new` and `mix phx.new` consumer paths from published artifacts.
- The gated publish flow should compose with the existing release-please + publish fallback setup instead of introducing an unrelated release system.
- Docs IA should preserve one clear front door at the root while using package READMEs to clarify package-local responsibilities.

</code_context>

<deferred>
## Deferred Ideas

- Make all current `rulestead_admin` LiveView routes/modules/components stable public API
- Ship new public behavior modules solely because they appear in roadmap prose
- Require browser-driven post-publish E2E as the blocking first-release gate
- Move directly to fully automatic publish-on-merge with no human approval checkpoint
- Turn the root README into a contributor-architecture front door ahead of first-user success

</deferred>

---

*Phase: 08-docs-api-stability-cheatsheet-post-publish-verify-v0-1-0-release*
*Context gathered: 2026-04-24*

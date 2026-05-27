---
gsd_state_version: 1.0
milestone: v1.5.0
milestone_name: v1.5.0 - Guarded Rollout Foundations
status: executing
last_updated: "2026-05-27T06:27:42.831Z"
last_activity: 2026-05-27 -- Phase 51 execution started
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 6
  completed_plans: 4
  percent: 50
---

# State: Rulestead

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-26)

**Core value:** Phoenix teams can safely gate, roll out, and explain runtime decisions — booleans, variants, and remote config — with 15-minute quickstart, deterministic evaluation, and a calm admin UI that operators, support, and SRE can all trust at 3am.
**Current focus:** Phase 51 — mounted-guardrail-workflow
**Milestone:** `v1.5.0 - Guarded Rollout Foundations`

## Roadmap Reference

See: `.planning/ROADMAP.md` for the active milestone phases and traceability map.

## Current Position

Phase: 51 (mounted-guardrail-workflow) — EXECUTING
Plan: 1 of 2
Status: Executing Phase 51
Last activity: 2026-05-27 -- Phase 51 execution started

## Current Milestone Focus

- `ROL-01` — completed by Phase 49 through the host-supplied rollout signal seam, authored guardrail schema, and compare/export durability proof
- `ROL-02` / `ROL-03` — completed by Phase 50 through explicit guarded decision states, sticky hold behavior, and exact stable-snapshot rollback
- `AUD-01` / `AUD-02` — completed by Phase 50 through durable guardrail decisions, governed mutation execution, and bounded audit evidence
- `ADM-01` / `VER-01` — remain active for Phase 51 and Phase 52 mounted workflow, docs, and proof closure

## Carryover Items

- `v1.6.0 - Reusable Targeting Deepening` remains queued behind guarded rollout.
- Keep the sibling-package release model, mounted-admin posture, host-owned identity boundary, and host-owned observability boundary unchanged.
- Do not widen guarded rollout into auto-advance, dashboards, or standalone-admin posture during Phase 49 planning.

## Anchor Docs (prompts/)

These remain the primary source of truth and should be loaded selectively per phase:

- `prompts/elixir_feature_flags_research_brief.md` — product vision and phased market thesis
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — validated patterns from prior shipped libs
- `prompts/rulestead-brand-book.md` — naming, voice, visual identity
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary
- `prompts/rulestead-release-engineering-and-ci.md` — release engineering reference
- `prompts/rulestead-testing-and-e2e-strategy.md` — testing and verification reference
- `prompts/rulestead-admin-ux-and-operator-ia.md` — admin/operator UX reference
- `prompts/rulestead-telemetry-observability-and-audit.md` — telemetry and audit reference
- `prompts/rulestead-security-privacy-and-threat-model.md` — security/privacy reference
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — persona and onboarding reference
- `prompts/rulestead-host-app-integration-seam.md` — host-app integration seam reference

## Decisions

- **14-01**: Scaffolded `open_feature_rulestead` as a sibling package to core `rulestead` to avoid vendor lock-in.
- **14-01**: Implemented `ContextMapper` to map loosely typed OpenFeature attributes into strongly typed Rulestead Contexts.
- **14-02**: Adopted OpenFeature.Provider behaviour to map contexts and resolutions.
- **14-02**: Mitigated Information Disclosure by selectively surfacing scalar metadata (matched_rule, flag_version, cache_age_ms) instead of full Rulestead engine telemetry.
- **15-02**: Used Elixir's native AST parser instead of regex for precise code reference detection.
- **15-02**: Created an Ecto schema and migration for persisting ingested code references securely via token auth.
- **15-03**: Validated exact flag key typing for production environment archival.
- **19-02**: Published exact versioned snapshots into Redis from the control plane while keeping the write path off the hot request path.
- **20-01**: Added a notifier seam so runtime invalidation transport stays configurable rather than Phoenix-only.
- **20-02**: Version-gated invalidation handling to ignore stale or duplicate refresh notices and preserve last-known-good snapshots on refresh failure.
- **21-01**: Kept infrastructure health node-local by default and exposed peer data only through an explicit host-provided seam.
- **21-01**: Added `[:rulestead, :sync, :delta_received]` and `[:rulestead, :cache, :invalidation]` as additive aliases on top of the Phase 20 runtime invalidation telemetry family.
- **21-02**: Mounted diagnostics inside the existing `rulestead_admin` router macro so the screen inherits the current session and policy envelope.
- **21-02**: Kept the diagnostics page explicitly current-node by default and rendered missing-snapshot states as critical operator copy instead of implying peer health.
- **23-02**: Reused the existing governed-action approval and policy surfaces for protected-environment promotion instead of introducing a parallel promotion workflow.
- **23-03**: Executed approved and scheduled governed promotion from the stored reviewed bundle snapshot instead of recomputing source intent later.
- **23-04**: Modeled re-apply-version as a fresh forward promotion from immutable environment-version history rather than a rollback shortcut.
- **23-05**: Kept compare, change-request, and schedule routes as the mounted operator entrypoints for promotion and re-apply.
- **24-04**: Reused the existing governed promotion change-request path for protected-target CLI promote apply rather than adding a direct CLI bypass.
- **35-00**: Activated lifecycle hygiene and ownership as `v1.2.0` ahead of guarded rollout and reusable targeting to close the strongest everyday trust/cleanup gap first.
- **41-00**: Redirected the next milestone toward adopter-truth and proof-posture closure before guarded rollout because current repo evidence shows conflicting release docs and failing proof surfaces.
- **41-01**: Activated `v1.3.0` as a bounded support-truth milestone instead of reopening feature prioritization because docs, migrations, and runnable proof are the highest-leverage current adopter gap.
- **41-02**: Centralized the repo-GA versus package-line explanation at the root README while keeping sibling package READMEs narrow and linked back to shared docs.
- **41-03**: Bounded public support truth to the local demo plus `mix verify.release_publish` and `mix verify.release_parity`, and locked that posture into release-contract tests.
- **44-01**: Kept the OpenFeature companion contract package-first and pushed the browser path to a clearly secondary host-owned demo surface.
- **44-02**: Exposed `openfeature_companion` as a named, path-gated proof bar instead of widening the default release gate.
- **44-03**: Closed milestone support truth only after root docs, demo docs, CI, and verification evidence all cited the same bounded proof commands.
- **45-00**: Re-ranked the next milestone to mounted companion proof reclosure after repo-local verification showed the named mounted-admin proof bar still failing while the OpenFeature companion proof bar passed.
- **45-01**: Reclassified reusable targeting from a net-new milestone concept to a later deepening pass because reusable audiences already exist across runtime, admin, compare, and manifest flows.
- **45-02**: Activated `v1.4.0` as a bounded mounted companion proof-reclosure milestone and preserved guarded rollout as the next planned differentiator.
- **48-03**: Archived `v1.4.0` after the milestone audit passed and restored `v1.5.0` as the next recommended candidate.
- **49-00**: Activated `v1.5.0` as a bounded guarded-rollout milestone and kept host-owned observability, mounted-admin, and linked-version package boundaries explicit from the start.
- **49-01**: Completed the bounded guardrail signal contract as a host-owned provider seam with explicit scope, threshold, freshness, sample-size, compare, and export semantics.
- **50-01**: Completed the guarded decision engine and audit path in `rulestead`, keeping automatic hold and rollback inside the existing store/governance/audit spine.

## Latest Activity

- 2026-05-27 — Reconciled GSD planning truth after terminal interruption: `main` and `origin/main` both point at `c4dd3fb`, Phase 49 and Phase 50 code is pushed, and the active next step is Phase 51 planning.
- 2026-05-26 — Implemented and pushed Phase 50 guarded rollout decision engine in commit `c4dd3fb`, adding durable guardrail decisions, `advance_rollout`, `evaluate_guarded_rollout`, `fetch_guardrail_status`, hold behavior, rollback-to-stable-snapshot behavior, and Ecto/fake adapter proof.
- 2026-05-26 — Executed Phase 49 guardrail signal contract across three plans: host-owned signal seam, authored rollout guardrail definitions, and compare/export durability proof.
- 2026-05-26 — Activated milestone `v1.5.0`, created `.planning/REQUIREMENTS.md`, rewrote `.planning/ROADMAP.md` for Phases 49-52, updated `.planning/PROJECT.md`, and reset active planning state for phase work.
- 2026-05-26 — Archived milestone `v1.4.0`, created shipped roadmap and requirements archives, updated the project and milestone arc, and reset planning state to await the next milestone definition.
- 2026-05-26 — Milestone audit for `v1.4.0` passed with all 5 requirements satisfied and no blocking integration or flow gaps.
- 2026-05-26 — Executed Phase 48, reran the bounded mounted proof bundle plus release-contract suites, created `48-VERIFICATION.md`, and reconciled active planning truth plus the milestone audit to `ready_for_closeout`.
- 2026-05-26 — Executed Phase 47 and reclosed root, package, and maintainer-facing support truth around the bounded mounted companion proof command, fail-closed host seam, and release-contract drift guards.
- 2026-05-25 — Executed Phase 46 and restored the repo-root mounted proof bar, repaired mounted cleanup/preview/confirm permission proof, and added a named mounted-proof CI lane wired into `release_gate`.

## Next Action

Next: Run `$gsd-plan-phase 51` to plan the mounted guardrail workflow against the pushed Phase 50 core/status surface.

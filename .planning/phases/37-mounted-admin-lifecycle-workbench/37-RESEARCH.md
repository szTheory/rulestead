# Phase 37: Mounted Admin Lifecycle Workbench - Research

**Researched:** 2026-05-23
**Domain:** Mounted-admin lifecycle triage, route-backed archive preview/confirm flows, and audit-safe queue return for Rulestead flags. [VERIFIED: repo docs] [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md and UI-SPEC.md)

### Locked Decisions
- **D-01:** Phase 37 stays recommendation-first and narrow. Ordinary tradeoffs should be decided in-agent unless they materially change scope, contract, security/governance, release shape, or package boundaries.
- **D-02:** The lifecycle workbench remains inside the mounted sibling-package posture. No standalone lifecycle console and no alternate admin product surface.
- **D-03:** The lifecycle story stays operator-led: review first, mutate second, audit always.
- **D-04:** `FlagLive.Index` remains the canonical lifecycle workbench. Do not introduce a second inventory screen.
- **D-05:** If a lifecycle entry shortcut is needed, it must resolve into the same `/admin/flags` query schema.
- **D-06:** Environment, lifecycle, stale/freshness, readiness, evidence-quality, owner, and archived filters remain URL-backed and shareable.
- **D-07:** Detail remains a calm read surface with guidance plus links into cleanup/action flow. It does not become the primary mutation hub.
- **D-08:** `owner` filtering remains exact `owner_ref` semantics; looser label discovery stays in general query/search.
- **D-09:** Saved URLs must preserve stable owner-filter meaning even if display labels change.
- **D-10:** Phase 37 ships single-flag actions only. Bulk archive/cleanup is deferred.
- **D-11:** `/cleanup` becomes the canonical pre-mutation review surface.
- **D-12:** Archive flow is route-backed `preview -> confirm -> audit`, with required reason capture.
- **D-13:** Main mutation flow must avoid modal-only orchestration.
- **D-14:** Preview must surface readiness, evidence quality, reasons, unknowns, blockers, recommended next action, and what the mutation changes.
- **D-15:** Confirm must revalidate the current lifecycle/readiness state before apply so stale previews cannot silently archive on drifted evidence.
- **D-16:** Successful actions return operators to the same filtered queue URL they came from.
- **D-17:** Archived visibility must remain explicit on return, including outcome messaging and audit linkage.
- **D-18:** `return_to` or equivalent origin state must be URL-backed and canonicalized in `handle_params/3`, not reconstructed from socket/session memory.
- **D-19:** Patch within the current LiveView for filter changes; navigate between index/detail/cleanup/preview/confirm routes.
- **D-20:** Production confirmation requires exact typed-key confirmation; non-production still requires a reason.

### Out of Scope
- Separate lifecycle console or second filter dialect
- Bulk archive or bulk cleanup
- Hidden automation or auto-archive
- Loose owner identity filtering through display labels
- Session-memory “return to prior filters” behavior
- Phase 38 docs/runbooks
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-03 | Operators can review lifecycle and cleanup posture through shareable admin filters that highlight owner, lifecycle state, last evaluated, code-reference status, and recommended next action. | Extend the existing `FlagLive.Index` URL contract instead of adding a new workbench; keep exact owner filtering and lifecycle presets as canonical query params rendered by the current inventory. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
| LIF-04 | Archive and cleanup flows stay explicit, previewable, and audited; Rulestead never auto-archives flags and never hides uncertainty behind false precision. | Turn `FlagLive.Cleanup` into the stable review entrypoint, then add dedicated preview/confirm routes that re-use the shared lifecycle payload, require reason capture, revalidate before apply, and return to the originating queue with audit-linked feedback. [VERIFIED: codebase grep] [VERIFIED: repo docs] |
</phase_requirements>

## Summary

Phase 37 should not invent a new lifecycle subsystem. The repo already has the correct building blocks: a URL-driven mounted inventory in [`rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex:1), a calm detail surface in [`rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex:1), an advisory cleanup review screen in [`rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex:1), and an explicit governed confirmation precedent in [`rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex`](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/flag_live/kill.ex:1). The recommended implementation is to connect those seams into one route-backed operator spine: `index -> detail/cleanup -> cleanup/preview -> cleanup/confirm -> return_to queue`. [VERIFIED: codebase grep]

The key design problem is not new classification logic; Phase 36 already delivered that. The Phase 37 work is state ownership and mutation safety: preserving shareable queue context across LiveViews, keeping exact `owner_ref` filtering distinct from free-text search, surfacing archive consequences before apply, and revalidating current lifecycle/readiness before archival so the preview cannot go stale silently. The current code does not yet have a canonical `return_to` contract or a post-action queue outcome pattern, so those are the two new seams that need explicit design and tests. [VERIFIED: codebase grep]

**Primary recommendation:** keep `FlagLive.Index` as the only lifecycle workbench, add route-backed lifecycle presets and exact-owner triage to that same URL contract, convert `FlagLive.Cleanup` from “Phase 36 advisory-only” into the stable review page, then implement dedicated preview and confirm LiveViews under `/cleanup` using the kill-switch confirmation pattern plus a new canonical `return_to` path that survives cross-route navigation and successful archival. [VERIFIED: codebase grep] [VERIFIED: repo docs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Canonical lifecycle queue filters and presets | Frontend Server (LiveView) | API / Backend | Filter state is already URL-owned in `FlagLive.Index`; Phase 37 should extend that contract, not duplicate it elsewhere. [VERIFIED: codebase grep] |
| Exact owner filter semantics | API / Backend | Frontend Server (LiveView) | `owner` must continue to mean exact `owner_ref` in the shared list/read seam, with UI copy clarifying that looser discovery belongs in `query`. [VERIFIED: repo docs] [VERIFIED: codebase grep] |
| Preview payload and archive consequence rendering | API / Backend | Frontend Server (LiveView) | Preview should consume the existing shared lifecycle/readiness payload plus existing fetched detail/code-reference context, not compute UI-local heuristics. [VERIFIED: codebase grep] |
| Destructive confirmation and revalidation | Frontend Server (LiveView) | API / Backend | The confirm route owns reason/typed-key validation and immediate revalidation-before-apply, then delegates the actual archive mutation to core command APIs. [VERIFIED: codebase grep] |
| Queue return and audit-linked outcome | Frontend Server (LiveView) | Shared session/path helper | `return_to` is a routing/state concern that must stay canonical across index/detail/cleanup/preview/confirm routes and environment switches. [VERIFIED: codebase grep] |

## Existing Code Signals

### What already exists
- `FlagLive.Index` already normalizes filter params through `handle_params/3`, canonicalizes URLs, and patches filter changes back into the address bar.
- `FlagLive.Index` already exposes `owner`, `lifecycle`, `stale`, `readiness`, `evidence_quality`, and `include_archived` filter vocabulary.
- `FlagLive.Show` already keeps the detail screen read-oriented and links into dedicated routes instead of embedding governed mutation UI inline.
- `FlagLive.Cleanup` already centralizes readiness, evidence quality, reasons, unknowns, blockers, and code references.
- `FlagLive.Kill` already proves the repo’s preferred destructive pattern: dedicated route, required reason, typed confirmation in production, server-side validation, and explicit notice after success.
- `RulesteadAdmin.Live.Session.current_path/3` and `env_links/3` already provide shared mount-path/environment-aware URL helpers.

### What is missing
- No canonical `return_to` parameter is carried from queue -> detail -> cleanup -> mutation routes today.
- Index row links and cleanup links currently preserve `env` but not the full queue filter state.
- Cleanup still contains Phase 36 “mutation comes later” copy and no explicit preview/confirm routes.
- There is no post-action queue banner/highlight pattern after an archive succeeds.
- Router does not yet expose `/cleanup/preview` or `/cleanup/confirm`.

## Recommended Project Structure

```text
rulestead_admin/lib/rulestead_admin/
├── live/
│   ├── flag_live/
│   │   ├── index.ex              # extend queue filters, presets, and return_to entry links
│   │   ├── show.ex               # add calm entrypoints into cleanup review while preserving detail posture
│   │   ├── cleanup.ex            # canonical review page with explicit preview handoff
│   │   ├── cleanup_preview.ex    # new route-backed preview screen
│   │   └── cleanup_confirm.ex    # new route-backed confirm/apply screen
│   └── session.ex                # canonical current_path/env_links helpers extended for return_to if needed
├── components/flag_components.ex # reuse/add outcome banner, summary cards, and action affordances
└── router.ex                     # add preview/confirm lifecycle routes under cleanup
```

This keeps all Phase 37 work inside the mounted admin package and aligned with the existing route-backed operator workflow style. [VERIFIED: codebase grep]

## Architecture Patterns

### Pattern 1: One Inventory, Multiple Presets
**What:** keep `/admin/flags` as the only lifecycle queue and express lifecycle entry shortcuts as prefilled canonical query params rather than as a second LiveView. [VERIFIED: repo docs]

**Use when:** adding “Archive candidates”, “Needs review”, or owner-focused triage shortcuts from nav, banners, or detail/cleanup links.

**Implementation guidance:**
- Use `push_patch` inside `FlagLive.Index` for preset changes.
- Store presets as URL params that round-trip through the same `normalize_filters/2` logic as manual filter changes.
- Preserve existing pagination reset behavior when presets change.

### Pattern 2: Carry `return_to` As A Canonical Path, Not As Partial Params
**What:** preserve the full originating queue URL as a canonical path string instead of trying to reconstruct it from individual assigns later. [INFERENCE from current code and context]

**Use when:** linking from index rows or detail pages into cleanup, preview, and confirm routes.

**Implementation guidance:**
- Generate `return_to` from the already-canonical current index path.
- Re-normalize it at each receiving LiveView so only in-scope mounted-admin paths are accepted.
- When the origin queue excluded archived items, preserve or force `include_archived=true` on the success return path so the archived row remains visible.

### Pattern 3: Review Route, Then Preview Route, Then Confirm Route
**What:** keep cleanup as the evidence/review page, preview as the “what changes” page, and confirm as the only route allowed to apply archive mutation. [VERIFIED: repo docs]

**Use when:** turning the current advisory cleanup surface into an explicit governed action flow without collapsing all steps into one route.

**Implementation guidance:**
- `cleanup.ex` stays read-dominant and links into preview.
- `cleanup_preview.ex` repeats the key evidence plus a concise before/after summary and audit consequences.
- `cleanup_confirm.ex` owns reason validation, production typed-key confirmation, revalidation-before-apply, and success routing.

### Pattern 4: Revalidate Immediately Before Apply
**What:** fetch the latest detail/readiness state during confirmation and block the archive if lifecycle evidence drifted since preview. [VERIFIED: repo docs]

**Use when:** the preview page is not guaranteed to remain fresh across tab switches, reconnects, or concurrent operator activity.

**Implementation guidance:**
- Compare the live detail/readiness posture against the preview assumptions.
- If drift is detected, render a clear message and route the operator back to preview or require a fresh confirm.
- Do not silently proceed on stale preview data.

### Pattern 5: Success Returns To Queue, Not To Confirm
**What:** after archive success, the operator lands back on the originating workbench URL with a visible outcome and audit link. [VERIFIED: repo docs]

**Use when:** completing archive from preview/confirm flows.

**Implementation guidance:**
- Pass a bounded success payload in query params or flash-compatible assigns that can render one neutral-success outcome banner on index.
- Include flag key, environment, echoed reason, and audit-timeline link.
- Highlight the archived row once if it is still present in the returned result set.

## Recommended Decomposition

### Slice A: Workbench URL contract and entrypoints
- Extend `FlagLive.Index` with lifecycle presets, exact-owner helper copy, and queue-aware links that carry canonical `return_to`.
- Update `FlagLive.Show` so “Review cleanup” and adjacent lifecycle links preserve queue return context.
- Keep all workbench state in the current `/admin/flags` query schema.

### Slice B: Route-backed archive workflow
- Convert `FlagLive.Cleanup` into the canonical review page for governed action entry.
- Add router entries plus new `cleanup_preview.ex` and `cleanup_confirm.ex`.
- Reuse kill-switch confirmation rules for required reason and production typed-key confirmation.
- Add pre-apply revalidation and archive apply path.

### Slice C: Queue return, outcome messaging, and tests
- Add canonical `return_to` validation/helper support.
- Return successful archives to the originating queue with explicit archived visibility.
- Render outcome banner + audit link + one-time row highlight on the index.
- Add LiveView coverage for filter round-trips, cross-route `return_to`, confirmation failure, drift revalidation, success return, and archived visibility.

## Testing Strategy

### Core LiveView risks to cover
- Index links preserve queue filters and `return_to`.
- Cleanup/preview/confirm environment links do not lose mounted scope.
- Exact owner filter remains distinct from general `query`.
- Non-production archive confirm requires reason only.
- Production archive confirm requires exact typed key.
- Revalidation failure blocks apply and forces a fresh review.
- Success returns to the originating queue with `include_archived=true` when needed.
- Outcome banner includes archived key, environment, echoed reason, and audit link.

### Likely test files
- `rulestead_admin/test/rulestead_admin/live/flag_live/index_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/show_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_preview_test.exs`
- `rulestead_admin/test/rulestead_admin/live/flag_live/cleanup_confirm_test.exs`

### Verification bias
- Prefer targeted LiveView tests over broad suites.
- Keep assertions concrete: canonical URLs, presence/absence of confirm controls, blocked stale preview copy, and exact outcome-banner strings.
- Reuse fake-store fixtures already present in Phase 36 tests so the lifecycle/readiness payload remains realistic.

## Planning Implications

- The phase should be split into at least two executable plans: one for queue/index/detail/cleanup state plumbing, and one for preview/confirm/archive return flow.
- `FlagLive.Cleanup` should not simultaneously hold the review surface and the final archive apply form; the route split is part of the locked UX contract.
- `Session` is the right shared seam for canonical mounted paths and environment-aware link generation; it is the most likely home for any `return_to` helper/guard.
- No Phase 38 docs or runbooks should be created here.

## Recommended Approach

1. Extend the canonical index/query contract first so every downstream route can inherit a stable `return_to`.
2. Upgrade cleanup into the governed review entrypoint while keeping detail calm.
3. Add preview and confirm LiveViews under `/cleanup`.
4. Reuse the kill-switch confirmation rules for reason + typed production confirmation.
5. Add explicit success return-to-queue behavior with archived visibility and audit-linked outcome rendering.

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|------|----------------|------------|
| `return_to` drift or unsafe path handling | Can break shareable URLs or create confusing back-navigation | Accept only canonical mounted-admin paths and re-normalize on every receiving route |
| Queue item disappears after archive | Violates the “where did it go?” constraint | Preserve or force `include_archived=true` on success return and highlight the archived row |
| Confirm proceeds on stale evidence | Can archive from outdated readiness posture | Re-fetch and revalidate detail/readiness immediately before apply |
| Detail becomes an action hub | Breaks the calm read-surface contract | Keep destructive UI in cleanup/preview/confirm only |
| Bulk semantics leak into the design | Adds scope and audit complexity | Keep every route and command strictly single-flag |

## Final Recommendation

Phase 37 should be planned as a mounted-admin routing and governed-action phase, not as another lifecycle-classification phase. Keep one canonical queue in `FlagLive.Index`, carry that queue state forward as canonical `return_to`, use `FlagLive.Cleanup` as the review waypoint, add dedicated preview and confirm routes beneath cleanup, borrow the kill-switch confirmation pattern for explicit archive apply, and always return the operator to the same filtered queue with archived visibility and an audit-linked outcome banner. That is the smallest coherent implementation that satisfies both `LIF-03` and `LIF-04` without drifting into future bulk tooling or Phase 38 documentation work. [VERIFIED: codebase grep] [VERIFIED: repo docs]

## RESEARCH COMPLETE

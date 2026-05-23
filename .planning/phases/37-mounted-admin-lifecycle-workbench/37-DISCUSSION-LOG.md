# Phase 37: Mounted Admin Lifecycle Workbench - Discussion Log

**Date:** 2026-05-23
**Mode:** recommendation-first discuss synthesis with advisor subagents
**User intent:** discuss all meaningful gray areas, research pros/cons/tradeoffs deeply, use prompt anchors, pull ecosystem lessons, and return one cohesive recommendation set without pushing routine choices back to the user

## Inputs considered

- `.planning/ROADMAP.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- Prior phase contexts: 11, 30, 35, 36
- Prompt anchors from `prompts/`, especially admin UX, engineering DNA, host seam, domain language, security, and LiveView best practices
- Current mounted-admin implementation in:
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex`
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex`
  - `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex`
  - `rulestead_admin/lib/rulestead_admin/components/flag_components.ex`
- Advisor subagent research for five gray areas
- Official ecosystem references including Phoenix LiveView, LaunchDarkly, Unleash, Oban Web, and Phoenix LiveDashboard

## Carried-forward constraints

- Keep URL-backed, shareable mounted-admin state
- Keep detail screens calm and read-oriented
- Preserve explicit `preview -> confirm -> audit` posture
- Keep lifecycle guidance advisory and explicit
- Keep `owner_ref` as the stable ownership contract
- Avoid standalone admin drift and preserve the linked-version sibling-package model
- Avoid automatic archive or heuristic mutation

## Gray areas discussed and locked

### 1. Workbench entrypoint

**Options considered**
- Enrich the existing flag inventory as the canonical lifecycle workbench
- Add a dedicated lifecycle route/screen backed by the same projector
- Add a lifecycle preset/shortcut that still resolves into the existing inventory

**Locked recommendation**
- Keep the existing flag inventory as the canonical lifecycle workbench.
- Allow a route-backed lifecycle preset or shortcut only if it reuses the same inventory/filter contract.

**Why**
- This matches current code, current IA, and idiomatic LiveView URL-state handling.
- It avoids duplicated filter semantics and parallel “flag list truth.”
- It aligns with Elixir operator-console precedents like Oban Web and LiveDashboard.

### 2. Owner filter behavior

**Options considered**
- Exact stable owner filter against `owner_ref` only
- Loose owner text search across ref/display/legacy labels
- Split contract: exact owner filter plus broader discovery search

**Locked recommendation**
- Use the split contract:
  - stable exact owner filter for canonical `owner_ref`
  - broader free-text discovery/search for display snapshots and legacy labels

**Why**
- It preserves durable URL meaning and audit continuity while still staying humane for operators.
- It keeps advisory display data from becoming identity truth.

### 3. Action scope

**Options considered**
- Single-flag lifecycle actions only
- Limited bulk archive only
- Limited bulk archive plus cleanup actions

**Locked recommendation**
- Phase 37 ships single-flag lifecycle actions only.

**Why**
- This keeps preview, authorization, reason capture, and audit attribution honest.
- Batch semantics would widen scope and add failure modes before the workbench is proven.

### 4. Preview flow shape

**Options considered**
- Keep cleanup as the canonical review surface, then branch into route-backed preview/confirm steps
- Trigger archive/cleanup directly from list/detail with modal-only preview

**Locked recommendation**
- Use cleanup as the canonical pre-mutation review surface.
- Add explicit route-backed preview/confirm/reason-capture steps from there.

**Why**
- This matches the repo’s route-backed workflow posture and LiveView’s strengths.
- Modal-only review would be less shareable, less resilient, and more likely to erode the calm-detail rule.

### 5. Post-action destination and visibility

**Options considered**
- Return to the same filtered workbench URL state with explicit archived visibility and audit-linked outcome
- Stay on detail/cleanup after the action
- Hybrid return behavior based on origin

**Locked recommendation**
- Return to the same filtered workbench URL state after action success.
- Keep archived visibility explicit and surface the outcome with an audit link.

**Why**
- This preserves operator queue continuity and avoids the “where did it go?” failure mode.
- It keeps detail/cleanup from becoming the canonical throughput surface.

## Cohesive recommendation set

The final recommendation set is intentionally one system, not five local picks:

1. Use the existing flag inventory as the lifecycle workbench.
2. Keep one canonical URL/filter contract.
3. Make owner filtering exact by `owner_ref`, with broader discovery handled separately.
4. Route from the workbench or detail into cleanup.
5. Use cleanup as the review surface for single-flag lifecycle actions.
6. Confirm with reason capture and revalidation.
7. Return to the same filtered workbench state with archived visibility and an audit-linked outcome.

This creates the intended operator flow:

`scan queue -> filter/share URL -> drill in -> review on cleanup -> confirm with reason -> return to queue with visible outcome`

## Ecosystem lessons that affected the recommendation

- LaunchDarkly is strongest where it keeps central workflow/review surfaces distinct from per-flag context surfaces.
- Unleash is useful inspiration for lifecycle/stale/archive visibility, but its richer bulk and lifecycle semantics would be premature to import wholesale here.
- Oban Web and Phoenix LiveDashboard are the strongest Elixir-native precedents for dense, queryable, route-backed operator workbenches.
- ConfigCat-style simplified stale/zombie heuristics are useful as a warning: weak evidence should not become lifecycle truth or bulk-action confidence.
- LiveView’s patch/navigate split strongly favors route-backed workbench and review flows over modal-heavy mutation UX.

## Preference shift captured

The user explicitly asked to push this preference left inside GSD:

- favor one-shot recommendation-heavy synthesis by default
- use subagent research and prompt anchors before asking
- escalate only the truly very impactful choices

That preference has been reflected in:
- this phase context
- a small tightening in `.planning/METHODOLOGY.md`

---

*Phase: 37-mounted-admin-lifecycle-workbench*
*Discussion logged: 2026-05-23*

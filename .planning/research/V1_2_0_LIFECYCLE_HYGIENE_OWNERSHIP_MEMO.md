# v1.2.0 Candidate Memo: Lifecycle Hygiene & Ownership

**Project:** Rulestead
**Date:** 2026-05-23
**Status:** Recommendation memo for milestone selection
**Confidence:** HIGH for product fit, MEDIUM for exact UX thresholds

## Context

Rulestead has already shipped the hard control-plane primitives: deterministic local evaluation, mounted admin, audit, approvals, scheduling, promotion, GitOps, RBAC, and bounded tenancy. The largest remaining everyday JTBD gap is not more evaluation power. It is the missing "birth to retirement" loop for flags:

- who owns this flag
- how long should it exist
- is it stale
- what code still references it
- when is it safe to archive or retire

That gap is already called out in [.planning/research/JTBD-MAP.md](/Users/jon/projects/rulestead/.planning/research/JTBD-MAP.md), deferred in [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md), and reinforced by the product/persona docs.

## Why This Milestone Fits Now

### Pros

- It sharpens a real post-GA weakness without widening the product.
- It helps every core persona except the pure contributor case: builders clean up debt, leads track ownership, operators triage stale flags, support gets better context.
- It compounds prior work instead of replacing it: code references, audit, compare, RBAC, change requests, and admin list/detail screens all become more valuable.
- It is idiomatic for the current package shape. Ownership metadata and lifecycle workflows belong in `rulestead` plus mounted `rulestead_admin`, not in a separate service.
- It improves principle of least surprise: mature flag platforms all surface lifecycle state, expected lifetime, and ownership instead of treating cleanup as tribal knowledge.

### Cons

- It is less headline-grabbing than guarded rollouts or reusable segments.
- It can become noisy if stale heuristics are weak or too aggressive.
- It introduces governance metadata that teams may leave blank unless the product makes it hard to ignore.
- If overbuilt, it risks turning a clean embedded library into an internal work-management tool.

### Tradeoffs

- Strong recommendation: prefer opinionated metadata plus actionable lists over a full-blown workflow engine.
- Strong recommendation: lifecycle state should guide operators, not silently mutate runtime semantics.
- Strong recommendation: make ownership required for new flags in admin UX, but keep runtime evaluation ignorant of ownership fields.

## What This Looks Like

### Library / runtime

- `Rulestead.Flag` gains bounded metadata such as `owner_ref`, `owner_kind`, `flag_type`, `expected_lifetime_days`, `sunset_at`, and `lifecycle_state`.
- Public read APIs expose this metadata for docs, admin, and CLI use, but `evaluate/3` remains pure and does not depend on it.
- Staleness is computed from authored metadata plus observed activity, not from ad hoc operator memory.
- Code references stay additive: "this flag has 4 live references in host code" should inform archive readiness, not block evaluation.

Concrete example:

```elixir
Rulestead.create_flag(%{
  key: "checkout_v2",
  flag_type: :release,
  owner_ref: "team:checkout",
  expected_lifetime_days: 40,
  description: "Progressive rollout for new checkout flow"
})
```

### Product / host-app DX

- `mix rulestead.add_flag` should prompt for owner and type.
- `mix rulestead.lifecycle` or `mix rulestead.stale` should show grouped cleanup candidates:
  - stale and still referenced
  - stale and unreferenced
  - launched but ready for code removal
  - archived but still referenced
- Host apps should be able to map internal ownership semantics without forcing Rulestead to model org charts. `owner_ref` should stay opaque.

Concrete example:

```bash
mix rulestead.stale --env prod

checkout_v2    stale   owner=team:checkout   refs=3   last_eval=18d   next_action=remove code then archive
legacy_pricing stale   owner=user:42         refs=0   last_eval=67d   next_action=archive now
```

### Admin UX

- Flag list gets filters for `Owner`, `Lifecycle`, `Type`, and `Ready for archive`.
- Flag detail gets an ownership/lifecycle card near status, not buried in settings.
- A new cleanup workbench or filtered list is preferable to a brand-new admin area. This should feel like an operator flow, not a different product.
- Archive should remain explicit and audited. "Ready to archive" is a recommendation, not an automatic destructive action.

Concrete example:

- Flag row pills: `Release`, `Potentially stale`, `Owner: Checkout`
- Detail page card:
  - Owner: `team:checkout`
  - Expected lifetime: `40 days`
  - Created: `2026-04-01`
  - Last evaluated: `2026-05-22`
  - Code references: `3`
  - Cleanup status: `Ready for code removal`
- Archive flow copy:
  - "No code references detected in the last scan. Flag is inactive in prod and older than expected lifetime. Archive?"

## Idiomatic Elixir / Plug / Ecto / Phoenix Shape

- Put lifecycle state derivation in core domain modules, not LiveViews.
- Use `Ecto.Multi` for every mutation that changes flag metadata and writes audit rows. This matches existing project DNA and keeps admin actions unsurprising.
- Store ownership and lifecycle metadata on the authored flag record, not in admin-only tables owned by `rulestead_admin`.
- Keep admin state URL-driven with `handle_params/3` for shareable filters like `?lifecycle=stale&owner=team:checkout`.
- Use LiveView streams and keyset pagination for cleanup/stale lists; this is already the right idiom for Rulestead's operator surfaces.
- Prefer additive background jobs for lifecycle scans via existing Oban seams, but never make runtime evaluation depend on those jobs having run.
- Expose lifecycle classification through stable public functions such as `Rulestead.lifecycle_status/2` rather than requiring callers to reproduce heuristics.

## Lessons From Comparable Tools

### Unleash

What it did right:

- Treats flag type and expected lifetime as first-class metadata.
- Marks flags `potentially stale` and `stale` automatically.
- Connects stale-state transitions to integrations and cleanup workflows.

What Rulestead should learn:

- Default expected lifetimes by flag type are useful and unsurprising.
- Lifecycle should be visible in the main list, not hidden in docs.

Footguns to avoid:

- Do not copy a broad project/workspace model just to support lifecycle.
- Do not let stale-state imply safe deletion without code-reference evidence.

### LaunchDarkly

What it did right:

- Distinguishes "ready for code removal" from "ready to archive."
- Combines age, evaluation activity, prerequisites, and code references.
- Allows lifecycle rules to be tuned rather than hardcoded forever.

What Rulestead should learn:

- Archive readiness is a richer concept than "old flag."
- The cleanup journey should have stages, not a binary stale toggle.

Footguns to avoid:

- Do not make the heuristic so configurable that small teams cannot predict behavior.
- Do not require enterprise-scale project modeling before lifecycle becomes useful.

### GrowthBook

What it did right:

- Strong emphasis on stale flag detection, code references, and developer/operator tooling.
- Good "debug and simulate" posture alongside feature management.

What Rulestead should learn:

- Cleanup value increases when code references and admin context sit together.
- Lifecycle is more credible when it is integrated into the core feature list rather than bolted on.

Footguns to avoid:

- Do not let experimentation-first concerns dominate this milestone.
- Avoid importing sticky-bucketing or rollout-health scope into a cleanup milestone.

### Flipper / Flipper Cloud

What it did right:

- Keeps evaluation local and fast while pushing ownership, audit, permissions, and history into the control plane.
- Models temporary/permanent longevity and feature owners in the product shape.

What Rulestead should learn:

- The runtime/control-plane split remains correct.
- Ownership metadata belongs with flag organization, not runtime branching logic.

Footguns to avoid:

- Flipper's broader hosted-cloud affordances are not Rulestead's next move.
- Avoid any move that makes `rulestead_admin` feel like an independently sold platform.

### FunWithFlags

What it did right:

- Proved the Elixir appetite for local evaluation, embeddability, and optional mounted UI.

What Rulestead should learn:

- Preserve the library-first ergonomics and host-app friendliness.
- Keep lifecycle work from contaminating the fast path.

Footguns to avoid:

- Do not regress toward gate-model complexity or host-coupled assumptions.
- Do not make lifecycle work depend on bespoke external services.

## Requirement Themes If This Becomes v1.2.0

- Ownership metadata is first-class for authored flags and surfaced everywhere operators already look.
- Lifecycle state is derived and explainable: active, potentially stale, stale, archived, retired.
- Cleanup flow distinguishes:
  - needs code removal
  - ready to archive
  - archived but still referenced
- Code references become part of archive guidance, not just passive research data.
- Admin UX prioritizes triage and actionability over taxonomy depth.
- CLI/docs story makes builders participate in cleanup, not just operators.

## Non-Goals

- No standalone `rulestead_admin` expansion.
- No org-chart, team-directory, or HR-style ownership model.
- No automatic code deletion or repo rewrites.
- No metric-driven rollback, guarded rollout automation, or experimentation expansion in this milestone.
- No segment/template system.
- No tenant hierarchies or topology changes.
- No runtime behavior change based on ownership or lifecycle metadata.

## Should This Be The Next Milestone?

Yes.

This is the best next milestone because it closes the most obvious everyday product gap without reopening architecture risk. Tenancy is shipped as a bounded seam. GA-grade governance, promotion, and diagnostics are already in place. The next highest-value move is to make flags easier to own, review, and retire. That improves operator trust and host-app friendliness immediately, while keeping the runtime and sibling-package boundaries intact.

I would defer guarded rollouts and reusable targeting assets until after Rulestead proves a credible cleanup loop. Mature platforms win by reducing flag debt, not just by adding more rollout features.

## Recommendation

Make `v1.2.0` a bounded lifecycle-and-ownership milestone.

Target a narrow outcome: every flag should have clear ownership, a visible expected lifetime, an explainable lifecycle state, and an explicit cleanup path backed by code references and audit-safe archive flows. Keep the milestone focused on list/detail/workbench UX, additive metadata, and stable public lifecycle APIs. Do not bundle guarded rollouts, segment reuse, or deeper experimentation work into it.

## Guardrails

- Keep lifecycle metadata in `rulestead`; keep presentation and workflows in `rulestead_admin`.
- Keep runtime evaluation fully independent of lifecycle scans, owner lookups, and admin UX.
- Treat `owner_ref` as opaque host-owned text or structured token, not a new Rulestead identity system.
- Make stale/archive readiness advisory and explicit; never auto-archive by background job.
- Reuse existing audit, policy, scheduling, and mounted-route seams instead of introducing parallel workflow systems.
- Prefer fixed sensible defaults by flag type before adding configurability.
- Preserve linked-version sibling-package discipline: no feature should require publishing `rulestead_admin` alone.
- Ship the cleanup loop as a calm extension of existing flag list/detail flows, not as a new platform surface.

## Sources

### Project sources

- [.planning/PROJECT.md](/Users/jon/projects/rulestead/.planning/PROJECT.md)
- [.planning/ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md)
- [.planning/STATE.md](/Users/jon/projects/rulestead/.planning/STATE.md)
- [.planning/research/JTBD-MAP.md](/Users/jon/projects/rulestead/.planning/research/JTBD-MAP.md)
- [.planning/milestones/v1.1.0-REQUIREMENTS.md](/Users/jon/projects/rulestead/.planning/milestones/v1.1.0-REQUIREMENTS.md)
- [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md)
- [prompts/rulestead-domain-language-field-guide.md](/Users/jon/projects/rulestead/prompts/rulestead-domain-language-field-guide.md)
- [prompts/rulestead-admin-ux-and-operator-ia.md](/Users/jon/projects/rulestead/prompts/rulestead-admin-ux-and-operator-ia.md)
- [prompts/rulestead-personas-jtbd-and-onboarding.md](/Users/jon/projects/rulestead/prompts/rulestead-personas-jtbd-and-onboarding.md)
- [prompts/rulestead-host-app-integration-seam.md](/Users/jon/projects/rulestead/prompts/rulestead-host-app-integration-seam.md)
- [prompts/rulestead-security-privacy-and-threat-model.md](/Users/jon/projects/rulestead/prompts/rulestead-security-privacy-and-threat-model.md)
- [prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md)
- [prompts/elixir_feature_flags_research_brief.md](/Users/jon/projects/rulestead/prompts/elixir_feature_flags_research_brief.md)

### External references

- Unleash feature toggles and lifecycle: https://docs.getunleash.io/reference/feature-toggles
- LaunchDarkly flag lifecycle and statuses: https://launchdarkly.com/docs/home/flags/flag-status
- LaunchDarkly lifecycle settings: https://launchdarkly.com/docs/home/flags/flag-lifecycle-settings
- LaunchDarkly flag health: https://launchdarkly.com/docs/home/observability/flag-health
- GrowthBook feature flags overview: https://www.growthbook.io/products/feature-flags
- Phoenix LiveView `handle_params/3`: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
- Ecto.Multi: https://hexdocs.pm/ecto/Ecto.Multi.html
- FunWithFlags docs: https://hexdocs.pm/fun_with_flags/readme.html
- Flipper Cloud overview: https://www.flippercloud.io/docs/cloud

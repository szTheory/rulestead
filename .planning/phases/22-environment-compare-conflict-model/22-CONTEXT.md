# Phase 22: Environment Compare & Conflict Model - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning
**Research mode:** discuss-all with parallel advisor passes across compare scope, authored-state boundary, conflict taxonomy, stale-preview semantics, and operator result shape

<domain>
## Phase Boundary

Let operators compare source and target environment configuration using authored state before any apply happens. Phase 22 defines the compare model, dependency closure, stale-preview contract, and operator-facing read surfaces that Phase 23 will later use for governed apply.

**In scope:**
- authored-state compare between source and target environments
- dependency validation and conflict/drift classification
- stale-preview detection and compare token semantics
- a read-only compare summary surface plus per-flag compare drill-in
- one canonical compare result payload that later admin, CLI, and manifest workflows can share

**Out of scope (explicitly deferred):**
- actual promotion/apply mutations
- bulk apply console behavior
- release-pipeline orchestration or stage engines
- destructive prune semantics
- Git-first reconciliation as the primary authoring model
- broader environment-management product surface

</domain>

<decisions>
## Implementation Decisions

### Compare Surface and Route Model
- **D-01:** Phase 22 starts with a **hybrid compare surface**: a lightweight environment-to-environment summary page that lists only differing or problematic flags, plus a per-flag compare drill-in where the real authored-state reasoning happens.
- **D-02:** Do **not** start with a standalone compare console that behaves like a release-orchestration product. Do **not** hide full compare only inside the existing flag detail page.
- **D-03:** The summary route stays read-only and shallow in Phase 22. It exists for discovery, scanability, and navigation into the per-flag compare screen, not for mutation.
- **D-04:** The compare entry should preserve the mounted admin’s existing URL/state discipline. Environment selection remains explicit and URL-backed; do not fork the current admin model into hidden session-only compare state.
- **D-05:** Phase 22 compare is whole-flag compare. Partial-rule or cherry-pick promotion remains deferred with `PROM-05`.

### Authored-State Boundary
- **D-06:** The canonical authored compare set is:
  - global flag metadata (`key`, description, flag/value type, default value, owner, lifecycle fields, tags, archive state)
  - the source and target environment’s **published** ruleset and active pointer
  - the dependency closure required to realize that published authored state, especially referenced audiences and similar prerequisite authored objects
- **D-07:** Draft rulesets are authored work, but they are **not** part of the default promotable compare basis. Surface them as explicit unpublished work so operators see that source has newer saved intent without accidentally promoting drafts.
- **D-08:** Kill-switch overrides, runtime snapshots, evaluation freshness counters, telemetry-derived stats, audit history, approval state, and similar operational/process artifacts are **not** part of authored compare. Surface them separately as warnings or banners when relevant.
- **D-09:** The compare model must preserve the project’s existing split: authored publication changes the desired config, and runtime snapshots/operational overlays remain separate consequences or overlays of that authored state.

### Dependency and Conflict Taxonomy
- **D-10:** Compare findings use a typed three-severity model:
  - `blocker` — not safe to apply because the proposed target state is invalid, unreproducible, or stale
  - `warning` — applyable, but operator intent may be misunderstood or runtime behavior may still differ due to non-authored state
  - `info` — observational drift or non-blocking asymmetry
- **D-11:** Severity is derived from **apply safety**, not from how visually different two environments are.
- **D-12:** Findings should also carry a typed class such as `missing_dependency`, `lifecycle_conflict`, `staleness_conflict`, `operational_override`, `soft_mismatch`, or `drift_info`, so later CLI and manifest workflows can preserve meaning without scraping prose.
- **D-13:** Recommended default classifications:
  - missing prerequisite/dependency required to realize source authored state -> `blocker`
  - source changed since preview -> `blocker`
  - target changed since preview -> `blocker`
  - stale preview bundle / compare token -> `blocker`
  - archived/retired target state that would require an explicit revive path -> `blocker`
  - active kill-switch or similar operational override difference -> `warning` by default
  - missing target `flag_environment` row that apply can legitimately create -> `warning`
  - protected target environment requiring governed apply -> `warning`
  - target-only unrelated extra state outside the selected authored scope -> `info`
- **D-14:** Do not silently treat operational overrides as authored diffs. Surface them explicitly and separately.

### Stale-Preview Contract
- **D-15:** Every compare result must carry a `compare_token` built from:
  - source environment
  - target environment
  - compared flag keys
  - dependency-closure keys
  - compare schema/algorithm version
  - source and target authored-state heads or fingerprints for that exact set
- **D-16:** A preview becomes **hard-stale** if apply-relevant authored state changes on either side for the compared set or its dependency closure.
- **D-17:** Unrelated mutations elsewhere in the source or target environment must **not** invalidate the compare token.
- **D-18:** Add a warning-only age badge after a short window, but do **not** hard-expire compare purely on elapsed time.
- **D-19:** Phase 23 governed apply and Phase 24 CLI/manifest flows should treat this token as a real workflow contract, not a cosmetic UI hint.

### Result Shape and Information Hierarchy
- **D-20:** The compare result should use a layered hybrid presentation:
  - context bar first
  - overall status and counts next
  - findings buckets next
  - per-flag rows next
  - expandable structured diffs after that
  - raw/machine payload hidden behind progressive disclosure
- **D-21:** Raw document diff is the wrong default for Rulestead. Summary and go/no-go clarity come first; exact detail is available on demand.
- **D-22:** The UI and future CLI should render the same canonical compare payload instead of inventing separate summary logic per surface.
- **D-23:** Each flag compare entry should conceptually carry:
  - `flag_key`
  - status / severity summary
  - changed fields
  - dependency findings
  - drift findings
  - conflict findings
  - source state
  - current target state
  - proposed target state after apply
- **D-24:** Use explicit directionality in copy and structure: `source`, `current target`, and `proposed target after apply`. Never collapse these into a vague “before/after.”

### Recommendation-Heavy Planning Posture
- **D-25:** For this repo and milestone, shift recommendations left in downstream GSD work by default. Research and planning should come back with a coherent recommended path unless a choice is truly high-impact, product-defining, or dangerous to lock without user confirmation.
- **D-26:** “High-impact” here means a choice that would materially change product scope, public contract, security posture, or release shape. Normal implementation tradeoffs should default to recommendation-first rather than question-first.

### the agent's Discretion
- Exact module and payload struct names for compare projections, provided the authored-state boundary and finding taxonomy stay intact
- Exact route names and LiveView/module split for the summary and drill-in surfaces, provided the hybrid IA stays intact
- Exact fingerprint/head implementation strategy, provided it is stable and scoped to apply-relevant authored state rather than whole-environment churn
- Exact warning copy, badge labels, and progressive-disclosure mechanics, provided the calm operator posture and explicit directionality remain intact

</decisions>

<specifics>
## Specific Ideas

- Treat compare as the promotion equivalent of a Terraform plan: a human-readable summary plus a machine-readable payload generated from the same canonical model.
- Learn from LaunchDarkly’s dual-level compare UX, Unleash’s unified-flag-per-environment model, and GrowthBook’s revision/diff mindset, without pulling Rulestead into full release-pipeline scope this milestone.
- Keep Phase 22 honest about what it is building: a compare contract and read surface that Phase 23 can safely apply, not a workflow engine.
- Preserve the current admin mental model: calm read surfaces, route-backed heavy workspaces, explicit environment scope, and no surprise hidden state.
- Surface unpublished drafts and operational overrides, but do not let them contaminate the default promotable authored-state model.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 22 goal, success criteria, and the explicit split between compare now and apply later
- `.planning/REQUIREMENTS.md` — source of truth for `PROM-01` and `PROM-02`
- `.planning/PROJECT.md` — linked-version product shape, calm admin posture, and `v0.6.0` milestone goals
- `.planning/STATE.md` — current milestone state and active focus

### Prior locked decisions
- `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md` — unified flag identity, environment overlays, immutable published rulesets, and key-first store posture
- `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-CONTEXT.md` — calm detail surface, dedicated workspaces, and canonical `?env=` model
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — explicit route-backed operator workflows, summary-first posture, kill-switch semantics, and append-only audit stance
- `.planning/phases/10-scheduled-changes-and-durable-execution/10-CONTEXT.md` — stale-intent failure posture, scheduled execution truth model, and recommendation-heavy planning preference
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — diff-first review surfaces, explicit approval/execution separation, and route-backed workflow posture

### Milestone-shape and research anchors
- `.planning/research/V0_6_PRODUCT_SHAPE.md` — milestone-level recommendation for unified flag + environment overlay + compare/apply
- `prompts/elixir_feature_flags_research_brief.md` — market and product lessons from FunWithFlags, Unleash, GrowthBook, LaunchDarkly, and related systems
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — inherited repo/release/API/testing patterns and planning discipline
- `prompts/rulestead-admin-ux-and-operator-ia.md` — operator IA, progressive disclosure, and mounted admin expectations
- `prompts/rulestead-domain-language-field-guide.md` — canonical nouns and verbs for flags, rulesets, environments, manifests, diffing, and audit
- `prompts/rulestead-security-privacy-and-threat-model.md` — least-surprise governance and protected-environment posture
- `prompts/rulestead-telemetry-observability-and-audit.md` — durable audit vs ephemeral telemetry boundary
- `prompts/rulestead-host-app-integration-seam.md` — mounted sibling-package and host-owned integration constraints
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — operator and developer expectations for safety and clarity

### Existing code and contracts
- `rulestead/lib/rulestead/store.ex` — store behavior surface compare must eventually extend
- `rulestead/lib/rulestead/store/command.ex` — existing command normalization and future place to carry compare/apply metadata
- `rulestead/lib/rulestead/store/ecto.ex` — authored payload projection, publication path, audit metadata, and environment-specific state already modeled
- `rulestead/lib/rulestead/flag.ex` — global authored flag metadata
- `rulestead/lib/rulestead/flag_environment.ex` — environment overlay state and operational override fields
- `rulestead/lib/rulestead/ruleset.ex` — immutable ruleset version model
- `rulestead/lib/rulestead/ruleset/rule.ex` — dependency-bearing rule structure
- `rulestead/lib/rulestead/audience.ex` — reusable audience dependency model
- `rulestead/lib/rulestead/governance/change_request.ex` — governed workflow contract that later apply will use
- `rulestead/lib/rulestead/governance/scheduled_execution.ex` — scheduled execution contract that later stale-compare revalidation must feed
- `rulestead_admin/lib/rulestead_admin/live/session.ex` — canonical environment URL/state model
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — existing calm read surface boundary
- `rulestead_admin/lib/rulestead_admin/components/operator_components.ex` — summary/status component vocabulary for compare results
- `rulestead_admin/lib/rulestead_admin/components/audit_components.ex` — readable diff rendering patterns already present

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Store.Ecto.build_flag_detail_payload/4` and related projections already expose a useful authored flag/environment payload shape that compare can reuse rather than reinventing.
- `Rulestead.Flag`, `Rulestead.FlagEnvironment`, `Rulestead.Ruleset`, and `Rulestead.Audience` already encode the right authored-state split for compare semantics.
- Existing audit metadata helpers in the store already project before/after/diff structures that can inform compare-result serialization.
- `RulesteadAdmin.Live.Session` already centralizes current environment, env links, policy state, and mounted-path behavior.
- `RulesteadAdmin.Components.OperatorComponents` and `AuditComponents` already support summary-first, readable-diff rendering patterns that match the recommended compare IA.

### Established Patterns
- The repo consistently prefers explicit route-backed workflows over overloaded detail pages.
- Draft vs publish is already a first-class distinction; compare should preserve that rather than flattening drafts into live state.
- Governance, scheduling, and audit already assume explicit staleness/conflict handling rather than hidden best-effort reconciliation.
- The admin package is intentionally mounted, sibling-scoped, and calm; compare must not turn it into a general release-orchestration control plane in this phase.

### Integration Points
- Phase 22 compare should produce a canonical payload that Phase 23 can attach to change requests or execution metadata without redesign.
- Phase 24 CLI/manifests should reuse the same finding codes, compare token semantics, and authored-state boundary rather than defining a second diff model.
- Any future compare/apply command surface should preserve stable machine-readable output from the same canonical projection used by the admin UI.

</code_context>

<deferred>
## Deferred Ideas

- Bulk environment promotion console or release-pipeline UX
- Automated stage engines or multi-step promotion workflows
- Destructive prune semantics for target-only extra state
- Git-first reconciler as the primary authoring model
- Partial-rule or cherry-pick promotion as a primary UX
- Broader environment-management product surface beyond compare and promotion

</deferred>

---

*Phase: 22-environment-compare-conflict-model*
*Context gathered: 2026-05-18*

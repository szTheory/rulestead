# Phase 36: Archive-Readiness Signals & Cleanup Analysis - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning
**Source:** discuss-all synthesis with parallel advisor research, codebase inspection, prior phase context, and prompt-anchor review

<domain>
## Phase Boundary

Turn archive-readiness into a bounded advisory system built from authored lifecycle intent, evaluation evidence, and code-reference signals, then expose that guidance through read-only admin/CLI reporting surfaces without storing computed readiness as canonical truth and without widening into mutation automation.

**In scope:**
- separate authored lifecycle facts from derived archive-readiness guidance
- combine lifecycle posture, evaluation evidence, code-reference evidence, and uncertainty into bounded advisory categories
- expose the new guidance through mounted-admin projections and a read-only CLI/report surface
- define recommended next-action semantics that stay advisory, explicit, and compatible with later Phase 37 mutation flows

**Out of scope:**
- automatic archive, automatic code removal, or any background cleanup mutation
- persisted computed readiness scores or machine-truth lifecycle enums
- Phase 37 workbench actions, previews, reasons, or archive execution flows
- standalone analytics/scoring engines, background recompute subsystems, or host-repo crawling inside Rulestead

</domain>

<decisions>
## Implementation Decisions

### Product shape and milestone discipline
- **D-01:** Phase 36 remains advisory and read-only. It must improve operator judgment, not automate cleanup.
- **D-02:** Recommendation-heavy output is preferred. Planning should assume one coherent path unless a choice would materially change public contract, security/governance posture, release shape, or package boundaries.
- **D-03:** The system must continue to honor the Phase 35 rule: operators author facts, admin computes guidance.

### Lifecycle facts vs archive-readiness guidance
- **D-04:** Keep authored lifecycle facts and derived archive-readiness guidance as separate axes.
- **D-05:** `archived_at` remains the only hard terminal lifecycle fact. Lifecycle-authored fields such as mode, review horizon, and override provenance remain canonical truth.
- **D-06:** Derived archive-readiness must not replace lifecycle posture and must not be persisted as canonical database truth.
- **D-07:** The current overloading of `lifecycle.state` with freshness semantics should be refactored toward a split model:
  - lifecycle/authored posture
  - freshness/evaluation evidence
  - archive-readiness advisory
- **D-08:** `stale` becomes one evidence signal inside archive-readiness, not the product’s entire cleanup model.

### Advisory model and evidence composition
- **D-09:** Use a bounded **rule-ladder plus evidence-matrix** model, exposed as categories and evidence quality, not a numeric score.
- **D-10:** User-visible numeric readiness scores are disallowed. They create false precision and undermine operator trust.
- **D-11:** Recommended derived guidance shape should include at least:
  - `readiness`
  - `evidence_quality`
  - `reasons`
  - `unknowns`
  - `blockers`
  - `recommended_next_action`
  - bounded secondary actions
- **D-12:** Recommended readiness categories are:
  - `keep_active`
  - `needs_review`
  - `archive_candidate`
- **D-13:** Recommended evidence-quality categories are:
  - `strong`
  - `partial`
  - `weak`
- **D-14:** If internal ordering is needed for sorting, use a hidden ordinal tuple or comparable bounded ranking. Do not expose that rank as a product score.
- **D-15:** Archive-readiness must stay explainable in plain language from the returned reasons and unknowns. Operators should be able to see what signal drove the recommendation without reverse-engineering weights.

### Signal semantics and uncertainty handling
- **D-16:** Distinguish positive evidence, negative evidence, and missing evidence explicitly. Missing data must never quietly count as archive-positive evidence.
- **D-17:** `no code references found from a fresh scan` is positive evidence; `no scan` or `stale scan` is uncertainty.
- **D-18:** Distinguish at least:
  - `recently evaluated`
  - `not evaluated recently`
  - `never evaluated`
  - `evaluation evidence unavailable`
- **D-19:** Evaluation evidence gaps must degrade evidence quality rather than silently helping an archive recommendation.
- **D-20:** Permanent authored posture should strongly resist archive recommendations unless later phases introduce an explicit retirement flow.
- **D-21:** Expiring authored posture lowers the archive-readiness threshold, but it must not override contradictory evidence such as fresh code references or recent evaluations.
- **D-22:** `remote_config` remains the important exception. Its readiness posture must follow authored intent more than type default, and it should require stronger evidence before becoming an archive candidate.
- **D-23:** `kill_switch`, `operational`, and `permission` flags should default toward `keep_active` unless explicit authored lifecycle posture and evidence clearly say otherwise.
- **D-24:** The archive-readiness model must be honest about uncertainty. Recommended UI/CLI language should say “guidance limited by missing evidence” rather than implying certainty.

### Recommendation UX and operator guidance
- **D-25:** Show one **primary recommended next action** plus at most two bounded secondary actions.
- **D-26:** When evidence is conflicting or weak, withhold the primary recommendation and surface a review-oriented message instead of pretending the system knows.
- **D-27:** Recommended next-action vocabulary should stay concrete and advisory, for example:
  - `keep_active`
  - `review_manually`
  - `refresh_code_refs`
  - `collect_eval_evidence`
  - `remove_code_refs`
  - `mark_permanent`
  - `archive_ready`
- **D-28:** Checklists are appropriate only after an action path is chosen. They should support Phase 37 preview/confirm flows, not replace Phase 36 recommendations.
- **D-29:** Mounted-admin copy should preserve the calm “read surface first, explicit action later” posture already used in the detail and cleanup views.

### CLI and reporting surface
- **D-30:** Phase 36 should add a **read-only** lifecycle/cleanup report command. No CLI mutation path ships in this phase.
- **D-31:** The preferred task shape is `mix rulestead.lifecycle`, with default human-readable text output and stable `--format json` output for scripts.
- **D-32:** CLI filter names should mirror mounted-admin vocabulary and URL state as closely as possible, including environment, owner, lifecycle, stale/freshness, and archived inclusion semantics.
- **D-33:** JSON output is the canonical machine contract; text output is a renderer over the same data, not a separate schema.
- **D-34:** The CLI should include a format/schema version field so downstream automation can remain stable as reporting evolves.
- **D-35:** This phase should not introduce `plan/apply` or `cleanup` mutation commands. Those belong in Phase 37 when explicit preview/confirm/audit flows land.

### Architecture and implementation guardrails
- **D-36:** Extend the existing projector seam in `Rulestead.Admin.Lifecycle` or an equivalent adjacent derived-guidance seam. Keep the computation pure and read-model focused.
- **D-37:** Avoid background recompute jobs, trigger-based projection persistence, generated columns, or SQL-heavy rule duplication for archive-readiness in this phase.
- **D-38:** Use bounded enums/atoms and stable reason identifiers so mounted-admin, CLI, and tests can share one coherent vocabulary.
- **D-39:** New public/admin payloads should carry enough explanation for LiveView badges, filters, cleanup screens, and CLI reports without requiring separate recomputation in each surface.

### Ecosystem lessons to incorporate
- **D-40:** Learn from LaunchDarkly’s separation of lifecycle intent, code-removal guidance, and archival checks; do not collapse them into one blunt stale bit.
- **D-41:** Learn from Unleash and Statsig that authored permanence vs temporary posture matters, but do not import their richer SaaS-only stage models wholesale into Rulestead’s bounded library/product shape.
- **D-42:** Avoid the ConfigCat/GrowthBook footgun of over-trusting weak or modified-time-only staleness heuristics.

### the agent's Discretion
- Exact field names for archive-readiness, evidence-quality, reason, and unknown sets
- Exact render shape for admin badges/cards, provided the authored-facts vs derived-guidance split remains explicit
- Exact CLI text layout, provided JSON remains the stable machine contract
- Exact internal sort tuple/rank shape, provided no user-visible score is introduced

</decisions>

<specifics>
## Specific Ideas

- Think in terms of **“lifecycle facts + freshness evidence + archive-readiness guidance”** rather than one overloaded lifecycle state.
- The mounted-admin list already separates `lifecycle` and `stale` filters; Phase 36 should formalize that split instead of deepening the ambiguity.
- The best operator experience here is:
  - one clear recommendation when evidence is good
  - bounded alternatives when there is a legitimate nearby option
  - explicit withholding when evidence is incomplete
- The CLI should feel like the rest of the repo’s operator commands: one discoverable top-level task, text by default, JSON for automation, no surprise mutation flags.
- `remote_config` needs special treatment because “quiet” config is not the same as dead config.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 36 goal, milestone framing, and explicit reporting/advisory scope
- `.planning/PROJECT.md` — `v1.2.0` goals, least-surprise lifecycle posture, and out-of-scope boundaries
- `.planning/REQUIREMENTS.md` — `LIF-02` and adjacent milestone constraints
- `.planning/STATE.md` — current milestone position and active phase context
- `.planning/METHODOLOGY.md` — recommendation-first planning lens for this repo

### Prior lifecycle and ownership decisions
- `.planning/phases/35-lifecycle-contract-ownership-metadata/35-CONTEXT.md` — authored-truth vs derived-guidance boundary, owner semantics, and no persisted machine lifecycle truth
- `.planning/phases/15-lifecycle-hygiene-and-code-references/15-CONTEXT.md` — passive code-reference ingestion, manual cleanup discipline, and no auto-archive precedent

### Prompt anchors
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — sibling-package architecture, operator trust, projection boundaries, and Mix task house style
- `prompts/rulestead-admin-ux-and-operator-ia.md` — calm mounted-admin read surfaces, shareable filter state, and preview/confirm/audit posture
- `prompts/rulestead-host-app-integration-seam.md` — host-facing CLI/install ergonomics and least-surprise integration seams
- `prompts/rulestead-domain-language-field-guide.md` — canonical lifecycle, stale, archive, and action vocabulary
- `prompts/rulestead-telemetry-observability-and-audit.md` — evidence, audit, and no-false-precision observability posture

### Existing code seams
- `rulestead/lib/rulestead/admin/lifecycle.ex` — current derived lifecycle/freshness projector that should absorb the new advisory split
- `rulestead/lib/rulestead/admin/stale_tracker.ex` — evaluation evidence ingestion seam for freshness signals
- `rulestead/lib/rulestead/flag/lifecycle_metadata.ex` — authored lifecycle metadata contract
- `rulestead/lib/rulestead/code_refs/code_reference.ex` — current code-reference evidence model
- `rulestead/lib/rulestead/telemetry/cache.ex` — low-level evaluation evidence source
- `rulestead_admin/lib/rulestead_admin/live/flag_live/index.ex` — current filter vocabulary and inventory read surface
- `rulestead_admin/lib/rulestead_admin/live/flag_live/show.ex` — detail-page lifecycle presentation and action entrypoints
- `rulestead_admin/lib/rulestead_admin/live/flag_live/cleanup.ex` — explicit cleanup/archive boundary that Phase 36 must support without widening into mutation automation
- `rulestead_admin/lib/rulestead_admin/components/flag_components.ex` — current lifecycle/stale badge vocabulary and tone mapping
- `rulestead/lib/mix/tasks/rulestead.promote.ex` — current Mix task contract conventions for text/json and read-vs-mutate separation
- `rulestead/lib/mix/tasks/rulestead.code_refs.ex` — existing operator-facing code-reference task shape and integration point

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Admin.Lifecycle` already exists as the right projection seam for computed operator guidance.
- `Rulestead.Admin.StaleTracker` and `Rulestead.Telemetry.Cache` already provide bounded evaluation-evidence inputs that Phase 36 can interpret without changing runtime semantics.
- `Rulestead.CodeRefs.CodeReference` and the existing code-ref ingest path already establish the passive “host scans its own code” model.
- The mounted-admin inventory, detail, and cleanup screens already separate read surfaces from explicit destructive actions.
- Existing Mix tasks already establish the repo’s expected command style for parsing, output, and mutation boundaries.

### Established Patterns
- The repo consistently prefers persisted authored facts plus derived read models over persisted machine projections.
- Mounted-admin filters live in URL params for shareable operator state; Phase 36 should preserve that habit in both UI and CLI naming.
- Audit-safe, preview-first operator posture is already a product principle and must not be bypassed by lifecycle guidance.
- Host-owned seams and explicit uncertainty are preferred over hidden automation or overconfident heuristics.

### Integration Points
- Archive-readiness composition should plug into the existing admin projection path rather than create a second recommendation engine in LiveView.
- The list/detail/cleanup screens should consume the same derived guidance payload as the future CLI report task.
- New report commands should follow the same public task conventions used by existing `mix rulestead.*` tasks.

</code_context>

<deferred>
## Deferred Ideas

- Explicit archive/cleanup preview, confirmation, reason capture, and audit continuity flows — Phase 37
- Lifecycle workbench ranking, bulk actions, and mutation orchestration beyond read-only review — Phase 37
- Any automatic archival, automatic code removal, or hidden state mutation based on heuristics
- Persisted readiness scores, background recompute pipelines, or SQL-native advisory materialization
- Rich SaaS-style lifecycle stage systems that exceed Rulestead’s mounted sibling-package scope

</deferred>

---

*Phase: 36-archive-readiness-signals-cleanup-analysis*
*Context gathered: 2026-05-23*

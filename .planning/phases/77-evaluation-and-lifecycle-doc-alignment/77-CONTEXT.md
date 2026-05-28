# Phase 77: Evaluation And Lifecycle Doc Alignment - Context

**Gathered:** 2026-05-28 (assumptions mode — Phase 76 deferrals + ROADMAP)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close **INV-INTRO-01 narrative** for evaluation and lifecycle docs — **docs only**, no `lib/`, release-contract guards, or verify task changes (Phase 78).

**In scope:** DOC-01, DOC-02, DOC-03.

**Out of scope:** `guides/introduction/phoenix-integration-spine.md` authoring (Phase 76 shipped); `release_contract_test` / `mix verify.phase76` (Phase 78); admin UI; runtime code changes.

</domain>

<decisions>
## Implementation Decisions

### evaluation.md Runtime APIs (DOC-01)
- **D-01:** Expand **"Pure Evaluation Versus Runtime Lookup"** in `guides/flows/evaluation.md` with a dedicated **Runtime keyed lookup** subsection naming `Rulestead.Runtime.evaluate/3`, `enabled?/3`, `get_value/4`, `get_variant/3`, `explain/3` — signature shape `(environment_key, flag_key, context)`.
- **D-02:** Include at least one full `Rulestead.Runtime.enabled?/3` example using `Rulestead.Context.new/1` (not Plug.conn as second arg).
- **D-03:** Keep **payload-first** `Rulestead.evaluate/3` as the canonical contract in "Core Calls" and opening paragraphs — Runtime is additive for snapshot-cache apps.
- **D-04:** Cross-link footguns table and phoenix-integration-spine; do not duplicate spine's full Plug walkthrough.

### Intro lifecycle callouts (DOC-02)
- **D-05:** Add a visible **lifecycle-required fields** callout in `getting-started.md` — owner_ref + expected_expiration required at flag create; link `../flows/flag-lifecycle.md`.
- **D-06:** Add matching callout in `installation.md` (post-install / what-happens-next area) — not only the spine link from Phase 76.
- **D-07:** Use `owner_ref` and `expected_expiration` field names (aligned with spine §6 and store commands).

### rulestead/README.md API ordering (DOC-03)
- **D-08:** Reorder **Runtime entrypoints** to match footguns: **Runtime keyed lookup first** (Phoenix snapshot path), then **payload-first** root module helpers.
- **D-09:** List `Rulestead.Runtime.enabled?/3`, `get_variant/3`, `evaluate/3`, `explain/3` (and `get_value/4` if space) with one-line arity note `(environment_key, flag_key, context)`.
- **D-10:** Preserve existing milestone contract sections below entrypoints — minimal diff.

### Execution shape
- **D-11:** Single plan **77-01** unless checker demands split (all three DOC reqs are grep-verifiable doc edits).

### Claude's Discretion
- Exact callout formatting (blockquote vs `> **Note:**` vs `###` subsection)
- Whether evaluation.md adds a small comparison table mirroring footguns or prose only
- README: whether to add a one-line link to phoenix-integration-spine

</decisions>

<canonical_refs>
## Canonical References

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 77 goal and success criteria
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, DOC-03
- `.planning/phases/76-phoenix-integration-spine-doc/76-CONTEXT.md` — deferrals into this phase
- `.planning/phases/76-phoenix-integration-spine-doc/76-01-SUMMARY.md` — spine delivered

### Docs to edit
- `guides/flows/evaluation.md`
- `guides/introduction/getting-started.md`
- `guides/introduction/installation.md`
- `rulestead/README.md`

### Alignment sources
- `guides/recipes/footguns.md` — payload-first vs Runtime table
- `guides/introduction/phoenix-integration-spine.md` — spine Runtime + lifecycle §§5–6
- `rulestead/lib/rulestead/runtime.ex` — public Runtime arities
- `guides/flows/flag-lifecycle.md` — birth / required fields

</canonical_refs>

<deferred>
## Deferred Ideas

- Release-contract guards for spine + lifecycle callouts — Phase 78 (VER-01)
- `mix verify.phase76` — Phase 78 (VER-02)

</deferred>

---

*Phase: 77-evaluation-and-lifecycle-doc-alignment*
*Context gathered: 2026-05-28*

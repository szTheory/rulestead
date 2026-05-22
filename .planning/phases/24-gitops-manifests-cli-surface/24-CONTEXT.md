# Phase 24: GitOps Manifests & CLI Surface - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning
**Research mode:** discuss-all with delegated advisor research across manifest shape, Mix-task UX, output contract, and import/promote safety posture

<domain>
## Phase Boundary

Ship deterministic manifest export, validation, diffing, import, and promotion automation surfaces that teams can use from local workflows and CI without changing Rulestead's mounted-admin-first product shape.

**In scope:**
- deterministic authored-state manifest export for one environment at a time
- offline or CI-friendly validate and diff commands
- dry-run / preview-first import and promote task flows
- human-readable and machine-readable CLI output from one canonical domain model
- CLI reuse of the Phase 22 compare contract and Phase 23 apply/governance contract

**Out of scope (explicitly deferred):**
- Git as the primary authoring surface
- bidirectional reconciliation or continuous sync
- destructive prune semantics
- archive/revive lifecycle mutations through import/promote
- partial-rule or cherry-pick promotion UX
- standalone `rulestead_admin` release-orchestration product shape

</domain>

<decisions>
## Implementation Decisions

### Recommendation-First Posture
- **D-01:** Downstream research, planning, and execution for this phase should default to **recommendation-first** decisions rather than reopening routine tradeoffs. Re-ask only when a choice would materially change public contract, security posture, product scope, or release shape.
- **D-02:** The coherent system matters more than local optimization. Manifest shape, CLI task family, output contract, and safety posture must be designed together and should not pull in opposite directions.

### Manifest Shape and File Boundary
- **D-03:** Phase 24 ships a **single canonical JSON manifest per environment export**. Do not make YAML the canonical format in this phase.
- **D-04:** The exported file boundary is **one environment bundle per file**, not one file per flag and not one multi-environment mega-document.
- **D-05:** The manifest captures **published authored desired state only** for the selected environment:
  - top-level schema/version and manifest kind
  - `environment_key`
  - one semantic entry per `flag_key`
  - global authored flag metadata that is semantic and reviewable
  - the selected environment's authored overlay
  - the active published ruleset only
  - stable dependency references by semantic key such as `audience_key`
- **D-06:** The manifest must exclude:
  - database IDs / UUIDs
  - inserted / updated timestamps
  - runtime snapshots and cache or invalidation metadata
  - audit events, change requests, approval state, and scheduled execution state
  - kill-switch / operational override state
  - unpublished drafts
  - persisted compare tokens or fingerprints in the authored export itself
- **D-07:** The manifest is a deterministic authored-state automation artifact, **not** a full disaster-recovery dump of every runtime or governance concern.

### CLI Task Family and Invocation Style
- **D-08:** Phase 24 ships **five separate Mix tasks**:
  - `mix rulestead.export`
  - `mix rulestead.validate`
  - `mix rulestead.diff`
  - `mix rulestead.import`
  - `mix rulestead.promote`
- **D-09:** Do **not** introduce a bespoke `mix rulestead ...` subcommand shell. Separate tasks are more idiomatic for Mix, clearer in `mix help`, and more consistent with the repo's current task style.
- **D-10:** `import` and `promote` use a **saved plan/apply workflow**:
  - preview or plan first
  - mutate only with explicit `--apply`
  - `--apply` consumes a previously generated plan artifact, not raw live inputs
- **D-11:** File and stream ergonomics should be Unix-friendly:
  - `-` means stdin or stdout where a file path is accepted
  - default text output for humans
  - explicit machine mode via `--format json`
- **D-12:** The task family should support explicit environment and scope flags rather than hidden defaults. Target environment must never be implicit for mutating commands.
- **D-13:** Require an explicit operator reason for real mutation paths (`--reason` on apply).

### Output and Exit-Code Contract
- **D-14:** All Phase 24 tasks render from **one canonical result envelope**. Human-readable text is a renderer over the same semantic payload used for JSON output, not a second ad hoc contract.
- **D-15:** Default human output is deterministic, line-oriented, and summary-first:
  - stable section order
  - stable sorting by flag key and finding severity/code
  - top-level status first
  - findings before deep detail
- **D-16:** `--format json` must print **only JSON to stdout**. Do not mix banners, prose, or warnings into machine-readable stdout.
- **D-17:** Lock a small, explicit status vocabulary for JSON output:
  - `ok`
  - `no_changes`
  - `changes`
  - `governance_required`
  - `invalid`
  - `blocked`
  - `stale`
  - `applied`
  - `queued`
  - `error`
- **D-18:** Use the following exit-code policy consistently:
  - `0` — successful and clean
  - `1` — CLI usage, file I/O, JSON encoding, or unexpected internal/system failure
  - `2` — successful domain result with changes present and no blocker preventing preview
  - `3` — successful command execution but domain state is invalid, blocked, stale, or otherwise not applyable
- **D-19:** Command-specific expectations:
  - `export` returns `0` on successful write
  - `validate` returns `0` when valid and `3` on schema/dependency invalidity
  - `diff` returns `0` for no diff, `2` for applyable diff, and `3` for blocked/invalid comparison basis
  - `import --plan` and `promote --plan` return `0` for no-op, `2` for applyable changes, and `3` for blocked/invalid/stale previews
  - `import --apply` and `promote --apply` return `0` for applied/no-op/queued governed result and `3` for stale/blocked/invalid domain rejection
- **D-20:** Stale preview is a **domain rejection**, not a system crash. It should map to `3`, not `1`.

### Import and Promote Safety Posture
- **D-21:** Phase 24 import and CLI promote use a **strict additive-only plan/apply posture**.
- **D-22:** Omission from source manifest or source environment means **not managed by this apply**, not delete/archive/prune.
- **D-23:** Mutation requires a fresh reviewed preview artifact contract:
  - promote reuses the Phase 23 compare token, source fingerprint, target fingerprint, and dependency closure keys
  - import mints an equivalent scoped preview contract from the manifest and target authored fingerprint
- **D-24:** Protected targets never mutate through a CLI side door. CLI apply must reuse the existing governed action path where protection requires it.
- **D-25:** No destructive prune, archive, revive, or force mode ships in Phase 24.
- **D-26:** Apply must **block** on:
  - stale preview/import token
  - source or target fingerprint mismatch
  - dependency closure drift or missing dependencies
  - archived dependency references
  - archive/revive lifecycle transitions through import/promote
  - direct protected-target mutation when governance is required
- **D-27:** Preview should **warn** on:
  - protected target posture
  - active operational override / kill-switch mismatch
  - unpublished drafts in the source side
  - missing target row that a valid apply can create
- **D-28:** Preview should **report only**:
  - target-only authored state absent from source/manifests
  - non-blocking authored drift
  - preview age badge when fingerprint contract is still fresh

### Idiomatic Ecosystem Fit
- **D-29:** Phase 24 should feel like an Elixir library with a mounted operator UI, not a standalone control plane awkwardly embedded in Phoenix.
- **D-30:** The mounted admin remains the visual review console and source of operator clarity; Mix tasks are the deterministic automation surface for local use and CI.
- **D-31:** Reuse the existing compare/apply/governance domain model instead of inventing a CLI-only workflow model. The admin UI and CLI should speak the same language: source, current target, proposed target, findings, tokens, fingerprints, and dependency closure.

### the agent's Discretion
- Exact manifest field names beyond the locked semantics above, provided they stay stable, semantic, and JSON-first
- Exact task flag names where the intent is already locked (for example `--out` vs `--output`), provided the family stays consistent
- Exact text rendering layout, provided it remains deterministic, findings-first, and CI-friendly
- Exact plan artifact file naming, provided plan/apply stays explicit and reproducible

</decisions>

<specifics>
## Specific Ideas

- Treat `mix rulestead.promote --plan` like the promotion analogue of `terraform plan -detailed-exitcode`: explicit preview, stable machine contract, and clear stale/apply semantics.
- Prefer one environment bundle such as `rulestead.staging.json` over either giant multi-env documents or per-flag file trees.
- Keep the CLI boring in the good way: explicit task names, explicit scope, explicit `--apply`, explicit reasons, explicit JSON mode.
- Preserve the repo's calm operator posture: preview first, mutation second, audit/governance intact, no hidden reconciliation magic.
- Move GSD toward recommendation-heavy downstream work by default, with user confirmation reserved for genuinely high-impact choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` — Phase 24 goal, success criteria, and plan slices
- `.planning/REQUIREMENTS.md` — source of truth for `MAN-01` through `MAN-04`
- `.planning/PROJECT.md` — linked-version product shape, mounted-admin posture, and `v0.6.0` milestone goals
- `.planning/STATE.md` — active milestone focus and current phase boundary

### Prior locked decisions
- `.planning/phases/22-environment-compare-conflict-model/22-CONTEXT.md` — authored-state compare boundary, compare token semantics, finding taxonomy, and shared result-shape expectations
- `.planning/phases/23-governed-promotion-apply/23-CONTEXT.md` — saved promotion bundle expectations, protected-target governance reuse, immutable environment versions, and stale revalidation posture
- `.planning/phases/06-admin-ui-flag-list-detail-rule-editor-environments-lifecycle/06-CONTEXT.md` — explicit environment scoping and mounted admin route-backed posture
- `.planning/phases/07-admin-ui-simulation-rollouts-kill-switch-audit-security-redaction/07-CONTEXT.md` — audit-first mutations, operational override semantics, and calm operator UX posture
- `.planning/phases/10-scheduled-changes-and-durable-execution/10-CONTEXT.md` — stale-intent rejection posture and explicit schedule truth model
- `.planning/phases/11-mounted-admin-governance-and-schedule-ui/11-CONTEXT.md` — approval/execution separation and governed review surface expectations

### Milestone-level research anchors
- `.planning/research/V0_6_PRODUCT_SHAPE.md` — recommendation to keep GitOps as an import/export seam rather than primary authoring
- `.planning/research/V0_6_RECOMMENDATIONS.md` — cohesive milestone-level recommendation set for compare/apply, manifests, and safety defaults
- `.planning/research/V0_6_DX.md` — Elixir/Phoenix/Mix ergonomics guidance for mounted admin plus CLI automation
- `prompts/elixir_feature_flags_research_brief.md` — ecosystem lessons from LaunchDarkly, Unleash, GrowthBook, Flagsmith, and adjacent systems
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — scripts-first automation, OSS ergonomics, and explicit seam guidance
- `prompts/rulestead-release-engineering-and-ci.md` — CI readability, deterministic artifacts, and scripts-first release posture
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary for manifest, snapshot, environment, import, export, diff, and promote
- `prompts/rulestead-host-app-integration-seam.md` — host-owned integration constraints and Mix-task posture
- `prompts/rulestead-testing-and-e2e-strategy.md` — testability and release-gate expectations for CLI/task surfaces
- `prompts/rulestead-security-privacy-and-threat-model.md` — fail-closed admin posture, environment-sensitive governance, and least-surprise safety defaults
- `prompts/rulestead-admin-ux-and-operator-ia.md` — preview/confirm/audit spine and mounted operator IA

### Existing code and contracts
- `rulestead/lib/rulestead/promotion/compare.ex` — compare tokens, fingerprints, finding taxonomy, and canonical compare payload
- `rulestead/lib/rulestead/promotion/apply.ex` — stale preview revalidation and apply-time guardrails
- `rulestead/lib/rulestead/store/command.ex` — key-first compare/apply command contracts and future task input shape
- `rulestead/lib/rulestead/store/ecto.ex` — apply persistence path, governance reuse, and target mutation rules
- `rulestead/lib/rulestead/fake.ex` — adapter parity expectations for compare/apply and future CLI contract tests
- `rulestead/lib/rulestead.ex` — public compare/apply facade shaping the library-level automation surface
- `rulestead/lib/mix/tasks/rulestead.install.ex` — existing Mix-task style and user-facing task ergonomics
- `rulestead/lib/mix/tasks/rulestead.redis.sync.ex` — existing Mix-task style for operational automation
- `rulestead/test/rulestead/promotion/compare_test.exs` — canonical compare payload expectations
- `rulestead/test/rulestead/store/compare_contract_test.exs` — compare parity, blockers, and stale token semantics
- `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` — apply contract, immutable environment versions, and protected-target rejection
- `rulestead/test/rulestead/release_contract_test.exs` — public surface discipline and release-contract mindset

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Rulestead.Promotion.Compare` already defines the canonical semantic payload that Phase 24 should render and serialize rather than re-deriving a second diff model.
- `Rulestead.Promotion.Apply` and `Command.ApplyPromotion` already enforce the right stale-preview and fingerprint discipline for explicit apply.
- Existing Mix tasks provide the right implementation pattern: thin task wrappers over domain modules with simple `OptionParser` handling and deterministic shell output.
- The fake and Ecto adapters already test parity around compare/apply contracts, making them the right base for future manifest and CLI contract tests.

### Established Patterns
- The repo prefers explicit route-backed or task-backed workflows over hidden state and bespoke workflow engines.
- The repo already separates authored desired state from runtime artifacts and operational overlays; Phase 24 manifests must preserve that split.
- Governance and audit are first-class constraints, not optional wrappers to bypass in CI.
- The project prefers recommendation-heavy downstream work when the product-shape decision is already clear.

### Integration Points
- `mix rulestead.diff` should render from the same compare/finding taxonomy already used in Phase 22.
- `mix rulestead.promote` should reuse the same promotion bundle and governed apply path shipped in Phase 23.
- `mix rulestead.import` should mint a manifest-scoped preview/apply contract that feels parallel to promote, not like a separate product.
- Future docs, admin affordances, and tests should all point at one canonical JSON/result envelope rather than divergent human and machine contracts.

</code_context>

<deferred>
## Deferred Ideas

- YAML as a first-class authored manifest format
- Multi-environment mega-documents or per-flag file-tree manifests
- Bidirectional reconciliation or continuous sync
- Destructive prune mode
- Archive/revive lifecycle mutations via import/promote
- `mix rulestead ...` bespoke umbrella subcommand shell
- Partial-rule or cherry-pick promotion UX

</deferred>

---

*Phase: 24-gitops-manifests-cli-surface*
*Context gathered: 2026-05-19*

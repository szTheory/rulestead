# Phase 57: Blast-Radius Threshold Contract - Context

**Gathered:** 2026-05-27 (assumptions mode + research synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Core classifies audience-mutation **blast radius** in **protected environments** using v1.6 **preview fingerprints** and **dependency truth** payloads only. It returns deterministic threshold verdicts and blocks above-threshold **direct apply** with actionable breach evidence.

**In scope:** Pure threshold evaluator, Fake+Ecto parity, fail-closed on stale/missing/unresolved inputs, operator-facing assessment payload suitable for Phase 58 change-request embedding.

**Out of scope:** Change-request proposal/execute (Phase 58), mounted admin routing/copy (Phase 59), docs/release-contract (Phase 60), observability-backed population counts, per-tenant threshold profiles (GOV-02-ext), new `Rulestead.Error` leaf types unless planning proves necessary.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Evaluation mechanism and module home
- **D-01:** Add `Rulestead.Governance.BlastRadiusThreshold` as a **pure module** (no behaviour, no GenServer, no store callback). Public API: `assess/2` → `{:ok, assessment()}` or `{:error, Rulestead.Error.t()}`; `validate_protected_apply/3` wraps assess + apply gate for stores.
- Measurement inputs stay in existing `Rulestead.Targeting.*` (`ImpactPreview`, `AudienceDependencies`, `DependencyValidator`, `DependencyInventory`). Governance owns **verdict + breach reasons**, not reference graph computation.
- **Rationale:** Matches `DependencyValidator`, `Guardrails.Decision`, `Promotion.Apply.validate` — deterministic, IEx-testable, zero I/O. Industry (Terraform plan policy, Ecto.Changeset) separates pure policy from persistence; LD/Unleash put approval in control plane, not eval hot path.
- **Anti-patterns avoided:** GenServer threshold state (violates runtime purity); duplicating logic in Fake vs Ecto (Phase 57 success criterion #4).

### D-02 — Protected-environment detection
- **D-02:** Threshold **apply gate** runs only when `Rulestead.Promotion.Compare.protected_target?(environment_key)` is true (`prod` / `production` — same keys as `Rulestead.Admin.Authorizer` production defaults).
- **Replace** the placeholder `ensure_protected_audience_confirmation/1` boolean gate as the sole protected-env signal. Retain `protected_shared_targeting?` on `ApplyAudienceMutation` as an **input amplifier** (feeds assessment metadata / breach reasons) but **never** as the only trigger — admin does not set it today.
- **Non-protected environments:** Still run preview + dependency validation as today; threshold assess may run for telemetry/audit but **must not block** direct apply.
- **Rationale:** GOV-01/03 are environment-scoped; v1.6 gap was prod edits slipping through without caller setting the boolean. Unleash/LD footgun: env-scoped CR with global segment objects — Rulestead audiences are env/tenant scoped via command envelope.

### D-03 — Scoring model (locked defaults)
- **D-03:** **Reference count is the sole breach dimension** for v1.7.0. Rollout and lifecycle contexts are **evidence hints** in the assessment payload, not score weights (defers GOV-02-ext weighting debate; aligns with authored-state-only GOV-02 and `ImpactPreview.uncertainty`).
- **Metrics (from preview + dependency entries):**
  - `reference_count` — `length(affected_references)` / `AudienceDependencies.reference_keys/1`
  - `distinct_flag_count` — deduped `flag_key` from references (reporting only, not a separate threshold in v1.7)
  - `rollout_hints` / `lifecycle_hints` — summarized from `rollout_context` / `lifecycle_context` per reference
- **Default profile** (`@default_profile`, overridable via `assess/2` opts for tests only — not `Rulestead.Config` yet):

  | Condition (protected env) | Verdict |
  |---------------------------|---------|
  | Any indeterminate input (see D-04) | `:indeterminate` → fail-closed |
  | `operation == "archive"` and `reference_count > 0` | `:above_threshold` |
  | `operation == "update"` and `reference_count > 2` | `:above_threshold` |
  | Otherwise | `:below_threshold` |

- **Below threshold:** Direct apply allowed when existing v1.6 gates pass (fresh `preview_fingerprint`, schema version, reason, dependency validator clear).
- **Above threshold:** Direct apply denied with structured breach evidence; remediation points to change request (implemented Phase 58).
- **Rationale:** Commercial FF products rarely compute unified blast scores — they use env protection + human review. Terraform/IaC uses explicit counts + breach reasons — closest analog for self-hosted OSS. Weighting unavailable rollout metadata caused false blocks in spike reasoning; hints preserve operator context without gaming risk.
- **Industry footguns avoided:** Observability-backed “&lt;5% auto-approve” (ConfigCat/Zapier); implying affected-user counts (GOV-02); zero blast radius when data missing.

### D-04 — Fail-closed / indeterminate inputs
- **D-04:** Verdict `:indeterminate` (treated as apply-blocked in protected env) when **any** of:
  - Missing or blank `preview_fingerprint` / wrong `preview_schema_version`
  - Stale fingerprint vs freshly recomputed preview (existing `ensure_fresh_audience_preview/2` — threshold path must not bypass)
  - `command.affected_reference_keys` mismatch vs preview keys (when references expected)
  - `DependencyValidator.blockers?/1` on dependency entries derived from preview
  - Any affected reference with `rollout_context.available? == false` or `lifecycle_context.available? == false` (unresolved authored hints)
  - `hidden_reference_count > 0` without policy visibility to resolve hidden refs
  - Protected-environment policy ambiguous (unknown env key classification → treat as protected per security brief fail-closed)
- **Never** default to `:below_threshold` when assessment cannot be computed.
- **Rationale:** GOV-04, support-truth gate (“no zero-blast-radius assumption”), threat model fail-closed on security paths. Flagsmith post-approval edit drift and Terraform stale-plan-at-apply are the counterexamples to avoid.

### D-05 — Error and evidence shape
- **D-05:** Reuse `StoreError.invalid_command/2` → `%Rulestead.Error{type: :invalid_command}` — **no new public `:type` atom** in Phase 57 unless `api_stability.md` update is explicitly planned.
- Emit **findings** in the same shape as `ImpactPreview.finding/4` / `DependencyValidator` (`severity`, `class`, `code`, `metadata`).
- Stable finding codes (minimum set):
  - `blast_radius_above_threshold`
  - `blast_radius_indeterminate`
  - `blast_radius_missing_preview_inputs` (subset of indeterminate)
  - `blast_radius_unresolved_dependency_truth`
- `metadata` on error must include: `verdict`, `reference_count`, `threshold_profile`, `operation`, `environment_key`, `preview_fingerprint`, `breach_reasons` (list of maps with `code`, `observed`, `limit`, `remediation`).
- Audit on blocked apply: include assessment summary in event metadata (mirror existing `dependency_findings` pattern in `fake.ex` apply audit).
- **Rationale:** Pattern-match by struct + `type`, never message string (engineering DNA #9). Optimizely/Terraform teach named rules with observed vs limit; Split’s opaque 403 is the anti-pattern.

### D-06 — Store integration and parity
- **D-06:** Call `BlastRadiusThreshold.validate_protected_apply/3` from **both** `Fake` and `Ecto` `do_apply_audience_mutation` **after** `ensure_fresh_audience_preview/2` and **before** dependency apply validation / persistence.
- Also invoke from `Rulestead.apply_audience_mutation/1` facade when protected so custom store adapters inherit the contract.
- Extend `audience_impact_contract_test.exs` and `ecto_audience_impact_contract_test.exs` with threshold cases: below (≤2 refs update), above (>2 refs), archive with refs, indeterminate (unavailable rollout context), non-protected bypass.
- **Rationale:** Same pattern as `Apply.validate_live_dependencies/3` dual-path parity.

### D-07 — Phase boundary vs change requests
- **D-07:** Phase 57 **does not** add `:apply_audience_mutation` to `ChangeRequest.governed_actions/0`. Phase 57 only produces `assessment` maps that Phase 58 embeds in change-request metadata.
- Replace generic `"protected shared targeting mutation requires confirmation"` with threshold breach findings + remediation `"Submit a change request after Phase 58"` (wording may say "governed approval required" without implementing CR submit).
- **Rationale:** ROADMAP splits 57/58; reuse existing CR envelope in 58 — no parallel workflow (MILESTONE-ARC guardrail, Unleash enterprise-only parallel path anti-pattern).

### D-08 — Configuration posture
- **D-08:** Ship **module defaults + keyword opts** on `assess/2` (`threshold_profile:`, `protected_environment?:`). **Do not** add NimbleOptions entries to `Rulestead.Config` in Phase 57 (GOV-02-ext deferred).
- Document defaults in `@moduledoc` and Phase 60 docs; host override seam is opts now, formal config schema later.
- **Rationale:** `Rulestead.Config` is for integration seams, not business policy (engineering DNA); premature `Application.get_env` creates untyped drift across adopters.

### D-09 — Operator copy principles (for error/findings strings)
- **D-09:** Breach messages must be **calm, actionable, 3am-safe** (admin UX brief): lead with **observed vs limit**, restate preview basis limits (`authoritative_population_count?: false`), never imply live user counts.
- Remediation strings:
  - Above threshold → "This audience change affects more than the direct-apply limit for protected environments. Submit a change request for governed approval."
  - Indeterminate → "Blast radius cannot be evaluated safely. Re-run preview after resolving dependency visibility, or cancel the change."
  - Stale preview → keep existing copy; threshold must not override stale gate.
- **Rationale:** GrowthBook simulation/explain investment; Rulestead admin already uses "Review authored blast radius before confirming" (`edit_preview.ex`).

### Claude's Discretion
- Exact `assessment` map field names and whether to expose `Rulestead.assess_audience_blast_radius/2` at top-level vs store-only (planner: prefer public read API for admin Phase 59).
- Whether to add thin `Rulestead.Governance.ProtectedEnvironment` delegating to `Compare.protected_target?/1` for vocabulary alignment.
- Finding `class` atoms (`:governance`, `:preview`, `:dependency`) and audit event type string for threshold-blocked applies.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 57 goal, success criteria, dependency on Phase 56
- `.planning/REQUIREMENTS.md` — GOV-01 through GOV-04, proof posture gate, support-truth gate, out-of-scope table
- `.planning/MILESTONE-ARC.md` — v1.7.0 guardrails (reuse CR envelope, authored-state thresholds, no dashboards)
- `.planning/milestones/v1.6.0-REQUIREMENTS.md` — IMP/DEP shipped contracts; GOV-01 deferred note
- `.planning/threads/2026-05-27-next-milestone-assessment.md` — GOV-01 gap analysis, threshold semantics investigation (resolved by D-03)

### Product and engineering anchors
- `prompts/elixir_feature_flags_research_brief.md` §4.1, §4.7 — env-sensitive governance, approvals not luxury; runtime vs control-plane separation §2
- `prompts/rulestead-engineering-dna-from-prior-libs.md` — Error struct, Fake adapter parity, pure evaluator, scripts-first proof
- `prompts/rulestead-domain-language-field-guide.md` — Change request, audit event, environment, audience vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — Fail closed, high blast radius of flags, no self-approval defaults
- `prompts/rulestead-admin-ux-and-operator-ia.md` — Preview → confirm → audit, calm 3am copy, no autopilot
- `prompts/rulestead-telemetry-observability-and-audit.md` — No PII in telemetry/audit meta
- `prompts/rulestead-host-app-integration-seam.md` — Explicit over magic, fail loud

### Code precedents (read before editing)
- `rulestead/lib/rulestead/targeting/impact_preview.ex` — `audprev_` fingerprint, uncertainty, affected_references
- `rulestead/lib/rulestead/targeting/audience_dependencies.ex` — reference graph, `available?: false` contexts
- `rulestead/lib/rulestead/targeting/dependency_validator.ex` — findings → `to_error/2` pattern
- `rulestead/lib/rulestead/promotion/compare.ex` — `protected_target?/1`
- `rulestead/lib/rulestead/governance/change_request.ex` — governed_actions list (unchanged in 57)
- `rulestead/lib/rulestead/fake.ex` — `do_apply_audience_mutation/2` pipeline
- `rulestead/lib/rulestead/store/ecto.ex` — Ecto parity path
- `rulestead/test/rulestead/store/audience_impact_contract_test.exs` — contract test pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImpactPreview.build/1` + `preview_fingerprint/1` — frozen evidence contract for assess inputs
- `AudienceDependencies.summarize/2` + `reference_keys/1` — reference counting
- `DependencyValidator.validate/2`, `blockers?/1`, `to_error/2` — fail-closed dependency gate pattern
- `Compare.protected_target?/1` — protected env detection (align with `Admin.Authorizer` prod keys)
- `Command.ApplyAudienceMutation` — preview fields already on command struct
- Contract tests: `audience_impact_contract_test.exs`, `ecto_audience_impact_contract_test.exs`

### Established Patterns
- Apply pipeline: schema → fresh preview → (NEW: threshold) → dependency validation → mutate → audit
- Errors: `:invalid_command` + findings in `details`/`cause`, stable codes in metadata
- Policy defaults in-module with keyword overrides (`Admin.Lifecycle`, `Compare`)

### Integration Points
- `Rulestead.apply_audience_mutation/1` facade — central place for cross-store policy
- Fake `handle_call` and Ecto transaction apply — must call same pure assess
- Phase 58: `assessment` map → change request `metadata` / command embedding
- Phase 59: admin renders `breach_reasons` + remediation (no new screens in 57)

</code_context>

<specifics>
## Specific Ideas

- Position Rulestead v1.7 as **"Terraform plan policy + GitHub CODEOWNERS for shared audiences"** — evidence-bound, self-hosted, not LaunchDarkly approval SaaS.
- Default **2-reference** direct-apply cap in prod balances v1.6 test fixtures (often 1 ref) with meaningful governance; archive with any live references always governed.
- Assessment payload should be stable enough to print in IEx and embed in CR without re-computation at submit time (Phase 58 re-validates fingerprint at execute).

</specifics>

<deferred>
## Deferred Ideas

- Per-tenant/environment threshold profiles (GOV-02-ext) — v2
- Observability-backed population or impression-weighted thresholds (IMP-05, out-of-scope table)
- New `Rulestead.Error` type `:blast_radius_exceeded` — only if pattern-matching demand exceeds `:invalid_command` + codes
- Mounted proposal UX and change-request submit button (Phases 58–59)
- Auto-approve below X% traffic (requires metrics Rulestead does not own)

</deferred>

---

*Phase: 57-blast-radius-threshold-contract*
*Context gathered: 2026-05-27*

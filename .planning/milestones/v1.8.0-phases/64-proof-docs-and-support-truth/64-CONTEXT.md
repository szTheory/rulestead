# Phase 64: Proof, Docs, And Support Truth - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.8 guarded rollout auto-advance with repo-local proof, bounded public docs, host seam guidance, and release-contract drift guards — without widening the linked sibling-package release model or changing core/admin contracts from Phases 61–63.

**In scope:** `mix verify.phase64` merge gate, `release_contract_test.exs` auto-advance support-truth block, README/MAINTAINING/package README updates, host-app integration seam auto-advance subsection, in-place flow guide updates, optional CI scope `guarded_rollout_auto_advance`, phase verification artifact.

**Out of scope:** Core policy/orchestration contract changes (Phases 61–62), mounted UX changes (Phase 63), new Phase 8-only docs (`api_stability.md`, etc.), standalone admin publish prep, observability product widening, fleet dashboards, time-based percentage rollout, metrics ingestion pipelines.

</domain>

<decisions>
## Implementation Decisions

### D-01 — Merge gate composition (`mix verify.phase64`)
- **D-01:** Add `Mix.Tasks.Verify.Phase64` as the v1.8 merge gate using an **explicit flat test union** — all `@phase60_core_tests` from `verify.phase60.ex` plus v1.8 auto-advance delta paths. Do **not** call `verify.phase60` or other sub-tasks (same anti-duplication pattern as `verify.phase60.ex`).
- **Core delta (VER-01 scenarios):**
  - `test/rulestead/rollout_auto_advance_contract_test.exs` — policy persistence + eligibility
  - `test/rulestead/rollout_auto_advance_orchestration_contract_test.exs` — healthy advance, blocked tick, protected-env CR, idempotency, manual-advance race
  - `test/rulestead/guardrails/auto_advance_test.exs` — pure fail-closed evaluator
  - `test/rulestead/guarded_rollout_test.exs` — ROL-07 hold/rollback preserved with auto-advance enabled
  - `test/rulestead/scheduled_execution_conflict_test.exs` — idempotency/conflict races
- **Admin delta:**
  - `test/rulestead_admin/live/flag_live/rollouts_test.exs`
  - `test/rulestead_admin/live/flag_live/timeline_test.exs`
- Register `verify.phase64` in `rulestead/mix.exs` `preferred_envs` alongside phase54–60.
- **Rationale:** VER-01 requires healthy auto-advance, fail-closed non-advance, protected-env governance parity, idempotency races, and stale-signal behavior in one maintainer command; `verify.phase60` alone does not cover v1.8 auto-advance tests.

### D-02 — Release contract & support truth (VER-02/03)
- **D-02:** Extend `release_contract_test.exs` with a **"guarded rollout auto-advance support truth stays bounded"** test block mirroring the v1.7 blast-radius block (~L410).
- Assert across root `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, and `MAINTAINING.md`:
  - `mix verify.phase64` present
  - Bounded vocabulary: opt-in auto-advance, observation window, authored next-stage plan, `guardrail_automation`, fail closed, host-owned metrics/signals
  - Package boundary: core owns policy + orchestration; admin owns mounted presentation; not standalone admin
  - `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh` in maintainer docs
- **Forbidden phrase updates:**
  - Remove blanket `"auto-advance"` from the v1.5 guarded-rollout block (currently ~L328) — feature is now shipped with bounded claims
  - Remove `"auto-advance guarded rollouts"` from the blast-radius block (currently ~L460) — v1.8 delivers ROL-04
  - Retain forbidding: built-in observability, fleet dashboards, self-healing rollouts, time-based percentage rollout, metrics ingestion, standalone admin, automatic progressive delivery platform
- Root README **"Proof today"** adds v1.8 auto-advance entry **alongside** `verify.phase60` and `verify.phase56` (do not remove prior entries).

### D-03 — Host seam + in-place flow docs (VER-02)
- **D-03:** Add a bounded **auto-advance subsection** to `prompts/rulestead-host-app-integration-seam.md` (after Oban/workers ~§7): host-owned `Guardrails.fetch_signal/2` provider seam, observation-window semantics, protected-env change-request routing at tick execute, no Rulestead-owned metrics dashboards.
- **In-place guide updates only** — no new top-level flow doc unless planning discovers an unavoidable gap:
  - `guides/flows/admin-ui.md` — auto-advance panel on rollouts page, pending observation state, automation vs manual timeline labels, protected-env CR callout
  - `guides/flows/rollout.md` — observation window + authored next-stage plan semantics; fail-closed on weak/stale signals
- Teach that metrics and signal facts remain host-owned; Rulestead evaluates normalized facts only.

### D-04 — CI scope, maintainer docs, and handoff (VER-03)
- **D-04:** Add `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance` to `scripts/ci/test.sh`:
  - New `run_guarded_rollout_auto_advance/0` function calling `mix verify.phase64`
  - Failure guidance function mirroring `print_blast_radius_governance_failure_guidance/0`
  - Update supported-scopes error message
- Add **"Guarded Rollout Auto-Advance Proof"** section to `MAINTAINING.md` describing bounded proof scope, rerun commands, and explicit non-claims (no metrics pipelines, no fleet dashboards, no time-based percentage rollout).
- Reference upstream phase artifacts: `.planning/phases/61-auto-advance-authored-contract/`, `62-orchestration-and-governed-execution/`, `63-mounted-auto-advance-workflows/` (CONTEXT + VERIFICATION files).
- Produce `64-VERIFICATION.md` in phase dir; optional `64-HANDOFF-CHECKLIST.md` for maintainer release checklist.

### D-05 — Four-plan execution shape
- **D-05:** Mirror Phase 60 capstone structure:
  - **64-01** — `mix verify.phase64` merge gate (VER-01)
  - **64-02** — `release_contract_test.exs` drift guards + README/MAINTAINING/package READMEs (VER-02/03)
  - **64-03** — host seam subsection + in-place flow guide updates (VER-02)
  - **64-04** — CI scope, handoff checklist, verification artifact (VER-03)

### Claude's Discretion
- Exact forbidden-phrase additions beyond the lists above
- Whether `guides/introduction/user-flows-and-jtbd.md` needs a one-paragraph auto-advance operator story
- Collapsible vs always-visible handoff checklist detail in MAINTAINING
- Exact release_contract assert string choices (as long as bounded support truth is enforced)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/ROADMAP.md` — Phase 64 goal, success criteria, VER-01–03
- `.planning/REQUIREMENTS.md` — VER-01, VER-02, VER-03; Proof Posture Gate; Support Truth Gate
- `.planning/milestones/v1.7.0-phases/60-proof-docs-and-support-truth/60-CONTEXT.md` — v1.7 capstone pattern (template for 64)

### Prior phase context (frozen contracts — do not change)
- `.planning/phases/61-auto-advance-authored-contract/61-CONTEXT.md` — policy persistence, pure eligibility, ladder advisory-only
- `.planning/phases/62-orchestration-and-governed-execution/62-CONTEXT.md` — scheduled tick, `guardrail_automation` audit, protected-env CR routing
- `.planning/phases/63-mounted-auto-advance-workflows/63-CONTEXT.md` — mounted panel, six fail-closed modes, timeline labeling
- `.planning/phases/61-auto-advance-authored-contract/61-VERIFICATION.md`
- `.planning/phases/62-orchestration-and-governed-execution/62-VERIFICATION.md`
- `.planning/phases/63-mounted-auto-advance-workflows/63-VERIFICATION.md`

### Proof and release engineering anchors
- `rulestead/lib/mix/tasks/verify.phase60.ex` — merge gate union pattern (template)
- `rulestead/lib/mix/tasks/verify.phase56.ex` — prior capstone reference
- `rulestead/test/rulestead/release_contract_test.exs` — support-truth drift guards
- `scripts/ci/test.sh` — scoped CI proof bars
- `MAINTAINING.md` — maintainer proof sections (guarded_rollout_foundations explicitly excludes auto-advance today)
- `prompts/rulestead-release-engineering-and-ci.md` — per-phase verify tasks, scripts-first CI
- `prompts/rulestead-testing-and-e2e-strategy.md` — Fake merge gate, contract tests

### Docs and host integration
- `prompts/rulestead-host-app-integration-seam.md` — host seam doc (add auto-advance subsection)
- `guides/flows/admin-ui.md` — admin operator contract (extend for auto-advance)
- `guides/flows/rollout.md` — staged rollout semantics (extend for observation window)
- `README.md`, `rulestead/README.md`, `rulestead_admin/README.md` — public support truth

### Product and security anchors
- `prompts/rulestead-admin-ux-and-operator-ia.md` — calm operator copy; automation labeled distinctly from manual
- `prompts/rulestead-domain-language-field-guide.md` — rollout, guardrail, observation window vocabulary
- `prompts/rulestead-security-privacy-and-threat-model.md` — host-owned Policy, fail-closed, redaction
- `prompts/rulestead-telemetry-observability-and-audit.md` — audit correlation, no PII in meta

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.Phase60` — flat core union + admin subprocess pattern; copy structure for Phase64
- `release_contract_test.exs` — guarded-rollout, blast-radius, and reusable-targeting support-truth blocks as templates
- `scripts/ci/test.sh` — `run_blast_radius_governance/0`, failure guidance, scope switch
- Phase 61–63 test files already green — phase64 union selects them, does not rewrite contracts

### Established Patterns
- Per-phase verify task = explicit test path list, no kitchen-sink verifier
- Support truth enforced by release_contract string asserts + forbidden phrases
- Phase 60: 4 plans (gate → contract → guides → CI/handoff)
- Docs: in-place guide updates, no Phase 8-only public API docs early
- `guarded_rollout_foundations` CI scope explicitly does not prove auto-advance — Phase 64 adds separate scope

### Integration Points
- `rulestead/mix.exs` — add `verify.phase64` preferred_env
- `scripts/ci/test.sh` — new `guarded_rollout_auto_advance` scope case + runner
- Root/package READMEs + MAINTAINING — proof commands and bounded auto-advance claims
- `prompts/rulestead-host-app-integration-seam.md`, `guides/flows/admin-ui.md`, `guides/flows/rollout.md` — auto-advance documentation

</code_context>

<specifics>
## Specific Ideas

- Mirror v1.7 Phase 60 closure shape exactly — this is the v1.8 capstone, not a feature phase.
- Remove stale forbidden `"auto-advance"` phrases from release_contract now that bounded claims are implemented.
- `verify.phase60` stays valid for v1.7 regression; `verify.phase64` is the superset v1.8 gate.
- `guarded_rollout_foundations` scope remains unchanged — auto-advance proof is a separate, explicit scope.

</specifics>

<deferred>
## Deferred Ideas

- Host-configurable auto-advance presets UI — deferred (ADM-05)
- Fleet auto-advance dashboard — out of scope (ROADMAP)
- Metrics graphs or signal trend charts — observability product widening; host-owned
- Auto-approve change requests for protected-env auto-advance — Phase 62 explicitly deferred
- New standalone `guides/flows/auto-advance.md` — prefer extending admin-ui + rollout unless gap found during planning

</deferred>

---

*Phase: 64-proof-docs-and-support-truth*
*Context gathered: 2026-05-27*

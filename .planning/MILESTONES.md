# Milestones

## v1.7.0 Blast-Radius Governance (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 16 plans, 8 tasks

**Key accomplishments:**

- Reusable blast-radius panel and AudienceLive governance loader assign governance_mode, visibility tier, and threshold assessment without predicate leakage.
- Edit and archive preview LiveViews load blast-radius assessment, show governance evidence above impact preview, and branch Continue CTA copy for protected above-threshold mutations.
- Edit and archive confirm LiveViews enforce blast-radius governance: direct apply below threshold, Submit change request above threshold, and fail-closed blocked state with prod LiveView proof.
- Change request review shows frozen blast-radius evidence for audience mutations, blocks approve when flag read visibility is partial, and documents that governance UX stays on existing audience preview/confirm routes.

Known deferred items at close: 3 (see STATE.md Deferred Items)

---

## v1.6.0 Reusable Targeting Deepening (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 16 plans, 22 tasks

**Key accomplishments:**

- Pure audience impact previews with scoped audprev fingerprints, redacted sample evidence, and authored-state dependency summaries.
- Runtime snapshots now carry compiled reusable audiences, and segment_match evaluation resolves them locally with deterministic support-safe traces.
- Public and Store audience impact preview/apply contracts with Fake stale-fingerprint enforcement and Redis read-only parity.
- Ecto-backed audience preview/apply enforcement with support-safe audit evidence and snapshot-local runtime audience payloads
- Shipped a canonical, deterministic audience dependency inventory with projection-backed Ecto/Fake parity and authorized redacted public read APIs for downstream promotion and manifest safety flows.
- Shared dependency truth now blocks unsafe publish and audience mutation writes in both Ecto and Fake with deterministic blocker findings and auditable evidence.
- Promotion and manifest apply paths now consume one deterministic dependency-truth contract, surface scoped dependency findings, and fail closed before any unsafe writes.
- Phase 54 now has deterministic dependency proof coverage, parity-safe fail-closed contract assertions, a single `mix verify.phase54` merge gate, and a Phase 55 handoff checklist that locks core-vs-mounted truth boundaries.
- Mounted audience library and detail surfaces render Phase 54 dependency inventory with policy-aware partial visibility and UI-SPEC operator copy.
- Audience edit and archive mutations use mounted preview → confirm → audit with drift handling; delete stays fail-closed.
- Flag explain, rules, and simulate surfaces carry reusable audience context with support-safe traces and links into the audience library.
- Compare surfaces audience dependency findings read-only; phase verification and handoff document lock core-vs-mounted boundaries for Phase 56.
- `mix verify.phase56` ships as the v1.6 reusable targeting deepening merge gate with a flat 17-path core union and bounded admin completion tests.
- Release-contract drift guards and README/MAINTAINING/package README sections now describe the same bounded v1.6 reusable targeting scope.
- Four operator flow guides now describe Audience preview limits, snapshot-local explain traces, mounted preview→confirm→audit, and scoped compare/promotion dependency findings.
- Phase 56 closes with optional CI proof scope, handoff/verification artifacts, and VER-01/02/03 traceability — sibling-package release model unchanged.

Known deferred items at close: 4 (see STATE.md Deferred Items)

---

## v1.5.0 - Guarded Rollout Foundations (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 8 plans, 10 tasks

**Key accomplishments:**

- Phase 49 now has one explicit, host-owned, fail-closed guardrail signal contract in `rulestead`.
- Guardrails now live inside rollout authored state and are validated before they can enter draft or publish flows.
- The Phase 49 guardrail contract now survives compare and manifest/export surfaces intact.
- Phase 50 now has a real guarded rollout decision engine and audit-backed intervention path in `rulestead`.
- Mounted rollout guardrail status panel with core-backed evidence, missing-prerequisite copy, and guardrail-preserving percentage saves.
- Automatic guardrail hold, rollback, and evaluated events now appear inside existing mounted timeline surfaces with bounded rollout-page context.
- Bounded guarded rollout proof bar with adapter-path fail-closed gaps, docs support truth, and drift guards
- Phase 52 verification artifact and active planning truth reconciled to VER-01 satisfied

---

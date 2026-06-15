# Milestones

## v1.17 Admin Design System Stress Test (Shipped: 2026-06-15)

**Phases completed:** 6 phases, 19 plans, 33 tasks

**Key accomplishments:**

- Plan 01 created the DSM-01 inventory artifact without touching runtime code, CSS, tests, packages, schemas, release workflow, FleetDesk branding, or publish-prep files.
- Plan 02 created the DSM-03 matrix contract without implementing the future matrix harness or editing runtime code, CSS, tests, packages, schemas, release workflow, FleetDesk branding, or publish-prep files.
- Plan 03 closed Phase 113 with acceptance gates and tracking updates after the inventory and matrix contract were already committed and verified.
- Demo-hosted Phoenix LiveView matrix rendering real admin components with deterministic stress fixtures and source-boundary tests.
- Playwright evidence for the real Phoenix admin UI matrix across theme, viewport, reduced-motion, keyboard, overflow, screenshot, and static-fixture preservation paths.
- Breakpoint exception ledger and stdlib source guard now make admin foundation drift auditable in CI.
- Reduced-motion behavior now neutralizes nonessential transforms, and one exact pixel breakpoint is normalized to canonical `60rem`.
- UI matrix evidence now proves reduced-motion transform behavior, raw-detail containment, and foundation source markers without adding baseline tooling.
- Raw markup classification plus shared operator primitive helpers for form fields, action rows, and blocked/read-only matrix states
- Canonical mutation confirms with typed-key, blocked-state, scope, evidence, and matrix variant coverage
- Reusable admin composite families with explicit provenance, guardrail, governance, uncertainty, trace, and authored-state labels
- Requirement-level matrix evidence, final raw-markup dispositions, Phase 116 verification, and a bounded Phase 117 IA handoff
- Route-cluster IA review plus deterministic UI matrix route examples for the Phase 117 flow set
- Playwright route-flow evidence for primary admin clusters, command palette reachability, kill-switch focus order, mobile containment, and generated screenshots
- Evidence-triggered audit, explain, and simulate hierarchy fixes with final FLOW requirement, decision, proof, and Phase 118 handoff coverage
- Stdlib CI guard that protects matrix/workflow evidence hooks, generated screenshot posture, selected contrast proof, fixture-health coverage, and visual-baseline exclusions.
- Reusable v1.17 evidence map with exact backend URL, generated screenshot counts, deterministic assertion results, and guard-chain output.
- Post-evidence VER-04 closeout tying Phase 118 proof, D-01 through D-20 decisions, requirement status, roadmap progress, state handoff, and Nyquist validation together.

---

## v1.16 Brand-Faithful UI Iteration (Shipped: 2026-06-13)

**Phases completed:** 7 phases, 8 plans

**Key accomplishments:**

- Repo-local UI-SPEC locked the boundary: mounted admin, brandbook, fixtures, and demo launcher use the v1.15 Rulestead identity; FleetDesk remains a distinct host/example app.
- Static fixtures render the shipped wordmark family, copied admin wordmark assets are drift-checked against `brandbook/assets/logo/`, and logo/contrast guards run in the normal lint path.
- Admin primitive tokens were corrected inside the frozen mineral palette: primary foreground contrast, soft-primary states, Stead Blue-derived focus/selection rings, scoped theme cascade, and non-color-only status semantics.
- Browser evidence covers admin route clusters, demo launcher, FleetDesk, fixtures, light/dark/system modes, desktop/mobile widths, logo visibility, theme controls, and horizontal-overflow absence.
- Phase 112.1 closed the audit gap: Phoenix-owned FleetDesk launcher/layout links render from `DEMO_FRONTEND_URL`, backend tests prove non-3000 URLs, and Playwright clicks through to the selected FleetDesk origin.
- Audit backfill added BUI requirement rows, summary frontmatter, and Nyquist validation artifacts for Phases 107-112; the v1.16 milestone audit now passes.

**Scope note:** No public runtime APIs, schemas, release workflow changes, component framework adoption, palette redesign, logo redraw, or `rulestead_admin` publish preparation.

**Archive:** [.planning/milestones/v1.16-ROADMAP.md](milestones/v1.16-ROADMAP.md)

**Requirements:** [.planning/milestones/v1.16-REQUIREMENTS.md](milestones/v1.16-REQUIREMENTS.md)

**Audit:** [.planning/milestones/v1.16-MILESTONE-AUDIT.md](milestones/v1.16-MILESTONE-AUDIT.md) (`passed`)

---

## v1.15 Identity Tournament (Shipped: 2026-06-12)

**Phases completed:** 5 phases, 8 plans

**Key accomplishments:**

- Human-gated logo tournament (2 rounds, 18 candidates + incumbent control, 4 design axes) produced winner A3-3: an integrated lockup where a Stead-Blue route grows collinear from the R's leg, threads the baseline, and rises through the final d to three exit nodes — lit copper = the selected route
- Complete 8-file logo family (primary, NEW tagline secondary, dark, d-sigil mark/dark/mono, 16px-verified transparent favicon, social card), all within 20KB budgets; SVGO config hardened to preserve accessibility attrs and per-glyph structure
- Zero token deviations — winner ships on the frozen v1.14 mineral palette and Sora Bold; all drift guards green untouched
- brand-book §14 rewritten as the shipped logo system (construction, clearspace, min sizes, usage/misuse); specimens regenerated programmatically from shipped sources
- Admin shell + demo propagation: brand_lockup/brand_wordmark components with semantic --logo-* vars across all four cascade blocks, d-sigil statics, demo favicon + digest regen; admin suite 200/0
- brandbook/index.html elevated to a designed artifact: Basalt cover with hero lockup + mantra, sticky numbered scrollspy rail, editorial numerals/pull-quotes, build-time WCAG AA/AAA-badged token swatches, dual-tile logo plates with clear-space diagram and struck don't-examples, print stylesheet — 223,744B (256KB budget unchanged), 12/12 file:// e2e

**Archive:** [.planning/milestones/v1.15-ROADMAP.md](milestones/v1.15-ROADMAP.md) · phases in `.planning/milestones/v1.15-phases/`

**Audit:** [.planning/milestones/v1.15-MILESTONE-AUDIT.md](milestones/v1.15-MILESTONE-AUDIT.md) (`milestone_complete`)

---

## v1.14 Brand System Realization (Shipped: 2026-06-06)

**Phases completed:** 7 phases, 28 plans

**Key accomplishments:**

- Recovered 27-section brand book pressure-tested and relocated to a self-contained, source-controlled `brandbook/` (BRD-01/02), with szTheory suite brand-architecture note (BRD-03)
- 68-token DTCG 2025.10 design-token system (`tokens.json` + `tokens.css` mirror) with drift guards (`check_brand_tokens.py`, `check_tokens_css.py`, `check_synced_pair.py`)
- Logo SVG system: wordmark, mark, mono/dark variants, 16px favicon, social card — all within 20KB budgets, concept exploration archived
- Admin UI re-skinned to the canonical mineral palette across all four CSS cascade blocks (light default, system dark, explicit pins)
- Six reproducible SVG specimens (palette, typography, components, code-block, readme-header, social-card)
- Marketing copy kit (VOICE.md, COPY.md, RELEASE-TEMPLATE.md) and asset-size policy (BUDGET.md)
- Generated `brandbook/index.html` capstone (stdlib generator, 256KB budget, drift check, file:// browser evidence, CI wiring)

No new runtime APIs, schema changes, package-version changes, or publish-posture changes.

**Archive:** [.planning/milestones/v1.14-ROADMAP.md](milestones/v1.14-ROADMAP.md) · phases in `.planning/milestones/v1.14-phases/`

---

## v1.13 Admin UI — First-Class Dark Mode + Design-System Polish (Shipped: 2026-06-04)

**Phases completed:** 8 phases, 14 plans, 24 tasks

**Key accomplishments:**

- Standalone HTML harness, five-case Playwright cascade spec, scope-containment spec, and WCAG contrast-check helper providing the complete verification substrate for Plans 02 and 03.
- Interactive focus targets added to theme-harness.html covering page-bg, card, and colored-fill surfaces so Plan 02's unified two-stop ring can be screenshot-verified on every context
- File:// Playwright fixture (inlined hook JS + radiogroup markup) + 11-test spec covering THM-02/THM-04 persistence, system/pinned/keyboard/ARIA/FOUC behaviors
- Delivered .ThemeControl runtime ColocatedHook with localStorage persistence, segmented radiogroup in shell header, and FOUC suppression via data-theme-pending — all 11 theme-control + 5 theme-cascade Playwright tests pass
- Added section 20 (Theme Persistence and Dark Mode) to the host integration guide: covers the theme_default attr on Shell.page/1, the optional layer-3 head script for pinned-mismatch fast-path, and CSP/nonce requirements for the runtime ColocatedHook
- --rs-accent darkened to #9a3f12 (5.74:1) in light-mode cascade; design-system gate restored to normal 4.5 threshold; 7-screen broadened sweep shows clean both-theme rendering with no straggler
- Entrance animations on card/record-row rows aligned to ease-out; theme-toggle background-transition flicker eliminated via transient `data-theme-switching` rAF suppression

---

## v1.11.1 Gap Closure (Shipped: 2026-05-29)

**Phases completed:** 3 phases, 3 plans, 8 tasks

**Key accomplishments:**

- Fixed getting-started → spine §6 lifecycle deep-link with numbered GitHub/HexDocs anchor slug (DOC-02, INT-02)
- Backfilled `76-VERIFICATION.md` and `77-VERIFICATION.md`; refreshed `77-VALIDATION.md` to complete status (INT-01–03, DOC-01–03)
- Extended intro contract test with DOC-01 `evaluation.md` Runtime API guard; backfilled `76-VALIDATION.md` Nyquist artifact
- `mix verify.phase76` green throughout gap closure; closes v1.11 audit deferrals from Phase 80/81

**Archive:** [.planning/milestones/v1.11.1-gap-closure-ROADMAP.md](milestones/v1.11.1-gap-closure-ROADMAP.md)

**Audit:** [.planning/milestones/v1.11.1-MILESTONE-AUDIT.md](milestones/v1.11.1-MILESTONE-AUDIT.md) (`passed`, supersedes v1.11 `gaps_found`)

---

## v1.11 Integration Spine (Shipped: 2026-05-28)

**Phases completed:** 3 phases, 5 plans, 0 tasks

**Key accomplishments:**

- Phoenix integration spine doc (`phoenix-integration-spine.md`) wired from intro hubs
- Evaluation and lifecycle doc alignment (`Rulestead.Runtime`, `owner_ref` / `expected_expiration` callouts)
- Intro spine contract test and `mix verify.phase76` merge gate ship as the v1.11 adopter bar; adopter and CI delegate to phase76 without calling phase73.
- Adopter and maintainer surfaces now cite `mix verify.phase76`; release_contract_test enforces phase76 strings and v1.11 spine routing.
- v1.11 milestone closed: INV-INTRO-01 marked Closed in STATE, audit published, requirements VER/AUD ticked complete.

---

## v1.10.1 Support-truth & Contract Honesty (Shipped: 2026-05-28)

**Phases completed:** 3 phases, 7 plans

**Key accomplishments:**

- Context `traits:` → `attributes` back-compat with release-contract quickstart guards
- `MAINTAINING.md` and `guides/api_stability.md` aligned with shipped post-GA public surface
- `mix verify.phase73` / `mix verify.adopter` proof umbrella; INV-API-01, INV-MAINT-01, INV-CTX-01 closed
- `v1.10.1-MILESTONE-AUDIT.md` (`support_truth_complete`)

---

## v1.10.0 Post-GA Band Truth & Adopter Closure (Shipped: 2026-05-28)

**Phases completed:** 4 phases, 0 plans (verification-driven closure)

**Key accomplishments:**

- Post-v1.9 band assessment (~94–96% done band) supersedes prior milestone-selection threads with adopter flow matrix and feature-complete v1.1–v1.9 verdict
- `product-boundary.md` and `footguns.md` publish honest in-scope, host-owned, and evaluation footgun guidance without new APIs
- README and getting-started teach payload-first evaluation and `Rulestead.Runtime` keyed lookup — not `Rulestead.enabled?(flag_key, conn)`
- `mix verify.phase72` and `mix verify.adopter` provide a flat post-GA band merge gate; `post_ga_band_closure` CI scope with categorized failure guidance
- `post_ga_band_contract_test.exs` and `release_contract_test.exs` guard band-closure support truth and forbid stale unbuilt claims for v1.7–v1.9 wedges
- `scripts/demo/proof.sh` documents a bounded 15-minute adopter proof path; README band-complete section points to v2 deferred queue
- `v1.10.0-MILESTONE-AUDIT.md` records `band_complete`; v1.9 phases archived under `milestones/v1.9.0-phases/`

Known deferred items at close: 3 (see STATE.md Deferred Items)

---

## v1.9.0 Host-Supplied Preview Evidence (Shipped: 2026-05-28)

**Phases completed:** 4 phases, 16 plans, 12 tasks

**Key accomplishments:**

- Host-configurable PreviewEvidence behaviour with normalized query map, fail-closed 25-row/16 KiB limits, and redacted sample/impression validation
- ImpactPreview schema v2 with impression_evidence, impression_fingerprint in deterministic preview token, and basis-specific uncertainty messages per D-04/D-05
- Fake and Ecto audience_preview_payload invoke PreviewEvidence before ImpactPreview.build, with union sample merge, basis selection, and adapter contract tests via Rulestead.Fake.PreviewEvidenceResolver
- Fake and Ecto contract tests prove schema v2 host evidence, fail-closed resolver errors, stale apply on impression drift, and GOV-05 reference-count-only blast-radius boundary
- Single `audit_evidence_summary/1` helper and `impression_evidence` audit allowlist for support-safe preview carry-through.
- Wired `audit_evidence_summary/1` through Fake and Ecto audience mutation audit paths including blast-radius blocks.
- Frozen `preview_evidence_summary` on change-request submit and terminal reject/cancel audit metadata.
- GOV-05 contract tests prove blast-radius routing ignores rich preview evidence; no scoring changes.
- Extended `AudienceComponents.impact_preview/1` to render bounded sample cohort and impression summary evidence with core-driven uncertainty copy.
- Mounted edit and archive preview LiveViews prove host-supplied evidence via `Rulestead.Fake.PreviewEvidenceResolver` with no LiveView code changes.
- Delete preview shows impact evidence alongside unsupported-delete callout; prod edit preview shows governance + evidence when resolver is on.
- Closed ADM-05 mounted contract sweep: confirm link carry-through, forbidden copy regression guard, MAINTAINING drift list.
- `mix verify.phase68` runs the v1.9 superset: all phase64 core paths plus three preview-evidence contract tests and `audience_components_test.exs` in the admin subprocess.
- Release contract drift guards and bounded v1.9 support-truth READMEs for host preview evidence.
- Host seam and in-place flow guides teach preview evidence boundaries and operator UX.
- `host_preview_evidence` CI scope, verification artifact, and maintainer handoff checklist close v1.9 proof traceability.

Known deferred items at close: 3 (see STATE.md Deferred Items)

---

## v1.8.0 Guarded Rollout Auto-Advance (Shipped: 2026-05-27)

**Phases completed:** 4 phases, 16 plans, 32 tasks

**Key accomplishments:**

- Observation-window close ticks register via schedule_governed_action after advance_rollout with deterministic idempotency, supersession, and fail-open scheduling across Ecto and Fake adapters.
- Automation ticks validate live rollout snapshots, resolve fresh guardrail signals, evaluate eligibility, and either complete blocked without mutation or build governed AdvanceRollout commands with guardrail_automation metadata.
- Protected environments auto-submit advance_rollout change requests at observation-window ticks; non-protected environments direct-advance through the orchestrator with Fake/Ecto finalize parity and audit CR links.
- Fake and Ecto pass identical orchestration contract tests proving schedule→execute auto-advance, guardrail_automation audit evidence, blocked non-advance, protected-env CR submit, replay safety, manual-advance races, and idempotent tick scheduling.
- Mounted rollouts page exposes a read-only auto-advance panel with fail-closed mode derivation from guardrails, policy, and scheduled ticks—no core package changes.
- Rollouts page saves auto-advance policy through direct upsert gated on `:advance_rollout`, with prerequisite-disabled modes and protected-env callout that does not block save.
- Timeline and intervention excerpts label guardrail_automation rollout.advance as Automatic rollout advance with explicit redaction paths and LiveView tests distinguishing automation from manual actions.
- ADM-04 and AUD-04 contract matrices are green: rollouts panel modes, timeline automation labeling, and Phase 62 orchestration regression verified with nyquist sign-off.
- v1.8 merge gate runs phase60 regression plus auto-advance contract and admin rollouts/timeline tests in one `mix verify.phase64` command without delegating to sub-tasks.
- v1.8 auto-advance support truth is enforced by release_contract_test.exs and reflected in root, package, and maintainer docs without removing verify.phase56 or verify.phase60 proof entries.
- Bounded auto-advance documentation added to the host integration seam and in-place flow guides — host-owned signals, observation windows, and guardrail_automation audit labeling without new standalone docs.
- Bounded auto-advance proof reruns via `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance`, with phase verification artifact and v1.8.0 milestone traceability closed.

Known deferred items at close: 3 (see STATE.md Deferred Items)

---

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

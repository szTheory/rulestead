# Research Summary — Rulestead

**Status:** Imported from `prompts/` anchor + topical docs (not re-derived by research agents).
**Primary sources:**
- `prompts/elixir_feature_flags_research_brief.md` (1720 lines — product vision, domain, personas, architecture, telemetry, admin UI, API, pitfalls, v1 acceptance criteria)
- `prompts/rulestead-engineering-dna-from-prior-libs.md` (master synthesis of 7 prior shipped Elixir OSS libs — validated patterns to port verbatim)
- `prompts/rulestead-brand-book.md` (naming, voice, visual identity)

**Topical deep-dives loaded selectively per phase:**
- `prompts/rulestead-release-engineering-and-ci.md` — repo bootstrap, CI, release-please, Hex publish
- `prompts/rulestead-testing-and-e2e-strategy.md` — test harness, Fake adapter, golden-diff installer, Playwright
- `prompts/rulestead-admin-ux-and-operator-ia.md` — flag list, detail, rulesets, rollouts, explain, simulate, kill switch, audit
- `prompts/rulestead-telemetry-observability-and-audit.md` — telemetry events, OTel, audit ledger
- `prompts/rulestead-security-privacy-and-threat-model.md` — policy, authz, redaction, threat model
- `prompts/rulestead-domain-language-field-guide.md` — canonical vocabulary (load at every phase start)
- `prompts/rulestead-personas-jtbd-and-onboarding.md` — personas, JTBD, onboarding flows
- `prompts/rulestead-host-app-integration-seam.md` — installer, generators, Plug, LiveView hook, Oban middleware

**Background (Elixir/Phoenix/Ecto/LiveView/OSS/CI-CD ecosystem best practices, shared across Jon's prior libs):**
- `prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`
- `prompts/elixir-best-practices-deep-research.md`
- `prompts/phoenix-best-practices-deep-research.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
- `prompts/ecto-best-practices-deep-research.md`
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`

---

## Stack (2026)

**Language/runtime:** Elixir 1.17+ / OTP 26+ (target matrix: 1.17/26.x and 1.19/28.x).
**Web/UI:** Phoenix 1.7+, Phoenix LiveView 1.0+, Plug.
**Data:** Ecto 3.11+, PostgreSQL 15+ primary store. Optional Redis adapter later.
**Jobs:** Oban for scheduled/background work (middleware for context propagation).
**Telemetry:** `:telemetry` as primary; optional OpenTelemetry bridge behind `Code.ensure_loaded?` guard.
**Testing:** ExUnit + Mox + StreamData + `Ecto.Adapters.SQL.Sandbox` (`mode: :manual`).
**E2E:** Playwright on GitHub Pages daily demo (sigra pattern).
**Packaging:** Hex.pm publish via release-please; MIT license; ExDoc guides (3-folder split: introduction / flows / recipes).

## Feature categories (from research brief §9 domain language + §20 phased roadmap)

**Table stakes for v0.1.0:**
- Evaluation runtime: booleans + multivariate values + ordered rules + deterministic bucketing + snapshot-based ETS cache
- Ecto-backed authoring store with migrations shipped via `mix rulestead.install`
- Explicit Context (from Plug conn / LiveView socket / Oban job / raw map)
- Plug, LiveView, Oban seams
- Telemetry spans + event catalog (versioned as public API)
- Explain API (matched rule, bucket reasoning, reason labels, snapshot version)
- Test helpers (`with_flag`, `put_flag`, `clear_flags`, `seed_bucket`)
- Admin UI: flag list, detail/rule editor, simulation/explain, rollout controls, kill switch, audit timeline
- Environments/projects model (dev/staging/prod isolation)
- Lifecycle metadata (owner, expiration, stale markers)

**Deferred to v0.2+ (governance milestone):**
- Approvals / change requests
- Scheduled changes (future-dated toggles)
- Webhooks
- Real-time update streaming (SSE/WS)
- Import/export (beyond JSON snapshots)
- Full code-references / stale-flag cleanup automation

**Deferred to v0.3+ (experimentation + ecosystem milestone):**
- Variant impressions / exposure event hooks (beyond basic telemetry)
- Tracking hooks / analytics integrations
- OpenFeature provider bridge
- Redis store adapter
- Multi-node sharded cache / streaming deltas
- Sample-ratio-mismatch detection / guardrail metrics

## Architecture (from research brief §11 + engineering DNA §5)

**Sibling packages:**
- `rulestead` — core (evaluator + store + snapshot cache + context + rules + variants + explain + telemetry + Plug/LiveView/Oban seams + installer + `Rulestead.Fake` test adapter)
- `rulestead_admin` — Phoenix LiveView admin UI (flag list/detail/editor, simulation, rollouts, kill switch, audit timeline)

Linked-versions release-please (accrue pattern). Admin is optional — host apps can adopt `rulestead` alone.

**Runtime shape:**
- Snapshot-based local evaluation (not direct DB reads)
- ETS compiled snapshot cache + refresh via Phoenix.PubSub / polling fallback
- Ordered rules, first-match-wins (not gate precedence) — teachable, simulatable, explainable
- Deterministic bucketing from `(flag_key, rule_key, salt, targeting_key)` — stable, migratable
- Hook points: `before_evaluate`, `after_evaluate`, `on_error`, `finally` (OpenFeature-aligned)

**Storage:**
- Ecto-backed authoring store (Postgres)
- Snapshot serialization (versioned) published on write, consumed on refresh
- Optional disk backup for evaluator restart

## Pitfalls to design around (from research brief §6)

1. **Percentage-of-time misuse** — default to sticky actor-based rollout; warn loudly in docs/UI.
2. **Missing targeting key** — `targeting_key` is a first-class required field for sticky rollouts; strict mode fails closed.
3. **Precedence confusion** — ordered rules, simulation/explain, archetypes.
4. **Stale-flag debt** — require owner + expiration at creation; surface stale/potentially-stale in UI + telemetry.
5. **Environment drift** — explicit environments, single flag identity with per-env behavior, diffs, stricter prod privileges.
6. **Cache/invalidation races** — pure evaluator, pluggable store/notification, explicit startup contracts, degraded mode, cache-age exposure.
7. **Test nondeterminism** — built-in deterministic test mode, `Rulestead.Fake` adapter, seeded bucketing helpers.
8. **Inscrutable admin UI** — simulation + explain are mandatory, not polish.
9. **PII leakage** — secure traits vs public metadata, redaction by default in logs/telemetry.
10. **Experiments bolted on without analytics design** — impressions/exposures in core; analytics hooks; don't pretend multivariate = experiment.

## Lifecycle & governance stance (v0.1.0)

- Owner (required) and expected expiration (required) at flag creation.
- Stale/potentially-stale surfaced in flag list + telemetry from v0.1.
- Full approvals / change requests / scheduled changes deferred to v0.2 governance milestone.
- Environments modeled from v0.1 (dev/staging/prod); per-env behavior with single flag identity.

---
*Research imported: 2026-04-23 from prompts/ anchor docs.*

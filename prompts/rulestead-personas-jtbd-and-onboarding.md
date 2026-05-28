# Rulestead Personas, Jobs-to-be-Done & Onboarding

> **Purpose:** Define who rulestead is for, what they're hiring it to do, and the golden-path onboarding experience that gets each persona productive fast. Every API decision, admin UI surface, doc section, and telemetry default should trace back to one or more of these personas.
>
> **Read alongside:** `rulestead-admin-ux-and-operator-ia.md` (screens-by-persona map), `rulestead-host-app-integration-seam.md` (installer UX), `rulestead-engineering-dna-from-prior-libs.md` §2.4.

---

## 1. Persona framework

6 canonical personas. They're not mutually exclusive — a single human might wear two or three of these hats depending on the day. We design for the intersections, not just the centers.

| # | Persona | Core question they bring | Primary surface |
|---|---|---|---|
| P1 | **App Dev (Alex)** — building a feature | "How do I gate this behind a flag in 5 minutes?" | `Rulestead` evaluation API + LiveView helpers |
| P2 | **Tech Lead (Tova)** — shaping rollouts | "How do I ship safely to 1% → 100% with an escape hatch?" | Rulesets + rollouts admin + audit |
| P3 | **PM / Operator (Priya)** — non-engineer | "Where do I see what's live and change a percentage?" | Admin UI flag list + rollout controls |
| P4 | **Support / Success (Sam)** — answering "why did X happen?" | "Why did user `u_9f3a` see treatment?" | Explain a decision + timeline |
| P5 | **SRE / On-call (Shiori)** — 3am incidents | "How do I kill this flag right now?" | Kill switch + health + diagnostics |
| P6 | **OSS Contributor (Omar)** — extending rulestead | "How do I write a custom store / rule strategy / hook?" | Source code + behaviours + contributor docs |

**Secondary personas** informed by the main six: Compliance Officer (audit export, signed bundles), Data/Analytics (impressions/exposures), Security (threat model, policy authoring).

---

## 2. P1 — App Dev (Alex)

### 2.1 Profile

- Mid-level Phoenix developer. 1–4 years Elixir experience.
- Comfortable with Ecto, LiveView, Plug. Not necessarily an OTP expert.
- Works in a team of 3–20 engineers.
- Ships features multiple times per week; wants flags to feel like a minor chore, not a sub-project.

### 2.2 Jobs to be done

1. **Gate a new code path behind a flag.** — "I want `Rulestead.Runtime.enabled?(env, "checkout_v2", context)` (or `evaluate` on a payload) in my controller and nothing else."
2. **Pick a variant for a specific user.** — `variant = Rulestead.get_variant("pricing_exp", ctx)`.
3. **Get a complex value (JSON config) from a flag.** — `%{timeout_ms: ..., rate_limit: ...} = Rulestead.get_value("checkout_config", ctx, default: @defaults)`.
4. **Use flags inside LiveView without boilerplate.** — `{:ok, assign_flags(socket, [:checkout_v2])}`.
5. **Gate an Oban job or background task.** — attach middleware once, evaluate per job.
6. **Test flag behavior without spinning up Postgres.** — `with_flag "foo", true, do: ... end`.
7. **Delete a flag when done.** — find dead flags; CLI surfaces them; archive and rotate out.

### 2.3 Pain points we must solve

- No "magic global state" — dev expects a clear Context they pass.
- No runtime crash if a flag is missing — default always wins, with a loud dev-env warning.
- No requirement to migrate / seed / run Postgres just to write a test.
- No need to learn a DSL — rules are data; evaluation is a function call.
- Honest error messages: a missing flag in dev logs "did you mean X? similar: Y" (Levenshtein suggest).

### 2.4 Golden-path (target: 15 minutes)

1. Add `{:rulestead, "~> 0.1"}` to `mix.exs` → `mix deps.get`.
2. `mix rulestead.install` (interactive; answers default to yes, `--yes` flag skips).
3. `mix ecto.migrate`.
4. Add `plug Rulestead.Plug` in endpoint.
5. Use `Rulestead.Runtime.enabled?("dev", "checkout_v2", context)` with context from Plug assigns.
6. Add a flag via `mix rulestead.add_flag checkout_v2 --default false --env dev`.
7. Toggle to `true` via `mix rulestead.set_flag checkout_v2 true --env dev` or browse to `/admin/flags`.
8. Reload → feature flips. Done.

First 15 minutes delivers value. No read of full docs required.

### 2.5 Key API surfaces

```elixir
Rulestead.evaluate(flag_payload, context, opts \\ [])
Rulestead.enabled?(flag_payload, context)
Rulestead.get_variant(flag_payload, context, opts \\ [])
Rulestead.get_value(flag_payload, context, opts \\ [])
Rulestead.Runtime.enabled?(environment_key, flag_key, context)

# LiveView helper
{:ok, socket} = Rulestead.LiveView.assign_flags(socket, [:checkout_v2, :pricing_exp])

# Test helpers (documented, stable)
with_flag "checkout_v2", true, do: ... end
put_flag "pricing_exp", %{variant: "treatment"}
seed_bucket "pricing_exp", "u_123", "treatment"
```

### 2.6 Doc touchpoints

- `README.md` quickstart (targets Alex; 60-second overview).
- `guides/introduction.md` (5-minute "hello flag").
- `guides/flows/evaluation.md` (10-minute deep-dive on evaluation + context).
- `guides/testing.md` (how to test-first with Fake adapter).

---

## 3. P2 — Tech Lead (Tova)

### 3.1 Profile

- Senior Elixir engineer or staff+ engineer.
- Owns architecture decisions; responsible for team velocity + safety.
- Thinks about rollout strategies, failure modes, experimentation design.
- Reviews PRs; writes runbooks.

### 3.2 Jobs to be done

1. **Design a staged rollout.** 1% → 10% → 50% → 100% with health-gating.
2. **Structure rulesets for maintainability.** Consistent precedence; named audiences; avoid rule sprawl.
3. **Enforce approval policy for prod changes.** Direct publish in staging; change-request required in prod.
4. **Understand evaluation performance.** p99 latency, cache hit rate, fallthrough rate.
5. **Audit + report.** Who changed what when. Export to compliance.
6. **Sketch A/B experiments.** Emit exposures; hand off to analytics team for assignment analysis.
7. **Own the kill-switch runbook.** How to engage + release; who's authorized.

### 3.3 Pain points

- Flag sprawl (flags live long past their useful life).
- Unclear who owns which flag.
- No simulation before publish → regret moments.
- Rollouts without auto-rollback signals → incidents.
- Audit trail that's technically complete but unnavigable.

### 3.4 Golden path

Beyond Alex's basics, Tova wants:

1. **Rollouts page** — can see every active rollout at a glance.
2. **Simulate-before-publish is enforced** — no publish without a simulate result.
3. **Audit exports signable** — can attach HMAC-signed bundle to a change ticket.
4. **Policy is code** — Tova writes `MyApp.RulesteadAdminPolicy` to encode team rules.
5. **Telemetry into existing OTel collector** — `Rulestead.OTel.setup()` one-liner.
6. **Lifecycle hygiene** — `mix rulestead.stale` lists flags not evaluated in 30d; propose archive.
7. **Shared vocab** — team uses the nouns/verbs from `rulestead-domain-language-field-guide.md`.

### 3.5 Doc touchpoints

- `guides/flows/rollouts.md` — staged rollout patterns, health-gating.
- `guides/flows/experimentation.md` — variants, exposures, handoff to analytics.
- `guides/policy-and-change-requests.md` — writing `Rulestead.Admin.Policy` impls.
- `guides/flag-lifecycle.md` — preventing sprawl.
- `guides/api_stability.md` — what's contract, what's internal.

---

## 4. P3 — PM / Operator (Priya)

### 4.1 Profile

- Product manager, growth, marketing ops, or lightweight admin.
- Not an engineer. Might know SQL. Won't read source code.
- Cares about user experience, launch timing, A/B test outcomes.
- Wants autonomy to adjust flags without filing a ticket.

### 4.2 Jobs to be done

1. **See what's currently live to which users.** Flag list with clear status pills.
2. **Flip an existing flag on/off.** With a reason field. No terminal required.
3. **Advance or hold a rollout.** Progress bar + advance button.
4. **Submit a change request for prod** that engineers approve.
5. **Know which flags are experiments vs operational toggles.** Tag-based filtering.
6. **Not break anything.** Actions that matter must have confirmation + diff + reason.

### 4.3 Pain points

- Admin UIs that require technical knowledge (condition DSLs, JSON editors).
- No undo.
- Cryptic error messages.
- Can't tell which flags are "mine" / owned by my team.

### 4.4 Golden path

1. Log into host app → `/admin/flags`.
2. See flags owned by her team (filter `?owner=me`).
3. Click a flag → see current state, who changed it last.
4. Click `Advance rollout` → fill reason → confirm.
5. Get a Slack notification (host-wired) when rollout completes.
6. Open audit timeline → export week's changes to share at standup.

### 4.5 UX guardrails

- **Simple mode by default.** Variants, percentage rollouts, advanced rule conditions hidden until "Advanced" toggle.
- **Every destructive action has:** preview + confirm + reason + undo path (via audit → revert).
- **Tags + owners visible everywhere.** Priya filters by "my team."
- **Scheduled changes feel like calendar items.** Rollout advance at `Mon 9am` is a row on the schedule view.

### 4.6 Doc touchpoints

- `guides/operator-handbook.md` — written for non-engineers; screenshots heavy.
- In-app help tooltips on every admin control.
- Onboarding tour (progressive) first time they visit `/admin/flags`.

---

## 5. P4 — Support / Success (Sam)

### 5.1 Profile

- Customer support, customer success, onboarding engineer.
- Handles tickets like "why did this user get the new checkout flow?"
- Needs fast read-only access + sharable evidence.
- Not an operator — can view + explain, can't mutate.

### 5.2 Jobs to be done

1. **Look up a decision for a specific user.** `(flag, user_id)` → full trace.
2. **Share a decision-lookup URL with an engineer.** Permalinks to `/admin/flags/:key/explain?actor=u_123`.
3. **See what changed in the last N hours** when a spike of tickets hits.
4. **Filter the timeline** by flag/actor/type.
5. **Quote evidence in a ticket response** — "As of 2026-04-23 14:12 UTC, user u_123 was in the `treatment` variant of `checkout_v2` because they matched rule 3 (US premium). Rollout was at 47%."

### 5.3 Pain points

- Explain pages that need engineering to interpret.
- Audit log that shows diffs but not human-readable summaries.
- No permalink to a specific decision.

### 5.4 Golden path

1. Receive ticket from user u_123 confused about checkout.
2. Open `/admin/flags/checkout_v2/explain?actor=u_123` (bookmark template).
3. See trace: "Served `treatment` — matched `rule 3 (country=US, plan=pro)` — bucket 4721 — ruleset v27 — at 14:12 UTC."
4. Copy-link the explain URL into the ticket.
5. If deeper look: scroll to "Recent audit events for this flag" → see last publish's `reason` + actor.

### 5.5 UX guardrails

- **Explain page is the headline feature.** Linkable, fast, human-readable.
- **Read-only role is a first-class role** in `Rulestead.Admin.Policy.RoleBased`.
- **No PII in URLs** (actor_id is fine; email is not).
- **Plain-English summary** rendered above the technical trace (AI assist option).

### 5.6 Doc touchpoints

- `guides/explaining-decisions.md` — one page, screenshots + URL template.
- Support-specific quickstart card in README (link).

---

## 6. P5 — SRE / On-call (Shiori)

### 6.1 Profile

- SRE, DevOps, platform engineer, or rotating on-call engineer.
- Wakes up at 3am because p99 latency spiked.
- Needs to act fast + safely. Not interested in long menus.
- Trusts runbooks; hates UIs that hide critical controls.

### 6.2 Jobs to be done

1. **Kill a flag instantly.** One action, one confirmation, done.
2. **Roll back a staged rollout** to the last-known-good stage.
3. **Verify rulestead health** — snapshot age, cache hit, fail-closed count.
4. **Trace an evaluation spike to a specific rule** — diagnostics → fallthrough panel.
5. **Hand off the incident** with timeline evidence.
6. **Audit bundle for post-mortem** — export last 2h signed bundle.

### 6.3 Pain points

- Kill switch buried in a menu.
- Confirmation modals with 5 fields when she needs 1.
- Can't tell if a rollback "took" — cache might still be serving old snapshot.
- No health endpoint to curl from alerting.

### 6.4 Golden path (3am incident)

1. PagerDuty fires: "checkout error rate spike."
2. Shiori opens `/admin/flags/checkout_v2/kill` (bookmarked).
3. Clicks big red `Engage kill switch` → reason "p99 regression, rolling back" → confirm.
4. UI confirms: `Kill switch engaged. All actors now served control. Snapshot version 2742 distributed to 12/12 nodes in 340ms.`
5. Opens `/admin/diagnostics` → verifies fallthrough rate dropped.
6. Opens audit timeline → copies event permalink into incident ticket.
7. Post-incident: exports signed audit bundle for the hour.

### 6.5 UX guardrails

- **Kill switch is its own route per flag.** Bookmarkable. Never buried.
- **Confirmation modal for kill has one required field (reason)** — everything else optional.
- **Health endpoint is stable + documented** for alerting pipelines.
- **`Rulestead.Debug.*` iex helpers** exist for when the admin UI itself is part of the incident.
- **Rollback is reversible** — audit records show what variant we reverted to, so we can restore.
- **`rollbar`-style grouping** in telemetry: spikes in `:fail_closed` events get grouped + alertable.

### 6.6 Doc touchpoints

- `guides/runbooks/kill-switch.md` — 1-page, screenshots + keyboard shortcuts.
- `guides/runbooks/rollback-rollout.md`.
- `guides/operations/health-monitoring.md` — curl examples, Prometheus exporter config.
- `guides/operations/alerting.md` — which telemetry events → which severity.

---

## 7. P6 — OSS Contributor (Omar)

### 7.1 Profile

- Elixir OSS author or user extending rulestead for their own needs.
- Might be writing a custom `Rulestead.Store` (for Redis / Mnesia / custom backend).
- Might be contributing a new rule strategy, hook, or admin widget.
- Reads source code; runs `mix test` locally; files PRs.

### 7.2 Jobs to be done

1. **Understand the internal architecture.** Behaviours, data flow, extension points.
2. **Write a custom store adapter.** Know what `Rulestead.Store` contract is + test suite.
3. **Write a custom rule strategy** (e.g., mathematical function, ML model output).
4. **Register a hook without surprises** — middleware order, failure semantics.
5. **Add a widget to the admin UI.** Know how to register, style, wire PubSub.
6. **Contribute a PR.** Conventional commits, CI green on first try.
7. **Release a companion lib** (`rulestead_redis_store`, `rulestead_statsd_exporter`, etc.).

### 7.3 Pain points

- Implicit contracts (behaviours without docs/tests).
- Brittle internals exposed via Hex as public API by accident.
- CI that takes 30 min to feedback on a 5-line PR.
- Style + formatting rules unclear.

### 7.4 Golden path (contribution)

1. Clone repo → `asdf install` (`.tool-versions`) → `mix deps.get` → `mix test` passes in <3 min (fake adapter + unit tests).
2. Read `CONTRIBUTING.md` (toolchain floor + expected PR shape).
3. Read `guides/api_stability.md` to know what's contract.
4. Branch → write test → write code → `mix ci.all` passes locally.
5. Open PR with conventional-commit title → CI green → review.

### 7.5 Golden path (writing a custom store)

1. Read `guides/extension-points/custom-store.md`.
2. Find `Rulestead.Store` behaviour in `lib/rulestead/store.ex`.
3. Implement callbacks; reuse `Rulestead.StoreTest` shared test suite.
4. `use Rulestead.StoreTest, store: MyRedisStore` in deps' test file → gives you 90% coverage.
5. Publish as `rulestead_redis_store` on Hex.

### 7.6 Doc touchpoints

- `CONTRIBUTING.md` — toolchain floor, branch + PR shape, how to run the full CI matrix locally.
- `MAINTAINING.md` — for rulestead maintainers (release runbook).
- `guides/api_stability.md` — what's `@moduledoc` public vs `internal: true`.
- `guides/extension-points/custom-store.md`.
- `guides/extension-points/custom-rule-strategy.md`.
- `guides/extension-points/hooks.md`.
- `guides/extension-points/admin-widgets.md`.
- `ARCHITECTURE.md` — short, high-level, with links to the deeper docs.

---

## 8. Cross-persona affordances

### 8.1 Permissions model

Reference `Rulestead.Admin.Policy.RoleBased` ships with roles covering all personas:

| Role | Alex | Tova | Priya | Sam | Shiori | Omar |
|---|---|---|---|---|---|---|
| `:viewer` |  |  |  | ✓ |  |  |
| `:editor` |  |  | ✓ |  |  |  |
| `:publisher` |  | ✓ |  |  |  |  |
| `:prod_publisher` |  | ✓ |  |  |  |  |
| `:on_call` |  |  |  |  | ✓ |  |
| `:incident_commander` |  |  |  |  | ✓ |  |
| `:auditor` (CR approval) |  | ✓ |  |  |  |  |
| `:dev` (staging/dev only) | ✓ |  |  |  |  |  |

Hosts extend / compose as needed. OSS contributors never touch prod.

### 8.2 In-app help affordances

- First-time visitor: guided tour (dismissible per user).
- Every page has a `?` keyboard shortcut → help overlay with shortcuts + links to relevant guide.
- Inline tooltips on non-obvious controls.
- "Related docs" card in sidebar linking into `hexdocs.pm/rulestead`.

### 8.3 CLI affordances

Every persona gets CLI ergonomics for their most common actions:

```
mix rulestead.add_flag <key> [--type boolean|string|number|json] [--default <v>]
mix rulestead.set_flag <key> <value> [--env <env>]
mix rulestead.archive_flag <key>
mix rulestead.list [--stale] [--env <env>] [--owner <team>]
mix rulestead.explain <flag> <actor_id> [--env <env>] [--at <iso8601>]
mix rulestead.stale [--since <iso8601>]      # flags not evaluated recently
mix rulestead.export_audit [--since <iso8601>] [--tenant <id>] [--out <path>]
mix rulestead.install [--no-admin] [--no-oban] [--yes]
mix rulestead.gen.store <module_name>         # scaffolds a new store adapter
mix rulestead.gen.strategy <module_name>      # scaffolds a new rule strategy
```

All CLI commands JSON-serializable via `--format json` for pipeline integration.

---

## 9. Onboarding checkpoints

These are the "wow moments" we engineer for.

| Checkpoint | Persona(s) | What they see / feel |
|---|---|---|
| **15 minutes** | Alex | First flag flips in local dev. "Oh, that was easy." |
| **1 hour** | Alex, Tova | Flag in tests via `with_flag/3`. Tests pass deterministically without Postgres. "I don't have to fight the test setup." |
| **1 day** | Tova | First staged rollout drafted + simulated. "I can see what'll happen before I publish." |
| **1 week** | Priya | First operator advance of a rollout without pinging an engineer. "I didn't need a ticket." |
| **2 weeks** | Sam | First ticket answered via explain-link. "I shipped a better answer faster." |
| **1 month** | Shiori | First kill-switch drill in staging. "I know exactly where the red button is." |
| **3 months** | Tova | First stale-flag sweep using `mix rulestead.stale`. "We're not accumulating tech debt." |
| **6 months** | Omar | First custom store / strategy lands in a companion Hex package. "The extension contracts are clean." |

Each checkpoint is a measurable goal during GSD's onboarding-quality phase.

---

## 10. Acceptance criteria per persona

These inform phase UAT questions during GSD.

### Alex
- Fresh Phoenix app → rulestead installed + first flag flipping in ≤15 min (measured in `test/example/` smoke).
- `with_flag/3` + friends work with zero Postgres (Fake adapter).
- Missing flag → default returned + dev-env warning with Levenshtein suggestion.
- LiveView helper has <50 LOC of integration code in a host view.

### Tova
- Staged rollout with health-gating designable + publishable in admin UI.
- Simulate-before-publish enforced (policy can relax for non-prod).
- `Rulestead.Admin.Policy.RoleBased` covers Tova's env-aware matrix out of the box.
- OTel setup is one function call + config.

### Priya
- "Simple mode" hides variants, percentage rollouts, audiences, kill switches.
- Every mutation has preview + reason + audit.
- Ownership filter on flag list works.
- CR flow round-trips (submit → approve → audit visible in timeline).

### Sam
- `/admin/flags/:key/explain?actor=...` is permalinkable + fast (<500ms).
- Trace is human-readable + copy-linkable line by line.
- Viewer role works without accidentally granting mutation capability.

### Shiori
- `/admin/flags/:key/kill` is bookmarkable; kill is one-form-field away.
- `/rulestead/health` returns structured JSON suitable for Prom/alerting.
- Fail-closed events emit `:warning` telemetry.
- Audit bundle exportable + signed.

### Omar
- `mix ci.all` completes in <3 min locally.
- Every behaviour has a shared test suite module (`Rulestead.StoreTest` etc.).
- `@moduledoc internal: true` tagged on every internal module.
- Custom store scaffold generates compiling, test-passing code.

---

## 11. Persona-driven doc organization

```
hexdocs.pm/rulestead
├── Introduction                       [Alex]
├── Quickstart                         [Alex]
├── Guides
│   ├── Flows
│   │   ├── Evaluation                 [Alex]
│   │   ├── Rulesets                   [Tova]
│   │   ├── Rollouts                   [Tova, Priya]
│   │   ├── Experimentation            [Tova]
│   │   ├── Kill Switches              [Shiori]
│   │   └── Change Requests            [Tova, Priya]
│   ├── Operator Handbook              [Priya]
│   ├── Explaining Decisions           [Sam]
│   ├── Runbooks
│   │   ├── Kill Switch                [Shiori]
│   │   ├── Rollback Rollout           [Shiori]
│   │   └── Snapshot Stale             [Shiori]
│   ├── Operations
│   │   ├── Health Monitoring          [Shiori]
│   │   ├── Alerting                   [Shiori]
│   │   └── Audit Export               [Compliance]
│   ├── Testing                        [Alex, Omar]
│   ├── Flag Lifecycle                 [Tova]
│   ├── API Stability                  [All]
│   ├── Policy & Change Requests       [Tova]
│   └── Extension Points
│       ├── Custom Store               [Omar]
│       ├── Custom Rule Strategy       [Omar]
│       ├── Hooks                      [Omar]
│       └── Admin Widgets              [Omar]
├── Architecture                        [Omar]
├── Reference
│   ├── Rulestead                       [Alex]
│   ├── Rulestead.Context               [Alex]
│   ├── Rulestead.Flags                 [Tova]
│   ├── Rulestead.Rulesets              [Tova]
│   ├── Rulestead.Rollouts              [Tova]
│   ├── Rulestead.Admin.Policy          [Tova]
│   └── ...                             [varies]
└── Contributing                        [Omar]
```

ExDoc `groups_for_modules` + `extras` configured to reflect this structure.

---

## 12. What we explicitly do not target

- **Client SDK for browsers / mobile.** Phase 2+ if ever. Current scope: server-side Elixir only.
- **Multi-cloud orchestration / Terraform provider.** Out of scope.
- **Drag-drop visual rule builder beyond ordered-rule + condition DSL.** No low-code / no-code positioning.
- **A/B test statistical analysis.** We emit exposures; we don't compute uplift. Integrate with Statsig / GrowthBook / in-house warehouse.
- **Distributed feature flag CDN / edge evaluation.** Runtime is in-process BEAM. Don't try to be LaunchDarkly's edge.

---

## 13. TL;DR

> Rulestead serves six personas: App Dev (15-min quickstart), Tech Lead (safe staged rollouts + policy + simulate), PM/Operator (simple-mode admin UI + reason on every action), Support (permalinked explain-a-decision), SRE (bookmarkable kill switch + health + audit), OSS Contributor (clean extension behaviours + fast CI). Every API, admin surface, doc section, and telemetry default traces to one of these personas, with onboarding checkpoints at 15min, 1h, 1d, 1w, 1mo, 6mo.

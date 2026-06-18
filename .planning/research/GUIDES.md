# R3 Research — Adoption Guides & Onboarding Content (Troubleshooting + Integrations Cookbook)

**Milestone:** v2.0 — 1.0 GA Release & Adoption
**Scope:** Two NEW adoption guides authored *before* the `1.0.0` cut so published HexDocs ships complete. **No new runtime features.**
**Expert lens:** senior dev-advocate / technical writer for Elixir infra libs + DX strategist, grounded in canonical personas (Alex/Tova/Priya/Sam/Shiori/Omar) and JTBD.
**Researched:** 2026-06-17
**Confidence:** HIGH (grounded in repo source-of-truth + verified idiomatic Elixir doc patterns: Oban troubleshooting, Ash tutorials/topics, Diátaxis; competitor footgun brief)

---

## Recommended Decisions Register

| # | Decision | Recommendation | Confidence | Why |
|---|----------|---------------|------------|-----|
| D1 | troubleshooting.md pattern count | **7 patterns** (top adopter failure seams) | HIGH | Oban ships 6; 7 covers Rulestead's distinct seams (config/runtime/RBAC/CR/OpenFeature/Redis/install) without bloat. Scannable in one screen of headings. |
| D2 | troubleshooting.md format | **Symptom → Cause → Fix → Verify**, one H2 per pattern, fix as code/command block | HIGH | Exact idiom of Oban's troubleshooting guide ("Is this my problem?" scan then progressive detail). |
| D3 | Relationship to footguns.md | **Distinct roles, cross-linked, NOT merged.** Troubleshooting = "it's broken, fix it now" (reactive, symptom-indexed). Footguns = "don't design it this way" (proactive, concept-indexed). Each pattern that maps to a footgun ends with a one-line "Underlying design: see [footguns]#anchor". | HIGH | Diátaxis: troubleshooting is a how-to (problem→solution); footguns is explanation/reference. Merging destroys both. |
| D4 | integrations-cookbook.md recipe count | **4 recipes** (3 named in scope + 1 high-leverage addition) | HIGH | 3–5 requested; 4 covers the named seams (Stripe→audience, eval-telemetry→Segment, staging→prod CR promotion) plus Oban-gated job, which is the most-asked Alex/Tova seam not yet a "recipe." |
| D5 | Recipe template | **Goal → Personas/JTBD → Prerequisites → Steps → Verification → Gotchas → Related** | HIGH | Mirrors host-integration-seam checklist shape + brand "what happened / what to do next" voice. "Gotchas" cross-links footguns instead of restating. |
| D6 | HexDocs IA / extras placement | Both land in the existing **Recipes** group (`groups_for_extras` already routes `recipes/`). Order recipes by adopter journey, not alphabetically. troubleshooting.md sits **last in Recipes** (reference-of-last-resort); cookbook sits **early in Recipes** (aspirational, post-first-success). | HIGH | Existing `groups_for_extras` regex already groups them. No new group needed; keeps the front door calm. |
| D7 | First-15-minutes path | **Untouched.** Neither new guide is on the 15-min path. Getting Started → Phoenix Spine stays the golden path; cookbook/troubleshooting are explicitly "after first success." | HIGH | Principle of least surprise: don't put failure content or advanced integrations in the new-adopter's face. Link forward, not up. |
| D8 | Voice | Apply brandbook VOICE/COPY verbatim: state what happened, what did NOT happen, what to do next. Symptom phrasing is blame-free and operator-trustable "at 3am". | HIGH | Canonical VOICE.md is the contract; troubleshooting copy is where 3am-trust is won or lost. |
| D9 | cheatmd vs md | Keep both as **`.md`** (prose, narrative steps). The existing `cheatsheet.cheatmd` already serves the dense-lookup role. | MEDIUM | cheatmd is for terse two-column reference; recipes and troubleshooting are narrative how-tos — wrong format for cheatmd. |
| D10 | Anti-scope guard | Cookbook recipes must use **only shipped public seams** (PreviewEvidence resolver, Guardrails provider, telemetry catalog, change requests, OpenFeature provider). No recipe may imply a runtime feature that doesn't exist. | HIGH | Milestone is release-truth: docs must not overclaim. Every recipe ends with an honest boundary line. |

---

## Part 1 — `guides/recipes/troubleshooting.md`

### Role & positioning (vs footguns.md)

Two guides, two jobs — keep them separate and cross-linked:

| | **troubleshooting.md** (NEW) | **footguns.md** (exists) |
|--|------------------------------|--------------------------|
| Diátaxis type | How-to (problem → solution) | Explanation / reference |
| Indexed by | **Symptom** ("I see X / it does Y") | **Concept / design choice** |
| Reader state | Reactive — something is wrong now | Proactive — designing, want to avoid traps |
| Voice | "Here's what happened and the exact fix" | "Here's why Rulestead refuses to do this" |
| Persona | Alex (install/runtime), Shiori (3am), Sam (explain) | Tova (architecture), Alex (first design) |

**Surfacing footguns without duplicating it:** every troubleshooting pattern whose root cause is an intentional design choice ends with a single line:

> **Underlying design:** Rulestead never auto-archives — see [Footguns → Lifecycle heuristics](footguns.md#lifecycle-heuristics-as-auto-archive).

Footguns owns the *why*; troubleshooting owns the *symptom + fix*. No copy-paste of the explanation.

### Chosen 7 patterns (derived from real footguns + platform seams + competitor brief §6)

Selected to cover the distinct seams an adopter actually hits, in rough order of first-encounter frequency:

1. **Install / migration** (Alex, first hour) — installer conflict + missing tables
2. **Runtime API confusion** (Alex) — payload-first vs keyed `Runtime` (the #1 footgun)
3. **Snapshot/boot race** (Alex, Shiori) — empty/stale snapshot, "flag returns default forever"
4. **Context propagation** (Alex) — lost context across Plug → LiveView → Oban, unstable bucketing
5. **RBAC / policy 403** (Tova, Priya) — admin denies, kill-switch forbidden in prod
6. **Change-request / governance block** (Priya, Tova) — "publish did nothing in prod"
7. **OpenFeature + distributed reads** (Tova, Shiori) — provider returns default, Redis/degraded stale serving

This set maps 1:1 to the platform's named seams in the focus brief (supervision/config/Plug, context propagation, snapshot/refresh, RBAC/policy, change-request governance, OpenFeature provider, Redis/distributed reads, migrations/installer) — collapsed where seams co-occur in one symptom.

### Concrete outline with symptom/cause/fix stubs

```markdown
# Troubleshooting

Symptom-indexed fixes for the situations adopters hit most. Scan the headings,
find your symptom, apply the fix, then verify.

For *why* Rulestead refuses certain patterns by design, see [Footguns](footguns.md).
For evaluating before integrating, see [Adoption Lab](../introduction/adoption-lab.md).

> **Reading this at 3am?** Jump to [Kill switch forbidden in prod](#...) or
> [Flag returns the default and never flips](#...).

## A flag always returns its default (and a dev-env warning logs)
**Symptom:** `Rulestead.Runtime.enabled?/3` returns the default; logs show
"flag not found: checkout_v2 — did you mean checkout-redesign?".
**Cause:** Flag key typo, wrong environment key, or the flag was never published
to that environment's snapshot.
**Fix:** Confirm the key + env with `mix rulestead.list --env <env>`; publish a
snapshot for that environment; re-check the Levenshtein suggestion in the log.
**Verify:** `mix rulestead.explain <flag> <actor> --env <env>` shows a rule match,
not `:flag_not_found`.

## `Rulestead.enabled?` raises or returns garbage on a conn
**Symptom:** `Rulestead.enabled?("checkout_v2", conn)` errors or misbehaves.
**Cause:** Root-module projection helpers take **(flag_payload, context)** — not
a string key on `%Plug.Conn{}`.
**Fix:** Build context via `Rulestead.Plug` (writes `conn.assigns[:rulestead_context]`),
then use the keyed runtime: `Rulestead.Runtime.enabled?(env, "checkout_v2", ctx)`.
**Verify:** Eval returns `{:ok, _}`; `[:rulestead, :eval, :decide, :stop]` fires.
**Underlying design:** see [Footguns → Payload-first vs keyed runtime](footguns.md#payload-first-vs-keyed-runtime-confusion).

## The same user flips between variants across requests
**Symptom:** A user sees treatment, then control, then treatment.
**Cause:** Missing or unstable `targeting_key`; bucketing hashes
`(flag_key, rule_key, salt, targeting_key)`.
**Fix:** Set `targeting_key` from a durable user/account id in `Rulestead.Plug`
`targeting_key_sources` or your context builder.
**Verify:** Two `explain` calls for the same actor return the same bucket.
**Underlying design:** see [Footguns → Missing or unstable targeting_key](footguns.md#missing-or-unstable-targeting_key).

## Evaluation works in tests but returns defaults on a freshly booted node
**Symptom:** Correct values in ExUnit (Fake), defaults right after deploy/boot.
**Cause:** Snapshot cache is empty or stale before the first refresh; node booted
before the store was reachable (expected degraded mode).
**Fix:** Confirm the `Rulestead` supervisor child is started; let the refresh
interval elapse; watch `[:rulestead, :runtime, :cache, :stale_used]` /
`:miss`. In tests use the Fake adapter (no Postgres).
**Verify:** `curl /rulestead/health` reports a non-stale snapshot age.
**Underlying design:** see [Footguns → Snapshot cache before readiness](footguns.md#snapshot-cache-before-readiness)
and [Deployment](deployment.md#start-with-degraded-mode-expectations).

## The installer aborted with a `.rulestead_conflict_*` file
**Symptom:** `mix rulestead.install` exits non-zero; a `*.rulestead_conflict`
sidecar appears next to a host file.
**Cause:** The installer found a hand-edited injection zone it could not safely
update (marker-bounded idempotency guard).
**Fix:** Open the sidecar, merge the intended changes into your file, delete the
sidecar, re-run `mix rulestead.install` (idempotent).
**Verify:** Re-run prints "No changes needed. Everything up to date."

## Admin denies an action / kill switch is forbidden in prod
**Symptom:** `/admin/flags` returns 403, or "Kill switch not engaged — forbidden".
**Cause:** Host `Rulestead.Admin.Policy` denied the action for this actor/env
(default-deny is intentional).
**Fix:** Check the actor's roles via your `ActorResolver`; confirm
`authorize/3` and `change_request_required?/3` in `MyApp.RulesteadAdminPolicy`
match the env. Prod kill may require `:incident_commander`.
**Verify:** Action succeeds for an authorized actor; audit timeline shows the
event with actor + reason.

## A prod publish "did nothing" / OpenFeature provider returns the default
**Symptom:** Publishing in prod left state unchanged; or the OpenFeature client
keeps returning the default value.
**Cause (publish):** Protected env routed the mutation through a **change request**
that is still pending approval — direct publish is staging-only.
**Cause (OpenFeature):** Provider not initialized, env mismatch, or the snapshot
hasn't propagated across nodes (Redis/PubSub) yet.
**Fix:** Approve the change request (or check the CR queue); for OpenFeature,
confirm provider config + env key and watch snapshot fan-out telemetry.
**Verify:** Audit shows the applied CR; provider returns the published value;
`:stale_used` is not firing on the serving node.
**Underlying design:** see [Footguns → Guardrails as an observability product](footguns.md#guardrails-as-an-observability-product)
for what Rulestead does and doesn't own.
```

**Tradeoffs of this structure**

- *Pro:* symptom-first headings are scannable at 3am; matches Oban's proven idiom; each fix is copy-pasteable; the "Verify" line closes the loop (operator knows it worked).
- *Con:* seven patterns can't be exhaustive — mitigate with a final "Still stuck?" section pointing to `mix rulestead.explain`, the health endpoint, telemetry, and the GitHub issue tracker.
- *Idiomatic check:* Oban's troubleshooting uses exactly this problem→cause→numbered-fix shape with embedded rationale. This is the ecosystem-correct format; do **not** invent a heavier template.

---

## Part 2 — `guides/recipes/integrations-cookbook.md`

### Recipe template (D5)

Every recipe is a self-contained how-to with this fixed skeleton:

```markdown
## <Recipe title — outcome-first, e.g. "Reuse your Stripe tier as a targeting audience">

**Goal:** One sentence — the concrete outcome.
**For:** <persona(s)> who need to <JTBD>.
**Prerequisites:** Installed Rulestead (see Getting Started); + any host seam
(e.g. an Oban queue, a telemetry handler, a configured store).
**Steps:**
1. ... (numbered, each with a code block where it earns one)
2. ...
**Verification:** The exact command / observation that proves it works
("`mix rulestead.explain ...` shows rule match", "Segment receives the event").
**Gotchas:** Bulleted; cross-link [Footguns] / [Troubleshooting] rather than
restating. State the honest boundary (what Rulestead does NOT own here).
**Related:** Links to the deeper flow/recipe guides.
```

This mirrors the host-integration-seam checklist shape and the brand voice ("what happened / what to do next"). "Verification" is non-negotiable — it's the trust close.

### Chosen 4 recipes (3 named in scope + 1 high-leverage)

| # | Recipe | Personas / JTBD | Seam used (all shipped) |
|---|--------|-----------------|-------------------------|
| R1 | **Stripe tier → reusable targeting audience** | Tova (structure rulesets), Priya (operate without a ticket) | Reusable audiences + context `attributes` (`plan`); host resolves tier into context |
| R2 | **Evaluation telemetry → Segment / analytics** | Tova (exposures handoff), Sam (evidence), Data/Analytics | Public telemetry catalog `[:rulestead, :eval, :decide, :stop]` + `Rulestead.Telemetry.attach_many/4` |
| R3 | **Staging → prod promotion via change request** | Tova (approval policy), Priya (submit CR), Shiori (safe rollback) | Compare/promote + governed change-request envelope + audit |
| R4 | **Gate an Oban background job** *(addition)* | Alex (JTBD #5), Tova | `Rulestead.Oban.Middleware` + `use Rulestead.Oban.Worker` |

**Why R4 over a fifth named recipe:** Alex's JTBD explicitly lists "gate an Oban job," it's the most-asked Phoenix integration after request-path gating, the seam is fully shipped, and it makes the cookbook span all the framework seams (Plug/LiveView already covered in context-propagation; Oban deserves an outcome-shaped recipe). It also reinforces the "one runtime contract across HTTP, LiveView, and Oban" message.

**Deliberately deferred (anti-scope, D10):** no "wire to a metrics warehouse," "compute A/B uplift," or "build a dashboard" recipes — those are explicit non-goals (footguns: guardrails-as-observability; personas §12). A recipe that implies them would break release-truth.

### Concrete cookbook outline with stubs

```markdown
# Integrations Cookbook

Outcome-shaped recipes for wiring Rulestead into the systems your team already
runs. Each recipe uses only shipped, public seams. Start here *after* your first
flag flips (see [Getting Started](../introduction/getting-started.md)).

## Reuse your Stripe tier as a targeting audience
**Goal:** Roll a feature out to all `pro`/`enterprise` accounts without hardcoding
account ids.
**For:** Tova structuring maintainable rulesets; Priya operating without a ticket.
**Prerequisites:** Installed Rulestead; your billing layer can resolve a tier for
the current actor.
**Steps:**
1. Project the tier into context attributes at the host boundary (in your
   `Rulestead.Plug` config or context builder): `attributes: %{plan: account.tier}`.
2. Author a reusable audience keyed on `plan in ["pro","enterprise"]`.
3. Reference that audience from the flag's ruleset (specific rule before default).
**Verification:** `mix rulestead.explain checkout_v2 <pro_actor> --env staging`
shows the audience rule matched; a starter actor falls through to default.
**Gotchas:**
- Rulestead never calls Stripe — the host owns identity/billing truth; you project
  the tier in. (Boundary: see [Context Propagation](context-propagation.md#what-bounded-means).)
- Put the specific audience rule above broad rules — see
  [Footguns → First-match rule order](footguns.md#first-match-rule-order-surprises).
**Related:** [Rulesets](../flows/rulesets.md), [Reusable audiences in Admin UI](../flows/admin-ui.md).

## Ship evaluation telemetry to Segment / your analytics warehouse
**Goal:** Emit flag exposures to your analytics pipeline for experiment analysis.
**For:** Tova (hand exposures to analytics); Sam (sharable evidence); Data team.
**Prerequisites:** Installed Rulestead; a Segment/analytics client in the host app.
**Steps:**
1. Attach a handler with the safe wrapper:
   `Rulestead.Telemetry.attach_many("seg", [[:rulestead,:eval,:decide,:stop]], &handle/4, nil)`.
2. In the handler, forward bounded metadata (`flag_key`, `environment`, `reason`,
   `variant`, `snapshot_version`) to Segment `track`.
3. Sample with the impressions/telemetry sample-rate config to control volume.
**Verification:** A test eval produces a Segment event with `flag_key` + `reason`;
no raw traits or resolved user payloads appear.
**Gotchas:**
- Rulestead **redacts** raw traits/values from telemetry by design — do not try to
  rebuild user profiles. (See [Telemetry recipe](telemetry.md#route-bounded-metadata-not-user-payloads).)
- Rulestead emits exposures; it does **not** compute uplift — that's your warehouse.
**Related:** [Telemetry flow](../flows/telemetry.md), [Telemetry recipe](telemetry.md).

## Promote staging rules to production through a change request
**Goal:** Move a verified staging ruleset to prod with approval + audit, not a
risky direct edit.
**For:** Tova (enforce approval policy); Priya (submit the request); Shiori (clean
rollback path).
**Prerequisites:** Installed Rulestead with the admin mounted; a policy that marks
prod publishes as `change_request_required?`.
**Steps:**
1. Compare staging vs prod for the flag (admin compare or `mix` compare surface).
2. Submit the promotion as a change request with a `reason`.
3. An authorized approver reviews the diff + approves; the governed envelope applies it.
**Verification:** Audit timeline shows the CR (submitter, approver, diff, reason);
prod snapshot now matches the promoted state.
**Gotchas:**
- Direct publish is staging-only by policy; prod goes through the CR envelope —
  if "publish did nothing," check the CR queue
  (see [Troubleshooting → prod publish did nothing](troubleshooting.md#...)).
- Re-apply is modeled as a fresh forward promotion from immutable history, not a
  hidden rollback shortcut.
**Related:** [Multi-environment](../flows/multi-env.md), [Rollout](../flows/rollout.md).

## Gate an Oban background job
**Goal:** Evaluate a flag inside a background worker using the same context the
request had.
**For:** Alex (JTBD: gate an Oban job); Tova (consistent runtime contract).
**Prerequisites:** Oban in the host; the Rulestead Oban middleware wired (installer
adds it unless `--no-oban`).
**Steps:**
1. Attach bounded context when enqueueing:
   `Rulestead.Oban.Middleware.attach(job, context: ctx)`.
2. `use Rulestead.Oban.Worker` and restore: `ctx = rulestead_context(job)`.
3. Evaluate through the keyed runtime: `Rulestead.Runtime.enabled?(ctx.environment, "sync-enabled", ctx)`.
**Verification:** Worker logs the eval; `assert_flag_evaluated/2` passes in a test.
**Gotchas:**
- Only bounded context fields serialize — no raw `Plug.Conn`/socket/job structs.
  (See [Context Propagation → bounded](context-propagation.md#what-bounded-means).)
- This seam carries context into work; it is not hosted rollout orchestration.
**Related:** [Oban Background Jobs](oban-background-jobs.md), [Testing](testing.md).
```

**Tradeoffs**

- *Pro:* outcome-first titles answer "can it do the thing I need?"; each recipe is independently linkable + complete; "Verification" + "Gotchas/boundary" make them trustworthy and honest. Reuses existing deep guides instead of duplicating them.
- *Con:* risk of drifting toward overclaiming integrations Rulestead doesn't own — D10 boundary line on every recipe is the guard.
- *Idiomatic check:* matches Stripe/Tailwind cookbook shape (goal → steps → verify) and Ash's how-to topic guides. cheatmd would be the wrong format here (those are terse two-column lookups).

---

## Part 3 — Onboarding IA & HexDocs extras order

### Where the new guides slot

The existing ExDoc config already routes by directory:

```elixir
groups_for_extras: [
  Introduction: ~r"guides/introduction/",
  Flows: ~r"guides/flows/",
  Recipes: ~r"guides/recipes/"
]
```

Both new files live in `guides/recipes/`, so **no new group is needed** — they auto-join "Recipes." The only change is adding the two paths to the `extras:` list. Recommended `extras` order (extras render in list order within their group):

```
... Recipes group ...
"../guides/recipes/integrations-cookbook.md",   # NEW — aspirational, early in Recipes
"../guides/recipes/testing.md",
"../guides/recipes/ecto-conventions.md",
"../guides/recipes/oban-background-jobs.md",
"../guides/recipes/deployment.md",
"../guides/recipes/context-propagation.md",
"../guides/recipes/footguns.md",
"../guides/recipes/migrating-from-funwithflags.md",
"../guides/recipes/troubleshooting.md"          # NEW — last (reference of last resort)
```

**Rationale (principle of least surprise):**
- **Cookbook early** in Recipes: it's the "now do something cool with it" content the post-first-success adopter reaches for. It belongs near the top of recipes, just after the journey transitions out of Introduction.
- **Troubleshooting last** in Recipes, adjacent to footguns: you go there when something is wrong; it's a destination you jump *to* (via in-guide links + search), not a step you read in sequence. Placing failure content early would chill the front door.
- Keep footguns immediately *before* troubleshooting so the conceptual "why" and reactive "fix" sit together in the sidebar.

### First-15-minutes path — unchanged (D7)

The golden path is **README → Getting Started → Phoenix Integration Spine**, ending at "first flag flips." Neither new guide is on it. They are linked **forward** from getting-started's "Continue from here" list (already links footguns; add troubleshooting + cookbook there) and surfaced **contextually** (e.g. a 403 in the admin links to troubleshooting; a "want to do more?" card links the cookbook). Never put failure or advanced-integration content above the first-success moment.

### Diátaxis map of the full guide set (for coherence)

| Diátaxis quadrant | Rulestead guides |
|-------------------|------------------|
| Tutorial (learning, hand-held) | Getting Started, Phoenix Integration Spine, Adoption Lab |
| How-to (goal, task) | **Integrations Cookbook (new)**, Testing, Oban, Context Propagation, Deployment, **Troubleshooting (new)** |
| Reference | API Stability, cheatsheet, module docs |
| Explanation | Footguns, Product Boundary, User Flows & JTBD, Domain Language |

The two new guides cleanly fill the how-to quadrant where the gaps were (reactive failure recovery; outcome-shaped integration wiring). This is the same IA Ash uses (tutorials → topics → how-tos).

---

## Part 4 — Voice / Microcopy (apply brandbook VOICE.md + COPY.md)

Calm, precise, operator-trustable at 3am. State what happened, what did NOT happen, what to do next. Avoid hype/magic/celebration.

### Say-this / not-this — guide prose

| Context | Say this | Not this | Why |
|---------|----------|----------|-----|
| Troubleshooting intro | "Scan the headings, find your symptom, apply the fix, then verify." | "Don't panic! We've got you covered." | Calm + actionable; no false reassurance. |
| Symptom heading | "A flag always returns its default (and a dev-env warning logs)" | "Flags not working??" | Names the exact observable state. |
| Fix close | "Verify: `mix rulestead.explain ...` shows a rule match, not `:flag_not_found`." | "That should fix it!" | Confirmation the operator can check. |
| Cookbook recipe goal | "Roll a feature out to all `pro`/`enterprise` accounts without hardcoding ids." | "Supercharge your rollouts with powerful audience targeting!" | Concrete outcome; no growth-platform hype. |
| Boundary line | "Rulestead never calls Stripe — the host owns identity; you project the tier in." | "Seamlessly integrates with Stripe out of the box." | Honest scope; no overclaim. |
| Prod publish gotcha | "Direct publish is staging-only by policy; prod goes through a change request." | "Just publish and you're done." | States the governance reality up front. |

### Say-this / not-this — headings

| Say this | Not this |
|----------|----------|
| "The same user flips between variants across requests" | "Sticky bucketing issues" |
| "Admin denies an action / kill switch is forbidden in prod" | "Permissions problems" |
| "Reuse your Stripe tier as a targeting audience" | "Stripe integration" |
| "Ship evaluation telemetry to Segment" | "Analytics" |

Headings are symptom-/outcome-first so a scanning operator (or search) lands on the right pattern instantly — matches Oban's proven heading style.

### Say-this / not-this — error-pattern phrasing (the Cause/Fix lines)

| Say this | Not this | Why |
|----------|----------|-----|
| "Cause: Protected env routed the mutation through a change request that is still pending approval — direct publish is staging-only." | "Cause: Something's blocking your publish." | Names the object (change request) + the rule + what to do. |
| "Cause: Snapshot cache is empty or stale before the first refresh (expected degraded mode)." | "Cause: Cache problem." | Normalizes degraded mode instead of alarming. |
| "Fix: Approve the change request (or check the CR queue)." | "Fix: Try again." | A specific operator action, not a retry-shrug. |

### Reusable error-copy patterns (lift directly from VOICE.md)

- Empty/missing object → name it + give the next step: "No snapshots have been published. Publish a snapshot before promoting rollout."
- Failure that did not corrupt → reassure scope: "Snapshot publish failed. The previous snapshot is still active. Check store connectivity and try again."
- Degraded behavior → name it + diagnostic: "Evaluation failed. The fallback value was returned. Check the flag payload and context shape."

Troubleshooting Symptom/Cause/Fix copy should read as if it were UI error copy promoted to a guide — same blame-free, what-did-not-happen discipline.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Pattern/recipe selection | HIGH | Derived directly from repo footguns.md, host-seam doc, personas JTBD, and competitor footgun brief §6 — all source-of-truth. |
| Idiomatic format (symptom/cause/fix, recipe template) | HIGH | Verified against Oban troubleshooting + Ash tutorial/topic IA + Diátaxis. |
| IA / extras placement | HIGH | Existing `groups_for_extras` regex + `extras` list inspected in `rulestead/mix.exs`; change is additive + ordering-only. |
| Voice/microcopy | HIGH | Applied canonical brandbook VOICE.md / COPY.md verbatim patterns. |
| Anti-scope (no overclaim) | HIGH | Cross-checked every recipe seam against shipped requirements + product-boundary; boundary line enforced per recipe (D10). |

## Open Questions (for the authoring phase, not blockers)

- Confirm exact CLI/compare command names for R3 promotion (`mix rulestead.*` compare/promote surface) against shipped tasks before finalizing the steps — use placeholders until the authoring phase verifies against `lib/`.
- Confirm the OpenFeature provider init snippet against `open_feature_rulestead` published shape (it publishes manually, dep becomes `rulestead ~> 1.0`).
- Anchor slugs in cross-links (`footguns.md#...`) must match ExDoc's generated anchors — verify after the `1.0` HexDocs render (the milestone already includes a front-door render confirmation step).
```


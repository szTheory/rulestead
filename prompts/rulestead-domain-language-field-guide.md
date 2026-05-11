# Rulestead Domain Language — Field Guide

> **Purpose:** Lock rulestead's vocabulary before implementation. Every other doc downstream (telemetry events, admin IA, schema names, Credo check names, API names) references these terms. Inconsistent names here will cause the rest of the system to disagree with itself.
>
> **Read this first** before writing or reviewing any phase plan, spec, PR description, or guide.
>
> **Modeled after:** `lockspire/prompts/lockspire-auth-domain-language-field-guide.md` — same structure, adapted for feature-flag / experimentation / remote-config domain.

---

## 1. Core distinctions

Feature-flag vocabulary is genuinely mushy across the industry. Many teams use `flag`, `feature`, `toggle`, `switch`, `rule`, `experiment`, `audience`, `cohort`, `variant`, `rollout`, and `remote config` interchangeably. Rulestead does not.

### 1.1 Flag vs feature vs toggle

- **Flag** (rulestead canonical) — a named runtime decision point with an owner, a lifecycle, a value type, and rules that produce a value given a context. This is always the term in code, docs, UI, and telemetry.
- **Feature** — the *product capability* the flag gates. Flags gate features; flags are not features. Never say "create a feature" in admin UI — say "create a flag."
- **Toggle** — a specific *kind* of flag (boolean-typed, release category). Every toggle is a flag; not every flag is a toggle.
- **Switch** — not used. Too colloquial, too ambiguous with "kill switch."

### 1.2 Rule vs strategy vs gate vs condition

- **Rule** (canonical) — one ordered entry in a ruleset. Matches a set of conditions and produces a value/variant/rollout outcome.
- **Condition** — a predicate inside a rule. `plan == "enterprise"` is a condition. A rule has 0..N conditions (ANDed).
- **Strategy** — how a matched rule produces a value: `:forced_value | :percentage_rollout | :variant_split | :segment_match`. Strategy is a field on a rule, not a top-level noun.
- **Gate** — NOT used. FunWithFlags uses "gate" for actor/group/percentage dimensions; rulestead's ordered-rules model deliberately replaces gate precedence with rule ordering. Banning "gate" from rulestead code/docs prevents FunWithFlags mental models leaking in.

### 1.3 Audience vs segment vs cohort vs identity

- **Audience** (canonical, user-facing) — a reusable targeting definition. The term surfaces in admin UI and docs. Every audience has a key, a description, and a definition (trait-based predicate OR explicit list).
- **Segment** (internal, implementation) — the schema table is `rulestead_audiences`, but within the evaluator, "segment" is acceptable when discussing the matching operation (`Segment.matches?/2`). Never surface "segment" in user-facing copy.
- **Cohort** — not a primary term. If used, it refers specifically to a *stable membership set* of actors (as in "the Q3 rollout cohort") rather than a reusable targeting rule. Prefer "audience" unless the temporal/immutable distinction matters.
- **Identity** — not used. Flagsmith calls actors "identities"; rulestead uses "actor" everywhere for symmetry with Phoenix/Ecto conventions.

### 1.4 Variant vs value vs payload

- **Variant** — one named option in a multivariate flag. Variants have a key (`:control`, `:treatment_a`), a value, and an optional weight.
- **Value** — the resolved output of evaluation. Always typed. `Rulestead.evaluate/3` returns a `%Rulestead.Result{value: ...}`.
- **Payload** — NOT used. "Payload" is too implementation-y and conflicts with audit-event `payload` JSONB field. Use "value" for user-facing terminology.

### 1.5 Rollout vs ramp vs release vs deployment

- **Rollout** (canonical) — the progressive expansion of a flag's exposure (0% → N% → 100%) over time and/or conditions. A flag has at most one active rollout at a time.
- **Rollout stage** — a single step in a scheduled rollout (`{pct: 10, at: ~U[...]}`).
- **Ramp** — acceptable informal synonym in docs; prefer "rollout" in code/UI.
- **Release** — *deployment* of software, not flag exposure. Don't conflate.
- **Deployment** — same; external to rulestead.

### 1.6 Experiment vs multivariate vs A/B test

- **Experiment** — a multivariate flag used to *measure* outcomes, wired to impressions + tracking hooks + external analytics. Rulestead ships the *primitives* for experiments (variant splits, impression events, tracking hooks), not the analytics/statistics layer. See §5 non-goals in `rulestead-security-privacy-and-threat-model.md` and the market-gap discussion in the research brief.
- **Multivariate flag** — a flag with >1 variant. Not all multivariate flags are experiments (remote config is multivariate but not an experiment).
- **A/B test** — colloquial; refer to it as "an experiment with N variants" in docs.

### 1.7 Kill switch vs emergency off vs hold

- **Kill switch** (canonical) — an immediate, flag-wide override that forces a specific variant (usually the safe default) regardless of rules. Requires operator confirmation + reason + audit row.
- **Engage** / **release** — the two verbs for kill switches. `KillSwitch.engage/3` takes a flag + actor + reason. `KillSwitch.release/3` takes a flag + actor + reason.
- **Hold** — pauses a rollout *without* overriding evaluation. Current variant stays sticky; rollout stage does not advance.
- **Emergency off** — not used. Say "kill switch."

### 1.8 Context vs actor vs subject vs user

- **Context** (canonical) — the full evaluation input. `%Rulestead.Context{actor, tenant, environment, attributes, request_id, session_id, strict?}`.
- **Actor** (canonical) — the entity whose experience the flag affects. Usually a user, but may be a service / job / machine / anonymous session. `%Rulestead.Actor{id, type, traits, tenant}`.
- **Subject** — NOT used in rulestead core. It appears in some OpenFeature docs but conflicts with audit-event `subject_type` / `subject_id` (which refers to the *thing being audited*, e.g. a flag or ruleset, not the actor).
- **User** — only when the actor is specifically a human user; prefer "actor" for generality.
- **Targeting key** (canonical) — the stable identifier used for deterministic bucketing. Usually the actor id, but can be overridden (e.g., bucket by `actor.tenant_id` when you want all users in a tenant to see the same variant).

### 1.9 Snapshot vs manifest vs state

- **Snapshot** — the in-memory compiled representation of all flags + rulesets + audiences for fast local evaluation. Versioned. Immutable. Refreshed via PubSub.
- **Manifest** — the *declarative source-of-truth document* (YAML/JSON) that flag-as-code teams commit in their repo and sync to rulestead. A manifest is imported; a snapshot is compiled.
- **State** — overloaded; avoid when snapshot or manifest applies.

### 1.10 Evaluation vs check vs resolve vs lookup

- **Evaluate** (canonical) — run the evaluator to produce a `%Rulestead.Result{}`. Primary verb.
- **Check** — user-facing convenience (`Rulestead.enabled?/2` — "check if enabled"). Short form of "evaluate and return the boolean value."
- **Resolve** — same meaning as evaluate; OpenFeature uses this. Acceptable synonym in bridge docs.
- **Lookup** — not used. Implies pure data fetching; evaluation is more than that.

### 1.11 Lifecycle states

- **Draft** — created, not yet activated.
- **Active** — being evaluated in the intended environment.
- **Archived** — no longer evaluated; kept for audit history.
- **Killswitched** — active but forcibly overridden by an engaged kill switch.
- **Potentially stale** — lifecycle cleanup flagged it as nearing `expected_lifetime_days`.
- **Stale** — past expected lifetime, no evaluations recently, surfaced in cleanup view.
- **Retired** — explicitly removed from production after cleanup.

---

## 2. Canonical nouns

Use these exact terms unless a cited spec requires a different wire name.

| Noun | Meaning | Plural |
|---|---|---|
| `Flag` | A named runtime decision point | `flags` |
| `Ruleset` | A versioned ordered list of rules for a flag | `rulesets` |
| `Rule` | One ordered evaluation unit inside a ruleset | `rules` |
| `Condition` | A predicate inside a rule | `conditions` |
| `Audience` | A reusable targeting definition | `audiences` |
| `Variant` | One named option in a multivariate flag | `variants` |
| `Rollout` | Progressive exposure of a flag over time | `rollouts` |
| `Rollout stage` | One step in a scheduled rollout | `rollout_stages` |
| `Kill switch` | Flag-wide emergency override | `kill_switches` |
| `Snapshot` | In-memory compiled eval manifest | `snapshots` |
| `Manifest` | Declarative flag-as-code source document | `manifests` |
| `Context` | Evaluation input envelope | `contexts` |
| `Actor` | Entity whose experience the flag affects | `actors` |
| `Tenant` | Organizational partition | `tenants` |
| `Environment` | Isolated runtime config space (dev/staging/prod) | `environments` |
| `Project` | Optional organizational boundary above environments | `projects` |
| `Namespace` | Optional partition within an environment (team/app) | `namespaces` |
| `Targeting key` | Stable identifier used for bucketing | `targeting_keys` |
| `Bucket` | Integer 0–10000 that determines rollout inclusion | `buckets` |
| `Impression` | A recorded evaluation that was actually exposed to a subject | `impressions` |
| `Exposure` | Synonym for impression (OpenFeature terminology); prefer impression | — |
| `Audit event` | An immutable record of an administrative change | `audit_events` |
| `Change request` | A proposed governed change awaiting approval | `change_requests` |
| `Scheduled change` | A future state mutation | `scheduled_changes` |
| `Approval` | A required signoff on a change request | `approvals` |
| `Reason` / `trace` | Structured explanation for a resolution | `reasons` |
| `Owner` | Team/person responsible for lifecycle | `owners` |
| `Lifecycle state` | `:active \| :potentially_stale \| :stale \| :archived \| :retired` | — |
| `Value type` | `:boolean \| :string \| :integer \| :float \| :json \| :variant` | — |
| `Flag type` | `:release \| :experiment \| :kill_switch \| :permission \| :remote_config \| :operational \| :migration` | — |

---

## 3. Canonical verbs

| Verb | Object | Notes |
|---|---|---|
| `evaluate` | flag, context | Primary eval verb |
| `check` | flag, context | User-facing shortcut for boolean eval |
| `resolve` | flag, context | Synonym for evaluate; OpenFeature bridge |
| `explain` | flag, context | Returns a trace, not a boolean |
| `simulate` | ruleset_draft, sample | Returns delta vs current active ruleset |
| `enable` | flag | Admin action |
| `disable` | flag | Admin action |
| `archive` | flag | Lifecycle transition |
| `retire` | flag | Post-cleanup removal |
| `create` | flag, ruleset, audience, rollout | |
| `update` | flag, ruleset, audience | |
| `publish` | ruleset | Transitions draft → active |
| `revert` | ruleset | Activates a prior version |
| `advance` | rollout | Move to next stage |
| `hold` | rollout | Pause without overriding |
| `roll back` | rollout | Return to prior stage / variant |
| `engage` | kill switch | Emergency override |
| `release` | kill switch | Clear emergency override |
| `schedule` | change, rollout | Plan a future mutation |
| `approve` | change request | Governance action |
| `reject` | change request | |
| `import` | manifest | From flag-as-code source |
| `export` | flag set | To manifest / snapshot |
| `sync` | manifest, snapshot | Push/pull inbound or outbound |
| `propagate` | snapshot | Distribute via PubSub to nodes |
| `invalidate` | cache | Force refresh |
| `refresh` | snapshot | Pull latest version |
| `override` | flag (per-request) | Dev/test context override |
| `track` | impression, conversion event | Analytics hook |
| `expose` | variant | User actually saw the variant |
| `diff` | ruleset versions, environments | Compare state |
| `bucket` | actor, rollout | Deterministic assignment |

---

## 4. Canonical events

Event names use snake_case for the file/json form and PascalCase for Elixir module form. Telemetry event tuples use the 4-level shape.

### 4.1 Flag lifecycle events

- `flag.created`
- `flag.updated`
- `flag.archived`
- `flag.retired`
- `flag.stale_marked`
- `flag.stale_cleared`

### 4.2 Ruleset events

- `ruleset.draft_created`
- `ruleset.published`
- `ruleset.reverted`
- `ruleset.simulated`

### 4.3 Rule events

- `rule.added`
- `rule.removed`
- `rule.reordered`
- `rule.condition_changed`

### 4.4 Audience events

- `audience.created`
- `audience.updated`
- `audience.archived`

### 4.5 Rollout events

- `rollout.created`
- `rollout.advanced`
- `rollout.held`
- `rollout.rolled_back`
- `rollout.completed`
- `rollout.scheduled`

### 4.6 Kill switch events

- `killswitch.engaged`
- `killswitch.released`

### 4.7 Evaluation events (runtime, high-volume; downsampled)

- `evaluation.resolved` (success)
- `evaluation.error` (exception)
- `evaluation.cache_hit`
- `evaluation.cache_miss`
- `evaluation.stale_used` (snapshot was stale but still served)
- `impression.recorded`

### 4.8 Snapshot / cache events

- `snapshot.published`
- `snapshot.applied`
- `cache.refreshed`
- `cache.invalidated`

### 4.9 Admin governance events

- `change_request.submitted`
- `change_request.approved`
- `change_request.rejected`
- `schedule.created`
- `schedule.triggered`

### 4.10 Ops / integration events

- `manifest.imported`
- `manifest.exported`
- `manifest.sync_failed`
- `webhook.received`
- `webhook.rejected_invalid_signature`
- `dlq.exhausted`

### 4.11 Telemetry event tuples

Structured form for `:telemetry.span/3`:

```elixir
[:rulestead, :eval, :decide, :start | :stop | :exception]
[:rulestead, :eval, :cache, :hit | :miss | :invalidate]
[:rulestead, :eval, :stale_used]
[:rulestead, :admin, :flag, :created | :updated | :archived]
[:rulestead, :admin, :ruleset, :published | :reverted | :simulated]
[:rulestead, :admin, :rollout, :advanced | :held | :rolled_back]
[:rulestead, :admin, :killswitch, :engaged | :released]
[:rulestead, :admin, :change_request, :submitted | :approved | :rejected]
[:rulestead, :snapshot, :published | :applied]
[:rulestead, :ops, :import, :applied | :failed]
[:rulestead, :ops, :export, :generated]
[:rulestead, :ops, :webhook, :received | :rejected]
[:rulestead, :ops, :dlq, :exhausted]
```

Full event catalog with metadata keys → `rulestead-telemetry-observability-and-audit.md`.

---

## 5. Naming guidance

### 5.1 `flag_key` vs `flag_name` vs `flag_id`

- **`flag_key`** — the stable user-authored string identifier (`"new_checkout"`). Used in evaluation API, URLs, manifest YAML, telemetry meta. Required, unique within `(owner_type, owner_id, tenant_id)`.
- **`flag_id`** — the UUIDv7 binary primary key. Database-internal; appears in audit events, FKs, admin URLs as a canonical anchor.
- **`flag_name`** — NOT used. "Name" conflicts with `description` (long) and `key` (short, machine-readable).
- **`display_name`** — optional human-friendly label for admin UI. Fallback to `key` if unset.

### 5.2 `actor` vs `user` vs `subject`

- Prefer **`actor`** everywhere. It generalizes to services, jobs, machines.
- When the actor is specifically a human, `actor.type == "user"`. Code may still pattern-match on `%Rulestead.Actor{type: "user"}`.
- **Never `subject`** — overlaps with audit event's `subject_type` / `subject_id` (which is the thing being audited, like a flag or ruleset).

### 5.3 `tenant` vs `org` vs `workspace` vs `account`

- Rulestead uses **`tenant`** in library code as the abstract partition.
- Host apps concretize via `Rulestead.Tenancy.scope/2` — may map to `Organization`, `Account`, `Workspace`, `Team`, or nothing (SingleTenant).
- In host-generated glue code, the concrete term (whatever the host's schema is named) wins. Library never refers to "organization" or "account" directly.

### 5.4 `attribute` vs `trait` vs `property` vs `claim`

- **`trait`** (canonical) — a key-value pair about an actor used in condition matching. `actor.traits.plan == "enterprise"`. Matches OpenFeature's `Targeting evaluation attributes`.
- **`attribute`** — acceptable synonym in OpenFeature-bridge docs, but `trait` is primary in code.
- **`property`** — NOT used; too generic.
- **`claim`** — auth/OIDC-coded; reserved for lockspire integration docs.

### 5.5 `segment` vs `audience`

- **Public-facing / admin / docs: `audience`**.
- **Internal evaluator / DB schema: `rulestead_audiences` table, but `Segment.matches?/2` function is acceptable** when discussing the match operation in isolation.
- Never flip this in user-facing copy.

### 5.6 `variant` vs `treatment` vs `arm`

- **`variant`** (canonical) — one option in a multivariate flag.
- **`treatment`** / **`arm`** — experiment-specific terminology from statistics; only use inside the experimentation module if/when built.

### 5.7 `rule` vs `rollout_rule` vs `targeting_rule`

- **`rule`** alone. Every rule is a rule. Context determines whether it's a percentage rule, a variant split rule, etc. — that's the `strategy` field, not the noun.

### 5.8 `evaluator` vs `engine` vs `decider`

- **`evaluator`** — the runtime subsystem that produces results.
- **`RuleEngine`** — the specific behaviour that ordered-rules evaluation is pluggable on top of.
- **`decider`** — NOT used; too marketing-coded.

### 5.9 Environment vs stage vs branch

- **`environment`** — the isolated config space. Conventional values: `"development"`, `"staging"`, `"production"`, `"test"`, plus host-chosen custom names.
- **`stage`** — reserved for rollout-stage (`{pct: 10, at: ...}`).
- **`branch`** — NOT used. Too git-coded; confusing.

---

## 6. Anti-terms (banned in rulestead code, docs, UI)

| Banned term | Why | Use instead |
|---|---|---|
| "Gate" | FunWithFlags precedence model leaks mental model | "Rule" |
| "Feature" (as a flag) | Flags *gate* features; not the same noun | "Flag" |
| "Toggle" (as generic flag) | Only use for boolean-release flags | "Flag" for the generic term |
| "Magic" | Marketing-coded, opaque | Name the mechanism explicitly |
| "Seamless" | Marketing-coded, promises undefinability | "Integrated," "auto-detected" |
| "Smart" | Marketing-coded | Describe the actual logic |
| "Realm" | Keycloak-coded; not our model | "Tenant" or "environment" |
| "Application auth" | Vague | Auth context (sigra) or OAuth client (lockspire) |
| "Identity" (as actor) | Flagsmith-coded | "Actor" |
| "Payload" (as value) | Internal / conflicts with audit payload | "Value" |
| "Subject" (as actor) | Conflicts with audit subject | "Actor" |
| "Emergency off" | Vague | "Kill switch" |
| "Experiment" (as any multivariate flag) | Reserves for measurement-wired flags | "Multivariate flag" |
| "A/B test" (in code / admin copy) | Informal | "Experiment with N variants" |
| "Ramp" (in code) | Informal | "Rollout" |
| "Switch" | Ambiguous with kill switch | "Flag" |
| "Gatekeeper" | Implies enforcement; we evaluate | "Evaluator" |
| "Smart targeting" | Marketing | "Rule-based targeting" |
| "Intelligent rollout" | Marketing | "Scheduled rollout" |

---

## 7. Phrasing in admin UI copy

Lockspire's operator-admin IA doc bans "marketing copy inside admin." Same rule here. Admin strings are:

- **Brief** — no sentences when a noun phrase works.
- **Calm** — no urgency-language ("⚠️ CRITICAL"). Severity badges carry tone.
- **Exact** — "Ruleset v3 active since 2026-04-22 14:31 UTC (by alice@)" beats "Recently published."
- **Low-anxiety** — confirmation dialogs name consequences plainly; no fear copy.
- **No marketing** — never write "Unlock powerful rollout controls." Never.

Examples:

| Bad | Good |
|---|---|
| "🚀 Flag is live and flying!" | "Active — 100% rollout, ruleset v4" |
| "Oops, something went wrong" | "Failed to publish — ruleset v5 validation error on rule 2 (unknown audience key)" |
| "Killswitch engaged! 🛑" | "Kill switch engaged 2m ago by alice@ — reason: 'degraded downstream vendor'" |
| "Awesome experiment results!" | "Experiment has 14,203 impressions across 3 variants since 2026-04-01" |
| "Click here to learn more about feature flags" | (link the word in context) |

---

## 8. Vocabulary locked by this doc

Before any phase plan can cite a term, it must already be in this doc. If a phase needs a new noun, verb, or event name:

1. Propose the term in the phase's `NN-DISCUSSION-LOG.md`.
2. Check it doesn't conflict with an anti-term.
3. Add it to this field guide in the same phase PR.
4. Ban the prior (if any) in admin copy and code comments.

This is how drift is prevented. Vocabulary-first planning is cheaper than vocabulary-repair refactoring.

---

## 9. Cross-reference — where each term surfaces

| Term | Schema column | Public API | Telemetry meta | Admin UI label | Guide filename |
|---|---|---|---|---|---|
| `flag_key` | `rulestead_flags.key` | `Rulestead.evaluate(:key, ctx)` | `flag_key` | "Flag key" | `flows/evaluation.md` |
| `ruleset` | `rulestead_rulesets` | `Rulestead.Rulesets.publish/3` | `ruleset_version` | "Ruleset" | `flows/rulesets.md` |
| `audience` | `rulestead_audiences` | `Rulestead.Audiences.create/2` | `audience_key` | "Audience" | `flows/rulesets.md` (segments section) |
| `rollout` | `rulestead_rollouts` | `Rulestead.Rollouts.advance/4` | `rollout_pct` | "Rollout" | `flows/rollout.md` |
| `actor` | (host-owned) | `%Rulestead.Actor{}` | `actor_id_digest` | "User" (if user-type) or "Actor" | `flows/evaluation.md` |
| `context` | — | `%Rulestead.Context{}` | `tenant_id`, `environment` | — | `flows/evaluation.md` |
| `targeting_key` | — | `context.targeting_key` | `has_targeting_key?` | "Targeting key" | `flows/rollout.md` |
| `impression` | `rulestead_events` (type=`impression.recorded`) | `Rulestead.Hooks` | `flag_key`, `variant` | "Impressions" | `recipes/telemetry.md` |
| `audit event` | `rulestead_events` | `Rulestead.Audit.timeline/2` | `event_type` | "Timeline" | `flows/audit.md` |
| `kill switch` | `rulestead_flags.status = :killswitched` | `Rulestead.KillSwitch.engage/3` | `killswitch_engaged?` | "Kill switch" | `flows/rollout.md` |
| `manifest` | (file) | `Rulestead.Manifest.import/2` | `manifest_source` | "Manifest sync" | `flows/manifest-sync.md` |

---

## 10. TL;DR — the vocabulary you will type the most

Every sentence you write about rulestead will contain one of these. Pick them from this doc, not your head.

- **Flag** — decision point
- **Rule** — one ordered match unit
- **Audience** — reusable targeting definition
- **Variant** — one named value option
- **Rollout** — progressive exposure
- **Kill switch** — emergency override
- **Actor** — entity whose experience is affected
- **Context** — evaluation input envelope
- **Targeting key** — stable bucketing identifier
- **Snapshot** — in-memory compiled manifest
- **Evaluate** — primary verb
- **Explain** — return a trace
- **Simulate** — preview a ruleset change
- **Impression** — recorded evaluation exposure
- **Audit event** — immutable admin change record
- **Tenant** — organizational partition
- **Environment** — isolated runtime config space

If you find yourself reaching for a word not in this guide, stop and come back here. Feature-flag vocabulary is load-bearing for every other doc — get it right once, reuse everywhere.

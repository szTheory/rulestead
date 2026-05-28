# Footguns

Patterns that look convenient but break trust, determinism, or support claims. Rulestead intentionally avoids several of them.

## Missing or unstable targeting_key

Percentage and variant rollouts hash `(flag_key, rule_key, salt, targeting_key)`. Without a stable `targeting_key`, the same actor can flip between buckets across requests.

**Do:** set `targeting_key` from a durable user or account id.

**Don't:** rely on random per-request keys or omit the key in strict mode.

## First-match rule order surprises

Rules are evaluated top-to-bottom; the first match wins. Broad rules above specific ones silently override intent.

**Do:** put specific rules first, defaults last; use explain to verify.

**Don't:** assume “all matching rules merge.”

## Payload-first vs keyed runtime confusion

| API | Use when |
|-----|----------|
| `Rulestead.evaluate(flag_payload, context)` | Tests, simulations, you already have the payload |
| `Rulestead.Runtime.enabled?(env, flag_key, context)` | Phoenix app with snapshot cache and environment key |

**Don't:** call `Rulestead.enabled?("flag_key", conn)` — the root module expects `(flag_payload, context)`, not a string key on `%Plug.Conn{}`.

Build context from Plug assigns (see [context propagation](context-propagation.md)), then use `Rulestead.Runtime` for keyed lookup.

## Percentage-of-time rollouts

Time-random percentage gates change outcome per request. Rulestead does not ship this as a first-class rollout type.

**Do:** percentage-of-actors with stable `targeting_key`.

## Treating preview evidence as census data

Impact previews declare **preview basis** and uncertainty. Host-supplied sample cohorts and impression summaries are bounded and redacted.

**Don't:** tell operators “X users affected” unless the host supplied an explicit, bounded summary — and never use impression richness to change blast-radius governance (GOV-05).

## Guardrails as an observability product

Guarded rollouts consume **host-supplied, normalized** guardrail facts. Rulestead does not ingest metrics warehouses or run statistical tests.

**Do:** wire `Guardrails.Provider` with fail-closed semantics.

**Don't:** expect built-in dashboards or automatic population health claims.

## Snapshot cache before readiness

Evaluation against an empty or stale snapshot can mislead in tests and boot races.

**Do:** follow supervision and refresh docs; use Fake adapter in unit tests without Postgres.

## Lifecycle heuristics as auto-archive

Stale guidance and archive-readiness hints are **advisory**. Rulestead does not delete flags or remove code references automatically.

## FunWithFlags migration assumptions

FunWithFlags is boolean-centric with ETS + persistence. Rulestead adds multivariate values, ordered rules, explain, and governance — migration is intentional, not drop-in for every call site.

See [migrating from FunWithFlags](migrating-from-funwithflags.md).

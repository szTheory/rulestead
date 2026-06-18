# Troubleshooting

This is the symptom-first companion to the conceptual [footguns](footguns.md) guide. When something is misbehaving at 3am, start here: each pattern is indexed by what you observe, then walks **Symptom → Cause → Fix → Verify** using only shipped, supported seams.

The tone is deliberately blame-free — these are situations the system can land in, not operator mistakes. Where a pattern overlaps a deeper concept, it links to footguns for the "why" rather than restating it, so this guide stays focused on the shortest path from symptom to a verified fix. Each "Verify" step names a public observable — a telemetry event, a `Rulestead.Runtime.diagnostics/1` field, a `%Rulestead.Result{}` reason, or a `%Rulestead.Error{}` type — so you can confirm the fix landed without reaching into internals.

## Flags evaluate but installation or migration seems incomplete

**Symptom:** A fresh integration raises `%Rulestead.Error{type: :repo_not_configured}` or `%Rulestead.Error{type: :store_not_configured}`, or evaluation returns nothing because the package tables are absent.

**Cause:** The installer step or the Ecto migration has not run yet, so the authoring schema the runtime reads from does not exist in this environment.

**Fix:** Run the installer, then apply the generated migrations with the same repo your host app uses:

```bash
mix rulestead.install
mix ecto.migrate
```

Package-owned tables land in the `rulestead` Postgres schema; no special `search_path` is needed. See the [deployment](deployment.md) recipe for ordering migrations inside a real deploy.

**Verify:** Re-run your evaluation path. A correctly configured install stops surfacing `%Rulestead.Error{type: :repo_not_configured}` / `:store_not_configured` and the authoring tables are present for snapshot publication.

## Evaluation returns an unexpected shape or rejects your arguments

**Symptom:** A call you expected to answer "is this on for this actor?" instead returns a full result payload, or raises because the arguments do not match — often after passing a string flag key where a payload or context was expected.

**Cause:** There are two distinct entry points. `Rulestead.evaluate/3` is the payload-first evaluator (you already hold the flag payload); `Rulestead.Runtime.enabled?/3` is the keyed runtime lookup for a Phoenix app backed by the snapshot cache and an environment key. Reaching for one while expecting the other's signature produces the mismatch.

**Fix:** For a keyed lookup against the live snapshot, use the runtime surface with `(environment, flag_key, context)`:

```elixir
{:ok, enabled?} =
  Rulestead.Runtime.enabled?(context.environment, "checkout-redesign", context)
```

Use `Rulestead.evaluate/3` only when you already have the flag payload (tests, simulations). For the conceptual distinction and the exact anti-call to avoid, see [footguns](footguns.md#payload-first-vs-keyed-runtime-confusion).

**Verify:** The keyed call returns the boolean tuple shape shown above; the payload call returns a `%Rulestead.Result{}`. Matching the right return shape to the call site confirms you are on the intended seam.

## Evaluation looks empty or stale right after a node boots

**Symptom:** Immediately after a deploy or node restart, evaluations return defaults or raise `%Rulestead.Error{type: :snapshot_not_found}`, then recover on their own a moment later.

**Cause:** The node booted before its snapshot was populated or refreshed. This is the expected degraded-mode window, not a failure — the runtime is designed to tolerate startup-order imperfections and serve last-known-good or defaults until refresh completes.

**Fix:** Lean on supervision and refresh ordering rather than request-time fallbacks. Follow the [deployment](deployment.md) recipe's degraded-mode expectations: assume a node may boot before the store is reachable and may briefly serve defaults, and observe refresh health explicitly in ops tooling instead of switching to ad-hoc SQL lookups during the window. For why an empty or stale snapshot can mislead, see [footguns](footguns.md#snapshot-cache-before-readiness).

**Verify:** Call `Rulestead.Runtime.diagnostics/1` and inspect the `infrastructure_health` and `environments` fields — once refresh has landed, the environment reports healthy and `%Rulestead.Error{type: :snapshot_not_found}` stops appearing.

## Rollouts flip per request or report a missing targeting key

**Symptom:** The same actor bounces between variants across requests, or a result carries `reason: :targeting_key_missing`.

**Cause:** Context is not being propagated end-to-end, so a stable `targeting_key` never reaches evaluation. Percentage and variant rollouts hash on the targeting key; without a durable one, bucketing is unstable.

**Fix:** Build and forward `%Rulestead.Context{}` explicitly at each boundary using the supported propagation seams: `Rulestead.Plug` (or `Rulestead.Phoenix.context_from_conn/2`) in the request pipeline, `Rulestead.LiveView.assign_flags/3` into LiveView, and `Rulestead.Oban.Middleware.attach/2` into background jobs. The [context propagation](context-propagation.md) recipe shows the full chain. For why a stable `targeting_key` matters, see [footguns](footguns.md#missing-or-unstable-targeting_key).

**Verify:** Inspect the `%Rulestead.Context{}` `targeting_key` at the evaluation site — once it is populated and stable per actor, results stop returning `reason: :targeting_key_missing` and bucketing holds steady across requests.

## Admin actions return 403 / unauthorized

**Symptom:** An operator action fails with `%Rulestead.Error{type: :unauthorized}` (domain `:auth`, carrying a `plug_status`).

**Cause:** The host actor does not map to a Rulestead operator role with the action they attempted. Authorization is the host's responsibility — Rulestead does not ship a bundled auth stack; it maps host actors onto the canonical operator role model and the specific workflow actions allowed.

**Fix:** Resolve the action against the policy surface in your `can?/4` implementation, and compare the attempted action to the role catalogs `Rulestead.Admin.Policy.viewer_actions/0`, `Rulestead.Admin.Policy.editor_actions/0`, `Rulestead.Admin.Policy.admin_actions/0`, and `Rulestead.Admin.Policy.governance_actions/0`. Grant the actor a role whose catalog includes the action, or adjust the host mapping so `Rulestead.Admin.Policy.can?/4` returns an allow for that actor. Authorization decisions remain host-owned (see the [product boundary](../introduction/product-boundary.md)).

**Verify:** Re-attempt the action with a correctly mapped actor; an authorized path no longer surfaces `%Rulestead.Error{type: :unauthorized}`, and the action's `plug_status` reflects success rather than a denied request.

## A mutation is blocked pending a change request

**Symptom:** A mutation that normally applies is held back, and an operator reports it cannot proceed even though they appear authorized.

**Cause:** Governance policy requires a change request for this mutation in this environment. The `Rulestead.Admin.Policy.change_request_required?/4` callback returned true, so the apply is gated behind review rather than landing directly.

**Fix:** Route the mutation through your governance flow: confirm whether `Rulestead.Admin.Policy.change_request_required?/4` is intended to gate this environment, and have the change reviewed and applied through that governed path instead of expecting a direct write. The gating is policy-driven, so adjust the policy if a given environment should not require review — otherwise treat the block as the review step working as designed.

**Verify:** Observe the `[:rulestead, :admin, :mutation, :stop]` telemetry event for the attempted mutation — a change-request-gated attempt surfaces as a blocked-mutation outcome on that event, which confirms the governance path (not an error) is what stopped the write.

## OpenFeature reads look stale after a Redis-backed change

**Symptom:** Consumers reading through the `open_feature_rulestead` provider see an outdated value for a short window after a change, then converge.

**Cause:** The runtime served a cached snapshot whose freshness lags the latest authored state — an expected cache window, surfaced rather than hidden. The provider is only the consumer boundary; the freshness behavior belongs to the runtime cache.

**Fix:** Treat this as a snapshot-freshness window. The operational refresh outcome is to bring the latest runtime snapshots into the cache (the `mix rulestead.redis.sync` task exists for this refresh outcome); after refresh, consumers reading through `open_feature_rulestead` see the current value. For why readiness and snapshot timing matter, see [footguns](footguns.md#snapshot-cache-before-readiness).

**Verify:** Watch the public cache telemetry events — `[:rulestead, :runtime, :cache, :stale_used]` firing indicates a stale read served, while `[:rulestead, :runtime, :cache, :miss]` and `[:rulestead, :runtime, :cache, :refresh]` show the refresh cycle. Once `Result.cache_age_ms` drops back to a fresh value, the staleness window has closed.

---

**Where to go next.** If none of the seven patterns above matches your symptom, the conceptual [footguns](footguns.md) guide explains the design choices behind targeting keys, rule order, snapshot readiness, and preview semantics — most surprises trace back to one of those. For propagation specifics, see the [context propagation](context-propagation.md) recipe; for boot-order and refresh posture, see the [deployment](deployment.md) recipe. When you do need to escalate, the public telemetry contract plus `Rulestead.Runtime.diagnostics/1` give you an auditable picture of runtime health without scraping internal process or table names.

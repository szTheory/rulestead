# Why Rulestead?

> **Runtime decisions, made clear.**

Rulestead is an Elixir-native feature-management runtime and self-hostable
Phoenix control plane: deterministic evaluation, explainable decisions, and an
admin UI calm enough to trust at 3am.

---

## The problem

Shipping safely gets harder as a Phoenix application matures. A few booleans
become a tangled web of conditionals. You inherit toggles nobody owns,
environments that have quietly drifted, and a dashboard that tells you *what*
is on but never *why* a specific user saw it.

Experiments outgrow booleans. Operational changes become hard to reason about.
Flag debt accumulates. At 3am, "is it safe to roll this back?" should not be a
research project.

---

## Why the usual answers fall short

**Roll your own.** Every team can build flags. Few can afford to maintain
explainability, governance, lifecycle hygiene, and a calm operator UI *forever*.
That is a sub-project disguised as a chore.

**Stay on boolean toggles.** An excellent starting point — until you need typed
values, variants, ordered rules, or to answer "why did this resolve this way?"
The model runs out before your product does.

**Reach for an external SaaS platform.** Powerful, but now your runtime
decisions depend on a service outside the BEAM, your user data leaves your
application, and self-hosting is someone else's roadmap.

---

## What you get with Rulestead

Rulestead gives Phoenix teams a fast, pure, local evaluator for booleans,
variants, and remote config — decisions resolve deterministically from ordered
rules with stable bucketing, and every result can explain exactly why it
resolved the way it did.

When you need more than evaluation, the optional `rulestead_admin` package
mounts inside your own Phoenix application: rollouts, kill switches, change
requests, audit, audience targeting, and lifecycle cleanup — governed by your
auth, deployed on your infrastructure.

It is the feature-management platform serious Elixir teams would have built
in-house, without the in-house maintenance burden.

### What you get at a glance

| Concern | What Rulestead delivers |
|---------|-------------------------|
| Runtime evaluation | Pure `Rulestead.evaluate/3` — deterministic, ordered rules, typed values |
| Explainability | Every result carries the matched rule, bucket, and snapshot version |
| Control plane | `rulestead_admin` mounts in your Phoenix app — your auth, your Postgres |
| Governance | Change requests, approvals, protected-environment controls, lifecycle hygiene |
| Safe rollout | Progressive percentages, kill switches, guarded rollouts with host signals |
| Testing | `Rulestead.TestHelpers` Fake adapter — no Postgres required in CI |

---

## The 60-second mental model

Evaluation is a pure local function:

```elixir
context =
  Rulestead.Context.new(
    environment: "production",
    targeting_key: "user-123",
    attributes: %{plan: :pro}
  )

flag_payload = ...  # from snapshot or store

with {:ok, result} <- Rulestead.evaluate(flag_payload, context) do
  result.enabled?  #=> true
  result.reason    #=> matched rule 3 (plan == :pro), bucket 4721
end
```

The runtime reads a snapshot it already holds in memory. No network call, no
database read, no shared state on the hot path. Bucketing is stable: the same
`targeting_key` always lands in the same bucket, so your users do not flicker
between variants.

### Payload-first vs cached lookup

| Approach | When to use |
|----------|-------------|
| `Rulestead.evaluate/3` with a payload you supply | Pure evaluation contracts, tests, projections, batch jobs |
| `Rulestead.Runtime` keyed lookup | Phoenix request path — let the snapshot cache resolve by `{environment, flag_key}` |

Both paths are part of the stable 1.x contract. See
[Evaluation](../flows/evaluation.md) for the full flow.

---

## What Rulestead is — and is not

Rulestead is a focused runtime and mounted control plane. It does not try to be
everything.

**Rulestead is:**
- A deterministic, pure, local evaluator for Elixir and Phoenix systems.
- A self-hostable admin companion that mounts inside your app.
- A library with a stable 1.x public contract and a published deprecation policy.
- Phoenix-native: Plug, LiveView, Oban seams; BEAM-resident evaluation.

**Rulestead is not:**
- A hosted Rulestead Cloud — you run your own Postgres and Phoenix.
- A stats engine or analytics warehouse — impression hooks only; analytics lives in your warehouse.
- A standalone fleet control plane — the admin mounts inside your app.
- A percentage-of-time rollout system — stable actor bucketing is the default; percentage-of-time is a footgun by design.

For the full, precise scope boundary see
[Product Boundary](product-boundary.md) — it states exactly what v1.x ships,
what the host always owns, and what is explicitly deferred.

---

## Will this be maintained?

Yes. Concretely:

- **API frozen and versioned.** The public surface is locked as-is for 1.x
  patch releases. The six-function evaluation catalog in
  [API Stability](../api_stability.md) is now a Hex SemVer promise, not a
  moving target. Breaking changes require a major bump and a migration path.
- **Published deprecation policy.** Symbols are soft-deprecated in docs first;
  hard deprecation requires a cycle and a tested migration path. The full policy
  is in [API Stability](../api_stability.md).
- **Maintainer runbook.** [MAINTAINING.md](../../MAINTAINING.md) documents
  the release process, CI gates, the verification trio, and the major-bump
  runbook. The process is transparent and auditable.
- **Verification trio on every release.** `release_contract_test.exs`, `mix
  docs --warnings-as-errors`, and `mix dialyzer` must all pass before a
  release is cut. The CI status badge reflects the current state.
- **Honest 1.0 story.** This is a promotion, not a debut. Rulestead has been
  API-frozen, RBAC-complete, and governance-rich through an internal v1.x band
  of real rollout, audience, lifecycle, and reliability hardening. The Hex
  version line (`0.1.x`) had stopped telling the truth about that maturity.
  1.0 corrects the record — and from here, SemVer is the public contract.

---

## Next steps

- **[Getting Started](getting-started.md)** — 15-minute path from deps to your first flag flip.
- **[Phoenix Integration Spine](phoenix-integration-spine.md)** — supervision → Plug → Runtime → lifecycle-honest flag create.
- **[API Stability](../api_stability.md)** — the 1.x contract, versioning policy, and deprecation rules.
- **[Product Boundary](product-boundary.md)** — full scope: what v1.x ships, what the host owns, what is deferred.
- **[Upgrading](upgrading.md)** — the 0.1.x → 1.0 mapping (mechanical; the surface is identical).

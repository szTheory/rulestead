# Rulestead

> **Runtime decisions, made clear.**
> Typed feature flags, variants, and remote config for Elixir apps, with an
> optional mounted Phoenix LiveView admin.

> **Release truth:** repo GA shipped in `v1.0.0` on 2026-05-21. The current
> installable sibling-package line remains `0.1.0`, so adopters should depend
> on the `0.1.x` Hex packages while using this repo's `v1.0.0` milestone docs
> as the support and proof posture reference.

## What this is (60 seconds)

Rulestead ships as two sibling Hex packages:

- `rulestead` for the runtime evaluator, installer, context builders, and test helpers
- `rulestead_admin` for the optional host-mounted admin UI

The runtime promise is simple: evaluation stays deterministic, rule precedence
is explicit, and operators can explain why a decision happened without reverse
engineering application state.

## 15-minute quickstart

Start with the runtime package:

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"}
  ]
end
```

Install and migrate:

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

Gate a code path:

```elixir
if Rulestead.enabled?("checkout_v2", conn) do
  render_v2(conn)
else
  render_v1(conn)
end
```

If your Phoenix app also needs the mounted companion admin, add
`rulestead_admin` immediately after the runtime dependency:

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:rulestead_admin, "~> 0.1"}
  ]
end
```

Mount the admin UI only if your app needs it:

```elixir
import RulesteadAdmin.Router

scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```

The canonical install-path split lives in
[Installation](guides/introduction/installation.md), which keeps the
runtime-first path as the default and the mounted companion as the next step.

The guided walkthrough continues in
[Getting Started](guides/introduction/getting-started.md).
If you want the fast product mental model first, read
[User Flows and JTBD](guides/introduction/user-flows-and-jtbd.md).
If you want the lifecycle operator story, read
[Flag Lifecycle](guides/flows/flag-lifecycle.md) for the canonical flag from
birth to retirement guide.

## Choose your path

### Build with Rulestead

Use the runtime package to evaluate booleans, variants, and typed values from
controllers, LiveViews, jobs, or explicit `%Rulestead.Context{}` structs.

- Start with [Installation](guides/introduction/installation.md)
- Continue with [Getting Started](guides/introduction/getting-started.md)
- Read [Flag Lifecycle](guides/flows/flag-lifecycle.md) for the canonical
  birth to retirement operator path
- Read [User Flows and JTBD](guides/introduction/user-flows-and-jtbd.md) for the
  cross-role mental model
- Go deeper with [Evaluation](guides/flows/evaluation.md),
  [Rulesets](guides/flows/rulesets.md), and
  [Testing](guides/recipes/testing.md)

### Operate via Admin UI

Use the optional `rulestead_admin` package when a host Phoenix app needs a
mounted operator surface with host-owned authorization and environment-aware
URLs.

- Start with [rulestead_admin/README.md](rulestead_admin/README.md)
- Read [Flag Lifecycle](guides/flows/flag-lifecycle.md) for the shared
  lifecycle narrative across runtime, CLI, and mounted admin
- Continue with [Admin UI](guides/flows/admin-ui.md),
  [Explainability](guides/flows/explainability.md), and
  [Multi-environment usage](guides/flows/multi-env.md)

### Extend Rulestead

Use the shared docs and repo conventions when you are changing the library
itself or integrating it into a larger release process.

- Read [CONVENTIONS.md](CONVENTIONS.md)
- Read [CONTRIBUTING.md](CONTRIBUTING.md) and [MAINTAINING.md](MAINTAINING.md)
- Use [Telemetry](guides/flows/telemetry.md) and
  [Context propagation](guides/recipes/context-propagation.md) as the current
  contract docs

## Why teams adopt it

- Deterministic evaluation and sticky bucketing for predictable rollouts
- Ordered rules with first-match-wins precedence
- Explainable decisions for support, operators, and incident response
- Test helpers and fake-backed workflows that do not require Postgres in the hot loop
- A sibling-package layout so runtime-only apps do not carry LiveView admin weight

## Repository layout

- `rulestead/` — runtime package
- `rulestead_admin/` — optional admin package
- `examples/demo/` — Phase 28 local demo backend/frontend stack
- `guides/` — shared HexDocs guides
- `prompts/` — product and engineering reference docs

## Local demo

## Proof today

The repo's current proof posture is intentionally bounded:

- `examples/demo/` is the primary runnable end-to-end proof path.
- `RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh`
  proves guarded rollout foundations: host-supplied normalized guardrail facts
  with explicit threshold, freshness, and sample-size semantics; fail closed
  outcomes for `pending_data`, `held`, and `rollback_triggered`; audited hold
  and rollback decisions; mounted status inside the existing workflow; and
  drift guards for the support truth in these docs.
- **Reusable targeting deepening (v1.6):** `cd rulestead && mix verify.phase56`
  proves dependency inventory, preview determinism, stale preview fingerprint
  rejection (`audprev_`), fail-closed missing/archive/incompatible references,
  audit evidence, explain trace carry-through, and promotion/manifest
  dependency blockers. Impact previews use **preview basis** (authored state ±
  **explicit samples**); they do not claim exact affected-user or population
  counts — previews carry **uncertainty** by design. **Audience**
  workflows respect explicit **environment scope** and **tenant scope**
  (`?env=`, `tenant_key`); same-name audiences are not assumed equivalent
  across scope. Mutations follow **preview → confirm → audit** and **fail
  closed** on stale or mismatched references. Identity and observability remain
  **host-owned**; the mounted companion presents core truth — not a standalone
  admin product.
- `RULESTEAD_TEST_SCOPE=reusable_targeting_deepening bash scripts/ci/test.sh`
  reruns the v1.6 reusable targeting deepening proof bar in CI.
- `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` proves the
  optional `open_feature_rulestead` companion package's Elixir provider contract:
  `context_mapper_test` and `provider_test`.
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` proves the
  repaired mounted companion contract surface around mounted session truth,
  mount behavior, canonical `?env=` routing, lifecycle transitions, and
  permission-gated cleanup behavior.
- `mix verify.release_publish <version>` proves published-consumer install and
  HexDocs reachability for the shipped `0.1.0` package line.
- `mix verify.release_parity <version>` proves the tagged release and Hex
  tarball stay in sync.

Anything beyond those seams should be read as current guidance rather than a
broader closed support guarantee. In particular, the OpenFeature companion bar
proves the package-local Elixir provider only, and the mounted companion proof
bar is intentionally narrower than "all admin behavior is green."
For the exact mounted host-package contract, including fail-closed prerequisites
and environment-selection rules, use
[rulestead_admin/README.md](rulestead_admin/README.md). For the maintainer
rerun path and CI gate semantics, use [MAINTAINING.md](MAINTAINING.md).

## Guarded rollout foundations

Guarded rollout support is intentionally host-owned and bounded. Hosts supply
normalized guardrail facts; Rulestead records deterministic decisions from
those facts using explicit threshold, freshness, and sample-size semantics.
Missing, stale, unsupported, or undersampled facts fail closed into
`pending_data` or `held`, while breached facts can produce
`rollback_triggered` only when a recorded stable rollback target exists.

The current support promise covers audited hold and rollback behavior plus
mounted status inside the existing workflow. It does not make Rulestead a
metrics collector, dashboard system, provider-integration catalog, experiment
analysis engine, or package-owned rollout operator. Maintainers can rerun the
bounded proof with:

```bash
RULESTEAD_TEST_SCOPE=guarded_rollout_foundations bash scripts/ci/test.sh
```

The runnable local demo lives under `examples/demo/`:

```bash
docker compose up --build
```

That boots Postgres, Redis, the Phoenix demo backend at `http://localhost:4000`,
the mounted Admin sign-in route at `http://localhost:4000/demo/sign-in`, and the
Next.js sample frontend at `http://localhost:3000`.

The shortest end-to-end proof is:

1. Open `http://localhost:3000` and confirm `The new operator cockpit is live.`
2. Open `http://localhost:4000/demo/sign-in`.
3. In the Admin UI, engage the kill switch for `enable-new-dashboard` in `staging`.
4. Confirm the frontend flips to `The classic cockpit is holding.`

See [examples/demo/README.md](examples/demo/README.md) for the smoke script and
browser automation path.

## Versioning and upgrade posture

Repo GA shipped in `v1.0.0` on 2026-05-21, while the installable sibling
packages currently remain on the `0.1.0` line. Treat that package line as the
current public consumer surface and use
[Upgrading](guides/introduction/upgrading.md) for the longer compatibility and
support-truth explanation.

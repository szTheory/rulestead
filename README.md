# Rulestead

> **Runtime decisions, made clear.**
> Typed feature flags, variants, and remote config for Elixir apps, with an
> optional mounted Phoenix LiveView admin.

> **Release truth:** repo GA shipped in `v1.0.0` on 2026-05-21. The current
> installable sibling-package line on Hex is **`0.1.3`** (`~> 0.1`). Repo
> milestones (`v1.0.0`–`v1.11`) and Hex semver are intentionally separate —
> use milestone docs here for support and proof posture.

## Post-GA band (v1.1–v1.9 complete)

The post-GA release-control band is **feature-complete** for serious Phoenix SaaS adopters:

- Tenancy helpers, lifecycle hygiene, guarded rollouts (hold/rollback + auto-advance)
- Reusable audiences with impact previews, blast-radius governance, host-supplied preview evidence

**v1.10.1** and **v1.11** close support truth and the first-hour Phoenix integration spine (docs and proof bars) — not new product APIs.
Optional v2 deepening (presets, baseline comparison, threshold profiles) is listed in
[product-boundary.md](guides/introduction/product-boundary.md).

**Prove it locally:** `scripts/demo/proof.sh`, [Adoption Lab](guides/introduction/adoption-lab.md), or `cd rulestead && mix verify.adopter`.

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

**Phoenix integrators:** follow the
[Phoenix Integration Spine](guides/introduction/phoenix-integration-spine.md)
for supervision → Plug → `Rulestead.Runtime` → lifecycle-honest flag create.

Gate a code path (payload-first — see [evaluation.md](guides/flows/evaluation.md)):

```elixir
context =
  Rulestead.Context.new(
    environment: "production",
    targeting_key: "user-123",
    attributes: %{plan: :pro}
  )

flag_payload = ... # from snapshot or store

with {:ok, result} <- Rulestead.evaluate(flag_payload, context) do
  if result.enabled? do
    render_v2(conn)
  else
    render_v1(conn)
  end
end
```

When using Phoenix with the snapshot cache, load the flag by environment key via
`Rulestead.Runtime` (see [evaluation.md](guides/flows/evaluation.md) and
[multi-env.md](guides/flows/multi-env.md)):

```elixir
context = conn.assigns[:rulestead_context]

{:ok, enabled?} =
  Rulestead.Runtime.enabled?("production", "checkout_v2", context)
```

The explicit contract remains flag payload + `%Rulestead.Context{}` for
`Rulestead.evaluate/3` and projection helpers on the root module.

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
Playwright path.

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
- **Blast radius governance (v1.7):** `cd rulestead && mix verify.phase60`
  proves threshold evaluation in protected environments, change-request
  proposal and execute for high-blast-radius audience mutations, stale-preview
  rejection, fail-closed behavior on missing or indeterminate inputs, and audit
  evidence. Previews use **preview basis** (authored references and **explicit
  samples** only) — they do not claim affected-user or population counts.
  Protected-environment mutations above threshold route through **change request**
  review; below-threshold mutations remain eligible for direct apply with fresh
  preview confirmation. **Host-owned policy** governs authorization; the mounted
  companion presents core truth — not a standalone admin product.
- `RULESTEAD_TEST_SCOPE=blast_radius_governance bash scripts/ci/test.sh`
  reruns the v1.7 blast radius governance proof bar in CI.
- **Guarded rollout auto-advance (v1.8):** `cd rulestead && mix verify.phase64`
  proves opt-in per-rollout auto-advance policy with **observation window** and
  **authored next-stage plan**, healthy scheduled-tick advance, fail-closed
  non-advance on weak or stale signals, protected-environment **change request**
  routing at tick execute, idempotency under concurrent manual advance, and
  mounted admin presentation of pending observation state. Timeline entries
  distinguish **`guardrail_automation`** from manual actions. Metrics and signal
  facts remain **host-owned**; Rulestead evaluates normalized facts only — not a
  package-owned observability stack or metrics product.
- `RULESTEAD_TEST_SCOPE=guarded_rollout_auto_advance bash scripts/ci/test.sh`
  reruns the v1.8 guarded rollout auto-advance proof bar in CI.
- **Host preview evidence (v1.9):** `cd rulestead && mix verify.phase68`
  proves bounded **host-supplied** sample cohort and impression summary on
  audience impact previews when the host configures
  `:preview_evidence_resolver`; resolver is opt-in; previews use
  **preview basis** and `authoritative_population_count?: false`; invalid or
  policy-denied evidence **fail closed**.
- `RULESTEAD_TEST_SCOPE=host_preview_evidence bash scripts/ci/test.sh`
  reruns the v1.9 host preview evidence proof bar in CI.
- **Post-GA band closure (v1.12):** `cd rulestead && mix verify.adopter` (alias:
  `mix verify.phase82`) runs the v1.12 adopter bar: v1.10.1 support-truth
  contracts, integration-spine doc checks, and adoption-lab contract guards. See
  [Adoption Lab](guides/introduction/adoption-lab.md) and
  [Phoenix Integration Spine](guides/introduction/phoenix-integration-spine.md).
  `RULESTEAD_TEST_SCOPE=post_ga_band_closure bash scripts/ci/test.sh`
  reruns that bar in CI. `scripts/demo/proof.sh` runs demo smoke + band verify.
  `RULESTEAD_TEST_SCOPE=install_journey bash scripts/ci/test.sh` runs the
  fresh-install golden-diff journey.
- `RULESTEAD_TEST_SCOPE=openfeature_companion bash scripts/ci/test.sh` proves the
  optional `open_feature_rulestead` companion package's Elixir provider contract:
  `context_mapper_test` and `provider_test`.
- `RULESTEAD_TEST_SCOPE=mounted_admin_contract bash scripts/ci/test.sh` proves the
  repaired mounted companion contract surface around mounted session truth,
  mount behavior, canonical `?env=` routing, lifecycle transitions, and
  permission-gated cleanup behavior.
- `mix verify.release_publish <version>` proves published-consumer install and
  HexDocs reachability for the shipped `0.1.x` package line (currently `0.1.3`).
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

## Versioning and upgrade posture

Repo GA shipped in `v1.0.0` on 2026-05-21, while the installable sibling
packages currently remain on the `0.1.0` line. Treat that package line as the
current public consumer surface and use
[Upgrading](guides/introduction/upgrading.md) for the longer compatibility and
support-truth explanation.

# rulestead

`rulestead` is the runtime package in the Rulestead sibling-package release.

Use this package when your application needs deterministic flag evaluation,
typed values, context builders, installer support, and fake-backed test helpers
without mounting the admin UI.

Repo GA shipped in `v1.0.0` on 2026-05-21, and the current installable package
line for `rulestead` on Hex is `0.1.3`. Keep the broader release and proof
posture in the shared root docs at [../README.md](../README.md).

Lifecycle guidance still lives in the shared root docs. The canonical flag from
birth to retirement guide is
[../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md), and it
keeps owner truth host-owned instead of turning the runtime package into an
identity directory.

## Install

Host apps need `ecto_sql ~> 3.14` (Ecto 3.14 pulls in Decimal 3.x).

```elixir
defp deps do
  [
    {:rulestead, "~> 0.1"},
    {:ecto_sql, "~> 3.14"}
  ]
end
```

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```

## Runtime entrypoints

### Keyed snapshot lookup (`Rulestead.Runtime`)

Phoenix apps with the local snapshot cache typically call:

- `Rulestead.Runtime.enabled?/3` — `(environment_key, flag_key, context)`
- `Rulestead.Runtime.get_variant/3`
- `Rulestead.Runtime.evaluate/3`
- `Rulestead.Runtime.get_value/4`
- `Rulestead.Runtime.explain/3`

See [evaluation.md](../guides/flows/evaluation.md) and the
[Phoenix Integration Spine](../guides/introduction/phoenix-integration-spine.md).

### Payload-first evaluation (`Rulestead`)

Tests, simulations, and tools that already hold the authored flag payload:

- `Rulestead.evaluate/3` — `(flag_payload, context)`
- `Rulestead.enabled?/2`
- `Rulestead.get_value/3`
- `Rulestead.get_variant/2`
- `Rulestead.explain/2`

## Guarded rollout runtime contract

The guarded rollout runtime uses a host-owned metrics provider seam. Host apps
submit normalized guardrail facts; `rulestead` keeps authored guardrail
definitions, deterministic sticky rollout decisions, and audited hold and rollback
records inside the runtime store.

This package intentionally provides no metrics ingestion, no dashboards, no statistics engine, and no built-in provider adapters. Hosts own provider selection, collection, aggregation, and normalization before facts reach the runtime command boundary.

## Reusable targeting deepening contract

`rulestead` owns **domain**, **validation**, and **contracts** for reusable
**Audience** targeting: dependency inventory, impact preview determinism,
promotion/manifest **fail closed** blockers, and snapshot-local evaluation.
This package does not ingest metrics, render dashboards, or resolve host
identity — observability and tenant catalogs remain **host-owned**.

Run `cd rulestead && mix verify.phase56` before changing audience dependency,
preview, promotion, or support-truth docs in this milestone.

## Blast radius governance contract

`rulestead` owns **domain**, **validation**, and **contracts** for blast-radius
threshold evaluation, change-request proposal/execute envelopes, and
fail-closed protected-environment behavior. Host apps own policy authorization
and observability — this package does not ingest metrics or resolve identity.

Run `cd rulestead && mix verify.phase60` before changing governance threshold,
change-request, or support-truth docs in the v1.7 milestone.

## Guarded rollout auto-advance contract

`rulestead` owns **domain**, **validation**, and **contracts** for opt-in
per-rollout auto-advance policy, **observation window** eligibility, and
**authored next-stage plan** metadata. Scheduled ticks advance only when
guardrails resolve healthy after the window closes; weak or stale signals
**fail closed** into non-advance. Protected-environment ticks route through the
same change-request envelope as manual advance. Timeline audit entries use
**`guardrail_automation`** to distinguish automation from manual actions.

Signal facts and metrics normalization remain **host-owned** — this package
evaluates normalized facts only and does not ship metrics pipelines or
fleet-wide operator dashboards.

Run `cd rulestead && mix verify.phase64` before changing auto-advance policy,
orchestration, or support-truth docs in the v1.8 milestone.

## Host preview evidence contract

`rulestead` owns **domain**, **validation**, and **contracts** for bounded
host-supplied sample cohort and impression summary on audience impact previews.
Hosts implement `Rulestead.Targeting.PreviewEvidence` via
`config :rulestead, :preview_evidence_resolver, MyApp.RulesteadPreviewEvidence`.

When no resolver is configured, previews use authored state and explicit samples
only. Invalid, oversized, or policy-denied resolver results **fail closed** with
`Rulestead.Error` — the mounted companion shows alert copy; it does not invent
`authoritative_population_count?: true` claims or fleet-wide analytics products.

Run `cd rulestead && mix verify.phase68` before changing preview evidence
resolver wiring, redaction, fingerprint/stale rejection, governance boundary, or
support-truth docs in the v1.9 milestone.

**Post-GA band closure:** `mix verify.adopter` (alias `mix verify.phase82`) runs
the v1.12 adopter bar: v1.10.1 support-truth contracts, integration-spine doc
checks, and adoption-lab contract guards. Evaluators:
[Adoption Lab](../guides/introduction/adoption-lab.md). Phoenix integrators:
[Phoenix Integration Spine](../guides/introduction/phoenix-integration-spine.md).
See the root [README](../README.md) proof section.

## Next docs

- Root front door: [../README.md](../README.md)
- Guided onboarding: [../guides/introduction/getting-started.md](../guides/introduction/getting-started.md)
- Installation choices: [../guides/introduction/installation.md](../guides/introduction/installation.md)
- Lifecycle guide: [../guides/flows/flag-lifecycle.md](../guides/flows/flag-lifecycle.md)
- Runtime usage: [../guides/flows/evaluation.md](../guides/flows/evaluation.md)
- Testing helpers: [../guides/recipes/testing.md](../guides/recipes/testing.md)

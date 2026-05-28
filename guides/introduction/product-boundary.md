# Product Boundary

Rulestead is a **self-hostable, Elixir-native** feature-flag and remote-config system for Phoenix teams. This page states what v1.x ships, what hosts own, and what is explicitly deferred so adopters do not expect a hosted LaunchDarkly clone.

## In scope (v1.x post-GA band)

| Surface | What you get |
|---------|----------------|
| **Runtime** | Pure `Rulestead.evaluate/3` on authored payloads + `%Rulestead.Context{}`; projections; explain API; deterministic bucketing |
| **Snapshot runtime** | `Rulestead.Runtime.*` keyed lookup by environment + flag key (local cache; not admin internals) |
| **Mounted admin** | `rulestead_admin` sibling package — flags, rollouts, kill switch, audit, compare, audiences, experiments, diagnostics |
| **Governance** | Change requests, scheduling, protected-environment controls, blast-radius thresholds (reference-count based) |
| **Guarded rollouts** | Host-supplied guardrail signals; hold/rollback; observation-window auto-advance (fail-closed) |
| **Reusable audiences** | Impact previews, dependency inventory, preview→confirm→audit, host-supplied preview evidence (bounded) |
| **Promotion / GitOps** | Compare, promote, manifest export/import with governed apply |
| **Lifecycle** | Owner metadata (host-owned refs), archive-readiness guidance, cleanup workbench — advisory only |
| **Tenancy helpers** | Explicit tenant scope in runtime, admin, promotion, audit — not environment-per-tenant topology |
| **Integration** | OpenFeature companion package, installer, Fake adapter, Plug/LiveView/Oban seams |

### Runtime semver (0.1.x)

`Rulestead.Runtime` is the supported **keyed lookup** path when using
environment + flag key with the snapshot cache. See
[Getting Started](getting-started.md) and [Evaluation](../flows/evaluation.md)
for the evaluation flow.

The **six-function catalog** in [API Stability](../api_stability.md) is stable
for `0.1.x` patch releases.

**Implementation modules** under `Rulestead.Runtime.*` (cache, snapshot,
refresh) are not semver-locked and may change without notice.

Payload-first `Rulestead.evaluate/3` remains the pure evaluation contract;
`Rulestead.Runtime` is additive for cached lookup.

## Host always owns

- **Identity and authorization** — `Rulestead.Admin.Policy` behaviour; no bundled auth stack
- **Observability and metrics** — guardrail signals, preview evidence, baselines; Rulestead normalizes bounded facts only
- **Population truth** — no authoritative affected-user counts; previews declare basis and uncertainty
- **Team/owner directory** — lifecycle owner fields are opaque host references

## Out of scope (not Rulestead)

| Area | Why |
|------|-----|
| Hosted Rulestead Cloud | Self-hostable OSS; you run Postgres and Phoenix |
| Stats engine / experiment analytics warehouse | Impression hooks only; analytics lives in your warehouse |
| Standalone fleet control plane | Admin mounts inside your app |
| Automatic code removal from lifecycle heuristics | Archive readiness is advisory |
| Percentage-of-time rollouts | Footgun; use stable targeting_key + percentage-of-actors |
| Impression-weighted blast-radius governance | GOV-05: reference-count thresholds only |

## Deferred to v2 (optional deepening)

| ID | Item | Reopen when |
|----|------|-------------|
| ADM-06 | Draft targeting presets | High authoring volume + duplication pain |
| ROL-08 | Guardrail baseline comparison | Prod guarded rollouts need host baselines |
| GOV-02-ext | Blast-radius threshold profiles | Per-env/tenant thresholds beyond v1.7 defaults |

Maintainers track full trigger text in the repository `.planning/DEFERRED.md`.

## Proof posture

Adopters should trust what CI and maintainers run:

- Every merge: full `mix test` in `rulestead` and `rulestead_admin` (includes `release_contract_test.exs`)
- Band closure maintainer gate: `cd rulestead && mix verify.phase76`
- Integrator shortcut: `cd rulestead && mix verify.adopter` (delegates to phase76)
- Runnable demo: `scripts/demo/proof.sh`

## Read next

- [Evaluation](../flows/evaluation.md) — payload-first vs runtime lookup
- [Footguns](../recipes/footguns.md) — common mistakes
- [Getting Started](getting-started.md) — 15-minute path

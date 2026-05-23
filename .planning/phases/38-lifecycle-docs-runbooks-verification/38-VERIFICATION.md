# Phase 38 Verification

## Requirement

- `LIF-05`: Docs and runbooks teach the "flag from birth to retirement" lifecycle clearly for Phoenix teams, including least-surprise defaults and host-owned integration expectations.

## Evidence Map

### Shared docs surface

- `README.md`
  - routes readers to `guides/flows/flag-lifecycle.md`
  - keeps the sibling-package shape explicit
- `rulestead/README.md`
  - points runtime readers to the shared lifecycle guide
  - keeps owner truth host-owned
- `rulestead_admin/README.md`
  - preserves mounted companion posture
  - routes lifecycle readers to the shared guide
- `guides/flows/flag-lifecycle.md`
  - canonical birth-to-retirement story
- `guides/flows/admin-ui.md`
  - queue-first mounted lifecycle review and `return_to` semantics
- `guides/flows/explainability.md`
  - support/SRE handoff through lifecycle evidence and audit history
- `guides/flows/evaluation.md`
  - lifecycle/evaluation boundary and advisory posture
- `guides/recipes/testing.md`
  - public lifecycle verification recipe
- `guides/api_stability.md`
  - public/private lifecycle verification boundary
- `MAINTAINING.md`
  - lifecycle release surface and machine-backed closeout requirement

### Automated test modules

- `rulestead/test/rulestead/mix/tasks/rulestead_lifecycle_test.exs`
- `rulestead/test/rulestead/release_contract_test.exs`
- `rulestead/test/rulestead/mix/tasks/verify_release_publish_test.exs`
- `rulestead/test/rulestead/mix/tasks/verify_release_parity_test.exs`
- `rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs`

## Commands Run

### Docs routing and vocabulary checks

```bash
rg -n "birth to retirement|host owns identity|archive_candidate.*not permission|preview.*confirm.*audit|mix rulestead\.lifecycle" /Users/jon/projects/rulestead/guides/flows/flag-lifecycle.md
rg -n "flag-lifecycle|birth to retirement" /Users/jon/projects/rulestead/README.md /Users/jon/projects/rulestead/rulestead/README.md /Users/jon/projects/rulestead/rulestead_admin/README.md
rg -n "mix rulestead\.lifecycle|preview.*confirm.*audit|\?env=|return_to|mounted companion" /Users/jon/projects/rulestead/guides/flows/admin-ui.md
rg -n "explain|audit history|lifecycle evidence|support|SRE" /Users/jon/projects/rulestead/guides/flows/explainability.md
rg -n "host-owned|advisory|does not affect evaluation|owner truth" /Users/jon/projects/rulestead/guides/flows/evaluation.md
rg -n "rulestead\.lifecycle|release_contract_test|admin_mount_test|public seam|browser-heavy" /Users/jon/projects/rulestead/guides/recipes/testing.md
rg -n "DOM|CSS|socket assigns|not public|route|query|mount" /Users/jon/projects/rulestead/guides/api_stability.md
rg -n "38-VERIFICATION|lifecycle release surface|machine-backed" /Users/jon/projects/rulestead/MAINTAINING.md
```

Observed result:

- all `rg` commands returned matches for the required lifecycle claims
- the negative admin test check `rg -n "CSS|selector|socket assign" rulestead_admin/test/rulestead_admin/integration/admin_mount_test.exs` returned no matches

### Core lifecycle release-surface tests

```bash
cd /Users/jon/projects/rulestead/rulestead && mix test test/rulestead/mix/tasks/rulestead_lifecycle_test.exs test/rulestead/release_contract_test.exs test/rulestead/mix/tasks/verify_release_publish_test.exs test/rulestead/mix/tasks/verify_release_parity_test.exs
```

Observed pass output structure:

- `Running ExUnit`
- `23 tests, 0 failures`

Covered by this suite:

- `schema_version`, owner field, advisory `archive_candidate`, and read-only posture for `mix rulestead.lifecycle`
- release contract checks for `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, and `guides/flows/flag-lifecycle.md`
- publish verification expectations for lifecycle doc discoverability
- parity coverage that includes `guides/flows/flag-lifecycle.md`

### Mounted admin host-seam tests

```bash
cd /Users/jon/projects/rulestead/rulestead_admin && mix test test/rulestead_admin/integration/admin_mount_test.exs
```

Observed pass output structure:

- `Running ExUnit`
- `2 tests, 0 failures`

Covered by this suite:

- mount redirect into `/admin/flags?env=prod`
- route availability for list, detail, rules, simulate, rollouts, and cleanup
- lifecycle queue access with `?env=` and readiness query state
- cleanup review access with `return_to` preserved at the host seam

## Traceability

| LIF-05 claim | Evidence |
|--------------|----------|
| One canonical lifecycle story is discoverable from repo/package entrypoints | `README.md`, `rulestead/README.md`, `rulestead_admin/README.md`, `guides/flows/flag-lifecycle.md`, `release_contract_test.exs` |
| Lifecycle docs preserve host-owned ownership and advisory archive-readiness posture | `guides/flows/flag-lifecycle.md`, `guides/flows/evaluation.md`, `rulestead_lifecycle_test.exs` |
| Supporting runbooks use one lifecycle vocabulary | `guides/flows/admin-ui.md`, `guides/flows/explainability.md`, `guides/recipes/testing.md`, `guides/api_stability.md`, `MAINTAINING.md` |
| Verification remains on public docs, CLI, and mount seams | `guides/recipes/testing.md`, `guides/api_stability.md`, `verify_release_publish_test.exs`, `verify_release_parity_test.exs`, `admin_mount_test.exs` |

## Outcome

`LIF-05` is backed by concrete docs checks, targeted `mix test` runs, and phase-local evidence instead of prose-only closeout.

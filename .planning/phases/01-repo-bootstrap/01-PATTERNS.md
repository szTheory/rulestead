# Phase 01: repo-bootstrap - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 42
**Local analogs found:** 0 / 42
**Anchor-doc analogs used:** 42 / 42

The repository is still greenfield at this phase. There are no local implementation files to copy from. Per [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:375) and [.planning/STATE.md](/Users/jon/projects/rulestead/.planning/STATE.md:24), planners should copy patterns from the locked prompt docs and phase context instead of looking for in-repo code analogs.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config | event-driven | `prompts/rulestead-release-engineering-and-ci.md:48-132` | doc-spec |
| `.github/workflows/release-please.yml` | config | event-driven | `prompts/rulestead-release-engineering-and-ci.md:267-384` + `01-CONTEXT.md:80-110` | doc-spec |
| `.github/workflows/publish-hex.yml` | config | event-driven | `prompts/rulestead-release-engineering-and-ci.md:304-330` + `01-CONTEXT.md:112-132` | doc-spec |
| `.github/workflows/pr-title.yml` | config | event-driven | `prompts/rulestead-engineering-dna-from-prior-libs.md:83-97` + `01-CONTEXT.md:146-149` | doc-spec |
| `.github/workflows/dependabot-automerge.yml` | config | event-driven | `prompts/rulestead-engineering-dna-from-prior-libs.md:94-97` | doc-spec |
| `.github/workflows/dependency-review.yml` | config | event-driven | `01-CONTEXT.md:151-152` | context-only |
| `.github/workflows/actionlint.yml` | config | event-driven | `01-CONTEXT.md:152-152` | context-only |
| `.github/dependabot.yml` | config | batch | `01-CONTEXT.md:159-163` | context-only |
| `.github/ISSUE_TEMPLATE/{bug_report,feature_request,release-parity-drift}.md` | config | request-response | `01-CONTEXT.md:159-163` | context-only |
| `.github/pull_request_template.md` | config | request-response | `01-CONTEXT.md:162-162` | context-only |
| `.github/CODEOWNERS` | config | request-response | `01-CONTEXT.md:163-163` | context-only |
| `.tool-versions` | config | request-response | `01-CONTEXT.md:176-185` | exact |
| `.formatter.exs` | config | transform | `01-CONTEXT.md:310-315` + `prompts/rulestead-engineering-dna-from-prior-libs.md:44-50` | doc-spec |
| `.credo.exs` | config | transform | `01-CONTEXT.md:310-315` + `prompts/rulestead-engineering-dna-from-prior-libs.md:153-155` | doc-spec |
| `release-please-config.json` | config | transform | `01-CONTEXT.md:80-104` | exact |
| `.release-please-manifest.json` | config | transform | `01-CONTEXT.md:171-174` | exact |
| `docker-compose.yml` | config | request-response | `01-CONTEXT.md:52-52` + `01-CONTEXT.md:254-255` | context-only |
| `scripts/ci/*.sh` | utility | batch | `prompts/rulestead-release-engineering-and-ci.md:770-785` | doc-spec |
| `README.md` | doc | transform | `01-CONTEXT.md:247-285` + `01-CONTEXT.md:391-430` + `prompts/rulestead-personas-jtbd-and-onboarding.md:83-88,511-511` | exact |
| `CONTRIBUTING.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `MAINTAINING.md` | doc | transform | `01-CONTEXT.md:249-261` + `01-CONTEXT.md:292-308` + `prompts/rulestead-release-engineering-and-ci.md:755-766` | exact |
| `SECURITY.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `CODE_OF_CONDUCT.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `LICENSE` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `CLAUDE.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `AGENTS.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `guides/introduction/{installation,getting-started,upgrading}.md` | doc | transform | `01-CONTEXT.md:263-284` + `prompts/rulestead-engineering-dna-from-prior-libs.md:141-151` | exact |
| `guides/flows/{evaluation,rulesets,rollout,admin-ui,explainability,multi-env}.md` | doc | transform | `01-CONTEXT.md:265-271` + `prompts/rulestead-engineering-dna-from-prior-libs.md:145-148` | exact |
| `guides/recipes/{testing,telemetry,ecto-conventions,oban-background-jobs,deployment,context-propagation}.md` | doc | transform | `01-CONTEXT.md:265-271` + `prompts/rulestead-engineering-dna-from-prior-libs.md:145-148` | exact |
| `rulestead/mix.exs` | config | request-response | `01-CONTEXT.md:191-239` + `01-CONTEXT.md:280-284` + `prompts/rulestead-release-engineering-and-ci.md:625-726` | exact |
| `rulestead/.formatter.exs` | config | transform | `01-CONTEXT.md:312-315` | exact |
| `rulestead/lib/rulestead.ex` | model | request-response | `prompts/rulestead-engineering-dna-from-prior-libs.md:50-51` + `01-CONTEXT.md:375-381` | partial |
| `rulestead/test/test_helper.exs` | test | request-response | `01-CONTEXT.md:19-19` + `prompts/rulestead-engineering-dna-from-prior-libs.md:124-137` | doc-spec |
| `rulestead/test/rulestead_test.exs` | test | request-response | `01-CONTEXT.md:19-19` + `prompts/rulestead-engineering-dna-from-prior-libs.md:124-137` | doc-spec |
| `rulestead/CHANGELOG.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `rulestead/README.md` | doc | transform | `01-CONTEXT.md:191-195` + `prompts/rulestead-release-engineering-and-ci.md:661-674` | partial |
| `rulestead_admin/mix.exs` | config | request-response | `01-CONTEXT.md:114-130` + `01-CONTEXT.md:198-205` + `prompts/rulestead-release-engineering-and-ci.md:372-384` | exact |
| `rulestead_admin/.formatter.exs` | config | transform | `01-CONTEXT.md:312-315` | exact |
| `rulestead_admin/lib/rulestead_admin.ex` | model | request-response | `01-CONTEXT.md:114-117` | exact |
| `rulestead_admin/lib/rulestead_admin/router.ex` | route | request-response | `01-CONTEXT.md:116-118,132-138` | exact |
| `rulestead_admin/test/test_helper.exs` | test | request-response | `01-CONTEXT.md:19-19` + `prompts/rulestead-engineering-dna-from-prior-libs.md:124-137` | doc-spec |
| `rulestead_admin/test/rulestead_admin_test.exs` | test | request-response | `01-CONTEXT.md:19-19` + `prompts/rulestead-engineering-dna-from-prior-libs.md:124-137` | doc-spec |
| `rulestead_admin/CHANGELOG.md` | doc | transform | `01-CONTEXT.md:249-261` | exact |
| `rulestead_admin/README.md` | doc | transform | `01-CONTEXT.md:200-202` + `prompts/rulestead-release-engineering-and-ci.md:661-674` | partial |

## Pattern Assignments

### Workflow Files

**Applies to:** `.github/workflows/ci.yml`, `release-please.yml`, `publish-hex.yml`, `pr-title.yml`, `dependabot-automerge.yml`, `dependency-review.yml`, `actionlint.yml`

**Primary analog:** [prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:48)

**Job-id contract** ([prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:41)):
```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and branch protection:
#   lint, test, integration, installer_golden, release_gate
# `name:` strings evolve freely; `id:` strings are immutable without coordinated docs + branch-protection updates.
```

**CI trigger / permissions / lint pattern** ([prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:52)):
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  actions: read
  checks: read

lint:
  runs-on: ubuntu-24.04
  steps:
    - uses: actions/checkout@de0fac2e0d0e70329c96e8b4d3e4dc33e27e6e83  # v6.0.2
    - uses: erlef/setup-beam@v1
      with:
        version-file: .tool-versions
        version-type: strict
```

**Phase-1 ci divergence to apply** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:146)):
```text
Jobs: lint, test (1.17/26.x + 1.19/28.x), integration-placeholder, release_gate.
Do not add installer_path_gate or installer_golden yet.
Keep release_gate as the only required CI aggregate.
```

**Release-please linked-versions pattern** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:84)):
```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "separate-pull-requests": false,
  "include-component-in-tag": true,
  "plugins": [
    {"type": "linked-versions", "groupName": "rulestead-monorepo",
     "components": ["rulestead", "rulestead_admin"]}
  ]
}
```

**Admin publish guard** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:132)):
```text
publish-hex.yml must refuse admin publish while router.ex still contains the Phase-1 stub macro that raises.
```

**Branch-protection strings to mirror in docs** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:296)):
```text
Required checks:
- release_gate
- Validate PR title
- dependency-review
- NOT actionlint
```

### Mix / Release Config

**Applies to:** `.tool-versions`, `.formatter.exs`, `.credo.exs`, `release-please-config.json`, `.release-please-manifest.json`, `rulestead/mix.exs`, `rulestead_admin/mix.exs`, `rulestead/.formatter.exs`, `rulestead_admin/.formatter.exs`

**Primary analogs:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:176), [prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:625), [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:42)

**Strict toolchain pinning** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:178)):
```text
elixir 1.19.2-otp-28
erlang 28.1.2
```

**Core `mix.exs` package/docs pattern** ([prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:627)):
```elixir
@version "0.1.0"

defp package do
  [
    licenses: ["MIT"],
    links: %{
      "GitHub" => @source_url,
      "HexDocs" => @hexdocs_url,
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
      "Guides" => "#{@release_docs_url}/readme.html"
    },
    files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md CONVENTIONS.md SECURITY.md)
  ]
end

defp docs do
  [
    main: "getting-started",
    source_ref: "v#{@version}",
    skip_undefined_reference_warnings_on: &String.starts_with?(&1, "lib/")
  ]
end
```

**Phase-1 overrides for core** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:193)):
```elixir
files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
# MUST never contain: test/example/, prompts/, .planning/, rulestead_admin/ (sibling), scripts/, docker-compose.yml
```

**Phase-1 dialyzer shape** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:215)):
```elixir
defp dialyzer do
  [
    plt_local_path: "priv/plts",
    plt_core_path: "priv/plts",
    plt_add_apps: [:ex_unit, :mix, :eex],
    flags: [:error_handling, :extra_return, :missing_return],
    ignore_warnings: ".dialyzer_ignore.exs",
    list_unused_filters: true
  ]
end
```

**Admin path/Hex env-swap** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:119)):
```elixir
defp rulestead_dep do
  if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
    {:rulestead, "~> #{@version}"}
  else
    {:rulestead, path: "../rulestead"}
  end
end
```

**Formatter/Credo shape** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:312)):
```text
Root .formatter.exs imports :phoenix, :ecto, :phoenix_live_view, :plug.
rulestead/.formatter.exs stays minimal.
rulestead_admin/.formatter.exs adds :rulestead only after Phase 2.
.credo.exs is strict with requires: [] in Phase 1.
```

### Package Skeleton Files

**Applies to:** `rulestead/lib/rulestead.ex`, `rulestead/test/test_helper.exs`, `rulestead/test/rulestead_test.exs`, `rulestead_admin/lib/rulestead_admin.ex`, `rulestead_admin/lib/rulestead_admin/router.ex`, `rulestead_admin/test/test_helper.exs`, `rulestead_admin/test/rulestead_admin_test.exs`

**Primary analogs:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:114), [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:124)

**Admin skeleton contract** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:114)):
```text
- lib/rulestead_admin.ex with @moduledoc false + version reflection
- lib/rulestead_admin/router.ex exports a rulestead_admin/2 macro
- the macro raises a Phase-1 ArgumentError pointing users to the roadmap
- cd rulestead_admin && mix test must work from day 1
```

**Minimal test scaffolding expectation** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:19)):
```text
Both packages compile and test green on an empty skeleton.
```

**Test structure pattern to copy later** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:124)):
```text
Keep ExUnit scaffolding minimal in Phase 1.
Reserve Fake-adapter, Mox, golden installer, and doc-contract patterns for later phases.
Do not invent integration fixtures before the host app exists.
```

### Repo Docs And Guides

**Applies to:** root docs, package changelogs/READMEs, `guides/**`

**Primary analogs:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:247), [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:393), [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:141), [prompts/rulestead-personas-jtbd-and-onboarding.md](/Users/jon/projects/rulestead/prompts/rulestead-personas-jtbd-and-onboarding.md:83)

**README/front-door pattern** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:393)):
```markdown
# Rulestead

> **Runtime decisions, made clear.**

> ⚠️ **Pre-release.** v0.1.0 is in active development (Phase 1 of 8).

## What this is (60 seconds)
## Who it's for
## 15-minute quickstart
```

**Persona contract** ([prompts/rulestead-personas-jtbd-and-onboarding.md](/Users/jon/projects/rulestead/prompts/rulestead-personas-jtbd-and-onboarding.md:85)):
```text
README quickstart targets Alex.
Contributing quality targets Omar.
Maintaining guidance serves Shiori and Tova.
Every doc section should trace to an explicit persona.
```

**Guide IA pattern** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:143)):
```text
guides/introduction/
guides/flows/
guides/recipes/
mix docs --warnings-as-errors stays blocking.
```

**Phase-1 guide stub pattern** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:267)):
```markdown
# Title

Documented in v0.1.0 (Phase N ships the feature; this guide lands in Phase 8).
See ROADMAP.
```

### Scripts

**Applies to:** `scripts/ci/*.sh`

**Primary analog:** [prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:770)

**Script header pattern** ([prompts/rulestead-release-engineering-and-ci.md](/Users/jon/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md:782)):
```bash
set -euo pipefail
RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"
```

**Phase-1 scope note** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:325)):
```text
Scripts not needed until later phases may be left as documented skeletons or deferred entirely.
```

## Shared Patterns

### No Local Source Analogs

**Source:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:375)

```text
This is a greenfield project — there is no existing code.
Canonical patterns come from prompts/ anchor docs.
```

Apply this to every file in this phase. Do not spend planner effort searching the repo for precedent that does not exist.

### Sibling-Package Monorepo

**Source:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:42)

```text
Repo root holds shared CI/docs/config.
Core lives in rulestead/.
Admin lives in rulestead_admin/.
Each sibling owns its own mix.exs and CHANGELOG.md.
```

Apply to: all package, workflow, docs, and release files.

### ExDoc Phase-1 Override

**Source:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:280)

```elixir
main: "readme"
skip_undefined_reference_warnings_on: &String.starts_with?(&1, "lib/")
source_ref: "v#{@version}"
```

Apply to: `rulestead/mix.exs`, guide scaffolding, root `README.md`.

### Workflow Required-Check Stability

**Source:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:317)

```text
Keep an integration-placeholder job in ci.yml now so release_gate.needs stays stable until Phase 5.
```

Apply to: `ci.yml`, `MAINTAINING.md`, branch-protection docs.

### Packaging Guardrails

**Source:** [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:191), [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:45)

```text
Use explicit package.files whitelists.
Comment forbidden paths directly above the whitelist.
Never ship .planning/, prompts/, sibling package files, or installer fixtures in Hex tarballs.
```

Apply to: both `mix.exs` files and release verification steps.

## No Analog Found

There are no close in-repository code analogs for any Phase 1 file. Use the anchor docs above as the implementation source.

## Metadata

**Analog search scope:** repository root, `.planning/`, `prompts/`
**Files scanned:** 8
**Pattern extraction date:** 2026-04-23

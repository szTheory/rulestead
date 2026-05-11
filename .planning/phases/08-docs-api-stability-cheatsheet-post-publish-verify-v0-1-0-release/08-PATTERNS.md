# Phase 8: Docs, API Stability, Cheatsheet, Post-Publish Verify, v0.1.0 Release - Pattern Map

**Mapped:** 2026-04-24
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | docs | request-response | `README.md` | exact |
| `rulestead/README.md` | docs | request-response | `rulestead/README.md` | exact |
| `rulestead_admin/README.md` | docs | request-response | `rulestead_admin/README.md` | exact |
| `rulestead/mix.exs` | config | transform | `rulestead/mix.exs` | exact |
| `rulestead_admin/mix.exs` | config | transform | `rulestead_admin/mix.exs` | exact |
| `CONVENTIONS.md` | docs | transform | `guides/flows/telemetry.md` | partial-match |
| `guides/api_stability.md` | docs | transform | `guides/flows/telemetry.md` | partial-match |
| `guides/cheatsheet.cheatmd` | docs | transform | `README.md` | partial-match |
| `guides/flows/extending-rulestead.md` | docs | transform | `rulestead_admin/README.md` | partial-match |
| `guides/introduction/installation.md` | docs | request-response | `guides/introduction/getting-started.md` | role-match |
| `guides/introduction/getting-started.md` | docs | request-response | `README.md` | role-match |
| `guides/introduction/upgrading.md` | docs | transform | `guides/flows/telemetry.md` | partial-match |
| `guides/flows/admin-ui.md` | docs | request-response | `rulestead_admin/README.md` | role-match |
| `guides/flows/explainability.md` | docs | request-response | `guides/flows/telemetry.md` | partial-match |
| `guides/flows/multi-env.md` | docs | request-response | `rulestead_admin/README.md` | partial-match |
| `guides/recipes/testing.md` | docs | request-response | `guides/recipes/testing.md` | exact |
| `rulestead/lib/mix/tasks/verify.workspace_clean.ex` | config | file-I/O | `rulestead/lib/mix/tasks/rulestead.install.ex` | role-match |
| `rulestead/lib/mix/tasks/verify.release_publish.ex` | config | request-response | `rulestead/lib/mix/tasks/rulestead.install.ex` | role-match |
| `rulestead/lib/mix/tasks/verify.release_parity.ex` | config | file-I/O | `rulestead/lib/mix/tasks/rulestead.install.ex` | role-match |
| `rulestead/test/rulestead/mix/tasks/verify_*_test.exs` | test | file-I/O | `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs` | role-match |
| `rulestead/test/rulestead/release_contract_test.exs` | test | request-response | `rulestead/test/rulestead/admin_contract_test.exs` | role-match |
| `rulestead/test/rulestead/integration/release_publish_smoke_test.exs` | test | request-response | `rulestead/test/rulestead/integration/install_smoke_test.exs` | role-match |
| `.github/workflows/release-please.yml` | config | event-driven | `.github/workflows/release-please.yml` | exact |
| `.github/workflows/publish-hex.yml` | config | event-driven | `.github/workflows/publish-hex.yml` | exact |
| `.github/workflows/verify-published-release.yml` | config | batch | `.github/workflows/ci.yml` | partial-match |
| `scripts/ci/check_package_whitelist.sh` | utility | file-I/O | `scripts/ci/check_package_whitelist.sh` | exact |
| `scripts/ci/admin_publish_guard.sh` | utility | request-response | `scripts/ci/admin_publish_guard.sh` | exact |
| `scripts/ci/release_gate.sh` | utility | batch | `scripts/ci/release_gate.sh` | exact |
| `scripts/ci/release_please_dry_run.sh` | utility | request-response | `scripts/ci/release_please_dry_run.sh` | exact |
| `scripts/ci/verify_published_release.sh` | utility | batch | `scripts/ci/check_package_whitelist.sh` | partial-match |

## Pattern Assignments

### `README.md` / `guides/introduction/getting-started.md` (docs front door, request-response)

**Analog:** `README.md`

**Front-door structure** ([README.md](/Users/jon/projects/rulestead/README.md:3), lines 3-22):
```markdown
> **Runtime decisions, made clear.**
> Batteries-included Elixir-native feature flags, experimentation, and
> remote config, with a mountable Phoenix LiveView admin.

## What this is (60 seconds)

Rulestead gives Elixir apps typed flags, staged rollouts, and a built-in
LiveView admin with explainability baked in.
```

**Alex-first quickstart pattern** ([README.md](/Users/jon/projects/rulestead/README.md:33), lines 33-72):
```markdown
## 15-minute quickstart

```elixir
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}
```

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```
```

**Planner note:** Keep root docs task-first and compact. Phase 8 should replace the Phase 1 pre-release framing, then immediately split readers into build, operate, and extend paths rather than turning the root README into a sitemap.

---

### `rulestead_admin/README.md` / `guides/flows/admin-ui.md` / `guides/flows/multi-env.md` (admin host seam docs)

**Analog:** `rulestead_admin/README.md`

**Mount seam pattern** ([rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:8), lines 8-21):
```markdown
## Mount seam

Mount the admin routes from the host router with the package macro:

```elixir
scope "/" do
  pipe_through :browser

  rulestead_admin "/admin/flags", policy: MyApp.RulesteadPolicy
end
```
```

**Session and env contract pattern** ([rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:23), lines 23-32):
```markdown
The mounted package expects the host session to provide:

- "current_actor" for policy checks
- "rulestead_admin_environments" as the environment picker source
- "rulestead_admin_last_env" as the remembered fallback

The URL query param `env` is the canonical environment selector.
```

**Planner note:** Reuse this exact host-contract posture in `api_stability.md`, the admin README, and admin-facing guides. The public promise is the router seam and operator URL/query conventions, not internal LiveView module names.

---

### `rulestead/mix.exs` / `rulestead_admin/mix.exs` (ExDoc extras and package metadata)

**Analog:** `rulestead/mix.exs`

**Package links and whitelist pattern** ([rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:46), lines 46-59):
```elixir
defp package do
  [
    name: "rulestead",
    description: "Runtime decisions, made clear.",
    links: %{
      "GitHub" => @source_url,
      "HexDocs" => @homepage_url,
      "Changelog" => "#{@source_url}/blob/main/rulestead/CHANGELOG.md",
      "Guides" => "#{@source_url}/tree/main/guides"
    },
    files: ~w(...)
  ]
end
```

**Extras wiring pattern** ([rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:62), lines 62-90):
```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    homepage_url: @homepage_url,
    extras: [
      "README.md",
      "../guides/introduction/installation.md",
      "../guides/introduction/getting-started.md",
      "../guides/flows/telemetry.md",
      "../guides/recipes/testing.md"
    ]
  ]
end
```

**Admin package-local pattern** ([rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:42), lines 42-70):
```elixir
defp rulestead_dep do
  if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
    {:rulestead, "~> #{@version}"}
  else
    {:rulestead, path: "../rulestead"}
  end
end
```

**Planner note:** Phase 8 should add the new docs files by extending the existing extras list, not by inventing a second docs pipeline. Keep package metadata and docs links aligned with the sibling-package split.

---

### `guides/api_stability.md` / `CONVENTIONS.md` / `guides/introduction/upgrading.md` (public contract inventory docs)

**Analog:** `guides/flows/telemetry.md`

**Versioned-public-API wording pattern** ([guides/flows/telemetry.md](/Users/jon/projects/rulestead/guides/flows/telemetry.md:1), lines 1-15):
```markdown
# Telemetry

Phase 4 locks Rulestead telemetry as a versioned public API. The event names in
this guide are additive-only for the rest of `v0.1.x`.

## Principles

- All events live under `[:rulestead, ...]`.
- The shared metadata spine is bounded and redacted at emission time.
```

**Closed-set catalog pattern** ([guides/flows/telemetry.md](/Users/jon/projects/rulestead/guides/flows/telemetry.md:14), lines 14-80):
```markdown
## Event Catalog

- `[:rulestead, :eval, :decide, :start]`
- `[:rulestead, :eval, :decide, :stop]`

## Shared Metadata Spine

- `:flag_key`
- `:flag_type`
- `:environment`
```

**Planner note:** `api_stability.md` should follow this same pattern: brief semantic promise, then explicit closed catalogs for modules/functions/struct fields/error atoms/telemetry events/config keys, followed by a blunt non-public section. `CONVENTIONS.md` should use the same "principles first, bounded rules second" shape.

---

### `guides/cheatsheet.cheatmd` (one-page quick reference)

**Analog:** `README.md`

**Compact recipe pattern** ([README.md](/Users/jon/projects/rulestead/README.md:33), lines 33-68):
```markdown
## 15-minute quickstart

```elixir
{:rulestead, "~> 0.1"},
{:rulestead_admin, "~> 0.1"}
```

```bash
mix deps.get
mix rulestead.install
mix ecto.migrate
```
```

**Planner note:** Keep the cheatsheet terse and command-heavy. Copy the README habit of alternating tiny prose headings with executable snippets; do not turn it into another narrative guide.

---

### `guides/flows/extending-rulestead.md` (supported extension seams only)

**Analog:** `rulestead_admin/README.md`

**Supported seam wording** ([rulestead_admin/README.md](/Users/jon/projects/rulestead/rulestead_admin/README.md:20), lines 20-39):
```markdown
The `policy:` option is required. The policy module owns host authorization
through the `Rulestead.Admin.Policy` behaviour.

The rules workspace keeps `Save draft` and `Publish` as distinct actions...
```

**Behavior contract source** ([rulestead/lib/rulestead/admin/policy.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/policy.ex:1), lines 1-14):
```elixir
defmodule Rulestead.Admin.Policy do
  @moduledoc """
  Host-owned authorization seam for mounted admin actions.
  """

  @callback can?(actor, action, resource, environment_key) :: boolean()
end
```

**Planner note:** Document extension seams the same way the admin README documents `policy:`: explicit ownership, explicit callback surface, no implied support for adjacent internals. Planned seams belong in an appendix labeled non-public.

---

### `rulestead/lib/mix/tasks/verify.workspace_clean.ex` / `verify.release_publish.ex` / `verify.release_parity.ex` (Mix verify tasks)

**Analog:** `rulestead/lib/mix/tasks/rulestead.install.ex`

**Task shell pattern** ([rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:1), lines 1-24):
```elixir
defmodule Mix.Tasks.Rulestead.Install do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

    case Install.run(opts) do
      {:ok, messages} -> Enum.each(messages, &Mix.shell().info/1)
      {:error, error} -> Mix.raise(error.message)
    end
  end
end
```

**Planner note:** Use the same thin-task pattern: parse flags, delegate to a plain module, emit deterministic shell lines, and raise on failure. For `verify.release_parity`, keep the diff/compute logic in a normal library module so ExUnit can test return codes and comparisons without invoking a task.

---

### `rulestead/test/rulestead/mix/tasks/verify_*_test.exs` (task tests)

**Analog:** `rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs`

**Temp workspace harness pattern** ([rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:9), lines 9-79):
```elixir
setup do
  tmp_dir =
    Path.join(System.tmp_dir!(), "rulestead-install-#{System.unique_integer([:positive])}")

  File.mkdir_p!(Path.join(tmp_dir, "config"))
  ...
  on_exit(fn -> File.rm_rf!(tmp_dir) end)

  {:ok, tmp_dir: tmp_dir}
end
```

**Deterministic output assertion pattern** ([rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:157), lines 157-207):
```elixir
first_output =
  capture_io(fn ->
    Mix.Tasks.Rulestead.Install.run(["--yes", "--repo", "MyApp.Repo"])
  end)

assert output_lines(first_output) == [
  "copy ...",
  "write ..."
]
```

**Planner note:** Reuse this exact style for verify tasks: isolate filesystem/network seams, capture shell output, and assert exact stable lines or stable exit behavior. Do not bury contract coverage in broad integration tests only.

---

### `rulestead/test/rulestead/release_contract_test.exs` / API lock tests

**Analog:** `rulestead/test/rulestead/admin_contract_test.exs`

**Explicit export lock pattern** ([rulestead/test/rulestead/admin_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/admin_contract_test.exs:7), lines 7-25):
```elixir
test "the root facade exposes the phase 6 admin verbs" do
  exports = Rulestead.module_info(:exports)

  assert {:list_flags, 0} in exports
  assert function_exported?(Rulestead, :list_flags, 1)
  assert function_exported?(Rulestead, :fetch_flag, 3)
end
```

**Behavior callback lock pattern** ([rulestead/test/rulestead/admin_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/admin_contract_test.exs:7), lines 7-9):
```elixir
test "admin policy exposes a single can?/4 host authorization callback" do
  assert [can?: 4] == Rulestead.Admin.Policy.behaviour_info(:callbacks)
end
```

**Planner note:** Phase 8 public-surface tests should use this same directness for modules, exports, callbacks, `Error.leaf_types/0`, and `Config.schema/0`. Assert the locked surface explicitly instead of snapshotting whole modules.

---

### `rulestead/test/rulestead/integration/release_publish_smoke_test.exs` (published-consumer smoke)

**Analog:** `rulestead/test/rulestead/integration/install_smoke_test.exs`

**Fresh-app smoke pattern** ([rulestead/test/rulestead/integration/install_smoke_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:8), lines 8-39):
```elixir
test "fresh host app installs, migrates, and boots ..." do
  result = setup_tmp_app!()
  on_exit(fn -> cleanup_tmp_app!(result) end)

  assert install_output =~ "write config/rulestead.exs"
  ...
  probe_output = run_probe!(result)
  assert probe_output =~ "admin_mount=true"
end
```

**Probe execution pattern** ([rulestead/test/rulestead/integration/install_smoke_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:41), lines 41-85):
```elixir
{probe_output, probe_status} =
  System.cmd("mix", ["run", "-e", probe_script()],
    cd: result.app_dir,
    stderr_to_stdout: true,
    env: [{"HEX_HOME", result.hex_home}]
  )
```

**Planner note:** Reuse the same structure for `mix new` and `mix phx.new` published-artifact verification. The only change should be dependency source and probe assertions, not the general harness shape.

---

### `.github/workflows/verify-published-release.yml` (daily drift cron)

**Analog:** `.github/workflows/ci.yml`

**Workflow header pattern** ([.github/workflows/ci.yml](/Users/jon/projects/rulestead/.github/workflows/ci.yml:1), lines 1-20):
```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and branch protection:
name: ci

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
```

**Job aggregation pattern** ([.github/workflows/ci.yml](/Users/jon/projects/rulestead/.github/workflows/ci.yml:123), lines 123-150):
```yaml
release_gate:
  needs:
    - changes
    - lint
    - test
  if: always()
  steps:
    - name: Evaluate gate
      run: scripts/ci/release_gate.sh ...
```

**Planner note:** The drift workflow should keep the same pinned-action, job-id-contract, and scripts-first posture. It will need new cron + issue-creation steps, but the orchestration style should stay consistent with `ci.yml`.

---

### `.github/workflows/release-please.yml` / `.github/workflows/publish-hex.yml` (release choreography)

**Analog:** existing workflow files

**Lockstep release-please pattern** ([.github/workflows/release-please.yml](/Users/jon/projects/rulestead/.github/workflows/release-please.yml:20), lines 20-65):
```yaml
jobs:
  release-please:
    outputs:
      rulestead_release_created: ${{ steps.release.outputs.rulestead--release_created }}
      rulestead_admin_release_created: ${{ steps.lockstep.outputs.rulestead_admin_release_created }}
    steps:
      - id: release
        uses: googleapis/release-please-action@... # v4
      - id: lockstep
        run: |
          set -euo pipefail
          ...
```

**Manual fallback publish pattern** ([.github/workflows/publish-hex.yml](/Users/jon/projects/rulestead/.github/workflows/publish-hex.yml:6), lines 6-24 and 28-84):
```yaml
on:
  workflow_dispatch:
    inputs:
      tag:
      release_version:
      package:

jobs:
  publish-core:
  publish-admin:
```

**Planner note:** Phase 8 should evolve these in place. Keep ordered core-then-admin semantics, explicit `workflow_dispatch` recovery, and environment variables for admin Hex release mode.

---

### `scripts/ci/check_package_whitelist.sh` / `scripts/ci/verify_published_release.sh` (shell helpers)

**Analog:** `scripts/ci/check_package_whitelist.sh`

**Repo-root resolution and helper-function pattern** ([scripts/ci/check_package_whitelist.sh](/Users/jon/projects/rulestead/scripts/ci/check_package_whitelist.sh:1), lines 1-28):
```bash
#!/usr/bin/env bash
set -euo pipefail

RULESTEAD_REPO="${RULESTEAD_REPO:-${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"

run_dry_run() {
  local package_dir="$1"
  ...
}
```

**Fail-fast guard pattern** ([scripts/ci/check_package_whitelist.sh](/Users/jon/projects/rulestead/scripts/ci/check_package_whitelist.sh:41), lines 41-51):
```bash
if rg -n "^rulestead_admin/" "${core_contents}" >/dev/null; then
  echo "core package dry-run output includes rulestead_admin/ content" >&2
  exit 1
fi
```

**Planner note:** New release verification scripts should follow this exact shape: repo-root normalization, tiny shell functions, explicit stderr failure messages, and local/GitHub compatibility.

---

### `scripts/ci/admin_publish_guard.sh` / `scripts/ci/release_gate.sh` / `scripts/ci/release_please_dry_run.sh` (guardrail scripts)

**Analogs:** existing scripts

**Single-purpose structural guard** ([scripts/ci/admin_publish_guard.sh](/Users/jon/projects/rulestead/scripts/ci/admin_publish_guard.sh:1), lines 1-12):
```bash
ROUTER_FILE="${RULESTEAD_REPO}/rulestead_admin/lib/rulestead_admin/router.ex"

if rg -n "Phases 6-7 of v0\\.1\\.0" "${ROUTER_FILE}" >/dev/null; then
  echo "refusing admin publish ..." >&2
  exit 1
fi
```

**Argument-pair gate pattern** ([scripts/ci/release_gate.sh](/Users/jon/projects/rulestead/scripts/ci/release_gate.sh:6), lines 6-21):
```bash
if [[ "$#" -eq 0 ]]; then
  echo "usage: $0 job=result [job=result...]" >&2
  exit 1
fi

for pair in "$@"; do
  ...
done
```

**Dry-run validation pattern** ([scripts/ci/release_please_dry_run.sh](/Users/jon/projects/rulestead/scripts/ci/release_please_dry_run.sh:20), lines 20-52):
```bash
if ! rg -n '"rulestead": "0\.0\.0"' "${MANIFEST_FILE}" >/dev/null; then
  echo "release-please bootstrap manifest must seed rulestead at 0.0.0" >&2
  exit 1
fi

npx --yes release-please@16.18.0 manifest-pr ... --dry-run
```

**Planner note:** Use these as the pattern for publish verification and drift scripts: one responsibility per script, precondition checks up front, no hidden defaults beyond repo-root resolution.

## Shared Patterns

### ExDoc Extras And Shared Guides
**Sources:** [rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:62), [rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:64)
**Apply to:** `rulestead/mix.exs`, `rulestead_admin/mix.exs`, all new Phase 8 docs

```elixir
docs: [
  main: "readme",
  source_ref: "v#{@version}",
  source_url: @source_url,
  homepage_url: @homepage_url,
  extras: [...]
]
```

Keep one shared docs tree under `guides/`, with the core package owning ExDoc extras for shared narrative docs.

### Stable Public-Surface Catalogs
**Sources:** [guides/flows/telemetry.md](/Users/jon/projects/rulestead/guides/flows/telemetry.md:14), [rulestead/lib/rulestead/error.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/error.ex:16), [rulestead/lib/rulestead/config.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/config.ex:38)
**Apply to:** `guides/api_stability.md`, `CONVENTIONS.md`, `guides/introduction/upgrading.md`

```markdown
## Event Catalog
- ...

## Shared Metadata Spine
- ...
```

```elixir
@type type ::
  :flag_not_found
  | :environment_not_found
  | ...
```

```elixir
@raw_schema [
  environment_key: [...],
  plug: [...],
  live_view: [...]
]
```

Build Phase 8 catalogs from real exported modules, callbacks, struct fields, error atoms, telemetry docs, and config schema keys already present in code.

### Thin Mix Tasks, Logic In Plain Modules
**Source:** [rulestead/lib/mix/tasks/rulestead.install.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.install.ex:1)
**Apply to:** all `Mix.Tasks.Verify.*`

```elixir
def run(args) do
  Mix.Task.run("app.start")
  {opts, _argv, _invalid} = OptionParser.parse(args, strict: @switches)

  case Install.run(opts) do
    {:ok, messages} -> ...
    {:error, error} -> Mix.raise(error.message)
  end
end
```

Keep tasks thin and deterministic. Put parity computation and remote polling logic in normal modules so tests do not need to spawn tasks for every branch.

### Contract Tests Over Broad Snapshots
**Sources:** [rulestead/test/rulestead/admin_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/admin_contract_test.exs:7), [rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_install_test.exs:129)
**Apply to:** public-surface locking tests, verify-task tests

```elixir
assert function_exported?(Rulestead, :fetch_flag, 3)
assert [can?: 4] == Rulestead.Admin.Policy.behaviour_info(:callbacks)
assert defaults[:runtime][:api] == Rulestead.Runtime
```

Prefer explicit assertions on callbacks, exports, config keys, and exact output lines.

### Scripts-First GitHub Actions
**Sources:** [.github/workflows/ci.yml](/Users/jon/projects/rulestead/.github/workflows/ci.yml:54), [.github/workflows/publish-hex.yml](/Users/jon/projects/rulestead/.github/workflows/publish-hex.yml:44), [scripts/ci/release_gate.sh](/Users/jon/projects/rulestead/scripts/ci/release_gate.sh:1)
**Apply to:** release/drift workflows and helper scripts

```yaml
- name: Run lint lane
  run: scripts/ci/lint.sh
```

```yaml
- name: Verify package whitelists
  run: scripts/ci/check_package_whitelist.sh
```

```bash
set -euo pipefail
```

Keep workflow YAML declarative and push non-trivial logic into locally runnable shell scripts.

## No Analog Found

Files with no exact same-role-and-flow analog in the repo yet; planner should reuse the nearest local pattern plus Phase 8 research:

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `guides/api_stability.md` | docs | transform | No existing guide inventories the whole public API boundary across modules, telemetry, errors, and config. |
| `guides/cheatsheet.cheatmd` | docs | transform | No existing CheatMd file exists yet. |
| `guides/flows/extending-rulestead.md` | docs | transform | No existing extension guide documents supported behaviors end-to-end. |
| `rulestead/lib/mix/tasks/verify.release_publish.ex` | config | request-response | No current task polls Hex or verifies HexDocs reachability. |
| `rulestead/lib/mix/tasks/verify.release_parity.ex` | config | file-I/O | No current task compares git-tag contents against a published Hex tarball. |
| `.github/workflows/verify-published-release.yml` | config | batch | No current scheduled drift-monitor workflow exists. |

## Metadata

**Analog search scope:** `README.md`, `MAINTAINING.md`, `guides/`, `rulestead/mix.exs`, `rulestead_admin/mix.exs`, `rulestead/lib/`, `rulestead_admin/lib/`, `rulestead/test/`, `.github/workflows/`, `scripts/ci/`
**Files scanned:** 28 primary files plus roadmap/context artifacts
**Pattern extraction date:** 2026-04-24

## PATTERN MAPPING COMPLETE

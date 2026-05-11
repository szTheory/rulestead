# Phase 02: data-model-error-model-ecto-store-fake-adapter - Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 12
**Local analogs found:** 6 / 12
**Anchor-doc analogs used:** 12 / 12

Phase 2 is the first real library-code phase. The repo still has very few runtime analogs, so the planner should copy local patterns where they already exist (`mix.exs`, root module, test bootstrap, monorepo/package boundaries) and use the locked Phase 2 context plus anchor docs for the new Ecto/store/error surfaces that do not exist yet.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/mix.exs` | config | request-response | `rulestead/mix.exs` + `.planning/phases/01-repo-bootstrap/01-CONTEXT.md:191-239` | exact |
| `rulestead/lib/rulestead.ex` | model | request-response | `rulestead/lib/rulestead.ex` + `prompts/elixir-best-practices-deep-research.md:26-55` | exact |
| `rulestead/lib/rulestead/error.ex` | model | request-response | `prompts/rulestead-engineering-dna-from-prior-libs.md:44-51` + `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:57-69` | doc-spec |
| `rulestead/lib/rulestead/store.ex` | behavior | request-response | `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:51-55` + `prompts/elixir-best-practices-deep-research.md:48-55` | doc-spec |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | `prompts/ecto-best-practices-deep-research.md:21-41,123-140,213-220` | doc-spec |
| `rulestead/lib/rulestead/fake.ex` | service | event-driven | `prompts/rulestead-testing-and-e2e-strategy.md:54-80` | doc-spec |
| `rulestead/lib/rulestead/{flag,environment,flag_environment,ruleset,audience,audit_event}.ex` | model | CRUD | `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:34-49` + `prompts/rulestead-domain-language-field-guide.md:96-131` + `prompts/ecto-best-practices-deep-research.md:43-59` | doc-spec |
| `rulestead/lib/rulestead/ruleset/{rule,condition,variant,rollout}.ex` | model | transform | `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:41-49` + `prompts/rulestead-domain-language-field-guide.md:22-40,102-110` | doc-spec |
| `rulestead/lib/mix/tasks/rulestead.install.ex` | utility | file-I/O | `.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:77-85` + `prompts/rulestead-engineering-dna-from-prior-libs.md:217-225` | doc-spec |
| `rulestead/priv/repo/migrations/*.exs` | migration | CRUD | `rulestead/priv/repo/migrations/.keep` + `.planning/ROADMAP.md:64-75` + `prompts/ecto-best-practices-deep-research.md:89-99,183-209` | partial |
| `rulestead/test/test_helper.exs` | test | request-response | `rulestead/test/test_helper.exs` + `prompts/rulestead-testing-and-e2e-strategy.md:25-40` | exact |
| `rulestead/test/rulestead/**/*_test.exs` | test | CRUD | `rulestead/test/rulestead_test.exs` + `prompts/rulestead-testing-and-e2e-strategy.md:128-213` | partial |

## Pattern Assignments

### `rulestead/mix.exs` (config, request-response)

**Analog:** [rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:1)

**Package boundary and docs wiring** ([rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:4)):
```elixir
@version "0.1.0"
@source_url "https://github.com/szTheory/rulestead"
@homepage_url "https://hexdocs.pm/rulestead"

def project do
  [
    app: :rulestead,
    version: @version,
    elixir: "~> 1.17",
    start_permanent: Mix.env() == :prod,
    deps: deps(),
    package: package(),
    docs: docs(),
    dialyzer: dialyzer()
  ]
end
```

**Whitelist discipline to preserve** ([rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:35)):
```elixir
defp package do
  [
    name: "rulestead",
    description: "Runtime decisions, made clear.",
    licenses: ["MIT"],
    links: %{
      "GitHub" => @source_url,
      "HexDocs" => @homepage_url,
      "Changelog" => "#{@source_url}/blob/main/rulestead/CHANGELOG.md",
      "Guides" => "#{@source_url}/tree/main/guides"
    },
    files:
      ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
  ]
end
```

**Phase 1 package-boundary rule** ([01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:191)):
```elixir
files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
# MUST never contain: test/example/, prompts/, .planning/, rulestead_admin/ (sibling), scripts/, docker-compose.yml
```

**Apply in Phase 2:** extend `deps/0` and `application/0` inside `rulestead/` only. Do not add `rulestead_admin/` paths or Phase 5/8 docs to `package.files`.

---

### `rulestead/lib/rulestead.ex` (model, request-response)

**Analog:** [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:1)

**Root public-surface pattern** ([rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:1)):
```elixir
defmodule Rulestead do
  @moduledoc """
  Root public module for the `rulestead` package.

  Phase 1 intentionally keeps the public API minimal while the package
  boundary, release tooling, and documentation surface settle.
  """

  @version Mix.Project.config()[:version] || "0.1.0"

  @doc """
  Returns the package version.
  """
  @spec version() :: String.t()
  def version, do: @version
end
```

**Namespace rule to preserve** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:44)):
```text
Root module (`Rulestead`) is the public surface.
Internal modules use `@moduledoc false` to lock the public API.
```

**API-shape rule to copy** ([prompts/elixir-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/elixir-best-practices-deep-research.md:48)):
```text
For public APIs, pick one of these patterns and stay consistent:
- {:ok, value} | {:error, reason}
- non-bang + bang pair: foo/1 and foo!/1
```

**Apply in Phase 2:** add the first public store/evaluation stubs here only if they are part of the stable public surface. Keep schema and adapter modules internal unless intentionally public.

---

### `rulestead/lib/rulestead/error.ex` (model, request-response)

**Analog:** [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:57) + [prompts/elixir-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/elixir-best-practices-deep-research.md:48)

**Locked Phase 2 error envelope** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:57)):
```text
Lock one concrete public `%Rulestead.Error{}` struct as the stable error envelope.
Non-bang APIs return `{:error, %Rulestead.Error{}}`; bang APIs raise that same struct.
Fields: :domain, :type, :message, :metadata, :details, :cause, optional :plug_status.
Exclude :cause from Jason.Encoder.
```

**Public return-shape rule** ([prompts/elixir-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/elixir-best-practices-deep-research.md:50)):
```elixir
{:ok, value} | {:error, reason}
foo/1 and foo!/1
```

**Public-root ownership rule** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:51)):
```text
Root module (`Rulestead`) is the public surface (reflection + orchestration + error types).
```

**Apply in Phase 2:** make `%Rulestead.Error{}` the single stable wire/runtime shape. If helper namespaces like `Rulestead.StoreError` exist, they should construct the same root struct instead of introducing competing public structs.

---

### `rulestead/lib/rulestead/store.ex` (behavior, request-response)

**Analog:** [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:51)

**Locked behavior contract** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:51)):
```text
`Rulestead.Store` is a domain-command, key-first behavior, not an `Ecto.Repo`-style CRUD abstraction.
Public selectors should be `flag_key` and `environment_key`; internal UUIDs stay private.
All non-bang public store-facing APIs return `{:ok, value} | {:error, %Rulestead.Error{}}`.
```

**Naming rule to copy** ([prompts/elixir-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/elixir-best-practices-deep-research.md:138)):
```text
behaviours: noun or role modules
dangerous/raising variants: end in !
```

**Future-facing behavior doc contract** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:150)):
```text
`api_stability.md` will enumerate locked public surface, including behaviour modules and function arities.
```

**Apply in Phase 2:** define semantic callbacks around fetch/save/publish/archive/list operations. Avoid generic `insert/update/delete` callbacks and avoid IDs in the public contract.

---

### `rulestead/lib/rulestead/store/ecto.ex` (service, CRUD)

**Analog:** [prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:21)

**Boundary/orchestration pattern** ([prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:23)):
```text
Expose public operations from your context, not from schema modules.
Keep schemas thin.
Keep Repo.* at the edges: context functions, repos, adapters.
```

**Changeset/constraint discipline** ([prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:71)):
```text
Use changesets for casting/validation/constraint translation.
Use DB constraints as the source of truth.
Pair friendly validations with real unique indexes + unique_constraint/3.
```

**Transaction pattern** ([prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:213)):
```text
Use Repo.transact(fn -> ... end) for simple linear workflows.
Use Ecto.Multi when the operation graph is dynamic or introspection helps.
```

**Apply in Phase 2:** keep Ecto-specific persistence inside this adapter. Put multi-row publish/pointer-flip operations behind `Repo.transact/1` or `Ecto.Multi`, and keep DB constraint mapping close to the adapter.

---

### `rulestead/lib/rulestead/fake.ex` (service, event-driven)

**Analog:** [prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:54)

**Fake adapter shape** ([prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:54)):
```elixir
defmodule Rulestead.Fake do
  @moduledoc """
  In-memory fake for tests. Deterministic bucketing, time-advanceable cache,
  trait-injectable actor resolver. This is the release-gate test target.
  """

  use GenServer

  # Public test API
  def put_flag(name \\ :default, key, attrs), do: ...
  def clear(name \\ :default), do: ...
  def advance_time(name \\ :default, duration), do: ...
end
```

**Locked fidelity rule** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:71)):
```text
`Rulestead.Fake` must implement the same semantic contract as `Rulestead.Store.Ecto`.
Extra test affordances must live outside `Rulestead.Store` in test-only modules.
```

**Apply in Phase 2:** keep the fake contract-faithful to the store behavior. If time controls or recording helpers are needed, keep them outside the shared store behavior.

---

### `rulestead/lib/rulestead/{flag,environment,flag_environment,ruleset,audience,audit_event}.ex` (model, CRUD)

**Analog:** [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:34) + [prompts/rulestead-domain-language-field-guide.md](/Users/jon/projects/rulestead/prompts/rulestead-domain-language-field-guide.md:96)

**Locked relational boundary** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:34)):
```text
One canonical `Flag` identity plus explicit environment-scoped behavior rows.
Use relational tables for `flags`, `environments`, and `flag_environments`.
`Ruleset` is the versioned publishing unit.
`Audience` remains relational and reusable.
```

**Canonical noun set** ([prompts/rulestead-domain-language-field-guide.md](/Users/jon/projects/rulestead/prompts/rulestead-domain-language-field-guide.md:96)):
```text
Flag, Ruleset, Rule, Condition, Audience, Variant, Rollout, Audit event, Environment
```

**Schema-thin rule** ([prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:43)):
```text
Schemas should describe fields, associations, embeds, maybe a few helpers,
but not become the dumping ground for business workflows.
```

**Apply in Phase 2:** use these modules for field definitions, embeds, changesets, and associations. Keep publish/save/archive orchestration out of the schemas.

---

### `rulestead/lib/rulestead/ruleset/{rule,condition,variant,rollout}.ex` (model, transform)

**Analog:** [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:41) + [prompts/rulestead-domain-language-field-guide.md](/Users/jon/projects/rulestead/prompts/rulestead-domain-language-field-guide.md:22)

**Locked embed boundary** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:41)):
```text
Embedded schemas stored as JSONB inside `rulesets` for the owned ordered rule graph:
`Rule`, `Condition`, `Variant`, and per-rule rollout/bucketing config.
Do not fully normalize rules/conditions/variants into standalone tables.
```

**Vocabulary to preserve** ([prompts/rulestead-domain-language-field-guide.md](/Users/jon/projects/rulestead/prompts/rulestead-domain-language-field-guide.md:22)):
```text
Use `Rule`, `Condition`, `Variant`, and `Rollout`.
Do not leak FunWithFlags-style `gate` terminology into code or docs.
```

**Apply in Phase 2:** model ordered, owned ruleset content as embedded schemas. Reusable targeting entities stay separate as `Audience`, not embedded duplicates.

---

### `rulestead/lib/mix/tasks/rulestead.install.ex` (utility, file-I/O)

**Analog:** [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:77) + [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:217)

**Locked Phase 2 installer scope** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:77)):
```text
Phase 2 `mix rulestead.install` may resolve/require a repo,
write migrations, write `config/rulestead.exs`,
and add `import_config "rulestead.exs"` to `config/config.exs` if absent.
It must be idempotent and must not modify router.ex, endpoint.ex, application.ex,
Oban config, PubSub wiring, admin mounts, or auth policy modules.
```

**Future installer architecture to stay compatible with** ([prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:217)):
```text
Feature-walker architecture:
`Rulestead.Install.Feature`, `Rulestead.Install.Runner`,
central migration timestamp allocation, idempotent reruns.
```

**Apply in Phase 2:** implement only the minimal slice, but shape the task so Phase 5 can grow it into the feature-walker installer instead of replacing it.

---

### `rulestead/priv/repo/migrations/*.exs` (migration, CRUD)

**Analog:** [rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:46) + [ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:64) + [prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:89)

**Packaging path already whitelisted** ([rulestead/mix.exs](/Users/jon/projects/rulestead/rulestead/mix.exs:46)):
```elixir
files:
  ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md SECURITY.md)
```

**Locked migration requirements** ([ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:64)):
```text
Postgres migrations with partial unique indexes, `gen_random_uuid()` defaults,
soft-delete columns, and ExUnit Ecto sandbox compatibility.
```

**Constraint-first rule** ([prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:89)):
```text
Use DB constraints as the source of truth.
Pair user-facing validation with real unique indexes and constraint mapping.
```

**Apply in Phase 2:** keep migrations library-owned under `rulestead/priv/repo/migrations/`; the installer copies them into host apps later. Prefer DB-level uniqueness and FK enforcement over app-only checks.

---

### `rulestead/test/test_helper.exs` (test, request-response)

**Analog:** [rulestead/test/test_helper.exs](/Users/jon/projects/rulestead/rulestead/test/test_helper.exs:1) + [prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:25)

**Current local bootstrap** ([rulestead/test/test_helper.exs](/Users/jon/projects/rulestead/rulestead/test/test_helper.exs:1)):
```elixir
ExUnit.start()
```

**Target Phase 2 bootstrap** ([prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:27)):
```elixir
ExUnit.start(exclude: [:golden, :integration, :browser, :load])

Mox.defmock(Rulestead.StoreMock, for: Rulestead.Store)
Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, :manual)

Rulestead.Fake.start_link!(name: :default)
```

**Roadmap lock** ([ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:75)):
```text
ExUnit Ecto sandbox `mode: :manual` scaffolding in `test/test_helper.exs`
```

**Apply in Phase 2:** evolve the existing helper rather than replacing the structure wholesale. Keep tag exclusions and fake bootstrapping here; do not invent Phase 5 golden/browser wiring yet beyond exclusions.

---

### `rulestead/test/rulestead/**/*_test.exs` (test, CRUD)

**Analog:** [rulestead/test/rulestead_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead_test.exs:1) + [prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:128)

**Current minimal shape** ([rulestead/test/rulestead_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead_test.exs:1)):
```elixir
defmodule RulesteadTest do
  use ExUnit.Case, async: true

  test "the package root module loads" do
    assert Rulestead.version() == "0.1.0"
  end
end
```

**Target test suite expansion** ([prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:132)):
```text
Every `lib/rulestead/` public module has a corresponding test module.
Cover flags, rulesets, explain/evaluate behavior, invalid weights,
not-found cases, archived/read-only behavior, and contract parity.
```

**Contract-test rule** ([02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:72)):
```text
Write one shared adapter contract suite and run it against both adapters.
```

**Apply in Phase 2:** keep the existing simple ExUnit style, then add focused tests per public module plus one adapter-contract suite shared by Ecto and Fake.

## Shared Patterns

### Monorepo Boundary
**Sources:** [AGENTS.md](/Users/jon/projects/rulestead/AGENTS.md:1), [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:73), [rulestead_admin/mix.exs](/Users/jon/projects/rulestead/rulestead_admin/mix.exs:32)
```text
Rulestead is a sibling-package monorepo.
Phase 2 work stays in `rulestead/`.
Keep the linked-version two-package shape intact.
Do not pull runtime/data-model code into `rulestead_admin/`.
```

### Admin Package Must Remain A Stub
**Sources:** [rulestead_admin/lib/rulestead_admin/router.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/router.ex:1), [scripts/ci/admin_publish_guard.sh](/Users/jon/projects/rulestead/scripts/ci/admin_publish_guard.sh:1), [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:112)
```elixir
defmacro rulestead_admin(path, opts \\ []) do
  quote bind_quoted: [path: path, opts: opts] do
    raise ArgumentError,
          "rulestead_admin: admin UI ships in Phases 6-7 of v0.1.0; track progress at ../../.planning/ROADMAP.md"
  end
end
```

```bash
if rg -n "Phases 6-7 of v0\\.1\\.0" "${ROUTER_FILE}" >/dev/null; then
  echo "refusing admin publish while ${ROUTER_FILE} still contains the Phase 1 stub" >&2
  exit 1
fi
```

**Apply to:** all Phase 2 planning

**Rule:** Phase 2 may add schema groundwork for `ADMIN-08`, but must not turn on admin routing, publishing, or host-app mounts.

### Formatter / Credo / Package Surface
**Sources:** [.formatter.exs](/Users/jon/projects/rulestead/.formatter.exs:1), [.credo.exs](/Users/jon/projects/rulestead/.credo.exs:1), [01-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/01-repo-bootstrap/01-CONTEXT.md:310)
```elixir
[
  import_deps: [:phoenix, :ecto, :phoenix_live_view, :plug],
  inputs: [
    "{mix,.formatter}.exs",
    "rulestead/{config,lib,test,priv/repo/migrations}/**/*.{ex,exs}",
    "rulestead_admin/{config,lib,test,priv/repo/migrations}/**/*.{ex,exs}"
  ]
]
```

```elixir
%{
  configs: [
    %{
      name: "default",
      strict: true,
      requires: []
    }
  ]
}
```

**Apply to:** every new Elixir source file and migration

### Test Bootstrap And Release-Gate Posture
**Sources:** [ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:73), [prompts/rulestead-testing-and-e2e-strategy.md](/Users/jon/projects/rulestead/prompts/rulestead-testing-and-e2e-strategy.md:25), [prompts/rulestead-engineering-dna-from-prior-libs.md](/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md:126)
```text
`Rulestead.Fake` is the release-gate test target.
`test/test_helper.exs` should own sandbox manual mode and fake startup.
Real Postgres parity tests exist, but merge-blocking tests should stay Fake-first.
```

**Apply to:** `rulestead/test/test_helper.exs`, contract tests, fake/ecto parity tests

### Ecto Boundary And Transaction Discipline
**Sources:** [prompts/ecto-best-practices-deep-research.md](/Users/jon/projects/rulestead/prompts/ecto-best-practices-deep-research.md:23), [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:40)
```text
Keep schemas thin.
Keep Repo usage at adapter/context edges.
Use DB constraints as truth.
Use Repo.transact/1 or Ecto.Multi for publish/pointer-flip workflows.
Normalize entities with independent identity; embed owned ordered rule documents.
```

**Apply to:** schemas, changesets, `Rulestead.Store.Ecto`, migrations

### Phase Boundary For Installer Work
**Sources:** [ROADMAP.md](/Users/jon/projects/rulestead/.planning/ROADMAP.md:58), [02-CONTEXT.md](/Users/jon/projects/rulestead/.planning/phases/02-data-model-error-model-ecto-store-fake-adapter/02-CONTEXT.md:77)
```text
Phase 2 installer work is migration generator + config only.
Do not edit router.ex, endpoint.ex, application.ex, Oban config, PubSub wiring, or admin mounts.
Full host-app integration is Phase 5.
```

**Apply to:** `lib/mix/tasks/rulestead.install.ex` and any helper modules

## Must Remain Untouched In Phase 2

| File | Why |
|---|---|
| `rulestead_admin/lib/rulestead_admin/router.ex` | Phase 1 stub must remain until Phases 6-7; changing it breaks the publish guard and phase boundary. |
| `scripts/ci/admin_publish_guard.sh` | Encodes the Phase 1 admin-release safety invariant. |
| `rulestead_admin/lib/rulestead_admin.ex` | Keep admin package as a version-reflection stub only. |
| `rulestead_admin/mix.exs` | Preserve the env-swap sibling dependency and unpublished admin package boundary. |
| `release-please-config.json` | Linked-version monorepo release contract is already locked. |

## No Local Analog Found

Files or surfaces with no close in-repo implementation analog yet; planner should use the locked docs above rather than inventing new patterns:

| File / Surface | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/lib/rulestead/error.ex` | model | request-response | No existing error struct or exception hierarchy exists in the repo yet. |
| `rulestead/lib/rulestead/store.ex` | behavior | request-response | No existing behavior module exists in the repo yet. |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | No existing Ecto adapter or Repo-backed context exists in the repo yet. |
| `rulestead/lib/rulestead/fake.ex` | service | event-driven | No existing fake/in-memory adapter exists in the repo yet. |
| `rulestead/lib/rulestead/{flag,...}.ex` | model | CRUD | No existing schema modules exist beyond placeholder package modules. |
| `rulestead/lib/mix/tasks/rulestead.install.ex` | utility | file-I/O | No local Mix task exists yet; only the locked phase context defines the allowed slice. |

## Metadata

**Analog search scope:** `rulestead/`, `rulestead_admin/`, repo-root config, `.planning/`, `prompts/`, `scripts/ci/`
**Files scanned:** 20+
**Pattern extraction date:** 2026-04-23

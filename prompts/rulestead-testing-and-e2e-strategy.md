# Rulestead Testing & E2E Strategy

> **Purpose:** Define how rulestead is tested from unit → integration → browser, with a specific focus on the patterns feature-flag libs need that other Elixir libs don't (deterministic bucketing tests, ruleset-precedence property tests, simulate/explain equivalence tests).
>
> **Read alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.6 + §3.5 + `rulestead-release-engineering-and-ci.md` §2.

---

## 1. Testing pyramid

| Layer | Tool | Count | Speed | Blocks merge? |
|---|---|---|---|---|
| Unit | ExUnit + Mox + `Rulestead.Fake` | ~80% | fast | yes |
| Property | StreamData | ~5% | medium | yes |
| Installer golden-diff | Custom harness over `System.cmd` | 1 harness, 60+ fixture files | slow (5min) | yes (path-gated) |
| Phoenix integration | `Phoenix.ConnTest`, `Phoenix.LiveViewTest` | ~10% | fast | yes |
| Host-app smoke | HTTP + real Postgres via `test/example/` subproject | ~5% | medium | yes |
| Browser E2E | Playwright over `test/example/` | ~1% | slow | yes (curated set only) |
| Load / fidelity | Nightly advisory matrix | rare | slow | no |

**Principle:** the Fake adapter + unit + property tests catch 95% of bugs at millisecond speed. Everything else is either a proof surface (installer goldens, host-app smoke) or trust theater (browser E2E, load tests).

---

## 2. `test/test_helper.exs` shape

```elixir
ExUnit.start(exclude: [:golden, :integration, :browser, :load])

Mox.defmock(Rulestead.StoreMock, for: Rulestead.Store)
Mox.defmock(Rulestead.ActorResolverMock, for: Rulestead.ActorResolver)
Mox.defmock(Rulestead.RuleEngineMock, for: Rulestead.RuleEngine)
Mox.defmock(Rulestead.EvaluationCacheMock, for: Rulestead.EvaluationCache)
Mox.defmock(Rulestead.AuditStoreMock, for: Rulestead.AuditStore)

Ecto.Adapters.SQL.Sandbox.mode(Rulestead.Repo, :manual)

# Fake adapter registration for tests that don't need Ecto.
Rulestead.Fake.start_link!(name: :default)
```

Tags convention:

- Default: unit tests using Fake adapter, Ecto sandbox.
- `@tag :golden` — installer golden-diff.
- `@tag :integration` — hits real Postgres + test/example/ app.
- `@tag :browser` — Playwright.
- `@tag :load` — load/fidelity nightly.

Each tag has its own mix alias: `mix test.golden`, `mix test.integration`, `mix test.browser`, `mix test.load`.

---

## 3. `Rulestead.Fake` — the release-gate test target

Mailglass-style fake adapter, but adapted for flag domain. In-memory `GenServer` that holds flags/rulesets/audiences/rollouts and serves the same public API as the real evaluator.

```elixir
defmodule Rulestead.Fake do
  @moduledoc """
  In-memory fake for tests. Deterministic bucketing, time-advanceable cache,
  trait-injectable actor resolver. This is the release-gate test target —
  every merge-blocking unit test uses it.
  """

  use GenServer

  # Public test API
  def put_flag(name \\ :default, key, attrs), do: GenServer.call(via(name), {:put_flag, key, attrs})
  def remove_flag(name \\ :default, key),     do: GenServer.call(via(name), {:remove_flag, key})
  def clear(name \\ :default),                do: GenServer.call(via(name), :clear)
  def advance_time(name \\ :default, duration), do: GenServer.call(via(name), {:advance_time, duration})
  def force_variant(name \\ :default, flag_key, actor_id, variant),
    do: GenServer.call(via(name), {:force_variant, flag_key, actor_id, variant})
  def recorded_evaluations(name \\ :default),  do: GenServer.call(via(name), :recorded_evaluations)
  def recorded_audit_events(name \\ :default), do: GenServer.call(via(name), :recorded_audit_events)

  # Behaviour callbacks (Rulestead.Store, RuleEngine, EvaluationCache, AuditStore, ActorResolver).
  # ...
end
```

And test helpers that wrap it with ExUnit ergonomics:

```elixir
defmodule Rulestead.TestHelpers do
  @moduledoc """
  Public test helpers. Treated as public API — documented, version-stable.
  Host apps can use these in their own tests.
  """

  @doc """
  Set a flag value for the duration of a test.
  Cleans up in `on_exit`.
  """
  def with_flag(key, value, test_fn) when is_function(test_fn, 0) do
    Rulestead.Fake.put_flag(key, %{default_value: value, status: :active})
    try do: test_fn.(), after: Rulestead.Fake.remove_flag(key)
  end

  @doc "Persist a flag in the Fake store for the remainder of the test."
  def put_flag(key, attrs), do: Rulestead.Fake.put_flag(key, attrs)

  @doc "Clear all flags (use sparingly — prefer targeted cleanup)."
  def clear_flags, do: Rulestead.Fake.clear()

  @doc "Force a specific actor to bucket into a known variant."
  def seed_bucket(flag_key, actor_id, variant),
    do: Rulestead.Fake.force_variant(flag_key, actor_id, variant)

  @doc "Assert rulestead evaluated a flag during the block."
  defmacro assert_flag_evaluated(flag_key, do: block) do
    quote do
      count_before = length(Rulestead.Fake.recorded_evaluations())
      unquote(block)
      evals = Rulestead.Fake.recorded_evaluations()
      assert length(evals) > count_before
      assert Enum.any?(evals, &match?({^unquote(flag_key), _, _}, &1))
    end
  end
end
```

These helpers ship in `lib/rulestead/test_helpers.ex` (public, documented, in `api_stability.md`).

---

## 4. Unit tests — what gets covered

### 4.1 Per-module

Every `lib/rulestead/` public module has a corresponding `test/rulestead/` test module. Examples:

- `test/rulestead_test.exs` — `Rulestead.evaluate/3`, `enabled?/2`, `get_variant/2`, `explain/2` happy paths + error cases.
- `test/rulestead/context_test.exs` — `Context.new/1`, `from_conn/1`, `from_socket/1`, `from_job/1`.
- `test/rulestead/bucket_test.exs` — bucketing determinism, hash stability, salt effects.
- `test/rulestead/rule_engine/default_test.exs` — ordered-rules precedence, strategy dispatch.
- `test/rulestead/rollouts_test.exs` — advance / hold / rollback state machine.
- `test/rulestead/kill_switch_test.exs` — engage / release + audit emission.
- `test/rulestead/flags_test.exs` — CRUD + changeset validations + audit row on every mutation.
- `test/rulestead/rulesets_test.exs` — publish transitions draft → active, partial-unique-index enforcement, revert restores prior version.
- `test/rulestead/evaluations_test.exs` — explain/2 returns trace, simulate/2 returns delta.
- `test/rulestead/audit_test.exs` — timeline/2, export/2, immutability trigger enforcement (attempt UPDATE / DELETE → assert raises `Postgrex.Error{postgres: %{code: "45A01"}}`).
- `test/rulestead/optional_deps/*_test.exs` — feature-detection helpers.

### 4.2 Boundary cases specific to flags

These are the tests that are easy to forget and expensive to discover at runtime:

- **Missing targeting key on a percentage rollout** — should return default variant + warn in strict mode, fail-closed in strict+raise mode.
- **Empty ruleset** — falls through to `default_value`.
- **All rules fail to match** — falls through to `default_value`.
- **Rule matches but strategy produces no value** — returns `:error, %ConfigError{}`.
- **Audience key referenced by rule but audience missing** — returns `:error, %ConfigError{type: :audience_not_found}`.
- **Kill switch engaged** — returns the safe default regardless of rules, includes `:killswitch` in the debug trace.
- **Flag archived mid-evaluation** — returns default, emits `[:rulestead, :eval, :stale_used]` event.
- **Cache stale, store unreachable** — snapshot's last-known-good is served; telemetry emits `stale_used`.
- **Rollout percentage 0%** — nobody matches (except forced-variant overrides).
- **Rollout percentage 100%** — everyone matches.
- **Multivariate weights don't sum to 1** — store-level validation rejects in changeset.
- **Tenant mismatch** — flag for tenant A never leaks to tenant B; evaluator returns default-for-tenant-B (or not-found error if strict).
- **Concurrent publish + eval** — old snapshot version served until PubSub invalidates cache; no split-brain.

---

## 5. StreamData property tests

Deterministic bucketing is the single most-important property to test.

```elixir
defmodule Rulestead.BucketPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "same (flag_key, targeting_key) → same bucket across 10k runs" do
    check all flag_key <- StreamData.string(:ascii, min_length: 1, max_length: 32),
              targeting_key <- StreamData.string(:ascii, min_length: 1, max_length: 64) do
      bucket_a = Rulestead.Bucket.compute(flag_key, targeting_key)
      bucket_b = Rulestead.Bucket.compute(flag_key, targeting_key)
      assert bucket_a == bucket_b
    end
  end

  property "bucket is always in 0..9999" do
    check all flag_key <- StreamData.string(:ascii, min_length: 1),
              targeting_key <- StreamData.string(:ascii, min_length: 1) do
      bucket = Rulestead.Bucket.compute(flag_key, targeting_key)
      assert bucket in 0..9999
    end
  end

  property "different salt → different bucket for same key pair (with high probability)" do
    check all flag_key <- StreamData.string(:ascii, min_length: 8),
              targeting_key <- StreamData.string(:ascii, min_length: 8),
              salt_a <- StreamData.string(:ascii, min_length: 8),
              salt_b <- StreamData.string(:ascii, min_length: 8),
              salt_a != salt_b do
      bucket_a = Rulestead.Bucket.compute(flag_key, targeting_key, salt: salt_a)
      bucket_b = Rulestead.Bucket.compute(flag_key, targeting_key, salt: salt_b)
      # collision is possible but should be rare; we assert "with high probability"
      # via a separate aggregate test, not this per-run check
      assert is_integer(bucket_a) and is_integer(bucket_b)
    end
  end
end
```

Additional properties worth writing:

- **Ruleset precedence:** given an ordered ruleset, the first matching rule wins. Generate random rule lists, assert evaluator result matches a reference implementation.
- **Idempotency key convergence:** `Ecto.Multi` with the same idempotency key applied twice produces exactly one audit row.
- **Simulate/evaluate equivalence:** `simulate(ruleset, sample)` result on an actor must equal `evaluate(ruleset, actor.context)` for every actor in the sample.
- **Explain is a superset of evaluate:** `explain(flag, ctx).value == evaluate(flag, ctx).value`.

---

## 6. Installer golden-diff test (sigra-ported)

### 6.1 Fixture tree

```
test/fixtures/install_golden/
├── tree/
│   ├── config/dev.exs
│   ├── config/config.exs
│   ├── lib/rulestead_install_golden_tmp/application.ex
│   ├── lib/rulestead_install_golden_tmp/rulestead_admin_policy.ex
│   ├── lib/rulestead_install_golden_tmp_web/router.ex        # post-injection
│   ├── lib/rulestead_install_golden_tmp_web/rulestead_flags.ex
│   ├── mix.exs                                                # post-injection
│   ├── priv/repo/migrations/TIMESTAMP_create_rulestead_flags.exs
│   ├── priv/repo/migrations/TIMESTAMP_create_rulestead_rulesets.exs
│   ├── priv/repo/migrations/TIMESTAMP_create_rulestead_audiences.exs
│   ├── priv/repo/migrations/TIMESTAMP_create_rulestead_rollouts.exs
│   └── priv/repo/migrations/TIMESTAMP_create_rulestead_events.exs
└── STDOUT.txt        # captured + normalized stdout
```

60–80 files total. Migration timestamps are replaced with the literal string `TIMESTAMP_` so runs are deterministic; file contents are byte-identical.

### 6.2 Harness

```elixir
defmodule Rulestead.Install.GoldenDiffTest do
  use ExUnit.Case, async: false
  @moduletag :golden
  @moduletag timeout: 300_000  # 5-minute ceiling

  import Rulestead.Test.InstallFixture

  test "installer emits byte-identical tree" do
    %{tmp_root: tmp, stdout: stdout} = setup_tmp_app!(
      flags: []  # run installer with defaults
    )
    actual_tree  = normalize_tree(tmp, strip: ["deps/", "_build/", ".elixir_ls/"])
    actual_stdout = normalize_stdout(stdout)

    expected_tree_root = Path.join([__DIR__, "..", "..", "fixtures", "install_golden", "tree"])
    expected_stdout    = File.read!(Path.join([__DIR__, "..", "..", "fixtures", "install_golden", "STDOUT.txt"]))

    assert_tree_equal(expected_tree_root, actual_tree)
    assert String.trim(actual_stdout) == String.trim(expected_stdout)
  end
end
```

`Rulestead.Test.InstallFixture.setup_tmp_app!/1` (`test/support/install_fixture.ex`):

1. `System.cmd("mix", ["phx.new", app_name, "--no-assets", "--no-install"], cd: tmp_parent)` into unique tmp dir.
2. Patch `mix.exs` (Perl -0777 one-liner) to insert `{:rulestead, path: "..", override: true}` as first dep.
3. `System.cmd("mix", ["deps.get"], env: [{"MIX_ENV", "test"}])` — pipes `n` to Hex auth prompt (public packages work anonymously).
4. `mix compile` pre-pass (keeps dep-compile noise out of captured stdout).
5. Snapshot baseline file paths.
6. Run `mix rulestead.install --yes <opts>` with `stderr_to_stdout: true`.
7. Return `%{tmp_root, stdout, baseline_paths}`.

`normalize_tree/2` returns sorted list of `{normalized_rel_path, content}` tuples; migration timestamps replaced with `TIMESTAMP_`.

`assert_tree_equal/2` does set-equal on paths, then diffs content per file and renders a unified diff for the first divergent file. Raises with fixture-regeneration runbook pointer.

### 6.3 Paired idempotency test

```elixir
test "installer is idempotent on re-run" do
  %{tmp_root: tmp} = setup_tmp_app!()
  {output, 0} = System.cmd("mix", ["rulestead.install", "--yes"],
                           cd: tmp, stderr_to_stdout: true,
                           env: [{"MIX_ENV", "test"}])
  # Second run should only emit "already injected" or "skipping (already exists)" lines.
  assert output =~ "already injected"
  refute output =~ "* injecting"
end
```

### 6.4 Flag matrix

```elixir
@flag_matrix [
  {"defaults",      []},
  {"no-admin",      ["--no-admin"]},
  {"no-oban",       ["--no-oban"]},
  {"no-admin,oban", ["--no-admin", "--no-oban"]}
]

for {name, flags} <- @flag_matrix do
  test "installer compiles with flags: #{name}" do
    %{tmp_root: tmp} = setup_tmp_app!(extra_flags: unquote(flags))
    assert {_, 0} = System.cmd("mix", ["compile", "--warnings-as-errors"],
                               cd: tmp,
                               env: [{"MIX_ENV", "dev"}])
  end
end
```

Every flag combination must produce a **compiling** Phoenix app. This is what proves `Features.Admin` / `Features.Oban` don't reference each other.

### 6.5 CI path-gating

The `installer_path_gate` job in `ci.yml` runs this only when installer surfaces change:

```
priv/templates/rulestead.install/**
lib/rulestead/install/**
lib/mix/tasks/rulestead.install.ex
```

On `main` push, always runs.

---

## 7. Phoenix integration tests

### 7.1 Plug tests

```elixir
defmodule Rulestead.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test

  test "assigns a %Rulestead.Context{} onto conn" do
    conn = conn(:get, "/") |> Rulestead.Plug.call(Rulestead.Plug.init([]))
    assert %Rulestead.Context{} = conn.assigns.rulestead_context
  end

  test "resolves actor via configured resolver" do
    # ... configure Mox to return a known actor
  end
end
```

### 7.2 LiveView tests

```elixir
defmodule RulesteadAdmin.FlagIndexLiveTest do
  use RulesteadAdmin.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "lists flags scoped by tenant", %{conn: conn} do
    put_flag("checkout_v2", %{status: :active, tenant_id: "tenant_a"})
    put_flag("other",       %{status: :active, tenant_id: "tenant_b"})

    {:ok, view, html} = live(conn, ~p"/admin/flags?tenant=tenant_a")
    assert html =~ "checkout_v2"
    refute html =~ "other"
  end

  test "explain view renders trace" do
    # ...
  end

  test "simulate view renders delta", %{conn: conn} do
    # verifies stream_async result + delta rendering
  end
end
```

### 7.3 Oban worker tests

```elixir
use Oban.Testing, repo: Rulestead.Repo

test "rollout advance worker schedules next stage" do
  # ...
end
```

---

## 8. Host-app smoke (`test/example/`)

A real Phoenix subproject under `test/example/` with its own `mix.exs`, excluded from root `mix test` via:

```elixir
def project do
  [
    test_load_filters: [~r"^test/(?!example/|fixtures/)"],
    test_ignore_filters: [
      fn path -> String.starts_with?(path, "test/example/") end,
      fn path -> String.starts_with?(path, "test/fixtures/") end
    ],
    # ...
  ]
end
```

What it contains:

- `lib/example/application.ex` — supervision tree with `Rulestead` children
- `lib/example_web/router.ex` — `rulestead_admin "/admin/flags"` mounted
- `lib/example/rulestead_admin_policy.ex` — sample policy impl
- `priv/repo/migrations/` — full rulestead migration set
- `test/example/http_smoke_test.exs` — boots endpoint, GETs `/admin/flags`, asserts 200 + HTML
- `priv/playwright/` — Playwright suite

CI job:

```yaml
integration:
  runs-on: ubuntu-24.04
  services: { postgres: ... }
  steps:
    - uses: actions/checkout@...
    - uses: erlef/setup-beam@v1
    - run: |
        cd test/example
        mix deps.get
        mix ecto.create
        mix ecto.migrate
        mix test
        scripts/ci/admin-acceptance-smoke.sh
```

---

## 9. Browser E2E (Playwright)

### 9.1 Scope

A **small curated set** of merge-blocking flows. Do NOT attempt wide E2E coverage — Playwright is expensive.

- `flag-create-happy-path.spec.ts` — create flag, add rule, publish ruleset, see in list.
- `rollout-advance.spec.ts` — advance from 10% → 50%, verify audit row.
- `kill-switch.spec.ts` — engage kill switch, verify forced variant.
- `explain-a-decision.spec.ts` — lookup `(flag, actor)`, verify trace rendering.
- `simulate-ruleset.spec.ts` — draft change, run simulate, verify delta view.
- `audit-timeline.spec.ts` — filter audit log by flag, verify rows.
- `admin-dark-mode-checkpoint.spec.ts` — screenshot checkpoint (sigra pattern).

### 9.2 Config

Under `test/example/priv/playwright/`:
- `playwright.config.ts` — projects: chromium, mobile-chromium, dark-mode.
- `package.json` — separate from root.
- `tests/*.spec.ts`.

CI job (deferred until v0.6 — audit + explain + simulate shipped):

```yaml
browser:
  runs-on: ubuntu-24.04
  timeout-minutes: 30
  services: { postgres: ... }
  env:
    RULESTEAD_E2E_PORT: "4017"
  steps:
    - uses: actions/checkout@...
    - uses: erlef/setup-beam@v1
    - uses: actions/setup-node@v4
      with:
        node-version: "22"
        cache: "npm"
        cache-dependency-path: "test/example/priv/playwright/package-lock.json"
    - run: |
        cd test/example
        mix deps.get; mix ecto.create; mix ecto.migrate
        mix run --no-halt &
        SERVER_PID=$!
        sleep 5
        # Route warm-up loop (sigra pattern — pay compile-on-demand cost off-clock)
        for route in /admin/flags /admin/rulesets /admin/audit /admin/explain; do
          curl -s -o /dev/null "http://localhost:$RULESTEAD_E2E_PORT$route" || true
        done
        cd priv/playwright
        npm ci
        npx playwright install --with-deps chromium
        npm test
        kill $SERVER_PID
    - name: Upload failure artifacts
      if: failure()
      uses: actions/upload-artifact@v4
      with:
        name: rulestead-playwright-report
        path: test/example/priv/playwright/playwright-report/
        if-no-files-found: ignore
    - name: Upload admin checkpoints (always)
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: rulestead-admin-checkpoints
        path: test/example/priv/playwright/test-results/admin-checkpoints/
        if-no-files-found: ignore
```

### 9.3 GitHub Pages admin demo (deferred)

`playwright-github-pages.yml` publishes Playwright reports + admin screenshots to `gh-pages` with 7-day retention. Full sigra pattern — port when v0.6+ ships. Low priority until rulestead has a browseable admin demo worth publishing.

---

## 10. Load / fidelity (nightly advisory)

Not merge-blocking. Examples:

- **Bucketing parity across seeds** — 100k random actors, verify same bucket every run.
- **Evaluation latency p99** — assert <100µs local cache hit, <5ms store fallback.
- **Concurrent publish load** — 10 publishes/sec for 60s, verify no snapshot inconsistency.
- **PubSub invalidation lag** — 100 nodes, measure cache-invalidation propagation time.
- **Stale snapshot graceful degradation** — simulate store outage, verify evaluator keeps serving.

Schedule: `workflow_dispatch` + weekly cron. Reports via GitHub step summary, not merge-blocking.

---

## 11. Doc-contract tests (scrypath-ported)

`test/rulestead/docs_contract_test.exs` reads README / CONTRIBUTING / guides / workflow YAML / Mix task source into module attributes and asserts shared constants line up.

Examples of assertions to make:

- README config example parses via `Rulestead.Config.Schema`.
- `guides/flows/evaluation.md` code fences are valid Elixir and reference only public API.
- `guides/api_stability.md` module list matches `Rulestead.Internal.Docs.public_modules/0`.
- CI workflow `jobs:` keys match `CONTRIBUTING.md` job-id table.
- `CHANGELOG.md` contains an entry for the current `@version`.
- Post-publish verify script env-var names match the Mix task source.

This catches a lot of silent documentation drift.

---

## 12. Aliases + scripts

### `mix.exs` aliases

```elixir
defp aliases do
  [
    "test":             ["test --warnings-as-errors"],
    "test.golden":      ["test --only golden"],
    "test.integration": ["test --only integration"],
    "test.browser":     ["cmd --cd test/example/priv/playwright npm test"],
    "test.all":         ["test --include golden --include integration"],
    "test.host":        ["cmd --cd test/example mix test"],
    "ci.all":           ["format --check-formatted", "compile --warnings-as-errors",
                         "credo --strict", "test --warnings-as-errors",
                         "docs --warnings-as-errors", "hex.audit"]
  ]
end
```

### `scripts/ci/` shell wrappers

All scripts start with `set -euo pipefail` and handle both local + CI invocation. See `rulestead-release-engineering-and-ci.md` §14 for full list.

---

## 13. Fixture + seed patterns

- **Per-test Fake seeding** — default. `with_flag/3`, `put_flag/2`, `seed_bucket/3` helpers; `on_exit` cleanup.
- **Shared Ecto seeds** — `test/support/seeds.ex` with functions like `seed_sample_flag_suite/1` for integration tests.
- **`priv/repo/migrations/`-as-fixture** — the installer emits these; test/example/ runs them; nothing exotic.
- **Factory helpers** — optional. If used, prefer `ExMachina` + keep factories under `test/support/factories/*.ex`.

---

## 14. Mutation testing (optional, after v0.5)

Run `muzak` or equivalent quarterly to verify tests actually fail when bugs are introduced. Not a merge gate. Results inform which modules need stronger assertions.

---

## 15. Anti-patterns — don't

- Don't test the real Postgres evaluator in unit tests. Use Fake. If you want Postgres coverage, it goes in `test/example/` integration smoke.
- Don't use `async: false` unless you explicitly need global state mutations. Default to `async: true` with isolated Fake name per test.
- Don't assert on random bucketing outputs. Use property tests or forced-variant helpers.
- Don't test telemetry by attaching to global handlers and asserting. Use `:telemetry_test.attach_event_handlers/2` for the test's lifetime + detach in `on_exit`.
- Don't let `test/example/` contaminate root `mix test`. Verify `test_load_filters` / `test_ignore_filters` prevent it — and test that they do (meta-test).
- Don't browser-test every admin flow. Curate 6–10 merge-blocking flows.
- Don't skip the golden-diff idempotency paired test. Re-running the installer must be safe.
- Don't let Playwright flake block merges. If a browser test is flaky, quarantine + fix before it erodes trust in the CI gate.

---

## 16. TL;DR — the test-first rules

1. **Fake adapter is the default test target.** Real Postgres only for integration + host-app smoke.
2. **Property tests own bucketing determinism, ruleset precedence, and simulate/evaluate equivalence.**
3. **Golden-diff installer test + paired idempotency test** are merge-blocking, path-gated.
4. **Host-app smoke via `test/example/`** proves the library composes into a real Phoenix app.
5. **Playwright covers a curated 6–10 flows**, never wide coverage.
6. **Doc-contract tests** catch README/guides drift without humans chasing it.
7. **Tag discipline**: `:golden`, `:integration`, `:browser`, `:load` have their own aliases and CI lanes.
8. **Public test helpers (`with_flag/3`, `put_flag/2`, etc.) are part of `api_stability.md`** — host apps depend on them.

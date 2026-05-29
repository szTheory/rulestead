# Testing

Rulestead's supported test story in `v0.1.0` is Fake-first. The public helper
surface is `Rulestead.TestHelpers`, backed by `Rulestead.Fake`, so host apps
can test flag behavior without Postgres, runtime refresh processes, or admin UI
bootstrapping.

Use the Fake-backed path for merge-blocking tests. Save real-store coverage for
integration smoke, install verification, or your own app-specific confidence
checks.

## Add the helper import

```elixir
defmodule MyApp.CheckoutTest do
  use ExUnit.Case, async: true

  import Rulestead.TestHelpers
end
```

The shipped helper surface includes:

- `with_flag/3`
- `put_flag/3`
- `clear_flags/0`
- `seed_bucket/3`
- `assert_flag_evaluated/2`

## Scope a forced value to one block

Use `with_flag/3` when you want a temporary override that restores prior fake
state automatically:

```elixir
test "renders the redesign when the flag is enabled" do
  with_flag "checkout-redesign", true do
    assert {:ok, html} = MyApp.Checkout.render(%{targeting_key: "user-123"})
    assert html =~ "New checkout"
  end
end
```

This is the safest default for isolated behavior tests because it snapshots the
Fake state before the block and restores it afterward.

## Seed fake state for the current test

Use `put_flag/3` when you want a seeded flag to remain available for the rest
of the test:

```elixir
setup do
  clear_flags()
  :ok
end

test "returns the forced value from the fake-backed contract" do
  put_flag("beta-banner", false, environment: "test")

  assert {:ok, false} =
           Rulestead.Runtime.enabled?(
             "test",
             "beta-banner",
             %{targeting_key: "user-123", environment: "test"}
           )
end
```

`clear_flags/0` resets the in-memory Fake so adjacent tests do not leak authored
state into each other.

## Pin deterministic bucket outcomes

Use `seed_bucket/3` when you want one targeting key to land on a specific
variant through the same public contract your app uses:

```elixir
test "pins the blue variant for a specific user" do
  seed_bucket("checkout-color", "user-123", "blue")

  assert {:ok, "blue"} =
           Rulestead.Runtime.get_variant(
             "test",
             "checkout-color",
             %{targeting_key: "user-123", environment: "test"}
           )
end
```

This is the supported way to make multivariate tests deterministic. Do not
reach into hash or bucket internals from host-app tests.

## Assert that code actually evaluated a flag

Use `assert_flag_evaluated/2` when you need to prove a code path performed an
evaluation instead of accidentally bypassing it:

```elixir
test "checkout code emits the eval stop event" do
  put_flag("checkout-redesign", true)

  assert_flag_evaluated "checkout-redesign" do
    MyApp.Checkout.render!(%{targeting_key: "user-123"})
  end
end
```

The helper asserts against bounded telemetry metadata only. It does not expose
raw attributes or resolved values.

## Keep host-app tests on the public surface

Prefer these layers in application tests:

1. `Rulestead.TestHelpers` to seed state.
2. the keyed runtime evaluation surface for app code.
3. `Rulestead`, `Rulestead.Phoenix`, `Rulestead.LiveView`, and
   `Rulestead.Oban` where your integration actually uses those seams.

Avoid depending on:

- `Rulestead.Fake.Control` directly from app tests
- runtime cache internals
- installer fixture helpers from this repo

Those are library-maintenance details, not the supported published-package test
contract.

## Published-package smoke stays aligned with this story

The release proof for `v0.1.0` mirrors the same approach. The published package
must be usable in a fresh consumer app where tests seed flags through the
Fake-backed helper surface and install smoke validates the generated Phoenix
wiring separately.

That is why this guide stays aligned with
[`rulestead/test/rulestead/integration/install_smoke_test.exs`](/Users/jon/projects/rulestead/rulestead/test/rulestead/integration/install_smoke_test.exs:1)
instead of teaching path-dependency-only shortcuts.

## Lifecycle Release Surface

Lifecycle verification should stay on stable public seams.

Use this layered release-facing path:

1. docs and README content checks for lifecycle discoverability
2. `mix rulestead.lifecycle` contract tests for read-only text and JSON output
3. `release_contract_test.exs` for shared docs and sibling-package posture
4. one mounted host-seam check through `admin_mount_test.exs`

That is the supported lifecycle verification recipe. It proves the public seam
without turning internal LiveView structure into contract.

### Public Seam, Not Browser-Heavy Lock-In

Prefer these checks:

- `rulestead_lifecycle_test.exs` for CLI/report vocabulary and schema
- `release_contract_test.exs` for lifecycle guide discoverability
- `admin_mount_test.exs` for mount, route, query, and environment behavior

Avoid browser-heavy lifecycle assertions that freeze private DOM or CSS
structure. The mounted host seam is public; internal selectors are not.

## When to use the real store

Use the Ecto-backed store only when you are intentionally testing your own
host-app integration with migrations, runtime refresh supervision, PubSub
delivery, or operator workflows.

Those are integration concerns. They should not replace the Fake-backed
contract as your default application test surface.

## Integration and E2E confidence

Fake-backed tests should remain your default application test surface. Add
host-shaped confidence only when you need it.

| Layer | When to use | Command / path |
|-------|-------------|----------------|
| Fake helpers | Every app unit test | `import Rulestead.TestHelpers` |
| Installer golden-diff | First-hour Phoenix wiring | `scripts/demo/install_journey.sh` |
| FleetDesk adoption lab | Full stack + admin + browser glue | `scripts/demo/proof.sh` or `scripts/demo/verify.sh` |
| Library contract | Pre-merge / release bar | `cd rulestead && mix verify.adopter` |

See [Adoption Lab](../introduction/adoption-lab.md) for persona-oriented guidance
on when to run FleetDesk vs the install journey vs contract tests alone.

CI runs FleetDesk compose + Playwright on every merge (`integration (FleetDesk
adoption lab)`). Install journey runs on the `install_journey` scoped lane.

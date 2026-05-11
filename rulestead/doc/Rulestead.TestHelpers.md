# `Rulestead.TestHelpers`
[🔗](https://github.com/szTheory/rulestead/blob/v0.1.0/lib/rulestead/test_helpers.ex#L1)

Public fake-backed test helpers for host app tests.

# `assert_flag_evaluated`
*macro* 

Asserts that the enclosed code emits a matching eval stop event.

# `clear_flags`

```elixir
@spec clear_flags() :: :ok
```

Clears fake state for test isolation.

# `put_flag`

```elixir
@spec put_flag(String.t() | atom(), term(), keyword()) :: map()
```

Seeds a fake-backed flag for the remainder of the current test.

# `seed_bucket`

```elixir
@spec seed_bucket(String.t() | atom(), String.t() | atom(), String.t() | atom()) ::
  map()
```

Pins a variant assignment for one targeting key through the fake-backed contract.

# `with_flag`
*macro* 

Seeds a flag value for the duration of the block and restores prior fake state.

---

*Consult [api-reference.md](api-reference.md) for complete listing*

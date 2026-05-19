# Phase 26: API Lockdown & Documentation Perfection - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** `rulestead/lib/rulestead.ex`, `rulestead/lib/rulestead/result.ex`, `rulestead/lib/rulestead/flag.ex`, `rulestead/lib/rulestead/runtime/cache.ex`, `rulestead/mix.exs`, `guides/introduction/upgrading.md`
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead/lib/**/*.ex` (internal) | internal | internal | `rulestead/lib/rulestead/flag.ex` | exact |
| `rulestead/lib/**/*.ex` (public API) | public API | various | `rulestead/lib/rulestead.ex` | exact |
| `rulestead/mix.exs` | config | config | `rulestead/mix.exs` | exact |
| `rulestead_admin/mix.exs` | config | config | `rulestead/mix.exs` | exact |
| `guides/**/*.md` | documentation | static | `guides/introduction/upgrading.md` | exact |

## Pattern Assignments

### Internal Modules Boundary (`@moduledoc false`)

**Analog:** `rulestead/lib/rulestead/flag.ex`

**Module Documentation Pattern** (lines 1-3):
```elixir
defmodule Rulestead.Flag do
  @moduledoc false

```
*Rule*: All modules not intended for direct use by host apps or end-users MUST begin with `@moduledoc false` immediately after the `defmodule` declaration to prevent them from appearing in Hexdocs.

---

### Public API Structs and Types

**Analog:** `rulestead/lib/rulestead/result.ex`

**Type Definition Pattern** (lines 12-24):
```elixir
  @type reason :: :rule_match | :default | :targeting_key_missing | :flag_off | :error

  @type debug_trace :: map() | nil

  @type t :: %__MODULE__{
          value: term(),
          enabled?: boolean(),
          variant: String.t() | nil,
          reason: reason(),
          matched_rule: String.t() | nil,
          flag_key: String.t() | nil,
          flag_version: integer() | nil,
          cache_age_ms: integer() | nil,
          debug_trace: debug_trace()
        }
```
*Rule*: Public structs must clearly document their `@type t()`. Use specific types over generic `any()` or `term()` whenever possible to strengthen Dialyzer's static analysis.

---

### Public API Function Documentation and Typespecs

**Analog:** `rulestead/lib/rulestead.ex`

**Public Function Pattern** (lines 35-43):
```elixir
  @doc """
  Fetches the authored flag state for a `flag_key` and `environment_key`.
  """
  @spec fetch_flag(String.t() | atom(), String.t() | atom(), keyword()) :: Store.result(map())
  def fetch_flag(flag_key, environment_key, opts \\ []) do
```
*Rule*: Public functions MUST have `@doc """..."""` string documenting their behavior, followed immediately by an `@spec` defining argument types and return shapes.

---

### Internal Module Function Typespecs

**Analog:** `rulestead/lib/rulestead/runtime/cache.ex`

**Internal Function Pattern** (lines 36-38):
```elixir
  @spec register_environment(String.t() | atom()) :: :ok
  def register_environment(environment_key) do
```
*Rule*: Even modules with `@moduledoc false` must include comprehensive `@spec`s for all exported functions to ensure Dialyzer passes across the entire project graph.

---

### Hexdocs Configuration (`mix.exs`)

**Analog:** `rulestead/mix.exs`

**Docs Configuration Pattern** (lines 52-80):
```elixir
  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      homepage_url: @homepage_url,
      extras: [
        "README.md",
        "../CONVENTIONS.md",
        "../guides/introduction/installation.md",
        "../guides/introduction/getting-started.md",
        # ... new guides should be appended here
      ],
      skip_undefined_reference_warnings_on: fn ref ->
        is_binary(ref) and String.starts_with?(ref, "lib/")
      end
    ]
  end
```
*Rule*: Hexdocs structure uses the `extras` list in the `docs/0` private function. Any new guides (like the FunWithFlags migration guide or architecture documents) must be explicitly listed here with their path relative to `rulestead/`.

---

## Shared Patterns

### Dialyzer Strictness
**Source:** `rulestead/mix.exs`
**Apply to:** All elixir files
Dialyzer must pass with zero warnings. Follow strict type enforcement (`@spec`, `@type`) throughout the codebase. The configuration includes `flags: [:error_handling, :extra_return, :missing_return]` indicating strict Dialyzer tracking.

### Migration / Documentation Style
**Source:** `guides/introduction/upgrading.md`
**Apply to:** `guides/introduction/migrating-from-fun-with-flags.md`
Guides use a clear `# Heading 1`, followed by introductory paragraphs, and use `## Subheadings` and bulleted lists for easily readable developer guidance. Technical terms and code paths should be wrapped in backticks (e.g. `v0.1.x`, `CHANGELOG.md`).

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `guides/introduction/migrating-from-fun-with-flags.md` | documentation | static | First competitor migration guide. Follow `upgrading.md` formatting and markdown style, but content is entirely new. |

## Metadata

**Analog search scope:** `rulestead/lib/**/*.ex`, `guides/**/*.md`, `mix.exs`
**Files scanned:** 127 Elixir files, 18 Markdown guides
**Pattern extraction date:** 2024-05-24

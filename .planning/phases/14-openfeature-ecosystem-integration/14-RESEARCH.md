# Phase 14: OpenFeature Ecosystem Integration - Research

**Researched:** 2024-05-14
**Domain:** OpenFeature SDK Integration
**Confidence:** HIGH

## Summary

Operators can use the CNCF standard OpenFeature API to interact with Rulestead without vendor lock-in. OpenFeature defines an Elixir Provider behaviour (`OpenFeature.Provider`) which we must implement. The integration will wrap `Rulestead.Runtime.evaluate/3` to map standard generic flag evaluation requests into Rulestead's explicit context format and return standardized `ResolutionDetails`. 

**Primary recommendation:** Build `Rulestead.OpenFeature.Provider` that takes an `environment_key` on initialization, translates OpenFeature's flat string-map context to `Rulestead.Context.t`, and projects Rulestead's `Result.t` fields (including explainability metadata) into standard `ResolutionDetails`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Standard Interface | API / Backend | — | Provides a vendor-neutral facade for flag evaluation. |
| Context Translation | API / Backend | — | Maps OpenFeature's weakly-typed context payload to Rulestead's strictly normalized structural context. |
| Explainability Export | API / Backend | — | Bridges Rulestead's rich trace maps into the `flag_metadata` boundary supported by OpenFeature. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| open_feature | ~> 0.1.3 | Standard OpenFeature Elixir API | The official CNCF SDK published to Hex.pm. |

**Installation:**
```bash
# (Added to rulestead/mix.exs as an optional dependency)
{:open_feature, "~> 0.1.3", optional: true}
```
*Note: Because OpenFeature is a CNCF standard but operators might not want the extra dependency if using Rulestead natively, `open_feature` should be an optional dependency.*

## Architecture Patterns

### Recommended Project Structure
```
rulestead/
├── lib/
│   └── rulestead/
│       └── open_feature/
│           └── provider.ex     # Implements OpenFeature.Provider behaviour
└── test/
    └── rulestead/
        └── open_feature/
            └── provider_test.exs
```

### Pattern 1: Mapping Contexts (ECO-02)
**What:** OpenFeature provides a flat map for Context, whereas Rulestead uses a rich Struct with predefined explicit fields.
**When to use:** In every `resolve_*` callback.
**Example:**
```elixir
defp translate_context(of_context) when is_map(of_context) do
  # Extract known standardized keys, pass the rest as attributes
  {known, attrs} = Map.split(of_context, ["targetingKey", "tenantKey", "environment", "sessionId", "requestId", "actor"])
  
  Rulestead.Context.new(
    targeting_key: known["targetingKey"],
    tenant_key: known["tenantKey"],
    environment: known["environment"],
    session_id: known["sessionId"],
    request_id: known["requestId"],
    actor: known["actor"],
    attributes: attrs
  )
end
```

### Pattern 2: Exposing Explainability (ECO-03)
**What:** Rulestead tracks cache age, rule matches, and trace information that isn't native to OpenFeature's first-class fields.
**When to use:** When building the `ResolutionDetails` return struct.
**Example:**
```elixir
defp build_flag_metadata(%Rulestead.Result{} = result) do
  %{}
  |> maybe_put("matched_rule", result.matched_rule)
  |> maybe_put("flag_version", result.flag_version)
  |> maybe_put("cache_age_ms", result.cache_age_ms)
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Standard Interface | Custom evaluation facade | `OpenFeature.Provider` | CNCF standardization allows operators to hot-swap vendors with zero application code changes. |
| Error code translation | Custom errors | Map to `OpenFeature.Types.error_code()` | Conforms to OpenFeature standard error handling. |

## Common Pitfalls

### Pitfall 1: Missing Environment Context
**What goes wrong:** OpenFeature standard doesn't strictly mandate "environment" out-of-the-box in its initialization, but `Rulestead.Runtime.evaluate` requires it.
**Why it happens:** Most generic systems use entirely separate connections per environment.
**How to avoid:** Define the `environment_key` explicitly in the `Rulestead.OpenFeature.Provider` struct during initialization so all `resolve_*` calls can inject it automatically. 

### Pitfall 2: Complex Trace Data in Metadata
**What goes wrong:** Provider crashes when trying to return `ResolutionDetails`.
**Why it happens:** `OpenFeature.Types.flag_metadata()` strictly allows string keys and `boolean | string | number` values. Rulestead's `debug_trace` contains complex nested maps and lists.
**How to avoid:** Flatten the most critical telemetry (rule name, cache age, version) into scalar string/number properties for the `flag_metadata` block instead of dumping the raw trace. 

## Code Examples

### Standard Provider Structure
```elixir
defmodule Rulestead.OpenFeature.Provider do
  @behaviour OpenFeature.Provider
  alias OpenFeature.ResolutionDetails

  defstruct name: "Rulestead", state: :not_ready, environment_key: nil

  @impl true
  def initialize(%{environment_key: env} = provider, _domain, _context) when not is_nil(env) do
    {:ok, %{provider | state: :ready}}
  end
  
  @impl true
  def resolve_boolean_value(provider, key, default, context) do
    do_resolve(provider, key, default, context)
  end
  
  # Delegate to Rulestead.Runtime.evaluate/3 and map Results
end
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| open_feature | OpenFeature integration | ✓ | ~> 0.1.3 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/rulestead/open_feature/provider_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ECO-01 | Implements required Provider callbacks | unit | `mix test test/rulestead/open_feature/provider_test.exs` | ❌ Wave 0 |
| ECO-02 | Translates map context to struct context | unit | `mix test test/rulestead/open_feature/provider_test.exs` | ❌ Wave 0 |
| ECO-03 | Populates ResolutionDetails metadata | unit | `mix test test/rulestead/open_feature/provider_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/rulestead/open_feature/provider_test.exs` — covers ECO-01, ECO-02, ECO-03

## Sources

### Primary (HIGH confidence)
- Hex Registry (verified) - `mix hex.info open_feature`
- `rulestead/lib/rulestead/runtime.ex` - Checked local implementation of `Rulestead.Runtime.evaluate/3`.
- `rulestead/lib/rulestead/error.ex` - Verified mapping between internal errors and OpenFeature codes.
- Compiled `OpenFeature.Types` and `OpenFeature.Provider` inside Elixir session - Verified specs and metadata constraints.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `open_feature` is standard.
- Architecture: HIGH - Mapped correctly between Rulestead Context and OpenFeature flat maps.
- Pitfalls: HIGH - Elixir Type specs confirmed the limit on `flag_metadata` values.

**Research date:** 2024-05-14
**Valid until:** 2024-11-14
<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 (Code Reference Detection):** Implement a **Passive (External CI Scanner)** approach. Rulestead will provide a Mix task (e.g., `mix rulestead.code_refs`) that the host application runs within its existing CI/CD pipeline to parse the Elixir AST and push results to Rulestead via an API endpoint. This ensures a minimal security blast radius and VCS independence. (Requirements: LCH-02)
- **D-02 (Stale Flag Identification):** Use a **Type-Aware Hybrid Model (Telemetry + State)**. A flag is identified as stale if its configuration has been in a terminal state (e.g., 100% rollout) for > 30 days AND a lightweight telemetry check (`last_evaluated_at` via ETS write-behind + Oban worker) confirms it has only served one variant. "Kill Switch" and "Operational" flags are structurally exempt. (Requirements: LCH-01)
- **D-03 (Admin UI Cleanup Workflow):** Use **Contextual Manual Action**. The Admin UI will use passive drift detection (displaying a subtle "possibly stale" badge) and enforce a strict pre-flight checklist modal when the operator manually initiates the archival process. The modal dynamically surfaces remaining code references to ensure safe archival without auto-generating system Change Requests. (Requirements: LCH-03)

### the agent's Discretion
None listed explicitly in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
- This phase focuses exclusively on discovering stale flags and capturing code references for presentation.
- Do not automate the removal or archiving of flags. The operator must always remain in the loop (preview -> confirm -> audit).
- Code parsing is restricted to the host application's environment (passive). Rulestead should not clone repositories or read source code directly.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LCH-01 | Implement detection mechanisms for stale flags (e.g., flags fully rolled out to 100% for an extended period, no traffic, or explicitly marked for deprecation). | ETS table caching + Oban write-behind worker approach is viable without adding heavy core dependencies. |
| LCH-02 | Create an integration (e.g., GitHub Action or external webhook receiver) capable of finding code references to Rulestead flags within the host application repository and reporting them to the platform. | Mix task parsing Elixir AST (`Code.string_to_quoted` / `Macro.prewalk`) and pushing to Rulestead's Admin API. |
| LCH-03 | Expose stale flag management and code reference discovery workflows in the Rulestead Admin UI to guide operators in safely removing obsolete flags. | Phoenix LiveView integration (badges, checklist modals) retrieving data pushed by the CI task. |
</phase_requirements>

# Phase 15: Lifecycle Hygiene & Code References - Research

**Researched:** 2024-05
**Domain:** Code Analysis & Admin UI Workflows
**Confidence:** HIGH

## Summary

This phase introduces lifecycle hygiene management by detecting stale feature flags and tracing their references in the host application's codebase. The research confirms that the standard Elixir `Code` and `Macro` modules are sufficient for the passive CI scanner (Mix task) to parse Elixir AST safely and efficiently without introducing heavy dependencies like `Sourceror`. Stale flag detection will utilize ETS for high-throughput write-behind caching of `last_evaluated_at`, flushed via Rulestead-provided Oban workers. The Admin UI will visually flag these states and provide a governed manual workflow for safe removal.

**Primary recommendation:** Use Elixir's native `Macro.prewalk/3` in the Mix task for code reference parsing to maintain a zero-dependency footprint in `rulestead`, and rely on the host's existing Oban integration for ETS write-behind flushes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Stale Flags Telemetry Cache** | API / Backend | Database | ETS tables process high-volume `last_evaluated_at` updates. Oban flushes to Postgres asynchronously. |
| **Code Reference Detection (CI)** | Client / CI | API / Backend | A minimal Mix task (`mix rulestead.code_refs`) processes AST locally in CI, then pushes JSON to a Rulestead endpoint. |
| **Cleanup UI Workflow** | Frontend (LiveView) | API / Backend | Renders stale state and checklists based on telemetry data and code references stored in the database. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Code` / `Macro` (Elixir core) | >= 1.17 | Code Reference Detection | Zero dependencies required; standard for Elixir AST processing. |
| `:ets` (Erlang core) | N/A | Telemetry Caching | Handles high-concurrency evaluation tracing with no DB bottleneck. |
| `Oban` (Host provided) | ~> 2.17 | Write-Behind worker | Rulestead already assumes Oban for Background Jobs/Scheduled execution (via `Rulestead.Oban`). |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Macro.prewalk` | `Sourceror` | `Sourceror` offers better zipper/modification, but we only need passive reading (AST traversal), making `Macro.prewalk` much lighter. |

## Architecture Patterns

### Recommended Project Structure
```
rulestead/
├── lib/rulestead/code_refs/
│   ├── scanner.ex        # Elixir AST traversal logic
│   └── client.ex         # HTTP client pushing results to Admin API
├── lib/mix/tasks/
│   └── rulestead.code_refs.ex
├── lib/rulestead/telemetry/
│   └── cache.ex          # ETS wrapper for last_evaluated_at
└── lib/rulestead/oban/
    └── telemetry_flush_worker.ex
rulestead_admin/
└── lib/rulestead_admin/live/
    └── flag_cleanup_modal_component.ex
```

### Pattern 1: Native AST Traversal
**What:** Use standard Elixir AST tooling to search for Rulestead flag references.
**When to use:** Detecting `Rulestead.evaluate("flag_key")` within host application's `.ex` files during CI/CD.
**Example:**
```elixir
{:ok, ast} = Code.string_to_quoted(file_content)
{_, references} = Macro.prewalk(ast, [], fn
  {{:., _, [{:__aliases__, _, [:Rulestead]}, :evaluate]}, meta, [key]}, acc when is_binary(key) ->
    {nil, [{key, meta[:line]} | acc]}
  node, acc ->
    {node, acc}
end)
```

### Pattern 2: ETS Write-Behind Cache
**What:** Instead of updating the DB on every evaluation, bump an ETS table counter and periodically persist it.
**When to use:** Tracking `last_evaluated_at` and `variants_served` for stale flag detection without crippling DB performance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AST Parsing Regex | Regex searches for flag keys | `Code.string_to_quoted/2` | Regex fails on multi-line strings, macro usage, and commented-out code. AST is deterministic. |
| Background Flushing | Custom `Task` loops for ETS sync | `Oban` | Rulestead already ships with `Rulestead.Oban` patterns; rely on the host's durable Oban job queue for flushing telemetry. |

## Common Pitfalls

### Pitfall 1: AST Node Structure Variations
**What goes wrong:** The AST pattern match misses indirect usages like alias imports (e.g. `alias Rulestead, as: RS`).
**Why it happens:** Hardcoding the exact AST tuple (`{:__aliases__, _, [:Rulestead]}`) ignores `alias` context which the compiler normally resolves.
**How to avoid:** The Mix task documentation should strongly recommend that teams evaluate flags using the fully qualified `Rulestead.evaluate/2` or specifically handle known alias nodes if dynamic matching is needed.

### Pitfall 2: CI Task Authentication
**What goes wrong:** The host app CI pipeline fails to push results because the Admin UI is protected by authentication.
**Why it happens:** The endpoint to receive code references requires a valid session or API key, but CI doesn't have one.
**How to avoid:** Ensure the platform supplies a designated CI/CD Service Token mechanism or secure Webhook ingress for the `rulestead.code_refs` Mix task to use.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir `Code` Module | Code Ref Scanner | ✓ | >= 1.17 | — |
| `Oban` | Telemetry Flush | ✓ | ~> 2.17 | Host application requirement |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LCH-01 | ETS cache updates on evaluation | unit | `mix test test/rulestead/telemetry/cache_test.exs` | ❌ Wave 0 |
| LCH-01 | Oban worker flushes ETS to DB | unit | `mix test test/rulestead/oban_telemetry_flush_worker_test.exs` | ❌ Wave 0 |
| LCH-02 | Mix task parses correct line numbers | unit | `mix test test/rulestead/code_refs/scanner_test.exs` | ❌ Wave 0 |
| LCH-03 | Admin UI renders stale badges | unit (LiveView) | `mix test test/rulestead_admin/live/flag_cleanup_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/rulestead/code_refs/scanner_test.exs` — covers LCH-02 AST parsing edge cases.
- [ ] `test/rulestead/telemetry/cache_test.exs` — covers LCH-01 high-concurrency ETS caching logic.
- [ ] `test/rulestead_admin/live/flag_cleanup_test.exs` — covers LCH-03 LiveView modal state management.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Admin API endpoint must authenticate CI/CD incoming pushes (Token). |
| V5 Input Validation | yes | Incoming JSON from the Mix task must be sanitized (Ecto Changeset). |

### Known Threat Patterns for Elixir / Mix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI Scanner API Abuse | Spoofing | Validate a specific API key generated from the Admin UI for code refs ingestion. |
| Path Traversal in Scanner | Information Disclosure | Lock the mix task scanner to safe directories (e.g., `lib/`). |

## Sources

### Primary (HIGH confidence)
- Rulestead mix.exs / rulestead_admin mix.exs - Dependencies reviewed.
- `Rulestead.Oban` - Implementation confirmed.
- Elixir standard library `Code` / `Macro` verified via script execution.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir utilities are perfectly suited.
- Architecture: HIGH - ETS write-behind is standard for telemetry.
- Pitfalls: HIGH - CI Auth is a well-known hurdle for passive scanners.

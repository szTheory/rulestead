# Architecture Patterns: v1.0.0 (GA)

**Domain:** Feature Management Platform
**Researched:** 2026-05-17

## Recommended Architecture

For v1.0.0, the architectural focus shifts from adding capabilities to enforcing boundaries. 

### Component Boundaries (Public vs Private)

| Component | Responsibility | Boundary Enforcement |
|-----------|---------------|-------------------|
| `Rulestead` | Core Public API (Evaluation) | Fully documented, strictly spec'd, covered by SemVer 1.x guarantees. |
| `Rulestead.Admin` | Public API for Management | Same as above. Contains the pure Elixir context functions for managing flags. |
| `Rulestead.Internal.*` | Implementation details | Tagged with `@moduledoc false`. No SemVer guarantees. |

### Data Flow for RBAC

1. Web Request (Admin UI / API)
2. Plug / LiveView `on_mount` hook retrieves the current User/Role.
3. Web layer calls `Rulestead.Admin` context.
4. `Rulestead.Admin` immediately delegates to `Rulestead.Policy` to verify action.
5. If `{:ok, :authorized}`, execution proceeds to Ecto / Redis.
6. If `{:error, :unauthorized}`, operation halts and audit log is written (optional).

## Patterns to Follow

### Pattern 1: Pure Elixir Policy Modules
**What:** Decoupling authorization logic from Ecto queries or Web Plugs using pure functions.
**When:** Enforcing RBAC before executing mutations.
**Example:**
```elixir
defmodule Rulestead.Policy do
  @doc "Checks if the given actor can perform the action on the resource."
  def authorize(:create_flag, %User{role: "admin"}, _resource), do: :ok
  def authorize(:create_flag, %User{role: "editor"}, _resource), do: :ok
  def authorize(:create_flag, _, _), do: {:error, :unauthorized}
  
  def authorize(:delete_environment, %User{role: "admin"}, _resource), do: :ok
  def authorize(:delete_environment, _, _), do: {:error, :unauthorized}
end
```

### Pattern 2: Explicit Internal Namespaces
**What:** Moving all implementation details into `Rulestead.Internal` or strictly using `@moduledoc false`.
**Why:** Prevents users from relying on internal functions, which makes future refactoring impossible without breaking SemVer.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Heavy Authorization Dependencies
**What:** Bringing in `permit` or `ash` for RBAC.
**Why bad:** Rulestead is meant to be embedded. If the host application uses Ash 2.x and Rulestead uses Ash 3.x, you have created an unresolvable dependency conflict.
**Instead:** Write 50 lines of pure Elixir pattern matching.

### Anti-Pattern 2: Config-driven Roles
**What:** Trying to allow users to define complex custom roles in `config.exs`.
**Why bad:** Creates massive complexity in the UI and evaluation layer.
**Instead:** Hardcode 3-4 sensible default roles (Admin, Editor, Viewer).

## Sources

- Best practices for embeddable Elixir engines (e.g., Oban, Phoenix LiveDashboard).

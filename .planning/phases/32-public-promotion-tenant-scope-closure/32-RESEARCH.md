# Phase 32: Public Promotion Tenant Scope Closure - Research

**Researched:** 2026-05-22 [VERIFIED: .planning/ROADMAP.md]
**Domain:** Public promotion-plan generation, saved-plan serialization, and apply/governed replay for explicit tenant scope in `rulestead`. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]
**Confidence:** HIGH [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/test/rulestead/promotion/apply_test.exs] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]

## User Constraints

- Phase scope is limited to Phase 32 in `.planning/ROADMAP.md`; Phase 33 owns the compare drill-in `compare_token` gap and is explicitly out of scope here. [VERIFIED: .planning/ROADMAP.md]
- This phase must close only the public promotion-plan tenant-scope gap for `TEN-01` and `TEN-03`, specifically `saved-promotion-plan-tenant-scope` and `public-plan-promotion-with-tenant`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]
- Keep the change aligned with the linked-version two-package monorepo and do not widen `rulestead_admin` or publish-prep the guarded admin stub. [VERIFIED: AGENTS.md] [VERIFIED: CLAUDE.md] [VERIFIED: .planning/PROJECT.md]
- Make the smallest coherent change and avoid speculative future-phase work such as CLI tenant UX expansion or compare drill-in identity fixes. [VERIFIED: AGENTS.md] [VERIFIED: .planning/ROADMAP.md]
- Reuse the bounded tenant provenance, compare-token, and saved-plan patterns already established in Phases 29-31 instead of inventing a new tenant metadata dialect. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-RESEARCH.md] [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-RESEARCH.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEN-01 | Runtime and admin flows support explicit tenant scope without requiring environment-per-tenant or cloned flag topology. [VERIFIED: .planning/REQUIREMENTS.md] | `Rulestead.plan_promotion/3` must forward explicit `tenant_key` into `compare_environments/3` so the saved plan preserves the reviewed tenant scope already supported by compare/apply. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] |
| TEN-03 | Rulestead exposes a minimal tenancy seam with a safe single-tenant default, tenant-aware bucketing hooks, and tenant-aware audit metadata. [VERIFIED: .planning/REQUIREMENTS.md] | The saved promote plan must keep using the existing top-level `tenant_key` and downstream bounded provenance path, without adding new tenancy inputs or widening public surfaces. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] |
</phase_requirements>

## Summary

The root cause is narrow and confirmed. `Rulestead.plan_promotion/3` builds `compare_opts` from `:flag_keys` only, then calls `compare_environments/3` without forwarding `:tenant_key`, so the compare result and the saved promote plan both end up unscoped even though the lower layers already support scoped compare/apply flows. [VERIFIED: rulestead/lib/rulestead.ex:137] [VERIFIED: rulestead/lib/rulestead.ex:144] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]

The downstream path is already tenant-ready once the plan contains a real `tenant_key`. `Command.CompareEnvironments.new/3` accepts `tenant_key`, `Promotion.Compare.compare_projected/1` includes it in the compare result and `compare_token`, `Manifest.Plan.build_promote/1` persists it, `apply_promotion_plan/2` validates it, and both direct apply and governed replay rebuild commands from `plan["tenant_key"]`. [VERIFIED: rulestead/lib/rulestead/store/command.ex:366] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:185] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:135] [VERIFIED: rulestead/lib/rulestead.ex:181] [VERIFIED: rulestead/lib/rulestead.ex:1689] [VERIFIED: rulestead/lib/rulestead.ex:1774]

**Primary recommendation:** Fix `Rulestead.plan_promotion/3` to forward a whitelisted `tenant_key` alongside `flag_keys`, then add regression coverage at the public façade, saved-plan/apply path, and governed/compute-plan surfaces without changing any public function signatures or CLI switches. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex] [VERIFIED: rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs]

## Recommended Plan Split

1. **Plan slice 32-01: Public plan-generation seam fix plus façade regression coverage.** Update only `Rulestead.plan_promotion/3` and add tests that prove `tenant_key` survives `plan_promotion/3 -> compare -> details.plan`. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/test/rulestead/promotion/compare_test.exs]
2. **Plan slice 32-02: Saved-plan/apply and governed replay verification.** Extend apply, governed, mix-task, and adapter-contract tests so a tenant-scoped public plan remains scoped through `Plan.load/1`, `apply_promotion_plan/2`, and protected-target change-request payloads. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead.ex:1709] [VERIFIED: rulestead/test/rulestead/promotion/apply_test.exs] [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] [VERIFIED: rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs] [VERIFIED: rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public promotion-plan option shaping | API / Backend [VERIFIED: rulestead/lib/rulestead.ex] | — | `Rulestead.plan_promotion/3` is the only broken seam; no browser or storage changes are needed to preserve `tenant_key`. [VERIFIED: rulestead/lib/rulestead.ex:137] |
| Compare preview scope identity | API / Backend [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] | Database / Storage [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] | Compare already computes tenant-scoped results and tokens from normalized command input. [VERIFIED: rulestead/lib/rulestead/store/command.ex:366] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:29] |
| Saved-plan serialization and reload | API / Backend [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] | Database / Storage [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] | The plan artifact is the canonical handoff boundary for later apply/governance flows. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:25] [VERIFIED: rulestead/lib/rulestead.ex:181] |
| Apply and governed replay tenant enforcement | API / Backend [VERIFIED: rulestead/lib/rulestead.ex] | Database / Storage [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] | `apply_promotion_plan/2`, `promotion_apply_command/3`, and `promotion_governance_command_payload/1` already consume `plan["tenant_key"]` and fail closed on drift. [VERIFIED: rulestead/lib/rulestead.ex:181] [VERIFIED: rulestead/lib/rulestead.ex:1689] [VERIFIED: rulestead/lib/rulestead.ex:1812] |

## Project Constraints (from CLAUDE.md)

- Treat `.planning/` as the source of truth for roadmap and phase boundaries. [VERIFIED: CLAUDE.md]
- Preserve the sibling-package layout; do not collapse work into one package or push admin-only behavior into the wrong package. [VERIFIED: CLAUDE.md]
- Do not create Phase 8-only docs early. [VERIFIED: CLAUDE.md]
- Do not introduce early publish flows for `rulestead_admin`. [VERIFIED: CLAUDE.md]
- Prefer narrow, auditable changes. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: `elixir --version`] | Public façade, command construction, and ExUnit verification. [VERIFIED: rulestead/mix.exs] | Phase 32 is an internal behavior fix on the existing Elixir/Mix surface with no new dependency need. [VERIFIED: rulestead/mix.exs] |
| Ecto / Ecto SQL | 3.13.5 [VERIFIED: rulestead/mix.lock] | Real-store compare/apply contract and environment-version persistence. [VERIFIED: rulestead/lib/rulestead/store/ecto.ex] | Existing adapter-contract tests already prove tenant persistence in environment-version metadata and should be reused. [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] |
| Jason | 1.4.4 [VERIFIED: rulestead/mix.lock] | Saved-plan JSON serialization and reload. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] | `Manifest.Plan.load/1` and `serialize/1` already normalize the artifact boundary; no alternate serializer is needed. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:17] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: `mix --version`] | Narrow regression tests around façade, apply, governed, and mix-task flows. [VERIFIED: rulestead/test/test_helper.exs] | Use for all Phase 32 verification; no browser or admin package coverage is required. [VERIFIED: .planning/ROADMAP.md] |
| `Rulestead.Fake` | repo-local adapter [VERIFIED: rulestead/lib/rulestead/fake.ex] | Fast parity checks for saved-plan/apply behavior. [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] | Use alongside Ecto for adapter parity on tenant-scoped plan handoff. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Forwarding `tenant_key` only from `plan_promotion/3` [VERIFIED: rulestead/lib/rulestead.ex] | Adding new tenant fields to plan/governance payloads | Unnecessary surface growth; the plan/apply path already uses top-level `tenant_key` and bounded provenance. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] |
| Reusing existing mix-task `compute_plan/3` API [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex] | Adding a new `--tenant` CLI flag in Phase 32 | That expands public CLI UX beyond the documented roadmap goal; programmatic `opts` already exist for targeted verification. [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:52] [VERIFIED: .planning/ROADMAP.md] |

**Installation:**
```bash
cd rulestead && mix deps.get
```
[VERIFIED: rulestead/mix.exs]

**Version verification:** Phase 32 does not require a new dependency; use the locked repo stack above. [VERIFIED: rulestead/mix.lock] [VERIFIED: rulestead/mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Rulestead.plan_promotion(source, target, tenant_key?: ...)
  -> build whitelisted compare opts
    -> Rulestead.compare_environments/3
      -> Command.CompareEnvironments.new(..., tenant_key)
        -> Promotion.Compare.compare_projected/1
          -> compare result {tenant_key, compare_token, fingerprints}
            -> Manifest.Plan.build_promote/1
              -> saved plan JSON {tenant_key, compare_token, plan_token}
                -> Rulestead.apply_promotion_plan/2
                  -> validate_target_tenant(plan, opts)
                    -> promotion_apply_command/3 or governed payload
                      -> Apply.validate/1 -> store adapter
```
[VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]

### Recommended Project Structure
```text
rulestead/lib/
├── rulestead.ex                    # public plan/apply façade
├── rulestead/manifest/plan.ex      # saved-plan normalization and tokenization
├── rulestead/promotion/compare.ex  # compare result + compare_token
├── rulestead/promotion/apply.ex    # compare revalidation before mutation
├── rulestead/store/command.ex      # compare/apply command structs with tenant_key
└── mix/tasks/rulestead.promote.ex  # programmatic CLI entrypoint

rulestead/test/rulestead/
├── promotion/compare_test.exs
├── promotion/apply_test.exs
├── store/promotion_apply_contract_test.exs
├── store/promotion_governed_apply_contract_test.exs
└── mix/tasks/rulestead_promote_test.exs
```
[VERIFIED: codebase grep]

### Pattern 1: Whitelist only existing tenant-aware compare inputs at the public façade
**What:** Keep `plan_promotion/3` as a thin façade that forwards only `flag_keys` and `tenant_key` into `compare_environments/3`. [VERIFIED: rulestead/lib/rulestead.ex]  
**When to use:** Phase 32 code fix in `Rulestead.plan_promotion/3`. [VERIFIED: rulestead/lib/rulestead.ex:137]  
**Why:** `Command.CompareEnvironments.new/3` already normalizes `tenant_key`, so the façade should reuse that seam instead of rebuilding tenant logic. [VERIFIED: rulestead/lib/rulestead/store/command.ex:381]
**Example:**
```elixir
# Source pattern: rulestead/lib/rulestead.ex
compare_opts =
  opts
  |> Keyword.take([:flag_keys, :tenant_key])
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
```

### Pattern 2: Keep top-level `tenant_key` as the canonical saved-plan scope field
**What:** Preserve the existing `tenant_key` plan field rather than introducing nested promotion-only tenant metadata. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex]  
**When to use:** Any saved promote plan generated by `Plan.build_promote/1` and reloaded by `Plan.load/1`. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:135]  
**Why:** Apply and governed replay already read from that field directly. [VERIFIED: rulestead/lib/rulestead.ex:1694] [VERIFIED: rulestead/lib/rulestead.ex:1778]
**Example:**
```elixir
# Source: rulestead/lib/rulestead/manifest/plan.ex
%{
  "mode" => "promote",
  "tenant_key" => tenant_key,
  "compare_token" => compare_token,
  "plan_token" => plan_token(plan_seed)
}
```

### Pattern 3: Rebuild apply/governed commands only from the loaded plan artifact
**What:** Let `apply_promotion_plan/2` reconstruct direct and governed commands from the saved plan, then validate live tenant drift separately. [VERIFIED: rulestead/lib/rulestead.ex]  
**When to use:** Non-protected and protected target apply handoff. [VERIFIED: rulestead/lib/rulestead.ex:1709]  
**Why:** This keeps the reviewed artifact authoritative and avoids caller-authored tenant overrides. [VERIFIED: rulestead/lib/rulestead.ex:1812]
**Example:**
```elixir
# Source: rulestead/lib/rulestead.ex
tenant_key: plan["tenant_key"],
compare_token: plan["compare_token"],
dependency_closure_keys: plan["dependency_closure_keys"]
```

### Anti-Patterns to Avoid

- **Do not fix this in `Promotion.Compare` or `Manifest.Plan` first.** Those layers already preserve `tenant_key` when it is present; changing them would mask the real public-façade defect. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:89] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:157]
- **Do not add a Phase 32-only CLI surface.** `Mix.Tasks.Rulestead.Promote.compute_plan/3` already accepts `opts`, while `run/1` intentionally exposes only `--source`, `--target`, `--plan`, `--apply`, and `--reason`. [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:9] [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:52]
- **Do not widen tenancy semantics beyond explicit `tenant_key`.** The roadmap goal is preserving reviewed explicit scope, not adding implicit resolution or cross-tenant behavior. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]

## Root Cause Trace

1. `Rulestead.plan_promotion/3` drops `tenant_key` before compare because `compare_opts` is built from `:flag_keys` only. [VERIFIED: rulestead/lib/rulestead.ex:138]
2. `Rulestead.compare_environments/3` already supports `tenant_key` through `Command.CompareEnvironments.new/3`. [VERIFIED: rulestead/lib/rulestead.ex:74] [VERIFIED: rulestead/lib/rulestead/store/command.ex:386]
3. `Promotion.Compare.compare_projected/1` already carries `tenant_key` into both the compare payload and `compare_token`. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:185] [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:217]
4. `Manifest.Plan.build_promote/1` already serializes `tenant_key` into the saved promote plan when present. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:157] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:202]
5. `Rulestead.apply_promotion_plan/2` already validates live tenant drift and reconstructs both direct and governed apply commands from `plan["tenant_key"]`. [VERIFIED: rulestead/lib/rulestead.ex:185] [VERIFIED: rulestead/lib/rulestead.ex:1694] [VERIFIED: rulestead/lib/rulestead.ex:1778] [VERIFIED: rulestead/lib/rulestead.ex:1812]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public promotion tenant forwarding [VERIFIED: rulestead/lib/rulestead.ex] | A second tenant normalization layer | `Command.CompareEnvironments.new/3` and existing compare/apply command structs [VERIFIED: rulestead/lib/rulestead/store/command.ex] | The command layer already normalizes `tenant_key` correctly. [VERIFIED: rulestead/test/rulestead/promotion/compare_test.exs] |
| Saved-plan tenant schema [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] | A nested promotion-only tenant block | Existing top-level `tenant_key` plus bounded command provenance [VERIFIED: rulestead/lib/rulestead/store/command.ex] | That keeps compatibility with `Plan.load/1`, apply reconstruction, and environment-version metadata. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] [VERIFIED: rulestead/test/rulestead/store/promotion_apply_contract_test.exs] |
| Tenant drift enforcement [VERIFIED: rulestead/lib/rulestead.ex:1812] | A new apply-time tenant checker outside the current path | Existing `validate_target_tenant/2` and `Apply.validate/1` [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex] | The fail-closed logic already exists; the plan just needs to carry the reviewed scope. [VERIFIED: rulestead/test/rulestead/promotion/apply_test.exs] |

**Key insight:** This phase is a missing-input bug, not a missing-validation bug. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Fixing only plan serialization
**What goes wrong:** Adding assertions or metadata inside `Manifest.Plan` without fixing `plan_promotion/3` still leaves `tenant_key=nil` at the source. [VERIFIED: rulestead/lib/rulestead.ex:144] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:157]  
**How to avoid:** Treat the façade option shaping in `Rulestead.plan_promotion/3` as the primary code change, then verify the artifact downstream. [VERIFIED: rulestead/lib/rulestead.ex]

### Pitfall 2: Expanding the CLI instead of the API seam
**What goes wrong:** Adding a `--tenant` flag obscures the actual defect and widens the public CLI contract unnecessarily. [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:9]  
**How to avoid:** Verify tenant-scoped planning through `Rulestead.plan_promotion/3` and `Mix.Tasks.Rulestead.Promote.compute_plan/3` programmatic opts in tests. [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:52]

### Pitfall 3: Forgetting governed apply parity
**What goes wrong:** Direct apply passes, but protected-target change requests still serialize an unscoped command if tests only cover non-governed paths. [VERIFIED: rulestead/lib/rulestead.ex:1721] [VERIFIED: rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs]  
**How to avoid:** Assert `change_request.command["tenant_key"]` survives from the saved plan alongside `compare_token`. [VERIFIED: rulestead/lib/rulestead.ex:1774]

## Code Examples

Verified patterns from the current codebase:

### Public promotion-plan seam fix
```elixir
# Source pattern: rulestead/lib/rulestead.ex
compare_opts =
  opts
  |> Keyword.take([:flag_keys, :tenant_key])
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)

with {:ok, compare} <-
       compare_environments(
         source_environment_key,
          target_environment_key,
         compare_opts
       ) do
  Plan.build_promote(%{
    source_environment_key: compare.source_environment.key,
    target_environment_key: compare.target_environment.key,
    tenant_key: compare.tenant_key,
    compare_token: compare.compare_token
  })
end
```

### Regression shape to lock the saved plan
```elixir
# Source pattern: rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs
assert {:ok, result} =
         Rulestead.plan_promotion("staging", "test", tenant_key: "acme")

plan = result["details"]["plan"]
assert plan["tenant_key"] == "acme"
assert String.starts_with?(plan["compare_token"], "cmp_")
```

### Governed replay contract to keep tenant scope
```elixir
# Source pattern: rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs
assert change_request.command["tenant_key"] == plan["tenant_key"]
assert change_request.command["compare_token"] == plan["compare_token"]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Compare/apply tenant preservation existed below the façade, but `plan_promotion/3` did not forward `tenant_key`. [VERIFIED: rulestead/lib/rulestead.ex] | Public promotion planning should reuse the same scoped compare/apply path already locked in Phases 29-31. [VERIFIED: .planning/phases/29-tenancy-helpers-validation/29-RESEARCH.md] [VERIFIED: .planning/phases/31-audit-tenant-provenance-enforcement/31-RESEARCH.md] | Gap identified in the milestone audit on 2026-05-22. [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md] | Phase 32 can remain a one-seam fix plus regressions instead of a broader tenancy redesign. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**
- Relying on unscoped public `plan_promotion/3` output as proof of full tenancy closure is outdated after the 2026-05-22 milestone audit. [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Human CLI tenant input is intentionally deferred from Phase 32 because the roadmap and root-cause audit scope only the public promotion API gap, while programmatic `compute_plan/3` opts already cover verification needs. [RESOLVED] | Open Questions | Low; a future phase can add human CLI tenant UX without changing the Phase 32 saved-plan contract. |
| A2 | This research remains valid until 2026-06-21 unless Phases 32-34 alter the promotion-plan path first. [ASSUMED] | Metadata | Planner may over-trust stale research after adjacent phase work changes the seam. |

## Open Questions (RESOLVED)

1. **Should Phase 32 add a CLI `--tenant` flag?** [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex]
   - What we know: the roadmap goal names the public promotion API gap, not CLI UX, and `compute_plan/3` already accepts `opts` for tests. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:52]
   - Resolution: human CLI tenant input is intentionally deferred. Phase 32 remains API-focused because the confirmed defect is `plan_promotion/3` dropping `tenant_key`, not the absence of a new CLI switch. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]
   - Decision: do not add the flag in Phase 32; verify tenant-scoped planning through `Rulestead.plan_promotion/3` and `Mix.Tasks.Rulestead.Promote.compute_plan/3` programmatic opts only. [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:52]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, façade verification | ✓ [VERIFIED: `elixir --version`] | 1.19.5 [VERIFIED: `elixir --version`] | — |
| Mix | Targeted verification commands | ✓ [VERIFIED: `mix --version`] | 1.19.5 [VERIFIED: `mix --version`] | — |
| PostgreSQL | Ecto adapter contract tests | ✓ [VERIFIED: `pg_isready`] | 14.17 client [VERIFIED: `psql --version`] | Fake adapter for non-Ecto coverage [VERIFIED: rulestead/lib/rulestead/fake.ex] |

**Missing dependencies with no fallback:**
- None for the recommended Phase 32 verification set. [VERIFIED: `pg_isready`] [VERIFIED: rulestead/lib/rulestead/fake.ex]

**Missing dependencies with fallback:**
- None. [VERIFIED: `pg_isready`]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto sandbox and `Rulestead.Fake` parity. [VERIFIED: rulestead/test/test_helper.exs] |
| Config file | `rulestead/test/test_helper.exs`. [VERIFIED: rulestead/test/test_helper.exs] |
| Quick run command | `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs`. [VERIFIED: executed command] |
| Full suite command | `cd rulestead && mix test`. [VERIFIED: rulestead/test/test_helper.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEN-01 | `plan_promotion/3` preserves explicit `tenant_key` into the saved plan and later apply handoff. [VERIFIED: .planning/ROADMAP.md] | unit + integration | `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs`. [VERIFIED: executed command] | ✅ [VERIFIED: codebase grep] |
| TEN-03 | Saved promote plans keep bounded explicit tenant scope through direct and governed replay. [VERIFIED: .planning/REQUIREMENTS.md] | adapter contract | `cd rulestead && mix test test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs`. [VERIFIED: executed command] | ✅ [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `cd rulestead && mix test test/rulestead/promotion/compare_test.exs test/rulestead/promotion/apply_test.exs test/rulestead/mix/tasks/rulestead_promote_test.exs` [VERIFIED: executed command]
- **Per wave merge:** `cd rulestead && mix test test/rulestead/store/promotion_apply_contract_test.exs test/rulestead/store/promotion_governed_apply_contract_test.exs` [VERIFIED: executed command]
- **Phase gate:** `cd rulestead && mix test` [VERIFIED: rulestead/test/test_helper.exs]

### Wave 0 Gaps

- None in framework setup; ExUnit, Repo startup, Fake adapter boot, and sandboxing already exist. [VERIFIED: rulestead/test/test_helper.exs]
- Coverage gap to add in this phase: explicit `tenant_key` assertions for public `plan_promotion/3`, mix-task `compute_plan/3`, and governed change-request command payloads. [VERIFIED: rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs] [VERIFIED: rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: .planning/ROADMAP.md] | Host-owned auth remains unchanged in this phase. [VERIFIED: CLAUDE.md] |
| V3 Session Management | no [VERIFIED: .planning/ROADMAP.md] | No session surface changes are in scope. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes [VERIFIED: .planning/REQUIREMENTS.md] | Fail-closed tenant drift enforcement through `validate_target_tenant/2` and governed replay from saved plans. [VERIFIED: rulestead/lib/rulestead.ex:1812] |
| V5 Input Validation | yes [VERIFIED: rulestead/lib/rulestead/store/command.ex] | Reuse normalized command constructors and `Plan.load/1` validation. [VERIFIED: rulestead/lib/rulestead/store/command.ex] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex] |
| V6 Cryptography | yes [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex] | Existing compare/plan token hashing via `:crypto.hash` remains the integrity primitive. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex:313] [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex:255] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Saved plan silently widens from scoped compare to unscoped apply. [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md] | Tampering | Forward explicit `tenant_key` at plan generation and keep `validate_target_tenant/2` fail-closed on apply. [VERIFIED: rulestead/lib/rulestead.ex:137] [VERIFIED: rulestead/lib/rulestead.ex:1812] |
| Governed apply loses reviewed tenant scope in replay payload. [VERIFIED: rulestead/lib/rulestead.ex:1721] | Repudiation | Assert `promotion_governance_command_payload/1` preserves `tenant_key` from the plan. [VERIFIED: rulestead/lib/rulestead.ex:1774] |
| Public fix accidentally broadens tenancy inputs beyond explicit scope. [VERIFIED: .planning/REQUIREMENTS.md] | Elevation of Privilege | Whitelist only `tenant_key` and `flag_keys` in the façade; do not add implicit resolution or new public flags. [VERIFIED: rulestead/lib/rulestead.ex:138] [VERIFIED: rulestead/lib/mix/tasks/rulestead.promote.ex:9] |

## Sources

### Primary (HIGH confidence)
- `rulestead/lib/rulestead.ex` - verified the defect in `plan_promotion/3` and the existing apply/governed handoff path. [VERIFIED: rulestead/lib/rulestead.ex]
- `rulestead/lib/rulestead/manifest/plan.ex` - verified saved-plan normalization and promote-plan `tenant_key` serialization. [VERIFIED: rulestead/lib/rulestead/manifest/plan.ex]
- `rulestead/lib/rulestead/promotion/compare.ex` - verified tenant-scoped compare payloads and compare-token generation. [VERIFIED: rulestead/lib/rulestead/promotion/compare.ex]
- `rulestead/lib/rulestead/promotion/apply.ex` - verified compare revalidation already forwards `tenant_key`. [VERIFIED: rulestead/lib/rulestead/promotion/apply.ex]
- `.planning/ROADMAP.md` and `.planning/v1.1.0-MILESTONE-AUDIT.md` - verified Phase 32 scope and the exact integration gap. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md]
- Executed `mix test` commands - verified the current baseline suites pass and identified coverage gaps rather than live regressions. [VERIFIED: executed command]

### Secondary (MEDIUM confidence)
- `prompts/rulestead-testing-and-e2e-strategy.md` - verified the repo’s preference for Fake-plus-contract testing over broader E2E expansion. [VERIFIED: prompts/rulestead-testing-and-e2e-strategy.md]
- `prompts/rulestead-host-app-integration-seam.md` - verified the explicit-over-magic host boundary, supporting the recommendation not to add new CLI UX in this phase. [VERIFIED: prompts/rulestead-host-app-integration-seam.md]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended tools and dependencies were verified from `mix.exs`, `mix.lock`, and local versions. [VERIFIED: rulestead/mix.exs] [VERIFIED: rulestead/mix.lock] [VERIFIED: `elixir --version`]
- Architecture: HIGH - the broken seam and intact downstream path were confirmed directly in code and tests. [VERIFIED: rulestead/lib/rulestead.ex] [VERIFIED: rulestead/test/rulestead/promotion/apply_test.exs]
- Pitfalls: HIGH - each pitfall is derived from the actual current gap boundary and existing roadmap exclusions. [VERIFIED: .planning/v1.1.0-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md]

**Research date:** 2026-05-22 [VERIFIED: .planning/ROADMAP.md]
**Valid until:** 2026-06-21 for this repo state unless Phase 32-34 change the promotion-plan path first. [ASSUMED]

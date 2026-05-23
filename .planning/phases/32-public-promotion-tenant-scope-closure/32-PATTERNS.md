# Phase 32: Public Promotion Tenant Scope Closure - Pattern Map

**Mapped:** 2026-05-22
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| Planned/Reference File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead.ex` | service | request-response | same file promotion facade helpers | exact |
| `rulestead/lib/rulestead/manifest/plan.ex` | utility | transform | same file import/promote builders | exact |
| `rulestead/lib/rulestead/promotion/compare.ex` | service | transform | same file compare token/result builder | exact |
| `rulestead/lib/rulestead/promotion/apply.ex` | service | request-response | same file compare revalidation contract | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | same file compare/apply adapter callbacks | exact |
| `rulestead/lib/rulestead/fake.ex` | service | CRUD | same file compare/apply fake parity | exact |
| `rulestead/lib/mix/tasks/rulestead.promote.ex` | service | request-response | same file programmatic promote task wrapper | exact |
| `rulestead/test/rulestead/promotion/compare_test.exs` | test | request-response | same file public compare facade tests | exact |
| `rulestead/test/rulestead/promotion/apply_test.exs` | test | request-response | same file saved-plan/apply replay tests | exact |
| `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` | test | CRUD | same file fake/ecto parity contract | exact |
| `rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs` | test | CRUD | same file governed replay contract tests | exact |
| `rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs` | test | request-response | same file promote task wrapper regressions | exact |
| `rulestead/test/rulestead/release_contract_test.exs` | test | request-response | same file public API catalog lock | exact |

## Pattern Assignments

### `rulestead/lib/rulestead.ex` (public facade, request-response)

**Analog:** same file, public promotion helpers.

**Bounded opt forwarding pattern** from [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:137):
```elixir
compare_opts =
  case Keyword.get(opts, :flag_keys) do
    nil -> []
    flag_keys -> [flag_keys: flag_keys]
  end

with {:ok, compare} <-
       compare_environments(source_environment_key, target_environment_key, compare_opts) do
```

Planner guidance:
- `plan_promotion/3` currently forwards only `:flag_keys`.
- Phase 32 work should extend this same bounded forwarding style for `:tenant_key`, not pass raw `opts`.
- Keep the public surface narrow: construct a small keyword list, then call `compare_environments/3`.

**Saved-plan build pattern** from [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:146):
```elixir
plan =
  Plan.build_promote(%{
    source_environment_key: compare.source_environment.key,
    target_environment_key: compare.target_environment.key,
    status: promotion_plan_status(compare),
    compare_token: compare.compare_token,
    source_fingerprint: compare.source_fingerprint,
    target_fingerprint: compare.target_fingerprint,
    dependency_closure_keys: compare.dependency_closure_keys,
    proposed_target_bundle:
      Map.new(compare.flags, fn flag ->
        {flag.flag_key, flag.proposed_target_state}
      end)
  })
```

Planner guidance:
- Promotion plans are built from compare payload fields, not from caller opts directly.
- Tenant scope should enter through compare result fields, then be copied into `Plan.build_promote/1`.

**Replay command pattern** from [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:1689):
```elixir
Command.ApplyPromotion.new(
  %{
    source_environment_key: plan["source_environment_key"],
    target_environment_key: plan["target_environment_key"],
    tenant_key: plan["tenant_key"],
    flag_keys: plan["flag_keys"],
    compare_token: plan["compare_token"],
    compare_schema_version: Compare.schema_version(),
    source_fingerprint: plan["source_fingerprint"],
    target_fingerprint: plan["target_fingerprint"],
    dependency_closure_keys: plan["dependency_closure_keys"],
    proposed_target_bundle: plan["proposed_target_bundle"]
  },
```

Planner guidance:
- Saved plan apply reconstructs a fresh command from normalized plan content.
- Tenant scope is replayed from the plan, not taken from arbitrary live opts except for drift validation.

**Fail-closed tenant drift pattern** from [rulestead/lib/rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:1812):
```elixir
live_tenant = Rulestead.Manifest.normalize_string(Keyword.get(opts, :tenant_key))
plan_tenant = plan["tenant_key"]

if live_tenant == plan_tenant do
  :ok
else
  {:error, StoreError.invalid_command("promotion target tenant drifted")}
end
```

Planner guidance:
- Preserve this exact fail-closed shape for tenant comparison: normalize live opt, compare against normalized plan field, return invalid command on mismatch.

### `rulestead/lib/mix/tasks/rulestead.promote.ex` (programmatic wrapper, request-response)

**Analog:** same file, thin wrapper over public `Rulestead` helpers.

**Programmatic wrapper pattern** from [rulestead/lib/mix/tasks/rulestead.promote.ex](/Users/jon/projects/rulestead/rulestead/lib/mix/tasks/rulestead.promote.ex:52):
```elixir
def compute_plan(source_environment_key, target_environment_key, opts \\ []) do
  Rulestead.plan_promotion(source_environment_key, target_environment_key, opts)
end

def compute_apply(content, opts \\ []) do
  Rulestead.apply_promotion_plan(content, opts)
end
```

Planner guidance:
- Keep the Mix task a thin programmatic wrapper over the fixed public API.
- Phase 32 should verify tenant-scoped `opts` reach `compute_plan/3` and `compute_apply/2` without adding a new human CLI flag.

### `rulestead/lib/rulestead/manifest/plan.ex` (plan serialization, transform)

**Analog:** same file, import/promote builders and `load/1`.

**Load-normalize-validate pattern** from [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:25):
```elixir
with :ok <- validate_kind(plan),
     :ok <- validate_schema_version(plan),
     {:ok, mode} <- fetch_required_string(plan, "mode"),
     :ok <- validate_mode(mode),
     {:ok, target_environment_key} <- fetch_required_string(plan, "target_environment_key"),
     {:ok, plan_token} <- fetch_required_string(plan, "plan_token"),
     {:ok, target_fingerprint} <- fetch_required_string(plan, "target_fingerprint"),
     {:ok, dependency_closure_keys} <- load_string_list(plan, "dependency_closure_keys"),
     {:ok, proposed_target_bundle} <- load_bundle(plan),
     {:ok, status} <- load_status(plan) do
```

Planner guidance:
- New plan fields must participate in `load/1` normalization if they are persisted contract fields.
- Optional fields use `maybe_put/3` after validation, not ad hoc merging.

**Optional tenant field preservation** from [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:48):
```elixir
|> maybe_put("tenant_key", fetch_optional_string(plan, "tenant_key"))
|> maybe_put("source_environment_key", fetch_optional_string(plan, "source_environment_key"))
|> maybe_put("compare_token", fetch_optional_string(plan, "compare_token"))
```

Planner guidance:
- `tenant_key` is already treated as a bounded optional string field.
- Phase 32 should preserve that exact normalization path rather than inventing separate tenant parsing logic.

**Promote-plan token seed pattern** from [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:182):
```elixir
plan_seed =
  %{
    "mode" => "promote",
    "source_environment_key" => source_environment_key,
    "target_environment_key" => target_environment_key,
    "compare_token" => compare_token,
    "source_fingerprint" => source_fingerprint,
    "target_fingerprint" => target_fingerprint,
    "dependency_closure_keys" => dependency_closure_keys,
    "proposed_target_bundle" => bundle
  }
  |> maybe_put("tenant_key", tenant_key)
```

Planner guidance:
- Tenant scope must be part of the plan token seed when present.
- That means any Phase 32 propagation bug is likely at the caller boundary, not inside token generation.

**Deterministic serialization pattern** from [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:320):
```elixir
map
|> Enum.map(fn {key, value} -> {to_string(key), encode_json(value)} end)
|> Enum.sort_by(&elem(&1, 0))
|> Enum.map_join(",", fn {key, value} -> Jason.encode!(key) <> ":" <> value end)
|> then(&"{" <> &1 <> "}")
```

Planner guidance:
- Keep serialization deterministic by sorting keys.
- Any new persisted field must flow through normalized maps so token/fingerprint stability remains intact.

### `rulestead/lib/rulestead/promotion/compare.ex` (compare contract, transform)

**Analog:** same file, compare token/result constructors.

**Tenant-aware compare token pattern** from [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:31):
```elixir
token_payload = %{
  schema_version: @schema_version,
  source_environment_key:
    normalize_string(attrs[:source_environment_key] || attrs["source_environment_key"]),
  target_environment_key:
    normalize_string(attrs[:target_environment_key] || attrs["target_environment_key"]),
  tenant_key:
    normalize_string(attrs[:tenant_key] || attrs["tenant_key"]),
  compared_flag_keys:
    normalize_string_list(attrs[:compared_flag_keys] || attrs["compared_flag_keys"]),
```

Planner guidance:
- Compare identity already includes `tenant_key`.
- Public facade changes should preserve this contract by ensuring compare receives tenant scope before plan generation.

**Result payload pattern** from [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:77):
```elixir
%{
  source_environment: ...,
  target_environment: ...,
  compare_token: attrs[:compare_token] || attrs["compare_token"],
  compare_schema_version: @schema_version,
  overall_status: overall_status(all_findings, flags),
  tenant_key: attrs[:tenant_key] || attrs["tenant_key"],
  requested_flag_keys:
    normalize_string_list(attrs[:requested_flag_keys] || attrs["requested_flag_keys"]),
```

Planner guidance:
- Tenant scope belongs in the top-level compare payload.
- `plan_promotion/3` should copy from `compare.tenant_key`, matching other fields copied from compare.

**Projected compare builder pattern** from [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:185):
```elixir
compare_token =
  compare_token(%{
    source_environment_key:
      get_environment_key(attrs[:source_environment] || attrs["source_environment"]),
    target_environment_key:
      get_environment_key(attrs[:target_environment] || attrs["target_environment"]),
    tenant_key: attrs[:tenant_key] || attrs["tenant_key"],
    compared_flag_keys: scope_keys,
    dependency_closure_keys: dependency_closure_keys,
```

Planner guidance:
- The compare contract derives its token from projected live state plus tenant scope.
- Do not bypass this by injecting tenant into plan token only.

### `rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs` (governed replay contract, CRUD)

**Analog:** same file, governed promotion replay assertions.

**Governed command payload pattern** from [rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_governed_apply_contract_test.exs:1):
- Protected-target promote plans should queue change requests whose persisted command payload keeps the reviewed `tenant_key` and `compare_token`.
- The test file is the closest analog for proving Phase 32 does not fix only the non-governed replay path.

Planner guidance:
- Use this file for protected-target parity, not for new governance semantics.
- Assert that the saved plan remains authoritative when converted into a governed change request.

### `rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs` (programmatic wrapper regression, request-response)

**Analog:** same file, promote task wrapper regression tests.

**Wrapper regression pattern** from [rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/mix/tasks/rulestead_promote_test.exs:1):
- Exercise `compute_plan/3` and `compute_apply/2` directly with bounded opts.
- Verify the result envelope and saved plan content rather than introducing new CLI parsing work.

Planner guidance:
- Lock the task wrapper to the same tenant-scoped public contract as `Rulestead.plan_promotion/3`.
- Keep this test programmatic; Phase 32 is not the place to broaden human CLI UX.

### `rulestead/lib/rulestead/promotion/apply.ex` (apply contract, request-response)

**Analog:** same file, compare revalidation before mutation.

**Compare revalidation pattern** from [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:67):
```elixir
Compare.compare(
  Command.CompareEnvironments.new(
    command.source_environment_key,
    command.target_environment_key,
    flag_keys: command.flag_keys,
    compare_token: command.compare_token,
    tenant_key: command.tenant_key
  )
)
```

Planner guidance:
- Replay validation always reissues compare with the command’s bounded fields.
- Tenant scope must stay on the command so live revalidation and saved-plan apply hit the same compare identity.

**Fail-closed validation order** from [rulestead/lib/rulestead/promotion/apply.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/apply.ex:82):
```elixir
cond do
  stale_preview?(command, compare) ->
    {:error, StoreError.invalid_command("promotion compare preview is stale")}

  dependency_drift?(command, compare) ->
    {:error, StoreError.invalid_command("promotion compare dependency closure drifted")}

  Compare.protected_target?(command.target_environment_key) and not allow_protected_target? ->
    {:error, StoreError.invalid_command("promotion to protected targets requires governance")}
```

Planner guidance:
- Keep tenant-scope enforcement aligned with this fail-closed ordering.
- Return store invalid-command errors, then let facade code map them into stale/blocked manifest results.

### `rulestead/lib/rulestead/store/ecto.ex` (real adapter, CRUD)

**Analog:** same file, compare/apply callbacks and immutable environment version persistence.

**Compare callback pattern** from [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:55):
```elixir
{:ok,
 Compare.compare_projected(%{
   source_environment: environment_summary(source_environment),
   target_environment: environment_summary(target_environment),
   requested_flag_keys: command.flag_keys,
   compare_token: command.compare_token,
   tenant_key: command.tenant_key,
   source_flags: compare_payloads(flags, source_environment),
   target_flags: compare_payloads(flags, target_environment),
   audiences: audiences
 })}
```

Planner guidance:
- Ecto compare does not compute tenant scope itself; it passes command scope into `Compare.compare_projected/1`.
- Public facade changes should preserve this adapter contract unchanged.

**Immutable apply envelope pattern** from [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:133):
```elixir
{:ok,
 %{
   source_environment_key: command.source_environment_key,
   target_environment_key: command.target_environment_key,
   compare_token: command.compare_token,
   compare_schema_version: command.compare_schema_version,
   applied_flag_keys: command.flag_keys,
   dependency_closure_keys: command.dependency_closure_keys,
   environment_version_id: environment_version.id,
   environment_version_version: environment_version.version,
   snapshot_version: runtime_snapshot.version
 }}
```

Planner guidance:
- Apply result echoes compare identity and immutable version IDs, but not tenant_key directly.
- Tenant evidence is persisted in `environment_versions`, not the top-level apply result.

**Environment version persistence pattern** from [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1880):
```elixir
%EnvironmentVersion{}
|> EnvironmentVersion.changeset(%{
  environment_key: target_environment.key,
  version: next_environment_version(repo, target_environment.key),
  authored_snapshot: command.proposed_target_bundle,
  source_environment_key: command.source_environment_key,
  target_environment_key: command.target_environment_key,
  compare_token: command.compare_token,
  source_fingerprint: command.source_fingerprint,
  target_fingerprint: command.target_fingerprint,
  dependency_closure_keys: command.dependency_closure_keys,
  applied_flag_keys: command.flag_keys,
  tenant_key: command.tenant_key,
```

**Metadata provenance pattern** from [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1894):
```elixir
metadata: %{
  "actor" => command.actor || %{},
  "reason" => command.reason,
  "metadata" => command.metadata,
  "tenant" => Command.GovernanceSupport.tenant_provenance(command)
}
```

Planner guidance:
- Preserve both `tenant_key` and derived tenant provenance metadata when command scope is replayed.
- Phase 32 should not widen persistence shape beyond this existing environment version contract.

### `rulestead/lib/rulestead/fake.ex` (fake adapter parity, CRUD)

**Analog:** same file, compare/apply parity with Ecto.

**Compare command parity pattern** from [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:2664):
```elixir
Command.CompareEnvironments.new(
  command.source_environment_key,
  command.target_environment_key,
  flag_keys: command.flag_keys,
  compare_token: command.compare_token,
  tenant_key: command.tenant_key
)
```

**Compare projection parity** from [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:2685):
```elixir
{:ok,
 Compare.compare_projected(%{
   source_environment: source_environment,
   target_environment: target_environment,
   requested_flag_keys: command.flag_keys,
   compare_token: command.compare_token,
   tenant_key: command.tenant_key,
   source_flags: source_flags,
   target_flags: target_flags,
   audiences: audiences
 })}
```

**Environment version parity** from [rulestead/lib/rulestead/fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:3199):
```elixir
normalize_environment_version(%EnvironmentVersion{
  id: Ecto.UUID.generate(),
  environment_key: target_environment.key,
  version: version,
  authored_snapshot: command.proposed_target_bundle,
  source_environment_key: command.source_environment_key,
  target_environment_key: command.target_environment_key,
  compare_token: command.compare_token,
  source_fingerprint: command.source_fingerprint,
  target_fingerprint: command.target_fingerprint,
  dependency_closure_keys: command.dependency_closure_keys,
  applied_flag_keys: command.flag_keys,
  tenant_key: command.tenant_key,
  metadata: %{
    "actor" => command.actor || %{},
    "reason" => command.reason,
    "metadata" => command.metadata,
    "tenant" => Command.GovernanceSupport.tenant_provenance(command)
  },
```

Planner guidance:
- Fake mirrors Ecto field-for-field for promotion apply persistence.
- Any Phase 32 change affecting saved plan tenant scope must be proven in both adapters.

## Regression Test Patterns

### Public facade compare tests

**Source:** [rulestead/test/rulestead/promotion/compare_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/promotion/compare_test.exs:64)

Use the existing stub-and-restore pattern:
```elixir
setup do
  previous_store = Application.get_env(:rulestead, :store)
  Application.put_env(:rulestead, :store, CompareStoreStub)

  on_exit(fn ->
    case previous_store do
      nil -> Application.delete_env(:rulestead, :store)
      value -> Application.put_env(:rulestead, :store, value)
    end
  end)

  :ok
end
```

Use public facade assertions shaped like [rulestead/test/rulestead/promotion/compare_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/promotion/compare_test.exs:93):
```elixir
assert {:ok, payload} =
         Rulestead.compare_environments("staging", "production",
           flag_keys: [:checkout_redesign, "beta-banner"],
           tenant_key: "acme",
           compare_token: "preview-token"
         )

assert payload.tenant_key == "acme"
```

Planner guidance:
- For Phase 32, copy this structure for `Rulestead.plan_promotion/3`.
- Assert public API forwarding, not internal helper calls.

### Saved plan / apply replay tests

**Source:** [rulestead/test/rulestead/promotion/apply_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/promotion/apply_test.exs:194)

Use literal saved-plan maps with normalized persisted keys:
```elixir
plan = %{
  "schema_version" => Rulestead.Manifest.Plan.schema_version(),
  "kind" => "rulestead_apply_plan",
  "mode" => "promote",
  "target_environment_key" => "qa",
  "source_environment_key" => "staging",
  "plan_token" => "plan_123",
  "compare_token" => "cmp_ok",
  "tenant_key" => "acme",
  ...
}
```

Use tenant drift assertion from [rulestead/test/rulestead/promotion/apply_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/promotion/apply_test.exs:213):
```elixir
assert {:ok, result} =
         Rulestead.apply_promotion_plan(plan, reason: "drifting tenant", tenant_key: "other")

assert result["status"] == "stale"
assert Enum.any?(result["findings"], &(&1["message"] =~ "tenant drifted"))
```

Use replay-command assertion from [rulestead/test/rulestead/promotion/apply_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/promotion/apply_test.exs:252):
```elixir
assert_receive {:apply_promotion_called, %Command.ApplyPromotion{} = applied_command}
assert applied_command.tenant_key == "acme"
```

Planner guidance:
- Phase 32 needs a matching saved-plan generation test on the public facade side, then reuse this replay test style for apply.

### Fake/Ecto parity contract tests

**Source:** [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:159)

Adapter loop pattern:
```elixir
Enum.each(@adapters, fn {_label, adapter, control} ->
  control.ensure_started()
  control.reset!()
  Application.put_env(:rulestead, :store, adapter)
  ...
end)
```

Tenant compare/apply parity assertions from [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:167):
```elixir
assert {:ok, compare} =
         adapter.compare_environments(
           Command.CompareEnvironments.new("staging", "test",
             flag_keys: ["checkout-redesign"],
             tenant_key: "acme"
           )
         )

command = build_apply_command(compare) |> Map.put(:tenant_key, "acme")
assert {:ok, result} = adapter.apply_promotion(command)
```

Immutable environment version assertions from [rulestead/test/rulestead/store/promotion_apply_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/promotion_apply_contract_test.exs:201):
```elixir
assert environment_version.source_environment_key == "staging"
assert environment_version.target_environment_key == "test"
assert environment_version.compare_token == compare.compare_token
assert environment_version.tenant_key == "acme"

assert environment_version.metadata["tenant"] == %{
  "tenant_key" => "acme",
  "scope_source" => "explicit",
  "validation" => %{"evidence" => "same_tenant_guard", "status" => "passed"}
}
```

Planner guidance:
- If Phase 32 changes public plan generation only, keep parity verification focused on downstream plan replay and persisted environment-version scope.

### Public API release contract tests

**Source:** [rulestead/test/rulestead/release_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/release_contract_test.exs:163)

Export catalog lock pattern:
```elixir
expected = MapSet.new(@root_exports)
actual = MapSet.new(Rulestead.__info__(:functions))
assert MapSet.subset?(expected, actual)
```

Planner guidance:
- Phase 32 should preserve existing public function names and arities.
- If tests are added here, they should only lock the existing `plan_promotion/3` or `apply_promotion_plan/2` boundary, not introduce new public exports.

## Shared Patterns

### Bounded Public Opts
**Apply to:** `Rulestead.plan_promotion/3`, `Rulestead.apply_promotion_plan/2`

- Construct a minimal keyword list or normalized command payload from caller input.
- Do not forward raw `opts` into compare/store calls.
- Tenant scope should be carried as one bounded field, `tenant_key`.

### Compare-First Promotion Identity
**Apply to:** plan generation and direct apply replay

- Compare payload is the source of truth for `compare_token`, fingerprints, dependency closure, requested flags, and tenant scope.
- Saved plans should be derived from compare results, then replayed through a fresh `Command.ApplyPromotion`.

### Fail-Closed Drift Handling
**Apply to:** saved plan apply and tenant validation

- Drift conditions return `%Rulestead.Error{type: :invalid_command}` from lower layers.
- Facade layer maps those into manifest envelopes with status `"stale"` or `"blocked"`.
- Tenant mismatch follows the same pattern as compare staleness and dependency drift.

### Fake/Ecto Persistence Parity
**Apply to:** any change touching promotion apply contract

- Keep `tenant_key` on `EnvironmentVersion`.
- Keep tenant provenance under `metadata["tenant"]`.
- Preserve the same apply result keys across adapters.

## No Analog Found

None. Phase 32 can stay inside established public promotion, manifest-plan, compare/apply, and fake/ecto contract patterns.

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/test`, `.planning`
**Files scanned:** 10
**Pattern extraction date:** 2026-05-22

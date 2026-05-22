# Phase 25: Tenancy Helpers & Validation - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 15 inferred files / file groups
**Analogs found:** 13 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/lib/rulestead/tenancy.ex` | behavior/service seam | request-response + transform | [rulestead/lib/rulestead/admin/policy.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/policy.ex:1), [rulestead/lib/rulestead/phoenix.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/phoenix.ex:1) | partial |
| `rulestead/lib/rulestead/tenancy/single_tenant.ex` | provider/default implementation | transform | [rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:29) | partial |
| `rulestead/lib/rulestead/tenancy/scope.ex` or helpers inside `tenancy.ex` | utility/model | transform | [rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:32), [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:40) | role-match |
| `rulestead/lib/rulestead/phoenix.ex` | framework seam | request-response | [rulestead/lib/rulestead/phoenix.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/phoenix.ex:42) | exact |
| `rulestead/lib/rulestead/live_view.ex` | framework seam | request-response | [rulestead/lib/rulestead/live_view.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/live_view.ex:27) | exact |
| `rulestead/lib/rulestead/oban.ex` and `rulestead/lib/rulestead/oban/middleware.ex` | background-job seam | event-driven | [rulestead/lib/rulestead/oban.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban.ex:22), [rulestead/lib/rulestead/oban/middleware.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/middleware.ex:11) | exact |
| `rulestead/lib/rulestead/evaluator.ex` | evaluator service | request-response | [rulestead/lib/rulestead/evaluator.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/evaluator.ex:124) | exact |
| `rulestead/lib/rulestead/ruleset/rollout.ex` | embedded model | CRUD + transform | [rulestead/lib/rulestead/ruleset/rollout.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rollout.ex:10) | exact |
| `rulestead/lib/rulestead/ruleset/experiment.ex` | embedded model | CRUD + transform | [rulestead/lib/rulestead/ruleset/experiment.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/experiment.ex:10) | exact |
| `rulestead/lib/rulestead/manifest/import.ex` | validator/orchestrator | request-response + transform | [rulestead/lib/rulestead/manifest/import.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/import.ex:10), [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:48) | exact |
| `rulestead/lib/rulestead/manifest/plan.ex` | saved artifact model | transform | [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:68) | exact |
| `rulestead/lib/rulestead/manifest/result.ex` | validation result surface | transform | [rulestead/lib/rulestead/manifest/result.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/result.ex:7), [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:64) | exact |
| `rulestead/lib/rulestead/audit_event.ex` | audit metadata model | append-only | [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33) | exact |
| `rulestead/lib/rulestead/store/command.ex` | command model | request-response | [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:12), [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:225) | exact |
| `rulestead_admin/lib/rulestead_admin/live/session.ex` and mounted governance screens | admin session/scope guard | request-response | [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:19), [rulestead/lib/rulestead/admin/authorizer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/authorizer.ex:29) | exact |

## Pattern Assignments

### 1. Minimal tenancy seam and `SingleTenant` default

**Best analogs:** [rulestead/lib/rulestead/admin/policy.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/policy.ex:1), [rulestead/lib/rulestead/context.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/context.ex:29), [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:40)

**Why these are closest**
- `Admin.Policy` is the clearest existing host-owned behavior seam: explicit callbacks, no hidden runtime lookup.
- `Context.new/1` is the clearest small normalizer constructor with safe defaults.
- `Session.resolve/3` is the clearest explicit scope resolver that prefers caller-visible inputs and falls back deterministically.

**Behavior seam pattern** (`admin/policy.ex:27-48`):
```elixir
@callback can?(
            actor :: term(),
            action :: atom(),
            resource :: term(),
            environment_key :: String.t() | atom() | nil
          ) :: boolean()

@optional_callbacks change_request_required?: 4, allow_self_approval?: 4
```

**Default normalizer pattern** (`context.ex:29-45`):
```elixir
@spec new(t() | keyword() | map()) :: t()
def new(attrs) when is_list(attrs) or is_map(attrs) do
  attrs = attrs |> Map.new() |> normalize_aliases()

  %__MODULE__{
    tenant_key: normalize_scalar(Map.get(attrs, :tenant_key)),
    environment: normalize_scalar(Map.get(attrs, :environment)),
    attributes: normalize_attributes(Map.get(attrs, :attributes, %{}))
  }
end
```

**Explicit resolution pattern** (`session.ex:40-71`):
```elixir
def resolve(params, session, opts) when is_map(params) and is_map(session) and is_list(opts) do
  url_env = blank_to_nil(Map.get(params, "env"))

  {environment, env_source} =
    cond do
      selected = find_environment(environments, url_env) -> {selected, :url}
      present?(url_env) -> {default_environment(environments), :default}
      selected = find_environment(environments, remembered_env) -> {selected, :remembered}
      true -> {default_environment(environments), :default}
    end
end
```

**Apply to Phase 25**
- Model `Rulestead.Tenancy` like a host-owned seam, not a hidden singleton.
- Model `SingleTenant` like `Context.new/1`: tiny, deterministic, nil-safe.
- Keep tenant resolution explicit and input-driven like `Session.resolve/3`; do not infer mutating scope from process state.

---

### 2. Explicit scope propagation through runtime, LiveView, and jobs

**Best analogs:** [rulestead/lib/rulestead/phoenix.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/phoenix.ex:42), [rulestead/lib/rulestead/live_view.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/live_view.ex:27), [rulestead/lib/rulestead/oban.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban.ex:22), [rulestead/lib/rulestead/oban/middleware.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/middleware.ex:11)

**Why these are closest**
- All four already propagate `tenant_key` explicitly.
- They keep framework structs at the edge and project only bounded fields into `%Rulestead.Context{}`.
- Oban already demonstrates bounded serialization instead of ambient context leakage.

**Conn/socket projection pattern** (`phoenix.ex:108-117`, `live_view.ex:65-74`):
```elixir
%{}
|> maybe_put(:actor, resolve_opt(conn, opts, :actor, &source_value/3))
|> maybe_put(:targeting_key, resolve_targeting_key(conn, opts, &source_value/3))
|> maybe_put(:tenant_key, resolve_opt(conn, opts, :tenant_key, &source_value/3))
|> maybe_put(:environment, resolve_opt(conn, opts, :environment, &source_value/3))
```

**Bounded job serialization pattern** (`oban.ex:49-57`):
```elixir
def serialize_context(context) do
  context
  |> Context.normalize()
  |> Map.from_struct()
  |> Map.take(@bounded_fields)
  |> Map.update(:actor, nil, &normalize_actor/1)
  |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, Atom.to_string(key), value) end)
end
```

**Strict attach pattern** (`oban/middleware.ex:11-19`):
```elixir
def attach(job, opts) when is_map(job) and is_list(opts) do
  context =
    case Keyword.fetch(opts, :context) do
      {:ok, context} -> context
      :error -> raise ArgumentError, "attach/2 requires :context"
    end

  Oban.put_context(job, context, opts)
end
```

**Apply to Phase 25**
- Extend the existing explicit field-projection posture rather than inventing ambient tenant resolution.
- Tenancy helpers should take `%Context{}` or explicit scope values and return normalized scope outputs.
- Any pubsub/topic or bucketing helper should use the same bounded-field mentality as `Oban.serialize_context/1`.

---

### 3. Tenant-aware bucketing hooks without changing rule topology

**Best analogs:** [rulestead/lib/rulestead/ruleset/rollout.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rollout.ex:10), [rulestead/lib/rulestead/ruleset/experiment.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/experiment.ex:10), [rulestead/lib/rulestead/evaluator.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/evaluator.ex:124)

**Why these are closest**
- `tenant` is already a first-class `bucket_by` enum value.
- `Evaluator` already resolves bucket identity from explicit context fields and keeps strict/permissive behavior stable.
- This is the exact place to add additive composition hooks without changing manifest or ruleset topology.

**Schema enum pattern** (`rollout.ex:10-16`, `experiment.ex:10-16`):
```elixir
@bucket_by_values [:subject, :account, :tenant, :session]

embedded_schema do
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
end
```

**Rollout/experiment hook point** (`evaluator.ex:137-168`, `351-363`):
```elixir
bucket_by = experiment[:bucket_by] || experiment["bucket_by"]

case resolve_bucket_identity(context, bucket_by) do
  {:ok, identity} ->
    Bucket.compute(flag_key, rule_key, Bucket.effective_salt(...), identity, :experiment)
end

defp resolve_bucket_identity(context, :tenant), do: present(context.tenant_key)
defp resolve_bucket_identity(context, "tenant"), do: present(context.tenant_key)
```

**Strict vs permissive failure pattern** (`evaluator.ex:171-188`, `235-251`):
```elixir
{:error, :missing_identity} ->
  if context.strict? do
    {:error, EvaluationError.missing_targeting_key(...)}
  else
    {:skip, :targeting_key_missing, %{warnings: [%{type: :missing_targeting_key, bucket_by: stringify(bucket_by), strict?: false}]}}
  end
```

**Apply to Phase 25**
- Keep `bucket_by` additive.
- Put any actor+tenant composition behind a helper called from `resolve_bucket_identity/2` or adjacent code, not by rewriting rule schemas.
- Preserve strict/permissive behavior and deterministic salts.

---

### 4. Tenant-aware validation finding surfaces for import/promotion

**Best analogs:** [rulestead/lib/rulestead/manifest/import.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/import.ex:63), [rulestead/lib/rulestead/manifest/result.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/result.ex:7), [rulestead/lib/rulestead/promotion/compare.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/promotion/compare.ex:48)

**Why these are closest**
- `Manifest.Import.preview/3` already builds preview findings before apply.
- `Manifest.Result` already defines the stable human/json validation envelope.
- `Promotion.Compare.finding/4` already has the richer finding taxonomy and metadata shape for dependency, stale, and governance issues.

**Preview-first aggregation pattern** (`manifest/import.ex:71-92`):
```elixir
findings =
  diff_result["findings"] ++
    additive_findings(source_manifest, target_manifest, proposed_target_bundle) ++
    dependency_findings(dependency_closure_keys) ++
    governance_findings(target_environment_key, diff_result["status"])

normalized_findings = Result.sort_findings(findings)
status = derive_status(normalized_findings, diff_result["status"], target_environment_key)
```

**Stable finding envelope** (`manifest/result.ex:7-20`, `23-31`):
```elixir
%{
  "status" => normalize_status(...),
  "command" => to_string(...),
  "summary" => normalize_map(...),
  "findings" => findings,
  "details" => normalize_map(...)
}

%{"code" => to_string(code), "severity" => to_string(severity), "scope" => to_string(scope)}
```

**Richer compare finding pattern** (`promotion/compare.ex:48-62`, `64-95`):
```elixir
def finding(severity, class, code, attrs \\ %{}) do
  metadata = attrs |> normalize_metadata() |> Map.drop(["message"])

  %{severity: severity, class: class, code: code}
  |> maybe_put(:message, fetch_message(attrs))
  |> maybe_put(:metadata, if(map_size(metadata) == 0, do: nil, else: metadata))
end

def new_result(attrs) when is_map(attrs) do
  %{overall_status: overall_status(all_findings, flags), findings: sort_findings(findings), flags: sort_flags(flags)}
end
```

**Apply to Phase 25**
- Add tenant-sensitive findings to the existing preview-first path.
- Reuse current finding vocabulary shape: `code`, `severity`, `scope`, optional `metadata`.
- Prefer scope strings like tenant keys or env+tenant scope tokens over hidden session-derived labels.

---

### 5. Saved plan/apply artifacts and command metadata

**Best analogs:** [rulestead/lib/rulestead/manifest/plan.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/plan.ex:68), [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:12), [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:389)

**Why these are closest**
- `Manifest.Plan` is the current saved-artifact contract.
- `GovernanceSupport` is the current metadata normalizer and sensitive-key scrubber.
- `ApplyManifestImport` and `ApplyPromotion` are the current bounded mutation command constructors.

**Deterministic artifact pattern** (`manifest/plan.ex:100-122`, `167-192`, `235-239`):
```elixir
plan_seed = %{
  "mode" => "import",
  "target_environment_key" => target_environment_key,
  "target_fingerprint" => target_fingerprint,
  "dependency_closure_keys" => dependency_closure_keys,
  "proposed_target_bundle" => bundle
}

"plan_token" => plan_token(plan_seed)
```

**Metadata scrub pattern** (`store/command.ex:55-56`, `94-109`):
```elixir
def normalize_metadata(metadata), do: metadata |> normalize_map() |> drop_sensitive_keys()

map
|> Map.drop(["admin_session", "session", "session_data", "session_id", "session_token", "socket"])
```

**Mutation command shape** (`store/command.ex:433-474`):
```elixir
%__MODULE__{
  target_environment_key: ... |> GovernanceSupport.normalize_string(),
  plan_token: ... |> GovernanceSupport.normalize_string(),
  dependency_closure_keys: ... |> normalize_flag_keys(),
  actor: ... |> GovernanceSupport.normalize_actor(),
  reason: ... |> GovernanceSupport.normalize_string(),
  metadata: ... |> GovernanceSupport.normalize_metadata()
}
```

**Apply to Phase 25**
- If tenant scope is added to saved plan/apply artifacts, normalize it like other plan fields and include it in the deterministic seed/fingerprint basis.
- Keep tenant metadata bounded and string-keyed.
- Do not serialize ambient session or broad tenant-owned state into plan artifacts.

---

### 6. Audit metadata handling with bounded tenant context

**Best analogs:** [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33), [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:55)

**Why these are closest**
- `AuditEvent.metadata/1` is already the append-only envelope used for bounded context, links, and governance/schedule metadata.
- `GovernanceSupport.normalize_metadata/1` already scrubs session-like inputs before commands hit adapters.

**Audit envelope pattern** (`audit_event.ex:33-65`):
```elixir
%{
  "before" => normalize_map(...),
  "after" => normalize_map(...),
  "diff" => normalize_map(...),
  "links" => normalize_map(...),
  "context" => context
}
|> maybe_put("request_id", ...)
|> maybe_put("source", ...)
|> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
|> maybe_put("scheduled_execution_id", scheduled_value(attrs, context, :scheduled_execution_id))
```

**Sensitive-context drop pattern** (`audit_event.ex:149-155`, `190-198`):
```elixir
defp normalize_context(map) when is_map(map) do
  map
  |> normalize_map()
  |> drop_sensitive_context_keys()
end

|> Map.drop(["session", "session_data", "session_id", "session_token", "socket_session"])
```

**Apply to Phase 25**
- Put tenant scope into bounded audit `context`/`links` metadata, not into free-form blobs.
- Reuse the existing scrubbing rules.
- Show enough tenant metadata for operator safety, but not a serialized tenant object graph.

---

### 7. Mounted admin scope checks and canonical mounted URLs

**Best analogs:** [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:19), [rulestead/lib/rulestead/admin/authorizer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/authorizer.ex:29), [rulestead_admin/test/rulestead_admin/live/governance_route_contract_test.exs](/Users/jon/projects/rulestead/rulestead_admin/test/rulestead_admin/live/governance_route_contract_test.exs:63)

**Why these are closest**
- `Session.on_mount/4` is the mounted admin entrypoint and already treats env scope as canonical URL/session state.
- `Admin.Authorizer` is the existing explicit policy gate for environment-scoped admin actions.
- Governance route tests already prove redirect-to-canonical-scope behavior.

**Mounted assign + allow-check pattern** (`session.ex:19-37`, `137-139`):
```elixir
resolved = resolve(params, session, policy: session["policy"], mount_path: session["mount_path"])

if allowed?(resolved) do
  socket
  |> assign(:current_environment, resolved.environment)
  |> assign(:rulestead_admin_session, resolved)
else
  {:halt, push_patch(socket, to: resolved.mount_path)}
end

defp allowed?(%{policy: policy, actor: actor, environment: environment}) do
  policy.can?(actor, :access_admin, :flags, environment.key)
end
```

**Authorizer pattern** (`authorizer.ex:29-44`, `185-190`):
```elixir
def authorize(actor, action, resource, environment_key) do
  normalized_environment = normalize_environment(environment_key)
  normalized_actor = normalize_actor(actor)
  normalized_resource = normalize_resource(resource)

  case authorize_normalized(normalized_actor, action, normalized_resource, normalized_environment) do
    :ok -> :ok
    {:error, error, audit_payload} -> {:error, error, audit_payload}
  end
end
```

**Canonical route test pattern** (`governance_route_contract_test.exs:68-79`, `94-110`):
```elixir
assert {:error, {:live_redirect, %{to: "/admin/flags/change-requests?env=staging"}}} =
         live(conn, "/admin/flags/change-requests")

assert {:error, {:live_redirect, %{to: ^expected_sched_path}}} =
         live(conn, "/admin/flags/schedule/#{sched_id}")
```

**Apply to Phase 25**
- Add tenant scope to mounted admin the same way env is handled now: canonical URL/session state, visible assigns, explicit policy calls.
- Fail closed on missing/invalid tenant scope.
- Reuse redirect-to-canonical-query tests rather than creating a second admin-scoping mechanism.

## Shared Patterns

### Explicit scope wins over ambient defaults
- Sources: [rulestead_admin/lib/rulestead_admin/live/session.ex](/Users/jon/projects/rulestead/rulestead_admin/lib/rulestead_admin/live/session.ex:40), [rulestead/lib/rulestead/phoenix.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/phoenix.ex:42), [rulestead/lib/rulestead/oban/middleware.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/middleware.ex:11)
- Apply to: runtime helpers, admin scope helpers, plan/apply flows
- Rule: take scope from explicit params/options/context; reject or default deterministically, never via hidden process state.

### Normalize and scrub metadata before persistence
- Sources: [rulestead/lib/rulestead/store/command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:55), [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:190)
- Apply to: tenant audit metadata, saved plans, governed/apply command metadata
- Rule: string-key maps, sorted lists, drop session-like keys, preserve bounded context only.

### Preview-first validation before apply
- Sources: [rulestead/lib/rulestead/manifest/import.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/import.ex:63), [rulestead/lib/rulestead/manifest/import.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/manifest/import.ex:31)
- Apply to: tenant-sensitive import/promotion checks
- Rule: surface findings in preview results first, then revalidate saved plans before mutation.

### Deterministic bucketing contracts stay stable
- Sources: [rulestead/lib/rulestead/evaluator.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/evaluator.ex:124), [rulestead/lib/rulestead/ruleset/rollout.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/ruleset/rollout.ex:10)
- Apply to: tenant-stable rollout hooks
- Rule: compose identity explicitly, preserve strict/permissive semantics, do not change current rule topology.

## Test Patterns

| Concern | Closest Test Analog | Why |
|---|---|---|
| Context + tenant normalization | [rulestead/test/rulestead/context_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/context_test.exs:6) | Canonical constructor assertions already include `tenant_key`. |
| Conn/LiveView scope projection | [rulestead/test/rulestead/plug_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/plug_test.exs:17), [rulestead/test/rulestead/live_view_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/live_view_test.exs:23) | Verifies explicit source descriptors and trimmed `tenant_key`. |
| Job propagation | [rulestead/test/rulestead/oban_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/oban_test.exs:18) | Proves bounded serialized context survives job boundaries. |
| Bucketing strict/permissive behavior | [rulestead/test/rulestead/evaluator_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/evaluator_test.exs:35) | Existing test shape already checks missing identity warnings vs errors. |
| Import validation and saved plan drift | [rulestead/test/rulestead/manifest/import_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/manifest/import_test.exs:29) | Preview/apply/saved-plan posture is already covered here. |
| Adapter parity for governed import statuses | [rulestead/test/rulestead/store/manifest_import_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/manifest_import_contract_test.exs:162) | Best place to add tenant-sensitive parity checks across Fake/Ecto. |
| Audit metadata redaction | [rulestead/test/rulestead/scheduled_execution_audit_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/scheduled_execution_audit_contract_test.exs:107) | Already asserts bounded metadata and stripped session keys. |
| Mounted admin canonical scope | [rulestead_admin/test/rulestead_admin/live/session_test.exs](/Users/jon/projects/rulestead/rulestead_admin/test/rulestead_admin/live/session_test.exs:9), [rulestead_admin/test/rulestead_admin/live/governance_route_contract_test.exs](/Users/jon/projects/rulestead/rulestead_admin/test/rulestead_admin/live/governance_route_contract_test.exs:63) | Existing env-canonical redirects and session resolution are the exact tenant-scope analog. |

## No Exact Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/lib/rulestead/tenancy/single_tenant.ex` concrete API surface | provider/default implementation | transform | The repo has no existing behavior+default pair for tenancy yet. Copy the callback posture from `Admin.Policy` and constructor/default posture from `Context.new/1`. |
| Mounted admin tenant picker / tenant query param contract | admin UX seam | request-response | Admin currently has canonical env scope only. Reuse `Session.resolve/current_path` and governance route redirect tests when adding tenant scope. |

## Metadata

**Analog search scope:** `rulestead/lib/rulestead/`, `rulestead_admin/lib/rulestead_admin/`, `rulestead/test/`, `rulestead_admin/test/`
**Pattern extraction date:** 2026-05-19

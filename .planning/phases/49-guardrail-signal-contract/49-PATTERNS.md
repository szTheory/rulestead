# Phase 49: Guardrail Signal Contract - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead/lib/rulestead/guardrails/provider.ex` | service | request-response | `rulestead/lib/rulestead/admin/policy.ex` | role-match |
| `rulestead/lib/rulestead/guardrails/signal_fact.ex` | model | transform | `rulestead/lib/rulestead/governance/approval_requirement.ex` | role-match |
| `rulestead/lib/rulestead/ruleset/guardrail.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset/rollout.ex` | exact |
| `rulestead/lib/rulestead/ruleset/rollout.ex` | model | CRUD | `rulestead/lib/rulestead/ruleset/rule.ex` | role-match |
| `rulestead/lib/rulestead/store/command.ex` | utility | transform | `rulestead/lib/rulestead/store/command.ex` | exact |
| `rulestead/lib/rulestead/audit_event.ex` | model | event-driven | `rulestead/lib/rulestead/audit_event.ex` | exact |
| `rulestead/lib/rulestead/telemetry.ex` | utility | event-driven | `rulestead/lib/rulestead/telemetry.ex` | exact |

## Pattern Assignments

### `rulestead/lib/rulestead/guardrails/provider.ex` (service, request-response)

**Primary analog:** `rulestead/lib/rulestead/admin/policy.ex`

**Seam shape** (`rulestead/lib/rulestead/admin/policy.ex:1-6`, `115-136`):
```elixir
defmodule Rulestead.Admin.Policy do
  @moduledoc false
  # Host-owned authorization seam for mounted admin actions.
  #
  # `rulestead_admin` calls `can?/4` with explicit actor, action, resource,
  # and environment scope rather than inferring authorization from roles.

  @callback can?(
              actor :: actor(),
              action :: action(),
              resource :: resource(),
              environment_key :: environment_key()
            ) :: boolean()
```

Copy this posture for the guardrail seam:
- behavior-only boundary
- host owns provider wiring
- explicit arguments for environment and tenant scope
- no hidden session/runtime lookup

**Secondary analog:** `rulestead/lib/rulestead/webhooks/verifier.ex`

**Adapter boundary + bounded outcomes** (`rulestead/lib/rulestead/webhooks/verifier.ex:11-35`):
```elixir
defmodule ProviderAdapter do
  @callback verify_signature(raw_body :: String.t(), headers :: map(), secret :: String.t()) ::
              :ok | {:error, :invalid_signature}

  @callback normalize_payload(raw_body :: String.t(), headers :: map()) ::
              {:ok, map()} | {:error, :malformed}
end

def verify(raw_body, headers, secret, provider_adapter, opts \\ []) do
  with :ok <- provider_adapter.verify_signature(raw_body, headers, secret),
       :ok <- check_freshness(headers, provider_adapter, opts),
       {:ok, normalized} <- provider_adapter.normalize_payload(raw_body, headers) do
    {:ok, InboundEvent.new(normalized)}
  else
    {:error, :invalid_signature} -> {:error, {:rejected, "invalid signature"}}
    {:error, :stale} -> {:error, {:stale, "webhook delivery is stale"}}
    {:error, :malformed} -> {:error, {:malformed, "payload is malformed"}}
  end
end
```

Copy this pattern for:
- host-supplied adapter module argument
- normalization before core use
- bounded fail-closed reasons instead of freeform provider errors

### `rulestead/lib/rulestead/guardrails/signal_fact.ex` (model, transform)

**Primary analog:** `rulestead/lib/rulestead/governance/approval_requirement.ex`

**Bounded struct + normalizer** (`rulestead/lib/rulestead/governance/approval_requirement.ex:5-18`, `20-68`, `71-94`):
```elixir
@enforce_keys [
  :action,
  :environment_key,
  :required_approvals,
  :change_request_required?,
  :self_approval_allowed?
]
defstruct [
  :action,
  :environment_key,
  :required_approvals,
  :change_request_required?,
  :self_approval_allowed?
]

@governed_actions [
  :publish_ruleset,
  :advance_rollout,
  :engage_kill_switch,
  :release_kill_switch,
  :promote_environment
]

def new(attrs) when is_list(attrs) or is_map(attrs) do
  attrs = Map.new(attrs)

  %__MODULE__{
    action: normalize_action(Map.get(attrs, :action)),
    environment_key: normalize_string(Map.get(attrs, :environment_key)),
    required_approvals: normalize_required_approvals(Map.get(attrs, :required_approvals)),
    change_request_required?: normalize_boolean(Map.get(attrs, :change_request_required?)),
    self_approval_allowed?: normalize_boolean(Map.get(attrs, :self_approval_allowed?))
  }
end
```

Use this exact style for a normalized signal fact:
- closed status/reason vocabularies as module attributes
- `new/1` accepts map or keyword
- normalize strings/booleans/integers early
- default invalid values into bounded safe values

**Secondary analog:** `rulestead/lib/rulestead/telemetry.ex:69-77`
```elixir
def metadata(attrs) when is_map(attrs) do
  attrs
  |> Map.take(@shared_keys ++ @optional_keys)
  |> Enum.reduce(%{}, fn
    {_key, nil}, acc -> acc
    {key, value}, acc -> Map.put(acc, key, sanitize_value(key, value))
  end)
end
```

Apply this to keep signal fact metadata bounded and shallow.

### `rulestead/lib/rulestead/ruleset/guardrail.ex` (model, CRUD)

**Primary analog:** `rulestead/lib/rulestead/ruleset/rollout.ex`

**Minimal embed with closed enum** (`rulestead/lib/rulestead/ruleset/rollout.ex:8-31`):
```elixir
@primary_key false

@bucket_by_values [:subject, :account, :tenant, :session]

embedded_schema do
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values)
  field(:percentage, :integer)
  field(:salt, :string)
end

def changeset(rollout, attrs) do
  rollout
  |> cast(attrs, [:bucket_by, :percentage, :salt])
  |> update_change(:salt, &normalize_string/1)
  |> validate_required([:bucket_by, :percentage])
  |> validate_number(:percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  |> validate_length(:salt, max: 255)
end
```

Copy this for guardrail authored config:
- standalone embedded schema
- `Ecto.Enum` for bounded status/operator/scope fields
- explicit scalar fields for threshold/freshness/min-sample inputs
- trim strings in `changeset/2`

**Secondary analog:** `rulestead/lib/rulestead/ruleset/experiment.ex:10-31`
```elixir
@bucket_by_values [:subject, :account, :tenant, :session]

embedded_schema do
  field(:iteration_salt, :string)
  field(:bucket_by, Ecto.Enum, values: @bucket_by_values, default: :subject)
  field(:holdout_percentage, :integer, default: 5)
end
```

Use this when guardrails need authored defaults.

### `rulestead/lib/rulestead/ruleset/rollout.ex` (model, CRUD)

**Primary analog:** `rulestead/lib/rulestead/ruleset/rule.ex`

**Parent embed composition** (`rulestead/lib/rulestead/ruleset/rule.ex:15-27`, `33-47`):
```elixir
embedded_schema do
  field(:key, :string)
  field(:name, :string)
  field(:description, :string)
  field(:strategy, Ecto.Enum, values: @strategies)

  embeds_many(:conditions, Condition, on_replace: :delete)
  embeds_many(:variants, Variant, on_replace: :delete)
  embeds_one(:rollout, Rollout, on_replace: :update)
  embeds_one(:experiment, Experiment, on_replace: :update)
end

def changeset(rule, attrs) do
  rule
  |> cast(attrs, [:key, :name, :description, :strategy, :value, :audience_id, :audience_key])
  |> cast_embed(:conditions, with: &Condition.changeset/2)
  |> cast_embed(:variants, with: &Variant.changeset/2)
  |> cast_embed(:rollout, with: &Rollout.changeset/2)
  |> cast_embed(:experiment, with: &Experiment.changeset/2)
  |> validate_required([:key, :strategy])
  |> validate_rule_shape()
end
```

If Phase 49 attaches guardrails to rollout authored state, follow this composition style:
- add `embeds_many` or `embeds_one` at the authored parent
- validate guardrail presence/absence with the same explicit `validate_*` helper style
- keep authored-state legality in changesets, not runtime-only code

### `rulestead/lib/rulestead/store/command.ex` (utility, transform)

**Primary analog:** `rulestead/lib/rulestead/store/command.ex`

**Bounded provenance vocabulary** (`rulestead/lib/rulestead/store/command.ex:17-19`, `64-79`, `84-129`, `154-172`, `222-280`):
```elixir
@tenant_scope_sources ["explicit", "host_resolved", "single_tenant"]
@tenant_validation_evidence ["same_tenant_guard", "single_tenant", "not_applicable"]
@tenant_validation_status ["passed", "bypassed"]

def normalize_tenant_provenance(value) when is_list(value) or is_map(value) do
  value = normalize_map(value)
  validation = normalize_tenant_validation_map(Map.get(value, "validation"))

  provenance =
    %{}
    |> maybe_put("tenant_key", normalize_string(Map.get(value, "tenant_key")))
    |> maybe_put("scope_source", normalize_enum(Map.get(value, "scope_source"), @tenant_scope_sources))
    |> maybe_put("validation", validation)

  if map_size(provenance) == 0, do: nil, else: provenance
end

def tenant_provenance(source, opts \\ []) do
  ...
  %{}
  |> maybe_put("tenant_key", tenant_key)
  |> maybe_put("scope_source", scope_source)
  |> maybe_put("validation", validation)
end

def normalize_map(map) when is_map(map) do
  Map.new(map, fn
    {key, value} when is_map(value) -> {to_string(key), normalize_map(value)}
    {key, value} when is_list(value) -> {to_string(key), Enum.map(value, &normalize_value/1)}
    {key, value} -> {to_string(key), normalize_value(value)}
  end)
end
```

Phase 49 should copy this exactly for any guardrail scope provenance or command metadata:
- string-keyed normalized maps
- explicit scope-source enum
- no raw provider blobs
- helpers that merge explicit source, metadata, and fallback deterministically

### `rulestead/lib/rulestead/audit_event.ex` (model, event-driven)

**Primary analog:** `rulestead/lib/rulestead/audit_event.ex`

**Audit metadata normalization** (`rulestead/lib/rulestead/audit_event.ex:36-86`, `170-239`):
```elixir
def metadata(attrs \\ %{}) when is_list(attrs) or is_map(attrs) do
  attrs = Map.new(attrs)
  context = normalize_context(Map.get(attrs, :context) || Map.get(attrs, "context"))
  before = normalize_map(Map.get(attrs, :before) || Map.get(attrs, "before"))
  after_map = normalize_map(Map.get(attrs, :after) || Map.get(attrs, "after"))
  diff = normalize_map(Map.get(attrs, :diff) || Map.get(attrs, "diff"))

  tenant =
    attrs
    |> Map.get(:tenant, Map.get(attrs, "tenant"))
    |> Kernel.||(Map.get(attrs, :tenant_provenance) || Map.get(attrs, "tenant_provenance"))
    |> Command.GovernanceSupport.normalize_tenant_provenance()

  %{
    "before" => before,
    "after" => after_map,
    "diff" => diff,
    "links" => normalize_map(Map.get(attrs, :links) || Map.get(attrs, "links")),
    "context" => context
  }
  |> maybe_put("tenant", tenant)
  |> maybe_put("request_id", Map.get(attrs, :request_id) || Map.get(attrs, "request_id"))
  |> maybe_put("source", Map.get(attrs, :source) || Map.get(attrs, "source"))
  |> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
  |> maybe_put("approval_id", governance_value(attrs, context, :approval_id))
  |> maybe_put("governance_action", governance_value(attrs, context, :governance_action))
end
```

Copy this pattern for future guardrail audits:
- top-level bounded keys only
- reuse tenant provenance normalizer
- normalize atoms to strings
- drop sensitive context keys before durable storage

### `rulestead/lib/rulestead/telemetry.ex` (utility, event-driven)

**Primary analog:** `rulestead/lib/rulestead/telemetry.ex`

**Bounded event metadata** (`rulestead/lib/rulestead/telemetry.ex:9-10`, `69-77`, `80-108`, `164-194`, `212-260`, `356-408`):
```elixir
@shared_keys ~w(flag_key flag_type environment snapshot_version cache_age_ms reason has_targeting_key? matched_rule_count)a
@optional_keys ~w(operation source refresh_status audit_action error_kind change_request_id correlation_id audit_event_id resource_key governance_action environment_key attempt_count execution_mode executed_by webhook_provider webhook_delivery_id webhook_receipt_id rejection_reason experiment_bucket)a

def metadata(attrs) when is_map(attrs) do
  attrs
  |> Map.take(@shared_keys ++ @optional_keys)
  |> Enum.reduce(%{}, fn
    {_key, nil}, acc -> acc
    {key, value}, acc -> Map.put(acc, key, sanitize_value(key, value))
  end)
end

def base_metadata(flag_payload, context, attrs \\ %{}) do
  context = normalize_context(context)

  attrs
  |> Map.new()
  |> Map.put_new(:environment, environment_value(flag_payload, context, attrs))
  |> Map.put_new(:has_targeting_key?, not is_nil(context.targeting_key))
end
```

Use this for any Phase 49 telemetry additions:
- predeclared metadata keys only
- `Context.normalize/1` as the scope carrier
- sanitize integers/booleans/atoms instead of passing raw values through

## Shared Patterns

### Explicit Host-Owned Seams

**Sources:**
- `rulestead/lib/rulestead/admin/policy.ex:1-6`
- `rulestead/lib/rulestead/admin/policy.ex:115-136`
- `rulestead/lib/rulestead/webhooks/verifier.ex:11-35`

Apply to all new guardrail provider/query modules:
- define a behavior or explicit module seam
- require explicit actor/environment/tenant inputs where relevant
- keep provider credentials and upstream identity in the host app
- return bounded normalized outcomes, never raw provider strings as contract truth

### Explicit Tenant and Environment Scope Propagation

**Sources:**
- `rulestead/lib/rulestead/context.ex:35-43`
- `rulestead/lib/rulestead/store/command.ex:84-129`
- `rulestead_admin/lib/rulestead_admin/live/session.ex:62-123`
- `rulestead_admin/lib/rulestead_admin/live/environment_compare_live/index.ex:161-170`

**Context carrier:**
```elixir
%__MODULE__{
  actor: actor,
  targeting_key: normalize_scalar(Map.get(attrs, :targeting_key) || actor_key(actor)),
  tenant_key: normalize_scalar(Map.get(attrs, :tenant_key)),
  environment: normalize_scalar(Map.get(attrs, :environment)),
  request_id: normalize_scalar(Map.get(attrs, :request_id)),
  session_id: normalize_scalar(Map.get(attrs, :session_id)),
  strict?: normalize_boolean(Map.get(attrs, :strict?, false))
}
```

**Mounted scope threading:**
```elixir
params
|> Map.put("env", env_key)
|> maybe_put_scope_param("tenant", tenant_key)
|> encode_params()
```

Guardrail contracts should preserve both scopes explicitly end to end. Do not infer them from process state or session.

### Bounded Enum and Status Vocabularies

**Sources:**
- `rulestead/lib/rulestead/ruleset/rollout.ex:10-16`
- `rulestead/lib/rulestead/governance/approval_requirement.ex:20-34`
- `rulestead/lib/rulestead/audit_event.ex:14-26`

Copy the repo’s pattern:
- define allowed values once in module attributes
- use `Ecto.Enum` in authored embeds
- expose `values()` helpers only when other modules need them
- normalize invalid input into safe bounded defaults or reject in changesets

### Fail-Closed Deterministic Evaluation

**Sources:**
- `rulestead/lib/rulestead/evaluator.ex:183-204`
- `rulestead/lib/rulestead/evaluator.ex:258-275`
- `rulestead/lib/rulestead/promotion/apply.ex:81-108`

**Pattern excerpt:**
```elixir
{:error, :missing_identity} ->
  if context.strict? do
    {:error, EvaluationError.missing_targeting_key(...)}
  else
    {:skip, :targeting_key_missing, %{...}}
  end
```

```elixir
cond do
  stale_preview?(command, compare) ->
    {:error, StoreError.invalid_command("promotion compare preview is stale")}
  blocker_findings?(compare) ->
    {:error, StoreError.invalid_command("promotion compare preview has blocker findings")}
end
```

Guardrail signal status handling should match this:
- stale/unsupported/missing data is not healthy
- bounded skip/error reasons drive later automation
- decision logic stays deterministic and explicit

### Bounded Audit and Command Metadata

**Sources:**
- `rulestead/lib/rulestead/store/command.ex:61-79`
- `rulestead/lib/rulestead/audit_event.ex:44-85`
- `rulestead/lib/rulestead/telemetry.ex:69-77`
- `rulestead_admin/lib/rulestead_admin/live/flag_live/rollouts.ex:589-596`

**Command metadata pattern:**
```elixir
%{
  request_id: socket.id,
  source: source,
  reason: reason,
  plan: "07-09",
  environment_key: socket.assigns.current_environment.key
}
```

Phase 49 additions should:
- keep metadata bounded and string-key normalizable
- carry explicit `request_id`, `source`, `reason`, `environment_key`, and tenant provenance when present
- avoid storing raw signal payloads as durable command/audit truth

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `rulestead/lib/rulestead/guardrails/signal_status.ex` | model | transform | No existing module models provider-agnostic rollout health facts directly; compose from `ApprovalRequirement`, `AuditEvent`, and `Telemetry` patterns instead. |

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead_admin/lib`, `.planning/phases/49-guardrail-signal-contract`
**Files scanned:** 17
**Pattern extraction date:** 2026-05-26

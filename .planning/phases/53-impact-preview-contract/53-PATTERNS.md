# Phase 53: Impact Preview Contract - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 17 new/modified files
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `rulestead/lib/rulestead/targeting/impact_preview.ex` | service | transform | `rulestead/lib/rulestead/promotion/compare.ex` | exact |
| `rulestead/lib/rulestead/targeting/audience_dependencies.ex` | service | transform | `rulestead/lib/rulestead/promotion/compare.ex` + `rulestead/lib/rulestead/manifest/import.ex` | exact |
| `rulestead/lib/rulestead/store/command.ex` | model | request-response | `Command.CompareEnvironments`, `Command.ApplyPromotion`, `Command.ApplyManifestImport` | exact |
| `rulestead/lib/rulestead/store.ex` | config | request-response | existing store callback list | exact |
| `rulestead/lib/rulestead.ex` | controller | request-response | existing public facade + `admin_read`/`admin_write` paths | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD | promotion/manifest apply + list audience + snapshot/audit code | exact |
| `rulestead/lib/rulestead/fake.ex` | service | CRUD | fake promotion/manifest/list audience implementation | exact |
| `rulestead/lib/rulestead/fake/control.ex` | utility | CRUD | existing fake control seeding helpers | role-match |
| `rulestead/lib/rulestead/store/redis.ex` | service | request-response | read-only unsupported callback loop | exact |
| `rulestead/lib/rulestead/runtime/snapshot.ex` | model | transform | existing runtime snapshot compiler | exact |
| `rulestead/lib/rulestead/evaluator.ex` | service | transform | existing rule/condition/trace evaluator | exact |
| `rulestead/lib/rulestead/audit_event.ex` | model | transform | existing audit metadata normalizer | exact |
| `rulestead/test/rulestead/targeting/impact_preview_test.exs` | test | transform | `rulestead/test/rulestead/promotion/compare_test.exs` | exact |
| `rulestead/test/rulestead/store/audience_impact_contract_test.exs` | test | CRUD | `rulestead/test/rulestead/store/compare_contract_test.exs` | exact |
| `rulestead/test/rulestead/store/ecto_audience_impact_contract_test.exs` | test | CRUD | `rulestead/test/rulestead/store/promotion_apply_contract_test.exs` | exact |
| `rulestead/test/rulestead/runtime/audience_snapshot_test.exs` | test | transform | `rulestead/test/rulestead/runtime_snapshot_test.exs` + `evaluator_test.exs` | role-match |
| `rulestead/test/rulestead/audience_mutation_audit_test.exs` | test | request-response | `rulestead/test/rulestead/admin_security_contract_test.exs` | exact |

## Pattern Assignments

### `rulestead/lib/rulestead/targeting/impact_preview.ex` (service, transform)

**Analog:** `rulestead/lib/rulestead/promotion/compare.ex`

**Imports and module shape** (lines 1-8):
```elixir
# credo:disable-for-this-file
defmodule Rulestead.Promotion.Compare do
  @moduledoc false

  alias Rulestead.Store.Command

  @schema_version 1
  @severity_rank %{blocker: 0, warning: 1, info: 2, in_sync: 3}
```

**Fingerprint/token pattern** (lines 25-48):
```elixir
@spec fingerprint(term()) :: String.t()
def fingerprint(term) do
  "sha256:" <> hash_term(term)
end

@spec compare_token(map()) :: String.t()
def compare_token(attrs) when is_map(attrs) do
  token_payload = %{
    schema_version: @schema_version,
    source_environment_key:
      normalize_string(attrs[:source_environment_key] || attrs["source_environment_key"]),
    target_environment_key:
      normalize_string(attrs[:target_environment_key] || attrs["target_environment_key"]),
    tenant_key: normalize_string(attrs[:tenant_key] || attrs["tenant_key"]),
    compared_flag_keys:
      normalize_string_list(attrs[:compared_flag_keys] || attrs["compared_flag_keys"]),
    dependency_closure_keys:
      normalize_string_list(attrs[:dependency_closure_keys] || attrs["dependency_closure_keys"]),
    source_fingerprint: attrs[:source_fingerprint] || attrs["source_fingerprint"],
    target_fingerprint: attrs[:target_fingerprint] || attrs["target_fingerprint"]
  }

  "cmp_" <> hash_term(token_payload)
end
```

Copy this pattern with an audience-specific prefix such as `audprev_`, and bind token basis to `environment_key`, `tenant_key`, `audience_key`, before/after definition fingerprints, affected references, explicit redacted sample digest, and preview basis.

**Result/finding shape** (lines 50-63, 66-99):
```elixir
def finding(severity, class, code, attrs \\ %{}) do
  metadata =
    attrs
    |> normalize_metadata()
    |> Map.drop(["message"])

  %{
    severity: severity,
    class: class,
    code: code
  }
  |> maybe_put(:message, fetch_message(attrs))
  |> maybe_put(:metadata, if(map_size(metadata) == 0, do: nil, else: metadata))
end
```

Return preview findings with the same `severity`, `class`, `code`, optional `message`, and `metadata` structure. Use blocker findings for stale/missing/archived/incompatible/tenant-mismatched references.

**Hash normalization** (lines 303-319):
```elixir
def normalize_term(term) when is_map(term) do
  term
  |> Enum.map(fn {key, value} -> {normalize_term(key), normalize_term(value)} end)
  |> Enum.sort()
end

def normalize_term(term) when is_list(term), do: Enum.map(term, &normalize_term/1)
def normalize_term(term) when is_atom(term), do: Atom.to_string(term)
def normalize_term(term), do: term

defp hash_term(term) do
  term
  |> normalize_term()
  |> :erlang.term_to_binary()
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

### `rulestead/lib/rulestead/targeting/audience_dependencies.ex` (service, transform)

**Analogs:** `rulestead/lib/rulestead/promotion/compare.ex`, `rulestead/lib/rulestead/manifest/import.ex`, `rulestead/lib/rulestead/ruleset/rule.ex`

**Dependency closure from authored rules** (compare lines 231-240):
```elixir
@spec dependency_closure_keys(map() | nil) :: [String.t()]
def dependency_closure_keys(nil), do: []

def dependency_closure_keys(payload) when is_map(payload) do
  payload
  |> authored_state()
  |> Map.get(:active_ruleset)
```

**Manifest dependency blockers** (manifest import lines 173-204):
```elixir
defp dependency_findings(dependency_closure_keys) do
  audience_map =
    case Rulestead.list_audiences(include_archived?: true, limit: 10_000) do
      {:ok, audiences} -> Map.new(audiences, &{"audience:" <> &1.key, &1})
      {:error, _error} -> %{}
    end

  dependency_closure_keys
  |> Enum.flat_map(fn key ->
    case Map.get(audience_map, key) do
      nil ->
        [
          Result.finding("missing_dependency", "blocker", key,
            message: "referenced audience was not found"
          )
        ]
```

**Rule shape source** (ruleset rule lines 13, 21-22, 60-65):
```elixir
@strategies [:forced_value, :percentage_rollout, :variant_split, :segment_match, :experiment]

field(:audience_id, :binary_id)
field(:audience_key, :string)

defp validate_audience_reference(changeset) do
  if get_field(changeset, :strategy) == :segment_match and
       is_nil(get_field(changeset, :audience_id)) and
       blank?(get_field(changeset, :audience_key)) do
    add_error(changeset, :audience_key, "must reference an audience for segment_match rules")
```

Search flags/rulesets for `strategy: :segment_match`/`"segment_match"` and `audience_key`; return stable sorted references with flag key, ruleset version/status, rule key, lifecycle/rollout hints, and hidden/blocked findings where appropriate.

### `rulestead/lib/rulestead/store/command.ex` (model, request-response)

**Analog:** `Command.CompareEnvironments`, `Command.ApplyPromotion`, `Command.ApplyManifestImport`

**Shared normalization helpers** (lines 35-75, 145-153):
```elixir
def fetch_required!(attrs, key) do
  case fetch(attrs, key) do
    nil -> raise KeyError, key: key, term: attrs
    value -> value
  end
end

def fetch(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))

def normalize_string(value) when is_binary(value) do
  value
  |> String.trim()
  |> case do
    "" -> nil
    normalized -> normalized
  end
end

def normalize_actor(actor) when is_list(actor) or is_map(actor) do
  actor = Map.new(actor)

  %{}
  |> maybe_put("id", fetch(actor, :id) |> normalize_string())
  |> maybe_put("type", fetch(actor, :type) |> normalize_string())
  |> maybe_put("display", fetch(actor, :display) |> normalize_string())
  |> maybe_put("roles", fetch(actor, :roles) || fetch(actor, :role))
end
```

**Preview command shape** (compare command lines 685-710):
```elixir
@enforce_keys [:source_environment_key, :target_environment_key]
defstruct [
  :source_environment_key,
  :target_environment_key,
  tenant_key: nil,
  flag_keys: nil,
  compare_token: nil
]

def new(source_environment_key, target_environment_key, opts \\ []) do
  %__MODULE__{
    source_environment_key: GovernanceSupport.normalize_string(source_environment_key),
    target_environment_key: GovernanceSupport.normalize_string(target_environment_key),
    tenant_key: GovernanceSupport.normalize_string(Keyword.get(opts, :tenant_key)),
    flag_keys: normalize_flag_keys(Keyword.get(opts, :flag_keys)),
    compare_token: GovernanceSupport.normalize_string(Keyword.get(opts, :compare_token))
  }
end
```

**Apply command shape** (apply promotion lines 739-764, 782-835):
```elixir
@enforce_keys [
  :source_environment_key,
  :target_environment_key,
  :flag_keys,
  :compare_token,
  :compare_schema_version,
  :source_fingerprint,
  :target_fingerprint,
  :dependency_closure_keys,
  :proposed_target_bundle
]
defstruct [
  :source_environment_key,
  :target_environment_key,
  :tenant_key,
  :flag_keys,
  :compare_token,
  :compare_schema_version,
  :source_fingerprint,
  :target_fingerprint,
  :dependency_closure_keys,
  :proposed_target_bundle,
  actor: nil,
  reason: nil,
  metadata: %{}
]
```

New audience commands should mirror this split: one preview command with optional `preview_fingerprint` for staleness checks, and one apply/archive command with required preview fingerprint/schema/basis plus actor, reason, metadata, environment scope, tenant scope, audience key, and proposed definition.

### `rulestead/lib/rulestead/store.ex` (config, request-response)

**Analog:** existing behavior callbacks

**Callback style** (lines 13-29):
```elixir
@type result(value) :: {:ok, value} | {:error, Error.t()}

@callback fetch_flag(Command.FetchFlag.t()) :: result(map())
@callback compare_environments(Command.CompareEnvironments.t()) :: result(map())
@callback apply_promotion(Command.ApplyPromotion.t()) :: result(map())
@callback preview_manifest_import(Command.PreviewManifestImport.t()) :: result(map())
@callback apply_manifest_import(Command.ApplyManifestImport.t()) :: result(map())
@callback fetch_snapshot(Command.FetchSnapshot.t()) :: result(map())
@callback create_flag(Command.CreateFlag.t()) :: result(map())
@callback update_flag(Command.UpdateFlag.t()) :: result(map())
@callback save_draft_ruleset(Command.SaveDraftRuleset.t()) :: result(map())
@callback publish_ruleset(Command.PublishRuleset.t()) :: result(map())
@callback archive_flag(Command.ArchiveFlag.t()) :: result(map())
@callback list_flags(Command.ListFlags.t()) :: result(Command.Page.t(map()))
@callback list_environments(Command.ListEnvironments.t()) :: result([map()])
@callback list_audiences(Command.ListAudiences.t()) :: result([map()])
```

Add callbacks near audience/list/promotion surfaces, for example `preview_audience_impact/1`, `apply_audience_mutation/1`, and/or `archive_audience/1`, all returning `result(map())`.

### `rulestead/lib/rulestead.ex` (controller, request-response)

**Analog:** public facade, admin read/write authorization

**Facade overloads** (lines 73-87, 92-107):
```elixir
@spec compare_environments(String.t() | atom(), String.t() | atom(), keyword()) ::
        Store.result(map())
def compare_environments(source_environment_key, target_environment_key, opts \\ []) do
  source_environment_key
  |> Command.CompareEnvironments.new(target_environment_key, opts)
  |> compare_environments()
end

@spec compare_environments(Command.CompareEnvironments.t()) :: Store.result(map())
def compare_environments(%Command.CompareEnvironments{} = command) do
  admin_read(:compare_environments, command)
end

@spec apply_promotion(Command.ApplyPromotion.t()) :: Store.result(map())
def apply_promotion(%Command.ApplyPromotion{} = command) do
  with :ok <- Apply.validate(command) do
    admin_write(:apply_promotion, command)
  end
end
```

**Admin write envelope** (lines 1334-1367):
```elixir
defp admin_write(operation, command) do
  redacted_command = redact_command(command)
  resource = command_resource(redacted_command)
  action = command_action(operation, redacted_command)

  Telemetry.span(
    [:rulestead, :admin, :mutation],
    Telemetry.metadata(
      redacted_command
      |> Telemetry.command_metadata(%{
        operation: Atom.to_string(operation),
        audit_action: Atom.to_string(action)
      })
      |> Map.merge(Telemetry.governance_metadata(redacted_command, %{action: action}))
    ),
    fn ->
      {result, executed_command} =
        case authorize_admin_write(operation, redacted_command, action, resource) do
          :ok ->
            {run_store(operation, [redacted_command], redacted_command), redacted_command}
```

Preview should use `admin_read` if it only reads authored state; apply/archive mutations must use `admin_write` so denied writes persist the existing denied-audit path.

### `rulestead/lib/rulestead/store/ecto.ex` (service, CRUD)

**Analog:** promotion/manifest apply, list audiences, snapshot publish, audit changesets

**Imports and aliases** (lines 1-48):
```elixir
defmodule Rulestead.Store.Ecto do
  import Ecto.Query

  alias Ecto.Changeset
  alias Ecto.ConstraintError
  alias Ecto.Multi

  alias Rulestead.{
    Admin.Lifecycle,
    Audience,
    Governance.Approval,
    Governance.ChangeRequest,
    Governance.ExecutionAttempt,
    Governance.ScheduledExecution,
    AuditEvent,
```

**Preview/query pattern** (compare lines 69-96):
```elixir
def compare_environments(%Command.CompareEnvironments{} = command) do
  with {:ok, source_environment} <- fetch_environment(command.source_environment_key),
       {:ok, target_environment} <- fetch_environment(command.target_environment_key) do
    flags =
      compare_flags_query(
        source_environment.key,
        target_environment.key,
        command.flag_keys
      )
      |> Repo.all()

    audiences =
      from(audience in Audience)
      |> Repo.all()
      |> Map.new(&{&1.key, audience_summary(&1)})

    {:ok,
     Compare.compare_projected(%{
       source_environment: environment_summary(source_environment),
```

**Transactional apply pattern** (lines 125-170):
```elixir
defp run_promotion_apply(%Command.ApplyPromotion{} = command, opts) do
  with {:ok, _source_environment} <- fetch_environment(command.source_environment_key),
       {:ok, target_environment} <- fetch_environment(command.target_environment_key),
       :ok <-
         ensure_promotion_target_allowed(
           target_environment.key,
           Keyword.get(opts, :allow_protected_target?, false)
         ) do
    published_at = now()

    Multi.new()
    |> Multi.run(:applied_flags, fn repo, _changes ->
      apply_promotion_bundle(repo, target_environment, command, published_at)
    end)
    |> Multi.run(:environment_version, fn repo, %{applied_flags: applied_flags} ->
      insert_environment_version(repo, target_environment, command, applied_flags)
    end)
    |> Multi.run(:runtime_snapshot, fn repo, _changes ->
      insert_runtime_snapshot(repo, target_environment, published_at)
    end)
    |> Repo.transact()
```

For audience apply/archive, re-build the current preview inside the transaction, compare supplied fingerprint/token, mutate the `Audience` row, write audit evidence, and publish a snapshot if runtime audience definitions changed.

**Audience list/summary pattern** (lines 536-546, 2450-2459):
```elixir
def list_audiences(%Command.ListAudiences{} = command) do
  audiences =
    Audience
    |> maybe_filter_archived_audiences(command.include_archived?)
    |> maybe_filter_audience_query(command.query)
    |> order_by([audience], asc: audience.key)
    |> limit(^command.limit)
    |> Repo.all()
    |> Enum.map(&audience_summary/1)

  {:ok, audiences}
end
```

**Snapshot publish pattern** (lines 2266-2279, 2312-2327):
```elixir
defp insert_runtime_snapshot(repo, environment, published_at) do
  snapshot_payload = build_environment_snapshot_payload(repo, environment)
  payload = :erlang.term_to_binary(snapshot_payload)

  attrs = %{
    environment_key: environment.key,
    version: next_snapshot_version(repo, environment.key),
    payload: payload,
    payload_checksum: payload_checksum(payload),
    metadata: %{
      schema_version: @snapshot_schema_version,
      flag_count: map_size(snapshot_payload.flags)
    },
    published_at: published_at
  }
```

Add `audiences: compiled_audience_definitions` to `build_environment_snapshot_payload/2` and bump `@snapshot_schema_version` if evaluator uses it.

**Audit pattern** (lines 2814-2836):
```elixir
defp audit_event_changeset(audit_event, command, event_type, result, opts) do
  AuditEvent.changeset(audit_event, %{
    event_type: event_type,
    resource_type: "flag",
    resource_key: to_string(Map.get(opts, :resource_key, Map.get(command, :flag_key))),
    environment_key:
      to_string(Map.get(opts, :environment_key, Map.get(command, :environment_key))),
    actor_id: actor_value(command.actor, "id"),
    actor_type: to_string(actor_value(command.actor, "type") || "operator"),
    actor_display: actor_value(command.actor, "display"),
    reason: Map.get(command, :reason),
    result: result,
    metadata:
      AuditEvent.metadata(%{
        before: Map.get(opts, :before, %{}),
        after: Map.get(opts, :after, %{}),
        diff: diff_map(Map.get(opts, :before, %{}), Map.get(opts, :after, %{})),
        links: Map.get(opts, :links, %{}),
        tenant: Command.GovernanceSupport.tenant_provenance(command),
        context: Map.get(command, :metadata, %{}),
```

Audience audit events should set `resource_type: "audience"`, resource key to `audience_key`, event types like `audience.preview`, `audience.update`, `audience.archive`, and metadata keys for preview fingerprint, affected-reference summary, explicit samples, uncertainty, blockers, tenant, and request id.

### `rulestead/lib/rulestead/fake.ex` (service, CRUD)

**Analog:** Fake store wrapper/handlers, compare/apply parity

**Adapter wrapper pattern** (lines 81-149):
```elixir
@impl Store
def compare_environments(%Command.CompareEnvironments{} = command) do
  call({:compare_environments, command})
end

@impl Store
def apply_promotion(%Command.ApplyPromotion{} = command) do
  call({:apply_promotion, command})
end

@impl Store
def list_audiences(%Command.ListAudiences{} = command) do
  call({:list_audiences, command})
end
```

**Handler/list pattern** (lines 703-715):
```elixir
def handle_call({:list_audiences, command}, _from, state) do
  audiences =
    state
    |> Map.get(:audiences, %{})
    |> Map.values()
    |> Enum.reject(fn audience ->
      Map.get(audience, :archived_at) && not command.include_archived?
    end)
    |> Enum.filter(&matches_audience_query?(&1, command.query))
    |> Enum.sort_by(& &1.key)
    |> Enum.take(command.limit)

  {:reply, {:ok, audiences}, state}
end
```

**Compare parity pattern** (lines 2896-2913):
```elixir
source_flags = compare_payloads_for_environment(state, source_environment.key)
target_flags = compare_payloads_for_environment(state, target_environment.key)

audiences =
  Map.new(state.audiences, fn {key, audience} -> {key, audience_summary(audience)} end)

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

**Apply parity pattern** (lines 3809-3860):
```elixir
defp do_apply_promotion(state, command, opts) do
  with {:ok, _source_environment} <-
         fetch_environment_from_state(state, command.source_environment_key),
       {:ok, target_environment} <-
         fetch_environment_from_state(state, command.target_environment_key),
       :ok <-
         ensure_promotion_target_allowed(
           target_environment.key,
           Keyword.get(opts, :allow_protected_target?, false)
         ),
       {:ok, applied_state} <- apply_promotion_bundle(state, target_environment.key, command) do
    version = next_environment_version(state, target_environment.key)
```

Fake must implement audience preview/apply with the same payload shape, staleness blockers, audit result, and snapshot side effects as Ecto so adapter contract tests can compare.

### `rulestead/lib/rulestead/fake/control.ex` (utility, CRUD)

**Analog:** existing fake control helpers

**Control helper pattern** (lines 12-45, 47-61):
```elixir
@spec ensure_started() :: :ok
def ensure_started do
  case Process.whereis(Fake) do
    nil ->
      case Fake.start_link() do
        {:ok, _pid} -> :ok
        {:error, {:already_started, _pid}} -> :ok
        {:error, reason} -> raise "failed to start Rulestead.Fake: #{inspect(reason)}"
      end

    _pid ->
      :ok
  end
end

@spec put_flag!(map()) :: map()
def put_flag!(attrs) do
  ensure_started()

  case Fake.put_flag(normalize_seed_attrs(attrs)) do
    {:ok, flag} -> flag
    {:error, error} -> raise error
  end
end
```

Add `put_audience!/1` only as a test-only helper, separate from the `Store` behavior, mirroring `put_flag!/1` and normalizing seed attrs if needed.

### `rulestead/lib/rulestead/store/redis.ex` (service, request-response)

**Analog:** read-only unsupported callback loop

**Unsupported mutation pattern** (lines 28-76):
```elixir
for callback <- [
      :compare_environments,
      :apply_promotion,
      :preview_manifest_import,
      :apply_manifest_import,
      :fetch_flag,
      :create_flag,
      :update_flag,
      :save_draft_ruleset,
      :publish_ruleset,
      :archive_flag,
      :list_flags,
      :list_environments,
      :list_audiences,
      :record_evaluation,
      :advance_rollout,
      :evaluate_guarded_rollout,
      :fetch_guardrail_status,
      :engage_kill_switch,
      :release_kill_switch,
      :list_audit_events,
      :rollback_audit_event,
      :submit_change_request,
      :approve_change_request,
      :reject_change_request,
      :cancel_change_request,
      :execute_change_request,
      :fetch_change_request,
      :list_change_requests,
      :schedule_change_request,
      :schedule_governed_action,
      :cancel_scheduled_execution,
      :requeue_scheduled_execution,
      :execute_scheduled_execution,
      :fetch_scheduled_execution,
      :list_scheduled_executions,
      :receive_inbound_webhook,
      :fetch_webhook_record,
      :list_webhook_records,
      :create_webhook_destination,
      :update_webhook_destination,
      :fetch_webhook_destination,
      :list_webhook_destinations,
      :list_webhook_deliveries,
      :retry_webhook_delivery
    ] do
  @impl Store
  def unquote(callback)(_command), do: {:error, StoreError.invalid_command(@read_only_message)}
end
```

If `Store` callbacks expand, add audience preview/mutation callbacks here unless a read-only preview over snapshots is explicitly designed. Do not make Redis an authoring mutation surface.

### `rulestead/lib/rulestead/runtime/snapshot.ex` (model, transform)

**Analog:** runtime snapshot compiler

**Struct and compile boundary** (lines 6-15, 32-51):
```elixir
@enforce_keys [:environment_key, :version, :published_at, :generated_at, :flags]
defstruct [
  :environment_key,
  :version,
  :published_at,
  :generated_at,
  :flags,
  metadata: %{},
  flag_keys: []
]

def compile(snapshot) when is_map(snapshot) do
  with {:ok, environment_key} <- fetch_string(snapshot, :environment_key),
       {:ok, version} <- fetch_integer(snapshot, :version),
       {:ok, published_at} <- fetch_datetime(snapshot, :published_at),
       {:ok, payload} <- fetch_binary(snapshot, :payload),
       {:ok, decoded_payload} <- decode_payload(payload),
       {:ok, flags, generated_at} <- compile_payload(decoded_payload, environment_key) do
```

**Payload validation pattern** (lines 68-84):
```elixir
defp compile_payload(payload, environment_key) do
  with {:ok, payload_environment_key} <- fetch_string(payload, :environment_key),
       true <- payload_environment_key == environment_key,
       flags when is_map(flags) <- fetch(payload, :flags) do
    compiled_flags =
      flags
      |> Enum.map(fn {flag_key, flag_payload} ->
        normalized_flag_key = normalize_string(flag_key)
        {normalized_flag_key, %{flag_key: normalized_flag_key, flag_payload: flag_payload}}
      end)
      |> Map.new()

    {:ok, compiled_flags, fetch(payload, :generated_at)}
  else
    false -> {:error, EvaluationError.malformed_runtime_data()}
    _other -> {:error, EvaluationError.malformed_runtime_data()}
  end
end
```

Add `audiences` as a required or version-gated payload map, normalize keys, expose `audience_keys`, and return malformed runtime data on shape/env mismatch. Keep all audience resolution data inside this compiled struct.

### `rulestead/lib/rulestead/evaluator.ex` (service, transform)

**Analog:** current evaluator rule/trace pipeline

**Evaluation entry and base trace** (lines 7-29):
```elixir
@spec evaluate(map(), Context.t() | keyword() | map()) ::
        {:ok, Result.t()} | {:error, Rulestead.Error.t()}
def evaluate(flag_payload, context) when is_map(flag_payload) do
  context = Context.normalize(context)

  with {:ok, flag} <- fetch_map(flag_payload, :flag),
       {:ok, active_ruleset} <- fetch_map(flag_payload, :active_ruleset) do
    rules = fetch_list(active_ruleset, :rules)
    evaluate_rules(rules, flag_payload, flag, active_ruleset, context)
  else
    {:error, %Rulestead.Error{} = error} -> {:error, error}
  end
end
```

**Rule skip/match trace pattern** (lines 78-100):
```elixir
defp evaluate_rule(rule, flag_payload, flag, active_ruleset, context) do
  rule_key = stringify(rule[:key] || rule["key"])

  with {:ok, condition_trace} <- evaluate_conditions(fetch_list(rule, :conditions), context),
       {:ok, rollout_trace} <- evaluate_rollout(rule, flag_payload, active_ruleset, context),
       {:ok, result} <-
         build_result(rule, flag, active_ruleset, rule_key, condition_trace, rollout_trace) do
    {:match, result,
     %{rule_key: rule_key, conditions: condition_trace, rollout: result.debug_trace.rollout}}
  else
    {:skip, reason, detail} ->
      {:skip,
       %{
         rule_key: rule_key,
         reason: reason,
         conditions: detail[:conditions] || [],
         rollout: detail[:rollout],
         warnings: detail[:warnings] || []
       }}
```

**Current segment behavior to replace** (lines 134-142, 284-291):
```elixir
strategy in [:forced_value, :segment_match, "forced_value", "segment_match"] ->
  {:ok, %{matched?: true}}

strategy
when strategy in [:forced_value, :segment_match, "forced_value", "segment_match"] ->
  value = extract_value(rule[:value] || rule["value"])
  {:ok, result(flag, active_ruleset, rule_key, value, nil, condition_trace, rollout_trace)}
```

Split `segment_match` from `forced_value`: resolve `audience_key` from compiled snapshot-local audience definitions, evaluate audience definition against normalized context, add match/miss/missing trace nodes, and never call Store/Ecto/Admin/host identity/observability from here.

### `rulestead/lib/rulestead/audit_event.ex` (model, transform)

**Analog:** audit metadata/changset normalizer

**Schema/results pattern** (lines 14-29):
```elixir
@results [:ok, :denied, :error]

schema "audit_events" do
  field(:event_type, :string)
  field(:resource_type, :string)
  field(:resource_id, :binary_id)
  field(:resource_key, :string)
  field(:environment_key, :string)
  field(:actor_id, :string)
  field(:actor_type, :string)
  field(:actor_display, :string)
  field(:reason, :string)
  field(:result, Ecto.Enum, values: @results, default: :ok)
  field(:metadata, :map, default: %{})
```

**Metadata normalization pattern** (lines 36-93):
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
```

Extend this style with allowlisted audience keys such as `preview_fingerprint`, `affected_references`, `preview_basis`, `uncertainty`, `sample_evidence`, and `blockers`. Do not store opaque unredacted preview blobs.

**Sensitive context scrub** (lines 177-225):
```elixir
defp normalize_context(map) when is_map(map) do
  map
  |> normalize_map()
  |> drop_sensitive_context_keys()
end

defp drop_sensitive_context_keys(map) do
  map
  |> Map.drop(["session", "session_data", "session_id", "session_token", "socket_session"])
  |> Map.new(fn
    {key, value} when is_map(value) -> {key, drop_sensitive_context_keys(value)}
    {key, value} when is_list(value) -> {key, Enum.map(value, &drop_sensitive_list_value/1)}
    entry -> entry
  end)
end
```

### Contract tests under `rulestead/test/rulestead/**` (test)

**Analogs:** compare contract, promotion apply contract, runtime/evaluator tests, admin security contract

**Adapter parity fixture pattern** (`compare_contract_test.exs` lines 1-17, 370-400):
```elixir
defmodule Rulestead.Store.CompareContractTest do
  use ExUnit.Case, async: false

  import Rulestead.StoreFixtures

  alias Rulestead.{
    Audience,
    Environment,
    Fake,
    Flag,
    FlagEnvironment,
    Promotion.Compare,
    Repo,
    Store.Command
  }
```

```elixir
assert {:ok, ecto_payload} = ecto_payload
assert {:ok, fake_payload} = fake_payload

assert ecto_payload.compare_schema_version == fake_payload.compare_schema_version
assert ecto_payload.overall_status == fake_payload.overall_status
assert ecto_payload.requested_flag_keys == fake_payload.requested_flag_keys
assert ecto_payload.dependency_closure_keys == fake_payload.dependency_closure_keys
assert is_binary(ecto_payload.compare_token)
assert is_binary(fake_payload.compare_token)
```

**Audience reference test pattern** (`compare_contract_test.exs` lines 214-244):
```elixir
publish_ruleset!(
  @store_module,
  "checkout-redesign",
  "staging",
  valid_ruleset_attrs(%{
    rules: [
      %{
        key: "segment-match",
        name: "VIP audience",
        strategy: :segment_match,
        audience_key: "vip-users",
        conditions: []
      }
    ]
  })
)

assert initial_compare.overall_status == :blocker
assert severities_for(initial_compare, :missing_dependency) == [:blocker]
```

**Token determinism unit pattern** (`promotion/compare_test.exs` lines 107-130):
```elixir
token = Compare.compare_token(attrs)

assert token ==
         Compare.compare_token(Map.merge(attrs, %{compared_flag_keys: ["checkout-redesign"]}))

refute token ==
         Compare.compare_token(%{
           attrs
           | dependency_closure_keys: ["audience:vip-users", "audience:cart-abandoners"]
         })
```

**Apply command from preview pattern** (`promotion_apply_contract_test.exs` lines 168-185, 370-384):
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
assert result.compare_token == compare.compare_token
assert result.dependency_closure_keys == compare.dependency_closure_keys
```

**Denied audit pattern** (`admin_security_contract_test.exs` lines 88-100, 192-207):
```elixir
assert {:error, %Error{domain: :auth, type: :unauthorized} = error, denied_audit} =
         Authorizer.authorize(actor, :engage_kill_switch, resource, "production")

assert denied_audit.result == :denied
```

```elixir
assert {"ruleset.save_draft", :denied, "viewer-1", "req-draft"} in denied
assert {"ruleset.publish", :denied, "viewer-1", "req-publish"} in denied
assert {"flag.archive", :denied, "viewer-1", "req-archive"} in denied
```

Tests to create:

| Test File | Copy Pattern From | Key Assertions |
|-----------|-------------------|----------------|
| `targeting/impact_preview_test.exs` | `promotion/compare_test.exs` | stable fingerprint, scope-bound token, redacted samples, uncertainty labels, stable sort |
| `store/audience_impact_contract_test.exs` | `store/compare_contract_test.exs` | Fake/Ecto same preview payload, blockers, dependency references |
| `store/ecto_audience_impact_contract_test.exs` | `store/promotion_apply_contract_test.exs` | transaction mutates audience, rejects stale token, writes audit, publishes snapshot |
| `runtime/audience_snapshot_test.exs` | `runtime_snapshot_test.exs` + `evaluator_test.exs` | snapshot compiles audiences, evaluator resolves locally, missing audience fails closed or traces skip |
| `audience_mutation_audit_test.exs` | `admin_security_contract_test.exs` | accepted/blocked/denied audit rows include fingerprint, references, actor, reason, tenant/env |

## Shared Patterns

### Authentication And Authorization

**Source:** `rulestead/lib/rulestead.ex`
**Apply to:** Public facade functions and mutation commands

Use `admin_read/2` for preview reads and `admin_write/2` for edit/archive/apply. `admin_write/2` redacts command metadata, computes command resource/action, runs authorization, persists denied mutation audit when applicable, and only then dispatches to the store (lines 1334-1367). Do not bypass this with direct adapter calls from the public API.

### Redaction

**Source:** `rulestead/lib/rulestead/admin/redaction.ex`
**Apply to:** Preview samples, audit metadata, telemetry metadata

```elixir
@spec redact_metadata(map(), keyword()) :: %{audit: map(), telemetry: map()}
def redact_metadata(metadata, opts \\ []) when is_map(metadata) do
  allow = opts |> Keyword.get(:allow, []) |> Enum.map(&normalize_path/1)

  %{
    audit: redact_map(metadata, allow, :audit),
    telemetry: redact_map(metadata, allow, :telemetry)
  }
end
```

Allowlist only support-safe preview fields. Missing explicit sample evidence should produce `preview_basis`/`uncertainty` metadata, not zero-impact claims.

### Error Handling

**Source:** `rulestead/lib/rulestead/store/ecto.ex`
**Apply to:** Ecto store callbacks

Use `with` for domain preconditions and `Repo.transact()` for mutations. Normalize `Rulestead.Error` directly, changesets to invalid-command/store errors, and unexpected transaction reasons to unavailable errors, as in promotion apply lines 161-170.

### Snapshot Locality

**Source:** `rulestead/lib/rulestead/store/ecto.ex`, `runtime/snapshot.ex`, `evaluator.ex`
**Apply to:** Runtime snapshot and evaluator changes

Snapshot payloads are built at publish/apply time and compiled from a binary payload. Evaluator currently receives only a `flag_payload` and normalized context. Phase 53 must keep audience data in the compiled payload and must not add live DB, mounted-admin, host identity, or observability lookups to evaluation.

### Stable Sorting And Findings

**Source:** `rulestead/lib/rulestead/promotion/compare.ex`
**Apply to:** Impact preview and dependency summaries

Use severity rank sorting, stable semantic keys, and deterministic hashes. The relevant helpers are `@severity_rank` (line 8), `sort_flags/1` (lines 345-350), and `sort_findings/1` (lines 353-358).

## No Analog Found

None. New targeting modules are new files, but promotion compare and manifest import provide exact domain analogs for pure preview contracts, staleness tokens, dependency findings, and stable result shapes.

## Metadata

**Analog search scope:** `rulestead/lib/rulestead/**/*.ex`, `rulestead/test/rulestead/**/*.exs`, `rulestead/test/support/**/*.ex`
**Files scanned:** 140+ repo-local Elixir files via `rg --files`, targeted `rg`, and targeted numbered reads
**Pattern extraction date:** 2026-05-27


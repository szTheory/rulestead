# Phase 10: Scheduled Changes and Durable Execution - Pattern Map

**Mapped:** 2026-04-24
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `rulestead/priv/repo/migrations/*_create_rulestead_scheduled_executions*.exs` | migration | CRUD | `rulestead/priv/repo/migrations/20260424000100_create_rulestead_change_requests_and_approvals.exs` | exact |
| `rulestead/lib/rulestead/governance/scheduled_execution.ex` | model | CRUD | `rulestead/lib/rulestead/governance/change_request.ex` | role-match |
| `rulestead/lib/rulestead/governance/execution_attempt.ex` | model | event-driven | `rulestead/lib/rulestead/governance/approval.ex` plus audit row patterns in `rulestead/lib/rulestead/audit_event.ex` | partial |
| `rulestead/lib/rulestead/store.ex` | service | request-response | `rulestead/lib/rulestead/store.ex` | exact |
| `rulestead/lib/rulestead/store/command.ex` | service | request-response | `rulestead/lib/rulestead/store/command.ex` governance command modules | exact |
| `rulestead/lib/rulestead.ex` | service | request-response | `rulestead/lib/rulestead.ex` governance facade verbs | exact |
| `rulestead/lib/rulestead/store/ecto.ex` | service | CRUD + event-driven | `rulestead/lib/rulestead/store/ecto.ex` change-request persistence and execution path | exact |
| `rulestead/lib/rulestead/fake.ex` | service | CRUD + event-driven | `rulestead/lib/rulestead/fake.ex` governance parity path | exact |
| `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` | worker | event-driven | `rulestead/lib/rulestead/oban/worker.ex` plus enqueue/context seam in `rulestead/lib/rulestead/oban.ex` and `oban/middleware.ex` | role-match |
| `rulestead/lib/rulestead/telemetry.ex` | utility | event-driven | `rulestead/lib/rulestead/telemetry.ex` governance metadata helpers | exact |
| `rulestead/lib/rulestead/audit_event.ex` | model | transform | `rulestead/lib/rulestead/audit_event.ex` governance metadata serialization | exact |
| `rulestead/lib/rulestead/admin/authorizer.ex` and related governance vocab files | service | request-response | `rulestead/lib/rulestead/admin/authorizer.ex`, `governance/change_request.ex`, `governance/approval_requirement.ex` | exact |
| `rulestead/test/rulestead/**/*scheduled*` and governance contract tests | test | request-response + event-driven | `rulestead/test/rulestead/store/governance_adapter_contract_test.exs`, `governance_safety_contract_test.exs`, `store/command_governance_test.exs`, `audit_event_governance_test.exs`, `oban_test.exs` | exact |

## Pattern Assignments

### `rulestead/priv/repo/migrations/*_create_rulestead_scheduled_executions*.exs` (migration, CRUD)

**Analog:** `rulestead/priv/repo/migrations/20260424000100_create_rulestead_change_requests_and_approvals.exs`

**Schema and constraint shape** ([20260424000100_create_rulestead_change_requests_and_approvals.exs](/Users/jon/projects/rulestead/rulestead/priv/repo/migrations/20260424000100_create_rulestead_change_requests_and_approvals.exs:4)):
```elixir
def up do
  create table(:change_requests, primary_key: false) do
    add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
    add(:status, :text, null: false, default: "submitted")
    add(:governed_action, :text, null: false)
    add(:environment_key, :text, null: false)
    add(:resource_type, :text, null: false)
    add(:resource_key, :text, null: false)
    add(:submitter_id, :text, null: false)
    add(:submitter_type, :text, null: false)
    add(:submitter_display, :text)
    add(:reason, :text)
    add(:approval_requirement_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
    add(:command_snapshot, :map, null: false, default: fragment("'{}'::jsonb"))
    add(:metadata, :map, null: false, default: fragment("'{}'::jsonb"))
    add(:correlation_id, :text, null: false)
    add(:submitted_at, :utc_datetime_usec, null: false)
    add(:resolved_at, :utc_datetime_usec)
    add(:executed_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end
```

**Index and enum pattern** ([20260424000100_create_rulestead_change_requests_and_approvals.exs](/Users/jon/projects/rulestead/rulestead/priv/repo/migrations/20260424000100_create_rulestead_change_requests_and_approvals.exs:27)):
```elixir
create(index(:change_requests, [:environment_key, :status]))
create(index(:change_requests, [:resource_type, :resource_key, :inserted_at]))
create(unique_index(:change_requests, [:correlation_id]))

create(
  constraint(:change_requests, :change_requests_status_must_be_valid,
    check: "status IN ('submitted', 'approved', 'rejected', 'cancelled', 'executed')"
  )
)
```

**Apply to Phase 10:** model `scheduled_executions` as the operator-facing source of truth, add explicit status constraints, add a unique replay/idempotency key per scheduled execution identity, and keep Oban linkage nullable/secondary rather than primary state.

---

### `rulestead/lib/rulestead/governance/scheduled_execution.ex` (model, CRUD)

**Analog:** `rulestead/lib/rulestead/governance/change_request.ex`

**Canonical struct and fixed vocab pattern** ([change_request.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/change_request.ex:8)):
```elixir
@states [:submitted, :approved, :rejected, :cancelled, :executed]
@terminal_states [:rejected, :cancelled, :executed]
@governed_actions [:publish_ruleset, :advance_rollout, :engage_kill_switch, :manage_settings]

@enforce_keys [
  :state,
  :action,
  :environment_key,
  :resource_type,
  :resource_key,
  :submitted_by,
  :command,
  :approval_requirement,
  :correlation_id
]
```

**Normalization and serialize pattern** ([change_request.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/change_request.ex:58)):
```elixir
def new(attrs) when is_list(attrs) or is_map(attrs) do
  attrs = Map.new(attrs)

  %__MODULE__{
    id: normalize_string(Map.get(attrs, :id)),
    state: normalize_state(Map.get(attrs, :state)),
    action: normalize_action(Map.get(attrs, :action)),
    environment_key: normalize_string(Map.get(attrs, :environment_key)),
    resource_type: normalize_string(Map.get(attrs, :resource_type)),
    resource_key: normalize_string(Map.get(attrs, :resource_key)),
    submitted_by: normalize_actor_summary(Map.get(attrs, :submitted_by)),
    command: normalize_command(Map.get(attrs, :command)),
    approval_requirement: ApprovalRequirement.new(Map.get(attrs, :approval_requirement, %{})),
    correlation_id: normalize_string(Map.get(attrs, :correlation_id))
  }
end
```

**Apply to Phase 10:** keep scheduled execution as an explicit domain record with locked states and serialized actor chain fields such as `scheduled_by`, `approved_by`, `executed_by`, requested time, actual time, and correlation id. Do not hide lifecycle inside Oban rows.

---

### `rulestead/lib/rulestead/governance/execution_attempt.ex` (model, event-driven)

**Analog:** `rulestead/lib/rulestead/audit_event.ex`

**Append-only event metadata pattern** ([audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:33)):
```elixir
def metadata(attrs \\ %{}) when is_list(attrs) or is_map(attrs) do
  attrs = Map.new(attrs)
  context = normalize_context(Map.get(attrs, :context) || Map.get(attrs, "context"))

  %{
    "before" => normalize_map(Map.get(attrs, :before) || Map.get(attrs, "before")),
    "after" => normalize_map(Map.get(attrs, :after) || Map.get(attrs, "after")),
    "diff" => normalize_map(Map.get(attrs, :diff) || Map.get(attrs, "diff")),
    "links" => normalize_map(Map.get(attrs, :links) || Map.get(attrs, "links")),
    "context" => context
  }
  |> maybe_put("request_id", Map.get(attrs, :request_id) || Map.get(attrs, "request_id"))
  |> maybe_put("source", Map.get(attrs, :source) || Map.get(attrs, "source"))
  |> maybe_put("rollback_of_event_id", Map.get(attrs, :rollback_of_event_id) || Map.get(attrs, "rollback_of_event_id"))
  |> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
  |> maybe_put("approval_id", governance_value(attrs, context, :approval_id))
  |> maybe_put("governance_action", governance_value(attrs, context, :governance_action))
  |> maybe_put("execution_stage", governance_value(attrs, context, :execution_stage))
end
```

**Sensitive-context stripping** ([audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:161)):
```elixir
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

**Apply to Phase 10:** if execution attempts become their own table or embedded metadata, copy this append-only, redacted, correlation-rich shape rather than inventing opaque worker-only error blobs.

---

### `rulestead/lib/rulestead/store.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/store.ex`

**Behavior extension pattern** ([store.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store.ex:22)):
```elixir
@callback submit_change_request(Command.SubmitChangeRequest.t()) :: result(map())
@callback approve_change_request(Command.ApproveChangeRequest.t()) :: result(map())
@callback reject_change_request(Command.RejectChangeRequest.t()) :: result(map())
@callback cancel_change_request(Command.CancelChangeRequest.t()) :: result(map())
@callback execute_change_request(Command.ExecuteChangeRequest.t()) :: result(map())
@callback fetch_change_request(Command.FetchChangeRequest.t()) :: result(map())
@callback list_change_requests(Command.ListChangeRequests.t()) :: result(Command.Page.t(map()))
```

**Apply to Phase 10:** add scheduled-execution callbacks here first so fake and ecto remain parity-bound by the same contract.

---

### `rulestead/lib/rulestead/store/command.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead/store/command.ex`

**GovernanceSupport normalization pattern** ([command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:10)):
```elixir
def normalize_actor(actor) when is_list(actor) or is_map(actor) do
  actor = Map.new(actor)

  %{}
  |> maybe_put("id", fetch(actor, :id) |> normalize_string())
  |> maybe_put("type", fetch(actor, :type) |> normalize_string())
  |> maybe_put("display", fetch(actor, :display) |> normalize_string())
end

def normalize_metadata(metadata), do: metadata |> normalize_map() |> drop_sensitive_keys()
def normalize_command(metadata), do: normalize_map(metadata)
```

**Submit/execute command module pattern** ([command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:572), [command.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/command.ex:714)):
```elixir
defmodule SubmitChangeRequest do
  @enforce_keys [:action, :environment_key, :resource_type, :resource_key, :command, :approval_requirement]
  defstruct [:action, :environment_key, :resource_type, :resource_key, :command, :approval_requirement,
             actor: nil, reason: nil, metadata: %{}]
end

defmodule ExecuteChangeRequest do
  @enforce_keys [:change_request_id]
  defstruct [:change_request_id, actor: nil, reason: nil, metadata: %{}]
end
```

**Command contract tests to copy** ([store/command_governance_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/command_governance_test.exs:19)):
```elixir
command =
  Command.SubmitChangeRequest.new(%{
    action: :publish_ruleset,
    environment_key: :production,
    resource_type: :flag,
    resource_key: :checkout_v2,
    command: %{version: 7, rollout: %{stage: :confirm}},
    approval_requirement: %{...},
    actor: %{id: 42, type: :operator, display: "Ops"},
    metadata: [request_id: "req-123", source: :admin_ui, nested: %{correlation_id: "corr-123"}]
  })
```

**Apply to Phase 10:** add schedule/requeue/retry/cancel/fetch/list commands using this exact normalization spine; keep admin/session fields out of the public command contract.

---

### `rulestead/lib/rulestead.ex` (service, request-response)

**Analog:** `rulestead/lib/rulestead.ex`

**Root facade governance verb pattern** ([rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:233)):
```elixir
@spec submit_change_request(Command.SubmitChangeRequest.t()) :: Store.result(map())
def submit_change_request(%Command.SubmitChangeRequest{} = command) do
  admin_write(:submit_change_request, command)
end

@spec execute_change_request(Command.ExecuteChangeRequest.t()) :: Store.result(map())
def execute_change_request(%Command.ExecuteChangeRequest{} = command) do
  admin_write(:execute_change_request, command)
end
```

**Action routing pattern** ([rulestead.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead.ex:884)):
```elixir
defp command_action(:engage_kill_switch), do: :engage_kill_switch
defp command_action(:release_kill_switch), do: :release_kill_switch
```

**Apply to Phase 10:** root-level scheduled execution verbs should be command-first and reuse `admin_write/2`; avoid adding worker-only bypass APIs.

---

### `rulestead/lib/rulestead/store/ecto.ex` (service, CRUD + event-driven)

**Analog:** `rulestead/lib/rulestead/store/ecto.ex`

**Transactional row + audit write pattern** ([store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:525)):
```elixir
correlation_id = governance_correlation_id(command)
submitted_at = now()

Multi.new()
|> Multi.run(:change_request, fn repo, _changes ->
  insert_change_request(repo, command, correlation_id, submitted_at)
end)
|> Multi.run(:audit_event, fn repo, %{change_request: change_request} ->
  audit_command = governance_audit_command(command, change_request, "submitted")
  repo.insert(audit_event_changeset(%AuditEvent{}, audit_command, "change_request.submitted", :ok, %{
    resource_key: change_request.resource_key,
    environment_key: change_request.environment_key
  }))
end)
|> Repo.transact()
```

**Source-of-truth row persistence pattern** ([store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1395)):
```elixir
attrs = %{
  status: "submitted",
  governed_action: Atom.to_string(command.action),
  environment_key: command.environment_key,
  resource_type: command.resource_type,
  resource_key: command.resource_key,
  submitter_id: actor_value(command.actor, "id"),
  submitter_type: actor_value(command.actor, "type") || "operator",
  submitter_display: actor_value(command.actor, "display"),
  reason: command.reason,
  approval_requirement_snapshot: command.approval_requirement,
  command_snapshot: command.command,
  metadata: command.metadata,
  correlation_id: correlation_id,
  submitted_at: submitted_at,
  resolved_at: nil,
  executed_at: nil
}
```

**Execution path pattern** ([store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1677)):
```elixir
defp execute_governed_change(%{governed_action: "publish_ruleset"} = change_request, command) do
  with {:ok, environment} <- fetch_environment(change_request.environment_key),
       {:ok, flag, flag_environment} <-
         fetch_flag_environment(change_request.resource_key, environment.key),
       {:ok, ruleset} <-
         resolve_publishable_ruleset(
           flag_environment,
           environment.key,
           change_request.command_snapshot["version"]
         ) do
    published_at = now()

    Multi.new()
    |> Multi.update(:ruleset, Ruleset.changeset(ruleset, %{status: :published, published_at: published_at}))
    |> Multi.update(:flag_environment, FlagEnvironment.changeset(flag_environment, %{...}))
    |> Multi.run(:runtime_snapshot, fn repo, _changes -> insert_runtime_snapshot(repo, environment, published_at) end)
    |> Multi.run(:ruleset_audit_event, fn repo, _changes -> ... end)
    |> Multi.run(:change_request, fn repo, _changes -> update_change_request(repo, change_request, %{status: "executed", ...}) end)
    |> Multi.run(:audit_event, fn repo, %{change_request: updated_change_request} -> ... end)
    |> Repo.transact()
  end
end
```

**Audit metadata pattern** ([store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1367)):
```elixir
metadata:
  AuditEvent.metadata(%{
    before: Map.get(opts, :before, %{}),
    after: Map.get(opts, :after, %{}),
    diff: diff_map(Map.get(opts, :before, %{}), Map.get(opts, :after, %{})),
    links: Map.get(opts, :links, %{}),
    context: Map.get(command, :metadata, %{}),
    request_id: correlation_id(command),
    source: command.metadata[:source] || command.metadata["source"],
    rollback_of_event_id: Map.get(opts, :rollback_of_event_id)
  }),
correlation_id: correlation_id(command),
occurred_at: now()
```

**Apply to Phase 10:** keep `scheduled_execution` insert/update, attempt recording, and Oban enqueue in one `Ecto.Multi`; reuse the same audit/update choreography when the worker promotes a due record from scheduled to executing/succeeded/failed/quarantined.

---

### `rulestead/lib/rulestead/fake.ex` (service, CRUD + event-driven)

**Analog:** `rulestead/lib/rulestead/fake.ex`

**Parity entrypoint pattern** ([fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:138)):
```elixir
@impl Store
def submit_change_request(%Command.SubmitChangeRequest{} = command) do
  call({:submit_change_request, command})
end

@impl Store
def execute_change_request(%Command.ExecuteChangeRequest{} = command) do
  call({:execute_change_request, command})
end
```

**Correlation and execution parity pattern** ([fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:1500)):
```elixir
defp governance_audit_command(command, change_request, stage) do
  metadata =
    command.metadata
    |> Map.merge(%{
      "request_id" => change_request.correlation_id,
      "change_request_id" => change_request.id,
      "governance_action" => change_request.governed_action,
      "execution_stage" => stage,
      "resource_key" => change_request.resource_key
    })

  Map.merge(command, %{metadata: metadata, reason: command.reason, actor: command.actor})
end
```

**In-memory execution simulation pattern** ([fake.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/fake.ex:1522)):
```elixir
defp execute_governed_change(
       state,
       %{governed_action: "publish_ruleset"} = change_request,
       command
     ) do
  ...
  {audit_event, post_audit_state} =
    append_audit_event(next_state, publish_command, "ruleset.publish", :ok, ...)

  {:ok, execution_result,
   %{post_audit_state | audit_events: [audit_event | post_audit_state.audit_events]}}
end
```

**Apply to Phase 10:** the fake adapter should own explicit scheduled state, retry counters, terminal/quarantined state, and requeue semantics in memory. Do not let Ecto-only behavior define the product contract.

---

### `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` (worker, event-driven)

**Analog:** `rulestead/lib/rulestead/oban/worker.ex`, `rulestead/lib/rulestead/oban.ex`, `rulestead/lib/rulestead/oban/middleware.ex`

**Context restoration pattern** ([oban/worker.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/worker.ex:6)):
```elixir
defmacro __using__(_opts) do
  quote do
    def rulestead_context(job), do: Rulestead.Oban.context_from_job(job)
    def context_from_job(job), do: Rulestead.Oban.context_from_job(job)
  end
end
```

**Bounded serialized context pattern** ([oban.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban.ex:8)):
```elixir
@default_key "rulestead_context"
@bounded_fields ~w(actor targeting_key tenant_key environment attributes request_id session_id strict?)a

def serialize_context(context) do
  context
  |> Context.normalize()
  |> Map.from_struct()
  |> Map.take(@bounded_fields)
  |> Map.update(:actor, nil, &normalize_actor/1)
  |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put(acc, Atom.to_string(key), value) end)
end
```

**Enqueue seam pattern** ([oban/middleware.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/middleware.ex:11)):
```elixir
@spec attach(map(), keyword()) :: map()
def attach(job, opts) when is_map(job) and is_list(opts) do
  context =
    case Keyword.fetch(opts, :context) do
      {:ok, context} -> context
      :error -> raise ArgumentError, "attach/2 requires :context"
    end

  Oban.put_context(job, context, opts)
end
```

**Worker contract test pattern** ([oban_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/oban_test.exs:54)):
```elixir
context =
  Context.new(
    actor: %{id: "system:oban"},
    targeting_key: "job-user",
    tenant_key: "tenant-1",
    environment: "prod",
    attributes: %{"source" => "checkout"},
    request_id: "req-oban",
    session_id: "session-oban",
    strict?: true
  )
```

**Apply to Phase 10:** the new worker should restore bounded context from the job, then call store/facade scheduled-execution APIs using the durable execution id as the primary input. Keep retries/idempotency in the application contract, not as raw job-arg branching.

---

### `rulestead/lib/rulestead/telemetry.ex` (utility, event-driven)

**Analog:** `rulestead/lib/rulestead/telemetry.ex`

**Governance metadata pattern** ([telemetry.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/telemetry.ex:101)):
```elixir
def governance_metadata(command, attrs \\ %{}) when is_struct(command) and is_map(attrs) do
  command_map = Map.from_struct(command)
  metadata = Map.get(command_map, :metadata, %{})

  %{}
  |> Map.put_new(:operation, governance_operation(command))
  |> Map.put_new(:change_request_id, Map.get(attrs, :change_request_id) || Map.get(command_map, :change_request_id))
  |> Map.put_new(:correlation_id, Map.get(attrs, :correlation_id) || Map.get(metadata, "correlation_id"))
  |> Map.put_new(:audit_event_id, Map.get(attrs, :audit_event_id) || Map.get(metadata, "audit_event_id"))
  |> Map.put_new(:resource_key, Map.get(attrs, :resource_key) || Map.get(metadata, "resource_key"))
  |> Map.put_new(:environment, Map.get(attrs, :environment_key) || Map.get(command_map, :environment_key) || Map.get(metadata, "environment_key"))
  |> Map.put_new(:audit_action, Map.get(attrs, :action))
  |> Map.put_new(:reason, Map.get(attrs, :event))
end
```

**Telemetry emission pattern** ([store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1770)):
```elixir
Telemetry.execute(
  [:rulestead, :admin, :change_request, event],
  %{count: 1},
  Telemetry.metadata(
    Telemetry.governance_metadata(command, %{
      event: event,
      action: governance_action(change_request.governed_action),
      environment_key: change_request.environment_key,
      resource_key: change_request.resource_key,
      change_request_id: change_request.id,
      correlation_id: change_request.correlation_id,
      audit_event_id: audit_event.id
    })
  )
)
```

**Metadata contract test** ([governance_facade_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/governance_facade_contract_test.exs:115)):
```elixir
assert metadata == %{
  operation: "execute_change_request",
  environment: "production",
  audit_action: "publish_ruleset",
  reason: :merged,
  change_request_id: "cr-123",
  correlation_id: "corr-123",
  audit_event_id: "evt-123",
  resource_key: "checkout-redesign"
}
```

**Apply to Phase 10:** extend, don’t replace, this metadata spine. Add scheduled execution id, scheduled_at, attempted_at, attempt_count, and terminal failure reason in the same bounded style.

---

### `rulestead/lib/rulestead/audit_event.ex` (model, transform)

**Analog:** `rulestead/lib/rulestead/audit_event.ex`

**Governance metadata keys already supported** ([audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:45)):
```elixir
|> maybe_put("request_id", Map.get(attrs, :request_id) || Map.get(attrs, "request_id"))
|> maybe_put("source", Map.get(attrs, :source) || Map.get(attrs, "source"))
|> maybe_put("rollback_of_event_id", Map.get(attrs, :rollback_of_event_id) || Map.get(attrs, "rollback_of_event_id"))
|> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
|> maybe_put("approval_id", governance_value(attrs, context, :approval_id))
|> maybe_put("governance_action", governance_value(attrs, context, :governance_action))
|> maybe_put("execution_stage", governance_value(attrs, context, :execution_stage))
```

**Audit metadata tests** ([audit_event_governance_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/audit_event_governance_test.exs:6)):
```elixir
assert event.metadata["change_request_id"] == "cr-123"
assert event.metadata["approval_id"] == "ap-456"
assert event.metadata["governance_action"] == "publish_ruleset"
assert event.metadata["execution_stage"] == "approval"
assert event.metadata["request_id"] == "req-123"
assert event.metadata["source"] == "admin_ui"
```

**Apply to Phase 10:** extend metadata keys for scheduled execution and attempt lineage here so both direct and scheduled governance flows serialize the same way.

---

### `rulestead/lib/rulestead/admin/authorizer.ex` and governance vocab files (service, request-response)

**Analog:** `rulestead/lib/rulestead/admin/authorizer.ex`, `governance/change_request.ex`, `governance/approval_requirement.ex`

**Governed action allowlist pattern** ([authorizer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/authorizer.ex:8)):
```elixir
@production_roles ~w(admin incident_commander prod_operator)a
@governed_actions [:publish_ruleset, :advance_rollout, :engage_kill_switch, :manage_settings]
```

**Approval requirement derivation** ([authorizer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/authorizer.ex:170)):
```elixir
ApprovalRequirement.new(
  action: action,
  environment_key: environment_key,
  required_approvals: if(change_request_required?, do: 1, else: 0),
  change_request_required?: change_request_required?,
  self_approval_allowed?: self_approval_allowed?
)
```

**Governance vocab lock tests** ([change_request_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/governance/change_request_contract_test.exs:7)):
```elixir
assert ChangeRequest.governed_actions() == [
  :publish_ruleset,
  :advance_rollout,
  :engage_kill_switch,
  :manage_settings
]
```

**Apply to Phase 10:** update the bounded action vocabulary together across authorizer, approval requirement, change request, store execution cases, and tests. The phase context says the action set is `publish_ruleset`, `advance_rollout`, `engage_kill_switch`, and `release_kill_switch`; current `manage_settings` fallback is legacy scope and should not silently absorb new scheduler actions.

---

### `rulestead/test/rulestead/**/*scheduled*` and governance contract tests (test, request-response + event-driven)

**Analogs:** `store/governance_adapter_contract_test.exs`, `governance_safety_contract_test.exs`, `store/command_governance_test.exs`, `audit_event_governance_test.exs`, `oban_test.exs`

**Cross-adapter parity pattern** ([governance_adapter_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/governance_adapter_contract_test.exs:22)):
```elixir
@adapters [Rulestead.Fake, StoreEcto]

Enum.each(@adapters, fn adapter ->
  reset_adapter!(adapter)
  seed_governed_publish!(adapter)
  ...
  assert {:ok, %{change_request: executed, execution_result: execution_result}} =
           adapter.execute_change_request(...)
end)
```

**Public facade safety pattern** ([governance_safety_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/governance_safety_contract_test.exs:33)):
```elixir
assert {:ok, %{change_request: submitted}} =
         Rulestead.submit_change_request(...)
assert {:ok, %{change_request: approved, approval: approval}} =
         Rulestead.approve_change_request(...)
assert {:ok, %{change_request: executed, execution_result: execution_result}} =
         Rulestead.execute_change_request(...)
```

**Command normalization pattern** ([store/command_governance_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/command_governance_test.exs:57)):
```elixir
for command <- [approve, reject, cancel, execute] do
  assert %{"id" => _, "type" => _, "display" => _} = command.actor
  assert is_binary(command.reason)
  assert is_map(command.metadata)
  assert is_binary(command.metadata["request_id"])
  refute Map.has_key?(command.metadata, "session_id")
end
```

**Apply to Phase 10:** add equivalent tests for schedule submit/edit/cancel/requeue/worker execute, with the same fake-vs-ecto coverage and correlation assertions. Verify stale-target failures and bounded retry exhaustion as product states, not only as Oban internals.

## Shared Patterns

### Transactional Durability
**Source:** [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:525), [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1677)

Use `Ecto.Multi` as the write boundary. Persist the domain record, enqueue the job, and write audit rows in the same transaction. Phase 10 should follow this instead of writing domain state after job insert succeeds.

### Audit Correlation Spine
**Source:** [rulestead/lib/rulestead/store/ecto.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/store/ecto.ex:1659), [rulestead/lib/rulestead/audit_event.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/audit_event.ex:45)

```elixir
defp governance_correlation_id(command) do
  command.metadata[:request_id] || command.metadata["request_id"] || Ecto.UUID.generate()
end
```

```elixir
|> maybe_put("change_request_id", governance_value(attrs, context, :change_request_id))
|> maybe_put("governance_action", governance_value(attrs, context, :governance_action))
|> maybe_put("execution_stage", governance_value(attrs, context, :execution_stage))
```

Apply to scheduled records, attempt rows, worker telemetry, and audit metadata.

### Oban Context Boundary
**Source:** [rulestead/lib/rulestead/oban.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban.ex:8), [rulestead/lib/rulestead/oban/middleware.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/oban/middleware.ex:11)

Only pass bounded serialized context through Oban. Put scheduled execution id and correlation metadata in job args; restore context in the worker; fetch the durable execution record from storage before mutating anything.

### Fake-vs-Ecto Parity
**Source:** [rulestead/test/rulestead/store/governance_adapter_contract_test.exs](/Users/jon/projects/rulestead/rulestead/test/rulestead/store/governance_adapter_contract_test.exs:22)

Every new scheduled-execution public/store verb should land in the shared adapter contract tests. If a behavior cannot be proven in both adapters, it is not yet a stable Phase 10 contract.

### Governance Vocabulary Lock
**Source:** [rulestead/lib/rulestead/governance/change_request.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/governance/change_request.ex:8), [rulestead/lib/rulestead/admin/authorizer.ex](/Users/jon/projects/rulestead/rulestead/lib/rulestead/admin/authorizer.ex:11)

The action list is duplicated across contracts, authorizer, and tests. Update all copies together when introducing `release_kill_switch` or narrowing fallback behavior.

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `rulestead/lib/rulestead/governance/scheduled_execution.ex` | model | CRUD | Scheduling is a new durable record; closest analog is the change-request contract, but there is no existing scheduler model. |
| `rulestead/lib/rulestead/governance/execution_attempt.ex` | model | event-driven | No attempt-tracking model exists yet; use audit-event metadata patterns plus approval/change-request row shape. |
| `rulestead/lib/rulestead/oban/scheduled_execution_worker.ex` | worker | event-driven | There is an Oban seam and worker macro, but no existing domain worker that mutates governed state. |

## Metadata

**Analog search scope:** `rulestead/lib`, `rulestead/priv/repo/migrations`, `rulestead/test`
**Files scanned:** 19
**Pattern extraction date:** 2026-04-24

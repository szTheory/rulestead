# API Stability

`guides/api_stability.md` is the v0.1.0 release contract for Rulestead's public
API catalog, carried forward on the
**`0.1.x` Hex package line**. Repository milestone docs (v1.0.0 GA through
v1.9.0 post-GA band) describe shipped capabilities and proof posture; they do
not change the semver boundary below.

Anything listed here is part of the supported public surface for `0.1.x`.
Anything not listed here may change without notice, even if it is visible in
source.

The boundary is intentionally asymmetric:

- `rulestead` ships a broad runtime-facing public contract.
- `rulestead_admin` ships a narrow host-facing mount contract.
- Internal implementation details remain flexible behind those package
  boundaries.

## Versioning Posture

- New public modules or functions are a minor-version change, not a patch.
- Removing or changing a documented contract requires a major-version change.
- Additive telemetry keys and additive docs are allowed when they do not change
  the semantics listed below.

## Stable `rulestead` Modules

These modules are public in v0.1.0:

- `Rulestead`
- `Rulestead.Context`
- `Rulestead.Result`
- `Rulestead.Error`
- `Rulestead.Store`
- `Rulestead.Admin.Policy`
- `Rulestead.Telemetry`
- `Rulestead.Config`

The **v0.1.0 core module list** above remains closed. **Post-GA supported
adopter facades** (below) are additionally public on `0.1.x` without opening
implementation trees.

## Supported adopter facades (post-GA)

### `Rulestead.Runtime`

Supported keyed lookup for Phoenix apps using the snapshot cache. Closed
function catalog:

- `evaluate/3`
- `enabled?/3`
- `get_value/4`
- `get_variant/3`
- `explain/3`
- `diagnostics/1`

`Rulestead.Runtime.Cache`, `Rulestead.Runtime.Snapshot`, and other
`Rulestead.Runtime.*` implementation modules are **not** public.

### `Rulestead.TestHelpers`

Supported Fake-backed test facade:

- `with_flag/3`
- `put_flag/3`
- `clear_flags/0`
- `seed_bucket/3`
- `assert_flag_evaluated/2`

Backed by `Rulestead.Fake` for in-memory state. `Rulestead.Fake.Control` is
**not** public.

## Stable `Rulestead` Function Catalog

The root facade is a closed catalog in v0.1.0:

- `version/0`
- `fetch_flag/1`
- `fetch_flag/2`
- `fetch_flag/3`
- `fetch_flag!/3`
- `fetch_flag!/2`
- `create_flag/1`
- `create_flag/2`
- `update_flag/1`
- `update_flag/2`
- `update_flag/3`
- `save_draft_ruleset/1`
- `save_draft_ruleset!/1`
- `publish_ruleset/1`
- `publish_ruleset!/1`
- `archive_flag/1`
- `archive_flag!/1`
- `engage_kill_switch/1`
- `engage_kill_switch/3`
- `engage_kill_switch/4`
- `release_kill_switch/1`
- `release_kill_switch/3`
- `release_kill_switch/4`
- `list_audit_events/0`
- `list_audit_events/1`
- `rollback_audit_event/1`
- `rollback_audit_event/2`
- `list_flags/0`
- `list_flags/1`
- `list_flags!/0`
- `list_flags!/1`
- `list_environments/0`
- `list_environments/1`
- `list_audiences/0`
- `list_audiences/1`
- `apply_audience_mutation/1`
- `apply_audience_mutation/2`
- `preview_audience_impact/1`
- `preview_audience_impact/2`
- `preview_audience_impact/3`
- `list_audience_dependencies/0`
- `list_audience_dependencies/1`
- `record_evaluation/1`
- `record_evaluation/3`
- `evaluate/2`
- `evaluate/3`
- `evaluate!/2`
- `evaluate!/3`
- `enabled?/2`
- `get_value/3`
- `get_variant/2`
- `explain/2`
- `simulate_flag/3`
- `simulate_flag/4`
- `explain_flag/3`
- `explain_flag/4`
- `diagnostics/0`

Public helpers outside the root facade:

- `Rulestead.Telemetry.span/3`
- `Rulestead.Telemetry.execute/3`
- `Rulestead.Telemetry.attach_many/4`
- `Rulestead.Telemetry.detach/1`
- `Rulestead.Telemetry.base_metadata/2`
- `Rulestead.Telemetry.metadata/1`
- `Rulestead.Telemetry.base_metadata/3`
- `Rulestead.Telemetry.result_metadata/2`
- `Rulestead.Telemetry.result_metadata/3`
- `Rulestead.Telemetry.runtime_metadata/1`
- `Rulestead.Telemetry.runtime_metadata/2`
- `Rulestead.Telemetry.command_metadata/1`
- `Rulestead.Telemetry.command_metadata/2`
- `Rulestead.Config.load/0`
- `Rulestead.Config.schema/0`
- `Rulestead.Config.defaults/0`
- `Rulestead.Config.validate/0`
- `Rulestead.Config.validate/1`
- `Rulestead.Config.validate!/0`
- `Rulestead.Config.validate!/1`
- `Rulestead.Config.load/1`

## Stable Struct Fields

### `%Rulestead.Context{}`

- `:actor`
- `:targeting_key`
- `:tenant_key`
- `:environment`
- `:attributes`
- `:request_id`
- `:session_id`
- `:strict?`

Construction and normalization helpers are public:

- `Rulestead.Context.new/1`
- `Rulestead.Context.normalize/1`

### `%Rulestead.Result{}`

- `:value`
- `:enabled?`
- `:variant`
- `:reason`
- `:matched_rule`
- `:flag_key`
- `:flag_version`
- `:cache_age_ms`
- `:debug_trace`

Construction and normalization helpers are public:

- `Rulestead.Result.new/1`
- `Rulestead.Result.normalize/1`

Closed `:reason` atoms:

- `:rule_match`
- `:default`
- `:targeting_key_missing`
- `:flag_off`
- `:error`

### `%Rulestead.Error{}`

- `:__exception__`
- `:domain`
- `:type`
- `:message`
- `:metadata`
- `:details`
- `:cause`
- `:plug_status`

Public helpers:

- `Rulestead.Error.new/1`
- `Rulestead.Error.normalize/1`
- `Rulestead.Error.domains/0`
- `Rulestead.Error.leaf_types/0`

The standard Elixir exception hooks generated for `%Rulestead.Error{}` remain
available when the error is raised or normalized.

Closed `:domain` atoms:

- `:evaluation`
- `:ruleset`
- `:kill_switch`
- `:config`
- `:store`
- `:auth`

Closed `:type` atoms:

- `:flag_not_found`
- `:environment_not_found`
- `:snapshot_not_found`
- `:ruleset_not_found`
- `:missing_targeting_key`
- `:repo_not_configured`
- `:repo_ambiguous`
- `:store_not_configured`
- `:store_adapter_invalid`
- `:store_unavailable`
- `:invalid_command`
- `:invalid_ruleset`
- `:variant_weights_invalid`
- `:invalid_value_projection`
- `:malformed_runtime_data`
- `:flag_archived`
- `:unauthorized`
- `:kill_switch_active`
- `:not_implemented`

`Jason.Encoder` for `%Rulestead.Error{}` is part of the contract, and it must
continue to exclude `:cause`.

## Stable Behavior Seams

### `Rulestead.Store`

The store behavior is public. Its callback catalog is closed in v0.1.0:

- `fetch_flag/1`
- `fetch_snapshot/1`
- `create_flag/1`
- `update_flag/1`
- `save_draft_ruleset/1`
- `publish_ruleset/1`
- `archive_flag/1`
- `list_flags/1`
- `list_environments/1`
- `list_audiences/1`
- `apply_audience_mutation/1`
- `preview_audience_impact/1`
- `list_audience_dependencies/1`
- `record_evaluation/1`
- `engage_kill_switch/1`
- `release_kill_switch/1`
- `list_audit_events/1`
- `rollback_audit_event/1`

### `Rulestead.Admin.Policy`

The admin policy seam is public and intentionally small:

- `can?/4`
- `allow_self_approval?/4`
- `change_request_required?/4`

Hosts own authorization. Rulestead does not ship a bundled auth stack. `can?/4` maps host actors to the canonical Rulestead operator role model (Viewer, Editor, Admin) and specific workflow actions.

## Stable Lifecycle Verification Seams

Lifecycle verification in this repo may rely on these public seams:

- shared README and guide content
- `mix rulestead.lifecycle` text and JSON behavior
- mounted admin route, query, and mount semantics such as `?env=`
- documented queue-to-review navigation semantics

Those seams are public because they are part of the release-facing docs and
host integration contract.

The following are still not public lifecycle API:

- internal LiveView modules
- DOM structure
- CSS classes
- test selectors
- socket assigns

Use route, query, and mount behavior for lifecycle verification. Do not freeze
implementation details that the mounted package intentionally keeps flexible.

## Stable Telemetry Contract

The event catalog from [Telemetry](flows/telemetry.md) is part of the public
release contract.

### Event Catalog

- `[:rulestead, :eval, :decide, :start]`
- `[:rulestead, :eval, :decide, :stop]`
- `[:rulestead, :eval, :decide, :exception]`
- `[:rulestead, :runtime, :cache, :hit]`
- `[:rulestead, :runtime, :cache, :miss]`
- `[:rulestead, :runtime, :cache, :refresh]`
- `[:rulestead, :runtime, :cache, :stale_used]`
- `[:rulestead, :runtime, :snapshot, :published]`
- `[:rulestead, :runtime, :snapshot, :applied]`
- `[:rulestead, :store, :read, :start]`
- `[:rulestead, :store, :read, :stop]`
- `[:rulestead, :store, :read, :exception]`
- `[:rulestead, :store, :write, :start]`
- `[:rulestead, :store, :write, :stop]`
- `[:rulestead, :store, :write, :exception]`
- `[:rulestead, :admin, :mutation, :start]`
- `[:rulestead, :admin, :mutation, :stop]`

### Shared Metadata Keys

- `:flag_key`
- `:flag_type`
- `:environment`
- `:snapshot_version`
- `:cache_age_ms`
- `:reason`
- `:has_targeting_key?`
- `:matched_rule_count`

Documented bounded additions:

- `:operation`
- `:source`
- `:refresh_status`
- `:audit_action`
- `:error_kind`

Telemetry remains redacted by default. Raw actor payloads, raw attributes,
secret values, Plug structs, LiveView sockets, and Oban jobs are not part of
the telemetry contract.

## Stable Host Config Schema

`Rulestead.Config` defines the supported host-app schema under
`config :rulestead, :host`.

Closed top-level keys:

- `:environment_key`
- `:plug`
- `:live_view`
- `:oban`
- `:runtime`
- `:tenancy`

Closed nested keys:

- `plug.context_assign`
- `plug.targeting_key_sources`
- `live_view.context_assign`
- `live_view.targeting_key_sources`
- `live_view.assign_flags_mode`
- `oban.enabled`
- `oban.context_key`
- `oban.middlewares`
- `runtime.api`
- `runtime.notifier`
- `runtime.health_peer_provider`
- `runtime.pubsub`
- `runtime.pubsub_topic`
- `tenancy.module`

Allowed `live_view.assign_flags_mode` values:

- `:enabled`
- `:variant`
- `:value`
- `:evaluate`

Other application env keys used internally by the library are not part of this
host-facing stability contract unless they are documented here later.

## Stable `rulestead_admin` Boundary

The admin package contract is intentionally narrow. The public package promise
stops at the mount seam and documented host-facing conventions.

### Public Admin Seam

- `RulesteadAdmin.Router.rulestead_admin/1`
- `RulesteadAdmin.Router.rulestead_admin/2`
- required `policy:` option implementing `Rulestead.Admin.Policy`

### Required Host Session Keys

- `"current_actor"`
- `"rulestead_admin_environments"`
- `"rulestead_admin_last_env"`

### Stable Host-Facing URL Conventions

The route family mounted beneath the chosen base path is public in v0.1.0:

- `/`
- `/new`
- `/audit`
- `/:key`
- `/:key/edit`
- `/:key/rules`
- `/:key/simulate`
- `/:key/rollouts`
- `/:key/kill`
- `/:key/timeline`

The `env` query parameter is the canonical environment selector across the
mounted UI.

The admin package does not promise internal LiveView module names, DOM shape,
or CSS structure. Host apps should integrate at the router, policy, session,
and documented URL level only.

## Non-Public Surface

The following are explicitly outside the v0.1.0 compatibility promise:

- post-GA facade support does not make governance, manifest, or admin LiveView
  modules public
- `RulesteadAdmin.Live.*`
- `RulesteadAdmin.Components.*`
- socket assigns
- DOM structure, CSS classes, and test selectors
- internal helper modules in either package
- internal runtime/cache/store implementation modules
- generated telemetry handler table details
- unpublished or undocumented modules visible only because they exist in source

These planned seams are also excluded from the stability contract until they
ship as documented, tested, supported code:

- `Rulestead.RuleEngine`
- `Rulestead.EvaluationCache`
- `Rulestead.AuditStore`
- `Rulestead.ActorResolver`

If a future guide mentions planned seams for roadmap context, that mention does
not make them public API.

The following exported helpers are visible for runtime mechanics but are not a
supported public seam in `v0.1.0`:

- `Rulestead.Telemetry.dispatch/4`
